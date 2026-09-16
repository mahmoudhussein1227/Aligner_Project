//`include "cfs_apb_if.sv"
//`include "cfs_md_if.sv"
`include "cfs_algn_test_pkg.sv"

module testbench();
    import uvm_pkg::*;
    //import cfs_apb_pkg::*;
    import cfs_algn_test_pkg::*;

    bit clk;
    // clk generation
    initial begin
        forever begin
            clk = #5 ~clk;
        end
    end

    // Initial reset generator
    initial begin
        apb_if.preset_n = 1;
        #6;
        apb_if.preset_n = 0;
        #30ns;
        apb_if.preset_n = 1;
    end

    // Interface instance
    cfs_apb_if      apb_if(.clk(clk));
    cfs_md_if#(32)  md_rx_if(.clk(clk));
    cfs_md_if#(32)  md_tx_if(.clk(clk));
    cfs_algn_if algn_if(.clk(clk));

    // Module instance
    cfs_aligner dut(
        // APB interface
        .clk            (clk),
        .reset_n        (apb_if.preset_n),
        .paddr          (apb_if.paddr),
        .pwrite         (apb_if.pwrite),
        .psel           (apb_if.psel),
        .penable        (apb_if.penable),
        .pwdata         (apb_if.pwdata),
        .pready         (apb_if.pready),
        .prdata         (apb_if.prdata),
        .pslverr        (apb_if.pslverr),
        // RX interface
        .md_rx_valid    (md_rx_if.valid),
        .md_rx_data     (md_rx_if.data),
        .md_rx_offset   (md_rx_if.offset),
        .md_rx_size     (md_rx_if.size),
        .md_rx_ready    (md_rx_if.ready),
        .md_rx_err      (md_rx_if.err),
        // TX interface
        .md_tx_valid    (md_tx_if.valid),
        .md_tx_data     (md_tx_if.data),
        .md_tx_offset   (md_tx_if.offset),
        .md_tx_size     (md_tx_if.size),
        .md_tx_ready    (md_tx_if.ready),
        .md_tx_err      (md_tx_if.err),
        //IRQ 
        .irq(algn_if.irq)
    );

    assign md_rx_if.reset_n = apb_if.preset_n;
    assign md_tx_if.reset_n = apb_if.preset_n;
    assign algn_if.reset_n  = apb_if.preset_n;

    // assign the push and pop signal

    assign algn_if.rx_fifo_push = dut.core.rx_fifo.push_ready & dut.core.rx_fifo.push_valid;
    assign algn_if.rx_fifo_pop  = dut.core.rx_fifo.pop_ready & dut.core.rx_fifo.pop_valid;
    assign algn_if.tx_fifo_push = dut.core.tx_fifo.push_ready & dut.core.tx_fifo.push_valid;
    assign algn_if.tx_fifo_pop  = dut.core.tx_fifo.pop_ready & dut.core.tx_fifo.pop_valid;

    // Main
    initial begin
        uvm_config_db#( virtual cfs_apb_if)::set(null, "uvm_test_top.env.apb_agent", "vif", apb_if);
        uvm_config_db#( virtual cfs_md_if#(32))::set( null, "uvm_test_top.env.md_agent_master",  "vif", md_rx_if);
        uvm_config_db#( virtual cfs_md_if#(32))::set( null, "uvm_test_top.env.md_agent_slave",   "vif", md_tx_if);
        uvm_config_db#( virtual cfs_algn_if)::set( null, "uvm_test_top.env",   "vif", algn_if);

        run_test("");
    end
endmodule