`ifndef CFS_ALGB_APB_ADAPTER_SV
    `define CFS_ALGB_APB_ADAPTER_SV

    class cfs_algn_apb_adapter extends uvm_reg_adapter;

        `uvm_object_utils(cfs_algn_apb_adapter)
        function new(string name = "");
            super.new(name);
        endfunction

        virtual function void bus2reg(uvm_sequence_item bus_item,ref uvm_reg_bus_op rw);
            cfs_apb_item_mon item_mon;
            cfs_apb_item_drv item_drv;

            if($cast(item_mon , bus_item))begin
                rw.kind   = (item_mon.dir == CFS_APB_WRITE) ? UVM_WRITE : UVM_READ;
                rw.addr   = item_mon.addr;
                rw.data   = item_mon.data;
                rw.status = item_mon.response == CFS_APB_OK ? UVM_IS_OK : UVM_NOT_OK;
            end

            if($cast(item_drv , bus_item))begin
                rw.kind   = (item_drv.dir == CFS_APB_WRITE) ? UVM_WRITE : UVM_READ;
                rw.addr   = item_drv.addr;
                rw.data   = item_drv.data;
                rw.status = UVM_IS_OK;
            end
        endfunction

        virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
            cfs_apb_item_drv item = cfs_apb_item_drv::type_id::create("item");

            item.dir  =  cfs_apb_dir'(rw.kind);
            item.addr =  rw.addr;
            item.data =  rw.data;

            return item;
        endfunction

    endclass


`endif