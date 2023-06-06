`default_nettype none
`timescale 1ns / 1ps

module slot_status #(
    parameter SLOT_NUM        = 4,
    parameter SLOT_ADDR_WIDTH = 2
) (
    input  wire                        clk           ,
    input  wire                        rst_n         ,
    input  wire                        i_set_req     ,
    input  wire [SLOT_ADDR_WIDTH-1:0]  i_set_addr    ,
    input  wire                        i_reset_req   ,
    input  wire [SLOT_ADDR_WIDTH-1:0]  i_reset_addr  ,
    output wire [SLOT_NUM-1:0]         o_slot_status
);

    reg [SLOT_NUM-1:0] slot_status                  ;
    reg [SLOT_NUM-1:0] set_mask, reset_mask         ;
    always@(*) 
        begin
            casex({i_set_req, i_set_addr})
            3'b0xx: set_mask = 4'b0000;
            3'b100: set_mask = 4'b0001;
            3'b101: set_mask = 4'b0010;
            3'b110: set_mask = 4'b0100;
            3'b111: set_mask = 4'b1000;
            default: set_mask = 4'b0000;
            endcase
        end
    always@(*) 
        begin
            casex({i_reset_req, i_reset_addr})
            3'b0xx: reset_mask = 4'b1111;
            3'b100: reset_mask = 4'b1110;
            3'b101: reset_mask = 4'b1101;
            3'b110: reset_mask = 4'b1011;
            3'b111: reset_mask = 4'b0111;
            default: reset_mask = 4'b1111;
            endcase
        end

    always @(posedge clk or negedge rst_n) 
        begin
            if(~rst_n) 
                begin
                    slot_status <= 4'b0000;
                end
            else 
                begin
                    slot_status <= (slot_status | set_mask) & reset_mask;
                end
        end

    assign o_slot_status = slot_status;
endmodule