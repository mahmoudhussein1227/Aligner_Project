`ifndef CFS_MD_AGENT_SV
    `define CFS_MD_AGENT_SV

    class cfs_md_agent#(int unsigned ALGN_DATA_WIDTH = 32 , type ITEM_DRV = cfs_md_item_base) extends uvm_agent;
        typedef virtual cfs_md_if#(ALGN_DATA_WIDTH) cfs_md_vif ;
        cfs_md_vif vif;
        // agent_config handle
        cfs_md_agent_config#(ALGN_DATA_WIDTH) agent_config;
        //driver handle
        cfs_md_driver#(.ALGN_DATA_WIDTH(ALGN_DATA_WIDTH) , .ITEM_DRV(ITEM_DRV)) driver;
        //sequencer handle
        cfs_md_sequencer#(ITEM_DRV) sequencer;
        //monitor handle
        cfs_md_monitor#(ALGN_DATA_WIDTH) monitor;
        // coverage handle
        cfs_md_coverage#(ALGN_DATA_WIDTH) coverage;

        cfs_md_sequencer_slave sqr_slv;

        `uvm_component_param_utils(cfs_md_agent#(ALGN_DATA_WIDTH, ITEM_DRV))

        function new (string name = "" , uvm_component parent);
            super.new(name , parent);
        endfunction

        virtual function void build_phase(uvm_phase phase);
            super.build_phase(phase);

            agent_config = cfs_md_agent_config#(ALGN_DATA_WIDTH)::type_id::create("agent_config" , this);
            if(agent_config.get_is_active() == UVM_ACTIVE)begin
                driver    = cfs_md_driver#(.ALGN_DATA_WIDTH(ALGN_DATA_WIDTH) , .ITEM_DRV(ITEM_DRV))::type_id::create("driver" , this);
                sequencer = cfs_md_sequencer#(ITEM_DRV)::type_id::create("sequencer" , this);
            end

            monitor = cfs_md_monitor#(ALGN_DATA_WIDTH)::type_id::create("monitor" , this);
            coverage = cfs_md_coverage#(ALGN_DATA_WIDTH)::type_id::create("coverage" , this);
        endfunction

        virtual function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);

            if(uvm_config_db#(cfs_md_vif)::get(this , "" , "vif" , vif)) begin
                agent_config.set_vif(vif);
            end
            else begin
                `uvm_fatal({get_type_name() , " ALG_ISSUE"} , "the vif is not configured")
            end

            if(agent_config.get_is_active() == UVM_ACTIVE)begin
                driver.agent_config = agent_config;
                driver.seq_item_port.connect(sequencer.seq_item_export);
            end

            monitor.agent_config = agent_config;
            if($cast(sqr_slv , sequencer))
                monitor.output_port.connect(sqr_slv.port_from_mon);

            coverage.agent_config = agent_config;
            monitor.output_port.connect(coverage.mon_port);
        endfunction

        virtual task wait_reset_start();
            agent_config.wait_reset_start();
        endtask

        virtual task wait_reset_end();
            agent_config.wait_reset_end();
        endtask

        virtual function void handle_reset(uvm_phase phase);
            cfs_md_reset_handler reset_handler;
            uvm_component children[$];

           get_children(children);

           foreach (children[i]) begin
                if($cast(reset_handler , children[i]))begin
                    reset_handler.handle_reset(phase);
                end
           end
        endfunction

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