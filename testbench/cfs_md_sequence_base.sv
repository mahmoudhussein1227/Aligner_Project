`ifndef CFS_MD_SEQUENCE_SV
    `define CFS_MD_SEQUENCE_SV

    class cfs_md_sequence_base extends uvm_sequence;
        `uvm_object_utils(cfs_md_sequence_base)
        function new(string name = "");
            super.new(name);
        endfunction

    endclass

`endif