`ifndef CFS_ALGN_COVERAGE_INFO_SV
    `define CFS_ALGN_COVERAGE_INFO_SV

    class cfs_algn_coverage_info extends uvm_object;

        // rx_item size
        int unsigned item_size;
        // rx_item offset
        int unsigned item_offset;
        // CTRL.SIZE value
        int unsigned ctrl_size;
        // CTRL.OFFSET value
        int unsigned ctrl_offset;
        // number of bytes needed to complete the tx_item
        int unsigned num_bytes;

        `uvm_object_utils(cfs_algn_coverage_info)

        function new(string name  = "");
            super.new(name);
        endfunction




    endclass

`endif