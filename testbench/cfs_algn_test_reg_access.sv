`ifndef CFS_ALGN_TEST_REG_ACCESS_SV
    `define CFS_ALGN_TEST_REG_ACCESS_SV

    class cfs_algn_test_reg_access extends cfs_algn_test_base;
        cfs_apb_sequence_simple seq_simple;
        int unsigned num_mapped_accesses; // number of apb legal accesses
        int unsigned num_unmapped_accesses; // number of apb illegal accesses
        `uvm_component_utils(cfs_algn_test_reg_access)

        function new(string name = "cfs_algn_test_reg_access", uvm_component parent = null);
            super.new(name, parent);
            num_mapped_accesses   = 0;
            num_unmapped_accesses = 50;
        endfunction


        virtual task run_phase(uvm_phase phase);
            uvm_status_e status;
            uvm_reg_data_t data;
            phase.raise_objection(this);
            `uvm_info(get_type_name(), "Test is up and running!", UVM_LOW)
            #200;
            
            fork
                begin
                    // legal APB accesses branch

                    // create the corr. v_seq
                    cfs_algn_mapped_reg_v_sequence v_seq = cfs_algn_mapped_reg_v_sequence::type_id::create("v_seq");
                    // randomize it
                    void'(v_seq.randomize()with{num_mapped_accesses == local::num_mapped_accesses ;});
                    // start it on the virtual sequencer
                    v_seq.start(env.v_sequencer);
                end
                begin
                    // unmapped APB accesses branch

                    cfs_algn_unmapped_reg_v_sequence unmapped_reg_v_seq = cfs_algn_unmapped_reg_v_sequence::type_id::create("unmapped_reg_v_seq");
                    void'(unmapped_reg_v_seq.randomize()with{num_unmapped_accesses == local::num_unmapped_accesses;});
                    unmapped_reg_v_seq.start(env.v_sequencer);
                end
            join
           

            #100;
            `uvm_info(get_type_name() , "END_OF_TEST" , UVM_LOW)
            phase.drop_objection(this);
        endtask

    endclass

`endif

