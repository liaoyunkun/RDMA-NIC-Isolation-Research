`timescale 1ns/1ps
`default_nettype none

module wqe_cache #(
    parameter WQE_WIDTH      = 512,
    parameter MAX_QP         = 16 ,
    parameter QP_PTR_WIDTH   = 4  ,
    parameter PWQE_SLOT_NUM  = 4  
)(
    input  wire                     clk, 
    input  wire                     rst_n,
    // if* with wqe_fetch
    input  wire                     i_wqe_cache_wr,
    input  wire [WQE_WIDTH-1:0]     i_wqe,
    output wire [MAX_QP-1:0]        o_wqe_cache_alfull,
    output wire [MAX_QP-1:0]        o_wqe_cache_full,
    // if* with grp_scheduler
    output wire                     o_ls_wqe_empty,
    input  wire                     i_ls_wqe_ren,
    output wire [WQE_WIDTH-1:0]     o_ls_wqe_rdata,
    // if* with slice_station
    output wire [PWQE_SLOT_NUM-1:0] o_bs_fifo_empty,
    input  wire [PWQE_SLOT_NUM-1:0] i_bs_fifo_rd,
    output reg                      o_bs_wqe_val,
    output reg  [WQE_WIDTH-1:0]     o_bs_wqe,
    output wire                     o_wqe_cache_wr_val,
    output reg  [QP_PTR_WIDTH-1:0]  o_wqe_cache_wr_qpn,
    output reg  [63:0]              o_wqe_cache_wr_wrid
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
    // Currently, only 2 BS-QPs are considered
    wire [WQE_WIDTH-1:0] bs_wqe_wdata [0:PWQE_SLOT_NUM-1];
    wire [PWQE_SLOT_NUM-1:0] bs_wqe_wen;
    wire [PWQE_SLOT_NUM-1:0] bs_wqe_ren;
    reg  [PWQE_SLOT_NUM-1:0] bs_wqe_ren_r;
    wire [WQE_WIDTH-1:0] bs_wqe_rdata [0:PWQE_SLOT_NUM-1];
    wire [PWQE_SLOT_NUM-1:0] bs_wqe_full;
    wire [PWQE_SLOT_NUM-1:0] bs_wqe_alfull;
    wire [PWQE_SLOT_NUM-1:0] bs_wqe_empty;
    
    assign rst = ~rst_n;
    // if any fifo queue is in alfull, assert o_wqe_cache_alfull
    // assign o_wqe_cache_alfull = ls_wqe_alfull | (|bs_wqe_alfull);
    genvar i;
    generate
        for (i = 0; i < MAX_QP; i = i + 1) 
            begin
                if(i % 2 == 0)
                    begin
                        // latency-sensitive qp
                        assign o_wqe_cache_alfull[i] = ls_wqe_alfull;
                        assign o_wqe_cache_full[i] = ls_wqe_full;
                    end
                else
                    begin
                        // bandwidth-sensitive qp
                        if(i <= 7)
                            begin
                                assign o_wqe_cache_alfull[i] = bs_wqe_alfull[i % 2];
                                assign o_wqe_cache_full[i] = bs_wqe_full[ i % 2];
                            end
                        else
                            begin
                                assign o_wqe_cache_alfull[i] = 1'b1;
                                assign o_wqe_cache_full[i] = 1'b1;
                            end
                    end
            end
    endgenerate
    
    // push wqe
    // currently, classify by the qp number directly
    // latency-sensitive qp
    assign ls_wqe_wdata = i_wqe;
    assign ls_wqe_wen = i_wqe_cache_wr & ~ls_wqe_full & 
                    (i_wqe[WQE_QPID_MSB:WQE_QPID_LSB] == 4'h0);
    // bandwidth-sensitve qp
    generate
        for(i = 0; i < PWQE_SLOT_NUM; i = i + 1)
            begin
                assign bs_wqe_wdata[i] = i_wqe;
                assign bs_wqe_wen[i] = i_wqe_cache_wr & ~bs_wqe_full[i] & 
                        (i_wqe[WQE_QPID_LSB] == 1'b1 &&   //  bandwidth-sensitive
                        i_wqe[WQE_QPID_MSB:WQE_QPID_LSB+1] == i);
            end
    endgenerate
    // TODO:
    assign o_wqe_cache_wr_val = ls_wqe_wen | (|bs_wqe_wen);
    always @(*)
        begin
            case({ls_wqe_wen, bs_wqe_wen}) 
            5'b1xxxx: 
                begin
                    o_wqe_cache_wr_qpn = ls_wqe_wdata[WQE_QPID_MSB:WQE_QPID_LSB];
                    o_wqe_cache_wr_wrid = ls_wqe_wdata[WQE_WRID_MSB:WQE_WRID_LSB];
                end  
            5'b00001:
                begin
                    o_wqe_cache_wr_qpn = bs_wqe_wdata[0][WQE_QPID_MSB:WQE_QPID_LSB];
                    o_wqe_cache_wr_wrid = bs_wqe_wdata[0][WQE_WRID_MSB:WQE_WRID_LSB];
                end
            5'b00010:
                begin
                    o_wqe_cache_wr_qpn = bs_wqe_wdata[1][WQE_QPID_MSB:WQE_QPID_LSB];
                    o_wqe_cache_wr_wrid = bs_wqe_wdata[1][WQE_WRID_MSB:WQE_WRID_LSB];
                end
            5'b00100:
                begin
                    o_wqe_cache_wr_qpn = bs_wqe_wdata[2][WQE_QPID_MSB:WQE_QPID_LSB];
                    o_wqe_cache_wr_wrid = bs_wqe_wdata[2][WQE_WRID_MSB:WQE_WRID_LSB];
                end
            5'b01000:
                begin
                    o_wqe_cache_wr_qpn = bs_wqe_wdata[3][WQE_QPID_MSB:WQE_QPID_LSB];
                    o_wqe_cache_wr_wrid = bs_wqe_wdata[3][WQE_WRID_MSB:WQE_WRID_LSB];
                end
            default:
                begin
                    o_wqe_cache_wr_qpn = ls_wqe_wdata[WQE_QPID_MSB:WQE_QPID_LSB];
                    o_wqe_cache_wr_wrid = ls_wqe_wdata[WQE_WRID_MSB:WQE_WRID_LSB];
                end 
            endcase
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

    assign bs_wqe_ren = i_bs_fifo_rd;
    always @(posedge clk or negedge rst_n)
        begin
            if(~rst_n)
                begin
                    bs_wqe_ren_r <= {PWQE_SLOT_NUM{1'b0}};
                end
            else 
                begin
                    bs_wqe_ren_r <= bs_wqe_ren;
                end
        end
    always @(*)
        begin
            case(bs_wqe_ren_r)
            4'b0001:
                begin
                    o_bs_wqe = bs_wqe_rdata[0];
                end
            4'b0010:
                begin
                    o_bs_wqe = bs_wqe_rdata[1];
                end
            4'b0100:
                begin
                    o_bs_wqe = bs_wqe_rdata[2];
                end
            4'b1000:
                begin
                    o_bs_wqe = bs_wqe_rdata[3];
                end
            default:
                begin
                    o_bs_wqe = bs_wqe_rdata[0];
                end
            endcase    
        end
        
    assign o_bs_fifo_empty = bs_wqe_empty;
    always @(posedge clk or negedge rst_n)
        begin
            if(~rst_n)
                begin
                    o_bs_wqe_val <= 1'b0;
                end
            else
                begin
                    o_bs_wqe_val <= |bs_wqe_ren;
                end
        end
    // generate
    //     for (i = 0; i < PWQE_SLOT_NUM; i = i + 1) 
    //         begin
    //             gen_sfifo #(
    //             .DEVICE_FIFO("GENERAL"), 
    //             .IS_ARRAY_RAM(0),
    //             .RAM_STYLE_MODE("block"), 
    //             .WIDTH_DATA(WQE_WIDTH),
    //             .WIDTH_ADDR(4),
    //             .WATERAGE_UP(1), 
    //             .WATERAGE_DOWN(1), 
    //             .SHOW_AHEAD(0), 
    //             .OVERLIMIT_CHECK(1), 
    //             .OUT_REGISTERED(1)                
    //             ) u_bs_wqe_queue (
    //                 .sys_clk  (clk               ),
    //                 .sys_rst  (rst               ),
    //                 .wdata    (bs_wqe_wdata[i]   ),
    //                 .wen      (bs_wqe_wen[i]     ),
            
    //                 .ren      (bs_wqe_ren[i]     ),
    //                 .rdata    (bs_wqe_rdata[i]   ),
            
    //                 .alfull   (bs_wqe_alfull[i]  ),
    //                 .full     (bs_wqe_full[i]    ),
    //                 .alempty  (                  ),
    //                 .empty    (bs_wqe_empty[i]   )
    //             );
    //         end
    // endgenerate

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
                ) u_bs_wqe_queue_0 (
                    .sys_clk  (clk               ),
                    .sys_rst  (rst               ),
                    .wdata    (bs_wqe_wdata[0]   ),
                    .wen      (bs_wqe_wen[0]     ),
            
                    .ren      (bs_wqe_ren[0]     ),
                    .rdata    (bs_wqe_rdata[0]   ),
            
                    .alfull   (bs_wqe_alfull[0]  ),
                    .full     (bs_wqe_full[0]    ),
                    .alempty  (                  ),
                    .empty    (bs_wqe_empty[0]   )
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
                ) u_bs_wqe_queue_1 (
                    .sys_clk  (clk               ),
                    .sys_rst  (rst               ),
                    .wdata    (bs_wqe_wdata[1]   ),
                    .wen      (bs_wqe_wen[1]     ),
            
                    .ren      (bs_wqe_ren[1]     ),
                    .rdata    (bs_wqe_rdata[1]   ),
            
                    .alfull   (bs_wqe_alfull[1]  ),
                    .full     (bs_wqe_full[1]    ),
                    .alempty  (                  ),
                    .empty    (bs_wqe_empty[1]   )
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
                ) u_bs_wqe_queue_2 (
                    .sys_clk  (clk               ),
                    .sys_rst  (rst               ),
                    .wdata    (bs_wqe_wdata[2]   ),
                    .wen      (bs_wqe_wen[2]     ),
            
                    .ren      (bs_wqe_ren[2]     ),
                    .rdata    (bs_wqe_rdata[2]   ),
            
                    .alfull   (bs_wqe_alfull[2]  ),
                    .full     (bs_wqe_full[2]    ),
                    .alempty  (                  ),
                    .empty    (bs_wqe_empty[2]   )
                );

    gen_sfifo #(
                .DEVICE_FIFO("GENERAL"), 
                .IS_ARRAY_RAM(0),
                .RAM_STYLE_MODE("block"), 
                .WIDTH_DATA(WQE_WIDTH),
                .WIDTH_ADDR(4), // Old Cfg is 4
                .WATERAGE_UP(1), 
                .WATERAGE_DOWN(1), 
                .SHOW_AHEAD(0), 
                .OVERLIMIT_CHECK(1), 
                .OUT_REGISTERED(1)                
                ) u_bs_wqe_queue_3 (
                    .sys_clk  (clk               ),
                    .sys_rst  (rst               ),
                    .wdata    (bs_wqe_wdata[3]   ),
                    .wen      (bs_wqe_wen[3]     ),
            
                    .ren      (bs_wqe_ren[3]     ),
                    .rdata    (bs_wqe_rdata[3]   ),
            
                    .alfull   (bs_wqe_alfull[3]  ),
                    .full     (bs_wqe_full[3]    ),
                    .alempty  (                  ),
                    .empty    (bs_wqe_empty[3]   )
                );


    // always @(posedge clk)
    //     begin
    //         if(~bs_wqe_alfull[0] && bs_wqe_alfull[1])
    //             begin
    //                 $display("BS-0 is not alfull, but BS-1 is alfull");    
    //             end
    //     end
    // always @(posedge clk)
    //     begin
    //         if(bs_wqe_wen[0])
    //             begin
    //                 $display("@ %0t : QPID is %0h,  WRID is %0h", $time, 
    //                     bs_wqe_wdata[0][WQE_QPID_MSB:WQE_QPID_LSB], 
    //                     bs_wqe_wdata[0][WQE_WRID_MSB:WQE_WRID_LSB]);
    //             end
    //         else if(bs_wqe_wen[1])
    //             begin
    //                 $display("@ %0t : WRID is %0h", $time, 
    //                 bs_wqe_wdata[1][WQE_QPID_MSB:WQE_QPID_LSB],
    //                 bs_wqe_wdata[1][WQE_WRID_MSB:WQE_WRID_LSB]);
    //             end
    //     end

    // always @(posedge clk)
    //     begin
    //         if(bs_wqe_ren[0])
    //             begin
    //                 $display("@ %0t : QPID is %0h, WRID is %0h", $time, 
    //                     bs_wqe_rdata[0][WQE_QPID_MSB:WQE_QPID_LSB],
    //                     bs_wqe_rdata[0][WQE_WRID_MSB:WQE_WRID_LSB]
    //                     );
    //             end
    //         else if(bs_wqe_ren[1])
    //             begin
    //                 $display("@ %0t : QPID is %0h, WRID is %0h", $time,
    //                     bs_wqe_rdata[1][WQE_QPID_MSB:WQE_QPID_LSB], 
    //                     bs_wqe_rdata[1][WQE_WRID_MSB:WQE_WRID_LSB]);
    //             end
    //     end

endmodule