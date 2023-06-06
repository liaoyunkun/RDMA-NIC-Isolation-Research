`default_nettype none 
`timescale 1ns/1ps

module ib_transport #(
    parameter WQE_WIDTH              = 512           ,
    parameter ETH_MAC_WIDTH          = 48            ,
    parameter IPV6_WIDTH             = 128           ,
    parameter UDP_PORT_WIDTH         = 16            ,
    parameter QP_PTR_WIDTH           = 5             ,
    parameter IB_PKEY_WIDTH          = 16            ,
    parameter IB_PMTU_CODE_WIDTH     = 3             ,
    parameter IB_QP_WIDTH            = 24            ,
    parameter IP_TTL_WIDTH           = 8             ,
    parameter IP_DSCP_WDITH          = 6             ,
    parameter IB_PSN_WIDTH           = 24            ,
    parameter IB_MSN_WIDTH           = 24            ,
    parameter PKT_DESC_WIDTH         = 1024          ,
    parameter PKT_DESC_HDR_LEN_WIDTH = 8             ,
    parameter PWQE_BUF_ADDR_WIDTH    = 2             
)(
    input  wire                               clk                        ,
    input  wire                               rst_n                      ,
    // if* with grp_scheduler
    input  wire                               i_wqe_cache_empty          ,
    output reg                                o_wqe_cache_rd             ,
    input  wire                               i_wqe_val                  ,
    input  wire                               i_wqe_type                 ,
    input  wire  [PWQE_BUF_ADDR_WIDTH-1:0]    i_wqe_addr                 ,
    input  wire  [WQE_WIDTH-1:0]              i_wqe                      ,
    output reg                                o_pwqe_wb                  ,
    output reg   [PWQE_BUF_ADDR_WIDTH-1:0]    o_pwqe_addr                ,
    output reg   [WQE_WIDTH-1:0]              o_pwqe                     ,
    // if* with slot_status
    output reg                                o_reset_req                ,
    output reg   [PWQE_BUF_ADDR_WIDTH-1:0]    o_reset_addr               ,
    // function-rnic context, fixed value after initialization
    input  wire  [ETH_MAC_WIDTH-1:0]          i_rnic_src_mac             ,
    input  wire  [IPV6_WIDTH-1:0]             i_rnic_src_ip              ,
    input  wire  [UDP_PORT_WIDTH-1:0]         i_rnic_src_port            ,
    // qp context lookup
    output reg                                o_qpc_hdr_lookup_valid     ,
    input  wire                               i_qpc_hdr_lookup_ready     ,
    output reg   [QP_PTR_WIDTH-1:0]           o_qpc_hdr_lookup_qp_id     ,
    input  wire                               i_qpc_valid                ,
    input  wire  [IB_PKEY_WIDTH-1:0]          i_qpc_pkey                 ,
    input  wire  [IB_PMTU_CODE_WIDTH-1:0]     i_qpc_pmtu                 ,
    input  wire  [IB_QP_WIDTH-1:0]            i_qpc_dest_qpid            ,
    input  wire  [IB_PSN_WIDTH-1:0]           i_qpc_sq_curr_psn          ,
    input  wire  [IB_MSN_WIDTH-1:0]           i_qpc_sq_curr_msn          ,
    input  wire  [IPV6_WIDTH-1:0]             i_qpc_dest_ip              ,
    input  wire  [IP_TTL_WIDTH-1:0]           i_qpc_ttl                  ,
    input  wire  [IP_DSCP_WDITH-1:0]          i_qpc_dscp                 , // traffic class
    input  wire  [ETH_MAC_WIDTH-1:0]          i_qpc_dest_mac             ,
    // qp context update 
    output reg                                o_qpc_hdr_update_valid     ,
    output reg   [QP_PTR_WIDTH-1:0]           o_qpc_hdr_update_qpid      ,
    output reg   [IB_PSN_WIDTH-1:0]           o_qpc_sq_curr_psn          ,
    output reg   [IB_MSN_WIDTH-1:0]           o_qpc_sq_curr_msn          ,
    // if* with pkt_desc_if            
    output reg                                o_pkt_desc_valid           ,
    input  wire                               i_pkt_desc_ready           ,
    output reg [PKT_DESC_HDR_LEN_WIDTH-1:0]   o_pkt_desc_hdr_len         ,
    output reg [PKT_DESC_WIDTH-1:0]           o_pkt_desc                 ,
    output reg                                o_final                    ,
    output reg [QP_PTR_WIDTH-1:0]             o_qpn                      ,
    output reg [63:0]                         o_wr_id              
);

// P-WQE Format 
/*
* Pos       |   Name      |    Desc
* [63:0]    | WR_ID       |  
* [71:64]   | OPCODE      |
*                            8'h00 RDMA_WRITE
*                            8'h01 RDMA_WRITE_IMM
*                            8'h02 RDMA_READ
*                            8'h03 RDMA_SEND
*                            8'h04 RDMA_SEND_IMM
*                            8'h05 RDMA_SEND_INV
* [103:72]  | LENGTH      | （remaining length）
* [167:104] | LOCAL_ADDR  |
* [199:168] | LOCAL_KEY   |
* [263:200] | REMOTE_ADDR |
* [295:264] | REMOTE_KEY  | 
* [327:296] | IMM or INV  |
* 328       First: 
*             0: first
*             1: not first
* [511:329] | RESERVED    |
*/
localparam WQE_WRID_LSB                   = 0                    ;
localparam WQE_WRID_MSB                   = 63                   ;
localparam WQE_OPCODE_LSB                 = 64                   ;
localparam WQE_OPCODE_MSB                 = 71                   ;
localparam WQE_LENGTH_LSB                 = 72                   ;
localparam WQE_LENGTH_MSB                 = 103                  ;
localparam WQE_LADDR_LSB                  = 104                  ;
localparam WQE_LADDR_MSB                  = 167                  ;
localparam WQE_LKEY_LSB                   = 168                  ;
localparam WQE_LKEY_MSB                   = 199                  ;
localparam WQE_RADDR_LSB                  = 200                  ;
localparam WQE_RADDR_MSB                  = 263                  ;
localparam WQE_RKEY_LSB                   = 264                  ;
localparam WQE_RKEY_MSB                   = 295                  ;
localparam WQE_IMM_INV_LSB                = 296                  ;
localparam WQE_IMM_INV_MSB                = 327                  ;
localparam WQE_QPID_LSB                   = 328                  ;
localparam WQE_QPID_MSB                   = WQE_QPID_LSB+QP_PTR_WIDTH-1;
localparam WQE_FIRST                      = WQE_QPID_MSB + 1     ;

