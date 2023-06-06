`default_nettype wire
`timescale 1ns/1ps
module mem_1r1w_xilinx #(parameter
    WIDTH_DATA                =   8              ,
    WIDTH_ADDR                =   8              ,
    DEVICE_RAM_TYPE           =   "AUTO"         ,  //"auto","distributed","block","ultra"
    DOUT_REG                  =   "false"           //"false":No register output;"true":register output
)
(
    input   wire                   wclk          ,
    input   wire [WIDTH_ADDR-1:0]  waddr         ,
    input   wire                   wen           ,
    input   wire [WIDTH_DATA-1:0]  din           ,
    input   wire                   rclk          ,
    input   wire                   ren           ,
    input   wire [WIDTH_ADDR-1:0]  raddr         ,
    output  wire [WIDTH_DATA-1:0]  dout
);

localparam READ_LATENCY_B = (DOUT_REG == "true") ? 2 : 1;

xpm_memory_sdpram # (
    // Common module parameters
    .MEMORY_SIZE                  ( WIDTH_DATA * (2 ** WIDTH_ADDR) ),
    .MEMORY_PRIMITIVE             ( DEVICE_RAM_TYPE                ),  //"auto","distributed","block","ultra"
    .CLOCKING_MODE                ( "independent_clock"            ),  //"independent_clock","common_clock"
    .ECC_MODE                     ( "no_ecc"                       ),
    .MEMORY_INIT_FILE             ( "none"                         ),
    .MEMORY_INIT_PARAM            ( ""                             ),
    .USE_MEM_INIT                 ( 1                              ),
    .WAKEUP_TIME                  ( "disable_sleep"                ),
    .AUTO_SLEEP_TIME              ( 0                              ),
    .MESSAGE_CONTROL              ( 0                              ),
    .USE_EMBEDDED_CONSTRAINT      ( 0                              ),
    .MEMORY_OPTIMIZATION          ( "true"                         ),
    // Port A module parameters
    .WRITE_DATA_WIDTH_A           ( WIDTH_DATA                     ),
    .BYTE_WRITE_WIDTH_A           ( WIDTH_DATA                     ),
    .ADDR_WIDTH_A                 ( WIDTH_ADDR                     ),
    // Port B module parameters
    .READ_DATA_WIDTH_B            ( WIDTH_DATA                     ),
    .ADDR_WIDTH_B                 ( WIDTH_ADDR                     ),
    .READ_RESET_VALUE_B           ( "0"                            ),
    .READ_LATENCY_B               ( READ_LATENCY_B                 ),
    .WRITE_MODE_B                 ( "read_first"                   )   //"write_first","read_first","no_change"
)
u_xpm_sdpram (
    // Common module ports
    .sleep                        ( 1'b0         ),
    // Port A module ports
    .clka                         ( wclk         ),
    .ena                          ( 1'b1         ),
    .wea                          ( {1{wen}}     ),
    .addra                        ( waddr        ),
    .dina                         ( din          ),
    .injectsbiterra               ( 1'b0         ),
    .injectdbiterra               ( 1'b0         ),
    // Port B module ports
    .clkb                         ( rclk         ),
    .rstb                         ( 1'b0         ),
    .enb                          ( ren          ),
    .regceb                       ( 1'b1         ),
    .addrb                        ( raddr        ),
    .doutb                        ( dout         ),
    .sbiterrb                     (              ),
    .dbiterrb                     (              )
);

endmodule
