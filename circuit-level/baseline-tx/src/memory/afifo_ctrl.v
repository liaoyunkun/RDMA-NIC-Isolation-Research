`default_nettype wire
`timescale 1ns/1ps
module afifo_ctrl #(parameter
    WIDTH_DATA                =   36     ,
    WIDTH_ADDR                =   8      ,
    //when deep > MAX_DEEP - WATERAGE_UP , then alfull <= 1
    WATERAGE_UP               =   8      ,
    //when deep <= WATERAGE_DOWN , then alempty <= 1
    WATERAGE_DOWN             =   1      ,
    SHOW_AHEAD                =   0      ,
    OVERLIMIT_CHECK           =   1      ,
    OUT_REGISTERED            =   0      ,
    FIFO_SYNC_LEVEL           =   2
)
(
    input   wire                    wrclock   ,
    input   wire                    wr_rst    ,
    input   wire                    wen       ,
    output  wire                    wen_allow ,
    output  wire  [WIDTH_ADDR-1:0]  waddr     ,

    input   wire                    rdclock   ,
    input   wire                    rd_rst    ,
    input   wire                    ren       ,
    output  wire                    ren_allow ,
    output  wire  [WIDTH_ADDR-1:0]  raddr     ,
//    input   wire  [WIDTH_DATA-1:0]  rdata_ram ,
//    output  wire  [WIDTH_DATA-1:0]  rdata     ,

    output  wire                    alfull    ,
    output  reg                     full      ,
    output  wire                    alempty   ,
    output  reg                     empty     ,
    output  wire  [WIDTH_ADDR-1:0]  wr_deep   ,
    output  wire  [WIDTH_ADDR-1:0]  rd_deep
);

