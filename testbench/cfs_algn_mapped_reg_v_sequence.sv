`ifndef CFS_ALGN_MAPPED_REG_V_SEQUENCE_SV
    `define CFS_ALGN_MAPPED_REG_V_SEQUENCE_SV

    class cfs_algn_mapped_reg_v_sequence extends uvm_sequence;
        rand int unsigned num_mapped_accesses;
        `uvm_declare_p_sequencer(cfs_algn_virtual_sequencer)
        `uvm_object_utils(cfs_algn_mapped_reg_v_sequence)

        function new(string name = "");
            super.new(name);
        endfunction

        virtual task body();
            uvm_status_e status;
            uvm_access_e apb_access_type;
            uvm_reg_data_t data;
            uvm_reg registers[$];
            uvm_reg rand_reg;
            int unsigned reg_idx;

            repeat(num_mapped_accesses) begin
                // get the register part of the APB reg_map
                p_sequencer.model.reg_block.default_map.get_registers(registers);
    
                // get a random mapped register 
                reg_idx = $urandom_range(0 , registers.size() - 1);
                rand_reg = registers[reg_idx];

                // start an APB sequence 
                apb_access_type = get_random_access_type();
                case(apb_access_type)
                    UVM_READ: begin
                        // start a APB READ access sequence 
                        rand_reg.read(status , data);
                    end
                    UVM_WRITE: begin
                        // start an APB WRTIE access sequence
                        void'(rand_reg.randomize());
                        rand_reg.update(status);
                    end
                endcase

                wait_random_time();
            end

        endtask

        virtual function uvm_access_e get_random_access_type();
            uvm_access_e result;
            void'(std::randomize(result) with{result inside {UVM_READ , UVM_WRITE};});
            return result;
        endfunction

        virtual task wait_random_time();
            int unsigned num_cycles = $urandom_range(0 , 20);
            repeat(num_cycles)begin
                @(posedge p_sequencer.model.algn_config.get_vif().clk);
            end
        endtask

    endclass

`endif