localparam WQE_RDMA_WRITE                 = 8'h00                ;
localparam WQE_RDMA_WRITE_IMM             = 8'h01                ;
localparam WQE_RDMA_READ                  = 8'h02                ;
localparam WQE_RDMA_SEND                  = 8'h03                ;
localparam WQE_RDMA_SEND_IMM              = 8'h04                ;
localparam WQE_RDMA_SEND_INV              = 8'h05                ;

// Pakcet Descriptor Format
localparam PKT_DESC_ETH_LSB               = 0                    ;
localparam PKT_DESC_ETH_MSB               = 111                  ;
localparam PKT_DESC_IP_V4_LSB             = 112                  ;
localparam PKT_DESC_IP_V4_MSB             = 271                  ;
localparam PKT_DESC_UDP_V4_LSB            = 272                  ;
localparam PKT_DESC_UDP_V4_MSB            = 335                  ;
localparam PKT_DESC_BTH_V4_LSB            = 336                  ;
localparam PKT_DESC_BTH_V4_MSB            = 431                  ;
localparam PKT_DESC_AETH_V4_LSB           = 432                  ;
localparam PKT_DESC_AETH_V4_MSB           = 463                  ;
localparam PKT_DESC_IETH_IMM_V4_LSB       = 432                  ;
localparam PKT_DESC_IETH_IMM_V4_MSB       = 463                  ;
localparam PKT_DESC_RETH_V4_LSB           = 432                  ;
localparam PKT_DESC_RETH_V4_MSB           = 559                  ; 
localparam PKT_DESC_WR_IMM_V4_LSB         = 560                  ;
localparam PKT_DESC_WR_IMM_V4_MSB         = 591                  ;
localparam PKT_DESC_DMA_ADDR_0_V4_LSB     = 720                  ;
localparam PKT_DESC_DMA_ADDR_0_V4_MSB     = 783                  ;
localparam PKT_DESC_DMA_LEN_0_V4_LSB      = 784                  ;
localparam PKT_DESC_DMA_LEN_0_V4_MSB      = 795                  ;
localparam PKT_DESC_QPN_V4_LSB            = 796                  ;
localparam PKT_DESC_QPN_V4_MSB            = PKT_DESC_QPN_V4_LSB + QP_PTR_WIDTH - 1;
localparam PKT_DESC_INLINE_V4             = PKT_DESC_QPN_V4_MSB + 1;
localparam PKT_DESC_INLINE_LEN_V4_LSB     = PKT_DESC_INLINE_V4 + 1;
localparam PKT_DESC_INLINE_LEN_V4_MSB     = PKT_DESC_INLINE_LEN_V4_LSB + 3;                  
localparam PKT_DESC_RSVD_V4_LSB           = PKT_DESC_INLINE_LEN_V4_MSB + 1;
localparam PKT_DESC_RSVD_V4_MSB           = 1023                 ;
// Infiniband RC BTH Opcode
localparam SEND_FIRST                     = 8'b0000_0000         ;
localparam SEND_MIDDLE                    = 8'b0000_0001         ;
localparam SEND_LAST                      = 8'b0000_0010         ;
localparam SEND_LAST_IMM                  = 8'b0000_0011         ;
localparam SEND_ONLY                      = 8'b0000_0100         ;
localparam SEND_ONLY_IMM                  = 8'b0000_0101         ;
localparam RDMA_WRITE_FIRST               = 8'b0000_0110         ;
localparam RDMA_WRITE_MIDDLE              = 8'b0000_0111         ;
localparam RDMA_WRITE_LAST                = 8'b0000_1000         ;
localparam RDMA_WRITE_LAST_IMM            = 8'b0000_1001         ;
localparam RDMA_WRITE_ONLY                = 8'b0000_1010         ;
localparam RDMA_WRITE_ONLY_IMM            = 8'b0000_1011         ;
localparam RDMA_READ_REQ                  = 8'b0000_1100         ;
localparam RDMA_READ_RSP_FIRST            = 8'b0000_1101         ;
localparam RDMA_READ_RSP_MIDDLE           = 8'b0000_1110         ;
localparam RDMA_READ_RSP_LAST             = 8'b0000_1111         ;
localparam RDMA_READ_RSP_ONLY             = 8'b0001_0000         ;
localparam ACKNOWLEDGE                    = 8'b0001_0001         ;
localparam SEND_LAST_INV                  = 8'b0001_0110         ;
localparam SEND_ONLY_INV                  = 8'b0001_0111         ;

// define FSM states
localparam IDLE         = 6'b000001;
localparam RD_WQE       = 6'b000010;
localparam RD_QPC       = 6'b000100;
localparam GEN_HDR      = 6'b001000;
localparam GEN_PKT_DESC = 6'b010000;
localparam WB_PWQE      = 6'b100000;

reg [5:0] fsm_cs;
reg [5:0] fsm_ns;

reg hdr_valid;  // eth/ip/udp header is valid
reg is_last;    // last iteration
reg [WQE_WIDTH-1:0] wqe_r;  // stroe the wqe
reg wqe_type_r;
reg [PWQE_BUF_ADDR_WIDTH-1:0] wqe_addr_r;
reg [QP_PTR_WIDTH-1:0] qpid;

