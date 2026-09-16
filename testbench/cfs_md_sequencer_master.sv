`ifndef CFS_MD_SEQUENCER_MASTER_SV
    `define CFS_MD_SEQUENCER_MASTER_SV

    class cfs_md_sequencer_master extends cfs_md_sequencer#(cfs_md_item_master_drv);

        `uvm_component_utils(cfs_md_sequencer_master)
        function new(string name ="" , uvm_component parent);
            super.new(name , parent);
        endfunction


    endclass
`endif