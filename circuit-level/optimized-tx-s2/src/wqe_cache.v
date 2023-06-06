`timescale 1ns/1ps
`default_nettype none

module wqe_cache #(
    parameter WQE_WIDTH      = 512,
    parameter QP_PTR_WIDTH   = 4  ,
    parameter PWQE_SLOT_NUM  = 4  
)(
    input  wire                     clk, 
    input  wire                     rst_n,
    // if* with wqe_fetch
    input  wire                     i_wqe_cache_wr,
    input  wire [WQE_WIDTH-1:0]     i_wqe,
    output wire                     o_wqe_cache_alfull,
    // if* with grp_scheduler
    output wire                     o_ls_wqe_empty,
    input  wire                     i_ls_wqe_ren,
    output wire [WQE_WIDTH-1:0]     o_ls_wqe_rdata,
    // if* with slice_station
    output wire [PWQE_SLOT_NUM-1:0] o_bs_fifo_empty,
    input  wire [PWQE_SLOT_NUM-1:0] i_bs_fifo_rd,
    output reg                      o_bs_wqe_val,
    output wire [WQE_WIDTH-1:0]     o_bs_wqe,
    output wire                     o_wqe_cache_wr_val,
    output wire [QP_PTR_WIDTH-1:0]  o_wqe_cache_wr_qpn,
    output wire [63:0]              o_wqe_cache_wr_wrid
);
    localparam WQE_WRID_LSB = 0                          ;
    localparam WQE_WRID_MSB = 63                         ;
    localparam WQE_QPID_LSB = 328                        ;
    localparam WQE_QPID_MSB = WQE_QPID_LSB+QP_PTR_WIDTH-1;

    wire rst;

    wire [WQE_WIDTH-1:0] ls_wqe_wdata;
    wire ls_wqe_wen;
    wire ls_wqe_full;
    wire ls_wqe_alfull;

    wire [WQE_WIDTH-1:0] bs_wqe_wdata;
    wire bs_wqe_wen;
    wire bs_wqe_ren;
    wire [WQE_WIDTH-1:0] bs_wqe_rdata;
    wire bs_wqe_full;
    wire bs_wqe_alfull;
    wire bs_wqe_empty;
    
    assign rst = ~rst_n;
    // push wqe
    // currently, classify by the qp number directly
    assign o_wqe_cache_alfull = ls_wqe_alfull | bs_wqe_alfull;
    assign ls_wqe_wdata = i_wqe;
    assign ls_wqe_wen = i_wqe_cache_wr & ~ls_wqe_full & 
                    (i_wqe[WQE_QPID_MSB:WQE_QPID_LSB] == 4'h0);
    assign bs_wqe_wdata = i_wqe;
    assign bs_wqe_wen = i_wqe_cache_wr & ~bs_wqe_full &
                    (i_wqe[WQE_QPID_MSB:WQE_QPID_LSB] == 4'h1);
    assign o_wqe_cache_wr_val = ls_wqe_wen | bs_wqe_wen;
    assign o_wqe_cache_wr_qpn = (ls_wqe_wen == 1'b1)? ls_wqe_wdata[WQE_QPID_MSB:WQE_QPID_LSB] : 
                                bs_wqe_wdata[WQE_QPID_MSB:WQE_QPID_LSB];
    assign o_wqe_cache_wr_wrid = (ls_wqe_wen == 1'b1)? ls_wqe_wdata[WQE_WRID_MSB:WQE_WRID_LSB] :
                                bs_wqe_wdata[WQE_WRID_MSB:WQE_WRID_LSB];
    
    gen_sfifo #(
        .DEVICE_FIFO("GENERAL"), 
        .IS_ARRAY_RAM(0),
        .RAM_STYLE_MODE("block"), 
        .WIDTH_DATA(WQE_WIDTH),
        .WIDTH_ADDR(4),
        .WATERAGE_UP(1), 
        .WATERAGE_DOWN(1), 
        .SHOW_AHEAD(0), 
        .OVERLIMIT_CHECK(1), 
        .OUT_REGISTERED(1)                
    ) u_ls_wqe_queue (
        .sys_clk  (clk               ),
        .sys_rst  (rst               ),
        .wdata    (ls_wqe_wdata      ),
        .wen      (ls_wqe_wen        ),
  
        .ren      (i_ls_wqe_ren      ),
        .rdata    (o_ls_wqe_rdata    ),
  
        .alfull   (ls_wqe_alfull     ),
        .full     (ls_wqe_full       ),
        .alempty  (                  ),
        .empty    (o_ls_wqe_empty    )
    );

    assign bs_wqe_ren = i_bs_fifo_rd[0];
    assign o_bs_wqe = bs_wqe_rdata;
    assign o_bs_fifo_empty = {{(PWQE_SLOT_NUM-1){1'b1}}, bs_wqe_empty};

    always @(posedge clk or negedge rst_n)
        begin
            if(~rst_n)
                begin
                    o_bs_wqe_val <= 1'b0;
                end
            else
                begin
                    o_bs_wqe_val <= bs_wqe_ren;
                end
        end
    gen_sfifo #(
        .DEVICE_FIFO("GENERAL"), 
        .IS_ARRAY_RAM(0),
        .RAM_STYLE_MODE("block"), 
        .WIDTH_DATA(WQE_WIDTH),
        .WIDTH_ADDR(4),
        .WATERAGE_UP(1), 
        .WATERAGE_DOWN(1), 
        .SHOW_AHEAD(0), 
        .OVERLIMIT_CHECK(1), 
        .OUT_REGISTERED(1)                
    ) u_bs_wqe_queue (
        .sys_clk  (clk               ),
        .sys_rst  (rst               ),
        .wdata    (bs_wqe_wdata      ),
        .wen      (bs_wqe_wen        ),
  
        .ren      (bs_wqe_ren        ),
        .rdata    (bs_wqe_rdata      ),
  
        .alfull   (bs_wqe_alfull     ),
        .full     (bs_wqe_full       ),
        .alempty  (                  ),
        .empty    (bs_wqe_empty      )
    );

endmodule