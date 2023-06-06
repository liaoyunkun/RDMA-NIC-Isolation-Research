`timescale 1ns/1ps
`default_nettype none

module station_writer #(
    parameter WQE_WIDTH            = 512 ,
    parameter PWQE_BUF_ADDR_WIDTH  = 2   ,
    parameter PWQE_BUF_WIDTH       = 512 ,
    parameter PWQE_SLOT_NUM        = 4   ,
    parameter PWQE_SLOT_ADDR_WIDTH = 2
)(
    input wire                              clk             ,
    input wire                              rst_n           ,
    // if* with wqe_cache (bs_group)
    input  wire [PWQE_SLOT_NUM-1:0]         i_bs_fifo_empty ,
    output reg  [PWQE_SLOT_NUM-1:0]         o_bs_fifo_rd    ,
    input  wire                             i_bs_wqe_val    ,
    input  wire [WQE_WIDTH-1:0]             i_bs_wqe        ,                   
    // if* with station_buffer 
    output wire                             o_ren_0         ,
    output reg                              o_wen_0         ,
    output reg  [PWQE_BUF_ADDR_WIDTH-1:0]   o_addr_0        ,
    output reg  [PWQE_BUF_WIDTH-1:0]        o_din_0         ,
    output reg                              o_set_req       ,
    output reg  [PWQE_SLOT_ADDR_WIDTH-1:0]  o_set_addr      ,
    input  wire [PWQE_SLOT_NUM-1:0]         i_slot_status
);

    reg wr_pending;
    // TODO: Currently, only one group of BS WQE is used for
    // TODO: micro benchmark. We simplify the implementation here.
    // TODO: implement bs_scheduler here
    // pop bs wqe from wqe_cache
    always @(posedge clk or negedge rst_n)
        begin
            if(~rst_n)
                begin
                    o_bs_fifo_rd <= {PWQE_SLOT_NUM{1'b0}};
                end
            else if(|o_bs_fifo_rd)
                begin
                    o_bs_fifo_rd <= {PWQE_SLOT_NUM{1'b0}};
                end
            else if(~i_bs_fifo_empty[0] & ~i_slot_status[0] & ~wr_pending & ~o_set_req)
                begin
                    o_bs_fifo_rd <= {{(PWQE_SLOT_NUM-1){1'b0}}, 1'b1};
                end
            else
                begin
                    o_bs_fifo_rd <= {PWQE_SLOT_NUM{1'b0}};
                end
        end
    
    always @(posedge clk or negedge rst_n)
        begin
            if(~rst_n)
                begin
                    wr_pending <= 1'b0;
                end
            else if(|o_bs_fifo_rd)
                begin
                    wr_pending <= 1'b1;
                end
            else if(i_bs_wqe_val)
                begin
                    wr_pending <= 1'b0;
                end
        end
    // write station_buffer
    assign o_ren_0 = 1'b0;
    always @(posedge clk or negedge rst_n)
        begin
            if(~rst_n)
                begin
                    o_wen_0 <= 1'b0;
                    o_addr_0 <= {PWQE_BUF_ADDR_WIDTH{1'b0}};
                    o_din_0 <= {PWQE_BUF_WIDTH{1'b0}}; 
                end
            else if(i_bs_wqe_val)
                begin
                    // TODO: fixed slot currently
                    o_wen_0 <= 1'b1;
                    o_addr_0 <= {PWQE_BUF_ADDR_WIDTH{1'b0}};
                    o_din_0 <= i_bs_wqe;
                end
            else
                begin
                    o_wen_0 <= 1'b0;
                    o_addr_0 <= {PWQE_BUF_ADDR_WIDTH{1'b0}};
                    o_din_0 <= {PWQE_BUF_WIDTH{1'b0}}; 
                end
        end

    always @(posedge clk or negedge rst_n)
        begin
            if(~rst_n)
                begin
                    o_set_req <= 1'b0;
                    o_set_addr <= {PWQE_SLOT_ADDR_WIDTH{1'b0}}; 
                end
            else if(i_bs_wqe_val)
                begin
                    // TODO: fixed currently
                    o_set_req <= 1'b1;
                    o_set_addr <= {PWQE_SLOT_ADDR_WIDTH{1'b0}}; 
                end
            else
                begin
                    o_set_req <= 1'b0;
                    o_set_addr <= {PWQE_SLOT_ADDR_WIDTH{1'b0}};
                end
        end
endmodule