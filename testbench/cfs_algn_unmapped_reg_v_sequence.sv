`ifndef CFS_ALGN_UNMAPPED_REG_V_SEQUENCE_SV
    `define CFS_ALGN_UNMAPPED_REG_V_SEQUENCE_SV

    class cfs_algn_unmapped_reg_v_sequence extends uvm_sequence;
        rand int unsigned num_unmapped_accesses; 
        cfs_apb_sequence_simple apb_seq;
        `uvm_declare_p_sequencer(cfs_algn_virtual_sequencer)
        `uvm_object_utils(cfs_algn_unmapped_reg_v_sequence)

        function new(string name = "");
            super.new(name);
        endfunction

        virtual task body();
            uvm_reg_addr_t mapped_addrs[$];
            // getting the mapped addresses to exclude it 
            uvm_reg registers[$];
            p_sequencer.model.reg_block.default_map.get_registers(registers);
            foreach (registers[reg_idx]) begin
                for(int num_bytes = 0 ; num_bytes < registers[reg_idx].get_n_bits() / 8 ; num_bytes++)begin
                    mapped_addrs.push_back(registers[reg_idx].get_offset() + num_bytes);
                end
            end

            repeat(num_unmapped_accesses)begin
                apb_seq = cfs_apb_sequence_simple::type_id::create("apb_seq");
                void'(apb_seq.randomize()with{!addr inside {mapped_addrs} ;});
                apb_seq.start(p_sequencer.apb_sqr);

            end

        endtask

/*
        virtual function uvm_access_e get_random_access_type();
            uvm_access_e result;
            void'(std::randomize(result) with{result inside {UVM_READ , UVM_WRITE};});
            return result;
        endfunction
*/
/*
        virtual task wait_random_time();
            int unsigned num_cycles = $urandom_range(0 , 20);
            repeat(num_cycles)begin
                @(posedge p_sequencer.model.algn_config.get_vif().clk);
            end
        endtask
*/


    endclass

`endif