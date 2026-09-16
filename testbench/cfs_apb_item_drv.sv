`ifndef CFS_APB_ITEM_DRV_SV
    `define CFS_APB_ITEM_DRV_SV

    class cfs_apb_item_drv extends cfs_apb_item_base;

        // pre drive delay
        rand int unsigned pre_drv_delay;
        // post drive delay
        rand int unsigned post_drv_delay;

        `uvm_object_utils(cfs_apb_item_drv)

        constraint pre_drive_delay_default {
            soft pre_drv_delay <= 5;
        }

        constraint post_drive_delay_default {
            soft post_drv_delay <= 5;
           // soft post_drv_delay != 0;
        }

        function new(string name = "cfs_apb_item_drv");
            super.new(name);
        endfunction

        virtual function string convert2string();
            string result = super.convert2string();
            result = {result , $sformatf(" , pre_drive_delay : %0d , post_drive_delay = %0d" , pre_drv_delay , post_drv_delay)};
            return result;
        endfunction
    endclass

`endif