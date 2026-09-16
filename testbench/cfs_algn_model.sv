`ifndef CFS_ALGN_MODEL_SV
    `define CFS_ALGN_MODEL_SV
    `uvm_analysis_imp_decl(_in_rx)
    `uvm_analysis_imp_decl(_in_tx)
    class cfs_algn_model extends uvm_component implements cfs_apb_reset_handler;

        typedef virtual cfs_algn_if cfs_algn_vif;

        cfs_algn_vif vif;
        bit first_time;
        cfs_algn_reg_block reg_block;
        cfs_algn_config  algn_config;

        // rx_fifo
        uvm_tlm_fifo#(cfs_md_item_master_mon) rx_fifo;
        uvm_tlm_fifo#(cfs_md_item_master_mon) tx_fifo;
        // buffer
        cfs_md_item_master_mon buffer[$];

        // input ports
        uvm_analysis_imp_in_rx#(cfs_md_item_master_mon , cfs_algn_model) port_in_rx;
        uvm_analysis_imp_in_tx#(cfs_md_item_master_mon , cfs_algn_model) port_in_tx;

        // output ports
        uvm_analysis_port#(cfs_md_response) port_out_rx;
        uvm_analysis_port#(cfs_md_item_master_mon) port_out_tx;
        uvm_analysis_port#(bit) port_out_irq;

        uvm_analysis_port#(cfs_algn_coverage_info) port_out_cov;

        //processes
        process process_push_to_rx_fifo_nb;
        process process_build_buffer_nb;
        process process_align_nb;
        process process_tx_ctrl_nb;

        process process_set_rx_fifo_empty;
        process process_set_rx_fifo_full;
        process process_set_tx_fifo_empty;
        process process_set_tx_fifo_full;
        
        process process_monitor_irqs;

        //events
        uvm_event tx_tr_completed;

        // irqs
        bit max_drp_cnt_irq;
        bit rx_fifo_empty_irq;
        bit rx_fifo_full_irq;
        bit tx_fifo_empty_irq;
        bit tx_fifo_full_irq;

        `uvm_component_utils(cfs_algn_model)
        function new(string name = "" , uvm_component parent);
            super.new(name , parent);
            port_in_tx      = new("port_in_tx"   , this);
            port_in_rx      = new("port_in_rx"   , this);
            port_out_rx     = new("port_out_rx"  , this);
            port_out_tx     = new("port_out_tx"  , this);
            port_out_irq    = new("port_out_irq" , this);
            port_out_cov    = new("port_out_cov" , this);
            rx_fifo         = new("rx_fifo"      , this , 8);
            tx_fifo         = new("tx_fifo"      , this , 8);
            tx_tr_completed = new("tx_tr_completed");
        endfunction

        virtual function void build_phase(uvm_phase phase);
            super.build_phase(phase);

            // create the reg_block instance
            if(reg_block == null)begin
                reg_block = cfs_algn_reg_block::type_id::create("reg_block");
                reg_block.build();
                reg_block.lock_model(); // no strucural changes after creating the register model
            end
        endfunction

        virtual function void connect_phase(uvm_phase phase);
            cfs_clr_cnt_drp_cbs cnt_drp_cbs = cfs_clr_cnt_drp_cbs::type_id::create("cnt_drp_cbs");
            super.connect_phase(phase);

            cnt_drp_cbs.cnt_drop = reg_block.STATUS.CNT_DROP;

            // add the cb custom type to the uvm_callbacks
            uvm_callbacks#(uvm_reg_field , cfs_clr_cnt_drp_cbs)::add(reg_block.CTRL.CLR ,cnt_drp_cbs);
        endfunction

        //kill_process
        /*
            this function is used to kill any running process
        */
        virtual function void kill_process(ref process running_process);
            if(running_process != null)begin
                running_process.kill();
                running_process = null;    
            end
            
        endfunction

        virtual function void kill_process_set_rx_fifo_empty();
            fork
                begin
                    uvm_wait_for_nba_region();
                    kill_process(process_set_rx_fifo_empty);    
                end
                    
            join_none
            
        endfunction

        virtual function void kill_process_set_rx_fifo_full();
            fork
                begin
            
                    uvm_wait_for_nba_region();
                    kill_process(process_set_rx_fifo_full);
                    
                end   
                
            join_none
            
        endfunction

        virtual function void kill_process_set_tx_fifo_empty();

            fork
                begin
                    uvm_wait_for_nba_region();

                    kill_process(process_set_tx_fifo_empty);
                   
                end
            join_none

           

        endfunction

        virtual function void kill_process_set_tx_fifo_full();
            fork
                begin
                   
                    uvm_wait_for_nba_region();
                    kill_process(process_set_tx_fifo_full);

                end
            join_none
        endfunction

        virtual function void handle_reset(uvm_phase phase);
            reg_block.reset("HARD");

            kill_process(process_push_to_rx_fifo_nb);
            kill_process(process_build_buffer_nb);
            kill_process(process_align_nb);
            kill_process(process_tx_ctrl_nb);

            kill_process(process_set_rx_fifo_empty);
            kill_process(process_set_rx_fifo_full);
            kill_process(process_set_tx_fifo_empty);
            kill_process(process_set_tx_fifo_full);

            kill_process(process_monitor_irqs);

            tx_tr_completed.reset();

            rx_fifo.flush();
            tx_fifo.flush();
            buffer = {};

            max_drp_cnt_irq   = 0;
            rx_fifo_empty_irq = 0;
            rx_fifo_full_irq  = 0;
            tx_fifo_empty_irq = 0;
            tx_fifo_full_irq  = 0;

            monitor_irqs_nb();
            build_buffer_nb();
            align_nb();
            tx_ctrl_nb();
        endfunction

        virtual function bit is_empty();
            if(rx_fifo.used != 0)begin
                return 0;
            end
            if(tx_fifo.used != 0)begin
                return 0;
            end
            if(buffer.size() != 0)begin
                return 0;
            end
            return 1;
        endfunction

        // get_expected response function 
        /*
            this function is taking an input md_item_master_mon from the rx agent monitor 
            then evaluate the corresponding response 
        */
        virtual function cfs_md_response get_exp_response(cfs_md_item_master_mon item);

            if(item.data.size() == 0)begin
                return CFS_MD_ERR;
            end

            if(item.data.size() + item.offset > (algn_config.get_algn_data_width() / 8) )begin
                return CFS_MD_ERR;
            end

            if(((algn_config.get_algn_data_width() / 8) + item.offset) % item.data.size() != 0 )begin
                return CFS_MD_ERR;
            end

            return CFS_MD_OK;

        endfunction

        // inc_drp_cnt function
        /*
            this function is used to increment the STATUS.CNT_DROP after each illegal MD transfer
            if the register value reached the it max then the set_max_drp_irq function will be called 
        */
        virtual function void inc_drp_cnt();
            uvm_reg_data_t data = reg_block.STATUS.CNT_DROP.get_mirrored_value();
            if(data < 255) begin
                void'(reg_block.STATUS.CNT_DROP.predict(data+1)); 
                `uvm_info("INC_DROP_CNT" , $sformatf("the STATUS.CNT_DROP has been increamented to value %0d " , reg_block.STATUS.CNT_DROP.get_mirrored_value())  , UVM_LOW) 
                if(reg_block.STATUS.CNT_DROP.get_mirrored_value() == 255 )begin
                    set_max_drp_irq();
                end
            end     
           
        endfunction

        // set_max_drp_irq
        /*
            this function is used for setting the IRQ.MAX_DROP register to one if the corresponds irqen register is written to one by the firmware
        */
        virtual function void set_max_drp_irq();
            void'(reg_block.IRQ.MAX_DROP.predict(1'b1));
            if(reg_block.IRQEN.MAX_DROP.get_mirrored_value() == 1'b1)begin
                //port_out_irq.write(1'b1);
                max_drp_cnt_irq = 1'b1;
            end

            //reg_block.IRQ.MAX_DROP.predict(1'b0);
        endfunction

        // sync_push_to_rx_fifo
        /*
            this task is used to sync the push to rx_fifo operation 
            with the one in the dut within some timer limit
        */
        virtual task sync_push_to_rx_fifo();
            vif = algn_config.get_vif();
            `uvm_info("sync_to_rx_fifo " , "entered the task" , UVM_LOW)

            fork
                begin
                    fork
                        begin
                            //`uvm_info("SYNC_PUSH_TO_RX_FIFO" , $sformatf("the push to rx_fifo is synced with the dut one") , UVM_LOW)
                            @(posedge vif.clk iff vif.rx_fifo_push);
                        end

                        begin
                            repeat(10)begin
                                uvm_reg_data_t rx_lvl = reg_block.STATUS.RX_LVL.get_mirrored_value();
                                //`uvm_info("SYNC_PUSH_TO_RX_FIFO" , $sformatf("the rx_lvl is %0d and the rx_fifo size is %0d" , rx_lvl , rx_fifo.size()) , UVM_LOW)
                                @(posedge vif.clk iff(rx_lvl < rx_fifo.size()));
                               
                            end

                            `uvm_warning("rx_fifo_push_sync" , "the push to rx fifo isn't synced with the dut one")
                        end
                    join_any

                    disable fork;
                end
            join
            
        endtask

        // push_to_rx_fifo
        /*
            this task is used to push new item to the rx_fifo 
        */
        virtual task push_to_rx_fifo(cfs_md_item_master_mon item);

            sync_push_to_rx_fifo();
            rx_fifo.put(item);

            kill_process_set_rx_fifo_empty();

            inc_rx_lvl();
            `uvm_info("PUSH_TO_RX_FIFO" , $sformatf("the item with data size %0d has been pushed to the rx_fifo and current rx_lvl  is %0d" , item.data.size() , reg_block.STATUS.RX_LVL.get_mirrored_value()) , UVM_LOW)
            port_out_rx.write(CFS_MD_OK);
        endtask

        // push_to_rx_fifo_nb
        /*
            this is the function that wrapp the push_to_rx_fifo into fork_join_none to be able to call it
            in the write_in_rx function
        */
        virtual function void push_to_rx_fifo_nb(cfs_md_item_master_mon item);
            if(process_push_to_rx_fifo_nb != null)begin
                `uvm_fatal("ALG_ISSUE" , "can't run more than one push_to_rx_fifo process at a time")
            end
            fork
                begin
                    process_push_to_rx_fifo_nb = process::self();

                    push_to_rx_fifo(item);
                    
                    process_push_to_rx_fifo_nb = null;
                end
            join_none
        endfunction


        // sync_push_to_rx_fifo
        /*
            this task is used to sync the push to rx_fifo operation 
            with the one in the dut within some timer limit
        */
        virtual task sync_push_to_tx_fifo();
            vif = algn_config.get_vif();

            fork
                begin
                    fork
                        begin
                            @(posedge vif.clk iff vif.tx_fifo_push);
                        end

                        begin
                            repeat(10)begin
                                uvm_reg_data_t tx_lvl = reg_block.STATUS.TX_LVL.get_mirrored_value() ;
                                @(posedge vif.clk iff( tx_lvl < tx_fifo.size()));
                            end

                            `uvm_warning("tx_fifo_push_sync" , "the push to tx fifo isn't synced with the dut one")
                        end
                    join_any

                    disable fork;
                end
            join
            
        endtask


        virtual task push_to_tx_fifo(cfs_md_item_master_mon item);
            sync_push_to_tx_fifo();
            tx_fifo.put(item);
            kill_process_set_tx_fifo_empty();
            incr_tx_lvl();
            `uvm_info(get_type_name() , $sformatf("the item with data size %0d has been pushed to the tx_fifo" , item.data.size()) , UVM_LOW)
        endtask

        // split
        /*
            this function is used to split the buffer item based on the number of bytes need from the align logic 
            to do the alignment
        */
        virtual function void split(int unsigned num_bytes , cfs_md_item_master_mon item , ref cfs_md_item_master_mon items[$]);
            if(num_bytes == 0 || num_bytes >= item.data.size())begin
                `uvm_fatal("ALG_ISSUE" , "can't split item with number of bytes >= the actual item data size")
            end
            for(int i = 0 ; i < 2 ; i++)begin
                cfs_md_item_master_mon splitted_item = cfs_md_item_master_mon::type_id::create("splitted_item");
                if(i == 0)begin
                    splitted_item.offset = item.offset;
                    for(int j = 0 ; j < num_bytes ; j++)begin
                        splitted_item.data.push_back(item.data[j]); 
                    end
                end
                else begin
                    splitted_item.offset = item.offset + num_bytes;
                    for(int j = num_bytes ; j < item.data.size() ; j++)begin
                        splitted_item.data.push_back(item.data[j]); 
                    end
                end
                splitted_item.prev_item_delay  = item.prev_item_delay;
                splitted_item.response         = item.response;
                items.push_back(splitted_item); 
            end
        endfunction

        // align
        /*
            this task is used to get items from the buffer and align the data 
        */
        
        virtual task align();
            vif = algn_config.get_vif();
            forever begin
                uvm_wait_for_nba_region();
                if ((buffer.size() > 0) && (buffer.sum() with (item.data.size())) >= reg_block.CTRL.SIZE.get_mirrored_value()) begin
                    while ((buffer.size() > 0) &&(buffer.sum() with (item.data.size())) >= reg_block.CTRL.SIZE.get_mirrored_value()) begin
                            cfs_md_item_master_mon tx_item = cfs_md_item_master_mon::type_id::create("tx_item");
                            cfs_algn_coverage_info info = cfs_algn_coverage_info::type_id::create("info");
                            cfs_md_item_master_mon buffer_item;
                            while (tx_item.data.size() != reg_block.CTRL.SIZE.get_mirrored_value()) begin
                                `uvm_info("ALIGN_DEBUG",$sformatf("buffer_size=%0d total_bytes=%0d ctrl_size=%0d",buffer.size(),(buffer.sum() with (item.data.size())),
                                reg_block.CTRL.SIZE.get_mirrored_value()),
                                UVM_LOW)
                                buffer_item = buffer.pop_front();
                                if(buffer_item.data.size() + tx_item.data.size() <= reg_block.CTRL.SIZE.get_mirrored_value())begin
                                    foreach (buffer_item.data[i]) begin
                                        tx_item.data.push_back(buffer_item.data[i]);
                                    end
                                    if(tx_item.data.size() == reg_block.CTRL.SIZE.get_mirrored_value())begin
                                        tx_item.offset = reg_block.CTRL.OFFSET.get_mirrored_value();
                                        push_to_tx_fifo(tx_item);
                                    end
                                end
                                else begin
                                    int unsigned num_bytes = reg_block.CTRL.SIZE.get_mirrored_value() - tx_item.data.size();
                                    cfs_md_item_master_mon items[$];
                                    // collecting the coverage info item
                                    info.item_size   = buffer_item.data.size();
                                    info.item_offset = buffer_item.offset;
                                    info.ctrl_size   = reg_block.CTRL.SIZE.get_mirrored_value();
                                    info.ctrl_offset = reg_block.CTRL.OFFSET.get_mirrored_value();
                                    info.num_bytes   = num_bytes;

                                    split(num_bytes , buffer_item , items);
                                    buffer.push_front(items[1]);
                                    buffer.push_front(items[0]);
                                    // populate the coverage info to the coverage component 
                                    port_out_cov.write(info);
                                end
                        end
                    end
                end   
            else begin
                @(posedge vif.clk);
            end
            end
        endtask

        // align_nb 
        virtual function void align_nb();
            if(process_align_nb != null)begin
                `uvm_fatal("ALG_ISSUE" , "we can't start more than one instaces of the align process at a time")
            end
            fork
                begin
                    process_align_nb = process::self();
                    align();
                    process_align_nb = null;
                end
            join_none

        endfunction
        
        // tx_ctrl
        /*
            this task is continously pop the tx_fifo and write the port_out_tx and wait the event to be triggered 
            indicating the end of tx md transaciton
        */
        virtual task tx_ctrl();
            forever begin
                cfs_md_item_master_mon item;
                pop_from_tx_fifo(item);
                port_out_tx.write(item);
                tx_tr_completed.wait_trigger();
            end
        endtask

        // tx_ctrl_nb 
        /*
            this is a wrapper function of the tx_ctrl task
        */
        virtual function void tx_ctrl_nb();
            if(process_tx_ctrl_nb != null)begin
                `uvm_fatal("ALG_ISSUE" , "we can't have more than one tx_ctrl_nb process at a time")
            end
            fork
                begin
                    process_tx_ctrl_nb = process::self();

                    tx_ctrl();

                    process_tx_ctrl_nb = null;
                end
            join_none
        endfunction

        
        // sync_pop_from_rx_fifo
        /*
            this task is used to sync the pop from rx_fifo operation 
            with the one in the dut within some timer limit
        */
        virtual task sync_pop_from_rx_fifo();
            vif = algn_config.get_vif();

            fork
                begin
                    fork
                        begin
                            @(posedge vif.clk iff vif.rx_fifo_pop);
                        end

                        begin
                            repeat(10)begin
                                uvm_reg_data_t rx_lvl = reg_block.STATUS.RX_LVL.get_mirrored_value();
                                uvm_reg_data_t tx_lvl = reg_block.STATUS.TX_LVL.get_mirrored_value();
                                @(posedge vif.clk iff ( rx_lvl > 0 && tx_lvl < tx_fifo.size()));
                            end

                            `uvm_warning("rx_fifo_pop_sync" , "the pop from rx fifo isn't synced with the dut one")
                        end
                    join_any

                    disable fork;
                end
            join
            
        endtask

        //pop_from_rx_fifo
        /*
            this task is used to pop from the rx_fifo via get() task
            call dcr_rx_fifo
        */
        virtual task pop_from_rx_fifo(ref cfs_md_item_master_mon item);
            sync_pop_from_rx_fifo();
            rx_fifo.get(item);

            kill_process_set_rx_fifo_full();

            dcr_rx_lvl();
        endtask

         // sync_pop_from_rx_fifo
        /*
            this task is used to sync the pop from rx_fifo operation 
            with the one in the dut within some timer limit
        */
        virtual task sync_pop_from_tx_fifo();
            vif = algn_config.get_vif();

            fork
                begin
                    fork
                        begin
                            @(posedge vif.clk iff vif.tx_fifo_pop);
                        end

                        begin
                            repeat(200)begin
                                uvm_reg_data_t tx_lvl = reg_block.STATUS.TX_LVL.get_mirrored_value();
                                @(posedge vif.clk iff(tx_lvl > 0 ));
                            end

                            `uvm_warning("tx_fifo_pop_sync" , "the pop from tx fifo isn't synced with the dut one")
                        end
                    join_any

                    disable fork;
                end
            join
            
        endtask
        

        // pop_from_tx_fifo
        /*
            this task is used to pop items from the tx_fifo
            and call the dcr_tx_lvl
        */
        virtual task pop_from_tx_fifo(output cfs_md_item_master_mon item);
            sync_pop_from_tx_fifo();
            tx_fifo.get(item);
            kill_process_set_tx_fifo_full();
            dcr_tx_lvl();
            `uvm_info(get_type_name() , $sformatf("there is a pop from the tx_fifo and the current tx_lvl : %0d , item :%0s" , reg_block.STATUS.TX_LVL.get_mirrored_value() , item.convert2string()) , UVM_LOW)
        endtask

        // build_buffer 
        /*
            this task is used to pop from the rx_fifo via the pop_from_rx_fifo task when 
            the CTRL.SIZE > item.data.size()

            and push this item into the buffer

            * if the popping condition is not fulfield we must wait a clock cycle to recheck*
        */
        virtual task build_buffer();
            vif = algn_config.get_vif();
            forever begin
                if(buffer.size() == 0 || ( buffer.sum()with(item.data.size())) <= reg_block.CTRL.SIZE.get_mirrored_value())begin
                    cfs_md_item_master_mon item;
                    pop_from_rx_fifo(item);
                    buffer.push_back(item);
                    `uvm_info("build_buffer" , $sformatf("the item with data size %0d has been pushed to the buffer" , item.data.size()) , UVM_LOW)
                end
                else begin
                    @(posedge vif.clk);
                end
            end

        endtask

        // build_buffer_nb
        /*
            this funciton wrap the build_buffer task into fork-join_none
            to be able to call it in the end of the reset_handle function 

        */
        virtual function void build_buffer_nb();
             if(process_build_buffer_nb != null)begin
                `uvm_fatal("ALG_ISSUE" , "can't run more than one build_buffer process at a time")
            end
            fork
                begin
                    process_build_buffer_nb = process::self();

                    build_buffer();
                
                    process_build_buffer_nb = null;
                end
            join_none
        endfunction

        // inc_rx_lvl
        /*
            this task to increament the STATUS.RX_LVL field upon each sucessful push to rx_fifo operation
        */
        virtual function void inc_rx_lvl();
            uvm_reg_data_t data = reg_block.STATUS.RX_LVL.get_mirrored_value();
            void'(reg_block.STATUS.RX_LVL.predict(data + 1));
            `uvm_info(get_type_name() , $sformatf("the STATUS.RX_LVL has been increamented to value %0d " , reg_block.STATUS.RX_LVL.get_mirrored_value())  , UVM_LOW)
            if(reg_block.STATUS.RX_LVL.get_mirrored_value() == rx_fifo.size())begin
                set_rx_fifo_full();
                `uvm_info(get_type_name() , $sformatf("the rx_fifo is full and the STATUS.RX_LVL is %0d and the irq.rx_fifo_full is set to %0d" ,  reg_block.STATUS.RX_LVL.get_mirrored_value() , reg_block.IRQ.RX_FIFO_FULL.get_mirrored_value())   , UVM_LOW)
                
            end
        endfunction
        
        //dcr_rx_lvl
        /*
            this function is used to decreament the STATUS.RX_LVL upon every successful pop from rx_fifo
            call the set_rx_fifo_empty if the number of entries inside the rx_fifo reaches 0
        */
        virtual function void dcr_rx_lvl();
            uvm_reg_data_t data = reg_block.STATUS.RX_LVL.get_mirrored_value();
            void'(reg_block.STATUS.RX_LVL.predict(data - 1));
            `uvm_info(get_type_name() , $sformatf("there is a pop from the rx fifo and the current rx_lvl is %0d" ,reg_block.STATUS.RX_LVL.get_mirrored_value() ) , UVM_LOW)
            if(reg_block.STATUS.RX_LVL.get_mirrored_value() == 0)begin
                set_rx_fifo_empty();
            end
        endfunction

        // incr_tx_lvl 
        /*
            this function is used to incr. the STATUS.TX_LVL field upon each successful pushing to the tx_fifo
            call the set_tx_fifo_full if the number of entries inside the tx_fifo reaches the max size

        */
        virtual function void incr_tx_lvl();
            uvm_reg_data_t data = reg_block.STATUS.TX_LVL.get_mirrored_value();
            void'(reg_block.STATUS.TX_LVL.predict(data + 1));
            if(reg_block.STATUS.TX_LVL.get_mirrored_value() == tx_fifo.size())begin
                set_tx_fifo_full();
            end

        endfunction

        // dcr_tx_lvl
        /*
            this function is used to decreament the value of the STATUS.TX_LVL upon each sucessful pop from the tx_fifo
            and call the set_tx_fifo_empty if the value of the STATUS.TX_LVL reaches 0
        */
        virtual function void dcr_tx_lvl();
            uvm_reg_data_t data = reg_block.STATUS.TX_LVL.get_mirrored_value();
            void'(reg_block.STATUS.TX_LVL.predict(data - 1));
            if(reg_block.STATUS.TX_LVL.get_mirrored_value() == 0)begin
                set_tx_fifo_empty();
            end
        endfunction



        // set rx_fifo_full 
        /*
            this function is to set the IRQ.RX_FIFO_FULL and write the port_out_irq if the corr. irqen flag is set
        */
        virtual function void set_rx_fifo_full();
            fork
                begin
                    process_set_rx_fifo_full = process::self();

                    repeat(2)begin
                        uvm_wait_for_nba_region();
                    end

                    void'(reg_block.IRQ.RX_FIFO_FULL.predict(1'b1));

                    if(reg_block.IRQEN.RX_FIFO_FULL.get_mirrored_value() == 1'b1)begin
                        //port_out_irq.write(1'b1);
                        rx_fifo_full_irq = 1'b1;
                        `uvm_info("RX_FIFO_FULL" , $sformatf("the rx_fifo is full and the STATUS.RX_LVL is %0d and the irq.rx_fifo_full is set to %0d" ,  reg_block.STATUS.RX_LVL.get_mirrored_value() , reg_block.IRQ.RX_FIFO_FULL.get_mirrored_value())   , UVM_LOW)
                    end

                     process_set_rx_fifo_full = null;
                end
            join_none
            
        endfunction

        //set_rx_fifo_empty
        /*
            this function is used to set the IRQ.RX_FIFO_EMPTY field to 1 
            and write to the port_out_irq 
        */
        virtual function void set_rx_fifo_empty();
            fork
                begin
                    process_set_rx_fifo_empty = process::self();

                    repeat(2)begin
                        uvm_wait_for_nba_region();
                    end
                    
                    void'(reg_block.IRQ.RX_FIFO_EMPTY.predict(1'b1));

                    if(reg_block.IRQEN.RX_FIFO_EMPTY.get_mirrored_value() == 1)begin
                        //port_out_irq.write(1);
                        rx_fifo_empty_irq = 1'b1;
                        `uvm_info("RX_FIFO_EMPTY" , $sformatf("the rx_fifo is empty and the STATUS.RX_LVL is %0d and the irq.rx_fifo_empty is set to %0d" ,  reg_block.STATUS.RX_LVL.get_mirrored_value() , reg_block.IRQ.RX_FIFO_EMPTY.get_mirrored_value())   , UVM_LOW)
                    end
                    process_set_rx_fifo_empty = null;
                end
            join_none     
        endfunction

        // set_tx_fifo_full
        /*
            this function is used to set the IRQ.TX_FIFO_FULL field to 1 
            and write to the port_out_irq 
        */
        virtual function void set_tx_fifo_full();
            fork
                begin
                    process_set_tx_fifo_full = process::self();

                    repeat(2)begin
                        uvm_wait_for_nba_region();
                    end

                    void'(reg_block.IRQ.TX_FIFO_FULL.predict(1'b1));
                    if(reg_block.IRQEN.TX_FIFO_FULL.get_mirrored_value() == 1'b1)begin
                        //port_out_irq.write(1'b1);
                        tx_fifo_full_irq = 1'b1;
                        `uvm_info("TX_FIFO_FULL" , $sformatf("the tx_fifo is full and the STATUS.TX_LVL is %0d and the irq.tx_fifo_full is set to %0d" ,  reg_block.STATUS.TX_LVL.get_mirrored_value() , reg_block.IRQ.TX_FIFO_FULL.get_mirrored_value())   , UVM_LOW)
                    end

                    process_set_tx_fifo_full = null;
                end 
            join_none
            
        endfunction

        //set_tx_fifo_empty
        /*
            this function is used to set the IRQ.TX_FIFO_EMPTY field 
            and write the port_out_irq
        */
        virtual function void set_tx_fifo_empty();
            fork
                begin
                    process_set_tx_fifo_empty = process::self();

                    repeat(2)begin
                        uvm_wait_for_nba_region();
                    end

                    void'(reg_block.IRQ.TX_FIFO_EMPTY.predict(1'b1));
                    if(reg_block.IRQEN.TX_FIFO_EMPTY.get_mirrored_value())begin
                        //port_out_irq.write(1'b1);
                        tx_fifo_empty_irq = 1'b1;
                        `uvm_info("TX_FIFO_EMPTY" , $sformatf("the tx_fifo is empty and the STATUS.TX_LVL is %0d and the irq.tx_fifo_empty is set to %0d" ,  reg_block.STATUS.TX_LVL.get_mirrored_value() , reg_block.IRQ.TX_FIFO_EMPTY.get_mirrored_value())   , UVM_LOW)
                    end

                    process_set_tx_fifo_empty = null;
                end
            join_none
        endfunction

        // monitor_irqs 
        /*
            this task is used to monitor all the irqs variable and the write to the port_out_irq if at least one irq is hot 

        */
        virtual task monitor_irqs();
            vif = algn_config.get_vif();
            forever begin
                @(negedge vif.clk);
                if(|{max_drp_cnt_irq , rx_fifo_empty_irq , rx_fifo_full_irq , tx_fifo_empty_irq , tx_fifo_full_irq} && first_time)begin
                    port_out_irq.write(1'b1);
                    max_drp_cnt_irq   = 0;
                    rx_fifo_empty_irq = 0;
                    rx_fifo_full_irq  = 0;
                    tx_fifo_empty_irq = 0;
                    tx_fifo_full_irq  = 0;
                end
                
            end
        endtask

        virtual function void monitor_irqs_nb();
            if(process_monitor_irqs != null)begin
                `uvm_fatal("ALG_ISSUE" , "we can't hve more than one running monitor_irqs instance at a time")
            end
            fork
                begin
                    process_monitor_irqs = process::self();

                    monitor_irqs();

                    process_monitor_irqs = null;    
                end
                
            join_none
        endfunction

        virtual function void write_in_rx(cfs_md_item_master_mon item);
            cfs_md_response exp_response;
            if(item.is_active_mon())begin
                exp_response = get_exp_response(item);
                case (exp_response)
                    CFS_MD_ERR: begin
                        inc_drp_cnt();
                        port_out_rx.write(exp_response);
                    end

                    CFS_MD_OK: begin
                        push_to_rx_fifo_nb(item);
                        //port_out_rx.write(exp_response);
                    end
                endcase
                
            end
                
        endfunction

        virtual function void write_in_tx(cfs_md_item_master_mon item);
            if(!item.is_active_mon())begin
                tx_tr_completed.trigger();
            end
                
        endfunction
    endclass
`endif