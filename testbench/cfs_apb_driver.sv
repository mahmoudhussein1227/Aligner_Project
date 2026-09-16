`ifndef CFS_APB_DRIVER_SV
    `define CFS_APB_DRIVER_SV

    class cfs_apb_driver extends uvm_driver #(cfs_apb_item_drv) implements cfs_apb_reset_handler;

        cfs_apb_item_drv item;
        cfs_apb_agent_config agent_config;
        cfs_apb_vif vif;

        // drive_transactions process handle
        process process_drive_transactions;

        `uvm_component_utils(cfs_apb_driver)

        function new(string name = "cfs_apb_driver", uvm_component parent = null);
            super.new(name, parent);
        endfunction

        virtual task drive_transaction(cfs_apb_item_drv item);
            vif = agent_config.get_vif();
            seq_item_port.get_next_item(item);
                `uvm_info("APB_ITEM_START ", item.convert2string(), UVM_LOW)
                
                for(int i = 0 ; i<item.pre_drv_delay ; i++) begin
                    @(posedge vif.clk);
                end
                
                vif.psel  <= 1'b1;
                vif.paddr <= item.addr;
                if(item.dir == CFS_APB_WRITE)
                    vif.pwdata <= item.data;
                vif.pwrite <= bit'(item.dir);

                @(posedge vif.clk);
                vif.penable <= 1'b1;

                while (vif.pready !== 1'b1) begin
                    @(posedge vif.clk);
                end

                vif.psel    <= 0;
                vif.paddr   <= 0;
                vif.pwdata  <= 0;
                vif.pwrite  <= 0;
                vif.penable <= 0;

                //@(posedge vif.clk);
                // guard of 1 clock cycle after transaction is completed if the post_drv_delay not supported
                for(int i = 0 ; i<item.post_drv_delay ; i++) begin
                    @(posedge vif.clk);
                end
                

            seq_item_port.item_done();
        endtask

        virtual task drive_transactions();
            fork begin
                    process_drive_transactions = process::self();
                    forever begin
                        item = cfs_apb_item_drv::type_id::create("item");
                        drive_transaction(item);
                    end  
                end 
            join
             
        endtask

        virtual task run_phase(uvm_phase phase);
            super.run_phase(phase);
            forever begin
                wait_reset_end();
                drive_transactions();    
            end
            

        endtask

        virtual task wait_reset_end();
            agent_config.wait_reset_end();
        endtask

        virtual function void handle_reset(uvm_phase phase);
            vif = agent_config.get_vif();

            if(process_drive_transactions != null)begin
                process_drive_transactions.kill();
                process_drive_transactions = null;
            end
            // initial conditions 
            vif.psel    <= 0;
            vif.paddr   <= 0;
            vif.pwdata  <= 0;
            vif.pwrite  <= 0;
            vif.penable <= 0;

        endfunction 

    endclass

`endif
