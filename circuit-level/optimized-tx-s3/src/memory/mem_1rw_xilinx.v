`default_nettype wire
`timescale 1ns/1ps
module mem_1rw_xilinx #(parameter
    WIDTH_DATA                =   8              ,
    WIDTH_ADDR                =   8              ,
    DEVICE_RAM_TYPE           =   "AUTO"         , //string; "auto", "distributed", "block" or "ultra";
    DOUT_REG                  =   "false"          //"false":No register output;"true":register output
)
(
    input                           wen        ,
    input                           ren        ,
    input       [WIDTH_ADDR-1:0]    addr       ,
    input       [WIDTH_DATA-1:0]    din        ,
    input                           clk        ,
    output      [WIDTH_DATA-1:0]    dout
);

localparam READ_LATENCY_A = (DOUT_REG == "true") ? 2 : 1;

wire ram_en;
assign ram_en = wen | ren;

// xpm_memory_spram: Single Port RAM
// Xilinx Parameterized Macro, Version 2017.4
xpm_memory_spram # (
    // Common module parameters
    .MEMORY_SIZE                  ( WIDTH_DATA * (2 ** WIDTH_ADDR)  ), //positive integer
    .MEMORY_PRIMITIVE             ( DEVICE_RAM_TYPE                 ), //string; "auto", "distributed", "block" or "ultra";
    .MEMORY_INIT_FILE             ( "none"                          ), //string; "none" or "<filename>.mem"
    .MEMORY_INIT_PARAM            ( ""                              ), //string;
    .USE_MEM_INIT                 ( 1                               ), //integer; 0,1
    .WAKEUP_TIME                  ( "disable_sleep"                 ), //string; "disable_sleep" or "use_sleep_pin"
    .MESSAGE_CONTROL              ( 0                               ), //integer; 0,1
    .MEMORY_OPTIMIZATION          ( "true"                          ), //string; "true", "false"
    // Port A module parameters
    .WRITE_DATA_WIDTH_A           ( WIDTH_DATA                      ), //positive integer
    .READ_DATA_WIDTH_A            ( WIDTH_DATA                      ), //positive integer
    .BYTE_WRITE_WIDTH_A           ( WIDTH_DATA                      ), //integer; 8, 9, or WRITE_DATA_WIDTH_A value
    .ADDR_WIDTH_A                 ( WIDTH_ADDR                      ), //positive integer
    .READ_RESET_VALUE_A           ( "0"                             ), //string
    .ECC_MODE                     ( "no_ecc"                        ), //string; "no_ecc", "encode_only", "decode_only" or "both_encode_and_decode"
    .AUTO_SLEEP_TIME              ( 0                               ), //Do not Change
    .READ_LATENCY_A               ( READ_LATENCY_A                  ), //non-negative integer
    .WRITE_MODE_A                 ( "write_first"                   )  //string; "write_first", "read_first", "no_change"
)
u_xpm_spram (
    // Common module ports
    .sleep                        ( 1'b0          ),
    // Port A module ports
    .clka                         ( clk           ),
    .rsta                         ( 1'b0          ),
    .ena                          ( ram_en        ),
    .regcea                       ( 1'b1          ),
    .wea                          ( {1{wen}}      ),
    .addra                        ( addr          ),
    .dina                         ( din           ),
    .injectsbiterra               ( 1'b0          ),
    .injectdbiterra               ( 1'b0          ),
    .douta                        ( dout          ),
    .sbiterra                     (               ),
    .dbiterra                     (               )
);

endmodule
