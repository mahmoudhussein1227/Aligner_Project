`ifndef CFS_MD_ITEM_MASTER_DRV_SV
    `define CFS_MD_ITEM_MASTER_DRV_SV

    class cfs_md_item_master_drv extends cfs_md_item_master_base;

        // pre_drv_delay
        rand int unsigned pre_drv_delay;
        // post_drv_delay
        rand int unsigned post_drv_delay;

        int unsigned ALGN_DATA_WIDTH = 32;

        constraint default_pre_drv_delay{
            soft pre_drv_delay  <=5;
        }

        constraint default_post_drv_delay {
            soft post_drv_delay <= 5;
        }

        constraint size_default {
           soft (data.size()) > 0;
           soft (data.size()) <= (ALGN_DATA_WIDTH / 8);
        }

        constraint offset_size_default{
           soft  ((ALGN_DATA_WIDTH / 8) + offset) % (data.size()) == 0;
           soft  (data.size() + offset) <= (ALGN_DATA_WIDTH / 8);
        }

        constraint offset_default{
           soft offset < (ALGN_DATA_WIDTH / 8);
        }

        `uvm_object_utils(cfs_md_item_master_drv)

        function new (string name = "");
            super.new(name);
        endfunction

        // virtual function convert2string()
        virtual function string convert2string();
            string result;
            result = super.convert2string();
            result = {result , $sformatf(" pre_drv_delay : %0d , post_drv_delay : %0d ", pre_drv_delay, post_drv_delay)};
            return result;
        endfunction

    endclass

`endif