`ifndef CFS_MD_ITEM_SLAVE_DRV_SV
    `define CFS_MD_ITEM_SLAVE_DRV_SV

    class cfs_md_item_slave_drv extends cfs_md_item_slave_base;

       //response field
       rand cfs_md_response response;
       // ready at end of the MD transaction field
       // if 1 that means a b2b MD transaction
       rand bit ready_at_end;
       // length of the MD transaction
       rand int unsigned length;


        constraint length_default{
            length <= 5;
            //length != 0;
        }
        `uvm_object_utils(cfs_md_item_slave_drv)

        function new (string name = "");
            super.new(name);
        endfunction

        // virtual function convert2string()
        virtual function string convert2string();
            string result;
            result = super.convert2string();
            result = {result , $sformatf("response: %0s, length: %0d, ready_at_end: %0d", response.name(), length, ready_at_end)};
            return result;
        endfunction

    endclass

`endif