`timescale 1ns/1ps
`default_nettype none

module wrr2_arbit (
    input  wire clk,
    input  wire rst_n,
    input  wire req_val,
    input  wire req0,
    input  wire req1,
    input  wire [4:0] wt0,
    input  wire [4:0] wt1,
    input  wire gnt_busy,
    output reg  gnt_val,
    output wire gnt0,
    output wire gnt1
  );


//Declaring registers and wires
reg  [1:0] gnt;
reg  [1:0] gnt_pre;
reg  [1:0] wrr_gnt;
reg  [4:0] wt_left;
reg  [4:0] wt_left_nxt;
wire [4:0] new_wt_left0;
wire [4:0] new_wt_left1;
wire [1:0] req;

// request and the weight is not zero
assign req = {
    (req1 & (|wt1)), 
    (req0 & (|wt0)) };

assign {gnt1 ,gnt0} = gnt;

// if gnt_busy is asserted, mask gnt_pre to get gnt
// otherwise, gnt is gnt_pre
always @(gnt_busy or gnt_pre) 
    begin
        gnt = {2{!gnt_busy}} & gnt_pre;
    end

assign new_wt_left0[4:0] = wt0 - 1'b1;

assign new_wt_left1[4:0] = wt1 - 1'b1;

// next state for gnt_pre and wt_left_nxt
always @(wt_left or req or wrr_gnt or new_wt_left0 or new_wt_left1) 
    begin
        gnt_pre = {2{1'b0}};
        wt_left_nxt = wt_left;
        if (wt_left == 0 | !(|(req & wrr_gnt)) ) begin
            case (wrr_gnt)
                2'b00 : begin 
                    if (req[0]) begin
                         gnt_pre = 2'b01;
                         wt_left_nxt = new_wt_left0;
                    end 
                    else if (req[1]) begin
                         gnt_pre = 2'b10;
                         wt_left_nxt = new_wt_left1;
                    end 
                end 
                2'b01 : begin 
                    if      (req[1]) begin
                        gnt_pre = 2'b10;
                        wt_left_nxt = new_wt_left1;
                    end
                    else if (req[0]) begin
                        gnt_pre = 2'b01;
                        wt_left_nxt = new_wt_left0;
                    end
               end
                2'b10 : begin 
                    if      (req[0]) begin
                        gnt_pre = 2'b01;
                        wt_left_nxt = new_wt_left0;
                    end
                    else if (req[1]) begin
                        gnt_pre = 2'b10;
                        wt_left_nxt = new_wt_left1;
                    end
               end
                //VCS coverage off
                default : begin 
                            gnt_pre[1:0] = {2{1'b0}};
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
                wrr_gnt <= {2{1'b0}};
                wt_left <= {5{1'b0}};
            end 
        else 
            begin
                if (!gnt_busy & req != {2{1'b0}}) 
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