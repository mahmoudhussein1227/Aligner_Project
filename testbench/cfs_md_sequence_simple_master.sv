`ifndef CFS_MD_SEQUENCE_SIMPLE_MASTER_SV
    `define CFS_MD_SEQUENCE_SIMPLE_MASTER_SV

    class cfs_md_sequence_simple_master#(int unsigned ALGN_DATA_WIDTH = 32) extends cfs_md_sequence_base;
        rand cfs_md_item_master_drv item;

        constraint item_hard{
            item.data.size() > 0;
            item.data.size() <= ALGN_DATA_WIDTH / 8;
      
            item.offset      <  ALGN_DATA_WIDTH / 8;
      
            item.data.size() + item.offset <= ALGN_DATA_WIDTH / 8;
        }
    
        `uvm_object_param_utils(cfs_md_sequence_simple_master#(ALGN_DATA_WIDTH))
        function new(string name = "");
            super.new(name);
            item = cfs_md_item_master_drv::type_id::create("item");
            item.ALGN_DATA_WIDTH = ALGN_DATA_WIDTH;
            //item.size_default.constraint_mode(0);
            //item.offset_size_default.constraint_mode(0);
            item.offset_default.constraint_mode(0);
        endfunction

        virtual task body();
            
            //item = cfs_md_item_master_drv::type_id::create("item");
            //item.ALGN_DATA_WIDTH = ALGN_DATA_WIDTH;
            //void'(item.randomize()with{item.data.size() == 4 ;
                                      // item.offset == 0;});
            `uvm_send(item)
        endtask

    endclass

`endif