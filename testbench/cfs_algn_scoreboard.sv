`ifndef CFS_ALGN_SCOREBOARD_SV
    `define CFS_ALGN_SCOREBOARD_SV

    `uvm_analysis_imp_decl(_in_model_tx)
    `uvm_analysis_imp_decl(_in_model_rx)
    `uvm_analysis_imp_decl(_in_model_irq)

    `uvm_analysis_imp_decl(_in_agent_tx)
    `uvm_analysis_imp_decl(_in_agent_rx)
  


    class cfs_algn_scoreboard extends uvm_component implements cfs_apb_reset_handler;
        // exp_outputs ports 
        uvm_analysis_imp_in_model_rx#(cfs_md_response , cfs_algn_scoreboard) port_in_model_rx;
        uvm_analysis_imp_in_model_tx#(cfs_md_item_master_mon , cfs_algn_scoreboard) port_in_model_tx;
        uvm_analysis_imp_in_model_irq#(bit , cfs_algn_scoreboard) port_in_model_irq;

        // dut ports 
        uvm_analysis_imp_in_agent_rx#(cfs_md_item_master_mon , cfs_algn_scoreboard) port_in_agent_rx;
        uvm_analysis_imp_in_agent_tx#(cfs_md_item_master_mon , cfs_algn_scoreboard) port_in_agent_tx;

        // env_config handel
        cfs_algn_config algn_config;

        typedef virtual cfs_algn_if cfs_algn_vif;
        //vif handle
        cfs_algn_vif vif ;

        //exp_response queue
        cfs_md_response exp_responses_queue[$];

        //exp_tx_item queue
        cfs_md_item_master_mon exp_tx_items_queue[$];

        // exp_irqs queue
        bit exp_irqs_queue[$];

        // watchdog processes handles queues
        process process_exp_responses_watchdog_queue[$];
        process process_exp_tx_items_watchdog_queue[$];
        process process_exp_irqs_watchdog_queue[$];

        process process_monitor_irq_nb;

        `uvm_component_utils(cfs_algn_scoreboard)
        function new(string name = "" , uvm_component parent);
            super.new(name , parent);
            port_in_model_rx  = new("port_in_model_rx"  , this);
            port_in_model_tx  = new("port_in_model_tx"  , this);
            port_in_model_irq = new("port_in_model_irq" , this);

            port_in_agent_rx = new("port_in_agent_rx" , this);
            port_in_agent_tx = new("port_in_agent_tx" , this);

        endfunction

        virtual function void kill_watchdog_processes (ref process p[$]);
            if(p.size() > 0)begin
                foreach (p[i]) begin
                    p[i].kill();
                    p[i] = null;
                    void'(p.pop_front());
                end
            end
        endfunction

        virtual function void handle_reset(uvm_phase phase);
            exp_responses_queue.delete();
            exp_tx_items_queue.delete();
            exp_irqs_queue.delete();
            kill_watchdog_processes(process_exp_responses_watchdog_queue);
            kill_watchdog_processes(process_exp_tx_items_watchdog_queue);
            kill_watchdog_processes(process_exp_irqs_watchdog_queue);
            if(process_monitor_irq_nb != null)begin
                process_monitor_irq_nb.kill();
                process_monitor_irq_nb = null;
            end

            monitor_irq_nb();
        endfunction


    //exp_response_watchdog 
    /*
        this task is used to start a watchdog timer for each exp_response enter the 
        exp_responses_queue 
    */
        virtual task exp_response_watchdog();
            int unsigned exp_response_thr;
            vif = algn_config.get_vif();
            exp_response_thr = algn_config.get_exp_response_thr();
            repeat(exp_response_thr)begin
                @(posedge vif.clk);
            end

            `uvm_error("TIME_OUT" , "the dut exceed the configured timer and stuck to produce a rx_response")
        endtask

    //exp_response_watchdog 
    /*
        this task is used to start a watchdog timer for each exp_tx_item enters the 
        exp_tx_items_queue 
    */
        virtual task exp_tx_item_watchdog();
            int unsigned exp_tx_item_thr;
            vif = algn_config.get_vif();
            exp_tx_item_thr = algn_config.get_exp_tx_item_thr();
            repeat(exp_tx_item_thr)begin
                @(posedge vif.clk);
            end

            `uvm_error("TIME_OUT" , "the dut exceed the configured timer and stuck to produce a tx_item")
        endtask
    // exp_irq_watchdog 
    /*
        this task is used to start the watchdog timer upon every irq enter the
        exp_irqs_queue 
    */
    virtual task exp_irq_watchdog();
        int unsigned exp_irq_thr;
        vif = algn_config.get_vif();
        exp_irq_thr = algn_config.get_exp_irq_thr();
        
        repeat(exp_irq_thr)begin
            @(posedge vif.clk);
        end

        `uvm_error("TIME_OUT" , "the dut exceed the configured timer and stuck to produce a irq")

    endtask

    //exp_response_watchdog_nb
    /*
        this function wrapp the exp_response_watchdog task in fork join_none
        and allocate the process of each exp_response watchdog
    */
    virtual function void exp_response_watchdog_nb();
        fork
            begin
                process_exp_responses_watchdog_queue.push_back(process::self());
                //`uvm_info("EXP_RESPONSE_WATCHDOG" , $sformatf("the watchdog process for the exp_response %0s is started" , exp_responses_queue[0].name()) , UVM_LOW)

                exp_response_watchdog();
            end
        join_none
    endfunction

    //exp_tx_item_watchdog_nb
    /*
        this function wrapp the exp_tx_item_watchdog task in fork join_none
        and allocate the process of each exp_tx_item watchdog
    */
    virtual function void exp_tx_item_watchdog_nb();
        fork
            begin
                process_exp_tx_items_watchdog_queue.push_back(process::self());

                exp_tx_item_watchdog();
            end
        join_none
    endfunction

    //exp_irq_watchdog_nb 
    /*
        this function wrap the exp_irq_watchdog task in fork join_none
        and allocata the timer process
    */
    virtual function void exp_irq_watchdog_nb();
        fork
            begin
                process_exp_irqs_watchdog_queue.push_back(process::self());

                exp_irq_watchdog();
            end
        join_none

    endfunction


   

    // model wrtie imp port functions
        virtual function void write_in_model_rx(cfs_md_response response);
            //`uvm_info("WRITE_IN_MODEL_RX" , $sformatf("the expected response %0s is pushed to the exp_responses_queue" , response.name()) , UVM_LOW)
            if(exp_responses_queue.size() >= 1)begin
                `uvm_fatal("ALG_ISSUE" ,"there is no way that there is a pending exp_response")
            end

            exp_responses_queue.push_back(response);

            exp_response_watchdog_nb();

        endfunction

        virtual function void write_in_model_tx(cfs_md_item_master_mon item);
            if(exp_tx_items_queue.size() >= 1)begin
                `uvm_fatal("ALG_ISSUE" ,"there is no way that there is a pending exp_tx_item")
            end
            
            exp_tx_items_queue.push_back(item);

            exp_tx_item_watchdog_nb();
        endfunction

        virtual function void write_in_model_irq(bit irq);
            if(exp_irqs_queue.size() >= 5)begin
                `uvm_fatal("ALG_ISSUE" , "there is no way to have 5 or more pending irqs")
            end

            exp_irqs_queue.push_back(irq);
            exp_irq_watchdog_nb();
        endfunction


    // dut write imp ports functions 
        virtual function void write_in_agent_rx(cfs_md_item_master_mon item);
            if(!item.is_active_mon())begin
                cfs_md_response exp_response;
                exp_response = exp_responses_queue.pop_front();
                process_exp_responses_watchdog_queue[0].kill();
                process_exp_responses_watchdog_queue[0] = null;
                void'(process_exp_responses_watchdog_queue.pop_front());

                //checking part
                if(exp_response != item.response)begin
                    `uvm_error("RESPONSE_MISSMATCH" , $sformatf("there is a mismatch in rx interface response ; expected : %0s , got : %0s" , exp_response.name() , item.response.name()))
                end
            end
           

        endfunction

        virtual function void write_in_agent_tx(cfs_md_item_master_mon item);
            if(!item.is_active_mon())begin
                cfs_md_item_master_mon exp_item;
                exp_item = exp_tx_items_queue.pop_front();
                process_exp_tx_items_watchdog_queue[0].kill();
                process_exp_tx_items_watchdog_queue[0] = null;
                void'(process_exp_tx_items_watchdog_queue.pop_front());

                //checking part
                if(item.offset != exp_item.offset || item.data != exp_item.data)begin
                    `uvm_error("TX_ITEM_MISSMATCH" , $sformatf("there is a missmatch between the dut tx_item and expected one ; exp : %0s , got %0s" , exp_item.convert2string() , item.convert2string()))
                end
            end
        endfunction

        // monitor_irq
        virtual task monitor_irq();
            bit exp_irq;
            vif = algn_config.get_vif();
            forever begin

                @(posedge vif.clk iff (vif.reset_n & vif.irq));
                `uvm_info("CATCH_IRQ" , $sformatf("the dut produced an irq at time %0t" , $time) , UVM_LOW)
                if(exp_irqs_queue.size() == 0)begin
                    `uvm_error("IRQ_MISSMATCH" , "the dut produced an irq without any expected irq")
                end
                else begin
                    exp_irq = exp_irqs_queue.pop_front();
                    process_exp_irqs_watchdog_queue[0].kill();
                    process_exp_irqs_watchdog_queue[0] = null;
                    void'(process_exp_irqs_watchdog_queue.pop_front());
                end
            end

        endtask

        // monitor_irq_nb
        virtual function void monitor_irq_nb();
            if(process_monitor_irq_nb != null)begin
                `uvm_fatal("ALG_ISSUE" , "there is no chance to run more than one monitor_irq_nb process")
            end
            fork
                begin
                    process_monitor_irq_nb = process::self();
                    monitor_irq();

                    process_monitor_irq_nb = null;
                end
            join_none
    endfunction

    endclass

    
`endif