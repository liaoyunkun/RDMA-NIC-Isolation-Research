
`default_nettype wire
`timescale 1ns/1ps
module mem_1rw #(
    parameter IS_ARRAY_RAM      = 0            ,
    parameter RAM_STYLE_MODE    = "block"      ,//"distributed", "registers","block"���Ժ�ȡ��
    parameter WIDTH_ADDR        = 8            ,
    parameter WIDTH_DATA        = 8            ,
    parameter DEVICE_RAM_TYPE   = "AUTO"       ,//For Xilinx: "auto", "distributed", "block" or "ultra";
                                                //For Altera: "M9K"
    parameter DOUT_REG          = "false"       //"false":No register output;"true":register output
    )
(
    input                           wen        ,
    input                           ren        ,
    input       [WIDTH_ADDR-1:0]    addr       ,
    input       [WIDTH_DATA-1:0]    din        ,
    input                           clk        ,
    output      [WIDTH_DATA-1:0]    dout
    ) ;
generate
    //ARRAY_RAM
    if (IS_ARRAY_RAM == 1) 
        begin: mem_1rw_gen
            mem_1rw_array #(
                .WIDTH_DATA         ( WIDTH_DATA        ) ,
                .WIDTH_ADDR         ( WIDTH_ADDR        ) ,
                .DOUT_REG           ( DOUT_REG          )
            )
            u_mem_1rw_array (
                .clk                (clk                ),
                .wen                (wen                ),
                .addr               (addr               ),
                .din                (din                ),
                .ren                (ren                ),
                .dout               (dout               )
            );
        end
    else 
        begin: mem_1rw_gen
            mem_1rw_xilinx #(
                .WIDTH_DATA         ( WIDTH_DATA        ) ,
                .WIDTH_ADDR         ( WIDTH_ADDR        ) ,
                .DEVICE_RAM_TYPE    ( DEVICE_RAM_TYPE   ) ,
                .DOUT_REG           ( DOUT_REG          )
            )
            u_mem_1rw_xilinx (
                .clk                (clk                ),
                .wen                (wen                ),
                .addr               (addr               ),
                .din                (din                ),
                .ren                (ren                ),
                .dout               (dout               )
            );
        end
endgenerate
endmodule
