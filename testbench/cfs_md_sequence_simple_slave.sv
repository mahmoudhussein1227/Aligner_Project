`ifndef CFS_MD_SEQUENCE_SIMPLE_SLAVE_SV
    `define CFS_MD_SEQUENCE_SIMPLE_SLAVE_SV

    class cfs_md_sequence_simple_slave extends cfs_md_sequence_base;
        rand cfs_md_item_slave_drv item;
        `uvm_declare_p_sequencer(cfs_md_sequencer_slave)

        `uvm_object_utils(cfs_md_sequence_simple_slave)
        function new (string name = "");
            super.new(name);
            item = cfs_md_item_slave_drv::type_id::create("item");
        endfunction

        virtual task body();
            cfs_md_item_master_mon item_mon;
            p_sequencer.pending_items.get(item_mon);
            `uvm_info({get_type_name(), " out_of_get"} , item_mon.convert2string() , UVM_LOW)
        /*
            ensure that the sequence will send the item to the slave driver
            only when there is a pending item from the rx interface 
        */
    
            begin
                //item = cfs_md_item_slave_drv::type_id::create("item");
                //void'(item.randomize());
                `uvm_send(item);    
            end
            
        endtask

    endclass

`endif