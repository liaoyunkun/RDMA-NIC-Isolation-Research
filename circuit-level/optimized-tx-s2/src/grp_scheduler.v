`default_nettype none
`timescale 1ns/1ps

module grp_scheduler #(
    parameter WQE_WIDTH = 512,
    parameter PWQE_SLOT_NUM = 4,
    parameter PWQE_BUF_ADDR_WIDTH = 2,
    parameter PWQE_BUF_WIDTH = 512
)(
    input  wire                             clk              ,
    input  wire                             rst_n            ,
    // if* with wqe_cache
    input  wire                             i_ls_wqe_empty   ,
    output reg                              o_ls_wqe_ren     ,
    input  wire [WQE_WIDTH-1:0]             i_ls_wqe_rdata   ,
    // if* with station_buffer
    output reg                              o_ren_1          ,
    output reg                              o_wen_1          ,
    output reg  [PWQE_BUF_ADDR_WIDTH-1:0]   o_addr_1         ,
    output reg  [PWQE_BUF_WIDTH-1:0]        o_din_1          ,
    input  wire [PWQE_BUF_WIDTH-1:0]        i_dout_1         ,
    input  wire [PWQE_SLOT_NUM-1:0]         i_slot_status    ,
    // if* with ib_transport
    output wire                             o_wqe_cache_empty,
    input  wire                             i_wqe_cache_rd   ,
    output reg                              o_wqe_val        ,
    output reg                              o_wqe_type       ,
    output reg [PWQE_BUF_ADDR_WIDTH-1:0]    o_wqe_addr       ,
    output wire [WQE_WIDTH-1:0]             o_wqe            ,

    input  wire                             i_pwqe_wb        ,
    input  wire [PWQE_BUF_ADDR_WIDTH-1:0]   i_pwqe_addr      ,
    input  wire [WQE_WIDTH-1:0]             i_pwqe
);

    wire rst;
    wire rr_ena;
    wire [1:0] rr_req;
    wire [1:0] rr_result;
    reg  [1:0] rr_result_r;

    reg wqe_cache_rd_r;

    assign o_wqe_cache_empty = i_ls_wqe_empty && 
                        (i_slot_status == {PWQE_SLOT_NUM{1'b0}});
    assign rr_ena = (i_wqe_cache_rd | wqe_cache_rd_r) & (|rr_req);
    assign rr_req = {|i_slot_status, ~i_ls_wqe_empty};
    assign rst = ~rst_n;

    
    always @(posedge clk or negedge rst_n)
        begin
            if(~rst_n)
                begin
                    wqe_cache_rd_r <= 1'b0;
                end
            else if(i_wqe_cache_rd & ~(|rr_req))
                begin
                    // assert
                    wqe_cache_rd_r <= 1'b1;
                end
            else if(wqe_cache_rd_r & (|rr_req))
                begin
                    // clear
                    wqe_cache_rd_r <= 1'b0;
                end
            // otherwise, keep the value
        end
    
    always @(posedge clk or negedge rst_n)
        begin
            if(~rst_n)
                begin
                    rr_result_r <= 2'h0;
                end
            else if(rr_ena)
                begin
                    rr_result_r <= rr_result;
                end
        end
    // select latency-sensitive group
    always @(posedge clk or negedge rst_n)
        begin
            if(~rst_n)
                begin
                    o_ls_wqe_ren <= 1'b0;
                end
            else if(rr_ena && rr_result == 2'b01)
                begin
                    o_ls_wqe_ren <= 1'b1;
                end
            else
                begin
                    o_ls_wqe_ren <= 1'b0;
                end
        end
    // select bandwidth-sensitive group
    always @(posedge clk or negedge rst_n)
        begin
            if(~rst_n)
                begin
                    o_ren_1 <= 1'b0;
                end
            else if(rr_ena && rr_result == 2'b10)
                begin
                    o_ren_1 <= 1'b1;
                end
            else
                begin
                    o_ren_1 <= 1'b0;
                end
        end
    always @(posedge clk or negedge rst_n)
        begin
            if(~rst_n)
                begin
                    o_wen_1 <= 1'b0;
                end
            else
                begin
                    o_wen_1 <= i_pwqe_wb;
                end
        end
    always @(posedge clk or negedge rst_n)
        begin
            if(~rst_n)
                begin
                    o_addr_1 <= {PWQE_BUF_ADDR_WIDTH{1'b0}};
                end
            else if(rr_ena && rr_result == 2'b10)
                begin
                    // TODO: fixed slot
                    o_addr_1 <= {PWQE_BUF_ADDR_WIDTH{1'b0}};
                end
            else if(i_pwqe_wb)
                begin
                    o_addr_1 <= i_pwqe_addr;
                end
        end

    always @(posedge clk or negedge rst_n)
        begin
            if(~rst_n)
                begin
                    o_din_1 <= {PWQE_BUF_WIDTH{1'b0}};
                end
            else if(i_pwqe_wb)
                begin
                    o_din_1 <= i_pwqe;
                end
        end
    // both ls-fifo and bs-dpsram read latency is 1 cycle
    always @(posedge clk or negedge rst_n)
        begin
            if(~rst_n)
                begin
                    o_wqe_val <= 1'b0;
                end
            else
                begin
                    o_wqe_val <= o_ls_wqe_ren | o_ren_1;
                end
        end

    reg ls_wqe_rdata_val;

    always @(posedge clk or negedge rst_n)
        begin
            if(~rst_n)
                begin
                    ls_wqe_rdata_val <= 1'b0;
                end
            else 
                begin
                    ls_wqe_rdata_val <= o_ls_wqe_ren;
                end
        end

    assign o_wqe = (ls_wqe_rdata_val == 1'b1)? i_ls_wqe_rdata : i_dout_1;

    // type of selected wqe
    always @(posedge clk or negedge rst_n)
        begin
            if(~rst_n)
                begin
                    o_wqe_type <= 1'b0;
                end
            else if(o_ls_wqe_ren)
                begin
                    o_wqe_type <= 1'b0;  // latency-sensitve wqe
                end
            else if(o_ren_1)
                begin
                    o_wqe_type <= 1'b1;  // bandwidth-sensitive wqe
                end
        end
    // addr of selected pwqe
    always @(posedge clk or negedge rst_n)
        begin
            if(~rst_n)
                begin
                    o_wqe_addr <= {PWQE_BUF_ADDR_WIDTH{1'b0}};
                end
            else if(o_ren_1)
                begin
                    // TODO: fixed slot
                    o_wqe_addr <= {PWQE_BUF_ADDR_WIDTH{1'b0}};
                end
        end
    
    rr_2_no_delay u_rr_2_no_delay(
        .sys_clk    ( clk      ),
        .sys_rst    ( rst      ),
        .rr_ena     ( rr_ena   ),
        .rr_req     ( rr_req   ),
        .rr_result  ( rr_result)
        );
endmodule