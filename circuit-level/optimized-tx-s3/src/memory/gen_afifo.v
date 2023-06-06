`default_nettype wire
`timescale 1ns/1ps
module gen_afifo #(parameter
    DEVICE_FIFO               = "GENERAL"        , //"ALTERA","XILINX","GENERAL"
    IS_ARRAY_RAM              =   0              ,
    RAM_STYLE_MODE            =  "block"         , //"distributed", "registers","block","aoto"
    WIDTH_DATA                =   36             ,
    WIDTH_ADDR                =   9              ,
    WATERAGE_UP               =   1              , //���ֵ: alfull ��Ӧ��ˮλ + WATERAGE_UP   = full
    WATERAGE_DOWN             =   1              , //���ֵ��alempty��Ӧ��ˮλ - WATERAGE_DOWN = empty
    SHOW_AHEAD                =   1              , //1��ʾshow_aheadģʽ��0��ʾnormalģʽ
    OVERLIMIT_CHECK           =   1              , //
    OUT_REGISTERED            =   0              , // 0 -> no registered ;
                                                   // 1 -> ram embed registered data out ;
                                                   // 2 -> registered dq out of ram ;
    FIFO_SYNC_LEVEL           =   2                // 1,2
)
(
    input   wire                    wrclock  ,
    input   wire                    wr_rst   ,
    input   wire  [WIDTH_DATA-1:0]  wdata    ,
    input   wire                    wen      ,

    input   wire                    rdclock  ,
    input   wire                    rd_rst   ,
    input   wire                    ren      ,
    output  wire  [WIDTH_DATA-1:0]  rdata    ,

    output  wire                    alfull   ,
    output  wire                    full     ,
    output  wire                    alempty  ,
    output  wire                    empty    ,
    output  wire  [WIDTH_ADDR-1:0]  wr_deep  ,
    output  wire  [WIDTH_ADDR-1:0]  rd_deep
);

generate
    if (DEVICE_FIFO == "XILINX") 
        begin: afifo
        localparam  READ_MODE = (SHOW_AHEAD == 1) ? "fwft" : "std";
        localparam  FIFO_READ_LATENCY = (SHOW_AHEAD == 1) ? 0 : 1;
        localparam  PROG_FULL_THRESH  = 2 ** WIDTH_ADDR - WATERAGE_UP ;
        localparam  PROG_EMPTY_THRESH = WATERAGE_DOWN ;
        // xpm_fifo_async: Asynchronous FIFO
        // Xilinx Parameterized Macro, Version 2017.4
        xpm_fifo_async # (
            .FIFO_MEMORY_TYPE       ( "auto"                ), //string; "auto", "block", or "distributed";
            .ECC_MODE               ( "no_ecc"              ), //string; "no_ecc" or "en_ecc";
            .RELATED_CLOCKS         ( 0                     ), //positive integer; 0 or 1
            .FIFO_WRITE_DEPTH       ( 2 ** WIDTH_ADDR       ), //positive integer
            .WRITE_DATA_WIDTH       ( WIDTH_DATA            ), //positive integer
            .WR_DATA_COUNT_WIDTH    ( WIDTH_ADDR            ), //positive integer
            .PROG_FULL_THRESH       ( PROG_FULL_THRESH      ), //positive integer
            .FULL_RESET_VALUE       ( 0                     ), //positive integer; 0 or 1
            .USE_ADV_FEATURES       ( "0707"                ), //string; "0000" to "1F1F";
            .READ_MODE              ( READ_MODE             ), //string; "std" or "fwft";
            .FIFO_READ_LATENCY      ( FIFO_READ_LATENCY     ), //positive integer;
            .READ_DATA_WIDTH        ( WIDTH_DATA            ), //positive integer
            .RD_DATA_COUNT_WIDTH    ( WIDTH_ADDR            ), //positive integer
            .PROG_EMPTY_THRESH      ( PROG_EMPTY_THRESH     ), //positive integer
            .DOUT_RESET_VALUE       ( "0"                   ), //string
            .CDC_SYNC_STAGES        ( 2                     ), //positive integer
            .WAKEUP_TIME            ( 0                     ) //positive integer; 0 or 2;
        )
        afifo_inst (
            .rst                    ( wr_rst      ),
            .wr_clk                 ( wrclock     ),
            .wr_en                  ( wen         ),
            .din                    ( wdata       ),
            .full                   ( full        ),
            .overflow               (             ),
            .prog_full              ( alfull      ),
            .wr_data_count          ( wr_deep     ),
            .almost_full            (             ),
            .wr_ack                 (             ),
            .wr_rst_busy            (             ),
            .rd_clk                 ( rdclock     ),
            .rd_en                  ( ren         ),
            .dout                   ( rdata       ),
            .empty                  ( empty       ),
            .underflow              (             ),
            .rd_rst_busy            (             ),
            .prog_empty             ( alempty     ),
            .rd_data_count          ( rd_deep     ),
            .almost_empty           (             ),
            .data_valid             (             ),
            .sleep                  ( 1'b0        ),
            .injectsbiterr          ( 1'b0        ),
            .injectdbiterr          ( 1'b0        ),
            .sbiterr                (             ),
            .dbiterr                (             )
        );
        end
    else 
        begin: afifo
        afifo #(
            .RAM_STYLE_MODE         ( RAM_STYLE_MODE      ), //"distributed", "registers","block"
            .WIDTH_DATA             ( WIDTH_DATA          ),
            .WIDTH_ADDR             ( WIDTH_ADDR          ),
            .WATERAGE_UP            ( WATERAGE_UP         ),
            .WATERAGE_DOWN          ( WATERAGE_DOWN       ),
            .SHOW_AHEAD             ( SHOW_AHEAD          ),
            .OVERLIMIT_CHECK        ( OVERLIMIT_CHECK     ),
            .OUT_REGISTERED         ( OUT_REGISTERED      ),
            .FIFO_SYNC_LEVEL        ( FIFO_SYNC_LEVEL     ),
            .IS_ARRAY_RAM           ( IS_ARRAY_RAM        )
        )
        afifo_inst (
            .wrclock                ( wrclock     ),
            .wr_rst                 ( wr_rst      ),
            .wdata                  ( wdata       ),
            .wen                    ( wen         ),

            .rdclock                ( rdclock     ),
            .rd_rst                 ( rd_rst      ),
            .ren                    ( ren         ),
            .rdata                  ( rdata       ),

            .alfull                 ( alfull      ),
            .full                   ( full        ),
            .alempty                ( alempty     ),
            .empty                  ( empty       ),
            .wr_deep                ( wr_deep     ),
            .rd_deep                ( rd_deep     )
        );

    end
endgenerate
endmodule
