`ifndef CSF_ALGN_VIRTAUL_SEQUENCE_SV
    `define CSF_ALGN_VIRTAUL_SEQUENCE_SV

    class cfs_algn_virtual_sequence extends uvm_sequence;
        `uvm_declare_p_sequencer(cfs_algn_virtual_sequencer)

        `uvm_object_utils(cfs_algn_virtual_sequence)

        function new(string name = "");
            super.new(name);
        endfunction

        virtual task body();
            int unsigned algn_data_width = p_sequencer.model.algn_config.get_algn_data_width();
            cfs_md_sequence_simple_master#(32) rx_sequence;
            int unsigned ctrl_size       = p_sequencer.model.reg_block.CTRL.SIZE.get_mirrored_value();
            fork
                begin
                    // md_rx_sequence
                    
                    `uvm_do_on_with(rx_sequence , p_sequencer.rx_sqr , {
                        ((algn_data_width / 8) + item.offset) % item.data.size() == 0 ;
                        (item.data.size() + item.offset) <= (algn_data_width / 8);

                        item.data.size() >= ctrl_size;
                    })

                end

                begin
                    // md_tx_sequence
                    cfs_md_sequence_simple_slave tx_sequence;
                    // number of needed tx_items = rx_item.data.szie() / CTRL.SIZE
                    int unsigned md_tx_item_num;
                    // the index of the current ouptuted tx_item
                    int unsigned md_tx_item_idx = 0;

                    md_tx_item_num = rx_sequence.item.data.size() / ctrl_size;

                    do begin
                        `uvm_do_on_with(tx_sequence , p_sequencer.tx_sqr , {
                            md_tx_item_num == 1                                             -> item.response == CFS_MD_OK;
                            (md_tx_item_num > 1) && (md_tx_item_idx < md_tx_item_num  - 1)  -> item.response == CFS_MD_OK;
                            (md_tx_item_num > 1) && (md_tx_item_idx == md_tx_item_num - 1)  -> item.response == CFS_MD_ERR;

                        })

                        md_tx_item_idx ++;
                        `uvm_info({get_type_name(), " md_tx_item_idx , md_tx_item_num "} , $sformatf("md_tx_item_idx : %0d , md_tx_item_num : %0d" , md_tx_item_idx , md_tx_item_num) , UVM_LOW)

                    end
                    while(md_tx_item_idx < md_tx_item_num);
                    
                end
            join
        endtask

    endclass

`endif