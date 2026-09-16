`ifndef CFS_APB_REG_PREDICTOR_SV
    `define CFS_APB_REG_PREDICTOR_SV
    class cfs_apb_reg_predictor#(type BUSTYPE = uvm_sequence_item) extends uvm_reg_predictor#(.BUSTYPE(BUSTYPE));
        int unsigned ALGN_DATA_WIDTH;
        `uvm_component_param_utils(cfs_apb_reg_predictor#(BUSTYPE))
        function new(string name = "" , uvm_component parent);
            super.new(name , parent);
            ALGN_DATA_WIDTH = 32;
        endfunction

        virtual function uvm_status_e get_exp_response(uvm_reg_bus_op operation);
            uvm_reg register;
            cfs_algn_reg_ctrl CTRL;
            register = map.get_reg_by_offset(operation.addr);
            // check 1: accessing unmapped register causes an APB error
            if(register == null)begin
                `uvm_info(get_type_name() , "the accessed register is unmapped" , UVM_LOW)
                return UVM_NOT_OK;
            end
            //check 2: write access to RO register caues an APB error
            if(register.get_rights() == "RO" && operation.kind == UVM_WRITE)begin
                `uvm_info(get_type_name() , "there is a write access to a RO register" , UVM_LOW)
                return UVM_NOT_OK;
            end
            // check 3 : read access to WO register causes an APB error
            if(register.get_rights() == "WO" && operation.kind == UVM_READ)begin
                `uvm_info(get_type_name() , "there is a read access to a WO register" , UVM_LOW)
                return UVM_NOT_OK;
            end

            if($cast(CTRL , register))begin
                // check 4: writting a 0 in SIZE field part of the CTRL register cause and APB error
                if (operation.kind == UVM_WRITE) begin
                    if(operation.data[2:0] == 0 )begin
                        `uvm_info(get_type_name() , "try to write a value 0 in the CTRL.SIZE field" , UVM_LOW)
                        return UVM_NOT_OK;
                    end
                    
                    if((operation.data[2:0] + operation.data[9:8])*8 > ALGN_DATA_WIDTH)begin
                        `uvm_info(get_type_name() , "try to write and illegal combination of size and offset that are bigger the APB DATA WIDTH" , UVM_LOW)
                        return UVM_NOT_OK;
                    end

                    if(((ALGN_DATA_WIDTH / 8) + operation.data[9:8] ) % operation.data[2:0] != 0 ) begin
                        `uvm_info(get_type_name() , "try to write and illegal combination of size and offset" , UVM_LOW)
                        return UVM_NOT_OK;
                    end
                end
            end

            return UVM_IS_OK;

        endfunction

        virtual function void write(BUSTYPE tr);
            uvm_reg_bus_op operation;
            adapter.bus2reg(tr , operation);

            if(get_exp_response(operation) == UVM_IS_OK)begin
                super.write(tr);
            end

        endfunction



    endclass

`endif