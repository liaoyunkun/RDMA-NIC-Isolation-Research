`timescale 1ns/1ps
`default_nettype none

module wrr8_arbit (
    input  wire clk,
    input  wire rst_n,
    input  wire req_val,
    input  wire req0,
    input  wire req1,
    input  wire req2,
    input  wire req3,
    input  wire req4,
    input  wire req5,
    input  wire req6,
    input  wire req7,
    input  wire [4:0] wt0,
    input  wire [4:0] wt1,
    input  wire [4:0] wt2,
    input  wire [4:0] wt3,
    input  wire [4:0] wt4,
    input  wire [4:0] wt5,
    input  wire [4:0] wt6,
    input  wire [4:0] wt7,
    input  wire gnt_busy,
    output reg  gnt_val,
    output wire gnt0,
    output wire gnt1,
    output wire gnt2,
    output wire gnt3,
    output wire gnt4,
    output wire gnt5,
    output wire gnt6,
    output wire gnt7
  );

// Algorithm Description
// 
//Declaring registers and wires
reg  [7:0] gnt;
reg  [7:0] gnt_pre;
reg  [7:0] wrr_gnt; // previous grant

reg  [4:0] wt_left;
reg  [4:0] wt_left_nxt;
wire [4:0] new_wt_left0;
wire [4:0] new_wt_left1;
wire [4:0] new_wt_left2;
wire [4:0] new_wt_left3;
wire [4:0] new_wt_left4;
wire [4:0] new_wt_left5;
wire [4:0] new_wt_left6;
wire [4:0] new_wt_left7;

wire [7:0] req;

// assign sys_clk = clk;
// assign sys_rst = ~rst_n;
// request and the weight is not zero
assign req = {
    (req7 & (|wt7)),
    (req6 & (|wt6)),
    (req5 & (|wt5)),
    (req4 & (|wt4)), 
    (req3 & (|wt3)),
    (req2 & (|wt2)),
    (req1 & (|wt1)), 
    (req0 & (|wt0)) };

assign {gnt7, gnt6, gnt5 ,gnt4, gnt3, gnt2, gnt1 ,gnt0} = gnt;

// if gnt_busy is asserted, mask gnt_pre to get gnt
// otherwise, gnt is gnt_pre
always @(gnt_busy or gnt_pre) 
    begin
        gnt = {8{!gnt_busy}} & gnt_pre;
    end

assign new_wt_left0[4:0] = wt0 - 1'b1;
assign new_wt_left1[4:0] = wt1 - 1'b1;
assign new_wt_left2[4:0] = wt2 - 1'b1;
assign new_wt_left3[4:0] = wt3 - 1'b1;

