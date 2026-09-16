`ifndef CFS_ALGN_VIRTUAL_SEQUENCER_SV
    `define CFS_ALGN_VIRTUAL_SEQUENCER_SV

    class cfs_algn_virtual_sequencer extends uvm_sequencer;
        // sequencers 
        // apb_sequencer handle
        cfs_apb_sequencer apb_sqr;
        // rx_sequencer handle
        cfs_md_sequencer_master rx_sqr;
        // tx_sequencer handele
        cfs_md_sequencer_slave tx_sqr;

        // model handle
        cfs_algn_model model;

        `uvm_component_utils(cfs_algn_virtual_sequencer)
        function new(string name = "" , uvm_component parent);
            super.new(name , parent);
        endfunction

    endclass

`endif