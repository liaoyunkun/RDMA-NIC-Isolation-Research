`default_nettype none 
`timescale 1ns/1ps

import axi_vip_pkg::*;
import design_1_axi_vip_0_0_pkg::*;
import design_1_axi_vip_1_0_pkg::*;
 
module design_1_wrapper_tb;

localparam WQE_WIDTH            = 512                       ;
localparam WQE_WIDTH_BYTE       = WQE_WIDTH / 8             ;
localparam SQ_DEPTH             = 128                       ;
localparam SQ_SIZE_BYTE         = SQ_DEPTH * WQE_WIDTH_BYTE ;
localparam SQ_PTR_WIDTH         = $clog2(SQ_DEPTH)          ;

localparam WQE_RDMA_WRITE       = 8'h00                     ;
localparam WQE_RDMA_WRITE_IMM   = 8'h01                     ;
localparam WQE_RDMA_READ        = 8'h02                     ;
localparam WQE_RDMA_SEND        = 8'h03                     ;
localparam WQE_RDMA_SEND_IMM    = 8'h04                     ;
localparam WQE_RDMA_SEND_INV    = 8'h05                     ;

localparam SQ_BASE_ADDR         = 32'h0                     ;

localparam LS_64B               = 32'd64                    ;
localparam BS_4KB               = 32'd4096                  ;
localparam BS_8KB               = BS_4KB * 2                ;
localparam BS_16KB              = BS_8KB * 2                ;
localparam BS_32KB              = BS_16KB * 2               ;
localparam BS_64KB              = BS_32KB * 2               ;
localparam BS_128KB             = BS_64KB * 2               ;
localparam BS_256KB             = BS_128KB * 2              ;
localparam BS_512KB             = BS_256KB * 2              ;
localparam BS_1MB               = BS_512KB * 2              ;

// sq-1 is bandwidth-sensitive, sq-2 is bandwidth-sensitive
localparam BS_BS_MODE           = 1                          ;
localparam BS_BS_ALONE          = 1                          ;
localparam BS_BS_DURATION       = 10000000                   ;
localparam BS_BS_PMTU           = 32'd1024                   ;

