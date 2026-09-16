`ifndef CFS_ALGN_REG_BLOCK_SV
    `define CFS_ALGN_REG_BLOCK_SV

    class cfs_algn_reg_block extends uvm_reg_block;
        // declare the registers
        cfs_algn_reg_ctrl   CTRL;
        cfs_algn_reg_status STATUS;
        cfs_algn_reg_irq    IRQ;
        cfs_algn_reg_irqen  IRQEN;

        `uvm_object_utils(cfs_algn_reg_block)
        function new(string name ="");
            super.new(.name(name) , .has_coverage(UVM_NO_COVERAGE));
        endfunction

        virtual function void build();
            // create the address map
            default_map = create_map(
                .name("apb_map"),
                .base_addr(0),
                .n_bytes(4),
                .endian(UVM_LITTLE_ENDIAN),
                .byte_addressing(1)
            );

            // enables the checks on read access
            default_map.set_check_on_read(1);

            // create the registers part of the register block
            CTRL   = cfs_algn_reg_ctrl::type_id::create("CTRL");
            STATUS = cfs_algn_reg_status::type_id::create("STATUS");
            IRQ    = cfs_algn_reg_irq::type_id::create("IRQ");
            IRQEN  = cfs_algn_reg_irqen::type_id::create("IRQEN");

            // configure these registers
            CTRL.configure(.blk_parent(this));
            STATUS.configure(.blk_parent(this));
            IRQ.configure(.blk_parent(this));
            IRQEN.configure(.blk_parent(this));
            
            CTRL.build();
            STATUS.build();
            IRQEN.build();
            IRQ.build();
            // add these registers to the map
            default_map.add_reg(
                .rg(CTRL),
                .offset('h0000),
                .rights("RW")
            );

            default_map.add_reg(
                .rg(STATUS),
                .offset('h000C),
                .rights("RO")
            );

            default_map.add_reg(
                .rg(IRQEN),
                .offset('h00F0),
                .rights("RW")
            );

            default_map.add_reg(
                .rg(IRQ),
                .offset('h00F4),
                .rights("RW")
            );

        endfunction




    endclass


`endif