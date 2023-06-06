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
    wire rr2_ena;
    wire [1:0] rr2_req;
    wire [1:0] rr2_result;

    wire rr4_ena;
    wire [3:0] rr4_req;
    wire [3:0] rr4_result;
    reg  [3:0] rr4_result_r;
    reg  [1:0] rr4_result_dec;
    reg  [1:0] rr4_result_dec_r;

    reg wqe_cache_rd_r;

    wire wrr_req_val;
    wire wrr_req0;
    wire wrr_req1;
    wire wrr_req2;
    wire wrr_req3;
    wire [4:0] wrr_wt0;
    wire [4:0] wrr_wt1;
    wire [4:0] wrr_wt2;
    wire [4:0] wrr_wt3;
    wire wrr_gnt_busy;
    wire wrr_gnt_val;
    wire wrr_gnt0;
    wire wrr_gnt1;
    wire wrr_gnt2;
    wire wrr_gnt3;

    assign o_wqe_cache_empty = i_ls_wqe_empty && 
                        (i_slot_status == {PWQE_SLOT_NUM{1'b0}});

    assign rr2_ena = (i_wqe_cache_rd | wqe_cache_rd_r) & (|rr2_req);
    assign rr2_req = {|i_slot_status, ~i_ls_wqe_empty};

    assign rr4_ena = rr2_ena & (rr2_result == 2'b10);
    assign wrr_req_val = rr4_ena;

    assign rr4_req = i_slot_status;

    assign wrr_req0 = rr4_req[0];
    assign wrr_req1 = rr4_req[1];
    assign wrr_req2 = rr4_req[2];
    assign wrr_req3 = rr4_req[3];

    assign wrr_wt0 = 5'd8;
    assign wrr_wt1 = 5'd4;
    assign wrr_wt2 = 5'd2;
    assign wrr_wt3 = 5'd1; 

    assign wrr_gnt_busy = 1'b0;

    assign rr4_result = {wrr_gnt3, wrr_gnt2, wrr_gnt1, wrr_gnt0};

    assign rst = ~rst_n;
    
    always @(posedge clk or negedge rst_n)
        begin
            if(~rst_n)
                begin
                    wqe_cache_rd_r <= 1'b0;
                end
            else if(i_wqe_cache_rd & ~(|rr2_req))
                begin
                    // assert if arbitration is not available
                    wqe_cache_rd_r <= 1'b1;
                end
            else if(wqe_cache_rd_r & (|rr2_req))
                begin
                    // clear if arbitration is availables
                    wqe_cache_rd_r <= 1'b0;
                end
            // otherwise, keep the value
        end
    
    always @(posedge clk or negedge rst_n)
        begin
            if(~rst_n)
                begin
                    rr4_result_r <= 4'h0;
                end
            else if(wrr_gnt_val)
                begin
                    rr4_result_r <= rr4_result;
                end
        end
    // select latency-sensitive group
    always @(posedge clk or negedge rst_n)
        begin
            if(~rst_n)
                begin
                    o_ls_wqe_ren <= 1'b0;
                end
            else if(rr2_ena && rr2_result == 2'b01)
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
            else if(wrr_gnt_val)
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
    
    always @(*)
        begin
            case(rr4_result) 
            4'b0001:
                begin
                    rr4_result_dec = 2'b00;
                end
            4'b0010:
                begin
                    rr4_result_dec = 2'b01;
                end
            4'b0100:
                begin
                    rr4_result_dec = 2'b10;
                end
            4'b1000:
                begin
                    rr4_result_dec = 2'b11;
                end
            default:
                begin
                    rr4_result_dec = 2'b00;
                end
            endcase
        end

    always @(posedge clk or negedge rst_n)
        begin
            if(~rst_n)
                begin
                    o_addr_1 <= {PWQE_BUF_ADDR_WIDTH{1'b0}};
                end
            else if(wrr_gnt_val)
                begin
                    o_addr_1 <= rr4_result_dec;
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

    assign o_wqe = (o_ls_wqe_ren == 1'b1)? i_ls_wqe_rdata : i_dout_1;
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
                    rr4_result_dec_r <= 2'h0;
                end
            else if(wrr_gnt_val)
                begin
                    rr4_result_dec_r <= rr4_result_dec;
                end
        end

    always @(posedge clk or negedge rst_n)
        begin
            if(~rst_n)
                begin
                    o_wqe_addr <= {PWQE_BUF_ADDR_WIDTH{1'b0}};
                end
            else if(wrr_gnt_val)
                begin
                    o_wqe_addr <= rr4_result_dec;
                end
        end
    
    rr_2_no_delay u_rr_2_no_delay(
        .sys_clk    ( clk      ),
        .sys_rst    ( rst      ),
        .rr_ena     ( rr2_ena   ),
        .rr_req     ( rr2_req   ),
        .rr_result  ( rr2_result)
        );

    wrr4_arbit u_wrr4_arbit(
        .clk      ( clk          ),
        .rst_n    ( rst_n        ),
        .req_val  ( wrr_req_val  ),
        .req0     ( wrr_req0     ),
        .req1     ( wrr_req1     ),
        .req2     ( wrr_req2     ),
        .req3     ( wrr_req3     ),
        .wt0      ( wrr_wt0      ),
        .wt1      ( wrr_wt1      ),
        .wt2      ( wrr_wt2      ),
        .wt3      ( wrr_wt3      ),
        .gnt_busy ( wrr_gnt_busy ),
        .gnt_val  ( wrr_gnt_val  ),
        .gnt0     ( wrr_gnt0     ),
        .gnt1     ( wrr_gnt1     ),
        .gnt2     ( wrr_gnt2     ),
        .gnt3     ( wrr_gnt3     )
    );


    // this is for analysis
    reg [63:0] sq1_cnt;
    reg [63:0] sq2_cnt;
    reg [63:0] sq1_req_cnt;
    reg [63:0] sq2_req_cnt;
    always @(posedge clk or negedge rst_n)
        begin
            if(~rst_n)
                begin
                    sq1_cnt <= 64'h0;
                    sq2_cnt <= 64'h0;
                end
            else if(wrr_gnt_val && rr4_result == 4'b0001)
                begin
                    sq1_cnt <= sq1_cnt + 1'b1;
                end
            else if(wrr_gnt_val && rr4_result == 4'b0010)
                begin
                    sq2_cnt <= sq2_cnt + 1'b1;
                end
        end

    always @(posedge clk or negedge rst_n)
        begin
            if(~rst_n)
                begin
                    sq1_req_cnt <= 64'h0;
                end
            else if(rr4_ena && rr4_req[0] == 1'b1)
                begin
                    sq1_req_cnt <= sq1_req_cnt + 1'b1;
                end
        end

    always @(posedge clk or negedge rst_n)
        begin
            if(~rst_n)
                begin
                    sq2_req_cnt <= 64'h0;
                end
            else if(rr4_ena && rr4_req[1] == 1'b1)
                begin
                    sq2_req_cnt <= sq2_req_cnt + 1'b1;
                end
        end

    // initial 
    //     begin
    //         $monitor("%0t, sq1_cnt : %0d, sq2_cnt : %0d", $time, sq1_cnt, sq2_cnt);
    //         $monitor("%0t, sq1_req_cnt : %0d, sq2_req_cnt : %0d", $time, sq1_req_cnt, sq2_req_cnt);
    //     end
endmodule