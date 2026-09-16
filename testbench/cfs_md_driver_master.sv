`ifndef CFS_MD_DRIVER_MASTER_SV
    `define CFS_MD_DRIVER_MASTER_SV

    class cfs_md_driver_master#(int unsigned ALGN_DATA_WIDTH = 32) extends cfs_md_driver#(ALGN_DATA_WIDTH , cfs_md_item_master_drv);

        `uvm_component_param_utils(cfs_md_driver_master#(ALGN_DATA_WIDTH))

        function new (string name = "" , uvm_component parent);
            super.new(name , parent);
        endfunction

        // drive_transaction
        virtual task drive_transaction(cfs_md_item_master_drv item);
            logic[ALGN_DATA_WIDTH - 1 : 0] data;
            vif = agent_config.get_vif();
            seq_item_port.get_next_item(item);
                `uvm_info("MD_ITEM_START" , item.convert2string() , UVM_LOW)

                for(int i = 0 ; i< item.pre_drv_delay ; i++)begin
                    @(posedge vif.clk);
                end

                vif.valid  <= 1'b1  ;
                vif.offset <= item.offset;

                data = '0;
                foreach (item.data[i]) begin
                    data[(item.offset + i)*8 +: 8] = item.data[i];
                end

                vif.data <= data;
                vif.size <= item.data.size();

                @(posedge vif.clk);

                while (vif.ready !== 1'b1) begin
                    @(posedge vif.clk);
                end

                vif.valid  <= 0;
                vif.data   <= 0;
                vif.size   <= 0;
                vif.offset <= 0;

                for(int i = 0 ; i < item.post_drv_delay ; i++)begin
                    @(posedge vif.clk);
                end

            seq_item_port.item_done();    
        endtask
        // handle_reset 
        virtual function void handle_reset(uvm_phase phase);
            super.handle_reset(phase);
            // to be extended to initialize the md signals based on the master and slave aspects
            vif = agent_config.get_vif();

            vif.valid  <= 0;
            vif.data   <= 0;
            vif.size   <= 0;
            vif.offset <= 0;
        endfunction



    endclass

`endif