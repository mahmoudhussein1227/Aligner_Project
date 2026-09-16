`ifndef CFS_APB_AGENT_SV
    `define CFS_APB_AGENT_SV

    class cfs_apb_agent extends uvm_agent implements cfs_apb_reset_handler;

        cfs_apb_vif          vif;
        cfs_apb_agent_config agent_config;
        cfs_apb_sequencer    sequencer;
        cfs_apb_driver       driver;
        cfs_apb_monitor     monitor;
        cfs_apb_coverage    coverage;

        `uvm_component_utils(cfs_apb_agent)

        function new(string name = "cfs_apb_agent", uvm_component parent = null);
            super.new(name, parent);
        endfunction

        virtual function void build_phase(uvm_phase phase);
            super.build_phase(phase);

            agent_config = cfs_apb_agent_config::type_id::create("agent_config", this);

            if (agent_config.get_is_active() == UVM_ACTIVE) begin
                sequencer = cfs_apb_sequencer::type_id::create("sequencer", this);
                driver    = cfs_apb_driver::type_id::create("driver", this);
            end

            monitor = cfs_apb_monitor::type_id::create("monitor" , this);
            coverage = cfs_apb_coverage::type_id::create("coverage" , this);

        endfunction

        virtual function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);

            if (!uvm_config_db#(cfs_apb_vif)::get(this, "", "vif", vif)) begin
                `uvm_fatal(get_type_name(), "Could not get virtual interface vif from uvm_config_db")
            end
            else begin
                agent_config.set_vif(vif);
            end

            // driver - sequencer connection
            if(agent_config.get_is_active() == UVM_ACTIVE)begin
                driver.seq_item_port.connect(sequencer.seq_item_export);
                driver.agent_config = agent_config;
                
            end

            monitor.agent_config = agent_config;

            coverage.agent_config = agent_config;
            monitor.output_port.connect(coverage.port_item);
        endfunction

        virtual function void handle_reset(uvm_phase phase);
            uvm_component children[$];
            cfs_apb_reset_handler reset_handler;

            get_children(children);
            foreach (children[i]) begin
                // Ensure the component implements cfs_apb_reset_handler before calling handle_reset()
                if ($cast(reset_handler, children[i])) begin
                    reset_handler.handle_reset(phase);
                end 
            end
        endfunction

        virtual task wait_reset_start();
            agent_config.wait_reset_start();
        endtask

        virtual task wait_reset_end();
            agent_config.wait_reset_end();
        endtask

        virtual task run_phase(uvm_phase phase);
            super.run_phase(phase);
            forever begin
                wait_reset_start();
                handle_reset(phase);
                wait_reset_end();
            end
        endtask

    endclass

`endif