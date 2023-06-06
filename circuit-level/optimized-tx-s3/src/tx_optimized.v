`default_nettype none
`timescale 1ns/1ps

module tx_optimized #(
    parameter MAX_QP                 = 32                ,	        
    parameter QP_PTR_WIDTH           = 5                 , 
    parameter AXI_DATA_WIDTH         = 512               ,
    parameter AXI_ADDR_WIDTH         = 32                ,
    parameter AXI_STRB_WIDTH         = (AXI_DATA_WIDTH/8),
    parameter AXI_ID_WIDTH           = 1                 ,
    parameter ETH_MAC_WIDTH          = 48                ,
    parameter IPV6_WIDTH             = 128               ,
    parameter UDP_PORT_WIDTH         = 16                ,
    parameter IB_PKEY_WIDTH          = 16                ,
    parameter IB_PMTU_CODE_WIDTH     = 3                 ,
    parameter IB_QP_WIDTH            = 24                ,
    parameter IP_TTL_WIDTH           = 8                 ,
    parameter IP_DSCP_WDITH          = 6                 ,
    parameter IB_PSN_WIDTH           = 24                ,
    parameter IB_MSN_WIDTH           = 24                ,
    parameter PKT_DESC_WIDTH         = 1024              ,
    parameter PKT_DESC_HDR_LEN_WIDTH = 8             
)(
    input  wire                                clk                    ,
    input  wire                                rst_n                  ,
    input  wire [MAX_QP -1:0]                  i_active               ,	
    input  wire [AXI_ADDR_WIDTH-1:0]           i_sq_base              ,
    // axi-master interface
    // dummy write channel
    output wire [AXI_ID_WIDTH-1:0]             m_axi_awid             ,
    output wire [AXI_ADDR_WIDTH-1:0]           m_axi_awaddr           ,
    output wire [7:0]                          m_axi_awlen            ,
    output wire [2:0]                          m_axi_awsize           ,
    output wire [1:0]                          m_axi_awburst          ,
    output wire                                m_axi_awlock           ,
    output wire [3:0]                          m_axi_awcache          ,
    output wire [2:0]                          m_axi_awprot           ,
    output wire                                m_axi_awvalid          ,
    input  wire                                m_axi_awready          ,
    output wire [AXI_DATA_WIDTH-1:0]           m_axi_wdata            ,
    output wire [AXI_STRB_WIDTH-1:0]           m_axi_wstrb            ,
    output wire                                m_axi_wlast            ,
    output wire                                m_axi_wvalid           ,
    input  wire                                m_axi_wready           ,
    input  wire [AXI_ID_WIDTH-1:0]             m_axi_bid              ,
    input  wire [1:0]                          m_axi_bresp            ,
    input  wire                                m_axi_bvalid           ,
    output wire                                m_axi_bready           ,
    // read channel
    output wire [AXI_ID_WIDTH-1:0]             m_axi_arid             ,
    output wire [AXI_ADDR_WIDTH-1:0]           m_axi_araddr           ,
    output wire [7:0]                          m_axi_arlen            ,
    output wire [2:0]                          m_axi_arsize           ,
    output wire [1:0]                          m_axi_arburst          ,
    output wire                                m_axi_arlock           ,
    output wire [3:0]                          m_axi_arcache          ,
    output wire [2:0]                          m_axi_arprot           ,
    output wire                                m_axi_arvalid          ,
    input  wire                                m_axi_arready          ,
    input  wire [AXI_ID_WIDTH-1:0]             m_axi_rid              ,
    input  wire [AXI_DATA_WIDTH-1:0]           m_axi_rdata            ,
    input  wire [1:0]                          m_axi_rresp            ,
    input  wire                                m_axi_rlast            ,
    input  wire                                m_axi_rvalid           ,
    output wire                                m_axi_rready           ,
    // function-rnic context, fixed value after initialization
    input  wire  [ETH_MAC_WIDTH-1:0]           i_rnic_src_mac         ,
    input  wire  [IPV6_WIDTH-1:0]              i_rnic_src_ip          ,
    input  wire  [UDP_PORT_WIDTH-1:0]          i_rnic_src_port        ,
    // qp context lookup
    output wire                                o_qpc_hdr_lookup_valid ,
    input  wire                                i_qpc_hdr_lookup_ready ,
    output wire   [QP_PTR_WIDTH-1:0]           o_qpc_hdr_lookup_qp_id ,
    input  wire                                i_qpc_valid            ,
    input  wire  [IB_PKEY_WIDTH-1:0]           i_qpc_pkey             ,
    input  wire  [IB_PMTU_CODE_WIDTH-1:0]      i_qpc_pmtu             ,
    input  wire  [IB_QP_WIDTH-1:0]             i_qpc_dest_qpid        ,
    input  wire  [IB_PSN_WIDTH-1:0]            i_qpc_sq_curr_psn      ,
    input  wire  [IB_MSN_WIDTH-1:0]            i_qpc_sq_curr_msn      ,
    input  wire  [IPV6_WIDTH-1:0]              i_qpc_dest_ip          ,
    input  wire  [IP_TTL_WIDTH-1:0]            i_qpc_ttl              ,
    input  wire  [IP_DSCP_WDITH-1:0]           i_qpc_dscp             , 
    input  wire  [ETH_MAC_WIDTH-1:0]           i_qpc_dest_mac         ,
    // qp context update 
    output wire                                o_qpc_hdr_update_valid ,
    output wire  [QP_PTR_WIDTH-1:0]            o_qpc_hdr_update_qpid  ,
    output wire  [IB_PSN_WIDTH-1:0]            o_qpc_sq_curr_psn      ,
    output wire  [IB_MSN_WIDTH-1:0]            o_qpc_sq_curr_msn      ,
    // if* with pkt_desc_if            
    output wire                                o_pkt_desc_valid       ,
    input  wire                                i_pkt_desc_ready       ,
    output wire  [PKT_DESC_HDR_LEN_WIDTH-1:0]  o_pkt_desc_hdr_len     ,
    output wire  [PKT_DESC_WIDTH-1:0]          o_pkt_desc             ,
    output wire                                o_final                ,
    output wire  [QP_PTR_WIDTH-1:0]            o_qpn                  ,
    output wire  [63:0]                        o_wr_id                ,
    // sync with micro-benchmark
    output wire                                o_wqe_cache_wr_val     ,
    output wire [QP_PTR_WIDTH-1:0]             o_wqe_cache_wr_qpn     ,
    output wire [63:0]                         o_wqe_cache_wr_wrid    ,
    output wire                                o_ibt_wqe_val          ,
    output wire [511:0]                        o_ibt_wqe  
); 

    localparam WQE_WIDTH              = 512;
    localparam WQE_WIDTH_BYTE         = WQE_WIDTH / 8;
    localparam SQ_DEPTH               = 128;
    localparam SQ_SIZE_BYTE           = SQ_DEPTH * WQE_WIDTH_BYTE;
    localparam SQ_PTR_WIDTH           = 7;
    localparam PWQE_SLOT_NUM          = 4;  
    localparam PWQE_SLOT_ADDR_WIDTH   = 2;
    localparam PWQE_BUF_ADDR_WIDTH    = 2;
    localparam PWQE_BUF_WIDTH         = 512;

    wire [MAX_QP-1:0]	      wqe_cache_alfull;
    wire [MAX_QP-1:0]         wqe_cache_full;
    wire                      wqe_fetch_ready;
    wire 			          arbit_val; 
    wire [QP_PTR_WIDTH -1 :0] qp_idx;
    wire [MAX_QP -1:0]        qp_idx_one_hot;

    // request for wqe read schedule
    // push wqe to wqe_cache
    wire                      wqe_cache_wr;
    wire [WQE_WIDTH-1:0]      wqe_wr;

    wire                      ls_wqe_empty                 ;
    wire                      ls_wqe_ren                   ;
    wire [WQE_WIDTH-1:0]      ls_wqe_rdata                 ;

    wire [PWQE_SLOT_NUM-1:0]  bs_fifo_empty                ;
    wire [PWQE_SLOT_NUM-1:0]  bs_fifo_rd                   ;
    wire                      bs_wqe_val                   ;
    wire [WQE_WIDTH-1:0]      bs_wqe                       ; 
    // if* with station_writer        
    wire                             ren_0      ;
    wire                             wen_0      ;
    wire [PWQE_BUF_ADDR_WIDTH-1:0]   addr_0     ;
    wire [PWQE_BUF_WIDTH-1:0]        din_0      ;
    wire                             set_req    ;
    wire [PWQE_SLOT_ADDR_WIDTH-1:0]  set_addr   ;
    // if*  with grp_scheduler    
    wire                             ren_1      ;
    wire                             wen_1      ;
    wire [PWQE_BUF_ADDR_WIDTH-1:0]   addr_1     ;
    wire [PWQE_BUF_WIDTH-1:0]        din_1      ;
    wire [PWQE_BUF_WIDTH-1:0]        dout_1     ;
    wire [PWQE_SLOT_NUM-1:0]         slot_status;
    // if* with ib_transport
    wire                             reset_req  ;
    wire [PWQE_SLOT_ADDR_WIDTH-1:0]  reset_addr ; 

    wire                             wqe_cache_empty;
    wire                             wqe_cache_rd   ;
    wire                             wqe_val        ;
    wire                             wqe_type       ;
    wire [PWQE_BUF_ADDR_WIDTH-1:0]   wqe_addr       ;
    wire [WQE_WIDTH-1:0]             wqe_rd         ;

    wire                             pwqe_wb        ;
    wire [PWQE_BUF_ADDR_WIDTH-1:0]   pwqe_addr      ;
    wire [WQE_WIDTH-1:0]             pwqe           ;

    wqe_read_schedule_wrapper#(
        .MAX_QP             ( MAX_QP             ),
        .QP_PTR_WIDTH       ( QP_PTR_WIDTH       )
    )u_wqe_read_schedule_wrapper(
        .clk                ( clk                ),
        .rst_n              ( rst_n              ),
        .i_wqe_cache_alfull ( wqe_cache_alfull   ),
        .i_wqe_fetch_ready  ( wqe_fetch_ready    ),
        .i_active           ( i_active           ),
        .o_arbit_val        ( arbit_val          ),
        .o_qp_idx           ( qp_idx             ),
        .o_qp_idx_one_hot   ( qp_idx_one_hot     )
    );

    wqe_fetch#(
        .MAX_QP             ( MAX_QP             ),
        .QP_PTR_WIDTH       ( QP_PTR_WIDTH       ),
        .SQ_DEPTH           ( SQ_DEPTH           ),
        .WQE_WIDTH          ( WQE_WIDTH          ),
        .SQ_PTR_WIDTH       ( SQ_PTR_WIDTH       ),
        .AXI_DATA_WIDTH     ( AXI_DATA_WIDTH     ),
        .AXI_ADDR_WIDTH     ( AXI_ADDR_WIDTH     ),
        .AXI_ID_WIDTH       ( AXI_ID_WIDTH       )
    )u_wqe_fetch(
        .clk                ( clk                ),
        .rst_n              ( rst_n              ),
        .i_active           ( i_active           ),
        .o_wqe_fetch_ready  ( wqe_fetch_ready    ),
        .i_arbit_val        ( arbit_val          ),
        .i_qp_idx           ( qp_idx             ),
        .i_qp_idx_one_hot   ( qp_idx_one_hot     ),
        .i_sq_base          ( i_sq_base          ),
        .i_wqe_cache_alfull ( wqe_cache_alfull   ),
        .i_wqe_cache_full   ( wqe_cache_full     ),
        .o_wqe_cache_wr     ( wqe_cache_wr       ),
        .o_wqe              ( wqe_wr             ),
        .m_axi_awid         ( m_axi_awid         ),
        .m_axi_awaddr       ( m_axi_awaddr       ),
        .m_axi_awlen        ( m_axi_awlen        ),
        .m_axi_awsize       ( m_axi_awsize       ),
        .m_axi_awburst      ( m_axi_awburst      ),
        .m_axi_awlock       ( m_axi_awlock       ),
        .m_axi_awcache      ( m_axi_awcache      ),
        .m_axi_awprot       ( m_axi_awprot       ),
        .m_axi_awvalid      ( m_axi_awvalid      ),
        .m_axi_awready      ( m_axi_awready      ),
        .m_axi_wdata        ( m_axi_wdata        ),
        .m_axi_wstrb        ( m_axi_wstrb        ),
        .m_axi_wlast        ( m_axi_wlast        ),
        .m_axi_wvalid       ( m_axi_wvalid       ),
        .m_axi_wready       ( m_axi_wready       ),
        .m_axi_bid          ( m_axi_bid          ),
        .m_axi_bresp        ( m_axi_bresp        ),
        .m_axi_bvalid       ( m_axi_bvalid       ),
        .m_axi_bready       ( m_axi_bready       ),
        .m_axi_arid         ( m_axi_arid         ),
        .m_axi_araddr       ( m_axi_araddr       ),
        .m_axi_arlen        ( m_axi_arlen        ),
        .m_axi_arsize       ( m_axi_arsize       ),
        .m_axi_arburst      ( m_axi_arburst      ),
        .m_axi_arlock       ( m_axi_arlock       ),
        .m_axi_arcache      ( m_axi_arcache      ),
        .m_axi_arprot       ( m_axi_arprot       ),
        .m_axi_arvalid      ( m_axi_arvalid      ),
        .m_axi_arready      ( m_axi_arready      ),
        .m_axi_rid          ( m_axi_rid          ),
        .m_axi_rdata        ( m_axi_rdata        ),
        .m_axi_rresp        ( m_axi_rresp        ),
        .m_axi_rlast        ( m_axi_rlast        ),
        .m_axi_rvalid       ( m_axi_rvalid       ),
        .m_axi_rready       ( m_axi_rready       )
    );

    wqe_cache#(
        .WQE_WIDTH          ( WQE_WIDTH          ),
        .QP_PTR_WIDTH       ( QP_PTR_WIDTH       ),
        .PWQE_SLOT_NUM      ( PWQE_SLOT_NUM      )
    )u_wqe_cache(
        .clk                ( clk                ),
        .rst_n              ( rst_n              ),
        .i_wqe_cache_wr     ( wqe_cache_wr       ),
        .i_wqe              ( wqe_wr             ),
        .o_wqe_cache_alfull ( wqe_cache_alfull   ),
        .o_wqe_cache_full   ( wqe_cache_full     ),
        .o_ls_wqe_empty     ( ls_wqe_empty       ),
        .i_ls_wqe_ren       ( ls_wqe_ren         ),
        .o_ls_wqe_rdata     ( ls_wqe_rdata       ),
        .o_bs_fifo_empty    ( bs_fifo_empty      ),
        .i_bs_fifo_rd       ( bs_fifo_rd         ),
        .o_bs_wqe_val       ( bs_wqe_val         ),
        .o_bs_wqe           ( bs_wqe             ),
        .o_wqe_cache_wr_val ( o_wqe_cache_wr_val ),
        .o_wqe_cache_wr_qpn ( o_wqe_cache_wr_qpn ),
        .o_wqe_cache_wr_wrid( o_wqe_cache_wr_wrid)
    );

    station_writer#(
        .WQE_WIDTH            ( WQE_WIDTH            ),
        .PWQE_BUF_ADDR_WIDTH  ( PWQE_BUF_ADDR_WIDTH  ),
        .PWQE_BUF_WIDTH       ( PWQE_BUF_WIDTH       ),
        .PWQE_SLOT_NUM        ( PWQE_SLOT_NUM        ),
        .PWQE_SLOT_ADDR_WIDTH ( PWQE_SLOT_ADDR_WIDTH )
    )u_station_writer(
        .clk                 ( clk                 ),
        .rst_n               ( rst_n               ),
        .i_bs_fifo_empty     ( bs_fifo_empty       ),
        .o_bs_fifo_rd        ( bs_fifo_rd          ),
        .i_bs_wqe_val        ( bs_wqe_val          ),
        .i_bs_wqe            ( bs_wqe              ),
        .o_ren_0             ( ren_0               ),
        .o_wen_0             ( wen_0               ),
        .o_addr_0            ( addr_0              ),
        .o_din_0             ( din_0               ),
        .o_set_req           ( set_req             ),
        .o_set_addr          ( set_addr            ),
        .i_slot_status       ( slot_status         )
    );


    station_buffer#(
        .PWQE_BUF_ADDR_WIDTH  ( PWQE_BUF_ADDR_WIDTH  ),
        .PWQE_BUF_WIDTH       ( PWQE_BUF_WIDTH       ),
        .PWQE_SLOT_NUM        ( PWQE_SLOT_NUM        ),
        .PWQE_SLOT_ADDR_WIDTH ( PWQE_SLOT_ADDR_WIDTH )
    )u_station_buffer(
        .clk                  ( clk                  ),
        .rst_n                ( rst_n                ),
        .i_ren_0              ( ren_0                ),
        .i_wen_0              ( wen_0                ),
        .i_addr_0             ( addr_0               ),
        .i_din_0              ( din_0                ),
        .i_set_req            ( set_req              ),
        .i_set_addr           ( set_addr             ),
        .i_ren_1              ( ren_1                ),
        .i_wen_1              ( wen_1                ),
        .i_addr_1             ( addr_1               ),
        .i_din_1              ( din_1                ),
        .o_dout_1             ( dout_1               ),
        .o_slot_status        ( slot_status          ),
        .i_reset_req          ( reset_req            ),
        .i_reset_addr         ( reset_addr           )
    );


    grp_scheduler#(
        .WQE_WIDTH           ( WQE_WIDTH           ),
        .PWQE_SLOT_NUM       ( PWQE_SLOT_NUM       ),
        .PWQE_BUF_ADDR_WIDTH ( PWQE_BUF_ADDR_WIDTH ),
        .PWQE_BUF_WIDTH      ( PWQE_BUF_WIDTH      )
    )u_grp_scheduler(
        .clk                 ( clk                 ),
        .rst_n               ( rst_n               ),
        // if* with wqe_cache
        .i_ls_wqe_empty      ( ls_wqe_empty        ),
        .o_ls_wqe_ren        ( ls_wqe_ren          ),
        .i_ls_wqe_rdata      ( ls_wqe_rdata        ),
        .o_ren_1             ( ren_1               ),
        .o_wen_1             ( wen_1               ),
        .o_addr_1            ( addr_1              ),
        .o_din_1             ( din_1               ),
        .i_dout_1            ( dout_1              ),
        .i_slot_status       ( slot_status         ),
        .o_wqe_cache_empty   ( wqe_cache_empty     ),
        .i_wqe_cache_rd      ( wqe_cache_rd        ),
        .o_wqe_val           ( wqe_val             ),
        .o_wqe_type          ( wqe_type            ),
        .o_wqe_addr          ( wqe_addr            ),
        .o_wqe               ( wqe_rd              ),
        .i_pwqe_wb           ( pwqe_wb             ),
        .i_pwqe_addr         ( pwqe_addr           ),
        .i_pwqe              ( pwqe                )
    );


    assign o_ibt_wqe_val = wqe_val;
    assign o_ibt_wqe = wqe_rd;
    ib_transport#(
        .WQE_WIDTH               ( WQE_WIDTH              ),
        .ETH_MAC_WIDTH           ( ETH_MAC_WIDTH          ),
        .IPV6_WIDTH              ( IPV6_WIDTH             ),
        .UDP_PORT_WIDTH          ( UDP_PORT_WIDTH         ),
        .QP_PTR_WIDTH            ( QP_PTR_WIDTH           ),
        .IB_PKEY_WIDTH           ( IB_PKEY_WIDTH          ),
        .IB_PMTU_CODE_WIDTH      ( IB_PMTU_CODE_WIDTH     ),
        .IB_QP_WIDTH             ( IB_QP_WIDTH            ),
        .IP_TTL_WIDTH            ( IP_TTL_WIDTH           ),
        .IP_DSCP_WDITH           ( IP_DSCP_WDITH          ),
        .IB_PSN_WIDTH            ( IB_PSN_WIDTH           ),
        .PKT_DESC_WIDTH          ( PKT_DESC_WIDTH         ),
        .PKT_DESC_HDR_LEN_WIDTH  ( PKT_DESC_HDR_LEN_WIDTH ),
        .PWQE_BUF_ADDR_WIDTH     ( PWQE_BUF_ADDR_WIDTH    )
    )u_ib_transport(
        .clk                     ( clk                     ),
        .rst_n                   ( rst_n                   ),
        .i_wqe_cache_empty       ( wqe_cache_empty         ),
        .o_wqe_cache_rd          ( wqe_cache_rd            ),
        .i_wqe_val               ( wqe_val                 ),
        .i_wqe_type              ( wqe_type                ),
        .i_wqe_addr              ( wqe_addr                ),
        .i_wqe                   ( wqe_rd                  ),
        .o_pwqe_wb               ( pwqe_wb                 ),
        .o_pwqe_addr             ( pwqe_addr               ),
        .o_pwqe                  ( pwqe                    ),
        .o_reset_req             ( reset_req               ),
        .o_reset_addr            ( reset_addr              ),
        .i_rnic_src_mac          ( i_rnic_src_mac          ),
        .i_rnic_src_ip           ( i_rnic_src_ip           ),
        .i_rnic_src_port         ( i_rnic_src_port         ),
        .o_qpc_hdr_lookup_valid  ( o_qpc_hdr_lookup_valid  ),
        .i_qpc_hdr_lookup_ready  ( i_qpc_hdr_lookup_ready  ),
        .o_qpc_hdr_lookup_qp_id  ( o_qpc_hdr_lookup_qp_id  ),
        .i_qpc_valid             ( i_qpc_valid             ),
        .i_qpc_pkey              ( i_qpc_pkey              ),
        .i_qpc_pmtu              ( i_qpc_pmtu              ),
        .i_qpc_dest_qpid         ( i_qpc_dest_qpid         ),
        .i_qpc_sq_curr_psn       ( i_qpc_sq_curr_psn       ),
        .i_qpc_sq_curr_msn       ( i_qpc_sq_curr_msn       ),
        .i_qpc_dest_ip           ( i_qpc_dest_ip           ),
        .i_qpc_ttl               ( i_qpc_ttl               ),
        .i_qpc_dscp              ( i_qpc_dscp              ),
        .i_qpc_dest_mac          ( i_qpc_dest_mac          ),
        .o_qpc_hdr_update_valid  ( o_qpc_hdr_update_valid  ),
        .o_qpc_hdr_update_qpid   ( o_qpc_hdr_update_qpid   ),
        .o_qpc_sq_curr_psn       ( o_qpc_sq_curr_psn       ),
        .o_qpc_sq_curr_msn       ( o_qpc_sq_curr_msn       ),
        .o_pkt_desc_valid        ( o_pkt_desc_valid        ),
        .i_pkt_desc_ready        ( i_pkt_desc_ready        ),
        .o_pkt_desc_hdr_len      ( o_pkt_desc_hdr_len      ),
        .o_pkt_desc              ( o_pkt_desc              ),
        .o_final                 ( o_final                 ),
        .o_qpn                   ( o_qpn                   ),
        .o_wr_id                 ( o_wr_id                 )
    );


endmodule