localparam PKT_DESC_QPN_V4_LSB  = 796                        ;
localparam PKT_DESC_QPN_V4_MSB  = 819                        ;
localparam WQE_WRID_LSB         = 0                          ;
localparam WQE_WRID_MSB         = 63                         ;
localparam WQE_QPID_LSB         = 328                        ;
localparam WQE_QPID_MSB         = WQE_QPID_LSB+3             ;
reg            clk_0 = '0;
reg [15:0]     i_active_0 = '0;
reg            i_pkt_desc_ready_0 = 1'b1; 
wire [127:0]   i_qpc_dest_ip_0;
wire [47:0]    i_qpc_dest_mac_0;
wire [23:0]    i_qpc_dest_qpid_0;
wire [5:0]     i_qpc_dscp_0;
wire           i_qpc_hdr_lookup_ready_0;
wire [15:0]    i_qpc_pkey_0;
wire [2:0]     i_qpc_pmtu_0;
wire [23:0]    i_qpc_sq_curr_msn_0;
wire [23:0]    i_qpc_sq_curr_psn_0;
wire [7:0]     i_qpc_ttl_0;
wire           i_qpc_valid_0;
reg [127:0]    i_rnic_src_ip_0 = {128{1'b1}};  
reg [47:0]     i_rnic_src_mac_0 = {48{1'b1}};
reg [15:0]     i_rnic_src_port_0 = {16{1'b1}};
reg [31:0]     i_sq_base_0 = SQ_BASE_ADDR;
wire [1023:0]  o_pkt_desc_0;
wire [7:0]     o_pkt_desc_hdr_len_0;
wire           o_pkt_desc_valid_0;
wire [3:0]     o_qpc_hdr_lookup_qp_id_0;
wire           o_qpc_hdr_lookup_valid_0;
wire [3:0]     o_qpc_hdr_update_qpid_0;
wire           o_qpc_hdr_update_valid_0;
wire [23:0]    o_qpc_sq_curr_msn_0;
wire [23:0]    o_qpc_sq_curr_psn_0;
reg            rst_n_0 = '0;
wire           o_final_0;
wire [3:0]     o_qpn_0;
wire [63:0]    o_wr_id_0;

wire           o_wqe_cache_wr_val_0;
wire [3:0]     o_wqe_cache_wr_qpn_0;
wire [63:0]    o_wqe_cache_wr_wrid_0; 
wire           o_ibt_wqe_val_0;
wire [511:0]   o_ibt_wqe_0;
wire [63:0]    o_ibt_wqe_0_wrid;
wire [3:0]     o_ibt_wqe_0_qpid;

assign o_ibt_wqe_0_wrid = o_ibt_wqe_0[WQE_WRID_MSB:WQE_WRID_LSB];
assign o_ibt_wqe_0_qpid = o_ibt_wqe_0[WQE_QPID_MSB:WQE_QPID_LSB];

// ID value for WRITE/READ_BURST transaction
xil_axi_uint                            mtestID = 'h0;
// ADDR value for WRITE/READ_BURST transaction
xil_axi_ulong                           mtestADDR;
// Burst Length value for WRITE/READ_BURST transaction
xil_axi_len_t                           mtestBurstLength = 'h0;
// SIZE value for WRITE/READ_BURST transaction
xil_axi_size_t                          mtestDataSize = xil_axi_size_t'(xil_clog2(512/8));
// Burst Type value for WRITE/READ_BURST transaction
xil_axi_burst_t                         mtestBurstType = XIL_AXI_BURST_TYPE_INCR; 
// LOCK value for WRITE/READ_BURST transaction
xil_axi_lock_t                          mtestLOCK = XIL_AXI_ALOCK_NOLOCK;
// Cache Type value for WRITE/READ_BURST transaction
xil_axi_cache_t                         mtestCacheType = 3;
// Protection Type value for WRITE/READ_BURST transaction
xil_axi_prot_t                          mtestProtectionType = 3'b000;
// Region value for WRITE/READ_BURST transaction
xil_axi_region_t                        mtestRegion = 4'b000;
// QOS value for WRITE/READ_BURST transaction
xil_axi_qos_t                           mtestQOS = 4'b000;
// Awuser value for WRITE/READ_BURST transaction
xil_axi_data_beat                       mtestAWUSER = 'h0;
xil_axi_data_beat                       mtestARUSER = 'h0;
xil_axi_uint                            mtestRUSER;
xil_axi_resp_t                          mtestBresp;

bit [511:0]                             mtestWData;

design_1_axi_vip_0_0_slv_mem_t sq_slave_agent;
design_1_axi_vip_1_0_mst_t sq_cfg_master_agent;

bit [31:0]                             sq_0_finish_cnt;
bit [31:0]                             sq_1_finish_cnt;
real sq_0_start_time [0:SQ_DEPTH-1];
bit [31:0] sq_0_start_cnt;
real sq_0_finish_time [0:SQ_DEPTH-1];
real sq_1_start_time [0:SQ_DEPTH-1];
bit [31:0] sq_1_start_cnt;
real sq_1_finish_time [0:SQ_DEPTH-1];
real sq_0_lat [0:SQ_DEPTH-1];
real sq_1_lat [0:SQ_DEPTH-1];
real sq_0_wait_lat [0:SQ_DEPTH-1];
real sq_0_proc_lat [0:SQ_DEPTH-1];
real sq_1_wait_lat [0:SQ_DEPTH-1];
real sq_1_proc_lat [0:SQ_DEPTH-1];
int lat_fd_0;
int wait_fd_0;
int proc_fd_0;
int lat_fd_1;
int wait_fd_1;
int proc_fd_1;

real sq_0_ibt_enter_time [0:SQ_DEPTH-1];
bit [31:0] sq_0_ibt_enter_cnt;
real sq_1_ibt_enter_time [0:SQ_DEPTH-1];
bit [31:0] sq_1_ibt_enter_cnt;


bit [31:0] sq_0_pkt_desc_cnt;
bit [31:0] sq_1_pkt_desc_cnt;
real bs_bs_start_time;
real bs_bs_finish_time;


// clock generation
always #5 clk_0 = ~clk_0;

initial 
    begin
        #10000 rst_n_0 = 1'b1;
        sq_slave_agent = new("sq slave vip agent",
                                design_1_wrapper_tb.dut.design_1_i.axi_vip_0.inst.IF);
        sq_slave_agent.start_slave();

        sq_cfg_master_agent = new("kv config master vip agent", 
                                design_1_wrapper_tb.dut.design_1_i.axi_vip_1.inst.IF);
        sq_cfg_master_agent.start_master();

        // configure SQ-1 (2'b01)
        for (int i = 0; i < SQ_DEPTH; i = i + 1) 
            begin
                mtestADDR = WQE_WIDTH_BYTE * (i + SQ_DEPTH * 1) + SQ_BASE_ADDR;
                gen_wqe(i, WQE_RDMA_WRITE, BS_4KB, 64'h0, 32'h0, 64'h0, 32'h0, 32'h0);  
                mtestBurstLength = 'h0;
                sq_cfg_master_agent.AXI4_WRITE_BURST(
                    mtestID,
                    mtestADDR,
                    mtestBurstLength,
                    mtestDataSize,
                    mtestBurstType,
                    mtestLOCK,
                    mtestCacheType,
                    mtestProtectionType,
                    mtestRegion,
                    mtestQOS,
                    mtestAWUSER,
                    mtestWData,
                    0,
                    mtestBresp
                ); 
            end
        // configure SQ-2 (2'b11)
        for (int i = 0; i < SQ_DEPTH; i = i + 1)
            begin
                mtestADDR = WQE_WIDTH_BYTE * (i + SQ_DEPTH * 3) + SQ_BASE_ADDR;
                gen_wqe(i, WQE_RDMA_WRITE, BS_1MB, 64'h0, 32'h0, 64'h0, 32'h0, 32'h0);
                mtestBurstLength = 'h0;
                sq_cfg_master_agent.AXI4_WRITE_BURST(
                    mtestID,
                    mtestADDR,
                    mtestBurstLength,
                    mtestDataSize,
                    mtestBurstType,
                    mtestLOCK,
                    mtestCacheType,
                    mtestProtectionType,
                    mtestRegion,
                    mtestQOS,
                    mtestAWUSER,
                    mtestWData,
                    0,
                    mtestBresp
                );
            end
        // assert i_active_0
        @(posedge clk_0)
            begin
                if(BS_BS_ALONE)
                    begin
                        i_active_0 <= 16'b0010;
                    end
                else 
                    begin
                        i_active_0 <= 16'b1010;
                    end
            end
        bs_bs_start_time = $realtime();
        wait(bs_bs_finish_time - bs_bs_start_time >= BS_BS_DURATION);
        // wait(sq_0_finish_cnt == SQ_DEPTH && sq_1_finish_cnt == SQ_DEPTH);
        $display("SQ-1 generated %d Packet Descriptors\n", sq_0_pkt_desc_cnt);
        $display("SQ-2 generated %d Packet Descriptors\n", sq_1_pkt_desc_cnt);
        #1000;
        $finish;
    end

// always @(posedge clk_0)
//     begin
//         if(o_final_0 && o_qpn_0 == 4'h3)
//             begin
//                 // $display("@ %0t : o_qpn_0 is %0h", $time, o_qpn_0);
//                 $display("@ %0t : qpid is %0h, o_wr_id_0 is %0h", $time, o_qpn_0, o_wr_id_0);
//             end
//     end
always @(posedge clk_0 or negedge rst_n_0)
    begin
        if(~rst_n_0)
            begin
                sq_0_finish_cnt <= 32'h0;
            end
        else if(o_final_0 && o_qpn_0 == 4'h1 && sq_0_finish_cnt < SQ_DEPTH)
            begin
                sq_0_finish_cnt <= sq_0_finish_cnt + 1'b1;
            end
    end

always @(posedge clk_0 or rst_n_0)
    begin
        if(~rst_n_0)
            begin
                sq_1_finish_cnt <= 32'h0;
            end
        else if(o_final_0 && o_qpn_0 == 4'h3 && sq_1_finish_cnt < SQ_DEPTH)
            begin
                sq_1_finish_cnt <= sq_1_finish_cnt + 1'b1;
            end
    end

// locate start time for each wqe
// SQ-0
always @(posedge clk_0 or negedge rst_n_0)
    begin
        if(~rst_n_0)
            begin
                sq_0_start_cnt <= 32'h0;
            end
        else if(o_wqe_cache_wr_val_0 && o_wqe_cache_wr_qpn_0 == 4'h1 && sq_0_start_cnt < SQ_DEPTH)
            begin
                sq_0_start_cnt <= sq_0_start_cnt + 1'b1;
            end
    end
always @(posedge clk_0 or negedge rst_n_0)
    begin
        if(o_wqe_cache_wr_val_0 && o_wqe_cache_wr_qpn_0 == 4'h1 && sq_0_start_cnt < SQ_DEPTH)
            begin
                sq_0_start_time[o_wqe_cache_wr_wrid_0] <= $realtime;
            end
    end
// SQ-1
always @(posedge clk_0 or negedge rst_n_0)
    begin
        if(~rst_n_0)
            begin
                sq_1_start_cnt <= 32'h0;
            end    
        else if(o_wqe_cache_wr_val_0 && o_wqe_cache_wr_qpn_0 == 4'h3 && sq_1_start_cnt < SQ_DEPTH)
            begin
                sq_1_start_cnt <= sq_1_start_cnt + 1'b1;
            end
    end

always @(posedge clk_0 or negedge rst_n_0)
    begin
        if(o_wqe_cache_wr_val_0 && o_wqe_cache_wr_qpn_0 == 4'h3 && sq_1_start_cnt < SQ_DEPTH)
            begin
                sq_1_start_time[o_wqe_cache_wr_wrid_0] <= $realtime;
            end
    end
// local ib_transport enter time for each wqe
always @(posedge clk_0 or negedge rst_n_0)
    begin
        if(~rst_n_0)
            begin
                sq_0_ibt_enter_cnt <= 0;
            end
        else if(o_ibt_wqe_val_0 && o_ibt_wqe_0_qpid == 4'h1 && sq_0_ibt_enter_cnt <= SQ_DEPTH)
            begin
                sq_0_ibt_enter_cnt <= sq_0_ibt_enter_cnt + 1'b1;
            end
    end

always @(posedge clk_0 or negedge rst_n_0)
    begin
        if(o_ibt_wqe_val_0 && o_ibt_wqe_0_qpid == 4'h1 && sq_0_ibt_enter_cnt < SQ_DEPTH)
            begin
                sq_0_ibt_enter_time[o_ibt_wqe_0_wrid] <= $realtime;
            end
    end

always @(posedge clk_0 or negedge rst_n_0)
    begin
        if(~rst_n_0)
            begin
                sq_1_ibt_enter_cnt <= 0;
            end
        else if(o_ibt_wqe_val_0 && o_ibt_wqe_0_qpid == 4'h3 && sq_1_ibt_enter_cnt < SQ_DEPTH)
            begin
                sq_1_ibt_enter_cnt <= sq_1_ibt_enter_cnt + 1'b1;
            end
    end

always @(posedge clk_0 or negedge rst_n_0)
    begin
        if(o_ibt_wqe_val_0 && o_ibt_wqe_0_qpid == 4'h3 && sq_1_ibt_enter_cnt < SQ_DEPTH)
            begin
                sq_1_ibt_enter_time[o_ibt_wqe_0_wrid] <= $realtime;
            end
    end
// locate finish time for each wqe
// SQ-0
always @(posedge clk_0 or negedge rst_n_0)
    begin
        if(o_final_0 && o_qpn_0 == 4'h1 && sq_0_finish_cnt < SQ_DEPTH)
            begin
                sq_0_finish_time[o_wr_id_0] <= $realtime;
            end
    end
// SQ-1
always @(posedge clk_0 or negedge rst_n_0)
    begin
        if(o_final_0 && o_qpn_0 == 4'h3 && sq_1_finish_cnt < SQ_DEPTH)
            begin
                sq_1_finish_time[o_wr_id_0] <= $realtime;
            end
    end

always @(posedge clk_0 or negedge rst_n_0)
    begin
        if(~rst_n_0)
            begin
                sq_0_pkt_desc_cnt <= 32'h0;
                sq_1_pkt_desc_cnt <= 32'h0;
            end
        else if(o_pkt_desc_valid_0 && 
                o_pkt_desc_0[PKT_DESC_QPN_V4_MSB:PKT_DESC_QPN_V4_LSB] == 4'h1)
            begin
                sq_0_pkt_desc_cnt <= sq_0_pkt_desc_cnt + 1'b1;
            end
        else if(o_pkt_desc_valid_0 &&
                o_pkt_desc_0[PKT_DESC_QPN_V4_MSB:PKT_DESC_QPN_V4_LSB] == 4'h3)
            begin
                sq_1_pkt_desc_cnt <= sq_1_pkt_desc_cnt + 1'b1;
            end
    end

// sample time in each cycle for bs-bs micro benchmark
always @(posedge clk_0)
    begin
        bs_bs_finish_time = $realtime;
    end

design_1_wrapper dut (
    .clk_0                    (clk_0     ),
    .i_active_0               (i_active_0),
    .i_pkt_desc_ready_0       (i_pkt_desc_ready_0),
    .i_qpc_dest_ip_0          (i_qpc_dest_ip_0),
    .i_qpc_dest_mac_0         (i_qpc_dest_mac_0),
    .i_qpc_dest_qpid_0        (i_qpc_dest_qpid_0),
    .i_qpc_dscp_0             (i_qpc_dscp_0),
    .i_qpc_hdr_lookup_ready_0 (i_qpc_hdr_lookup_ready_0),
    .i_qpc_pkey_0             (i_qpc_pkey_0),
    .i_qpc_pmtu_0             (i_qpc_pmtu_0),
    .i_qpc_sq_curr_msn_0      (i_qpc_sq_curr_msn_0),
    .i_qpc_sq_curr_psn_0      (i_qpc_sq_curr_psn_0),
    .i_qpc_ttl_0              (i_qpc_ttl_0),
    .i_qpc_valid_0            (i_qpc_valid_0),
    .i_rnic_src_ip_0          (i_rnic_src_ip_0),
    .i_rnic_src_mac_0         (i_rnic_src_mac_0),
    .i_rnic_src_port_0        (i_rnic_src_port_0),
    .i_sq_base_0              (i_sq_base_0),
    .o_pkt_desc_0             (o_pkt_desc_0),
    .o_pkt_desc_hdr_len_0     (o_pkt_desc_hdr_len_0),
    .o_pkt_desc_valid_0       (o_pkt_desc_valid_0),
    .o_qpc_hdr_lookup_qp_id_0 (o_qpc_hdr_lookup_qp_id_0),
    .o_qpc_hdr_lookup_valid_0 (o_qpc_hdr_lookup_valid_0),
    .o_qpc_hdr_update_qpid_0  (o_qpc_hdr_update_qpid_0),
    .o_qpc_hdr_update_valid_0 (o_qpc_hdr_update_valid_0),
    .o_qpc_sq_curr_msn_0      (o_qpc_sq_curr_msn_0),
    .o_qpc_sq_curr_psn_0      (o_qpc_sq_curr_psn_0),
    .rst_n_0                  (rst_n_0),
    .o_final_0                (o_final_0),
    .o_qpn_0                  (o_qpn_0),
    .o_wr_id_0                (o_wr_id_0),
    .o_wqe_cache_wr_val_0     (o_wqe_cache_wr_val_0),
    .o_wqe_cache_wr_qpn_0     (o_wqe_cache_wr_qpn_0),
    .o_wqe_cache_wr_wrid_0    (o_wqe_cache_wr_wrid_0),
    .o_ibt_wqe_val_0          (o_ibt_wqe_val_0),
    .o_ibt_wqe_0              (o_ibt_wqe_0)
    );

qpc_agent#(
        .MAX_QP                  ( 16                        )
    )u_qpc_agent(
        .clk                     ( clk_0                     ),
        .rst_n                   ( rst_n_0                   ),
        .i_qpc_hdr_lookup_valid  ( o_qpc_hdr_lookup_valid_0  ),
        .o_qpc_hdr_lookup_ready  ( i_qpc_hdr_lookup_ready_0  ),
        .i_qpc_hdr_lookup_qp_id  ( o_qpc_hdr_lookup_qp_id_0  ),
        .o_qpc_valid             ( i_qpc_valid_0             ),
        .o_qpc_pkey              ( i_qpc_pkey_0              ),
        .o_qpc_pmtu              ( i_qpc_pmtu_0              ),
        .o_qpc_dest_qpid         ( i_qpc_dest_qpid_0         ),
        .o_qpc_sq_curr_psn       ( i_qpc_sq_curr_psn_0       ),
        .o_qpc_sq_curr_msn       ( i_qpc_sq_curr_msn_0       ),
        .o_qpc_dest_ip           ( i_qpc_dest_ip_0           ),
        .o_qpc_ttl               ( i_qpc_ttl_0               ),
        .o_qpc_dscp              ( i_qpc_dscp_0              ),
        .o_qpc_dest_mac          ( i_qpc_dest_mac_0          ),
        .i_qpc_hdr_update_valid  ( o_qpc_hdr_update_valid_0  ),
        .i_qpc_hdr_update_qpid   ( o_qpc_hdr_update_qpid_0   ),
        .i_qpc_sq_curr_psn       ( o_qpc_sq_curr_psn_0       ),
        .i_qpc_sq_curr_msn       ( o_qpc_sq_curr_msn_0       )
    );


task gen_wqe();
    input [63:0] wr_id;
    input [7:0] opcode;
    input [31:0] length;
    input [63:0] local_addr;
    input [31:0] local_key;
    input [63:0] remote_addr;
    input [31:0] remote_key;
    input [31:0] imm_inv;
    // output [WQE_WIDTH-1:0] wqe;
    begin
        mtestWData[63:0] = wr_id;
        mtestWData[71:64] = opcode;
        mtestWData[103:72] = length;
        mtestWData[167:104] = local_addr;
        mtestWData[199:168] = local_key;
        mtestWData[263:200] = remote_addr;
        mtestWData[295:264] = remote_key;
        mtestWData[327:296] = imm_inv;
        mtestWData[WQE_WIDTH-1:328] = '0;   
    end
endtask //

task cal_lat;
    for (int i = 0; i < SQ_DEPTH; i = i + 1) 
        begin
            sq_0_lat[i] = sq_0_finish_time[i] - sq_0_start_time[i];
            sq_0_wait_lat[i] = sq_0_ibt_enter_time[i] - sq_0_start_time[i];
            sq_0_proc_lat[i] = sq_0_finish_time[i] - sq_0_ibt_enter_time[i];
            sq_1_lat[i] = sq_1_finish_time[i] - sq_1_start_time[i];
            sq_1_wait_lat[i] = sq_1_ibt_enter_time[i] - sq_1_start_time[i];
            sq_1_proc_lat[i] = sq_1_finish_time[i] - sq_1_ibt_enter_time[i];
        end 
endtask

task wr_lat;
    lat_fd_0 = $fopen("./lat_0.txt", "w");
    wait_fd_0 = $fopen("./lat_wait_0.txt", "w");
    proc_fd_0 = $fopen("./lat_proc_0.txt", "w");
    lat_fd_1 = $fopen("./lat_1.txt", "w");
    wait_fd_1 = $fopen("./lat_wait_1.txt", "w");
    proc_fd_1 = $fopen("./lat_proc_1.txt", "w");
    for (int i = 0; i < SQ_DEPTH; i = i + 1) 
        begin
            $fwrite(lat_fd_0, "%f\n", sq_0_lat[i]);
            $fwrite(wait_fd_0, "%f\n", sq_0_wait_lat[i]);
            $fwrite(proc_fd_0, "%f\n", sq_0_proc_lat[i]);
            $fwrite(lat_fd_1, "%f\n", sq_1_lat[i]);
            $fwrite(wait_fd_1, "%f\n", sq_1_wait_lat[i]);
            $fwrite(proc_fd_1, "%f\n", sq_1_proc_lat[i]);
        end
endtask

endmodule