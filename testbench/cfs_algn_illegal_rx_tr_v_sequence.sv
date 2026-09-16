`ifndef CFS_ALGN_ILLEGA_RX_TR_V_SEQUENCE_SV
    `define CFS_ALGN_ILLEGA_RX_TR_V_SEQUENCE_SV

    class cfs_algn_illegal_rx_tr_v_sequence extends cfs_algn_random_md_tr_v_sequence;
        int unsigned ALGN_DATA_WIDTH;
        `uvm_object_utils(cfs_algn_illegal_rx_tr_v_sequence)

        constraint illegal_rx_hard{
            (((ALGN_DATA_WIDTH / 8) + rx_seq.item.offset) % rx_seq.item.data.size() != 0) ||
            ((rx_seq.item.data.size() + rx_seq.item.offset) > (ALGN_DATA_WIDTH / 8));
        }

        function new(string name = "");
            super.new(name);
            rx_seq.item.size_default.constraint_mode(0);
            rx_seq.item.offset_size_default.constraint_mode(0);
            rx_seq.item.offset_default.constraint_mode(0);
        endfunction

        function void pre_randomize();
            super.pre_randomize();
            ALGN_DATA_WIDTH = p_sequencer.model.algn_config.get_algn_data_width();
        endfunction


    endclass


`endif