
`timescale 1ns/1ps
`default_nettype none

module grp_scheduler_tb;

    localparam WQE_WIDTH = 512;
    localparam PWQE_SLOT_NUM = 4;
    localparam PWQE_BUF_ADDR_WIDTH = 2;
    localparam PWQE_BUF_WIDTH = 512;

    reg                              clk              = '0;
    reg                              rst_n            = '0;
    // if* with wqe_cache
    reg                              i_ls_wqe_empty   = '0;
    wire                             o_ls_wqe_ren     ;
    reg   [WQE_WIDTH-1:0]            i_ls_wqe_rdata   = '0;
    // if* with station_buffer
    wire                             o_ren_1          ;
    wire                             o_wen_1          ;
    wire  [PWQE_BUF_ADDR_WIDTH-1:0]  o_addr_1         ;
    wire  [PWQE_BUF_WIDTH-1:0]       o_din_1          ;
    reg   [PWQE_BUF_WIDTH-1:0]       i_dout_1         = {PWQE_BUF_WIDTH{1'b1}};
    reg   [PWQE_SLOT_NUM-1:0]        i_slot_status    = '0;
    // if* with ib_transport
    wire                             o_wqe_cache_empty;
    reg                              i_wqe_cache_rd   = '0;
    wire                             o_wqe_val        ;
    wire                             o_wqe_type       ;
    wire [PWQE_BUF_ADDR_WIDTH-1:0]   o_wqe_addr       ;
    wire [WQE_WIDTH-1:0]             o_wqe            ;

    reg                              i_pwqe_wb        = '0;
    reg [PWQE_BUF_ADDR_WIDTH-1:0]    i_pwqe_addr      = '0;
    reg [WQE_WIDTH-1:0]              i_pwqe           = '0;

    bit [31:0] ls_cnt;
    bit [31:0] bs_0_cnt;
    bit [31:0] bs_1_cnt;
    bit [31:0] bs_2_cnt;
    bit [31:0] bs_3_cnt;

    always #5 clk = ~clk;

    initial 
        begin
            #10 rst_n = 1'b1;
            @(posedge clk)
                begin
                    i_ls_wqe_empty <= 1'b1;
                    i_ls_wqe_rdata <= {(WQE_WIDTH/4){4'ha}};
                    i_slot_status <= 4'b1111;
                end
            for (int i = 0; i < 10000; i = i + 1) 
                begin
                    @(posedge clk)
                        begin
                            i_wqe_cache_rd <= 1'b1;
                        end
                    @(posedge clk)
                        begin
                            i_wqe_cache_rd <= 1'b0;
                        end
                    @(posedge clk);
                    @(posedge clk);
                end
            $display("LS-CNT: %d, BS-0-CNT: %d, BS-1-CNT: %d, BS-2-CNT: %d, BS-3-CNT: %d\n", 
                        ls_cnt, bs_0_cnt, bs_1_cnt, bs_2_cnt, bs_3_cnt);
            $stop;
        end

    always @(posedge clk)
        begin
            if(o_wqe_val == 1'b1 && o_wqe_type == 1'b0)
                begin
                    ls_cnt <= ls_cnt + 1'b1;
                end
            else if(o_wqe_val == 1'b1 && o_wqe_type == 1'b1 && o_wqe_addr == 2'b0)
                begin
                    bs_0_cnt <= bs_0_cnt + 1'b1;
                end
            else if(o_wqe_val == 1'b1 && o_wqe_type == 1'b1 && o_wqe_addr == 2'b1)
                begin
                    bs_1_cnt <= bs_1_cnt + 1'b1;
                end
            else if(o_wqe_val == 1'b1 && o_wqe_type == 1'b1 && o_wqe_addr == 2'h2)
                begin
                    bs_2_cnt <= bs_2_cnt + 1'b1;
                end
            else if(o_wqe_val == 1'b1 && o_wqe_type == 1'b1 && o_wqe_addr == 2'h3)
                begin
                    bs_3_cnt <= bs_3_cnt + 1'b1;
                end
        end
    
    grp_scheduler#(
        .WQE_WIDTH           ( 512 ),
        .PWQE_SLOT_NUM       ( 4 ),
        .PWQE_BUF_ADDR_WIDTH ( 2 ),
        .PWQE_BUF_WIDTH      ( 512 )
    )u_grp_scheduler(
        .clk                 ( clk                 ),
        .rst_n               ( rst_n               ),
        .i_ls_wqe_empty      ( i_ls_wqe_empty      ),
        .o_ls_wqe_ren        ( o_ls_wqe_ren        ),
        .i_ls_wqe_rdata      ( i_ls_wqe_rdata      ),
        .o_ren_1             ( o_ren_1             ),
        .o_wen_1             ( o_wen_1             ),
        .o_addr_1            ( o_addr_1            ),
        .o_din_1             ( o_din_1             ),
        .i_dout_1            ( i_dout_1            ),
        .i_slot_status       ( i_slot_status       ),
        .o_wqe_cache_empty   ( o_wqe_cache_empty   ),
        .i_wqe_cache_rd      ( i_wqe_cache_rd      ),
        .o_wqe_val           ( o_wqe_val           ),
        .o_wqe_type          ( o_wqe_type          ),
        .o_wqe_addr          ( o_wqe_addr          ),
        .o_wqe               ( o_wqe               ),
        .i_pwqe_wb           ( i_pwqe_wb           ),
        .i_pwqe_addr         ( i_pwqe_addr         ),
        .i_pwqe              ( i_pwqe              )
    );


endmodule