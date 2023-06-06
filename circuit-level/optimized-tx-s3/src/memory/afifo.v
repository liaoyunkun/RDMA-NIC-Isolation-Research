`default_nettype wire
`timescale 1ns/1ps
module afifo #(parameter
    RAM_STYLE_MODE            =  "block"         , //"distributed", "registers","block"
    WIDTH_DATA                =   36             ,
    WIDTH_ADDR                =   9              ,
    WATERAGE_UP               =   1              ,
    WATERAGE_DOWN             =   1              ,
    SHOW_AHEAD                =   1              ,
    OVERLIMIT_CHECK           =   1              ,
    // 0 -> no registered ;
    // 1 -> ram embed registered data out ;
    // 2 -> registered dq out of ram ;
    OUT_REGISTERED            =   0              ,
    FIFO_SYNC_LEVEL           =   2              ,
    IS_ARRAY_RAM              =   0
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

//##############################################################################
//  ��������  localparam
//##############################################################################

localparam  DOUT_REG = (OUT_REGISTERED == 1) ? "true" : "false";

wire                           wen_allow  ;
wire  [WIDTH_ADDR-1:0]         waddr      ;

wire                           ren_allow  ;
wire  [WIDTH_ADDR-1:0]         raddr      ;
wire  [WIDTH_DATA-1:0]         rdata_ram  ; //RAMֱ����� û�мĴ�
reg   [WIDTH_DATA-1:0]         rdata_reg  ;

wire                           rd_ram_en  ;

assign  rd_ram_en = (SHOW_AHEAD == 1 || (SHOW_AHEAD == 0 && OUT_REGISTERED != 0)) ? 1'b1 : ren_allow;
assign  rdata     = (OUT_REGISTERED == 2) ? rdata_reg  : rdata_ram ;

afifo_ctrl  # (
    .WIDTH_DATA     ( WIDTH_DATA       ) ,
    .WIDTH_ADDR     ( WIDTH_ADDR       ) ,
    .WATERAGE_UP    ( WATERAGE_UP      ) ,
    .WATERAGE_DOWN  ( WATERAGE_DOWN    ) ,
    .SHOW_AHEAD     ( SHOW_AHEAD       ) ,
    .OVERLIMIT_CHECK( OVERLIMIT_CHECK  ) ,
    .OUT_REGISTERED ( OUT_REGISTERED   ) ,
    .FIFO_SYNC_LEVEL( FIFO_SYNC_LEVEL  )
)
u_afifo_ctrl (
    .wr_rst         ( wr_rst           ) ,
    .wrclock        ( wrclock          ) ,
    .wen            ( wen              ) ,
    .wen_allow      ( wen_allow        ) ,
    .waddr          ( waddr            ) ,

    .rd_rst         ( rd_rst           ) ,
    .rdclock        ( rdclock          ) ,
    .ren            ( ren              ) ,
    .ren_allow      ( ren_allow        ) ,
    .raddr          ( raddr            ) ,

    .alfull         ( alfull           ) ,
    .full           ( full             ) ,
    .alempty        ( alempty          ) ,
    .empty          ( empty            ) ,
    .wr_deep        ( wr_deep          ) ,
    .rd_deep        ( rd_deep          )
);

// FIFO RAM
mem_1r1w #(
    .WIDTH_DATA     ( WIDTH_DATA       ) ,
    .WIDTH_ADDR     ( WIDTH_ADDR       ) ,
    .IS_ARRAY_RAM   ( IS_ARRAY_RAM     ) ,
    .DOUT_REG       ( DOUT_REG         )
) u_afifo_ram (
    .wclk           ( wrclock          ) ,
    .wen            ( wen_allow        ) ,
    .waddr          ( waddr            ) ,
    .din            ( wdata            ) ,
    .rclk           ( rdclock          ) ,
    .ren            ( rd_ram_en        ) ,
    .raddr          ( raddr            ) ,
    .dout           ( rdata_ram        )
);

always @(posedge rdclock or posedge rd_rst) begin
    if (rd_rst == 1'b1) begin
        rdata_reg  <= {WIDTH_DATA{1'b0}};
    end
    else if (SHOW_AHEAD == 1'b1) begin
            rdata_reg  <=  rdata_ram;
    end
    else begin
        if (ren_allow == 1'b1) begin
            rdata_reg  <=  rdata_ram;
        end
    end
end

`ifdef ASSERT_ON
// synopsys translate_off
defparam  u_afifo_ram.RC_NO_SAME_ADDR_CHECK = 1;
sva_afifo   sva_afifo_inst();
// synopsys translate_on
`endif

initial begin : config_drc
    reg drc_err_flag;
    drc_err_flag = 0;
    #1;

    if (!(WIDTH_ADDR >= 3 && WIDTH_ADDR <= 32)) begin
      $error("[%s %0d-%0d] WIDTH_ADDR (%0d) value specified is not within the supported ranges. Miniumum supported depth is 3, and the maximum supported depth is 32 locations. %m", "RC_AFIFO", 1, 0, WIDTH_ADDR);
      drc_err_flag = 1;
    end

    if (!((WIDTH_DATA * (2 ** WIDTH_ADDR)) >= 8 && (WIDTH_DATA * (2 ** WIDTH_ADDR)) <= 4*1024*1024)) begin
      $error("[%s %0d-%0d] WIDTH_DATA(%0d) x 2^WIDTH_ADDR (%0d) value specified is not within the supported ranges. Miniumum supported depth is 8, and the maximum supported depth is 4*1024*1024 locations. %m", "RC_AFIFO", 1, 1, WIDTH_DATA, WIDTH_ADDR);
      drc_err_flag = 1;
    end

    if (drc_err_flag == 1)
      #1 $finish;
end : config_drc

endmodule
