`ifndef CFS_MD_AGENT_MASTER_SV
    `define CFS_MD_AGENT_MASTER_SV

    class cfs_md_agent_master#(int unsigned ALGN_DATA_WIDTH = 32) extends cfs_md_agent#(ALGN_DATA_WIDTH , cfs_md_item_master_drv);
        `uvm_component_param_utils(cfs_md_agent_master#(ALGN_DATA_WIDTH))

        function new (string name = "" , uvm_component parent);
            super.new(name , parent);
            // Factory override: agent_config will be created as master type
            cfs_md_agent_config#(ALGN_DATA_WIDTH)::type_id::set_inst_override(
                cfs_md_agent_config_master#(ALGN_DATA_WIDTH)::get_type(),
                "agent_config", this
            );

            cfs_md_driver#(ALGN_DATA_WIDTH , cfs_md_item_master_drv)::type_id::set_inst_override(
                cfs_md_driver_master#(ALGN_DATA_WIDTH)::get_type(),
                "driver", this
            );

            cfs_md_sequencer#(cfs_md_item_master_drv)::type_id::set_inst_override(
                cfs_md_sequencer_master::get_type(),
                "sequencer", this
            );



        endfunction
    endclass

`endif
