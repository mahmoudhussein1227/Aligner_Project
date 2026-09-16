`ifndef CFS_ALGN_PKG_SV
    `define CFS_ALGN_PKG_SV
    `include "cfs_algn_if.sv"
    `include "uvm_macros.svh"
    `include "cfs_apb_pkg.sv"
    `include "cfs_algn_reg_pkg.sv"
    `include "cfs_md_pkg.sv"
    package cfs_algn_pkg;

        import uvm_pkg::*;
        //agent imports
        import cfs_apb_pkg::*;
        import cfs_algn_reg_pkg::*;
        import cfs_md_pkg::*;

        `include "cfs_algn_coverage_info.sv"

        `include "cfs_algn_config.sv"
        `include "cfs_apb_reg_predictor.sv"
        `include "cfs_clr_cnt_drp_cbs.sv"
        `include "cfs_algn_model.sv"
        `include "cfs_algn_scoreboard.sv"
        `include "cfs_algn_coverage.sv"
        `include "cfs_algn_virtual_sequencer.sv"
        `include "cfs_algn_env.sv"
       

        // main legal md_trasnactions v_sequence
        `include "cfs_algn_virtual_sequence.sv"
        // v_sequence to generate an apb accesses to mapped registers
        `include "cfs_algn_mapped_reg_v_sequence.sv"
        // v_sequence to generata an apb accesses to unmapped registers
        `include "cfs_algn_unmapped_reg_v_sequence.sv"
        // v_sequence to configure the config registers like CTRL randomly
        `include "cfs_algn_reg_config_v_sequence.sv"
        // v_sequence to start a random rx_transactions
        `include "cfs_algn_random_md_rx_tr_v_sequence.sv"
        // v_seq to read status registers
        `include "cfs_algn_read_status_regs_v_sequences.sv"
        // v_seq to start illegal rx_transactions
        `include "cfs_algn_illegal_rx_tr_v_sequence.sv"

    endpackage

`endif 