`ifndef CFS_ALGN_ENV_SV
    `define CFS_ALGN_ENV_SV

    class cfs_algn_env extends uvm_env implements cfs_apb_reset_handler;

        cfs_apb_agent apb_agent;
        // md agents
        cfs_md_agent_master#(32) md_agent_master;
        cfs_md_agent_slave#(32)  md_agent_slave;
        // model handel
        cfs_algn_model model;
        // predictor handle
        cfs_apb_reg_predictor#(.BUSTYPE(cfs_apb_item_mon)) predictor;

        // algn_config handle
        cfs_algn_config algn_config;
        cfs_algn_config::cfs_algn_vif vif;

        // scoreboard handle
        cfs_algn_scoreboard scoreboard;

        // coverage handle
        cfs_algn_coverage coverage;

        //virtual sequencer handle
        cfs_algn_virtual_sequencer v_sequencer;

        `uvm_component_utils(cfs_algn_env)
        function new(string name  , uvm_component parent);
            super.new(name , parent);
        endfunction

        virtual function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            algn_config = cfs_algn_config::type_id::create( "algn_config", this);
            apb_agent = cfs_apb_agent::type_id::create("apb_agent" , this);
            md_agent_master = cfs_md_agent_master#(32)::type_id::create("md_agent_master" , this);
            md_agent_slave  = cfs_md_agent_slave#(32)::type_id::create("md_agent_slave" , this);
            model = cfs_algn_model::type_id::create("model" , this);
            predictor = cfs_apb_reg_predictor#(.BUSTYPE(cfs_apb_item_mon))::type_id::create("predictor" , this);
            scoreboard = cfs_algn_scoreboard::type_id::create("scoreboard" , this);
            coverage = cfs_algn_coverage::type_id::create("coverage" , this);
            v_sequencer = cfs_algn_virtual_sequencer::type_id::create("v_sequencer" , this);
        endfunction

        virtual function void connect_phase(uvm_phase phase);
            cfs_algn_apb_adapter adapter = cfs_algn_apb_adapter::type_id::create("adapter");
            super.connect_phase(phase);

            if (!uvm_config_db#(cfs_algn_config::cfs_algn_vif)::get(this, "", "vif", vif)) begin
                `uvm_fatal("CFS_ALGN_ENV", "Failed to get cfs_algn_if from the config database")
            end
            algn_config.set_vif(vif);
            model.algn_config = algn_config;

            // assign the address map of the predictor to the default_map of the reg_block
            predictor.map = model.reg_block.default_map; 

            // connect the adapter to the predictor adapter handel
            predictor.adapter = adapter;

            //connect the bus_in port of the predictor to the output_port of the monitor
            apb_agent.monitor.output_port.connect(predictor.bus_in);

            // set the sequencer to the apb_register map to be able to use it to send the stimlus
            model.reg_block.default_map.set_sequencer(apb_agent.sequencer , adapter );


            // model port_in_rx connection to the MD monitor
            md_agent_master.monitor.output_port.connect(model.port_in_rx);

            // model port_in_tx connection to the MD monitor
            md_agent_slave.monitor.output_port.connect(model.port_in_tx);


            // scb analysis imp port connections
            scoreboard.algn_config = algn_config;
            model.port_out_rx.connect(scoreboard.port_in_model_rx);
            model.port_out_tx.connect(scoreboard.port_in_model_tx);
            model.port_out_irq.connect(scoreboard.port_in_model_irq);

            if(algn_config.get_has_coverage()) begin
                model.port_out_cov.connect(coverage.port_in_model);
            end

            md_agent_master.monitor.output_port.connect(scoreboard.port_in_agent_rx);
            md_agent_slave.monitor.output_port.connect(scoreboard.port_in_agent_tx);
            

            // v_sequencer connections
            v_sequencer.apb_sqr = apb_agent.sequencer;
            if(!$cast(v_sequencer.rx_sqr ,  md_agent_master.sequencer ))begin
                `uvm_fatal("TYPE", "Bad cast")
            end
                
            if(!$cast(v_sequencer.tx_sqr , md_agent_slave.sequencer ))begin
                `uvm_fatal("TYPE", "Bad cast")
            end
           
            v_sequencer.model   = model;

        endfunction

        virtual task wait_reset_start();
            apb_agent.agent_config.wait_reset_start();
        endtask

        virtual task wait_reset_end();
            apb_agent.agent_config.wait_reset_end();
        endtask

        virtual task run_phase(uvm_phase phase);
            super.run_phase(phase);
            forever begin
                wait_reset_start();
                handle_reset(phase);
                wait_reset_end();    
            end
        endtask

        virtual function void handle_reset(uvm_phase phase);
            model.handle_reset(phase);
            scoreboard.handle_reset(phase);
        endfunction

    endclass

`endif