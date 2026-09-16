`ifndef CFS_MD_DRIVER_SV
    `define CFS_MD_DRIVER_SV

    class cfs_md_driver#(int unsigned ALGN_DATA_WIDTH = 32 , type ITEM_DRV = cfs_md_item_base) extends uvm_driver#(ITEM_DRV) implements cfs_md_reset_handler;

        typedef virtual cfs_md_if#(ALGN_DATA_WIDTH) cfs_md_vif;
        cfs_md_vif vif;
        cfs_md_agent_config#(ALGN_DATA_WIDTH) agent_config;
        process process_drive_transactions;

        `uvm_component_param_utils(cfs_md_driver#(ALGN_DATA_WIDTH , ITEM_DRV))

        function new (string name = "" , uvm_component parent);
            super.new(name , parent);
        endfunction

        // drive_transaction
        virtual task drive_transaction(ITEM_DRV item);

        endtask
        // drive_transactions
        virtual task drive_transactions();
            fork
                begin
                    process_drive_transactions = process::self();
                    forever begin
                        ITEM_DRV item = ITEM_DRV::type_id::create("item");
                        drive_transaction(item);
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
                drive_transactions();
            end

        endtask
        // handle_reset 
        virtual function void handle_reset(uvm_phase phase);
            // kill the drive_transactions process
            if(process_drive_transactions != null)begin
                process_drive_transactions.kill();
                process_drive_transactions = null;

            end
                
            // to be extended to initialize the md signals based on the master and slave aspects

        endfunction



    endclass

`endif