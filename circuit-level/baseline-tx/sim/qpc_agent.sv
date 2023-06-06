`timescale 1ns/1ps
`default_nettype none

module qpc_agent #(
    parameter MAX_QP          = 256,
    parameter QP_PTR_WIDTH    = $clog2(MAX_QP)
)
(
    input  wire                     clk                     ,
    input  wire                     rst_n                   ,
    // qp context lookup
    input  wire                     i_qpc_hdr_lookup_valid  ,
    output wire                     o_qpc_hdr_lookup_ready  ,
    input  wire [QP_PTR_WIDTH-1:0]  i_qpc_hdr_lookup_qp_id  ,
    output reg                      o_qpc_valid             ,
    output reg  [15:0]              o_qpc_pkey              ,
    output reg  [2:0]               o_qpc_pmtu              ,
    output reg  [23:0]              o_qpc_dest_qpid         ,
    output reg  [23:0]              o_qpc_sq_curr_psn       ,
    output reg  [23:0]              o_qpc_sq_curr_msn       ,
    output reg  [127:0]             o_qpc_dest_ip           ,
    output reg  [7:0]               o_qpc_ttl               ,
    output reg  [5:0]               o_qpc_dscp              , 
    output reg  [47:0]              o_qpc_dest_mac          ,
    // qp context update 
    input wire                      i_qpc_hdr_update_valid  ,
    input wire  [QP_PTR_WIDTH-1:0]  i_qpc_hdr_update_qpid   ,
    input wire  [23:0]              i_qpc_sq_curr_psn       ,
    input wire  [23:0]              i_qpc_sq_curr_msn       
);

    assign o_qpc_hdr_lookup_ready = 1'b1;

    reg [23:0] psn_mem [0:MAX_QP-1];
    reg [23:0] msn_mem [0:MAX_QP-1];

    // initialize psn_mem and msn_mem, only for simulation purpose
    initial 
        begin
            for (int i = 0; i < MAX_QP; i = i + 1) 
                begin
                   psn_mem[i] = 24'h0; 
                   msn_mem[i] = 24'h0;
                end
        end
    // psn and msn
    always @(posedge clk or negedge rst_n)
        begin
            // lookup
            if(i_qpc_hdr_lookup_valid)
                begin
                    o_qpc_sq_curr_psn <= psn_mem[i_qpc_hdr_lookup_qp_id];
                    o_qpc_sq_curr_msn <= msn_mem[i_qpc_hdr_lookup_qp_id];
                end
            // update
            else if(i_qpc_hdr_update_valid)
                begin
                    psn_mem[i_qpc_hdr_lookup_qp_id] <= i_qpc_sq_curr_psn;
                    msn_mem[i_qpc_hdr_lookup_qp_id] <= i_qpc_sq_curr_msn;
                end
        end

    always @(posedge clk or negedge rst_n)
        begin
            if(~rst_n)
                begin
                    o_qpc_valid <= 1'b0;
                end
            else if(i_qpc_hdr_lookup_valid)
                begin
                    o_qpc_valid <= 1'b1;
                end
            else
                begin
                    o_qpc_valid <= 1'b0;
                end
        end

    always @(posedge clk or negedge rst_n)
        begin
            if(~rst_n)
                begin
                    o_qpc_pkey <= 16'h0;
                    o_qpc_pmtu <= 3'h0;
                    o_qpc_dest_qpid <= 24'h0;
                    o_qpc_sq_curr_psn <= 24'h0;
                    o_qpc_sq_curr_msn <= 24'h0;
                    o_qpc_dest_ip <= 128'h0;
                    o_qpc_ttl <= 8'h0;
                    o_qpc_dscp <= 6'h0;
                    o_qpc_dest_mac <= 48'h0;
                end
            else if(i_qpc_hdr_lookup_valid)
                begin
                    o_qpc_pkey <= {16{1'b1}};
                    o_qpc_pmtu <= 3'b010;
                    o_qpc_dest_qpid <= {{(24-QP_PTR_WIDTH){1'b0}}, i_qpc_hdr_update_qpid};
                    o_qpc_dest_ip <= {128{1'b1}};
                    o_qpc_ttl <= {8{1'b1}};
                    o_qpc_dscp <= {6{1'b1}};
                    o_qpc_dest_mac <= {48{1'b1}};
                end
        end

endmodule //qpc_agent