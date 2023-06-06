`timescale 1ns / 10ps
`default_nettype none

module rr_16(
    input  wire         sys_clk,
    input  wire         sys_rst,
    input  wire         rr_ena,
    input  wire [15:0]  rr_req,
    output reg  [15:0]  rr_result
);

  //******* Interface Signal Declaration  ********//
 

  //*******  Register Declaration  *******//
//   reg [15:0]         rr_result;            //本次RR调度的结果
reg [15:0]         last_result;          //上一次RR调度的结果
reg [15:0]         pq_result_unmask;     //未覆盖掩码前请求的PQ调度结果
reg [15:0]         pq_result_mask;       //覆盖掩码后的请求的PQ调度结果
reg [15:0]         mask;                 //根据上一次调度结果生成的掩码

wire [15:0]        rr_req_mask;          //用掩码覆盖后生成的新的RR请求
wire              req_mask_zero;        //掩码覆盖后生成的新RR请求为全0的标志

//-----------------------------------------
// 根据上一次调度结果生成掩码
//-----------------------------------------
always @(*)
    begin
        if (last_result[0] == 1'b1)
            mask = 16'b1111_1111_1111_1110;
        else if (last_result[1] == 1'b1)
            mask = 16'b1111_1111_1111_1100;
        else if (last_result[2] == 1'b1)
            mask = 16'b1111_1111_1111_1000;
        else if (last_result[3] == 1'b1)
            mask = 16'b1111_1111_1111_0000;
        else if (last_result[4] == 1'b1)
            mask = 16'b1111_1111_1110_0000;
        else if (last_result[5] == 1'b1)
            mask = 16'b1111_1111_1100_0000;
        else if (last_result[6] == 1'b1)
            mask = 16'b1111_1111_1000_0000;
        else if (last_result[7] == 1'b1)
            mask = 16'b1111_1111_0000_0000;
        else if (last_result[8] == 1'b1)
            mask = 16'b1111_1110_0000_0000;  
        else if (last_result[9] == 1'b1)
            mask = 16'b1111_1100_0000_0000;
        else if (last_result[10] == 1'b1)
            mask = 16'b1111_1000_0000_0000;
        else if (last_result[11] == 1'b1)
            mask = 16'b1111_0000_0000_0000;
        else if (last_result[12] == 1'b1)
            mask = 16'b1110_0000_0000_0000;
        else if (last_result[13] == 1'b1)
            mask = 16'b1100_0000_0000_0000;
        else if (last_result[14] == 1'b1)
            mask = 16'b1000_0000_0000_0000;
        else if (last_result[15] == 1'b1)
            mask = 16'b0000_0000_0000_0000;
        else
            mask = 16'b1111_1111_1111_1111;
    end

//-----------------------------------------
// 用掩码覆盖生成新的RR请求
//-----------------------------------------
assign   rr_req_mask = rr_req & mask;

//-----------------------------------------
// 未覆盖掩码前请求的PQ调度
//-----------------------------------------
always @(*)
    begin
        if (rr_req[0] == 1'b1)
            pq_result_unmask = 16'b0000_0000_0000_0001;
        else if (rr_req[1] == 1'b1)
            pq_result_unmask = 16'b0000_0000_0000_0010;
        else if (rr_req[2] == 1'b1)
            pq_result_unmask = 16'b0000_0000_0000_0100;
        else if (rr_req[3] == 1'b1)
            pq_result_unmask = 16'b0000_0000_0000_1000;
        else if (rr_req[4] == 1'b1)
            pq_result_unmask = 16'b0000_0000_0001_0000;
        else if (rr_req[5] == 1'b1)
            pq_result_unmask = 16'b0000_0000_0010_0000;
        else if (rr_req[6] == 1'b1)
            pq_result_unmask = 16'b0000_0000_0100_0000;
        else if (rr_req[7] == 1'b1)
            pq_result_unmask = 16'b0000_0000_1000_0000;   
        else if (rr_req[8] == 1'b1)
            pq_result_unmask = 16'b0000_0001_0000_0000;
        else if (rr_req[9] == 1'b1)
            pq_result_unmask = 16'b0000_0010_0000_0000;
        else if (rr_req[10] == 1'b1)
            pq_result_unmask = 16'b0000_0100_0000_0000;
        else if (rr_req[11] == 1'b1)
            pq_result_unmask = 16'b0000_1000_0000_0000;
        else if (rr_req[12] == 1'b1)
            pq_result_unmask = 16'b0001_0000_0000_0000;
        else if (rr_req[13] == 1'b1)
            pq_result_unmask = 16'b0010_0000_0000_0000;
        else if (rr_req[14] == 1'b1)
            pq_result_unmask = 16'b0100_0000_0000_0000;
        else if (rr_req[15] == 1'b1)
            pq_result_unmask = 16'b1000_0000_0000_0000;    
        else 
            pq_result_unmask = 16'b0000_0000_0000_0000;
    end

//-----------------------------------------
// 覆盖掩码后的请求的PQ调度
//-----------------------------------------
always @(*)
    begin
        if (rr_req_mask[0] == 1'b1)
            pq_result_mask = 16'b0000_0000_0000_0001;
        else if (rr_req_mask[1] == 1'b1)
            pq_result_mask = 16'b0000_0000_0000_0010;
        else if (rr_req_mask[2] == 1'b1)
            pq_result_mask = 16'b0000_0000_0000_0100;
        else if (rr_req_mask[3] == 1'b1)
            pq_result_mask = 16'b0000_0000_0000_1000;  
        else if (rr_req_mask[4] == 1'b1)
            pq_result_mask = 16'b0000_0000_0001_0000;
        else if (rr_req_mask[5] == 1'b1)
            pq_result_mask = 16'b0000_0000_0010_0000;
        else if (rr_req_mask[6] == 1'b1)
            pq_result_mask = 16'b0000_0000_0100_0000;
        else if (rr_req_mask[7] == 1'b1)
            pq_result_mask = 16'b0000_0000_1000_0000;
        else if (rr_req_mask[8] == 1'b1)
            pq_result_mask = 16'b0000_0001_0000_0000;
        else if (rr_req_mask[9] == 1'b1)
            pq_result_mask = 16'b0000_0010_0000_0000;
        else if (rr_req_mask[10] == 1'b1)
            pq_result_mask = 16'b0000_0100_0000_0000;
        else if (rr_req_mask[11] == 1'b1)
            pq_result_mask = 16'b0000_1000_0000_0000;
        else if (rr_req_mask[12] == 1'b1)
            pq_result_mask = 16'b0001_0000_0000_0000;
        else if (rr_req_mask[13] == 1'b1)
            pq_result_mask = 16'b0010_0000_0000_0000;
        else if (rr_req_mask[14] == 1'b1)
            pq_result_mask = 16'b0100_0000_0000_0000;
        else if (rr_req_mask[15] == 1'b1)
            pq_result_mask = 16'b1000_0000_0000_0000;
        else
            pq_result_mask = 16'b0000_0000_0000_0000;
    end

//----------------------------------------------------------------------------------------------
// 生成最后的RR结果
//*******************
// 掩码后请求不全0就以掩码后请求的PQ结果为最终的RR结果，否则以初始请求的PQ调度结果为最终的RR结果
//----------------------------------------------------------------------------------------------

/* 判断掩码后的新请求是否为全0 */
assign  req_mask_zero  =  ~|rr_req_mask;

/* 取最终的RR结果 */
always @(posedge sys_clk or posedge sys_rst)
    begin
        if (sys_rst == 1'b1)
            rr_result <= 16'b0;
        else if (rr_ena == 1'b1)
            begin
                if (req_mask_zero == 1'b1)
                    rr_result <= pq_result_unmask;
                else
                    rr_result <= pq_result_mask;
            end
    end

//-----------------------------------------
// 储存RR的结果
//-----------------------------------------
always @(posedge sys_clk or posedge sys_rst)
    begin
        if (sys_rst == 1'b1)
            last_result <= 16'b0;
        else if (rr_ena == 1'b1)
            begin
                if (req_mask_zero == 1'b1)
                    last_result <= pq_result_unmask;
                else
                    last_result <= pq_result_mask;
            end
    end

endmodule

