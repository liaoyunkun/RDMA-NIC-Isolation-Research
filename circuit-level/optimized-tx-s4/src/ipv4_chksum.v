`default_nettype none
`timescale 1ns / 1ps

module ipv4_chksum #(
    parameter IPV4_CHKSUM_WIDTH = 2*8
)(
    input  wire                              clk,
    input  wire                              rst_n,
    input  wire                              i_chksum_start,
    input  wire      [15:0]                  i_ipv4_len,
    input  wire      [15:0]                  i_ipv4_identification,
    input  wire      [7:0]                   i_ipv4_ttl,
    input  wire      [31:0]                  i_ipv4_src_addr,
    input  wire      [31:0]                  i_ipv4_dest_addr,
    output reg                               o_chksum_done,
    output wire      [IPV4_CHKSUM_WIDTH-1:0] o_ipv4_chksum
);
    reg [IPV4_CHKSUM_WIDTH+4-1:0] ipv4_chksum;
    reg chksum_cal_start;
    
    assign o_ipv4_chksum = ipv4_chksum[IPV4_CHKSUM_WIDTH-1:0];
    always @(posedge clk or negedge rst_n) 
        begin
            if(~rst_n) 
                begin
                    o_chksum_done <= 0;
                    ipv4_chksum <= 0;
                    chksum_cal_start <= 0;
                end 
            else if(i_chksum_start) // assert for one cycle
                begin    
                    ipv4_chksum <= 16'h4501 + i_ipv4_len + i_ipv4_identification + 16'h4000 +
                                {i_ipv4_ttl, 8'h11} + i_ipv4_src_addr[31:16] + i_ipv4_src_addr[15:0] +
                                i_ipv4_dest_addr[31:16] + i_ipv4_dest_addr[15:0];
                    chksum_cal_start <= 1'b1;
                end
            else if(chksum_cal_start) 
                begin
                    if(ipv4_chksum[19:16] != 4'b0000) 
                        begin
                            // with carry in, iteration
                            ipv4_chksum <= ipv4_chksum[15:0] + ipv4_chksum[19:16];
                        end
                    else 
                        begin
                            chksum_cal_start <= 1'b0;
                            o_chksum_done <= 1'b1;
                        end
                end
            else if(o_chksum_done) 
                begin
                    o_chksum_done <= 1'b0;   // assert for 1 cycle
                end
        end


endmodule