`timescale 1ns/1ps
`default_nettype none

module wrr2_arbit_tb;

    reg req_val = '0;
    reg req0 = '0;
    reg req1 = '0;
    reg [4:0] wt0 = '0;
    reg [4:0] wt1 = '0;
    reg gnt_busy = '0;
    reg clk = '0;
    reg rst_n = '0;
    wire gnt_val;
    wire gnt0;
    wire gnt1;

    bit [31:0] gnt0_cnt = '0;
    bit [31:0] gnt1_cnt = '0;

    always #5 clk = ~clk;

    initial 
        begin
            #10 rst_n = 1'b1;
            for (int i = 0; i < 1000; i = i + 1) 
                begin
                    gen_req();
                end
            $display("GNT-0-CNT: %d, GNT-1-CNT: %d\n", gnt0_cnt, gnt1_cnt);
            #100;
            $finish;
        end

    wrr2_arbit u_wrr2_arbit(
        .clk      ( clk      ),
        .rst_n    ( rst_n    ),
        .req_val  ( req_val  ),
        .req0     ( req0     ),
        .req1     ( req1     ),
        .wt0      ( wt0      ),
        .wt1      ( wt1      ),
        .gnt_busy ( gnt_busy ),
        .gnt_val  ( gnt_val  ),
        .gnt0     ( gnt0     ),
        .gnt1     ( gnt1     )
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
        end

    task gen_req;
        @(posedge clk)
            begin
                req_val <= 1'b1;
                req0 <= 1'b1;
                req1 <= 1'b1;
                wt0 <= 5'd4;    // PMTU = 1024B
                wt1 <= 5'd2;    // PMTU = 2048B
            end
        @(posedge clk)
            begin
                req_val <= 1'b0;
            end
    endtask

endmodule