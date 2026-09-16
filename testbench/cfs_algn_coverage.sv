`ifndef CFS_ALGN_COVERAGE_SV
    `define CFS_ALGN_COVERAGE_SV

    `uvm_analysis_imp_decl(_in_model)


    class cfs_algn_coverage extends uvm_component implements cfs_apb_reset_handler;

        uvm_analysis_imp_in_model#(cfs_algn_coverage_info , cfs_algn_coverage) port_in_model;

        covergroup cover_split with function sample(cfs_algn_coverage_info item);
            option.per_instance = 1;
            
            // rx_item_size coverpoint
            rx_item_size : coverpoint item.item_size{
                bins values[] = {[1:4]};
            }
            // rx_item_offset coverpoint
            rx_item_offset : coverpoint item.item_offset{
                bins values[] = {[0:3]};
            }
            // configured size coverpoint
            ctrl_size : coverpoint item.ctrl_size{
                bins values[] = {[1:4]};
            }
            // configured offset coverpoint
            ctrl_offset : coverpoint item.ctrl_offset{
                bins values[] = {[0:3]};
            }
            // number of bytes left to complete the tx_item
            num_bytes : coverpoint item.num_bytes{
                bins values[] = {[1:3]};
            }
            
            cross rx_item_size, rx_item_offset , ctrl_size , ctrl_offset , num_bytes{
                ignore_bins ingnore_ctrl =  (binsof(ctrl_offset) intersect {0} && binsof(ctrl_size) intersect {3})       || 
                                            (binsof(ctrl_offset) intersect {1} && binsof(ctrl_size) intersect {2, 3, 4}) || 
                                            (binsof(ctrl_offset) intersect {2} && binsof(ctrl_size) intersect {3, 4})    || 
                                            (binsof(ctrl_offset) intersect {3} && binsof(ctrl_size) intersect {2, 3, 4});
            }
            // TODO : there are another senarios to be excluded 
        endgroup

        `uvm_component_utils(cfs_algn_coverage)

        function new(string name = "" , uvm_component parent);
            super.new(name , parent);
            port_in_model = new("port_in_model" , this);
            cover_split = new;
        endfunction

        virtual function void handle_reset(uvm_phase phase);

        endfunction

        virtual function void write_in_model(cfs_algn_coverage_info item);
            cover_split.sample(item);
        endfunction

    endclass


`endif