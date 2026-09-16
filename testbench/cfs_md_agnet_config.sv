`ifndef CFS_MD_AGENT_CONFIG_SV
    `define CFS_MD_AGENT_CONFIG_SV

    class cfs_md_agent_config#(int unsigned ALGN_DATA_WIDTH = 32) extends uvm_component;
        // md vif handle
        typedef virtual cfs_md_if#(ALGN_DATA_WIDTH) cfs_md_vif ;

        cfs_md_vif vif;
        protected uvm_active_passive_enum is_active_env;
        bit has_checks;

        `uvm_component_param_utils(cfs_md_agent_config#(ALGN_DATA_WIDTH))

        function new(string name = "" , uvm_component parent);
            super.new(name , parent);
            is_active_env = UVM_ACTIVE;
            has_checks = 1'b1;
        endfunction

        // is_active getter and setter
        virtual function uvm_active_passive_enum get_is_active();
            return is_active_env;
        endfunction

        virtual function void set_is_active(uvm_active_passive_enum is_active_env);
            this.is_active_env = is_active_env;
        endfunction

        virtual function bit get_ready_after_reset();

        endfunction

        // vif_setter 
        virtual function void set_vif(cfs_md_vif value);
            if(vif == null)begin
                vif = value;    
            end
            else begin
                `uvm_fatal({get_type_name(), " ALG_ISSUE"} , "vif is configured only once")
            end
        endfunction

        //vif_getter
        virtual function cfs_md_vif get_vif();
            return vif;
        endfunction

        // wait_reset_start task
        virtual task wait_reset_start();
            while (vif.reset_n !== 0) begin
                @(negedge vif.reset_n);
            end
        endtask

        // wait_reset_end task
        virtual task wait_reset_end();
            while (vif.reset_n == 0) begin
                @(posedge vif.clk);
            end
        endtask

        // set has_checks function
        virtual function void set_has_checks(bit value);
            has_checks = value;
        endfunction 

        // get has_checks function
        virtual function bit get_has_checks();
            return has_checks;
        endfunction

        // run phase
        virtual task run_phase(uvm_phase phase);
            super.run_phase(phase);
            forever begin
                @(vif.has_checks);
                if(get_has_checks() != vif.has_checks)begin
                    `uvm_fatal("ALG_ISSUE" , "has_checks field must be accessed via agent_config only")
                end
            end
        endtask


    endclass

`endif

