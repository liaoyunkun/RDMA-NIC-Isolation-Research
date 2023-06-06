`timescale 1ns/1ps
`default_nettype none

module station_buffer #(
    parameter PWQE_BUF_ADDR_WIDTH  = 2   ,
    parameter PWQE_BUF_WIDTH       = 512 ,
    parameter PWQE_SLOT_NUM        = 4   ,
    parameter PWQE_SLOT_ADDR_WIDTH = 2
)(
    input  wire                             clk          ,
    input  wire                             rst_n        ,
    // if* with station_writer        
    input  wire                             i_ren_0      ,
    input  wire                             i_wen_0      ,
    input  wire [PWQE_BUF_ADDR_WIDTH-1:0]   i_addr_0     ,
    input  wire [PWQE_BUF_WIDTH-1:0]        i_din_0      ,
    input  wire                             i_set_req    ,
    input  wire [PWQE_SLOT_ADDR_WIDTH-1:0]  i_set_addr   ,
    // if*  with grp_scheduler    
    input  wire                             i_ren_1      ,
    input  wire                             i_wen_1      ,
    input  wire [PWQE_BUF_ADDR_WIDTH-1:0]   i_addr_1     ,
    input  wire [PWQE_BUF_WIDTH-1:0]        i_din_1      ,
    output wire [PWQE_BUF_WIDTH-1:0]        o_dout_1     ,
    output wire [PWQE_SLOT_NUM-1:0]         o_slot_status,
    // if* with ib_transport
    input  wire                             i_reset_req  ,
    input  wire [PWQE_SLOT_ADDR_WIDTH-1:0]  i_reset_addr 
);

    // instantiate sync dpsram
    p_wqe_dpsram #(
        .IS_ARRAY_RAM     (1                   ),
        .WIDTH_ADDR       (PWQE_BUF_ADDR_WIDTH ),
        .WIDTH_DATA       (PWQE_BUF_WIDTH      )
    ) p_wqe_dpsram_inst (
        .addra  (i_addr_0  ),
        .dina   (i_din_0   ),
        .wena   (i_wen_0   ),
        .rena   (i_ren_0   ),
        .clka   (clk       ),
        .douta  (          ),
    
        .addrb  (i_addr_1  ),
        .dinb   (i_din_1   ),
        .wenb   (i_wen_1   ),
        .renb   (i_ren_1   ),
        .clkb   (clk       ),
        .doutb  (o_dout_1  )
    );
    
    slot_status #(
        .SLOT_NUM       (PWQE_SLOT_NUM       ),
        .SLOT_ADDR_WIDTH(PWQE_SLOT_ADDR_WIDTH)
    ) slot_status_inst (
        .clk            (clk                 ),
        .rst_n          (rst_n               ),
        .i_set_req      (i_set_req           ),
        .i_set_addr     (i_set_addr          ),
        .i_reset_req    (i_reset_req         ),
        .i_reset_addr   (i_reset_addr        ),
        .o_slot_status  (o_slot_status       )
    );
endmodule