reg [111:0]                       eth_hdr                      ;
reg [159:0]                       ip_hdr                       ;
reg [63:0]                        udp_hdr                      ;
reg [95:0]                        bth_hdr                      ;
reg [7:0]                         bth_opcode                   ;
reg                               bth_se                       ;
reg                               bth_migration                ;
reg [1:0]                         bth_pad                      ;
reg [3:0]                         bth_tver                     ;
reg [IB_PKEY_WIDTH-1:0]           bth_pkey                     ;
reg [IB_QP_WIDTH-1:0]             bth_destqp                   ;
reg                               bth_ackreq                   ;
reg [IB_PSN_WIDTH-1:0]            bth_psn                      ;
reg [127:0]                       reth_hdr                     ;
reg [31:0]                        immdt_hdr                    ;
reg [31:0]                        ieth_hdr                     ;

reg [2*8-1:0]                     ipv4_identification          ;   
reg [IB_PKEY_WIDTH-1:0]           qpc_pkey_r                   ;
reg [12:0]                        qpc_pmtu_r                   ;
reg [IB_QP_WIDTH-1:0]             qpc_dest_qpid_r              ;
reg [IB_PSN_WIDTH-1:0]            qpc_sq_curr_psn_r            ;
reg [IB_MSN_WIDTH-1:0]            qpc_sq_curr_msn_r            ;
reg [IPV6_WIDTH-1:0]              qpc_dest_ip_r                ;
reg [IP_TTL_WIDTH-1:0]            qpc_ttl_r                    ;
reg [IP_DSCP_WDITH-1:0]           qpc_dscp_r                   ; 
reg [ETH_MAC_WIDTH-1:0]           qpc_dest_mac_r               ;

// remaining length in byte
reg [31:0]                        rem_len                      ;  

reg                               send_task                    ;
reg                               send_inv_task                ;
reg                               send_imm_task                ;
reg                               write_imm_task               ;
reg                               write_task                   ;
reg                               read_req_task                ;
wire                              ack_task                     ;
wire                              read_rsp_task                ;
reg                               only                         ;
reg                               first                        ;
reg                               last                         ;
wire                              reth_present                 ;
reg                               first_iter                   ;
wire                              imm_present                  ;
wire                              inv_present                  ;

reg  [15:0]                       ipv4_len                     ;
wire [15:0]                       udp_len                      ;
// payload length of current packet in bytes, multiple of 4
reg [12:0]                        payload_len                  ;
reg                               payload_len_valid            ;

reg                               chksum_start                 ; 
reg                               chksum_invoke                ;
wire                              chksum_done                  ;
wire [15:0]                       ipv4_chksum                  ;
// BTH.psn of current packet in each iteration
reg [23:0]                        curr_psn                     ;
reg [63:0]                        reth_va                      ;
reg [31:0]                        reth_dmalen                  ;
reg [31:0]                        reth_rkey                    ;
reg [31:0]                        imm_data                     ;
reg [31:0]                        inv_mkey                     ;
reg [63:0]                        local_addr                   ;

reg [IB_PSN_WIDTH-1:0]            psn_wb                       ;
reg [IB_MSN_WIDTH-1:0]            msn_wb                       ;

reg                               wqe_first                    ;
wire [63:0]                       laddr_udt                    ;

// always @(posedge clk)
//     begin
//         if(i_wqe_val && i_wqe_type)
//             begin
//                 $display("@ %0t : WRID is %0h", $time, i_wqe[WQE_WRID_MSB:WQE_WRID_LSB]);
//             end
//     end

always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n)
            begin
                fsm_cs <= IDLE;                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
            end
        else
            begin
                fsm_cs <= fsm_ns;
            end
    end

always @(*)
    begin
        case(fsm_cs)
        IDLE:
            begin
                if(~i_wqe_cache_empty)
                    begin
                        fsm_ns = RD_WQE;
                    end
                else
                    begin
                        fsm_ns = IDLE;
                    end
            end
        RD_WQE:
            begin
                if(i_wqe_val)
                    begin
                        fsm_ns = RD_QPC;
                    end
                else
                    begin
                        fsm_ns = RD_WQE;
                    end
            end
        RD_QPC:
            begin
                if(i_qpc_valid)
                    begin
                        fsm_ns = GEN_HDR;
                    end
                else
                    begin
                        fsm_ns = RD_QPC;
                    end
            end
        GEN_HDR:
            begin
                if(hdr_valid)
                    begin
                        fsm_ns = GEN_PKT_DESC;
                    end
                else
                    begin
                        fsm_ns = GEN_HDR;
                    end
            end
        GEN_PKT_DESC:
            begin
                if(o_pkt_desc_valid & i_pkt_desc_ready & ~is_last & wqe_type_r)
                    begin
                        fsm_ns = WB_PWQE;
                    end
                else if(o_pkt_desc_valid & i_pkt_desc_ready)
                    begin
                        // last iteration
                        fsm_ns = IDLE;
                    end
                else
                    begin
                        fsm_ns = GEN_PKT_DESC;
                    end
            end
        WB_PWQE:
            begin
                if(o_pwqe_wb)
                    begin
                        fsm_ns = IDLE;
                    end
                else
                    begin
                        fsm_ns = WB_PWQE;
                    end
            end
        default:
            fsm_ns = IDLE;
        endcase
    end

// pop wqe 
always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n)
            begin
                 o_wqe_cache_rd <= 1'b0;
            end
        else if(fsm_cs == IDLE & fsm_ns == RD_WQE)
            begin
                o_wqe_cache_rd <= 1'b1;
            end
        else
            begin
                o_wqe_cache_rd <= 1'b0;
            end
    end

