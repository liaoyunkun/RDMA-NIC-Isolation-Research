`default_nettype wire
`timescale 1ns/1ps
module mem_1rw1rw_xilinx #(parameter
    WIDTH_DATA                =   8              ,
    WIDTH_ADDR                =   8              ,
    DEVICE_RAM_TYPE           =   "AUTO"         , //string; "auto", "distributed", "block" or "ultra";
    READ_DURING_WRITE_A       =   "new"          , //string; "new", "old", "no_change"
    READ_DURING_WRITE_B       =   "new"          , //string; "new", "old", "no_change"
    DOUT_REG_A                =   "false"        , //"false":No register output;"true":register output
    DOUT_REG_B                =   "false"          //"false":No register output;"true":register output
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
);

localparam READ_LATENCY_A = (DOUT_REG_A == "true") ? 2 : 1;
localparam READ_LATENCY_B = (DOUT_REG_B == "true") ? 2 : 1;
localparam WRITE_MODE_A   = (READ_DURING_WRITE_A == "old") ? "read_first"  :
                            (READ_DURING_WRITE_A == "new") ? "write_first" :
                                                             "no_change"   ;
localparam WRITE_MODE_B   = (READ_DURING_WRITE_B == "old") ? "read_first"  :
                            (READ_DURING_WRITE_B == "new") ? "write_first" :
                                                             "no_change"   ;

wire ram_ena;
wire ram_enb;
assign ram_ena = wena | rena;
assign ram_enb = wenb | renb;

// xpm_memory_tdpram: True Dual Port RAM
// Xilinx Parameterized Macro, Version 2017.4
xpm_memory_tdpram # (
    // Common module parameters
    .MEMORY_SIZE                  ( WIDTH_DATA * (2 ** WIDTH_ADDR)  ), //positive integer
    .MEMORY_PRIMITIVE             ( DEVICE_RAM_TYPE                 ), //string; "auto", "distributed", "block" or "ultra";
    .CLOCKING_MODE                ( "independent_clock"             ), //string; "common_clock", "independent_clock"
    .MEMORY_INIT_FILE             ( "none"                          ), //string; "none" or "<filename>.mem"
    .MEMORY_INIT_PARAM            ( ""                              ), //string;
    .USE_MEM_INIT                 ( 1                               ), //integer; 0,1
    .WAKEUP_TIME                  ( "disable_sleep"                 ), //string; "disable_sleep" or "use_sleep_pin"
    .MESSAGE_CONTROL              ( 0                               ), //integer; 0,1
    .ECC_MODE                     ( "no_ecc"                        ), //string; "no_ecc", "encode_only", "decode_only" or "both_encode_and_decode"
    .AUTO_SLEEP_TIME              ( 0                               ), //Do not Change
    .USE_EMBEDDED_CONSTRAINT      ( 0                               ), //integer: 0,1
    .MEMORY_OPTIMIZATION          ( "true"                          ), //string; "true", "false"
    // Port A module parameters
    .WRITE_DATA_WIDTH_A           ( WIDTH_DATA                      ), //positive integer
    .READ_DATA_WIDTH_A            ( WIDTH_DATA                      ), //positive integer
    .BYTE_WRITE_WIDTH_A           ( WIDTH_DATA                      ), //integer; 8, 9, or WRITE_DATA_WIDTH_A value
    .ADDR_WIDTH_A                 ( WIDTH_ADDR                      ), //positive integer
    .READ_RESET_VALUE_A           ( "0"                             ), //string
    .READ_LATENCY_A               ( READ_LATENCY_A                  ), //non-negative integer
    .WRITE_MODE_A                 ( WRITE_MODE_A                    ), //string; "write_first", "read_first", "no_change"
    // Port B module parameters
    .WRITE_DATA_WIDTH_B           ( WIDTH_DATA                      ), //positive integer
    .READ_DATA_WIDTH_B            ( WIDTH_DATA                      ), //positive integer
    .BYTE_WRITE_WIDTH_B           ( WIDTH_DATA                      ), //integer; 8, 9, or WRITE_DATA_WIDTH_B value
    .ADDR_WIDTH_B                 ( WIDTH_ADDR                      ), //positive integer
    .READ_RESET_VALUE_B           ( "0"                             ), //vector of READ_DATA_WIDTH_B bits
    .READ_LATENCY_B               ( READ_LATENCY_B                  ), //non-negative integer
    .WRITE_MODE_B                 ( WRITE_MODE_B                    )  //string; "write_first", "read_first", "no_change"
)
u_xpm_tdpram (
    // Common module ports
    .sleep                        ( 1'b0                  ),
    // Port A module ports
    .clka                         ( clka                  ),
    .rsta                         ( 1'b0                  ),
    .ena                          ( ram_ena               ),
    .regcea                       ( 1'b1                  ),
    .wea                          ( {1{wena}}             ),
    .addra                        ( addra                 ),
    .dina                         ( dina                  ),
    .injectsbiterra               ( 1'b0                  ),
    .injectdbiterra               ( 1'b0                  ),
    .douta                        ( douta                 ),
    .sbiterra                     (                       ),
    .dbiterra                     (                       ),
    // Port B module ports
    .clkb                         ( clkb                  ),
    .rstb                         ( 1'b0                  ),
    .enb                          ( ram_enb               ),
    .regceb                       ( 1'b1                  ),
    .web                          ( {1{wenb}}             ),
    .addrb                        ( addrb                 ),
    .dinb                         ( dinb                  ),
    .injectsbiterrb               ( 1'b0                  ),
    .injectdbiterrb               ( 1'b0                  ),
    .doutb                        ( doutb                 ),
    .sbiterrb                     (                       ),
    .dbiterrb                     (                       )
);

endmodule
