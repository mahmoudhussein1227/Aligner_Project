`ifndef CFS_ALGN_IF_SV
    `define CFS_ALGN_IF_SV


    interface cfs_algn_if(input bit clk);
        logic reset_n;
        logic irq;
        logic rx_fifo_push;
        logic rx_fifo_pop;
        logic tx_fifo_push;        
        logic tx_fifo_pop;
    endinterface

`endif