`ifndef CFS_MD_ITEM_MASTER_BASE_SV
    `define CFS_MD_ITEM_MASTER_BASE_SV

    class cfs_md_item_master_base extends cfs_md_item_base;

        // data 
        rand logic[7:0]data[$];
        // offset
        rand int unsigned offset;

        `uvm_object_utils_begin(cfs_md_item_master_base)
            `uvm_field_queue_int(data, UVM_RECORD)
            `uvm_field_int(offset , UVM_RECORD)
        `uvm_field_utils_end

        function new (string name = "");
            super.new(name);
        endfunction

        // virtual function convert2string()
        virtual function string convert2string();
            string data_str = "'{";
            foreach (data[i]) begin
                data_str = {data_str, (i == 0 ? "" : ", "), $sformatf("'h%02x", data[i])};
            end
            data_str = {data_str, "}"};

            return $sformatf("data: %0s , offset : %0d , size : %0d ", data_str , offset , data.size());
        endfunction

    endclass

`endif