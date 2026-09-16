`ifndef CFS_ALGN_REG_CONFIG_V_SEQUENCE_SV
    `define CFS_ALGN_REG_CONFIG_V_SEQUENCE_SV
    
    class cfs_algn_reg_config_v_sequence extends uvm_sequence;
        `uvm_declare_p_sequencer(cfs_algn_virtual_sequencer)
        `uvm_object_utils(cfs_algn_reg_config_v_sequence)

        function new(string name = "");
            super.new(name);
        endfunction

        virtual task body();
            uvm_status_e status;
            // get all the config. registers from the mapped one 
            uvm_reg registers[$];
            p_sequencer.model.reg_block.default_map.get_registers(registers);
            // filter these registers by the rights to be {RW or WO}
            foreach (registers[reg_idx]) begin
                if(!(registers[reg_idx].get_rights() inside{"RW" , "WO"}))begin
                    registers.delete(reg_idx);
                end
            end
            // here the registers queue must contain the config. registers only
            //`uvm_info("CONFIG_REGS" , $sformatf("The config. registers are %p" , registers) , UVM_LOW)
            // lets shuffle the config registers queue
            registers.shuffle();

            // lets start a random write access to the registers
            foreach (registers[reg_idx]) begin
                //`uvm_info("CONFIG_REGS" , $sformatf("Randomizing the register %s" , registers[reg_idx].get_name()) , UVM_LOW)
                void'(registers[reg_idx].randomize());
                registers[reg_idx].update(status);
            end
        endtask

    endclass

`endif