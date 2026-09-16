`ifndef CFS_ALGN_REG_IRQEN_SV
    `define CFS_ALGN_REG_IRQEN_SV

    class cfs_algn_reg_irqen extends uvm_reg;

        // reg_fields 
        rand uvm_reg_field RX_FIFO_EMPTY;
        rand uvm_reg_field RX_FIFO_FULL;
        rand uvm_reg_field TX_FIFO_EMPTY;
        rand uvm_reg_field TX_FIFO_FULL;
        rand uvm_reg_field MAX_DROP;

        `uvm_object_utils(cfs_algn_reg_irqen)

        function new (string name = "");
            super.new(.name(name), .n_bits(32), .has_coverage(UVM_NO_COVERAGE));
        endfunction

        virtual function void build();
            // creating field instances
            RX_FIFO_EMPTY = uvm_reg_field::type_id::create(.name("RX_FIFO_EMPTY"));
            RX_FIFO_FULL  = uvm_reg_field::type_id::create(.name("RX_FIFO_FULL"));
            TX_FIFO_EMPTY = uvm_reg_field::type_id::create(.name("TX_FIFO_EMPTY"));
            TX_FIFO_FULL  = uvm_reg_field::type_id::create(.name("TX_FIFO_FULL"));
            MAX_DROP      = uvm_reg_field::type_id::create(.name("MAX_DROP"));

            // configure the fields
            RX_FIFO_EMPTY.configure(
                .parent(this),
                .size(1),
                .lsb_pos(0),
                .access("RW"),
                .volatile(0),
                .reset(1'b0),
                .has_reset(1),
                .is_rand(1),
                .individually_accessible(0)
            );

            RX_FIFO_FULL.configure(
                .parent(this),
                .size(1),
                .lsb_pos(1),
                .access("RW"),
                .volatile(0),
                .reset(1'b0),
                .has_reset(1),
                .is_rand(1),
                .individually_accessible(0)
            );

            TX_FIFO_EMPTY.configure(
                .parent(this),
                .size(1),
                .lsb_pos(2),
                .access("RW"),
                .volatile(0),
                .reset(1'b0),
                .has_reset(1),
                .is_rand(1),
                .individually_accessible(0)
            );

            TX_FIFO_FULL.configure(
                .parent(this),
                .size(1),
                .lsb_pos(3),
                .access("RW"),
                .volatile(0),
                .reset(1'b0),
                .has_reset(1),
                .is_rand(1),
                .individually_accessible(0)
            );

            MAX_DROP.configure(
                .parent(this),
                .size(1),
                .lsb_pos(4),
                .access("RW"),
                .volatile(0),
                .reset(1'b0),
                .has_reset(1),
                .is_rand(1),
                .individually_accessible(0)
            );

        endfunction

    endclass

`endif

