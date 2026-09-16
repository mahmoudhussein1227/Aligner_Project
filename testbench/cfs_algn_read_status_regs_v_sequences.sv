`ifndef CFS_ALGN_READ_STATUS_REGS_V_SEQUENCE_SV
    `define CFS_ALGN_READ_STATUS_REGS_V_SEQUENCE_SV

    class cfs_algn_read_status_regs_v_sequence extends uvm_sequence;
        `uvm_declare_p_sequencer(cfs_algn_virtual_sequencer)
        `uvm_object_utils(cfs_algn_read_status_regs_v_sequence)

        function new(string name = "");
            super.new(name);
        endfunction

        virtual task body();
            uvm_status_e status;
            uvm_reg_data_t data;
            // getting the status regs
            uvm_reg registers[$];
            uvm_reg status_registers[$];
            p_sequencer.model.reg_block.default_map.get_registers(registers);
            //`uvm_info("CONFIG_REGS" , $sformatf("The status registers are  %p" , registers) , UVM_LOW)
            foreach(registers[reg_idx])begin
                //`uvm_info("CONFIG_REGS" , $sformatf("The status register is %s" , registers[reg_idx].get_name()) , UVM_LOW)
                if((registers[reg_idx].get_rights() inside{"RO"}))begin
                    //`uvm_info("CONFIG_REGS" , $sformatf("The status register %s is not RO" , registers[reg_idx].get_name()) , UVM_LOW)
                    status_registers.push_back(registers[reg_idx]);
                end
            end
           // `uvm_info("CONFIG_REGS" , $sformatf("the status registers are  %p" , registers) , UVM_LOW)
            registers.shuffle();

            // read the status regs
            foreach (status_registers[reg_idx]) begin
                status_registers[reg_idx].read(status , data);
            end
        endtask

    endclass

`endif