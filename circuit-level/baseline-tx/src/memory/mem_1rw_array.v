`default_nettype wire
`timescale 1ns/1ps
module mem_1rw_array #(parameter
    RAM_STYLE_MODE            = "block"       ,//"distributed", "registers"���Ժ�ȡ��
    WIDTH_DATA                =   8           ,
    WIDTH_ADDR                =   8           ,
    DOUT_REG                  = "false"         //register output
)
(
    input   wire                   clk        ,
    input   wire [WIDTH_ADDR-1:0]  addr       ,
    input   wire                   wen        ,
    input   wire [WIDTH_DATA-1:0]  din        ,
    input   wire                   ren        ,
    output  wire [WIDTH_DATA-1:0]  dout
);

// Declare the RAM variable
reg [WIDTH_DATA-1:0] ram [2**WIDTH_ADDR-1 : 0];

reg [WIDTH_DATA-1:0] ram_dout                 ;
reg [WIDTH_DATA-1:0] ram_reg                  ;

// synopsys translate_off
`ifdef RAM_INIT_DEBUG
integer i;
initial begin
    ram_dout   = {WIDTH_DATA{1'b0}};
    ram_reg    = {WIDTH_DATA{1'b0}};
    for(i = 0 ; i < (2**WIDTH_ADDR) ; i = i+1)
        ram[i] = {WIDTH_DATA{1'b0}};
end
`endif
// synopsys translate_on

wire mem_en;
reg  mem_en_dly;
`ifdef DEVICE_VENDOR_IS_XILINX
    assign mem_en = wen | ren;
`else
    assign mem_en = 1'b1;
`endif

// Write
always @ (posedge clk) begin
    if (wen & mem_en) begin
        ram[addr] <= din;
    end
end

// Read
always @ (posedge clk) begin
    if (mem_en == 1'b1) begin
        if(wen == 1'b1)
            ram_dout <= din;
        else
            ram_dout <= ram[addr];
    end
end

always @ (posedge clk) begin

        mem_en_dly <= mem_en;

end

// DOUT register
generate
    if(DOUT_REG == "true")begin
        always @(posedge clk)begin
            if(mem_en_dly) begin
                ram_reg <= ram_dout;
            end
        end
        assign dout = ram_reg;
    end
    else begin
        assign dout = ram_dout;
    end
endgenerate

endmodule
