module wqe_fetch 
#(
    parameter MAX_QP         = 16,
    parameter QP_PTR_WIDTH   = 4,
    parameter SQ_DEPTH       = 4096,
    parameter WQE_WIDTH      = 512,
    parameter WQE_WIDTH_BYTE = WQE_WIDTH / 8,
    parameter SQ_SIZE_BYTE   = SQ_DEPTH * WQE_WIDTH_BYTE,
    parameter SQ_PTR_WIDTH   = 12,
    parameter AXI_DATA_WIDTH = 512,
    parameter AXI_ADDR_WIDTH = 32,
    parameter AXI_STRB_WIDTH = (AXI_DATA_WIDTH/8),
    parameter AXI_ID_WIDTH   = 1
)(
    input  wire                       clk,
    input  wire                       rst_n,
    // request for wqe read schedule
    input  wire [MAX_QP-1:0]          i_active, 
    output reg                        o_wqe_fetch_ready,
    input  wire                       i_arbit_val,
    input  wire [QP_PTR_WIDTH-1:0]    i_qp_idx,   
    input  wire [MAX_QP-1:0]          i_qp_idx_one_hot,
    input  wire [AXI_ADDR_WIDTH-1:0]  i_sq_base,
    // push wqe to wqe_cache
    input  wire [MAX_QP-1:0]          i_wqe_cache_alfull,
    input  wire [MAX_QP-1:0]          i_wqe_cache_full,
    output reg                        o_wqe_cache_wr,
    output reg  [WQE_WIDTH-1:0]       o_wqe,
    // axi-master interface
    // dummy write channel
    output wire [AXI_ID_WIDTH-1:0]    m_axi_awid,
    output wire [AXI_ADDR_WIDTH-1:0]  m_axi_awaddr,
    output wire [7:0]                 m_axi_awlen,
    output wire [2:0]                 m_axi_awsize,
    output wire [1:0]                 m_axi_awburst,
    output wire                       m_axi_awlock,
    output wire [3:0]                 m_axi_awcache,
    output wire [2:0]                 m_axi_awprot,
    output wire                       m_axi_awvalid,
    input  wire                       m_axi_awready,
    output wire [AXI_DATA_WIDTH-1:0]  m_axi_wdata,
    output wire [AXI_STRB_WIDTH-1:0]  m_axi_wstrb,
    output wire                       m_axi_wlast,
    output wire                       m_axi_wvalid,
    input  wire                       m_axi_wready,
    input  wire [AXI_ID_WIDTH-1:0]    m_axi_bid,
    input  wire [1:0]                 m_axi_bresp,
    input  wire                       m_axi_bvalid,
    output wire                       m_axi_bready,
    // read channel
    output wire [AXI_ID_WIDTH-1:0]    m_axi_arid,
    output wire [AXI_ADDR_WIDTH-1:0]  m_axi_araddr,
    output wire [7:0]                 m_axi_arlen,
    output wire [2:0]                 m_axi_arsize,
    output wire [1:0]                 m_axi_arburst,
    output wire                       m_axi_arlock,
    output wire [3:0]                 m_axi_arcache,
    output wire [2:0]                 m_axi_arprot,
    output wire                       m_axi_arvalid,
    input  wire                       m_axi_arready,
    input  wire [AXI_ID_WIDTH-1:0]    m_axi_rid,
    input  wire [AXI_DATA_WIDTH-1:0]  m_axi_rdata,
    input  wire [1:0]                 m_axi_rresp,
    input  wire                       m_axi_rlast,
    input  wire                       m_axi_rvalid,
    output wire                       m_axi_rready
);

    // assume all the sq share the same depth 
    // and all the sq are continuous in the dram
    // |sq-0|sq-1|sq-2|...|
    // i_sq_base is the address of sq-0/wqe-0

    // Maximum AXI burst length to generate
    localparam AXI_MAX_BURST_LEN = 16;
    // Width of AXI stream interfaces in bits
    localparam AXIS_DATA_WIDTH = AXI_DATA_WIDTH;
    // AXI stream tkeep signal width (words per cycle)
    localparam AXIS_KEEP_WIDTH = (AXIS_DATA_WIDTH/8);
    // Use AXI stream tlast signal
    localparam AXIS_LAST_ENABLE = 1;
    // Propagate AXI stream tid signal
    localparam AXIS_ID_ENABLE = 0;
    // AXI stream tid signal width
    localparam AXIS_ID_WIDTH = 1;
    // Propagate AXI stream tdest signal
    localparam AXIS_DEST_ENABLE = 0;
    // AXI stream tdest signal width
    localparam AXIS_DEST_WIDTH = 1;
    // Propagate AXI stream tuser signal
    localparam AXIS_USER_ENABLE = 0;
    // AXI stream tuser signal width
    localparam AXIS_USER_WIDTH = 1;
    // Width of length field
    localparam LEN_WIDTH = 7;
    // Width of tag field
    localparam TAG_WIDTH = 1;
    // Enable support for scatter/gather DMA
    // (multiple descriptors per AXI stream frame)
    localparam ENABLE_SG = 0;
    // Enable support for unaligned transfers
    localparam ENABLE_UNALIGNED = 0;

    localparam IDLE = 4'b0001;
    localparam RD_SQ = 4'b0010;
    localparam WAIT_SQE = 4'b0100;
    localparam PUSH_SQE = 4'b1000;

    localparam WQE_QPID_LSB = 328                  ;
    localparam WQE_QPID_MSB = WQE_QPID_LSB+QP_PTR_WIDTH-1;

    // AXI read descriptor input
    reg  [AXI_ADDR_WIDTH-1:0]    s_axis_read_desc_addr;
    reg  [LEN_WIDTH-1:0]         s_axis_read_desc_len;
    wire [TAG_WIDTH-1:0]         s_axis_read_desc_tag;
    wire [AXIS_ID_WIDTH-1:0]     s_axis_read_desc_id;
    wire [AXIS_DEST_WIDTH-1:0]   s_axis_read_desc_dest;
    wire [AXIS_USER_WIDTH-1:0]   s_axis_read_desc_user;
    reg                          s_axis_read_desc_valid;
    wire                         s_axis_read_desc_ready;

    assign s_axis_read_desc_tag  = {TAG_WIDTH{1'b0}};
    assign s_axis_read_desc_id   = {AXIS_ID_WIDTH{1'b0}};
    assign s_axis_read_desc_dest = {AXIS_DEST_WIDTH{1'b0}};
    assign s_axis_read_desc_user = {AXIS_USER_WIDTH{1'b0}};
    // AXI read descriptor status output
    // ignore now
    wire [TAG_WIDTH-1:0]         m_axis_read_desc_status_tag;
    wire [3:0]                   m_axis_read_desc_status_error;
    wire                         m_axis_read_desc_status_valid;
    // AXI stream read data output
    wire [AXIS_DATA_WIDTH-1:0]   m_axis_read_data_tdata;
    wire [AXIS_KEEP_WIDTH-1:0]   m_axis_read_data_tkeep;
    wire                         m_axis_read_data_tvalid;
    reg                          m_axis_read_data_tready;
    wire                         m_axis_read_data_tlast;
    wire [AXIS_ID_WIDTH-1:0]     m_axis_read_data_tid;
    wire [AXIS_DEST_WIDTH-1:0]   m_axis_read_data_tdest;
    wire [AXIS_USER_WIDTH-1:0]   m_axis_read_data_tuser;

    // maintain pi of SQ
    // TODO: this implementation is only for simulation
    reg [SQ_PTR_WIDTH-1:0] sq_pi [0:MAX_QP-1];

    reg [3:0] fsm_cs;
    reg [3:0] fsm_ns;

    reg [QP_PTR_WIDTH-1:0] qp_idx_r;

    wire rst;
    wire wr_wqe_finish;

    assign rst = ~rst_n;

    // fill dummy write chnanel
    assign m_axi_awid    = {AXI_ID_WIDTH{1'b0}};
    assign m_axi_awaddr  = {AXI_ADDR_WIDTH{1'b0}};
    assign m_axi_awlen   = 8'h0;
    assign m_axi_awsize  = 3'h0;
    assign m_axi_awburst = 2'h0;
    assign m_axi_awlock  = 1'b0;
    assign m_axi_awcache = 4'h0;
    assign m_axi_awprot  = 3'h0;
    assign m_axi_awvalid = 1'b0;

    assign m_axi_wdata  = {AXI_DATA_WIDTH{1'b0}};
    assign m_axi_wstrb  = {AXI_STRB_WIDTH{1'b0}};
    assign m_axi_wlast  = 1'b0;
    assign m_axi_wvalid = 1'b0;

    assign m_axi_bready = 1'b0;

    // fsm design 
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
    // next-state logic
    always @(*)
        begin
            case (fsm_cs)
                IDLE:
                    if(i_arbit_val && ~(i_qp_idx_one_hot == 16'h0))
                        begin
                            fsm_ns = RD_SQ;
                        end
                    else
                        begin
                            fsm_ns = IDLE;
                        end
                RD_SQ:
                    if(s_axis_read_desc_valid & s_axis_read_desc_ready)
                        begin
                            fsm_ns = WAIT_SQE;
                        end
                    else
                        begin
                            fsm_ns = RD_SQ;
                        end
                WAIT_SQE: 
                    if(m_axis_read_data_tvalid & m_axis_read_data_tready)
                        begin
                            fsm_ns = PUSH_SQE;
                        end
                    else
                        begin
                            fsm_ns = WAIT_SQE;
                        end
                PUSH_SQE:
                    if(wr_wqe_finish)
                        begin
                            fsm_ns = IDLE;  
                        end
                    else
                        begin
                            fsm_ns = PUSH_SQE;
                        end
                default: fsm_ns = IDLE;
            endcase
        end
    
    assign wr_wqe_finish = o_wqe_cache_wr && (~i_wqe_cache_full[qp_idx_r]);
    // generate wqe_read request: o_wqe_fetch_ready
    reg arbit_pending;

    always @(posedge clk or negedge rst_n)
        begin
            if(~rst_n)  
                begin
                    arbit_pending <= 1'b0;
                end
            else if(o_wqe_fetch_ready)
                begin
                    arbit_pending <= 1'b1;
                end
            else if(i_arbit_val)
                begin
                    arbit_pending <= 1'b0;
                end
        end

    always @(posedge clk or negedge rst_n)
        begin
            if(~rst_n)
                begin
                    qp_idx_r <= {QP_PTR_WIDTH{1'b0}};
                end
            else if(i_arbit_val)
                begin
                    qp_idx_r <= i_qp_idx;
                end
        end
    // request for arbitration
    always @(posedge clk or negedge rst_n)
        begin
            if(~rst_n)
                begin
                    o_wqe_fetch_ready <= 1'b0;
                end
            else if(fsm_cs == IDLE & ~arbit_pending & (i_wqe_cache_alfull != {MAX_QP{1'b1}})
                    & |i_active)
                begin
                    o_wqe_fetch_ready <= 1'b1;
                end
            else
                begin
                    o_wqe_fetch_ready <= 1'b0;
                end
        end

    // generate sqe read dma request
    always @(posedge clk or negedge rst_n)
        begin
            if(~rst_n)
                begin
                    s_axis_read_desc_addr <= {AXI_ADDR_WIDTH{1'b0}};
                    s_axis_read_desc_len <= {LEN_WIDTH{1'b0}};
                    s_axis_read_desc_valid <= 1'b0;
                end
            else if(fsm_cs == IDLE & fsm_ns == RD_SQ)
                begin
                    s_axis_read_desc_addr <= i_sq_base + i_qp_idx * SQ_SIZE_BYTE
                                            + sq_pi[i_qp_idx] * WQE_WIDTH_BYTE;
                    s_axis_read_desc_len <= WQE_WIDTH_BYTE;
                    s_axis_read_desc_valid <= 1'b1;
                end
            else if(s_axis_read_desc_valid & s_axis_read_desc_ready)
                begin
                    s_axis_read_desc_addr <= {AXI_ADDR_WIDTH{1'b0}};
                    s_axis_read_desc_len <= {LEN_WIDTH{1'b0}};
                    s_axis_read_desc_valid <= 1'b0;
                end
        end


    genvar i;
    generate
        for(i = 0; i < MAX_QP; i = i + 1)
            begin
                always @(posedge clk or negedge rst_n)
                    begin
                        if(~rst_n)
                            begin
                                sq_pi[i] <= {QP_PTR_WIDTH{1'b0}};
                            end
                        else if(fsm_cs == IDLE && fsm_ns == RD_SQ && i == i_qp_idx)
                            begin
                                sq_pi[i] <= sq_pi[i] + 1'b1;
                            end
                    end
            end
    endgenerate
    
    // accept incoming SQE
    always @(posedge clk or negedge rst_n)
        begin
            if(~rst_n)
                begin
                    m_axis_read_data_tready <= 1'b0;
                end
            else if(fsm_cs == RD_SQ & fsm_ns == WAIT_SQE)
                begin
                    m_axis_read_data_tready <= 1'b1;
                end
            else if(m_axis_read_data_tready & m_axis_read_data_tvalid)
                begin
                    m_axis_read_data_tready <= 1'b0;
                end
        end

    // push SQE
    always @(posedge clk or negedge rst_n)
        begin
            if(~rst_n)
                begin
                    o_wqe_cache_wr <= 1'b0;
                    o_wqe <= {(WQE_WIDTH){1'b0}};
                end
            else if(m_axis_read_data_tvalid)
                begin
                    o_wqe_cache_wr <= 1'b1;
                    o_wqe <= {{(WQE_WIDTH-1-WQE_QPID_MSB){1'b0}}, qp_idx_r, 
                            m_axis_read_data_tdata[WQE_QPID_LSB-1:0]};
                end
            else if(wr_wqe_finish)
                begin
                    o_wqe_cache_wr <= 1'b0;
                    o_wqe <= {(WQE_WIDTH){1'b0}};
                end
        end

    // reg [63:0] sq1_fetch_cnt;
    // reg [63:0] sq2_fetch_cnt;
    // always @(posedge clk or negedge rst_n)
    //     begin
    //         if(~rst_n)
    //             begin
    //                 sq1_fetch_cnt <= 64'h0;
    //                 sq2_fetch_cnt <= 64'h0;
    //             end
    //         else if(i_arbit_val && i_qp_idx == 4'h1)
    //             begin
    //                 sq1_fetch_cnt <= sq1_fetch_cnt + 1'b1;
    //             end
    //         else if(i_arbit_val && i_qp_idx == 4'h3)
    //             begin
    //                 sq2_fetch_cnt <= sq2_fetch_cnt + 1'b1;
    //             end
    //     end
    // initial 
    //     begin
    //         $monitor("fetch sq1 :%0d, fetch sq2 :%0d", sq1_fetch_cnt, sq2_fetch_cnt);
    //     end
    axi_dma_rd#(
        .AXI_DATA_WIDTH                ( AXI_DATA_WIDTH     ),
        .AXI_ADDR_WIDTH                ( AXI_ADDR_WIDTH     ),
        .AXI_ID_WIDTH                  ( AXI_ID_WIDTH       ),
        .AXI_MAX_BURST_LEN             ( AXI_MAX_BURST_LEN  ),
        .AXIS_DATA_WIDTH               ( AXI_DATA_WIDTH     ),
        .AXIS_LAST_ENABLE              ( AXIS_LAST_ENABLE   ),
        .AXIS_ID_ENABLE                ( AXIS_ID_ENABLE     ),
        .AXIS_ID_WIDTH                 ( AXIS_ID_WIDTH      ),
        .AXIS_DEST_ENABLE              ( AXIS_DEST_ENABLE   ),
        .AXIS_DEST_WIDTH               ( AXIS_DEST_WIDTH    ),
        .AXIS_USER_ENABLE              ( AXIS_USER_ENABLE   ),
        .AXIS_USER_WIDTH               ( AXIS_USER_WIDTH    ),
        .LEN_WIDTH                     ( LEN_WIDTH          ),
        .TAG_WIDTH                     ( TAG_WIDTH          ),
        .ENABLE_SG                     ( ENABLE_SG          ),
        .ENABLE_UNALIGNED              ( ENABLE_UNALIGNED   )
    )u_axi_dma_rd(
        .clk                           ( clk                           ),
        .rst                           ( rst                           ),
        .s_axis_read_desc_addr         ( s_axis_read_desc_addr         ),
        .s_axis_read_desc_len          ( s_axis_read_desc_len          ),
        .s_axis_read_desc_tag          ( s_axis_read_desc_tag          ),
        .s_axis_read_desc_id           ( s_axis_read_desc_id           ),
        .s_axis_read_desc_dest         ( s_axis_read_desc_dest         ),
        .s_axis_read_desc_user         ( s_axis_read_desc_user         ),
        .s_axis_read_desc_valid        ( s_axis_read_desc_valid        ),
        .s_axis_read_desc_ready        ( s_axis_read_desc_ready        ),
        .m_axis_read_desc_status_tag   ( m_axis_read_desc_status_tag   ),
        .m_axis_read_desc_status_error ( m_axis_read_desc_status_error ),
        .m_axis_read_desc_status_valid ( m_axis_read_desc_status_valid ),
        .m_axis_read_data_tdata        ( m_axis_read_data_tdata        ),
        .m_axis_read_data_tkeep        ( m_axis_read_data_tkeep        ),
        .m_axis_read_data_tvalid       ( m_axis_read_data_tvalid       ),
        .m_axis_read_data_tready       ( m_axis_read_data_tready       ),
        .m_axis_read_data_tlast        ( m_axis_read_data_tlast        ),
        .m_axis_read_data_tid          ( m_axis_read_data_tid          ),
        .m_axis_read_data_tdest        ( m_axis_read_data_tdest        ),
        .m_axis_read_data_tuser        ( m_axis_read_data_tuser        ),
        .m_axi_arid                    ( m_axi_arid                    ),
        .m_axi_araddr                  ( m_axi_araddr                  ),
        .m_axi_arlen                   ( m_axi_arlen                   ),
        .m_axi_arsize                  ( m_axi_arsize                  ),
        .m_axi_arburst                 ( m_axi_arburst                 ),
        .m_axi_arlock                  ( m_axi_arlock                  ),
        .m_axi_arcache                 ( m_axi_arcache                 ),
        .m_axi_arprot                  ( m_axi_arprot                  ),
        .m_axi_arvalid                 ( m_axi_arvalid                 ),
        .m_axi_arready                 ( m_axi_arready                 ),
        .m_axi_rid                     ( m_axi_rid                     ),
        .m_axi_rdata                   ( m_axi_rdata                   ),
        .m_axi_rresp                   ( m_axi_rresp                   ),
        .m_axi_rlast                   ( m_axi_rlast                   ),
        .m_axi_rvalid                  ( m_axi_rvalid                  ),
        .m_axi_rready                  ( m_axi_rready                  ),
        .enable                        ( 1'b1                          )
    );

endmodule