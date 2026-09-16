`ifndef CFS_MD_ITEM_SLAVE_BASE_SV
    `define CFS_MD_ITEM_SLAVE_BASE_SV

    class cfs_md_item_slave_base extends cfs_md_item_base;


        `uvm_object_utils(cfs_md_item_slave_base)

        function new (string name = "");
            super.new(name);
        endfunction

        // virtual function convert2string()
        virtual function string convert2string();
           
        endfunction

    endclass

`endif