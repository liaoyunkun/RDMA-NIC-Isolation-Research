`default_nettype none
`timescale 1ns/1ps

module wqe_read_schedule_tb;
    localparam MAX_QP          = 256;
    localparam QP_PTR_WIDTH    = $clog2(MAX_QP) ;
    localparam TEST_CNT        = 500;

    reg 				       clk      = '0;
    reg 				       rst_n    = '0; 
    reg 				       i_arbit  = '0; 
    reg 				       i_enable = '0; 
    reg [MAX_QP -1:0]          i_active = '0;	
    wire 			           o_arbit_val; 
    wire [QP_PTR_WIDTH -1 :0]  o_qp_idx;
    wire [MAX_QP -1:0]         o_qp_idx_one_hot;

    always #5 clk = ~clk;
    
    initial 
        begin
            i_active = {{(MAX_QP-4){1'b1}}, 4'hc};
            i_enable = 1'b1;
            #10 rst_n = 1'b1;
            for (int i = 0; i < TEST_CNT; i = i + 1) 
                begin
                    enable_arbit();
                end
            #20;
            $finish;
        end

    wqe_read_schedule#(
        .MAX_QP            ( MAX_QP      ),
        .QP_PTR_WIDTH      ( QP_PTR_WIDTH)
    )u_wqe_read_schedule(
        .clk               ( clk         ),
        .rst_n             ( rst_n       ),
        .i_arbit           ( i_arbit     ),
        .i_enable          ( i_enable    ),
        .i_active          ( i_active    ),
        .o_arbit_val       ( o_arbit_val ),
        .o_qp_idx          ( o_qp_idx    ),
        .o_qp_idx_one_hot  ( o_qp_idx_one_hot  )
    );

    task enable_arbit();
        @(posedge clk)
            begin
                i_arbit <= 1'b1;
            end
        @(posedge clk)
            begin
                i_arbit <= 1'b0;
            end
    endtask

endmodule