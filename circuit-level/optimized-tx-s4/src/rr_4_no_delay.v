`timescale 1ns / 10ps
`default_nettype none

module rr_4_no_delay
(
    input  wire       sys_clk,
    input  wire       sys_rst,
    input  wire       rr_ena,
    input  wire [3:0] rr_req,
    output wire [3:0] rr_result
);

    //*******  Register Declaration  *******//
    reg [3:0]         last_result;          //上一次RR调度的结果
    reg [3:0]         pq_result_unmask;     //未覆盖掩码前请求的PQ调度结果
    reg [3:0]         pq_result_mask;       //覆盖掩码后的请求的PQ调度结果
    reg [3:0]         mask;                 //根据上一次调度结果生成的掩码

    wire [3:0]        rr_req_mask;          //用掩码覆盖后生成的新的RR请求
    wire              req_mask_zero;        //掩码覆盖后生成的新RR请求为全0的标志

    //-----------------------------------------
    // 根据上一次调度结果生成掩码
    //-----------------------------------------
    always @(*)
        begin
            if (last_result[0] == 1'b1)
                mask = 4'b1110;
            else if (last_result[1] == 1'b1)
                mask = 4'b1100;
            else if (last_result[2] == 1'b1)
                mask = 4'b1000;
            else if (last_result[3] == 1'b1)
                mask = 4'b0000;
            else
                mask = 4'b11;
        end

    //-----------------------------------------
    // 用掩码覆盖生成新的RR请求
    //-----------------------------------------
    assign rr_req_mask = rr_req & mask;

    //-----------------------------------------
    // 未覆盖掩码前请求的PQ调度
    //-----------------------------------------
    always @(*)
        begin
            if(rr_req[0] == 1'b1)
                pq_result_unmask = 4'b0001;
            else if(rr_req[1] == 1'b1)
                pq_result_unmask = 4'b0010;
            else if(rr_req[2] == 1'b1)
                pq_result_unmask = 4'b0100;
            else if(rr_req[3] == 1'b1)
                pq_result_unmask = 4'b1000;
            else 
                pq_result_unmask = 4'b0;
        end

    //-----------------------------------------
    // 覆盖掩码后的请求的PQ调度
    //-----------------------------------------
    always @(*)
        begin
            if (rr_req_mask[0] == 1'b1)
                pq_result_mask = 4'b0001;
            else if (rr_req_mask[1] == 1'b1)
                pq_result_mask = 4'b0010;
            else if(rr_req_mask[2] == 1'b1)
                pq_result_mask = 4'b0100;
            else if(rr_req_mask[3] == 1'b1)
                pq_result_mask = 4'b1000;
            else
                pq_result_mask = 4'b0;
        end

    //----------------------------------------------------------------------------------------------
    // 生成最后的RR结果
    //*******************
    // 掩码后请求不全0就以掩码后请求的PQ结果为最终的RR结果，否则以初始请求的PQ调度结果为最终的RR结果
    //----------------------------------------------------------------------------------------------

    /* 判断掩码后的新请求是否为全0 */
    assign  req_mask_zero  =  ~|rr_req_mask;

    /* 取最终的RR结果 */
    assign rr_result = (req_mask_zero == 1'b1)? pq_result_unmask : pq_result_mask; 

    //-----------------------------------------
    // 储存RR的结果
    //-----------------------------------------
    always @(posedge sys_clk or posedge sys_rst)
        begin
            if (sys_rst == 1'b1)
                last_result <= 4'b0;
            else if (rr_ena == 1'b1)
                begin
                    if (req_mask_zero == 1'b1)
                        last_result <= pq_result_unmask;
                    else
                        last_result <= pq_result_mask;
                end
        end

endmodule