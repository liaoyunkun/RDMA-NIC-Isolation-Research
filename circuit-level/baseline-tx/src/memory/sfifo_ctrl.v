`default_nettype wire
`timescale 1ns/1ps
module sfifo_ctrl #(parameter
    WIDTH_DATA                =   36     ,
    WIDTH_ADDR                =   8      ,
    //when deep >= MAX_DEEP - WATERAGE_UP , then alfull <= 1
    WATERAGE_UP               =   8      ,
    //when deep <= WATERAGE_DOWN , then alempty <= 1
    WATERAGE_DOWN             =   1      ,
    SHOW_AHEAD                =   1      ,
    OVERLIMIT_CHECK           =   1      ,
    OUT_REGISTERED            =   0
)
(
    input   wire                    sys_clk   ,
    input   wire                    sys_rst   ,

    input   wire                    wen       ,
    output  wire                    wen_allow ,
    output  wire  [WIDTH_ADDR-1:0]  waddr     ,

    input   wire                    ren       ,
    output  wire                    ren_allow ,
    output  wire  [WIDTH_ADDR-1:0]  raddr     ,

    output  reg                     alfull    ,
    output  reg                     full      ,
    output  reg                     alempty   ,
    output  reg                     empty     ,
    output  reg   [WIDTH_ADDR-1:0]  deep      ,
    output  wire                    pre_rd_ram_en,
    output  wire                    ren_shift_en
);

localparam  MAX_DEEP        = 1<<WIDTH_ADDR;  //{WIDTH_ADDR{1'b1}}    ; //(1<<WIDTH_ADDR)-1
localparam  WATERAGE_ALFULL = MAX_DEEP - WATERAGE_UP;

localparam ZERO     = 2'b00;
localparam ONE      = 2'b01;
localparam TWO      = 2'b10;
localparam TWO_PLUS = 2'b11;

reg   [WIDTH_ADDR:0]           raddr_reg     ;
reg   [WIDTH_ADDR:0]           raddr_next    ;
reg   [WIDTH_ADDR:0]           raddr_next_two;
reg   [WIDTH_ADDR:0]           waddr_reg     ;
reg   [WIDTH_ADDR:0]           waddr_next    ;
reg   [WIDTH_ADDR:0]           waddr_reg_dly1;

reg                            pre_read_en   ;
reg                            pre_rd_addr_en;
wire                           ren_allow_next;

assign  wen_allow   =  (OVERLIMIT_CHECK == 1)   ? wen & ~full  : wen  ;
assign  ren_allow   =  (OVERLIMIT_CHECK == 1)   ? ren & ~empty : ren  ;

assign  waddr       =  waddr_reg[WIDTH_ADDR-1:0];

generate  //read address gen function

if (SHOW_AHEAD == 0 && OUT_REGISTERED == 0) begin

    assign  raddr = raddr_reg[WIDTH_ADDR-1:0];

