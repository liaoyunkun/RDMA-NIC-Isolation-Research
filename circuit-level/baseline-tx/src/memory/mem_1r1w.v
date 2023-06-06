`default_nettype wire
`timescale 1ns/1ps
module mem_1r1w #(
    parameter IS_ARRAY_RAM      = 0             ,
    parameter RAM_STYLE_MODE    = "block"       , //"distributed","registers","block"
    parameter WIDTH_ADDR        = 8             ,
    parameter WIDTH_DATA        = 8             ,
    parameter DEVICE_RAM_TYPE   = "AUTO"        , //For Xilinx:"auto","distributed","block","ultra"
    parameter DOUT_REG          = "false"         //"false":No register output;"true":register output
    )
    (
    input                           wclk              ,
    input                           wen               ,
    input       [WIDTH_ADDR-1:0]    waddr             ,
    input       [WIDTH_DATA-1:0]    din               ,
    input                           rclk              ,
    input                           ren               ,
    input       [WIDTH_ADDR-1:0]    raddr             ,
    output      [WIDTH_DATA-1:0]    dout
    ) ;

generate
    //ARRAY_RAM
    if (IS_ARRAY_RAM == 1) 
        begin: mem_1r1w_gen
        mem_1r1w_array #(
            .WIDTH_DATA         ( WIDTH_DATA        ) ,
            .WIDTH_ADDR         ( WIDTH_ADDR        ) ,
            .DOUT_REG           ( DOUT_REG          )
        )
        u_mem_1r1w_array (
            .wclk               (wclk               ),
            .wen                (wen                ),
            .waddr              (waddr              ),
            .din                (din                ),

            .rclk               (rclk               ),
            .ren                (ren                ),
            .raddr              (raddr              ),
            .dout               (dout               )
        );
    end
    else
        // Xilinx RAM 
        begin: mem_1r1w_gen
        mem_1r1w_xilinx #(
            .WIDTH_DATA         ( WIDTH_DATA        ) ,
            .WIDTH_ADDR         ( WIDTH_ADDR        ) ,
            .DEVICE_RAM_TYPE    ( DEVICE_RAM_TYPE   ) ,
            .DOUT_REG           ( DOUT_REG          )
        )
        u_mem_1r1w_xilinx (
            .wclk               (wclk               ),
            .wen                (wen                ),
            .waddr              (waddr              ),
            .din                (din                ),

            .rclk               (rclk               ),
            .ren                (ren                ),
            .raddr              (raddr              ),
            .dout               (dout               )
        );
    end

endgenerate
endmodule
