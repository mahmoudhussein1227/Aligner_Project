`ifndef CFS_CLR_CNT_DRP_CBS_SV
    `define CFS_CLR_CNT_DRP_CBS_SV

    class cfs_clr_cnt_drp_cbs extends uvm_reg_cbs;

    uvm_reg_field cnt_drop;

    `uvm_object_utils(cfs_clr_cnt_drp_cbs)

    function new(string name = "");
        super.new(name);
    endfunction

    virtual function void post_predict(
        input uvm_reg_field fld,
        input uvm_reg_data_t previous,
        inout uvm_reg_data_t value,
        input uvm_predict_e kind,
        input uvm_path_e path,
        input uvm_reg_map map
    );

        if(kind == UVM_PREDICT_WRITE) begin // kind of operation done to the CLR field
            if(value == 1) begin
                void'(cnt_drop.predict(0)); // value written into the CLR field 
                value = 0; // write 0 to the CLR field after the drp_counter is reseted
                `uvm_info(get_type_name() , $sformatf("Clearing %0s", cnt_drop.get_full_name()) , UVM_LOW )
            end 
            
        end
        

    endfunction


    endclass

`endif