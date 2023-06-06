`timescale 1ns/1ps
`default_nettype none

module wrr4_arbit_tb;

    reg req_val = '0;
    reg req0 = '0;
    reg req1 = '0;
    reg req2 = '0;
    reg req3 = '0;
    reg [4:0] wt0 = '0;
    reg [4:0] wt1 = '0;
    reg [4:0] wt2 = '0;
    reg [4:0] wt3 = '0;
    reg gnt_busy = '0;
    reg clk = '0;
    reg rst_n = '0;
    wire gnt_val;
    wire gnt0;
    wire gnt1;
    wire gnt2;
    wire gnt3;

    bit [31:0] gnt0_cnt = '0;
    bit [31:0] gnt1_cnt = '0;
    bit [31:0] gnt2_cnt = '0;
    bit [31:0] gnt3_cnt = '0;

    always #5 clk = ~clk;

    initial 
        begin
            #10 rst_n = 1'b1;
            for (int i = 0; i < 1000; i = i + 1) 
                begin
                    gen_req();
                end
            $display("GNT-0-CNT: %d, GNT-1-CNT: %d\n, GNT-2-CNT: %d, GNT-3-CNT: %d\n", 
                        gnt0_cnt, gnt1_cnt, gnt2_cnt, gnt3_cnt);
            $display("GNT-0-DATA: %d, GNT-1-DATA: %d\n, GNT-2-DATA: %d, GNT-3-DATA: %d\n", 
                        gnt0_cnt * 1024, gnt1_cnt * 2048, gnt2_cnt * 256, gnt3_cnt * 4096);
            #100;
            $stop;
        end

    wrr4_arbit u_wrr4_arbit(
        .clk      ( clk      ),
        .rst_n    ( rst_n    ),
        .req_val  ( req_val  ),
        .req0     ( req0     ),
        .req1     ( req1     ),
        .req2     ( req2     ),
        .req3     ( req3     ),
        .wt0      ( wt0      ),
        .wt1      ( wt1      ),
        .wt2      ( wt2      ),
        .wt3      ( wt3      ),
        .gnt_busy ( gnt_busy ),
        .gnt_val  ( gnt_val  ),
        .gnt0     ( gnt0     ),
        .gnt1     ( gnt1     ),
        .gnt2     ( gnt2     ),
        .gnt3     ( gnt3     )
    );

    always @(posedge clk)
        begin
            if(gnt_val && gnt0 == 1'b1)
                begin
                    gnt0_cnt <= gnt0_cnt + 1'b1;
                end
            else if(gnt_val && gnt1 == 1'b1)
                begin
                    gnt1_cnt <= gnt1_cnt + 1'b1;
                end
            else if(gnt_val && gnt2 == 1'b1)
                begin
                    gnt2_cnt <= gnt2_cnt + 1'b1;
                end
            else if(gnt_val && gnt3 == 1'b1)
                begin
                    gnt3_cnt <= gnt3_cnt + 1'b1;
                end
        end

    task gen_req;
        @(posedge clk)
            begin
                req_val <= 1'b1;
                req0 <= 1'b1;
                req1 <= 1'b1;
                req2 <= 1'b1;
                req3 <= 1'b1;
                wt0 <= 5'd4;    // PMTU = 1024B
                wt1 <= 5'd2;    // PMTU = 2048B
                wt2 <= 5'd16;   // PMTU = 256B
                wt3 <= 5'd1;    // PMTU = 4096B
            end
        @(posedge clk)
            begin
                req_val <= 1'b0;
            end
    endtask

endmodule