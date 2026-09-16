`ifndef CFS_MD_AGENT_CONFIG_SLAVE_SV
    `define CFS_MD_AGENT_CONFIG_SLAVE_SV

    class cfs_md_agent_config_slave#(int unsigned ALGN_DATA_WIDTH =32) extends cfs_md_agent_config#(ALGN_DATA_WIDTH);
        local bit ready_after_reset;
        `uvm_component_param_utils(cfs_md_agent_config_slave#(ALGN_DATA_WIDTH))

        function new (string name = "" , uvm_component parent);
            super.new(name , parent);
            ready_after_reset = 1'b1;
        endfunction

        virtual function void set_ready_after_reset(bit value);
            ready_after_reset = value;
        endfunction
         virtual function bit get_ready_after_reset();
            return ready_after_reset; 
        endfunction
        

    endclass

`endif
