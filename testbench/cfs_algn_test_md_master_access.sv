`ifndef CFS_ALGN_TEST_MD_MASTER_ACCESS_SV
    `define CFS_ALGN_TEST_MD_MASTER_ACCESS_SV

    class cfs_algn_test_md_master_access extends cfs_algn_test_base;
        //cfs_md_sequence_simple_master#(32) seq_simple;
        cfs_algn_virtual_sequence v_sequence;
        int unsigned num_md_rx_tr;
        
        `uvm_component_utils(cfs_algn_test_md_master_access)

        function new(string name = "cfs_algn_test_md_master_access", uvm_component parent = null);
            super.new(name, parent);
            num_md_rx_tr = 200;
        endfunction

        virtual task run_phase(uvm_phase phase);
            uvm_status_e status;
            phase.raise_objection(this);
            `uvm_info(get_type_name(), "Test is up and running!", UVM_LOW)
            #200;

                fork
                    begin
                        forever begin
                            cfs_md_sequence_simple_slave seq_slave = cfs_md_sequence_simple_slave::type_id::create("seq_slave");
                            void'(seq_slave.randomize());
                            seq_slave.start(env.v_sequencer.tx_sqr);
                        end
                    end
                join_none

                repeat(2)begin
                    // start virtual sequence to randomly configure the all configuration registers
                    begin
                        
                        if(env.model.is_empty() == 1)begin
                           cfs_algn_reg_config_v_sequence reg_config_v_seq = cfs_algn_reg_config_v_sequence::type_id::create("reg_config_v_seq");
                           reg_config_v_seq.start(env.v_sequencer);
                        end
                       
                        
                    end

                    // start virtual sequence to send multiple legal md_rx_transactions
                    begin
                        repeat(num_md_rx_tr)begin
                            cfs_algn_random_md_tr_v_sequence rx_v_seq;
                            rx_v_seq = cfs_algn_random_md_tr_v_sequence::type_id::create("rx_v_seq");
                            rx_v_seq.set_sequencer(env.v_sequencer);
                            void'(rx_v_seq.randomize());
                            rx_v_seq.start(env.v_sequencer);
                        end
                    end

                    begin 
                        repeat(100)begin
                            @(posedge env.algn_config.vif.clk);
                        end
                    end
                    // start a virtual sequence to read the status registers after each tx_md_transaciton
                    begin
                        cfs_algn_read_status_regs_v_sequence status_reg_v_seq = cfs_algn_read_status_regs_v_sequence::type_id::create("status_reg_v_seq");
                        status_reg_v_seq.start(env.v_sequencer);
                    end
                end
            #1000;
            `uvm_info(get_type_name(), "END_OF_TEST", UVM_LOW)
            phase.drop_objection(this);
        endtask

    endclass

`endif

