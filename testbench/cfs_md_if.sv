`ifndef CFS_MD_IF_SV
    `define CFS_MD_IF_SV

    interface cfs_md_if#(int unsigned ALGN_DATA_WIDTH = 32)(input bit clk);

        localparam OFFSET_WIDTH = ($clog2(ALGN_DATA_WIDTH/8) > 1) ? $clog2(ALGN_DATA_WIDTH/8) : 1;
        localparam SIZE_WIDTH   = $clog2(ALGN_DATA_WIDTH/8) + 1; 

        logic reset_n;
        logic valid;
        logic [ALGN_DATA_WIDTH - 1 : 0] data;
        logic [OFFSET_WIDTH - 1 :    0] offset;
        logic [SIZE_WIDTH - 1   :    0] size;
        logic ready;
        logic err;

        bit has_checks;
        initial begin
            has_checks = 1'b1;
        end

        // assertions

        property valid_high;
            @(posedge clk) disable iff (~reset_n | ~has_checks)
            $rose(valid) |-> valid throughout (ready[->1]);
        endproperty
        VALID_MD_HIGH_A: assert property (valid_high)
            else $error("Assertion VALID_HIGH_A failed!");

        property valid_data;
        @(posedge clk) disable iff (~reset_n | ~has_checks)
        valid |-> ~$isunknown(data);
        endproperty
        VALID_MD_DATA_A: assert property (valid_data)
            else $error("data must have a valid value during the MD transaction"); 

        property stable_data;
            logic[ALGN_DATA_WIDTH - 1 : 0] sampled_data;
            @(posedge clk) disable iff (~reset_n | ~has_checks)
            ($rose(valid) , sampled_data = data ) |-> (data == sampled_data) throughout (ready[->1]);
        endproperty
        STABLE_MD_DATA_A: assert property (stable_data)
            else $error("data must be stable during the MD transaction"); 

        property valid_offset;
            @(posedge clk) disable iff (~reset_n | ~has_checks)
            valid |-> ~$isunknown(offset);
        endproperty
        VALID_MD_OFFSET_A: assert property (valid_offset)
            else $error("offset must have a valid value during the MD transaction");
                
        property stable_offset;
            logic [OFFSET_WIDTH - 1 :0] sampled_offset;
            @(posedge clk) disable iff (~reset_n | ~has_checks)
            ($rose(valid) , sampled_offset = offset) |-> (offset == sampled_offset) throughout (ready[->1]);
        endproperty
        STABLE_MD_OFFSET_A: assert property (stable_offset)
            else $error("offset must be stable during the MD transaction");

        property valid_size;
            @(posedge clk) disable iff (~reset_n | ~has_checks)
            valid |-> ~$isunknown(size);
        endproperty
        VALID_MD_SIZE_A: assert property (valid_size)
            else $error("size must have a valid value during the MD transaction");

        property stable_size;
            logic [SIZE_WIDTH - 1 : 0] size_sampled ;
            @(posedge clk) disable iff (~reset_n | ~has_checks)
            ($rose(valid) , size_sampled = size ) |-> (size == size_sampled) throughout (ready[->1]);
        endproperty
        STABLE_MD_SIZE_A: assert property (stable_size)
            else $error("size must be stable during the MD transaction");

        // size must have a value > 0
        property not_zero_size ;
            @(posedge clk) disable iff (~reset_n | ~has_checks)
            valid |-> size!==0;
        endproperty
        NOT_ZERO_SIZE_A: assert property (not_zero_size)
            else $error("size mustn't hold a value zero");

        // size_offset valid combinations
        property legal_size_offset;
            @(posedge clk) disable iff (~reset_n | ~has_checks)
            valid |-> (((ALGN_DATA_WIDTH / 8) + offset) % size == 0) ||
            ((size + offset) <= (ALGN_DATA_WIDTH / 8));
        endproperty
        LEGAL_SIZE_OFFSET_A: assert property (legal_size_offset)
            else $error("illegal sizexoffset combiniations");
        

        property valid_err;
            @(posedge clk) disable iff (~reset_n | ~has_checks)
            valid && ready |-> ~$isunknown(err);
        endproperty
        VALID_ERR_A: assert property (valid_err)
            else $error("err must have a valid value at the end of the MD transaction");
        
        property high_err;
            @(posedge clk) disable iff (~reset_n | ~has_checks)
            err |-> (valid && ready);
        endproperty
        HIGH_ERR_A: assert property (high_err)
            else $error("err must be high only when valid and ready are high");
            

    endinterface


`endif