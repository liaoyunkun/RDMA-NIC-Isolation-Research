`timescale 1ns/1ps
`default_nettype none

module wqe_cache #(
    parameter WQE_WIDTH      = 512,
    parameter QP_PTR_WIDTH   = 4
)(
    input  wire                    clk, 
    input  wire                    rst_n,
    input  wire                    i_wqe_cache_wr,
    input  wire [WQE_WIDTH-1:0]    i_wqe,
    output wire                    o_wqe_cache_alfull,
    output wire                    o_wqe_cache_empty,
    input  wire                    i_wqe_cache_rd,
    output reg                     o_wqe_val,
    output wire [WQE_WIDTH-1:0]    o_wqe,
    output wire                    o_wqe_cache_wr_val,
    output wire [QP_PTR_WIDTH-1:0] o_wqe_cache_wr_qpn,
    output wire [63:0]             o_wqe_cache_wr_wrid
);
    localparam WQE_WRID_LSB = 0                          ;
    localparam WQE_WRID_MSB = 63                         ;
    localparam WQE_QPID_LSB = 328                        ;
    localparam WQE_QPID_MSB = WQE_QPID_LSB+QP_PTR_WIDTH-1;

    wire rst;
    wire [WQE_WIDTH-1:0] wqe_wdata;
    wire wqe_wen;
    wire wqe_ren;
    wire [WQE_WIDTH-1:0] wqe_rdata;
    wire wqe_full;
    wire wqe_alfull;
    wire wqe_empty;

    assign rst = ~rst_n;
    assign wqe_wdata = i_wqe;
    assign wqe_wen = i_wqe_cache_wr & ~wqe_full;
    assign o_wqe_cache_alfull = wqe_alfull;
    assign o_wqe_cache_empty = wqe_empty;
    assign wqe_ren = i_wqe_cache_rd;
    assign o_wqe = wqe_rdata;

    assign o_wqe_cache_wr_val = wqe_wen;
    assign o_wqe_cache_wr_qpn = wqe_wdata[WQE_QPID_MSB:WQE_QPID_LSB];
    assign o_wqe_cache_wr_wrid = wqe_wdata[WQE_WRID_MSB:WQE_WRID_LSB];

    // SFIFO read latency is 1 clock
    always @(posedge clk or negedge rst_n)
        begin
            if(~rst_n)
                begin
                    o_wqe_val <= 1'b0;
                end
            else 
                begin
                    o_wqe_val <= wqe_ren;
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
    ) u_wqe_queue (
        .sys_clk  (clk               ),
        .sys_rst  (rst               ),
        .wdata    (wqe_wdata         ),
        .wen      (wqe_wen           ),
  
        .ren      (wqe_ren           ),
        .rdata    (wqe_rdata         ),
  
        .alfull   (wqe_alfull),
        .full     (wqe_full          ),
        .alempty  (                  ),
        .empty    (wqe_empty         )
    );

endmodule