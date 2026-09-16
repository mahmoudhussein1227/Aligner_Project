`ifndef CFS_APB_ITEM_BASE_SV
    `define CFS_APB_ITEM_BASE_SV

    class cfs_apb_item_base extends uvm_sequence_item;
        // data
        rand cfs_apb_data data;
        // direction
        rand cfs_apb_dir dir;
        // address
        rand cfs_apb_addr addr; 

        `uvm_object_utils(cfs_apb_item_base)

        function new(string name = "cfs_apb_item_base");
            super.new(name);
        endfunction

        virtual function string convert2string();
            string result;
            result = $sformatf("dir: %s, addr: 'h%0x, ", dir.name(), addr);
            result = {result, $sformatf("data: 'h%0x, ", data)};

            return result;
        endfunction

    endclass
`endif