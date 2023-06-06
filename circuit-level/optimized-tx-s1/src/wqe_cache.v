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

    // wire [WQE_WIDTH-1:0] wqe_wdata;
    // wire wqe_wen;
    // wire wqe_ren;
    // wire [WQE_WIDTH-1:0] wqe_rdata;
    // wire wqe_full;
    // wire wqe_alfull;
    // wire wqe_empty;
    wire [WQE_WIDTH-1:0] ls_wqe_wdata;
    wire ls_wqe_wen;
    wire ls_wqe_ren;
    wire [WQE_WIDTH-1:0] ls_wqe_rdata;
    wire ls_wqe_full;
    wire ls_wqe_alfull;
    wire ls_wqe_empty;

    wire [WQE_WIDTH-1:0] bs_wqe_wdata;
    wire bs_wqe_wen;
    wire bs_wqe_ren;
    wire [WQE_WIDTH-1:0] bs_wqe_rdata;
    wire bs_wqe_full;
    wire bs_wqe_alfull;
    wire bs_wqe_empty;

    wire rr_ena;
    wire [1:0] rr_req;
    wire [1:0] rr_result;
    reg ls_wqe_ren_r;
    
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
    // pop wqe
    assign o_wqe_cache_empty = ls_wqe_empty & bs_wqe_empty;
    assign rr_ena = i_wqe_cache_rd;
    assign rr_req = {~bs_wqe_empty, ~ls_wqe_empty};
    assign ls_wqe_ren = i_wqe_cache_rd & rr_result[0];
    assign bs_wqe_ren = i_wqe_cache_rd & rr_result[1];
    
    always @(posedge clk or negedge rst_n)
        begin
            if(~rst_n)
                begin 
                    ls_wqe_ren_r <= 1'b0;
                end
            else 
                begin
                    ls_wqe_ren_r <= ls_wqe_ren;
                end
        end
    assign o_wqe = (ls_wqe_ren_r == 1'b1)? ls_wqe_rdata : bs_wqe_rdata;
    always @(posedge clk or negedge rst_n)
        begin
            if(~rst_n)
                begin
                    o_wqe_val <= 1'b0;
                end
            else
                begin
                    o_wqe_val <= ls_wqe_ren | bs_wqe_ren;
                end
        end
        
    assign o_wqe_cache_wr_val = ls_wqe_wen | bs_wqe_wen;
    assign o_wqe_cache_wr_qpn = i_wqe[WQE_QPID_MSB:WQE_QPID_LSB];
    assign o_wqe_cache_wr_wrid = i_wqe[WQE_WRID_MSB:WQE_WRID_LSB];

    // SFIFO read latency is 1 clock
    // always @(posedge clk or negedge rst_n)
    //     begin
    //         if(~rst_n)
    //             begin
    //                 o_wqe_val <= 1'b0;
    //             end
    //         else 
    //             begin
    //                 o_wqe_val <= wqe_ren;
    //             end
    //     end

    // separate queue for latency-sensitive and bandwidth-sensitive wqe
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
  
        .ren      (ls_wqe_ren        ),
        .rdata    (ls_wqe_rdata      ),
  
        .alfull   (ls_wqe_alfull     ),
        .full     (ls_wqe_full       ),
        .alempty  (                  ),
        .empty    (ls_wqe_empty      )
    );

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

    rr_2_no_delay u_rr_2_no_delay(
        .sys_clk ( clk ),
        .sys_rst ( rst ),
        .rr_ena  ( rr_ena  ),
        .rr_req  ( rr_req  ),
        .rr_result  ( rr_result  )
    );

endmodule