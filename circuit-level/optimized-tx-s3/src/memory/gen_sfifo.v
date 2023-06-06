`default_nettype wire
`timescale 1ns/1ps
module gen_sfifo #(parameter
    DEVICE_FIFO               = "GENERAL"        , //"ALTERA","XILINX","GENERAL"
    IS_ARRAY_RAM              =   0              ,
    RAM_STYLE_MODE            =  "block"         , //"distributed", "registers","block","auto"
    WIDTH_DATA                =   32             ,
    WIDTH_ADDR                =   9              ,
    WATERAGE_UP               =   1              , //���ֵ: alfull ��Ӧ��ˮλ + WATERAGE_UP   = full
    WATERAGE_DOWN             =   1              , //���ֵ��alempty��Ӧ��ˮλ - WATERAGE_DOWN = empty
    SHOW_AHEAD                =   1              , //1��ʾshow_aheadģʽ��0��ʾnormalģʽ
    OVERLIMIT_CHECK           =   1              , //
    OUT_REGISTERED            =   0                // 0 -> no registered ;
                                                   // 1 -> ram embed registered data out ;
                                                   // 2 -> registered dq out of ram ;
)
(
    input   wire                    sys_clk  ,
    input   wire                    sys_rst  ,
    input   wire  [WIDTH_DATA-1:0]  wdata    ,
    input   wire                    wen      ,

    input   wire                    ren      ,
    output  wire  [WIDTH_DATA-1:0]  rdata    ,

    output  wire                    alfull   ,
    output  wire                    full     ,
    output  wire                    alempty  ,
    output  wire                    empty    ,
    output  wire  [WIDTH_ADDR-1:0]  deep
);

generate
    if (DEVICE_FIFO == "XILINX") 
        begin: sfifo
            localparam  READ_MODE = (SHOW_AHEAD == 1) ? "fwft" : "std";
            localparam  FIFO_READ_LATENCY = (SHOW_AHEAD == 1) ? 0 : 1;
            localparam  PROG_FULL_THRESH  = 2 ** WIDTH_ADDR - WATERAGE_UP ;
            localparam  PROG_EMPTY_THRESH = WATERAGE_DOWN ;
            // xpm_fifo_sync: Synchronous FIFO
            // Xilinx Parameterized Macro, Version 2017.4
            xpm_fifo_sync # (
                .FIFO_MEMORY_TYPE             ( "auto"            ), //string; "auto", "block", "distributed", or "ultra";
                .ECC_MODE                     ( "no_ecc"          ), //string; "no_ecc" or "en_ecc";
                .FIFO_WRITE_DEPTH             ( 2 ** WIDTH_ADDR   ), //positive integer
                .WRITE_DATA_WIDTH             ( WIDTH_DATA        ), //positive integer
                .WR_DATA_COUNT_WIDTH          ( WIDTH_ADDR        ), //positive integer
                .PROG_FULL_THRESH             ( PROG_FULL_THRESH  ), //positive integer
                .FULL_RESET_VALUE             ( 0                 ), //positive integer; 0 or 1
                .USE_ADV_FEATURES             ( "0707"            ), //string; "0000" to "1F1F";
                .READ_MODE                    ( READ_MODE         ), //string; "std" or "fwft";
                .FIFO_READ_LATENCY            ( FIFO_READ_LATENCY ), //positive integer;
                .READ_DATA_WIDTH              ( WIDTH_DATA        ), //positive integer
                .RD_DATA_COUNT_WIDTH          ( WIDTH_ADDR        ), //positive integer
                .PROG_EMPTY_THRESH            ( PROG_EMPTY_THRESH ), //positive integer
                .DOUT_RESET_VALUE             ( "0"               ), //string
                .WAKEUP_TIME                  ( 0                 ) //positive integer; 0 or 2;
            )
            sfifo_inst (
                .sleep                        ( 1'b0              ),
                .rst                          ( sys_rst           ),
                .wr_clk                       ( sys_clk           ),
                .wr_en                        ( wen               ),
                .din                          ( wdata             ),
                .full                         ( full              ),
                .overflow                     (                   ),
                .prog_full                    ( alfull            ),
                .wr_data_count                ( deep              ),
                .almost_full                  (                   ),
                .wr_ack                       (                   ),
                .wr_rst_busy                  (                   ),
                .rd_en                        ( ren               ),
                .dout                         ( rdata             ),
                .empty                        ( empty             ),
                .prog_empty                   ( alempty           ),
                .rd_data_count                (                   ),
                .almost_empty                 (                   ),
                .data_valid                   (                   ),
                .underflow                    (                   ),
                .rd_rst_busy                  (                   ),
                .injectsbiterr                ( 1'b0              ),
                .injectdbiterr                ( 1'b0              ),
                .sbiterr                      (                   ),
                .dbiterr                      (                   )
            );

        end
    else 
        begin: sfifo
            sfifo #(
                .RAM_STYLE_MODE               ( RAM_STYLE_MODE    ), //"distributed", "registers","block"
                .WIDTH_DATA                   ( WIDTH_DATA        ),
                .WIDTH_ADDR                   ( WIDTH_ADDR        ),
                .WATERAGE_UP                  ( WATERAGE_UP       ),
                .WATERAGE_DOWN                ( WATERAGE_DOWN     ),
                .SHOW_AHEAD                   ( SHOW_AHEAD        ),
                .OVERLIMIT_CHECK              ( OVERLIMIT_CHECK   ),
                .OUT_REGISTERED               ( OUT_REGISTERED    ),
                .IS_ARRAY_RAM                 ( IS_ARRAY_RAM      )
            )
            sfifo_inst (
                .sys_clk                      ( sys_clk           ),
                .sys_rst                      ( sys_rst           ),
                .wdata                        ( wdata             ),
                .wen                          ( wen               ),

                .ren                          ( ren               ),
                .rdata                        ( rdata             ),

                .alfull                       ( alfull            ),
                .full                         ( full              ),
                .alempty                      ( alempty           ),
                .empty                        ( empty             ),
                .deep                         ( deep              )
            );
        end
endgenerate

endmodule
