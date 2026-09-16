`ifndef CFS_MD_ITEM_MASTER_MON_SV
    `define CFS_MD_ITEM_MASTER_MON_SV

    class cfs_md_item_master_mon extends cfs_md_item_master_base;

        // response field
        cfs_md_response response;

        // length
        int unsigned length;

        // prev_item_delay
        int unsigned prev_item_delay;


        `uvm_object_utils_begin(cfs_md_item_master_mon)
            `uvm_field_int(length, UVM_RECORD)
            `uvm_field_enum(cfs_md_response, response, UVM_RECORD)
            `uvm_field_int(prev_item_delay, UVM_RECORD)
        `uvm_object_utils_end

        function new(string name ="");
            super.new(name);
        endfunction

        virtual function bit is_active_mon();
            return get_end_time == -1;
        endfunction 
            
        

        virtual function string convert2string();
            string result;
            result = super.convert2string();
            result = {result , $sformatf( " , length : %0d , response : %0s , prev_item_delay : %0d" , length, response.name() , prev_item_delay)};
            return result;
        endfunction


    endclass

    

`endif