end
else if((SHOW_AHEAD == 1 && OUT_REGISTERED == 0) ||
        (SHOW_AHEAD == 0 && OUT_REGISTERED != 0)) begin

    assign  raddr = (ren_allow == 1'b1) ? raddr_next[WIDTH_ADDR-1:0] :
                                          raddr_reg[WIDTH_ADDR-1:0] ;

end
else if(SHOW_AHEAD == 1 && OUT_REGISTERED != 0) begin

    assign  raddr = (pre_rd_addr_en == 1'b1) ? raddr_reg[WIDTH_ADDR-1:0] :
                    (ren_allow_next == 1'b1) ? raddr_next_two[WIDTH_ADDR-1:0] :
                                               raddr_next[WIDTH_ADDR-1:0];

end

endgenerate

always @(posedge sys_clk or posedge sys_rst) begin
    if (sys_rst == 1'b1) begin
//        waddr_last <= {{(WIDTH_ADDR){1'b1}},1'b1};
        waddr_reg  <= {{(WIDTH_ADDR){1'b0}},1'b0};
        waddr_next <= {{(WIDTH_ADDR){1'b0}},1'b1};
    end
    else begin
//        waddr_last <= (wen_allow == 1'b1) ? waddr_reg         : waddr_last;
        waddr_reg  <= (wen_allow == 1'b1) ? waddr_next        : waddr_reg ;
        waddr_next <= (wen_allow == 1'b1) ? waddr_next + 1'b1 : waddr_next;
    end
end

// Read Address generator
always @(posedge sys_clk or posedge sys_rst) begin
    if (sys_rst == 1'b1) begin
        raddr_reg      <= {{(WIDTH_ADDR-1){1'b0}},2'b00};
        raddr_next     <= {{(WIDTH_ADDR-1){1'b0}},2'b01};
        raddr_next_two <= {{(WIDTH_ADDR-1){1'b0}},2'b10};
    end
    else begin
        raddr_reg      <= (ren_allow == 1'b1) ? raddr_next            : raddr_reg;
        raddr_next     <= (ren_allow == 1'b1) ? raddr_next_two        : raddr_next;
        raddr_next_two <= (ren_allow == 1'b1) ? raddr_next_two + 1'b1 : raddr_next_two;
    end
end

always @(posedge sys_clk or posedge sys_rst) begin
    if (sys_rst == 1'b1) begin
        deep  <= {WIDTH_ADDR{1'b0}};
    end
    else if (wen_allow == 1'b1 && ren_allow == 1'b0) begin
        deep  <= deep + 1'b1;
    end
    else if (ren_allow == 1'b1 && wen_allow == 1'b0) begin
        deep  <= deep - 1'b1;
    end
end

always @(posedge sys_clk or posedge sys_rst) begin
    if (sys_rst == 1'b1) begin
        alempty   <= 1'b1;
    end
    else if (deep == WATERAGE_DOWN + 1'b1) begin
        if (ren_allow == 1'b1 && wen_allow == 1'b0) begin
            alempty   <= 1'b1;
        end
    end
    else if (deep == WATERAGE_DOWN) begin
        if (ren_allow == 1'b0 && wen_allow == 1'b1) begin
            alempty   <= 1'b0;
        end
    end
end

always @(posedge sys_clk or posedge sys_rst) begin
    if (sys_rst == 1'b1) begin
        alfull   <= 1'b0;
    end
    else if (deep == WATERAGE_ALFULL - 1'b1) begin
        if (ren_allow == 1'b0 && wen_allow == 1'b1) begin
            alfull   <= 1'b1;
        end
    end
    else if (deep == WATERAGE_ALFULL) begin
        if (ren_allow == 1'b1 && wen_allow == 1'b0) begin
            alfull   <= 1'b0;
        end
    end
end

//##############################################################################
// Empty and Full generator
//##############################################################################
generate  //empty and full function

if (SHOW_AHEAD == 0 && OUT_REGISTERED == 0) begin
    // Good compared with Altera normal FIFO
    always @(posedge sys_clk or posedge sys_rst) begin
        if (sys_rst == 1'b1) begin
            empty <= 1'b1;
        end
        else begin
            if(deep == 1 && ren_allow == 1'b1 && wen_allow == 1'b0) begin
                empty <= 1'b1;
            end
            else if(empty == 1'b1 && wen_allow == 1'b1) begin
                empty <= 1'b0;
            end
        end
    end

    always @(posedge sys_clk or posedge sys_rst) begin
        if (sys_rst == 1'b1) begin
            full <= 1'b0;
        end
        else begin
            if(deep == (MAX_DEEP - 1) && ren_allow == 1'b0 && wen_allow == 1'b1) begin
                full <= 1'b1;
            end
            else if(full == 1'b1 && ren_allow == 1'b1) begin
                full <= 1'b0;
            end
        end
    end

    assign pre_rd_ram_en = 1'b0;
    assign ren_shift_en  = 1'b0;

end
else if((SHOW_AHEAD == 1 && OUT_REGISTERED == 0) ||
        (SHOW_AHEAD == 0 && OUT_REGISTERED != 0)) begin

    // Good compared with Altera show ahead FIFO
    always @(posedge sys_clk or posedge sys_rst) begin
        if (sys_rst == 1'b1) begin
            empty   <= 1'b1;
        end
        else if((waddr_reg == raddr_reg) || (ren_allow == 1'b1 && (waddr_reg == raddr_next))) begin
            empty   <= 1'b1;
        end
        else begin
            empty   <= 1'b0;
        end
    end

    always @(posedge sys_clk or posedge sys_rst) begin
        if (sys_rst == 1'b1) begin
            full   <= 1'b0;
        end
        else if (((waddr_reg[WIDTH_ADDR-1:0] == raddr_reg[WIDTH_ADDR-1:0]) &&
                  (waddr_reg[WIDTH_ADDR] != raddr_reg[WIDTH_ADDR])) ||
                 (wen_allow == 1'b1 && (waddr_next[WIDTH_ADDR-1:0] == raddr_reg[WIDTH_ADDR-1:0]) &&
                  (waddr_next[WIDTH_ADDR] != raddr_reg[WIDTH_ADDR]))) begin
            full   <= 1'b1;
        end
        else begin
            full   <= 1'b0;
        end
    end

    always @(posedge sys_clk or posedge sys_rst) begin
        if (sys_rst == 1'b1) begin
            pre_read_en <= 1'b0;
        end
        else begin
            case (pre_read_en)
                1'b0 : begin
                    if(empty == 1'b1) begin
                        if(wen_allow == 1'b1)
                            pre_read_en <= 1'b1;
                        else
                            pre_read_en <= 1'b0;
                    end
                    else begin
                        if(waddr_reg == raddr_next && wen_allow == 1'b1 && ren_allow == 1'b1 )
                            pre_read_en <= 1'b1;
                        else
                            pre_read_en <= 1'b0;
                    end
                end
                1'b1 : begin
                    pre_read_en <= 1'b0;
                end
                default : begin
                    pre_read_en <= 1'b0;
                end
            endcase
        end
    end

    assign pre_rd_ram_en = pre_read_en;
    assign ren_shift_en  = 1'b0;

end
else if(SHOW_AHEAD == 1 && OUT_REGISTERED != 0) begin

reg     [1:0]       deep_state;

reg     pre_empty;
reg     ren_shift_en1;

    always @(posedge sys_clk or posedge sys_rst) begin
        if (sys_rst == 1'b1) begin
            pre_empty     <= 1'b1;
        end
        else if((waddr_reg == raddr_next) ||
                /*(ren_allow == 1'b1 && waddr_reg == raddr_next) || */
                (ren_allow == 1'b1 && waddr_reg == raddr_next_two)) begin
            pre_empty     <= 1'b1;
        end
        else begin
            pre_empty     <= 1'b0;
        end
    end

    always @(posedge sys_clk or posedge sys_rst) begin
        if (sys_rst == 1'b1) begin
            waddr_reg_dly1 <= {{(WIDTH_ADDR){1'b0}},1'b0};
        end
        else begin
            waddr_reg_dly1 <= waddr_reg;
        end
    end

    always @(posedge sys_clk or posedge sys_rst) begin
        if (sys_rst == 1'b1) begin
            empty     <= 1'b1;
        end
        else if((waddr_reg_dly1 == raddr_reg) ||
                (ren_allow == 1'b1 && waddr_reg_dly1 == raddr_next) ) begin
            empty     <= 1'b1;
        end
        else begin
            empty     <= 1'b0;
        end
    end

    always @(posedge sys_clk or posedge sys_rst) begin
        if (sys_rst == 1'b1) begin
            full   <= 1'b0;
        end
        else if (((waddr_reg[WIDTH_ADDR-1:0] == raddr_reg[WIDTH_ADDR-1:0]) &&
                  (waddr_reg[WIDTH_ADDR] != raddr_reg[WIDTH_ADDR])) ||
                 (wen_allow == 1'b1 && (waddr_next[WIDTH_ADDR-1:0] == raddr_reg[WIDTH_ADDR-1:0]) &&
                  (waddr_next[WIDTH_ADDR] != raddr_reg[WIDTH_ADDR]))) begin
            full   <= 1'b1;
        end
        else begin
            full   <= 1'b0;
        end
    end

    always @(posedge sys_clk or posedge sys_rst) begin
        if (sys_rst == 1'b1) begin
            pre_rd_addr_en <= 1'b0;
        end
        else begin
            case (pre_rd_addr_en)
                1'b0 : begin
                    if(empty == 1'b1) begin
                        if(waddr_reg == raddr_reg && wen_allow == 1'b1)
                            pre_rd_addr_en <= 1'b1;
                        else
                            pre_rd_addr_en <= 1'b0;
                    end
                    else begin
                        if(waddr_reg == raddr_next && wen_allow == 1'b1 && ren_allow == 1'b1)
                            pre_rd_addr_en <= 1'b1;
                        else
                            pre_rd_addr_en <= 1'b0;
                    end
                end
                1'b1 : begin
                    pre_rd_addr_en <= 1'b0;
                end
                default : begin
                    pre_rd_addr_en <= 1'b0;
                end
            endcase
        end
    end

    assign ren_allow_next = ren_allow & ~pre_empty;
    assign pre_rd_ram_en  = pre_read_en;
    assign ren_shift_en   = ren_shift_en1 | ren_allow_next;
    
    always @(posedge sys_clk or posedge sys_rst) begin
        if (sys_rst == 1'b1) begin
            deep_state <= ZERO;
            pre_read_en <= 1'b0;
            ren_shift_en1 <= 1'b0;
        end
        else begin
            case (deep_state)
                ZERO : begin
                    //state transform
                    if(wen_allow == 1'b1) begin
                        deep_state <= ONE;
                    end
                    
                    //action generate
                    if(wen_allow == 1'b1) begin
                        pre_read_en <= 1'b1;
                    end
                    else begin
                        pre_read_en <= 1'b0;
                    end
                    ren_shift_en1 <= 1'b0;
                end
                ONE  : begin
                    //state transform
                    if(wen_allow == 1'b1 && ren_allow == 1'b0) begin
                        deep_state <= TWO;
                    end
                    else if(wen_allow == 1'b0 && ren_allow == 1'b1) begin
                        deep_state <= ZERO;
                    end
                    else begin
                        deep_state <= ONE;
                    end
                    
                    //action generate
                    if(wen_allow == 1'b1 || ren_allow == 1'b1) begin
                        pre_read_en <= 1'b1;
                    end
                    else begin
                        pre_read_en <= 1'b0;
                    end
                    if(ren_shift_en1 == 1'b0) begin
                        ren_shift_en1 <= pre_read_en;
                    end
                    else begin
                        ren_shift_en1 <= 1'b0;
                    end
                end
                TWO  : begin
                    //state transform
                    if(ren_allow == 1'b1 && wen_allow == 1'b0) begin
                        deep_state <= ONE;
                    end
                    else if(ren_allow == 1'b0 && wen_allow == 1'b1) begin
                        deep_state <= TWO_PLUS;
                    end
                    else begin
                        deep_state <= TWO;
                    end
                    
                    //action generate
                    if(ren_allow == 1'b1 && wen_allow == 1'b1) begin
                        pre_read_en <= 1'b1;
                    end
                    else begin
                        pre_read_en <= 1'b0;
                    end
                    if(ren_shift_en1 == 1'b0) begin
                        ren_shift_en1 <= pre_read_en & ren_allow;
                    end
                    else begin
                        ren_shift_en1 <= 1'b0;
                    end
                end
                TWO_PLUS : begin
                    //state transform
                    if(waddr_reg == (raddr_next_two + 1'b1) && ren_allow == 1'b1 && wen_allow == 1'b0) begin
                        deep_state <= TWO;
                    end
                    else begin
                        deep_state <= TWO_PLUS;
                    end
                    //action generate
                    pre_read_en <= 1'b0;
                    ren_shift_en1 <= 1'b0;
                end
                default : begin
                    deep_state <= ZERO;
                end
            endcase
        end
    end

end

endgenerate

endmodule
