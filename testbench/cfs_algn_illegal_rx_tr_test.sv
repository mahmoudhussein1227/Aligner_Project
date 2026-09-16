`ifndef CFS_ALGN_ILLEGAL_RX_TR_TEST_SV
    `define CFS_ALGN_ILLEGAL_RX_TR_TEST_SV

    class cfs_algn_illegal_rx_tr_test extends cfs_algn_test_md_master_access;

        `uvm_component_utils(cfs_algn_illegal_rx_tr_test)

        function new(string name = "" , uvm_component parent);
            super.new(name , parent);
            num_md_rx_tr = 300;
            // override the rx_v_seq to the illegal one 
            cfs_algn_random_md_tr_v_sequence::type_id::set_type_override(cfs_algn_illegal_rx_tr_v_sequence::get_type());
        endfunction

        virtual task run_phase(uvm_phase phase);
            //rx_v_seq.set_sequencer(env.v_sequencer);
            super.run_phase(phase); 
        endtask

    endclass

`endif