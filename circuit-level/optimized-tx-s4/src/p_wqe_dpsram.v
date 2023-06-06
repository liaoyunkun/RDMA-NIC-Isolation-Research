/***********************************************Copyright@2019*****************************************************

                                        YUSUR CO. LTD. All rights reserved
                                http://www.yusur.tech, http://www.carch.ac.cn/~adapt

=========================================FILE INFO.===================================================
File Name      : task_mem_dpsram.v
Last Update    : 2022.5.24
Latest version : v1.00
Descriptions   : 
=========================================AUTHOR INFO.===============================================
Created by     : Yunkun Liao
Create date    : 2022.5.24
Version        : v1.00
Descriptions   : 
========================================UPDATE HISTORY=============================================
Modified by    : 
Modified date  : 
Version        : 
Descriptions   : 
--------------------------------------------------------------------------------------------------
Modified by    : 
Modified date  : 
Version        : 
Descriptions   : 
--------------------------------------------------------------------------------------------------
(Add more modification logs, separated with '----')

*****************************************Confidential. Do NOT disclose*********************************************/
`timescale 1ns / 1ps
// `include "../../common/yusur_memory/mem_conf_define.v"
module p_wqe_dpsram #(
    parameter IS_ARRAY_RAM        = 0          ,
    parameter RAM_STYLE_MODE      = "block"    , //"distributed", "registers","block"���Ժ�ȡ��
    parameter WIDTH_ADDR          = 8          ,
    parameter WIDTH_DATA          = 8          ,
    parameter DEVICE_RAM_TYPE     = "AUTO"     , //For Xilinx: "auto", "distributed", "block" or "ultra";
                                                 //For Altera: "M9K",
    parameter READ_DURING_WRITE_A = "new"      , //new old, but no xxx in altera 1rw1rw ram
    parameter READ_DURING_WRITE_B = "new"      , //new old, but no xxx in altera 1rw1rw ram
    parameter DOUT_REG_A          = "false"    , //register output a
    parameter DOUT_REG_B          = "false"      //register output b
)
(
    input       [WIDTH_ADDR-1:0]    addra      ,
    input       [WIDTH_DATA-1:0]    dina       ,
    input                           wena       ,
    input                           rena       ,
    input                           clka       ,
    output      [WIDTH_DATA-1:0]    douta      ,

    input       [WIDTH_ADDR-1:0]    addrb      ,
    input       [WIDTH_DATA-1:0]    dinb       ,
    input                           wenb       ,
    input                           renb       ,
    input                           clkb       ,
    output      [WIDTH_DATA-1:0]    doutb
) ;


    mem_1rw1rw #(      
        .IS_ARRAY_RAM          (IS_ARRAY_RAM         ),
        .RAM_STYLE_MODE        (RAM_STYLE_MODE       ), 
        .WIDTH_ADDR            (WIDTH_ADDR           ),
        .WIDTH_DATA            (WIDTH_DATA           ),
        .DEVICE_RAM_TYPE       (DEVICE_RAM_TYPE      ), 
        .READ_DURING_WRITE_A   (READ_DURING_WRITE_A  ), 
        .READ_DURING_WRITE_B   (READ_DURING_WRITE_B  ), 
        .DOUT_REG_A            (DOUT_REG_A           ), 
        .DOUT_REG_B            (DOUT_REG_B           )
    ) mem_1rw1rw_inst (                 
        .addra                 (addra                ),
        .dina                  (dina                 ),
        .wena                  (wena                 ),
        .rena                  (rena                 ),
        .clka                  (clka                 ),
        .douta                 (douta                ),
                                 
        .addrb                 (addrb                ),
        .dinb                  (dinb                 ),
        .wenb                  (wenb                 ),
        .renb                  (renb                 ),
        .clkb                  (clkb                 ),
        .doutb                 (doutb                )
    );

endmodule