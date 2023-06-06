`default_nettype wire
`timescale 1ns/1ps
module mem_1rw1rw #(
    parameter IS_ARRAY_RAM        = 0          ,
    parameter RAM_STYLE_MODE      = "block"    , //"distributed", "registers","block"���Ժ�ȡ��
    parameter WIDTH_ADDR          = 8          ,
    parameter WIDTH_DATA          = 8          ,
    parameter DEVICE_RAM_TYPE     = "AUTO"     , //For Xilinx: "auto", "distributed", "block" or "ultra";
                                                 //For Altera: "M9K",
    parameter READ_DURING_WRITE_A = "new"      , //new old, but no xxx in altera 1rw1rw ram
    parameter READ_DURING_WRITE_B = "new"      , //new old, but no xxx in altera 1rw1rw ram
    parameter DOUT_REG_A          = "false"    , //register output a
    parameter DOUT_REG_B          = "false"      //register output b
)
(
    input       [WIDTH_ADDR-1:0]    addra      ,
    input       [WIDTH_DATA-1:0]    dina       ,
    input                           wena       ,
    input                           rena       ,
    input                           clka       ,
    output      [WIDTH_DATA-1:0]    douta      ,

    input       [WIDTH_ADDR-1:0]    addrb      ,
    input       [WIDTH_DATA-1:0]    dinb       ,
    input                           wenb       ,
    input                           renb       ,
    input                           clkb       ,
    output      [WIDTH_DATA-1:0]    doutb
) ;

generate
    //ARRAY_RAM
    if (IS_ARRAY_RAM == 1) 
        begin: mem_1rw1rw_gen
            mem_1rw1rw_array #(
                .WIDTH_DATA             ( WIDTH_DATA          ),
                .WIDTH_ADDR             ( WIDTH_ADDR          ),
                .READ_DURING_WRITE_A    ( READ_DURING_WRITE_A ),
                .READ_DURING_WRITE_B    ( READ_DURING_WRITE_B ),
                .DOUT_REG_A             ( DOUT_REG_A          ),
                .DOUT_REG_B             ( DOUT_REG_B          )
            )
            u_mem_1rw1rw_array (
                .addra                  ( addra         ),
                .dina                   ( dina          ),
                .wena                   ( wena          ),
                .rena                   ( rena          ),
                .clka                   ( clka          ),
                .douta                  ( douta         ),

                .addrb                  ( addrb         ),
                .dinb                   ( dinb          ),
                .wenb                   ( wenb          ),
                .renb                   ( renb          ),
                .clkb                   ( clkb          ),
                .doutb                  ( doutb         )
            );
        end
    else 
        begin: mem_1rw1rw_gen
            mem_1rw1rw_xilinx #(
                .WIDTH_DATA             ( WIDTH_DATA          ),
                .WIDTH_ADDR             ( WIDTH_ADDR          ),
                .DEVICE_RAM_TYPE        ( DEVICE_RAM_TYPE     ),
                .READ_DURING_WRITE_A    ( READ_DURING_WRITE_A ),
                .READ_DURING_WRITE_B    ( READ_DURING_WRITE_B ),
                .DOUT_REG_A             ( DOUT_REG_A          ),
                .DOUT_REG_B             ( DOUT_REG_B          )
            )
            u_mem_1rw1rw_xilinx (
                .addra                  ( addra         ),
                .dina                   ( dina          ),
                .wena                   ( wena          ),
                .rena                   ( rena          ),
                .clka                   ( clka          ),
                .douta                  ( douta         ),

                .addrb                  ( addrb         ),
                .dinb                   ( dinb          ),
                .wenb                   ( wenb          ),
                .renb                   ( renb          ),
                .clkb                   ( clkb          ),
                .doutb                  ( doutb         )
            );
        end
endgenerate
endmodule
