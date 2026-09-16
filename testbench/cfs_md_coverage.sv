`ifndef CFS_MD_COVERAGE_SV
    `define CFS_MD_COVERAGE_SV

    class cfs_md_coverage#(ALGN_DATA_WIDTH = 32) extends uvm_component implements cfs_md_reset_handler;
        typedef virtual cfs_md_if#(ALGN_DATA_WIDTH) cfs_md_vif;
        cfs_md_vif vif;
        cfs_md_agent_config#(ALGN_DATA_WIDTH) agent_config;

        uvm_analysis_imp#(cfs_md_item_master_mon , cfs_md_coverage#(ALGN_DATA_WIDTH)) mon_port;

        covergroup cover_item with function sample(cfs_md_item_master_mon item);
            option.per_instance = 1;
            
            response : coverpoint item.response {   
            }

            length : coverpoint item.length {

                bins length_eq1     = {1};
                bins length_le5[]   = {[2:5]};
                bins length_gt5     = {[6:$]};

                illegal_bins length_eq0 = {0};

            }

            prev_item_delay : coverpoint item.prev_item_delay{
                bins back2back     = {0};
                bins delay_le_5[]  = {[1:5]}; 
                bins delay_gt5     = {[6:$]};
            }

            size : coverpoint item.data.size() {
                bins values []  = {[1:(ALGN_DATA_WIDTH / 8)]}; 
            }

            offset : coverpoint item.offset {
                bins values [] = {[0 : (ALGN_DATA_WIDTH / 8) - 1]};
            }

            size_x_offset : cross size , offset {
                ignore_bins offset_size_gt_data_width = size_x_offset with (offset + size > ALGN_DATA_WIDTH/8);
            }
   
        endgroup

        covergroup cover_reset with function sample(bit value);
            option.per_instance = 1;
            reset_on_going : coverpoint value {
                    bins active   = {1};
                    bins inactive = {0};
            }
        endgroup            

        `uvm_component_param_utils(cfs_md_coverage#(ALGN_DATA_WIDTH))

        function new(string name = "" , uvm_component parent);
            super.new(name , parent);
            mon_port    = new("mon_port" , this);
            cover_item  = new();
            cover_reset = new();
        endfunction

        virtual function void write(cfs_md_item_master_mon item);
            cover_item.sample(item);
        endfunction

        virtual function void handle_reset(uvm_phase phase);
            vif = agent_config.get_vif();
            cover_reset.sample(vif.valid);
        endfunction

    endclass

`endif