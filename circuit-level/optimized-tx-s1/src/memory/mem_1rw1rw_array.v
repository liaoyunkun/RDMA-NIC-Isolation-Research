`default_nettype wire
`timescale 1ns/1ps
module mem_1rw1rw_array #(parameter
    RAM_STYLE_MODE          = "block"  ,//"distributed", "registers",�Ժ�ȡ��
    WIDTH_ADDR              = 8        ,
    WIDTH_DATA              = 8        ,
    READ_DURING_WRITE_A     = "new"    ,//new old, but no xxx in altera 1rw1rw ram
    READ_DURING_WRITE_B     = "new"    ,//new old, but no xxx in altera 1rw1rw ram
    DOUT_REG_A              = "false"  ,//register output a
    DOUT_REG_B              = "false"   //register output b
)
(
    input       [WIDTH_ADDR-1:0]    addra      ,
    input       [WIDTH_DATA-1:0]    dina       ,
    input                           wena       ,
    input                           rena       ,//no use
    input                           clka       ,
    output      [WIDTH_DATA-1:0]    douta      ,

    input       [WIDTH_ADDR-1:0]    addrb      ,
    input       [WIDTH_DATA-1:0]    dinb       ,
    input                           wenb       ,
    input                           renb       ,//no use
    input                           clkb       ,
    output      [WIDTH_DATA-1:0]    doutb
) ;

// Declare the RAM variable
reg [WIDTH_DATA-1:0] ram [2**WIDTH_ADDR-1 : 0];

reg [WIDTH_DATA-1:0] ram_douta                ;
reg [WIDTH_DATA-1:0] ram_rega                 ;
reg [WIDTH_DATA-1:0] ram_doutb                ;
reg [WIDTH_DATA-1:0] ram_regb                 ;

// synopsys translate_off
`ifdef RAM_INIT_DEBUG
integer i;
initial begin
    ram_douta   = {WIDTH_DATA{1'b0}};
    ram_rega    = {WIDTH_DATA{1'b0}};
    ram_doutb   = {WIDTH_DATA{1'b0}};
    ram_regb    = {WIDTH_DATA{1'b0}};
    for(i = 0 ; i < (2**WIDTH_ADDR) ; i = i+1)
        ram[i] = {WIDTH_DATA{1'b0}};
end
`endif
// synopsys translate_on

wire mem_ena;
wire mem_enb;
reg  mem_ena_dly;
reg  mem_enb_dly;
`ifdef DEVICE_VENDOR_IS_XILINX
    assign mem_ena = wena | rena;
    assign mem_enb = wenb | renb;
`else
    assign mem_ena = 1'b1;
    assign mem_enb = 1'b1;
`endif

// Write
always @(posedge clka) begin
    if(wena & mem_ena)
        ram[addra] <= dina;
end

always @(posedge clkb) begin
    if(wenb & mem_enb)
        ram[addrb] <= dinb;
end

//
always @(posedge clka) begin

        mem_ena_dly <= rena;
end

always @(posedge clkb) begin

        mem_enb_dly <= renb;
end

// Read
//always @(posedge clka) begin
//    if (READ_DURING_WRITE_A == "new") begin // :mem_1rw1rw_ram_douta
//        if(mem_ena ) begin
//            if(wena )
//                ram_douta <= dina            ;
//            else
//                ram_douta <= ram[addra]      ;
//        end
//    end
//    else begin // :mem_1rw1rw_ram_douta
//        if(mem_ena & rena)
//            ram_douta <= ram[addra]      ;
//    end
//end

generate
    if (READ_DURING_WRITE_A == "new") begin // :mem_1rw1rw_ram_douta
        always @(posedge clka) begin
            if(mem_ena ) begin
                if(wena )
                    ram_douta <= dina            ;
                else
                    ram_douta <= ram[addra]      ;
            end
        end
    end
    else begin
        always @(posedge clka) begin
            if(mem_ena & rena) begin
                    ram_douta <= ram[addra]      ;
            end
        end
    end
endgenerate

generate
    if (READ_DURING_WRITE_B == "new") begin // :mem_1rw1rw_ram_doutb
        always @(posedge clkb) begin
            if(mem_enb ) begin
                if(wenb )
                    ram_doutb <= dinb            ;
                else
                    ram_doutb <= ram[addrb]      ;
            end
        end
    end
    else begin
        always @(posedge clkb) begin
            if(mem_enb & renb) begin
                    ram_doutb <= ram[addrb]      ;
            end
        end
    end
endgenerate

// DOUT register
generate
    if(DOUT_REG_A == "true")begin
        always @(posedge clka)begin
            if(mem_ena_dly) begin
                ram_rega <= ram_douta;
            end
        end
        assign douta = ram_rega;
    end
    else begin
        assign douta = ram_douta;
    end
    if(DOUT_REG_B == "true")begin
        always @(posedge clkb)begin
            if(mem_enb_dly) begin
                ram_regb <= ram_doutb;
            end
        end
        assign doutb = ram_regb;
    end
    else begin
        assign doutb = ram_doutb;
    end
endgenerate

// synopsys translate_off
always @(posedge clka) begin
    if(wena == 1'b1 && wenb == 1'b1 && addra == addrb)
        $display("%t %m: mem_1rw1rw write the same address at same time caseA   addra=%h,  addrb=%h",
                  $time,           addra,              addrb);
end

always @(posedge clkb) begin
    if(wena == 1'b1 && wenb == 1'b1 && addra == addrb)
        $display("%t %m: mem_1rw1rw write the same address at same time caseB   addra=%h,  addrb=%h",
                  $time,           addra,              addrb);
end
// synopsys translate_on

endmodule
