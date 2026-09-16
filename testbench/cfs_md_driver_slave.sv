`ifndef CFS_MD_DRIVER_SLAVE_SV
    `define CFS_MD_DRIVER_SLAVE_SV

    class cfs_md_driver_slave#(int unsigned ALGN_DATA_WIDTH = 32) extends cfs_md_driver#(ALGN_DATA_WIDTH , cfs_md_item_slave_drv);

        `uvm_component_param_utils(cfs_md_driver_slave#(ALGN_DATA_WIDTH))

        function new (string name = "" , uvm_component parent);
            super.new(name , parent);
        endfunction

        // drive_transaction
        virtual task drive_transaction(cfs_md_item_slave_drv item);
            vif = agent_config.get_vif();

            seq_item_port.get_next_item(item);
               `uvm_info({get_type_name() , " driving"} , item.convert2string() , UVM_LOW)

                if(vif.valid !== 1'b1)begin
                    `uvm_error("ALG_ISSUE" , "no MD transaction is driven form the master driver");
                end

                vif.ready <= 0;
               

                for(int i = 0; i < item.length ; i++) begin
                    @(posedge vif.clk);
                end

                vif.ready <= 1'b1;
                vif.err   <= bit'(item.response);

                @(posedge vif.clk);

                vif.ready <=item.ready_at_end;
                vif.err   <= 0;
               
            seq_item_port.item_done();    
        endtask
        // handle_reset 
        virtual function void handle_reset(uvm_phase phase);
            vif = agent_config.get_vif();
            super.handle_reset(phase);
            // to be extended to initialize the md signals based on the master and slave aspects
            vif.ready <= agent_config.get_ready_after_reset();
            vif.err   <= 0;
        endfunction



    endclass

`endif