`ifndef CFS_APB_IF_SV
    `define CFS_APB_IF_SV

    `ifndef CFS_APB_MAX_DATA_WIDTH
        `define CFS_APB_MAX_DATA_WIDTH 32
    `endif

    `ifndef CFS_APB_MAX_ADDR_WIDTH
        `define CFS_APB_MAX_ADDR_WIDTH 16
    `endif

    interface cfs_apb_if(input bit clk);

        logic        preset_n;
        logic        psel;
        logic        penable;
        logic        pwrite;
        logic [`CFS_APB_MAX_ADDR_WIDTH - 1:0] paddr;
        logic [`CFS_APB_MAX_DATA_WIDTH - 1:0] pwdata;
        logic        pready;
        logic [`CFS_APB_MAX_DATA_WIDTH - 1:0] prdata;
        logic        pslverr;


        bit has_checks;
        initial begin
            has_checks = 1;
        end

        // checks 

        // setup phase
        sequence setup_phase;
            ((psel == 1) && ($past(psel) == 0)) || ((psel == 1)&&($past(psel == 1)) && ($past(pready == 1)));
        endsequence

        // access phase
        sequence access_phase;
            (psel == 1) && (penable == 1);
        endsequence

        // once the setup phase is entered paddr should have a vaild value
        property valid_paddr ;
            @(posedge clk) disable iff (~preset_n | ~has_checks)
            setup_phase |-> $isunknown(paddr)==0 ;
        endproperty

        KNOWN_PADDR: assert property (valid_paddr)
                    else $error("KNOWN_PADDR failed");

        // once the setup phase is entered pwrite should have a vaild value
        property valid_pwrite ;
            @(posedge clk) disable iff (~preset_n | ~has_checks)
            setup_phase |-> $isunknown(pwrite)==0 ;
        endproperty

        KNOWN_PWRITE: assert property (valid_pwrite)
                    else $error("KNOWN_PWRITE failed");

        // once the setup phase is entered pwdata should have a vaild value only when write operations is selected
        property valid_pwdata ;
            @(posedge clk) disable iff (~preset_n | ~has_checks | ~pwrite)
            (setup_phase) |-> $isunknown(pwdata)==0 ;
        endproperty

        KNOWN_PWDATA: assert property (valid_pwdata)
                    else $error("KNOWN_PWDATA failed");

        // the penable must be asserted one cycle after the setup phase
        property penable_is_low ;
            @(posedge clk) disable iff (~preset_n | ~has_checks)
            (setup_phase) |-> penable == 0 ;
        endproperty

        PENABLE_IS_LOW: assert property (penable_is_low)
                    else $error(" PENABLE_IS_LOW failed and penable must be deasserted during setup phase");

        // the penable must be asserted one cycle after the setup phase
        property enter_access_phase ;
            @(posedge clk) disable iff (~preset_n | ~has_checks)
            (setup_phase) |=> penable == 1 ;
        endproperty

        ENTER_ACCESS_PHASE: assert property (enter_access_phase)
                    else $error(" ENTER_ACCESS_PHASE failed and penable must be asserted the cycle after the setup phase");
        

        // pwdata must be stable in the access phase
        property stable_pwdata;
            @(posedge clk) disable iff (~preset_n | ~has_checks)
            ((access_phase) and (pwrite) ) |-> $stable(pwdata) == 1;
        endproperty

        STABLE_PWDATA: assert property (stable_pwdata)
                    else $error(" STABLE_PWDATA failed pwdata must be stable in the access phase");


        // pslverr must be valid at the end of the APB access
        property valid_pslverr;
            @(posedge clk) disable iff (~preset_n | ~has_checks)
            pready |-> ~$isunknown(pslverr);
        endproperty

        VALID_PSLVERR: assert property (valid_pslverr)
                    else $error(" VALID_PSLVERR failed pslverr must be valid at the end of the APB transaction");

    endinterface

    

`endif