localparam  MAX_DEEP        = {WIDTH_ADDR{1'b1}};
localparam  WATERAGE_ALFULL = MAX_DEEP - WATERAGE_UP;

reg     [(WIDTH_ADDR - 1) : 0]  rd_addr       ;
reg     [(WIDTH_ADDR - 1) : 0]  rd_addr_gray1 ;
reg     [(WIDTH_ADDR - 1) : 0]  rd_addr_gray2 ;
reg     [(WIDTH_ADDR - 1) : 0]  rd_addr_gray3 ;
reg     [(WIDTH_ADDR - 1) : 0]  wr_addr       ;
reg     [(WIDTH_ADDR - 1) : 0]  wr_addr_gray1 ;
reg     [(WIDTH_ADDR - 1) : 0]  wr_addr_gray2 ;
(* ASYNC_REG = "TRUE" *) reg     [(WIDTH_ADDR - 1) : 0]  rd_addr_gray3s;
(* ASYNC_REG = "TRUE" *) reg     [(WIDTH_ADDR - 1) : 0]  rd_addr_gray2s;
(* ASYNC_REG = "TRUE" *) reg     [(WIDTH_ADDR - 1) : 0]  wr_addr_gray2s;

wire    [(WIDTH_ADDR - 1) : 0]  rd_addr_to_gray         ;
wire    [(WIDTH_ADDR - 1) : 0]  wr_addr_to_gray         ;
wire    [(WIDTH_ADDR - 1) : 0]  wr_addr_gray2_to_bin    ;
wire    [(WIDTH_ADDR - 1) : 0]  rd_addr_gray2s_to_bin   ;
wire    [(WIDTH_ADDR - 1) : 0]  wr_addr_gray2s_to_bin   ;
wire    [(WIDTH_ADDR - 1) : 0]  rd_addr_gray2_to_bin    ;

reg     [(WIDTH_ADDR - 1) : 0]  fifo_rd_used_cnt;
reg     [(WIDTH_ADDR - 1) : 0]  fifo_wr_used_cnt;

wire                            read_allow    ;
wire                            write_allow   ;
reg                             water_dn      ;
reg                             water_up      ;
wire                            emptyg        ;
wire                            almostemptyg  ;
wire                            fullg         ;
wire                            almostfullg   ;
reg                             almost_full   ;
reg                             almost_empty  ;

assign waddr        = wr_addr_gray2   ;
assign raddr        = (SHOW_AHEAD == 0 && OUT_REGISTERED == 0) ? rd_addr_gray2 :
                      (read_allow == 1'b1) ? rd_addr_gray1 : rd_addr_gray2;

assign alfull       = (WATERAGE_UP   == 1) ? almost_full : water_up;
assign alempty      = (WATERAGE_DOWN == 1) ? almost_empty: water_dn;
assign wr_deep      = fifo_wr_used_cnt;
assign rd_deep      = fifo_rd_used_cnt;
assign wen_allow    = write_allow     ;
assign ren_allow    = read_allow      ;

assign read_allow   = (OVERLIMIT_CHECK == 1) ? ren & ~empty : ren;
assign write_allow  = (OVERLIMIT_CHECK == 1) ? wen & ~full  : wen;

bin_to_gray #(WIDTH_ADDR) b2g_inst1(rd_addr,rd_addr_to_gray);
bin_to_gray #(WIDTH_ADDR) b2g_inst2(wr_addr,wr_addr_to_gray);

//------------------------------------------------------------------------------
// Generate the read addresses & pipelined gray-code versions
// If you're reading along in the Xilinx XAPP174, here's the conversion chart:
//   rd_addr_gray1 == read_nextgray
//   rd_addr_gray2 == read_addrgray
//   rd_addr_gray3 == read_lastgray
//
//  The addr and gray-code reset procedure has been designed
//  to be more "dumb-proof" when parameterized.  The initial
//  values are different than the Xilinx version.
//------------------------------------------------------------------------------
always @(posedge rdclock or posedge rd_rst) begin
    if(rd_rst) begin
        rd_addr_gray3 <= 2'd0;
        rd_addr_gray2 <= 2'd1;
        rd_addr_gray1 <= 2'd3;
        rd_addr       <= 2'd3;
    end
    else begin
        if(read_allow == 1'b1) begin
            rd_addr       <= rd_addr + 1'b1;
            rd_addr_gray1 <= rd_addr_to_gray;
            rd_addr_gray2 <= rd_addr_gray1;
            rd_addr_gray3 <= rd_addr_gray2;
        end
    end
end

//------------------------------------------------------------------------------
//  Generate the write addresses & pipelined gray-code versions
//    wr_addr_gray1 == write_nextgray
//    wr_addr_gray2 == write_addrgray
//------------------------------------------------------------------------------
always @(posedge wrclock or posedge wr_rst) begin
    if(wr_rst) begin
        wr_addr_gray2 <= 2'd1;
        wr_addr_gray1 <= 2'd3;
        wr_addr       <= 2'd3;
    end
    else begin
        if(write_allow == 1'b1) begin
            wr_addr       <= wr_addr + 1'b1;
            wr_addr_gray1 <= wr_addr_to_gray;
            wr_addr_gray2 <= wr_addr_gray1;
        end
    end
end

//------------------------------------------------------------------------------
//  gray-code transfer to different clock domain
//------------------------------------------------------------------------------
generate

if (FIFO_SYNC_LEVEL == 1) begin:level_one

    always @(posedge rdclock or posedge rd_rst) begin
        if(rd_rst == 1'b1) begin
            wr_addr_gray2s <= 2'd1;
        end
        else begin
            wr_addr_gray2s <= wr_addr_gray2;
        end
    end

    always @(posedge wrclock or posedge wr_rst) begin
        if(wr_rst == 1'b1) begin
            rd_addr_gray3s <= 2'd0;
            rd_addr_gray2s <= 2'd1;
        end
        else begin
            rd_addr_gray3s <= rd_addr_gray3;
            rd_addr_gray2s <= rd_addr_gray2;
        end
    end

end
else if (FIFO_SYNC_LEVEL == 2) begin:level_two

(* ASYNC_REG = "TRUE" *) reg     [(WIDTH_ADDR - 1) : 0]  rd_addr_gray3s_meta;
(* ASYNC_REG = "TRUE" *) reg     [(WIDTH_ADDR - 1) : 0]  rd_addr_gray2s_meta;
(* ASYNC_REG = "TRUE" *) reg     [(WIDTH_ADDR - 1) : 0]  wr_addr_gray2s_meta;

    always @(posedge rdclock or posedge rd_rst) begin
        if(rd_rst == 1'b1) begin
            wr_addr_gray2s_meta <= 2'd1;
            wr_addr_gray2s      <= 2'd1;
        end
        else begin
            wr_addr_gray2s_meta  <= wr_addr_gray2;
            wr_addr_gray2s <= wr_addr_gray2s_meta;
        end
    end

    always @(posedge wrclock or posedge wr_rst) begin
        if(wr_rst == 1'b1) begin
            rd_addr_gray3s_meta <= 2'd0;
            rd_addr_gray3s      <= 2'd0;
        end
        else begin
            rd_addr_gray3s_meta  <= rd_addr_gray3;
            rd_addr_gray3s <= rd_addr_gray3s_meta;
        end
    end

    always @(posedge wrclock or posedge wr_rst) begin
        if(wr_rst == 1'b1) begin
            rd_addr_gray2s_meta <= 2'd1;
            rd_addr_gray2s      <= 2'd1;
        end
        else begin
            rd_addr_gray2s_meta <= rd_addr_gray2;
            rd_addr_gray2s <= rd_addr_gray2s_meta;
        end
    end

end
else begin:level_error

    always @(posedge rdclock or posedge rd_rst) begin
        if(rd_rst == 1'b1) begin
            wr_addr_gray2s <= 2'd1;
        end
        else begin
            wr_addr_gray2s <= wr_addr_gray2;
        end
    end

    always @(posedge wrclock or posedge wr_rst) begin
        if(wr_rst == 1'b1) begin
            rd_addr_gray3s <= 2'd0;
            rd_addr_gray2s <= 2'd1;
        end
        else begin
            rd_addr_gray3s <= rd_addr_gray3;
            rd_addr_gray2s <= rd_addr_gray2;
        end
    end

end

endgenerate

//------------------------------------------------------------------------------
//  read/write addr are compared
//------------------------------------------------------------------------------

assign emptyg       = (wr_addr_gray2s == rd_addr_gray2) ? 1'b1 : 1'b0;
assign almostemptyg = (wr_addr_gray2s == rd_addr_gray1) ? 1'b1 : 1'b0;
assign fullg        = (wr_addr_gray2 == rd_addr_gray3s) ? 1'b1 : 1'b0;
assign almostfullg  = (wr_addr_gray1 == rd_addr_gray3s) ? 1'b1 : 1'b0;

//------------------------------------------------------------------------------
//  Generate Empty
//------------------------------------------------------------------------------
always @(posedge rdclock or posedge rd_rst) begin
    if(rd_rst) begin
        empty <= 1'b1;
    end
    else begin
        if(emptyg == 1'b1 || (almostemptyg == 1'b1 && read_allow == 1'b1)) begin
            empty <= 1'b1;
        end
        else begin
            empty <= 1'b0;
        end
    end
end

//------------------------------------------------------------------------------
//  Generate Full
//------------------------------------------------------------------------------
always @(posedge wrclock or posedge wr_rst) begin
    if(wr_rst) begin
        full <= 1'b1;
    end
    else begin
        if(fullg == 1'b1 || (almostfullg == 1'b1 && write_allow == 1'b1)) begin
            full <= 1'b1;
        end
        else begin
            full <= 1'b0;
        end
    end
end

//------------------------------------------------------------------------------
//  Generate AlmostEmpty
//------------------------------------------------------------------------------
always @(posedge rdclock or posedge almostemptyg) begin
    if(almostemptyg) begin
        almost_empty <= 1'b1;
    end
    else begin
        if(emptyg == 1'b1) begin
            almost_empty <= 1'b1;
        end
        else begin
            almost_empty <= 1'b0;
        end
    end
end

//------------------------------------------------------------------------------
//  Generate AlmostFull
//------------------------------------------------------------------------------
always @(posedge wrclock or posedge almostfullg) begin
    if(almostfullg) begin
        almost_full <= 1'b1;
    end
    else begin
        if(fullg == 1'b1) begin
            almost_full <= 1'b1;
        end
        else begin
            almost_full <= 1'b0;
        end
    end
end

//------------------------------------------------------------------------------
//  Generate Used Counter
//------------------------------------------------------------------------------

gray_to_bin #(WIDTH_ADDR) g2b_inst1(wr_addr_gray2  , wr_addr_gray2_to_bin );
gray_to_bin #(WIDTH_ADDR) g2b_inst2(rd_addr_gray2s , rd_addr_gray2s_to_bin);
gray_to_bin #(WIDTH_ADDR) g2b_inst3(wr_addr_gray2s , wr_addr_gray2s_to_bin);
gray_to_bin #(WIDTH_ADDR) g2b_inst4(rd_addr_gray2  , rd_addr_gray2_to_bin );

always @(posedge rdclock or posedge rd_rst) begin
    if(rd_rst) begin
        fifo_rd_used_cnt <= {WIDTH_ADDR{1'b0}};
    end
    else begin
        fifo_rd_used_cnt <= wr_addr_gray2s_to_bin - rd_addr_gray2_to_bin;
    end
end

always @(posedge wrclock or posedge wr_rst) begin
    if(wr_rst) begin
        fifo_wr_used_cnt <= {WIDTH_ADDR{1'b0}};
    end
    else begin
        fifo_wr_used_cnt <= wr_addr_gray2_to_bin - rd_addr_gray2s_to_bin;
    end
end

//------------------------------------------------------------------------------
//  Generate water flag
//------------------------------------------------------------------------------

always @(posedge rdclock or posedge rd_rst) begin
    if(rd_rst) begin
        water_dn <= 1'b1;
    end
    else begin
        if(fifo_rd_used_cnt <= WATERAGE_DOWN) begin
            water_dn <= 1'b1;
        end
        else begin
            water_dn <= 1'b0;
        end
    end
end

always @(posedge wrclock or posedge wr_rst) begin
    if(wr_rst) begin
        water_up <= 1'b0;
    end
    else begin
        if(fifo_wr_used_cnt >= WATERAGE_ALFULL) begin
            water_up <= 1'b1;
        end
        else begin
            water_up <= 1'b0;
        end
    end
end

//##############################################################################
// ģ��ʵ����
//##############################################################################

endmodule

//##############################################################################
// �����Ʊ��뵽�������ת��ģ��
//##############################################################################
module bin_to_gray
#(
    parameter   WIDTH              = 4
)
(
    input       [(WIDTH-1) : 0]    din,
    output      [(WIDTH-1) : 0]    dout
);

assign dout = din ^ (din >> 1);

endmodule

//##############################################################################
// �����뵽�����Ʊ����ת��ģ��
//##############################################################################
module gray_to_bin
#(
    parameter   WIDTH              = 4
)
(
    input       [(WIDTH-1) : 0]    din,
    output      [(WIDTH-1) : 0]    dout
);

assign dout[WIDTH-1] = din[WIDTH-1];

generate

    genvar i;
    for(i = WIDTH-2 ; i >= 0 ; i = i-1)
    begin:inst
        xor (dout[i] , dout[i+1] , din[i]);
        //dout[i] = dout[i+1] ^ din[i];
    end

endgenerate

endmodule
