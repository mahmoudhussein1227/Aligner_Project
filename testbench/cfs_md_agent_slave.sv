`ifndef CFS_MD_AGENT_SLAVE_SV
    `define CFS_MD_AGENT_SLAVE_SV

    class cfs_md_agent_slave#(int unsigned ALGN_DATA_WIDTH = 32) extends cfs_md_agent#(ALGN_DATA_WIDTH , cfs_md_item_slave_drv);
        cfs_md_sequencer_slave sequencer_slave;   // correctly-typed handle

        `uvm_component_param_utils(cfs_md_agent_slave#(ALGN_DATA_WIDTH))

        function new (string name = "" , uvm_component parent);
            super.new(name , parent);
            // Factory override: agent_config will be created as slave type
            cfs_md_agent_config#(ALGN_DATA_WIDTH)::type_id::set_inst_override(
                cfs_md_agent_config_slave#(ALGN_DATA_WIDTH)::get_type(),
                "agent_config", this
            );

            cfs_md_sequencer#(cfs_md_item_slave_drv)::type_id::set_inst_override(
                cfs_md_sequencer_slave::get_type(),
                "sequencer", this
            );

            cfs_md_driver#(ALGN_DATA_WIDTH , cfs_md_item_slave_drv)::type_id::set_inst_override(
                cfs_md_driver_slave#(ALGN_DATA_WIDTH)::get_type(),
                "driver", this
            );

        endfunction


    endclass

`endif
