`ifndef CFS_APB_COVERAGE_SV
    `define CFS_APB_COVERAGE_SV
    `uvm_analysis_imp_decl(_item)
    class cfs_apb_coverage extends uvm_component implements cfs_apb_reset_handler;
        cfs_apb_agent_config agent_config;
        cfs_apb_vif vif;
        uvm_analysis_imp_item #(cfs_apb_item_mon , cfs_apb_coverage) port_item;

        covergroup cover_item with function sample(cfs_apb_item_mon item);
            option.per_instance = 1;
            direction : coverpoint item.dir{
            }
            response : coverpoint item.response{
            }
            prev_item_delay : coverpoint item.prev_item_delay{
                bins back2back =  {0};
                bins delay_le_5 = {[1 : 5]};
                bins delay_gt_5 = {[6 : $]};
            }
            length : coverpoint item.length{
                bins length_eq_2  =  {2};
                bins length_le_10 =  {[3:10]};
                bins length_gt_10 =  {[11 : $]};

                illegal_bins lenght_le2 = {[$:1]};
            }

            dir_x_response: cross direction , response;

            operation_transitions: coverpoint item.dir{
                bins direction_trans[] = (CFS_APB_WRITE , CFS_APB_READ => CFS_APB_READ , CFS_APB_WRITE);
            }
        endgroup

        covergroup cover_reset with function sample(bit psel);
            access_ongoing : coverpoint psel{
                ignore_bins not_active_access = {0};
            }
        endgroup

        `uvm_component_utils(cfs_apb_coverage)
        function new(string name = "" , uvm_component parent);
            super.new(name , parent);
            port_item   = new("port_item" , this);
            cover_item  = new();
            cover_reset = new();
        endfunction

        virtual function void write_item(cfs_apb_item_mon item);
            cover_item.sample(item);
        endfunction 

        virtual function void handle_reset(uvm_phase phase);
            vif = agent_config.get_vif();
            cover_reset.sample(vif.psel);
        endfunction

    endclass
`endif