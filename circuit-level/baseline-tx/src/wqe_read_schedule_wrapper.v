`default_nettype none
`timescale 1ns/1ps

module wqe_read_schedule_wrapper 
    #(
        parameter	MAX_QP          = 32,	        
        parameter	QP_PTR_WIDTH    = 5	
    )
    (
        input  wire 				      clk, 
        input  wire 				      rst_n, 
        input  wire 				      i_wqe_cache_alfull, 
        input  wire                       i_wqe_fetch_ready,
        input  wire [MAX_QP -1:0]         i_active,	
        output wire 			          o_arbit_val, 
        output wire [QP_PTR_WIDTH -1 :0]  o_qp_idx,
        output wire [MAX_QP -1:0]         o_qp_idx_one_hot
    );

    reg arbit;
    reg arbit_val;
    wire [MAX_QP-1:0] grant;
    wire rst;

    assign rst = ~rst_n;
    assign o_arbit_val = arbit_val;
    assign o_qp_idx_one_hot = grant;
    assign o_qp_idx = one_hot_2_dec(o_qp_idx_one_hot);
    // // arbit is a pulse triggered by i_wqe_fetch_ready
    always @(posedge clk or negedge rst_n)
        begin
            if(~rst_n)
                begin
                    arbit <= 1'b0;
                end
            else if(arbit)
                begin
                    arbit <= 1'b0;
                end
            else if(~i_wqe_cache_alfull)
                begin
                    arbit <= i_wqe_fetch_ready;
                end
        end
    always @(posedge clk or negedge rst_n) 
        begin
            if(~rst_n)
                begin
                    arbit_val <= 1'b0;
                end
            else
                begin
                    arbit_val <= arbit;
                end
        end

    // round_robin_arbiter#(
    //     .N      ( MAX_QP )
    // )u_round_robin_arbiter(
    //     .rst_an ( rst_n    ),
    //     .clk    ( clk      ),
    //     .rr_ena ( arbit    ),
    //     .req    ( i_active ),
    //     .grant  ( grant    )
    // );

    rr_16 u_rr_16 (
        .sys_clk(clk),
        .sys_rst(rst),
        .rr_ena(arbit),
        .rr_req(i_active),
        .rr_result(grant)
        );

    function [QP_PTR_WIDTH :0] one_hot_2_dec;
        input [MAX_QP-1 :0] in_val;
        integer 			       j;
        begin
            one_hot_2_dec = {QP_PTR_WIDTH {1'b0}};
            for (j = 0; j < MAX_QP ; j = j+1)
                if (in_val[j])
                    begin	
                        one_hot_2_dec = j; 
                    end
        end
    endfunction

    // wqe_read_schedule#(
    //     .MAX_QP       ( MAX_QP       ),
    //     .QP_PTR_WIDTH ( QP_PTR_WIDTH )
    // )u_wqe_read_schedule(
    //     .clk               ( clk               ),
    //     .rst_n             ( rst_n             ),
    //     .i_arbit           ( arbit             ),
    //     .i_enable          ( 1'b1              ),
    //     .i_active          ( i_active          ),
    //     .o_arbit_val       ( o_arbit_val       ),
    //     .o_qp_idx          ( o_qp_idx          ),
    //     .o_qp_idx_one_hot  ( o_qp_idx_one_hot  )
    // );

endmodule