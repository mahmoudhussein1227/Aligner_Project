`ifndef CFS_APB_SEQUENCE_SIMPLE_SV
    `define CFS_APB_SEQUENCE_SIMPLE_SV
    
    class cfs_apb_sequence_simple extends cfs_apb_sequence_base;
        // item 
        rand cfs_apb_item_drv item;

        // data
        rand cfs_apb_data data;
        // direction
        rand cfs_apb_dir dir;
        // address
        rand cfs_apb_addr addr;

        `uvm_object_utils(cfs_apb_sequence_simple)

        function new(string name = "");
            super.new(name);
        endfunction

        virtual task body();

            item = cfs_apb_item_drv::type_id::create("item");

            start_item(item);

                void'(item.randomize()with{dir ==  local::dir; 
                                           addr == local::addr;
                                           data == local::data;});
                

            finish_item(item);

        endtask



    endclass

`endif