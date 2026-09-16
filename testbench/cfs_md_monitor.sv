`ifndef CFS_MD_MONITOR_SV
    `define CFS_MD_MONITOR_SV

    class cfs_md_monitor#(int unsigned ALGN_DATA_WIDTH = 32) extends uvm_monitor implements cfs_md_reset_handler;

        typedef virtual cfs_md_if#(ALGN_DATA_WIDTH) cfs_md_vif;
        cfs_md_vif vif;
        cfs_md_agent_config#(ALGN_DATA_WIDTH) agent_config;

        process process_collect_transactions;

        uvm_analysis_port#(cfs_md_item_master_mon) output_port;

        `uvm_component_param_utils(cfs_md_monitor#(ALGN_DATA_WIDTH))
        function new(string name = "" , uvm_component parent);
            super.new(name , parent);
            output_port = new("output_port" , this);
        endfunction

        // Add this to your monitor or base test configuration
        virtual function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            // Enforce recording so begin_tr(item) processes the object
            //set_config_int(this, "*", "recording_detail", UVM_FULL); 
        endfunction

        // collect_transaction task
        virtual task collect_transaction();
            cfs_md_item_master_mon item = cfs_md_item_master_mon::type_id::create("item");
            vif = agent_config.get_vif();
            #1;
            while (vif.valid !== 1'b1) begin
                @(posedge vif.clk);
                item.prev_item_delay ++;
                #1;
            end
            // start recording the MD transaction
            //item.enable_recording(this.get_tr_stream("MD_ITEM"));
            
             // begin the transaction 
            void'(begin_tr(.tr(item) ,.stream_name("MD_ITEM")));

            item.length = 1;
            item.offset = vif.offset;
            //item.size   = vif.size;
            begin
                logic [ALGN_DATA_WIDTH - 1 : 0] temp_data;
                temp_data = vif.data >> (vif.offset * 8);
                item.data.delete();
                for (int i = 0; i < vif.size; i++) begin
                    item.data.push_back(temp_data[i*8 +: 8]);
                end
            end

            `uvm_info("MD_ITEM_START" , item.convert2string() , UVM_LOW)
        
            output_port.write(item);

            @(posedge vif.clk);

            while (vif.ready !== 1'b1) begin
                @(posedge vif.clk);
                item.length++;
            end
            item.response = cfs_md_response'(vif.err);
            end_tr(item);
            #0;
            output_port.write(item);
            
            `uvm_info("MD_ITEM_END" , item.convert2string() , UVM_LOW)
            //@(posedge vif.clk);

        endtask
        

        // collect_transactions task
        virtual task collect_transactions();
            fork
                begin
                    process_collect_transactions = process::self();
                    forever begin
                        collect_transaction();
                    end
                end
                
            join
            
        endtask

        virtual task run_phase(uvm_phase phase);
            forever begin
                fork
                    begin
                        wait_reset_end();
                        collect_transactions();

                        disable fork;
                    end 
                join
            end
        endtask

        //wait_reset_end task
        virtual task wait_reset_end();
            agent_config.wait_reset_end();
        endtask

        // handle_reset imp
        virtual function void handle_reset(uvm_phase phase);
            if(process_collect_transactions != null)begin
                process_collect_transactions.kill();
                process_collect_transactions = null;
            end
        endfunction


    endclass

`endif