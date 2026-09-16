`ifndef CFS_ALGN_RANDOM_MD_TR_V_SEQUENCE_SV
    `define CFS_ALGN_RANDOM_MD_TR_V_SEQUENCE_SV

    class cfs_algn_random_md_tr_v_sequence extends uvm_sequence;
        rand cfs_md_sequence_simple_master#(32) rx_seq;
        `uvm_declare_p_sequencer(cfs_algn_virtual_sequencer)
        `uvm_object_utils(cfs_algn_random_md_tr_v_sequence)

        function new(string name = "");
            super.new(name);
            rx_seq = cfs_md_sequence_simple_master#(32)::type_id::create("rx_seq");
            rx_seq.item_hard.constraint_mode(0);
        endfunction

        virtual task body();
            //void'(rx_seq.randomize());
            rx_seq.start(p_sequencer.rx_sqr);
        endtask

    endclass


`endif