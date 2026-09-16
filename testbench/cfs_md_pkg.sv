`ifndef CFS_MD_PKG_SV
    `define CFS_MD_PKG_SV

    `include "uvm_macros.svh"
    `include "cfs_md_if.sv"
    package cfs_md_pkg;
        import uvm_pkg::*;
        
        // types file
        `include "cfs_md_types.sv"

        // reset handler 
        `include "cfs_md_reset_handler.sv"

        // sequence items
        `include "cfs_md_item_base.sv"
        `include "cfs_md_item_master_base.sv"
        `include "cfs_md_item_master_drv.sv"
        `include "cfs_md_item_master_mon.sv"
        `include "cfs_md_item_slave_base.sv"
        `include "cfs_md_item_slave_drv.sv"

        // components
        `include "cfs_md_agnet_config.sv"
        `include "cfs_md_agent_config_master.sv"
        `include "cfs_md_agent_config_slave.sv"

        `include "cfs_md_sequencer.sv"
        `include "cfs_md_sequencer_master.sv"
        `include "cfs_md_sequencer_slave.sv"

        `include "cfs_md_driver.sv"
        `include "cfs_md_driver_master.sv"
        `include "cfs_md_driver_slave.sv"

        `include "cfs_md_monitor.sv"

       

        `include "cfs_md_coverage.sv"

        `include "cfs_md_agent.sv"
        `include "cfs_md_agent_master.sv"
        `include "cfs_md_agent_slave.sv"

        // sequences
        `include "cfs_md_sequence_base.sv"
        `include "cfs_md_sequence_simple_master.sv"
        `include "cfs_md_sequence_simple_slave.sv"
    endpackage

`endif