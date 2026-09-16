`ifndef CFS_ALGN_REG_CTRL_SV
    `define CFS_ALGN_REG_CTRL_SV

    class cfs_algn_reg_ctrl extends uvm_reg;

        // CTRL reg_fields
        rand uvm_reg_field SIZE;
        rand uvm_reg_field OFFSET;
        rand uvm_reg_field CLR;

        // DATA_WIDTH parameter 
        local int unsigned ALGN_DATA_WIDTH;

        //constariants
        constraint legal_size {
            SIZE.value != 0;
        }

        constraint legal_size_offset {
            (SIZE.value + OFFSET.value) <= ALGN_DATA_WIDTH/8;
            ((ALGN_DATA_WIDTH / 8) + OFFSET.value) % SIZE.value == 0;
        }

        `uvm_object_utils(cfs_algn_reg_ctrl)
        function new (string name = "");
            super.new(.name(name) , .n_bits(32) , .has_coverage(UVM_NO_COVERAGE));
            ALGN_DATA_WIDTH = 32;
        endfunction

        virtual function void build();
            //creating the reg_field instances
            SIZE    = uvm_reg_field::type_id::create(.name("SIZE"));
            OFFSET  = uvm_reg_field::type_id::create(.name("OFFSET"));
            CLR     = uvm_reg_field::type_id::create(.name("CLR"));


            // configure the reg_fields 
            SIZE.configure(
                .parent(this),
                .size(3),
                .lsb_pos(0),
                .access("RW"),
                .volatile(0),
                .reset(3'b001),
                .has_reset(1),
                .is_rand(1),
                .individually_accessible(0)
            );

            OFFSET.configure(
                .parent(this),
                .size(2),
                .lsb_pos(8),
                .access("RW"),
                .volatile(0),
                .reset(2'b0),
                .has_reset(1),
                .is_rand(1),
                .individually_accessible(0)
            );

            CLR.configure(
                .parent(this),
                .size(1),
                .lsb_pos(16),
                .access("WO"),
                .volatile(0),
                .reset(1'b0),
                .has_reset(1),
                .is_rand(1),
                .individually_accessible(0)
            );

        endfunction

    endclass


`endif