// next state for gnt_pre and wt_left_nxt
always @(wt_left or req or wrr_gnt or new_wt_left0 or new_wt_left1) 
    begin
        gnt_pre = {8{1'b0}};
        wt_left_nxt = wt_left;
        if (wt_left == 0 | !(|(req & wrr_gnt)) ) begin
            case (wrr_gnt)
                8'b0000_0000 : begin 
                    // Priority: 0 -> 1 -> 2 -> 3 -> 4 -> 5 -> 6 -> 7
                    if (req[0]) 
                        begin
                            gnt_pre = 8'b0000_0001;
                            wt_left_nxt = new_wt_left0;
                        end 
                    else if (req[1]) 
                        begin
                            gnt_pre = 8'b0000_0010;
                            wt_left_nxt = new_wt_left1;
                        end 
                    else if (req[2])
                        begin
                            gnt_pre = 8'b0000_0100;
                            wt_left_nxt = new_wt_left2;
                        end
                    else if (req[3])
                        begin
                            gnt_pre = 8'b0000_1000;
                            wt_left_nxt = new_wt_left3;
                        end
                    //
                    else if (req[4]) 
                        begin
                            gnt_pre = 8'b0001_0000;
                            wt_left_nxt = new_wt_left4;
                        end 
                    else if (req[5]) 
                        begin
                            gnt_pre = 8'b0010_0000;
                            wt_left_nxt = new_wt_left5;
                        end 
                    else if (req[6])
                        begin
                            gnt_pre = 8'b0100_0000;
                            wt_left_nxt = new_wt_left6;
                        end
                    else if (req[7])
                        begin
                            gnt_pre = 8'b1000_0000;
                            wt_left_nxt = new_wt_left7;
                        end
                end 
                8'b0000_0001 : 
                    begin 
                        // Priority: 1 -> 2 -> 3 -> 4 -> 5 -> 6 -> 7 -> 0
                        if(req[1]) 
                            begin
                                gnt_pre = 8'b0000_0010;
                                wt_left_nxt = new_wt_left1;
                            end
                        else if(req[2])
                            begin
                                gnt_pre = 8'b0000_0100;
                                wt_left_nxt = new_wt_left2;
                            end
                        else if(req[3])
                            begin
                                gnt_pre = 8'b0000_1000;
                                wt_left_nxt = new_wt_left3;
                            end
                        else if(req[4])
                            begin
                                gnt_pre = 8'b0001_0000;
                                wt_left_nxt = new_wt_left4;
                            end
                        else if(req[5])
                            begin
                                gnt_pre = 8'b0010_0000;
                                wt_left_nxt = new_wt_left5;
                            end
                        else if(req[6])
                            begin
                                gnt_pre = 8'b0100_0000;
                                wt_left_nxt = new_wt_left6;
                            end
                        else if(req[7])
                            begin
                                gnt_pre = 8'b1000_0000;
                                wt_left_nxt = new_wt_left7;
                            end
                        else if (req[0]) begin
                            gnt_pre = 8'b0000_0001;
                            wt_left_nxt = new_wt_left0;
                        end
                    end
                8'b0000_0010:
                    begin
                        // Priority: 2 -> 3 -> 4 -> 5 -> 6 -> 7 -> 0 -> 1
                        if(req[2])
                            begin
                                gnt_pre = 8'b0000_0100;
                                wt_left_nxt = new_wt_left2;
                            end
                        else if(req[3])
                            begin
                                gnt_pre = 8'b0000_1000;
                                wt_left_nxt = new_wt_left3;
                            end
                        else if(req[4])
                            begin
                                gnt_pre = 8'b0001_0000;
                                wt_left_nxt = new_wt_left4;
                            end
                        else if(req[5])
                            begin
                                gnt_pre = 8'b0010_0000;
                                wt_left_nxt = new_wt_left5;
                            end
                        else if(req[6])
                            begin
                                gnt_pre = 8'b0100_0000;
                                wt_left_nxt = new_wt_left6;
                            end
                        else if(req[7])
                            begin
                                gnt_pre = 8'b1000_0000;
                                wt_left_nxt = new_wt_left7;
                            end
                        else if (req[0]) begin
                            gnt_pre = 8'b0000_0001;
                            wt_left_nxt = new_wt_left0;
                        end
                        else if(req[1]) 
                            begin
                                gnt_pre = 8'b0000_0010;
                                wt_left_nxt = new_wt_left1;
                            end
                    end
                8'b0000_0100:
                    begin
                        // Priority: 3 -> 4 -> 5 -> 6 -> 7 -> 0 -> 1 -> 2
                        if(req[3])
                            begin
                                gnt_pre = 8'b0000_1000;
                                wt_left_nxt = new_wt_left3;
                            end
                        else if(req[4])
                            begin
                                gnt_pre = 8'b0001_0000;
                                wt_left_nxt = new_wt_left4;
                            end
                        else if(req[5])
                            begin
                                gnt_pre = 8'b0010_0000;
                                wt_left_nxt = new_wt_left5;
                            end
                        else if(req[6])
                            begin
                                gnt_pre = 8'b0100_0000;
                                wt_left_nxt = new_wt_left6;
                            end
                        else if(req[7])
                            begin
                                gnt_pre = 8'b1000_0000;
                                wt_left_nxt = new_wt_left7;
                            end
                        else if (req[0]) begin
                            gnt_pre = 8'b0000_0001;
                            wt_left_nxt = new_wt_left0;
                        end
                        else if(req[1]) 
                            begin
                                gnt_pre = 8'b0000_0010;
                                wt_left_nxt = new_wt_left1;
                            end
                        else if(req[2])
                            begin
                                gnt_pre = 8'b0000_0100;
                                wt_left_nxt = new_wt_left2;
                            end
                    end
                8'b0000_1000: 
                    begin 
                        // Priority: 4 -> 5 -> 6 -> 7 -> 0 -> 1 -> 2 -> 3
                        if(req[4])
                            begin
                                gnt_pre = 8'b0001_0000;
                                wt_left_nxt = new_wt_left4;
                            end
                        else if(req[5])
                            begin
                                gnt_pre = 8'b0010_0000;
                                wt_left_nxt = new_wt_left5;
                            end
                        else if(req[6])
                            begin
                                gnt_pre = 8'b0100_0000;
                                wt_left_nxt = new_wt_left6;
                            end
                        else if(req[7])
                            begin
                                gnt_pre = 8'b1000_0000;
                                wt_left_nxt = new_wt_left7;
                            end
                        else if (req[0]) begin
                            gnt_pre = 8'b0000_0001;
                            wt_left_nxt = new_wt_left0;
                        end
                        else if(req[1]) 
                            begin
                                gnt_pre = 8'b0000_0010;
                                wt_left_nxt = new_wt_left1;
                            end
                        else if(req[2])
                            begin
                                gnt_pre = 8'b0000_0100;
                                wt_left_nxt = new_wt_left2;
                            end
                        else if(req[3])
                            begin
                                gnt_pre = 8'b0000_1000;
                                wt_left_nxt = new_wt_left3;
                            end
                    end
                8'b0001_0000: 
                    begin 
                        // Priority: 5 -> 6 -> 7 -> 0 -> 1 -> 2 -> 3 -> 4
                        if(req[5])
                            begin
                                gnt_pre = 8'b0010_0000;
                                wt_left_nxt = new_wt_left5;
                            end
                        else if(req[6])
                            begin
                                gnt_pre = 8'b0100_0000;
                                wt_left_nxt = new_wt_left6;
                            end
                        else if(req[7])
                            begin
                                gnt_pre = 8'b1000_0000;
                                wt_left_nxt = new_wt_left7;
                            end
                        else if (req[0]) begin
                            gnt_pre = 8'b0000_0001;
                            wt_left_nxt = new_wt_left0;
                        end
                        else if(req[1]) 
                            begin
                                gnt_pre = 8'b0000_0010;
                                wt_left_nxt = new_wt_left1;
                            end
                        else if(req[2])
                            begin
                                gnt_pre = 8'b0000_0100;
                                wt_left_nxt = new_wt_left2;
                            end
                        else if(req[3])
                            begin
                                gnt_pre = 8'b0000_1000;
                                wt_left_nxt = new_wt_left3;
                            end
                        else if(req[4])
                            begin
                                gnt_pre = 8'b0001_0000;
                                wt_left_nxt = new_wt_left4;
                            end
                    end
                8'b0010_0000: 
                    begin 
                        // Priority: 6 -> 7 -> 0 -> 1 -> 2 -> 3 -> 4 -> 5 
                        if(req[6])
                            begin
                                gnt_pre = 8'b0100_0000;
                                wt_left_nxt = new_wt_left6;
                            end
                        else if(req[7])
                            begin
                                gnt_pre = 8'b1000_0000;
                                wt_left_nxt = new_wt_left7;
                            end
                        else if (req[0]) begin
                            gnt_pre = 8'b0000_0001;
                            wt_left_nxt = new_wt_left0;
                        end
                        else if(req[1]) 
                            begin
                                gnt_pre = 8'b0000_0010;
                                wt_left_nxt = new_wt_left1;
                            end
                        else if(req[2])
                            begin
                                gnt_pre = 8'b0000_0100;
                                wt_left_nxt = new_wt_left2;
                            end
                        else if(req[3])
                            begin
                                gnt_pre = 8'b0000_1000;
                                wt_left_nxt = new_wt_left3;
                            end
                        else if(req[4])
                            begin
                                gnt_pre = 8'b0001_0000;
                                wt_left_nxt = new_wt_left4;
                            end
                        else if(req[5])
                            begin
                                gnt_pre = 8'b0010_0000;
                                wt_left_nxt = new_wt_left5;
                            end
                    end
                8'b0100_0000: 
                    begin 
                        // Priority: 7 -> 0 -> 1 -> 2 -> 3 -> 4 -> 5 -> 6
                        if(req[7])
                            begin
                                gnt_pre = 8'b1000_0000;
                                wt_left_nxt = new_wt_left7;
                            end
                        else if (req[0]) begin
                            gnt_pre = 8'b0000_0001;
                            wt_left_nxt = new_wt_left0;
                        end
                        else if(req[1]) 
                            begin
                                gnt_pre = 8'b0000_0010;
                                wt_left_nxt = new_wt_left1;
                            end
                        else if(req[2])
                            begin
                                gnt_pre = 8'b0000_0100;
                                wt_left_nxt = new_wt_left2;
                            end
                        else if(req[3])
                            begin
                                gnt_pre = 8'b0000_1000;
                                wt_left_nxt = new_wt_left3;
                            end
                        else if(req[4])
                            begin
                                gnt_pre = 8'b0001_0000;
                                wt_left_nxt = new_wt_left4;
                            end
                        else if(req[5])
                            begin
                                gnt_pre = 8'b0010_0000;
                                wt_left_nxt = new_wt_left5;
                            end
                        else if(req[6])
                            begin
                                gnt_pre = 8'b0100_0000;
                                wt_left_nxt = new_wt_left6;
                            end
                    end
                8'b1000_0000: 
                    begin 
                        // Priority: 0 -> 1 -> 2 -> 3 -> 4 -> 5 -> 6 -> 7
                        if (req[0]) begin
                            gnt_pre = 8'b0000_0001;
                            wt_left_nxt = new_wt_left0;
                        end
                        else if(req[1]) 
                            begin
                                gnt_pre = 8'b0000_0010;
                                wt_left_nxt = new_wt_left1;
                            end
                        else if(req[2])
                            begin
                                gnt_pre = 8'b0000_0100;
                                wt_left_nxt = new_wt_left2;
                            end
                        else if(req[3])
                            begin
                                gnt_pre = 8'b0000_1000;
                                wt_left_nxt = new_wt_left3;
                            end
                        else if(req[4])
                            begin
                                gnt_pre = 8'b0001_0000;
                                wt_left_nxt = new_wt_left4;
                            end
                        else if(req[5])
                            begin
                                gnt_pre = 8'b0010_0000;
                                wt_left_nxt = new_wt_left5;
                            end
                        else if(req[6])
                            begin
                                gnt_pre = 8'b0100_0000;
                                wt_left_nxt = new_wt_left6;
                            end
                        else if(req[7])
                            begin
                                gnt_pre = 8'b1000_0000;
                                wt_left_nxt = new_wt_left7;
                            end
                    end
            //VCS coverage off
            default : begin 
                        gnt_pre[7:0] = {8{1'b0}};
                        wt_left_nxt[4:0] = {5{1'b0}};
                        end  
            //VCS coverage on
            endcase
        end 
        else 
            begin
                gnt_pre = wrr_gnt;
                wt_left_nxt = wt_left - 1'b1;
            end
    end

always @(posedge clk or negedge rst_n) 
    begin
        if (!rst_n) 
            begin
                wrr_gnt <= {8{1'b0}};
                wt_left <= {5{1'b0}};
            end 
        else 
            begin
                if (!gnt_busy & req != {8{1'b0}}) 
                    begin
                        // if there is request, and gnt_busy is not asserted,
                        // update wrr_gnt, and wt_left
                        wrr_gnt <= gnt;
                        wt_left <= wt_left_nxt;
                    end 
            end
    end

always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n)
            begin
                gnt_val <= 1'b0;
            end
        else
            begin
                gnt_val <= req_val;
            end
    end

endmodule 