always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n)
            begin
                wqe_r <= {WQE_WIDTH{1'b0}};
            end
        else if(i_wqe_val)
            begin
                wqe_r <= i_wqe;
            end
    end

always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n)
            begin
                wqe_type_r <= 1'b0;
            end
        else if(i_wqe_val)
            begin
                wqe_type_r <= i_wqe_type;
            end
    end

always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n)
            begin
                wqe_addr_r <= {PWQE_BUF_ADDR_WIDTH{1'b0}};
            end
        else if(i_wqe_val)
            begin
                wqe_addr_r <= i_wqe_addr;
            end
    end
always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n)
            begin
                o_qpc_hdr_lookup_valid <= 1'b0;
                o_qpc_hdr_lookup_qp_id <= {QP_PTR_WIDTH{1'b0}};
            end
        else if(o_qpc_hdr_lookup_valid & i_qpc_hdr_lookup_ready)
            begin
                o_qpc_hdr_lookup_valid <= 1'b0;
                o_qpc_hdr_lookup_qp_id <= {QP_PTR_WIDTH{1'b0}};
            end
        else if(i_wqe_val)
            begin
                o_qpc_hdr_lookup_valid <= 1'b1;
                o_qpc_hdr_lookup_qp_id <= i_wqe[WQE_QPID_MSB:WQE_QPID_LSB];
            end
    end

always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n)
            begin
                qpid <= {QP_PTR_WIDTH{1'b0}};
            end
        else if(i_wqe_val)
            begin
                qpid <= i_wqe[WQE_QPID_MSB:WQE_QPID_LSB];
            end
    end

// Maintain IPv4 identification counter
always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n)
            begin
                ipv4_identification <= 16'h0;
            end
        else if(fsm_cs == GEN_HDR && fsm_ns == GEN_PKT_DESC)
            begin
                ipv4_identification <= ipv4_identification + 16'h1;
            end
    end

// store incoming qpc infomation
always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n)
            begin
                qpc_pkey_r        <= {IB_PKEY_WIDTH{1'b0}};
                qpc_pmtu_r        <= 13'h0;
                qpc_dest_qpid_r   <= {IB_QP_WIDTH{1'b0}};
                qpc_sq_curr_psn_r <= {IB_PSN_WIDTH{1'b0}};
                qpc_sq_curr_msn_r <= {IB_MSN_WIDTH{1'b0}};
                qpc_dest_ip_r     <= {IPV6_WIDTH{1'b0}};
                qpc_ttl_r         <= {IP_TTL_WIDTH{1'b0}};
                qpc_dscp_r        <= {IP_DSCP_WDITH{1'b0}};
                qpc_dest_mac_r    <= {ETH_MAC_WIDTH{1'b0}};
            end
        else if(i_qpc_valid)
            begin
                qpc_pkey_r        <= i_qpc_pkey;       
                qpc_dest_qpid_r   <= i_qpc_dest_qpid;  
                qpc_sq_curr_psn_r <= i_qpc_sq_curr_psn;
                qpc_sq_curr_msn_r <= i_qpc_sq_curr_msn;
                qpc_dest_ip_r     <= i_qpc_dest_ip;    
                qpc_ttl_r         <= i_qpc_ttl;        
                qpc_dscp_r        <= i_qpc_dscp;       
                qpc_dest_mac_r    <= i_qpc_dest_mac;   
                case(i_qpc_pmtu)
                // valid after fsm_cs enters GEN_HDR
                3'b000: qpc_pmtu_r <= 13'h0100;
                3'b001: qpc_pmtu_r <= 13'h0200;
                3'b010: qpc_pmtu_r <= 13'h0400;
                3'b011: qpc_pmtu_r <= 13'h0800;
                3'b100: qpc_pmtu_r <= 13'h1000;
                default: qpc_pmtu_r <= 13'h0100;
                endcase
            end
    end

always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n)
            begin
                send_inv_task <= 1'b0;
                send_imm_task <= 1'b0;
                write_imm_task <= 1'b0;
                write_task <= 1'b0;
                send_task <= 1'b0;
                read_req_task <= 1'b0;
            end
        else if(i_wqe_val)
            begin
                send_inv_task <= i_wqe[WQE_OPCODE_MSB:WQE_OPCODE_LSB] == WQE_RDMA_SEND_INV;
                send_imm_task <= i_wqe[WQE_OPCODE_MSB:WQE_OPCODE_LSB] == WQE_RDMA_SEND_IMM;
                write_imm_task <= i_wqe[WQE_OPCODE_MSB:WQE_OPCODE_LSB] == WQE_RDMA_WRITE_IMM;
                write_task <= i_wqe[WQE_OPCODE_MSB:WQE_OPCODE_LSB] == WQE_RDMA_WRITE;
                send_task <= i_wqe[WQE_OPCODE_MSB:WQE_OPCODE_LSB] == WQE_RDMA_SEND;
                read_req_task <= i_wqe[WQE_OPCODE_MSB:WQE_OPCODE_LSB] == WQE_RDMA_READ;
            end
    end
// TODO: Current implementation does not handle acknowledgement and read response
assign ack_task = 1'b0;
assign read_rsp_task = 1'b0;
// TODO: update the generation of first_iter, only, first, last, is_last
always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n)
            begin
                wqe_first <= 1'b0;
            end
        else if(fsm_cs == RD_WQE && i_wqe_val)
            begin
                wqe_first <= i_wqe[WQE_FIRST];
            end
    end
// valid at the first beat of GEN_HDR
always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n)
            begin
                first_iter <= 1'b0;
            end
        else if(fsm_ns == IDLE)
            begin
                first_iter <= 1'b0;
            end
        else if(fsm_cs == RD_QPC && fsm_ns == GEN_HDR && ~wqe_first)
            begin
                first_iter <= 1'b1;
            end
    end
// valid at the second beat of GEN_HDR
always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n)
            begin
                only <= 1'b0;
            end
        else if(fsm_ns == IDLE)
            begin
                only <= 1'b0;
            end
        else if(first_iter && fsm_cs == GEN_HDR && rem_len <= qpc_pmtu_r)
            begin
                only <= 1'b1;
            end
    end
// valid at the second beat of GEN_HDR
always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n)
            begin
                first <= 1'b0;
            end
        else if(fsm_ns == IDLE)
            begin
                first <= 1'b0;
            end
        else if(first_iter && fsm_cs == GEN_HDR && rem_len > qpc_pmtu_r)
            begin
                first <= 1'b1;
            end
    end
// valid at the second beat of GEN_HDR
always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n)
            begin
                last <= 1'b0;
            end
        else if(fsm_ns == IDLE)
            begin
                last <= 1'b0;
            end
        else if(~first_iter && fsm_cs == GEN_HDR && rem_len <= qpc_pmtu_r)
            begin
                last <= 1'b1;
            end
    end
// valid at the third beat of GEN_HDR
always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n)
            begin
                is_last <= 1'b0;
            end
        else if(fsm_ns == IDLE)
            begin
                is_last <= 1'b0;
            end
        else if(only | last)
            begin
                is_last <= 1'b1;
            end
    end
// valid at the second beat of GEN_HDR
assign reth_present = (only | first) && (write_task | write_imm_task); 
assign imm_present = (only | last) && (send_imm_task | write_imm_task);
assign inv_present = (only | last) && send_inv_task;
// maintain payload_len
always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n)
            begin
                payload_len <= 13'h0;
            end
        else if(fsm_cs == GEN_HDR & rem_len >= qpc_pmtu_r)
            begin
                payload_len <= qpc_pmtu_r;
            end
        else if(fsm_cs == GEN_HDR & rem_len <= qpc_pmtu_r)
            begin
                payload_len <= rem_len;
            end
    end 
// assert payload_len_valid during GEN_HDR state, at sencond cycle
always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n)
            begin
                payload_len_valid <= 1'b0;
            end
        else if(fsm_cs == GEN_HDR && fsm_ns == GEN_HDR)
            begin
                payload_len_valid <= 1'b1;
            end
        else if(fsm_cs == GEN_HDR && fsm_ns == GEN_PKT_DESC)
            begin
                payload_len_valid <= 1'b0;
            end
    end

// maintain rem_len
always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n)
            begin
                rem_len <= 32'h0;
            end
        // load initial value for each WQE
        else if(i_wqe_val)
            begin
                rem_len <= i_wqe[WQE_LENGTH_MSB:WQE_LENGTH_LSB];
            end
        // update rem_len in each iteration, write back to the p_wqe
        else if(fsm_cs == GEN_HDR && fsm_ns == GEN_PKT_DESC)
            begin
                rem_len <= rem_len - payload_len;
            end
    end

// Generate Ethernet Header
// fixed in each iteration
// generate once
// valid at 1st cycle of GEN_HDR
always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n)
            begin
                eth_hdr <= 112'h0;
            end    
        else if(fsm_cs == RD_QPC && fsm_ns == GEN_HDR)
            begin
                eth_hdr <= {16'h0008, i_rnic_src_mac[8*1-1:0],
                                i_rnic_src_mac[8*2-1:8*1], i_rnic_src_mac[8*3-1:8*2],
                                i_rnic_src_mac[8*4-1:8*3], i_rnic_src_mac[8*5-1:8*4],
                                i_rnic_src_mac[8*6-1:8*5], i_qpc_dest_mac[8*1-1:0],
                                i_qpc_dest_mac[8*2-1:8*1], i_qpc_dest_mac[8*3-1:8*2],
                                i_qpc_dest_mac[8*4-1:8*3], i_qpc_dest_mac[8*5-1:8*4],
                                i_qpc_dest_mac[8*6-1:8*5]};
            end
    end
// generate IP header, require length of the packet
// maintain ipv4_len, sync with payload_len
always@(*) 
        begin
            if((only | last) & (send_inv_task | send_imm_task | write_imm_task)) 
                begin
                    ipv4_len = 8'h2C + payload_len + {reth_present,4'h0} + 3'd4;
                end
            else 
                begin
                    ipv4_len = 8'h2C + payload_len + {reth_present,4'h0};
                end
        end
// Wait for IPv4 Checksum, 
// IPv4 Checksum Calculation starts at 3rd cycle
// of GEN_HDR
always@(posedge clk or negedge rst_n) 
    begin
        if(~rst_n) 
            begin
                chksum_start <= 1'b0;
            end
        else if(chksum_start) 
            begin
                chksum_start <= 1'b0;
            end
        else if(payload_len_valid & ~chksum_invoke) 
            begin
                chksum_start <= 1'b1;
            end
    end

always@(posedge clk or negedge rst_n) 
    begin
        if(~rst_n) 
            begin
                chksum_invoke <= 0;
            end
        else if(fsm_cs == GEN_HDR & fsm_ns == GEN_PKT_DESC) 
            begin
                chksum_invoke <= 1'b0;
            end
        else if(chksum_start) 
            begin
                chksum_invoke <= 1'b1;
            end
    end

always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n)
            begin
                ip_hdr <= 160'h0;
            end
        else if(fsm_cs == GEN_HDR && chksum_done)
            begin
                ip_hdr <= {qpc_dest_ip_r[1*8-1:0], qpc_dest_ip_r[2*8-1:1*8],
                            qpc_dest_ip_r[3*8-1:2*8], qpc_dest_ip_r[4*8-1:3*8],
                            i_rnic_src_ip[1*8-1:0], i_rnic_src_ip[2*8-1:1*8],
                            i_rnic_src_ip[3*8-1:2*8], i_rnic_src_ip[4*8-1:3*8],
                            ~ipv4_chksum[7:0], ~ipv4_chksum[15:8],
                            8'h11, qpc_ttl_r, 16'h0040, ipv4_identification[7:0],
                            ipv4_identification[15:8], ipv4_len[7:0],
                            ipv4_len[15:8], 16'h0145
                        };
            end
    end

// generate udp header
assign udp_len = ipv4_len - 16'h14;
always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n)
            begin
                udp_hdr <= 64'h0;
            end
        else if(fsm_cs == GEN_HDR && payload_len_valid)
            begin
                udp_hdr <= {16'h0000, udp_len[7:0], udp_len[15:8], 16'hB712,
                                i_rnic_src_port[7:0], i_rnic_src_port[15:8]};
            end
    end

// Generate BTH Header
// Generate BTH Opcode
always@(*) 
    begin
        if(send_task | send_imm_task | send_inv_task) 
            begin
                if(only) 
                    begin
                        if(send_imm_task) 
                            begin
                                bth_opcode = SEND_ONLY_IMM;
                            end
                        else if(send_inv_task) 
                            begin
                                bth_opcode = SEND_ONLY_INV;
                            end
                        else 
                            begin
                                bth_opcode = SEND_ONLY;
                            end
                    end
                else if(first) 
                    begin
                        bth_opcode = SEND_FIRST;
                    end
                else if(last) 
                    begin
                        if(send_imm_task) 
                            begin
                                bth_opcode = SEND_LAST_IMM;
                            end
                        else if(send_inv_task) 
                            begin
                                bth_opcode = SEND_LAST_INV;
                            end
                        else 
                            begin
                                bth_opcode = SEND_LAST;
                            end
                    end
                else 
                    begin
                        bth_opcode = SEND_MIDDLE;
                    end
            end
        else if(write_task | write_imm_task) 
            begin
                if(only) 
                    begin
                        if(write_imm_task) 
                            begin
                                bth_opcode = RDMA_WRITE_ONLY_IMM;
                            end
                        else 
                            begin
                                bth_opcode = RDMA_WRITE_ONLY;
                            end
                    end
                else if(first) 
                    begin
                        bth_opcode = RDMA_WRITE_FIRST;
                    end
                else if(last) 
                    begin
                        if(write_imm_task) 
                            begin
                                bth_opcode = RDMA_WRITE_LAST_IMM;
                            end
                        else 
                            begin
                                bth_opcode = RDMA_WRITE_LAST;
                            end
                    end
                else 
                    begin
                        bth_opcode = RDMA_WRITE_MIDDLE;
                    end
            end
        else if(read_req_task)
            begin
                bth_opcode = RDMA_READ_REQ;
            end
        else if(ack_task)
            begin
                bth_opcode = ACKNOWLEDGE;
            end
        else if(read_rsp_task)
            begin
                if(only)
                    begin
                        bth_opcode = RDMA_READ_RSP_ONLY;
                    end
                else if(first)
                    begin
                        bth_opcode = RDMA_READ_RSP_FIRST;
                    end
                else if(last)
                    begin
                        bth_opcode = RDMA_READ_RSP_LAST;
                    end
                else
                    begin
                        bth_opcode = RDMA_READ_RSP_MIDDLE;
                    end
            end
        else
            begin
                bth_opcode = 8'h0;
            end
    end

// BTH.Solicited-Event
always@(*) 
    begin
        if((only | last) & (send_task | send_imm_task | send_inv_task)) 
            begin
                bth_se = 1'b0;
            end
        else 
            begin
                bth_se = 1'b1;
            end
    end
// maintain psn for each iteration
always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n)
            begin
                curr_psn <= 24'h0;
            end
        // load initial value
        // TODO: ignore acknowledgement and read response
        else if(i_qpc_valid)
            begin
                curr_psn <= i_qpc_sq_curr_psn;
            end
        // update for each iteration
        else if(fsm_cs == GEN_HDR && fsm_ns == GEN_PKT_DESC)
            begin
                curr_psn <= curr_psn + 1'b1;
            end
    end

// other BTH fields
always@(*) 
    begin
        bth_migration = 1'b0;
        bth_pad = 2'h0;    
        bth_tver = 4'h0;
        bth_pkey = qpc_pkey_r;
        bth_destqp = qpc_dest_qpid_r;
        bth_psn = curr_psn;    // TODO:
        bth_ackreq = last | only | read_req_task;
    end
// valid at 2nd cycle of GEN_HDR
always@(posedge clk or negedge rst_n) 
    begin
        if(~rst_n) 
            begin
                bth_hdr <= 0;
            end
        else if(fsm_cs == GEN_HDR & payload_len_valid) 
            begin
                bth_hdr <= {bth_psn[7:0], bth_psn[15:8], bth_psn[23:16],
                            {bth_ackreq, 7'h0}, bth_destqp[7:0], bth_destqp[15:8],
                            bth_destqp[23:16], 8'h00, bth_pkey[7:0], bth_pkey[15:8],
                            {bth_se, bth_migration, bth_pad, bth_tver}, bth_opcode};
            end
    end

always@(posedge clk or negedge rst_n)
    begin
        if(~rst_n)
            begin
                hdr_valid <= 1'b0;
            end
        else if(fsm_cs == GEN_PKT_DESC && (fsm_ns == WB_PWQE || fsm_ns == IDLE))
            begin
                hdr_valid <= 1'b0;
            end
        else if(fsm_cs == GEN_HDR & chksum_done)
            begin
                hdr_valid <= 1'b1;
            end
    end
    
// generate RETH/ImmDt/IETH/AETH according to WQE   
always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n)
            begin
                reth_va <= 64'h0;
                reth_dmalen <= 32'h0;
                reth_rkey <= 32'h0;
                imm_data <= 32'h0;
                inv_mkey <= 32'h0;
            end
        else if(i_wqe_val)
            begin
                reth_va <= i_wqe[WQE_RADDR_MSB:WQE_RADDR_LSB];
                reth_dmalen <= i_wqe[WQE_LENGTH_MSB:WQE_LENGTH_LSB];
                reth_rkey <= i_wqe[WQE_RKEY_MSB:WQE_RKEY_LSB];
                imm_data <= i_wqe[WQE_IMM_INV_MSB:WQE_IMM_INV_LSB];
                inv_mkey <= i_wqe[WQE_IMM_INV_MSB:WQE_IMM_INV_LSB];
            end
    end

always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n)
            begin
                reth_hdr <= 128'h0;
                immdt_hdr <= 32'h0;
                ieth_hdr <= 32'h0;
            end
        else if(fsm_cs == RD_QPC && fsm_ns == GEN_HDR)
            begin
                reth_hdr <= {reth_dmalen[7:0], reth_dmalen[15:8], reth_dmalen[23:16],
                                reth_dmalen[31:24], reth_rkey[7:0], reth_rkey[15:8], reth_rkey[23:16],
                                reth_rkey[31:24], reth_va[7:0], reth_va[15:8], reth_va[23:16],
                                reth_va[31:24], reth_va[39:32], reth_va[47:40], reth_va[55:48],
                                reth_va[63:56]};
                immdt_hdr <= {imm_data[7:0], imm_data[15:8], imm_data[23:16], imm_data[31:24]};
                ieth_hdr <= {inv_mkey[7:0], inv_mkey[15:8], inv_mkey[23:16], inv_mkey[31:24]};
            end
    end
// generate DMA descriptor
// maintain local_addr, dma addr of packet's payload in 
// each iteration

always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n)
            begin
                local_addr <= 64'h0;
            end
        // load initial value from WQE
        // TODO: ignore virtual address translation now
        else if(i_wqe_val)
            begin
                local_addr <= i_wqe[WQE_LADDR_MSB:WQE_LADDR_LSB];
            end
        // update after each iteration
        // else if(fsm_cs == GEN_PKT_DESC && fsm_ns == GEN_HDR)
        //     begin
        //         local_addr <= local_addr + qpc_pmtu_r;
        //     end
    end
// generate packet descriptor
always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n)
            begin
                o_pkt_desc_valid <= 1'b0;
                o_pkt_desc_hdr_len <= 8'h0;
                o_pkt_desc <= {PKT_DESC_WIDTH{1'b0}};
            end
        else if(o_pkt_desc & i_pkt_desc_ready)
            begin
                o_pkt_desc_valid <= 1'b0;
                o_pkt_desc_hdr_len <= 8'h0;
                o_pkt_desc <= {PKT_DESC_WIDTH{1'b0}};
            end
        else if(fsm_cs == GEN_HDR && fsm_ns == GEN_PKT_DESC)
            begin
                o_pkt_desc_valid <= 1'b1;
                o_pkt_desc[PKT_DESC_ETH_MSB:PKT_DESC_ETH_LSB] <= eth_hdr;
                o_pkt_desc[PKT_DESC_IP_V4_MSB:PKT_DESC_IP_V4_LSB] <= ip_hdr;
                o_pkt_desc[PKT_DESC_UDP_V4_MSB:PKT_DESC_UDP_V4_LSB] <= udp_hdr;
                o_pkt_desc[PKT_DESC_DMA_ADDR_0_V4_MSB:PKT_DESC_DMA_ADDR_0_V4_LSB] <= payload_len;   // TODO:
                o_pkt_desc[PKT_DESC_DMA_LEN_0_V4_MSB:PKT_DESC_DMA_LEN_0_V4_LSB] <= local_addr;
                o_pkt_desc[PKT_DESC_QPN_V4_MSB:PKT_DESC_QPN_V4_LSB] <= qpid;
                o_pkt_desc[PKT_DESC_INLINE_V4] <= 1'b0;
                o_pkt_desc[PKT_DESC_INLINE_LEN_V4_MSB:PKT_DESC_INLINE_LEN_V4_LSB] <= 4'h0;
                o_pkt_desc[PKT_DESC_RSVD_V4_MSB:PKT_DESC_RSVD_V4_LSB] <= 
                                            {(PKT_DESC_RSVD_V4_MSB-PKT_DESC_RSVD_V4_LSB){1'b0}};
                if(write_task | write_imm_task)
                    begin
                        if(reth_present & imm_present)
                            begin
                                // WRITE_ONLY: |BTH|RETH|IMM|
                                o_pkt_desc_hdr_len <= 8'h4A;
                                o_pkt_desc[PKT_DESC_RETH_V4_MSB:PKT_DESC_RETH_V4_LSB] <= reth_hdr;
                                o_pkt_desc[PKT_DESC_WR_IMM_V4_MSB:PKT_DESC_WR_IMM_V4_LSB] <= immdt_hdr;
                            end
                        else if(~reth_present & imm_present)
                            begin
                                // WRITE_IMM_LAST: |BTH|IMM|
                                o_pkt_desc_hdr_len <= 8'h3A;
                                o_pkt_desc[PKT_DESC_WR_IMM_V4_MSB:PKT_DESC_WR_IMM_V4_LSB] <= immdt_hdr;
                            end
                        else if(reth_present & ~imm_present)
                            begin
                                // WRITE_FIRST or WRITE_IMM_FIRST: |BTH|RETH|
                                o_pkt_desc_hdr_len <= 8'h46;
                                o_pkt_desc[PKT_DESC_RETH_V4_MSB:PKT_DESC_RETH_V4_LSB] <= reth_hdr;
                            end
                        else
                            begin
                                // WRITE MIDDLE
                                o_pkt_desc_hdr_len <= 8'h36;
                            end
                    end 
                else if(send_task | send_imm_task | send_inv_task)
                    begin
                        if(imm_present)
                            begin
                                o_pkt_desc_hdr_len <= 8'h3A;
                                o_pkt_desc[PKT_DESC_IETH_IMM_V4_MSB:PKT_DESC_IETH_IMM_V4_LSB] <= immdt_hdr;
                            end
                        else if(inv_present)
                            begin
                                o_pkt_desc_hdr_len <= 8'h3A;
                                o_pkt_desc[PKT_DESC_IETH_IMM_V4_MSB:PKT_DESC_IETH_IMM_V4_LSB] <= ieth_hdr;
                            end
                        else
                            begin
                                o_pkt_desc_hdr_len <= 8'h36;
                            end
                    end
                else if(read_req_task)
                    begin
                        o_pkt_desc_hdr_len <= 8'h46;
                        o_pkt_desc[PKT_DESC_RETH_V4_MSB:PKT_DESC_RETH_V4_LSB] <= reth_hdr;
                    end
            end
    end

// write back pwqe
always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n)
            begin
                o_pwqe_wb <= 1'b0;
            end
        else if(fsm_cs == GEN_PKT_DESC && fsm_ns == WB_PWQE)
            begin
                o_pwqe_wb <= 1'b1;
            end
        else 
            begin
                o_pwqe_wb <= 1'b0;
            end
    end

always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n)
            begin
                o_pwqe_addr <= {PWQE_BUF_ADDR_WIDTH{1'b0}};
            end
        else if(fsm_cs == GEN_PKT_DESC && fsm_ns == WB_PWQE)
            begin
                o_pwqe_addr <= wqe_addr_r;
            end
    end

// update WQE.length, WQE.local_addr, WQE.first
assign laddr_udt = local_addr + qpc_pmtu_r;
always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n)
            begin
                o_pwqe <= {WQE_WIDTH{1'b0}};
            end
        else if(fsm_cs == GEN_PKT_DESC && fsm_ns == WB_PWQE)
            begin
                o_pwqe <= {wqe_r[511:WQE_FIRST+1],
                        1'b1,   // not first if updated
                        wqe_r[WQE_QPID_MSB:WQE_LKEY_LSB],
                        laddr_udt,  // update local_addr
                        rem_len,    // update length
                        wqe_r[WQE_OPCODE_MSB:WQE_WRID_LSB]};
            end
    end

// clear slot status
always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n)
            begin
                o_reset_req <= 1'b0;
                o_reset_addr <= {PWQE_BUF_ADDR_WIDTH{1'b0}};
            end
        else if(fsm_cs == GEN_PKT_DESC && fsm_ns == IDLE && wqe_type_r)
            begin
                o_reset_req <= 1'b1;
                o_reset_addr <= wqe_addr_r;
            end
        else
            begin
                o_reset_req <= 1'b0;
                o_reset_addr <= {PWQE_BUF_ADDR_WIDTH{1'b0}};
            end
    end
// update QPC
// only generate one packet in each iteration
always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n)
            begin
                psn_wb <= {IB_PSN_WIDTH{1'b0}};
            end
        else if(fsm_cs == RD_QPC && fsm_ns == GEN_HDR)
            begin
                psn_wb <= i_qpc_sq_curr_psn + 1'b1;
            end
    end

always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n)
            begin
                msn_wb <= {IB_MSN_WIDTH{1'b0}};
            end
        else if(fsm_cs == RD_QPC && fsm_ns == GEN_HDR)
            begin
                msn_wb <= i_qpc_sq_curr_msn + 1'b1;
            end

    end

always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n)
            begin
                o_qpc_hdr_update_valid <= 1'b0;
                o_qpc_hdr_update_qpid <= {QP_PTR_WIDTH{1'b0}};
                o_qpc_sq_curr_psn <= {IB_PSN_WIDTH{1'b0}};
                o_qpc_sq_curr_msn <= {IB_MSN_WIDTH{1'b0}};
            end
        else if(fsm_cs == GEN_PKT_DESC && (fsm_ns == IDLE || fsm_ns == WB_PWQE))
            begin
                o_qpc_hdr_update_valid <= 1'b1;
                o_qpc_hdr_update_qpid <= qpid;
                o_qpc_sq_curr_psn <= psn_wb;
                o_qpc_sq_curr_msn <= msn_wb;
            end
        else
            begin
                o_qpc_hdr_update_valid <= 1'b0;
                o_qpc_hdr_update_qpid <= {QP_PTR_WIDTH{1'b0}};
                o_qpc_sq_curr_psn <= {IB_PSN_WIDTH{1'b0}};
                o_qpc_sq_curr_msn <= {IB_MSN_WIDTH{1'b0}};
            end
    end
// synchronize final signal and wr_id, for locating the 
// position of wqe
always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n)
            begin
                o_final <= 1'b0;
            end
        else if(fsm_cs == GEN_PKT_DESC && fsm_ns == IDLE)
            begin
                o_final <= 1'b1;
            end
        else
            begin
                o_final <= 1'b0;
            end
    end

always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n)
            begin
                o_qpn <= {QP_PTR_WIDTH{1'b0}};
            end
        else if(fsm_cs == GEN_PKT_DESC && fsm_ns == IDLE)
            begin
                o_qpn <= qpid;
            end
        else
            begin
                o_qpn <= {QP_PTR_WIDTH{1'b0}};
            end
    end
always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n)
            begin
                o_wr_id <= 64'h0;
            end
        else if(fsm_cs == GEN_PKT_DESC && fsm_ns == IDLE)
            begin
                o_wr_id <= wqe_r[WQE_WRID_MSB:WQE_WRID_LSB];
            end
        else 
            begin
                o_wr_id <= 64'h0;
            end
    end
// instantiate ipv4_chksum 
ipv4_chksum ipv4_chksum_inst(
    .clk(clk),
    .rst_n(rst_n),
    .i_chksum_start(chksum_start),
    .i_ipv4_len(ipv4_len),
    .i_ipv4_identification(ipv4_identification),
    .i_ipv4_ttl(qpc_ttl_r),
    .i_ipv4_src_addr(i_rnic_src_ip[31:0]),
    .i_ipv4_dest_addr(qpc_dest_ip_r[31:0]),
    .o_chksum_done(chksum_done),
    .o_ipv4_chksum(ipv4_chksum)
);

endmodule 