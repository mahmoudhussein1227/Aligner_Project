`ifndef CFS_APB_AGENT_CONFIG_SV
    `define CFS_APB_AGENT_CONFIG_SV

    class cfs_apb_agent_config extends uvm_component;
        `uvm_component_utils(cfs_apb_agent_config)

        protected uvm_active_passive_enum is_active;
        protected bit                     has_coverage;
        protected bit                     has_checks;
        protected cfs_apb_vif             vif;

        function new(string name = "cfs_apb_agent_config", uvm_component parent = null);
            super.new(name, parent);
            is_active = UVM_ACTIVE;
            has_coverage = 1'b1;
            has_checks = 1'b1;
        endfunction

        // is_active getter and setter
        virtual function uvm_active_passive_enum get_is_active();
            return is_active;
        endfunction

        virtual function void set_is_active(uvm_active_passive_enum is_active);
            this.is_active = is_active;
        endfunction

        // has_coverage getter and setter
        virtual function bit get_has_coverage();
            return has_coverage;
        endfunction

        virtual function void set_has_coverage(bit has_coverage);
            this.has_coverage = has_coverage;
        endfunction

        // vif getter and setter
        virtual function cfs_apb_vif get_vif();
            return vif;
        endfunction

        virtual function void set_vif(cfs_apb_vif vif);
            this.vif = vif;
        endfunction

        virtual function bit get_has_checks();
            return has_checks;
        endfunction

        virtual function void set_has_checks(bit value);
            has_checks = value;
        endfunction

        // check vif in start_of_simulation_phase
        virtual function void start_of_simulation_phase(uvm_phase phase);
            super.start_of_simulation_phase(phase);
            if (vif == null) begin
                `uvm_fatal(get_type_name(), "Virtual interface (vif) is not set!")
            end
            else begin
                `uvm_info(get_type_name(), "Virtual interface (vif) is set correctly", UVM_LOW)
            end
        endfunction

        virtual task wait_reset_start();
            if(vif.preset_n !== 0)begin
                @(negedge vif.preset_n);
            end
        endtask

        virtual task wait_reset_end();
            while (vif.preset_n == 0) begin
                @(posedge vif.clk);
            end
        endtask

        virtual task run_phase(uvm_phase phase);
            super.run_phase(phase);
            forever begin
                @(vif.has_checks)
                if(vif.has_checks !== has_checks)begin
                    `uvm_fatal({get_type_name() , " ALGORITHM_ISSUE"} , "has checks value is accessed outside the agent config component")
                
                end
            end
        endtask

    endclass

`endif
