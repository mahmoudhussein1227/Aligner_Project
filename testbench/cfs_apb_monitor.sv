`ifndef CFS_APB_MONITOR_SV
    `define CFS_APB_MONITOR_SV

    class cfs_apb_monitor extends uvm_monitor implements cfs_apb_reset_handler;
        cfs_apb_item_mon item;
        cfs_apb_vif vif;
        cfs_apb_agent_config agent_config;
        uvm_analysis_port#(cfs_apb_item_mon) output_port;
        // collect_transactions process handle
        process process_collect_transactions;

        `uvm_component_utils(cfs_apb_monitor)
        function new(string name = "" , uvm_component parent);
            super.new(name , parent);
            output_port = new("output_port" , this);
        endfunction

        // collect transaction
        virtual task collect_transaction(cfs_apb_item_mon item);
            vif = agent_config.get_vif();

            while (vif.psel !== 1'b1) begin
                @(posedge vif.clk);
                item.prev_item_delay++;
            end
            item.length = 1;
            item.dir = cfs_apb_dir'(vif.pwrite);
            item.addr = vif.paddr;

            if(item.dir == CFS_APB_WRITE) begin
               item.data = vif.pwdata;
            end

            while (vif.pready !== 1'b1) begin
                @(posedge vif.clk);
                item.length++;
            end
            item.response = cfs_apb_response'(vif.pslverr);
            
            if(item.dir == CFS_APB_READ) begin
                item.data = vif.prdata;
            end

            `uvm_info("APB_ITEM_START" ,item.convert2string() , UVM_LOW)
            output_port.write(item);

            @(posedge vif.clk);

            

           
        endtask

        // collect transactions
        virtual task collect_transactions();
            fork
                begin
                    process_collect_transactions = process::self();
                    forever begin
                        item = cfs_apb_item_mon::type_id::create("item");
                        collect_transaction(item);
                    end
                end
            join
            
        endtask

        virtual task wait_reset_end();
            agent_config.wait_reset_end();
        endtask

        // run_phase
        virtual task run_phase(uvm_phase phase);
            super.run_phase(phase);
            forever begin
                wait_reset_end();
                 collect_transactions();
            end     
        endtask

        virtual function void handle_reset(uvm_phase phase);
            if(process_collect_transactions != null)begin
                process_collect_transactions.kill();
                process_collect_transactions = null;
            end     
        endfunction

    endclass

`endif