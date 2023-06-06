`timescale 1ns/1ps
`default_nettype none

module station_writer #(
    parameter WQE_WIDTH            = 512 ,
    parameter PWQE_BUF_ADDR_WIDTH  = 2   ,
    parameter PWQE_BUF_WIDTH       = 512 ,
    parameter PWQE_SLOT_NUM        = 4   ,
    parameter PWQE_SLOT_ADDR_WIDTH = 2
)(
    input wire                              clk             ,
    input wire                              rst_n           ,
    // if* with wqe_cache (bs_group)
    input  wire [PWQE_SLOT_NUM-1:0]         i_bs_fifo_empty ,
    output reg  [PWQE_SLOT_NUM-1:0]         o_bs_fifo_rd    ,
    input  wire                             i_bs_wqe_val    ,
    input  wire [WQE_WIDTH-1:0]             i_bs_wqe        ,                   
    // if* with station_buffer 
    output wire                             o_ren_0         ,
    output reg                              o_wen_0         ,
    output reg  [PWQE_BUF_ADDR_WIDTH-1:0]   o_addr_0        ,
    output reg  [PWQE_BUF_WIDTH-1:0]        o_din_0         ,
    output reg                              o_set_req       ,
    output reg  [PWQE_SLOT_ADDR_WIDTH-1:0]  o_set_addr      ,
    input  wire [PWQE_SLOT_NUM-1:0]         i_slot_status
);

    localparam WQE_WRID_LSB                   = 0                    ;
    localparam WQE_WRID_MSB                   = 63                   ;
    localparam WQE_QPID_LSB                   = 328                  ;
    localparam WQE_QPID_MSB                   = WQE_QPID_LSB+3       ;

    reg wr_pending;
    wire rst;
    wire rr_ena;
    wire [3:0] rr_req;
    wire [3:0] rr_result;
    reg [1:0] rr_result_dec_r;

    assign rst = ~rst_n;
    assign rr_req = ~i_bs_fifo_empty & ~i_slot_status;
    assign rr_ena = |rr_req & ~wr_pending & ~o_set_req;
    // TODO: Currently, only one group of BS WQE is used for
    // TODO: micro benchmark. We simplify the implementation here.
    // TODO: implement bs_scheduler here
    // pop bs wqe from wqe_cache
    always @(posedge clk or negedge rst_n)
        begin
            if(~rst_n)
                begin
                    o_bs_fifo_rd <= {PWQE_SLOT_NUM{1'b0}};
                end
            else if(|o_bs_fifo_rd)
                begin
                    o_bs_fifo_rd <= {PWQE_SLOT_NUM{1'b0}};
                end
            else if(rr_ena)
                begin
                    o_bs_fifo_rd <= rr_result;
                end
            else
                begin
                    o_bs_fifo_rd <= {PWQE_SLOT_NUM{1'b0}};
                end
        end
    
    always @(posedge clk or negedge rst_n)
        begin
            if(~rst_n)
                begin
                    wr_pending <= 1'b0;
                end
            else if(|o_bs_fifo_rd)
                begin
                    wr_pending <= 1'b1;
                end
            else if(i_bs_wqe_val)
                begin
                    wr_pending <= 1'b0;
                end
        end
    // always latch the value of rr_result for valid arbitration
    always @(posedge clk or negedge rst_n)
        begin
            if(~rst_n)
                begin
                    rr_result_dec_r <= 2'h0;
                end
            else if(rr_ena)
                begin
                    case(rr_result) 
                    4'b0001:
                        begin
                            rr_result_dec_r <= 2'h0;
                        end
                    4'b0010:
                        begin
                            rr_result_dec_r <= 2'h1;
                        end
                    4'b0100:
                        begin
                            rr_result_dec_r <= 2'h2;
                        end
                    4'b1000:
                        begin
                            rr_result_dec_r <= 2'h3;
                        end
                    endcase
                end
        end
    // write station_buffer
    assign o_ren_0 = 1'b0;
    always @(posedge clk or negedge rst_n)
        begin
            if(~rst_n)
                begin
                    o_wen_0 <= 1'b0;
                    o_addr_0 <= {PWQE_BUF_ADDR_WIDTH{1'b0}};
                    o_din_0 <= {PWQE_BUF_WIDTH{1'b0}}; 
                end
            else if(i_bs_wqe_val)
                begin
                    o_wen_0 <= 1'b1;
                    o_addr_0 <= rr_result_dec_r;
                    o_din_0 <= i_bs_wqe;
                end
            else
                begin
                    o_wen_0 <= 1'b0;
                    o_addr_0 <= {PWQE_BUF_ADDR_WIDTH{1'b0}};
                    o_din_0 <= {PWQE_BUF_WIDTH{1'b0}}; 
                end
        end

    always @(posedge clk or negedge rst_n)
        begin
            if(~rst_n)
                begin
                    o_set_req <= 1'b0;
                    o_set_addr <= {PWQE_SLOT_ADDR_WIDTH{1'b0}}; 
                end
            else if(i_bs_wqe_val)
                begin
                    o_set_req <= 1'b1;
                    o_set_addr <= rr_result_dec_r; 
                end
            else
                begin
                    o_set_req <= 1'b0;
                    o_set_addr <= {PWQE_SLOT_ADDR_WIDTH{1'b0}};
                end
        end

    rr_4_no_delay u_rr_4_no_delay(
        .sys_clk ( clk     ),
        .sys_rst ( rst     ),
        .rr_ena  ( rr_ena  ),
        .rr_req  ( rr_req  ),
        .rr_result  ( rr_result  )
    );

    // always @(posedge clk)
    //     begin
    //         if(o_wen_0)
    //             begin
    //                 $display("@ %0t : Write QPID is %0h, WRID is %0h", $time, 
    //                     o_din_0[WQE_QPID_MSB:WQE_QPID_LSB],
    //                     o_din_0[WQE_WRID_MSB:WQE_WRID_LSB]);
    //             end
    //     end

endmodule