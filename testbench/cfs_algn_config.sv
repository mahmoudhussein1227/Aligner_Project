`ifndef CFS_ALGN_CONFIG_SV
    `define CFS_ALGN_CONFIG_SV

    class cfs_algn_config extends uvm_component;

        typedef virtual cfs_algn_if cfs_algn_vif;
        cfs_algn_vif vif;
        
        local int unsigned algn_data_width;
        local int unsigned exp_response_thr;
        local int unsigned exp_tx_item_thr;
        local int unsigned exp_irq_thr;

        local bit has_coverage;

        

        `uvm_component_utils(cfs_algn_config)

        function new(string name = "", uvm_component parent);
            super.new(name, parent);
            algn_data_width  = 32;
            exp_response_thr = 10;
            exp_tx_item_thr  = 10;
            exp_irq_thr      = 10;
            has_coverage     = 1 ;
        endfunction

        virtual function void set_algn_data_width(int unsigned value);
            algn_data_width = value;
        endfunction

        virtual function int unsigned get_algn_data_width();
            return algn_data_width;
        endfunction

        virtual function void set_vif(cfs_algn_vif value);
            vif = value;
        endfunction

        virtual function cfs_algn_vif get_vif();
            return vif;
        endfunction

        virtual function void set_exp_response_thr(int unsigned value);
            exp_response_thr = value;
        endfunction

        virtual function int unsigned get_exp_response_thr();
            return exp_response_thr;
        endfunction

        virtual function void set_exp_tx_item_thr(int unsigned value);
            exp_tx_item_thr = value;
        endfunction

        virtual function int unsigned get_exp_tx_item_thr();
            return exp_tx_item_thr;
        endfunction

        virtual function void set_exp_irq_thr(int unsigned value);
            exp_irq_thr = value;
        endfunction

        virtual function int unsigned get_exp_irq_thr();
            return exp_irq_thr;
        endfunction

        virtual function void set_has_coverage(bit value);
            has_coverage = value;
        endfunction

        virtual function bit get_has_coverage();
            return has_coverage;
        endfunction

    endclass

`endif