//-- tbench.sv: Testbench
//-- Copyright (C) 2023 CESNET z. s. p. o.
//-- Author:   Daniel Kříž <xkrizd01@vutbr.cz>

//-- SPDX-License-Identifier: BSD-3-Clause

import uvm_pkg::*;
`include "uvm_macros.svh"
import test::*;

module testbench;

    // -------------------------------------------------------------------------------------------------------------------------------------------------------------------
    localparam HDR_WIDTH       = 128;
    localparam PREFIX_WIDTH    = 32;
    localparam BAR_RANGE_WIDTH = 3;
    // Signals
    logic PCIE_SYSCLK_P = '0;
    logic PCIE_SYSCLK_N = '0;
    logic PCIE_USER_CLK = '0;
    logic [PCIE_CONS*PCIE_CLKS-1 : 0] pcie_sysclk_p_logic;
    logic [PCIE_CONS*PCIE_CLKS-1 : 0] pcie_sysclk_n_logic;
    logic [PCIE_ENDPOINTS-1 : 0]      pcie_user_clk_logic;
    logic [PCIE_ENDPOINTS-1 : 0]      pcie_user_reset_logic;
    logic [PCIE_CONS-1 : 0]           pcie_sysrst_n_logic;
    logic INIT_DONE_N = 1;
    logic DMA_CLK = 0;
    logic MI_CLK = 0;

    logic [CQ_MFB_REGIONS*HDR_WIDTH      -1 : 0] down_hdr[PCIE_CONS]      ;
    logic [CQ_MFB_REGIONS*PREFIX_WIDTH   -1 : 0] down_prefix[PCIE_CONS]   ;
    logic [CQ_MFB_REGIONS*BAR_RANGE_WIDTH-1 : 0] down_bar_range[PCIE_CONS];

    logic [PCIE_ENDPOINTS*CQ_MFB_REGIONS*CQ_MFB_REGION_SIZE*CQ_MFB_BLOCK_SIZE*CQ_MFB_ITEM_WIDTH-1 : 0] dma_avst_down_data ;
    logic [PCIE_ENDPOINTS*CQ_MFB_REGIONS                                                       -1 : 0] dma_avst_down_sop  ;
    logic [PCIE_ENDPOINTS*CQ_MFB_REGIONS                                                       -1 : 0] dma_avst_down_eop  ;
    logic [PCIE_ENDPOINTS*CQ_MFB_REGIONS*$clog2(RQ_MFB_REGION_SIZE*RQ_MFB_BLOCK_SIZE)          -1 : 0] dma_avst_down_empty;
    logic [PCIE_ENDPOINTS                                                                      -1 : 0] dma_avst_down_ready;
    logic [PCIE_ENDPOINTS*CQ_MFB_REGIONS                                                       -1 : 0] dma_avst_down_valid;

    logic [PCIE_ENDPOINTS*CC_MFB_REGIONS*HDR_WIDTH                                                                 -1: 0] up_hdr[PCIE_CONS];
    logic [PCIE_ENDPOINTS*CC_MFB_REGIONS*PREFIX_WIDTH                                                              -1: 0] up_prefix[PCIE_CONS];
    logic [PCIE_ENDPOINTS*CC_MFB_REGIONS                                                                           -1: 0] up_error[PCIE_CONS];

    // -------------------------------------------------------------------------------------------------------------------------------------------------------------------
    // Interfaces
    reset_if  pcie_user_reset[PCIE_ENDPOINTS](PCIE_USER_CLK);
    reset_if  pcie_sysrst_n[PCIE_CONS](PCIE_SYSCLK_N);
    reset_if  mi_reset(MI_CLK);
    reset_if  dma_reset(DMA_CLK);
    // For Intel (AVALON)
    avst_if #(CQ_MFB_REGIONS, CQ_MFB_REGION_SIZE, CQ_MFB_BLOCK_SIZE, CQ_MFB_ITEM_WIDTH, AVST_DOWN_META_W) avst_down[PCIE_ENDPOINTS](PCIE_USER_CLK);
    avst_if #(CC_MFB_REGIONS, CC_MFB_REGION_SIZE, CC_MFB_BLOCK_SIZE, CC_MFB_ITEM_WIDTH, AVST_UP_META_W)   avst_up[PCIE_ENDPOINTS](PCIE_USER_CLK);
    // For Xilinx (AXI)
    axi_if #(AXI_DATA_WIDTH, AXI_CQUSER_WIDTH) cq_axi[PCIE_ENDPOINTS](PCIE_USER_CLK);
    axi_if #(AXI_DATA_WIDTH, AXI_CCUSER_WIDTH) cc_axi[PCIE_ENDPOINTS](PCIE_USER_CLK);
    axi_if #(AXI_DATA_WIDTH, AXI_RCUSER_WIDTH) rc_axi[PCIE_ENDPOINTS](PCIE_USER_CLK);
    axi_if #(AXI_DATA_WIDTH, AXI_RQUSER_WIDTH) rq_axi[PCIE_ENDPOINTS](PCIE_USER_CLK);
    // For Intel and Xilinx (MFB)
    mfb_if #(RQ_MFB_REGIONS, RQ_MFB_REGION_SIZE, RQ_MFB_BLOCK_SIZE, RQ_MFB_ITEM_WIDTH, RQ_MFB_META_W)  dma_rq_mfb[DMA_PORTS](DMA_CLK);
    mvb_if #(RQ_MFB_REGIONS, DMA_UPHDR_WIDTH_W)                                                        dma_rq_mvb[DMA_PORTS](DMA_CLK);
    mfb_if #(RC_MFB_REGIONS, RC_MFB_REGION_SIZE, RC_MFB_BLOCK_SIZE, RC_MFB_ITEM_WIDTH, RC_MFB_META_W)  dma_rc_mfb[DMA_PORTS](DMA_CLK);
    mvb_if #(RC_MFB_REGIONS, DMA_DOWNHDR_WIDTH_W)                                                      dma_rc_mvb[DMA_PORTS](DMA_CLK);

    mfb_if #(CC_MFB_REGIONS, CQ_MFB_REGION_SIZE, CQ_MFB_BLOCK_SIZE, CQ_MFB_ITEM_WIDTH, CQ_MFB_META_W)  dma_cq_mfb[DMA_PORTS](DMA_CLK);
    mfb_if #(CC_MFB_REGIONS, CC_MFB_REGION_SIZE, CC_MFB_BLOCK_SIZE, CC_MFB_ITEM_WIDTH, CC_MFB_META_W)  dma_cc_mfb[DMA_PORTS](DMA_CLK);
    mi_if  #(32, 32) config_mi[PCIE_ENDPOINTS] (MI_CLK);
    // -------------------------------------------------------------------------------------------------------------------------------------------------------------------
    // Define clock period
    always #(PCIE_SYSCLK_CLK_PERIOD) PCIE_SYSCLK_P = ~PCIE_SYSCLK_P;
    always #(PCIE_SYSCLK_CLK_PERIOD) PCIE_SYSCLK_N = ~PCIE_SYSCLK_N;
    always #(DMA_CLK_PERIOD) PCIE_USER_CLK         = ~PCIE_USER_CLK;
    always #(DMA_CLK_PERIOD) DMA_CLK               = ~DMA_CLK;
    always #(MI_CLK_PERIOD) MI_CLK                 = ~MI_CLK;

    for (genvar pcie_e = 0; pcie_e < PCIE_ENDPOINTS; pcie_e++) begin
        assign pcie_user_reset[pcie_e].RESET = pcie_user_reset_logic[pcie_e];
    end

    for (genvar pcie_clks = 0; pcie_clks < PCIE_CONS*PCIE_CLKS; pcie_clks++) begin
        assign pcie_sysclk_p_logic[pcie_clks] = PCIE_SYSCLK_P;
        assign pcie_sysclk_n_logic[pcie_clks] = PCIE_SYSCLK_N;
    end
    for (genvar pcie_c = 0; pcie_c < PCIE_CONS; pcie_c++) begin
        assign pcie_sysrst_n_logic[pcie_c] = pcie_sysrst_n[pcie_c].RESET;
        // assign INIT_DONE_N = !pcie_sysrst_n[pcie_c].RESET;
    end

    // -------------------------------------------------------------------------------------------------------------------------------------------------------------------
    // Start of tests
    initial begin
        uvm_root m_root;

        // AVALON interface
        automatic virtual avst_if #(CQ_MFB_REGIONS, CQ_MFB_REGION_SIZE, CQ_MFB_BLOCK_SIZE, CQ_MFB_ITEM_WIDTH, AVST_DOWN_META_W) v_avst_down[PCIE_ENDPOINTS] = avst_down;
        automatic virtual avst_if #(CC_MFB_REGIONS, CC_MFB_REGION_SIZE, CC_MFB_BLOCK_SIZE, CC_MFB_ITEM_WIDTH, AVST_UP_META_W) v_avst_up[PCIE_ENDPOINTS] = avst_up;

        // DMA
        automatic virtual mfb_if #(RQ_MFB_REGIONS, RQ_MFB_REGION_SIZE, RQ_MFB_BLOCK_SIZE, RQ_MFB_ITEM_WIDTH, RQ_MFB_META_W) v_rq_mfb[DMA_PORTS]               = dma_rq_mfb;
        automatic virtual mvb_if #(RQ_MFB_REGIONS, DMA_UPHDR_WIDTH_W)                                                       v_rq_mvb[DMA_PORTS]               = dma_rq_mvb;
        automatic virtual mfb_if #(RC_MFB_REGIONS, RC_MFB_REGION_SIZE, RC_MFB_BLOCK_SIZE, RC_MFB_ITEM_WIDTH, RC_MFB_META_W) v_rc_mfb[DMA_PORTS]               = dma_rc_mfb;
        automatic virtual mvb_if #(RC_MFB_REGIONS, DMA_DOWNHDR_WIDTH_W)                                                     v_rc_mvb[DMA_PORTS]               = dma_rc_mvb;

        automatic virtual mfb_if #(CQ_MFB_REGIONS, CQ_MFB_REGION_SIZE, CQ_MFB_BLOCK_SIZE, CQ_MFB_ITEM_WIDTH, CQ_MFB_META_W) v_cq_mfb[DMA_PORTS]               = dma_cq_mfb;
        automatic virtual mfb_if #(CC_MFB_REGIONS, CC_MFB_REGION_SIZE, CC_MFB_BLOCK_SIZE, CC_MFB_ITEM_WIDTH, CC_MFB_META_W) v_cc_mfb[DMA_PORTS]               = dma_cc_mfb;

        // AXI
        automatic virtual axi_if #(AXI_DATA_WIDTH, AXI_CQUSER_WIDTH)                                                        v_cq_axi[DMA_PORTS]               = cq_axi;
        automatic virtual axi_if #(AXI_DATA_WIDTH, AXI_CCUSER_WIDTH)                                                        v_cc_axi[DMA_PORTS]               = cc_axi;
        automatic virtual axi_if #(AXI_DATA_WIDTH, AXI_RCUSER_WIDTH)                                                        v_rc_axi[DMA_PORTS]               = rc_axi;
        automatic virtual axi_if #(AXI_DATA_WIDTH, AXI_RQUSER_WIDTH)                                                        v_rq_axi[DMA_PORTS]               = rq_axi;

        automatic virtual mi_if #(32, 32)                                                                                   v_mi_config[PCIE_ENDPOINTS]       = config_mi;
        automatic virtual reset_if                                                                                          v_pcie_user_reset[PCIE_ENDPOINTS] = pcie_user_reset;
        automatic virtual reset_if                                                                                          v_pcie_sysrst_n[PCIE_CONS]        = pcie_sysrst_n;

        for (int dma = 0; dma < DMA_PORTS; dma++) begin
            string i_string;
            i_string.itoa(dma);
            uvm_config_db#(virtual mfb_if #(RQ_MFB_REGIONS, RQ_MFB_REGION_SIZE, RQ_MFB_BLOCK_SIZE, RQ_MFB_ITEM_WIDTH, RQ_MFB_META_W))::set(null, "", {"vif_rq_mfb_",i_string}, v_rq_mfb[dma]);
            uvm_config_db#(virtual mvb_if #(RQ_MFB_REGIONS, DMA_UPHDR_WIDTH_W))::set(null, "", {"vif_rq_mvb_",i_string}, v_rq_mvb[dma]);
            uvm_config_db#(virtual mfb_if #(RC_MFB_REGIONS, RC_MFB_REGION_SIZE, RC_MFB_BLOCK_SIZE, RC_MFB_ITEM_WIDTH, RC_MFB_META_W))::set(null, "", {"vif_rc_mfb_",i_string}, v_rc_mfb[dma]);
            uvm_config_db#(virtual mvb_if #(RC_MFB_REGIONS, DMA_DOWNHDR_WIDTH_W))::set(null, "", {"vif_rc_mvb_",i_string}, v_rc_mvb[dma]);

            uvm_config_db#(virtual mfb_if #(CQ_MFB_REGIONS, CQ_MFB_REGION_SIZE, CQ_MFB_BLOCK_SIZE, CQ_MFB_ITEM_WIDTH, CQ_MFB_META_W))::set(null, "", {"vif_cq_mfb_",i_string}, v_cq_mfb[dma]);
            uvm_config_db#(virtual mfb_if #(CC_MFB_REGIONS, CC_MFB_REGION_SIZE, CC_MFB_BLOCK_SIZE, CC_MFB_ITEM_WIDTH, CC_MFB_META_W))::set(null, "", {"vif_cc_mfb_",i_string}, v_cc_mfb[dma]);
        end

        for (int unsigned pcie_e = 0; pcie_e < PCIE_ENDPOINTS; pcie_e++) begin
            string i_string;
            i_string.itoa(pcie_e);
            uvm_config_db#(virtual mi_if #(32, 32))::set(null, "", {"vif_mi_",i_string}, v_mi_config[pcie_e]);
            uvm_config_db#(virtual reset_if)::set(null, "", {"vif_pcie_user_reset_",i_string}, v_pcie_user_reset[pcie_e]);
            uvm_config_db#(virtual reset_if)::set(null, "", {"vif_pcie_sysrst_n_",i_string}, v_pcie_sysrst_n[pcie_e]);
            uvm_config_db#(virtual avst_if #(CQ_MFB_REGIONS, CQ_MFB_REGION_SIZE, CQ_MFB_BLOCK_SIZE, CQ_MFB_ITEM_WIDTH, AVST_DOWN_META_W))::set(null, "", {"vif_avst_down_", i_string}, v_avst_down[pcie_e]);
            uvm_config_db#(virtual avst_if #(CC_MFB_REGIONS, CC_MFB_REGION_SIZE, CC_MFB_BLOCK_SIZE, CC_MFB_ITEM_WIDTH, AVST_UP_META_W))::set(null, "", {"vif_avst_up_", i_string}, v_avst_up[pcie_e]);

            // AXI
            uvm_config_db#(virtual axi_if #(AXI_DATA_WIDTH, AXI_CQUSER_WIDTH))::set(null, "", {"vif_cq_axi_",i_string}, v_cq_axi[pcie_e]);
            uvm_config_db#(virtual axi_if #(AXI_DATA_WIDTH, AXI_CCUSER_WIDTH))::set(null, "", {"vif_cc_axi_",i_string}, v_cc_axi[pcie_e]);
            uvm_config_db#(virtual axi_if #(AXI_DATA_WIDTH, AXI_RCUSER_WIDTH))::set(null, "", {"vif_rc_axi_",i_string}, v_rc_axi[pcie_e]);
            uvm_config_db#(virtual axi_if #(AXI_DATA_WIDTH, AXI_RQUSER_WIDTH))::set(null, "", {"vif_rq_axi_",i_string}, v_rq_axi[pcie_e]);
        end

        uvm_config_db#(virtual reset_if)::set(null, "", "vif_dma_reset", dma_reset);
        uvm_config_db#(virtual reset_if)::set(null, "", "vif_mi_reset", mi_reset);

        m_root = uvm_root::get();
        m_root.finish_on_completion = 0;
        m_root.set_report_id_action_hier("ILLEGALNAME",UVM_NO_ACTION);

        uvm_config_db#(int)            ::set(null, "", "recording_detail", 0);
        uvm_config_db#(uvm_bitstream_t)::set(null, "", "recording_detail", 0);

        run_test();
        $stop(2);
    end

    // -------------------------------------------------------------------------------------------------------------------------------------------------------------------
    // DUT
    DUT DUT_U (
        .PCIE_SYSCLK_P   (pcie_sysclk_p_logic),
        .PCIE_SYSCLK_N   (pcie_sysclk_n_logic),
        .PCIE_USER_CLK   (pcie_user_clk_logic),
        .PCIE_USER_RESET (pcie_user_reset_logic),
        .PCIE_SYSRST_N   (pcie_sysrst_n_logic),
        .INIT_DONE_N     (INIT_DONE_N),
        .DMA_CLK         (DMA_CLK),
        .DMA_RESET       (dma_reset.RESET),
        .MI_CLK          (MI_CLK),
        .MI_RESET        (mi_reset.RESET),
        .dma_rq_mfb      (dma_rq_mfb),
        .dma_rq_mvb      (dma_rq_mvb),
        .dma_rc_mfb      (dma_rc_mfb),
        .dma_rc_mvb      (dma_rc_mvb),
        .dma_cq_mfb      (dma_cq_mfb),
        .dma_cc_mfb      (dma_cc_mfb),
        .config_mi       (config_mi)
    );

    // -------------------------------------------------------------------------------------------------------------------------------------------------------------------
    // GRAY BOX CONNECTION
    generate
        for (genvar pcie_e = 0; pcie_e < PCIE_ENDPOINTS; pcie_e++) begin

            assign DUT_U.VHDL_DUT_U.pcie_core_i.pcie_hip_clk[pcie_e] = PCIE_USER_CLK;

            if (IS_INTEL_DEV) begin

                assign DUT_U.VHDL_DUT_U.pcie_core_i.pcie_link_up_comb[pcie_e]  = '1;

                for (genvar pcie_r = 0; pcie_r < CQ_MFB_REGIONS; pcie_r++) begin
                    assign down_hdr      [pcie_e] [(pcie_r+1)*HDR_WIDTH      -1 -: HDR_WIDTH]       = avst_down[pcie_e].META[pcie_r*AVST_DOWN_META_W + HDR_WIDTH                                 -1 -: HDR_WIDTH];
                    assign down_prefix   [pcie_e] [(pcie_r+1)*PREFIX_WIDTH   -1 -: PREFIX_WIDTH]    = avst_down[pcie_e].META[pcie_r*AVST_DOWN_META_W + HDR_WIDTH + PREFIX_WIDTH                  -1 -: PREFIX_WIDTH];
                    assign down_bar_range[pcie_e] [(pcie_r+1)*BAR_RANGE_WIDTH-1 -: BAR_RANGE_WIDTH] = avst_down[pcie_e].META[pcie_r*AVST_DOWN_META_W + HDR_WIDTH + PREFIX_WIDTH + BAR_RANGE_WIDTH-1 -: BAR_RANGE_WIDTH];
                end
                for (genvar pcie_r = 0; pcie_r < CC_MFB_REGIONS; pcie_r++) begin
                    assign avst_up[pcie_e].META[pcie_r*AVST_UP_META_W + HDR_WIDTH                   -1 -: HDR_WIDTH]    = up_hdr   [pcie_e] [(pcie_r+1)*HDR_WIDTH      -1 -: HDR_WIDTH];
                    assign avst_up[pcie_e].META[pcie_r*AVST_UP_META_W + HDR_WIDTH + PREFIX_WIDTH    -1 -: PREFIX_WIDTH] = up_prefix[pcie_e] [(pcie_r+1)*PREFIX_WIDTH   -1 -: PREFIX_WIDTH];
                    assign avst_up[pcie_e].META[pcie_r*AVST_UP_META_W + HDR_WIDTH + PREFIX_WIDTH + 1-1 -: 1]            = up_error [pcie_e] [(pcie_r+1)*1              -1 -: 1];
                end

                assign DUT_U.VHDL_DUT_U.pcie_core_i.pcie_adapter_g[pcie_e].pcie_adapter_i.AVST_DOWN_DATA      = avst_down[pcie_e].DATA;
                assign DUT_U.VHDL_DUT_U.pcie_core_i.pcie_adapter_g[pcie_e].pcie_adapter_i.AVST_DOWN_SOP       = avst_down[pcie_e].SOP;
                assign DUT_U.VHDL_DUT_U.pcie_core_i.pcie_adapter_g[pcie_e].pcie_adapter_i.AVST_DOWN_EOP       = avst_down[pcie_e].EOP;
                assign DUT_U.VHDL_DUT_U.pcie_core_i.pcie_adapter_g[pcie_e].pcie_adapter_i.AVST_DOWN_EMPTY     = avst_down[pcie_e].EMPTY;
                assign DUT_U.VHDL_DUT_U.pcie_core_i.pcie_adapter_g[pcie_e].pcie_adapter_i.AVST_DOWN_VALID     = avst_down[pcie_e].VALID;
                assign DUT_U.VHDL_DUT_U.pcie_core_i.pcie_adapter_g[pcie_e].pcie_adapter_i.AVST_DOWN_HDR       = down_hdr[pcie_e];
                assign DUT_U.VHDL_DUT_U.pcie_core_i.pcie_adapter_g[pcie_e].pcie_adapter_i.AVST_DOWN_PREFIX    = down_prefix[pcie_e];
                assign DUT_U.VHDL_DUT_U.pcie_core_i.pcie_adapter_g[pcie_e].pcie_adapter_i.AVST_DOWN_BAR_RANGE = down_bar_range[pcie_e];
                assign avst_down[pcie_e].READY = DUT_U.VHDL_DUT_U.pcie_core_i.pcie_adapter_g[pcie_e].pcie_adapter_i.AVST_DOWN_READY;

                assign avst_up[pcie_e].DATA  = DUT_U.VHDL_DUT_U.pcie_core_i.pcie_adapter_g[pcie_e].pcie_adapter_i.AVST_UP_DATA;
                assign avst_up[pcie_e].SOP   = DUT_U.VHDL_DUT_U.pcie_core_i.pcie_adapter_g[pcie_e].pcie_adapter_i.AVST_UP_SOP;
                assign avst_up[pcie_e].EOP   = DUT_U.VHDL_DUT_U.pcie_core_i.pcie_adapter_g[pcie_e].pcie_adapter_i.AVST_UP_EOP;
                assign avst_up[pcie_e].VALID = DUT_U.VHDL_DUT_U.pcie_core_i.pcie_adapter_g[pcie_e].pcie_adapter_i.AVST_UP_VALID;
                assign up_hdr[pcie_e]        = DUT_U.VHDL_DUT_U.pcie_core_i.pcie_adapter_g[pcie_e].pcie_adapter_i.AVST_UP_HDR;
                assign up_prefix[pcie_e]     = DUT_U.VHDL_DUT_U.pcie_core_i.pcie_adapter_g[pcie_e].pcie_adapter_i.AVST_UP_PREFIX;
                assign up_error[pcie_e]      = DUT_U.VHDL_DUT_U.pcie_core_i.pcie_adapter_g[pcie_e].pcie_adapter_i.AVST_UP_ERROR;
                assign DUT_U.VHDL_DUT_U.pcie_core_i.pcie_avst_up_ready[pcie_e] = avst_up[pcie_e].READY;

                assign avst_up[pcie_e].EMPTY = '0;
            end else begin
                assign DUT_U.VHDL_DUT_U.pcie_core_i.cfg_phy_link_status[pcie_e][0]  = 1'b1;
                assign DUT_U.VHDL_DUT_U.pcie_core_i.cfg_phy_link_status[pcie_e][1]  = 1'b1;

                assign DUT_U.VHDL_DUT_U.pcie_core_i.pcie_adapter_g[pcie_e].pcie_adapter_i.CQ_AXI_DATA  = cq_axi[pcie_e].TDATA;
                assign DUT_U.VHDL_DUT_U.pcie_core_i.pcie_adapter_g[pcie_e].pcie_adapter_i.CQ_AXI_USER  = cq_axi[pcie_e].TUSER;
                assign DUT_U.VHDL_DUT_U.pcie_core_i.pcie_adapter_g[pcie_e].pcie_adapter_i.CQ_AXI_LAST  = cq_axi[pcie_e].TLAST;
                assign DUT_U.VHDL_DUT_U.pcie_core_i.pcie_adapter_g[pcie_e].pcie_adapter_i.CQ_AXI_KEEP  = cq_axi[pcie_e].TKEEP;
                assign DUT_U.VHDL_DUT_U.pcie_core_i.pcie_adapter_g[pcie_e].pcie_adapter_i.CQ_AXI_VALID = cq_axi[pcie_e].TVALID;
                assign cq_axi[pcie_e].TREADY = DUT_U.VHDL_DUT_U.pcie_core_i.pcie_adapter_g[pcie_e].pcie_adapter_i.CQ_AXI_READY;

                assign DUT_U.VHDL_DUT_U.pcie_core_i.pcie_adapter_g[pcie_e].pcie_adapter_i.RC_AXI_DATA  = rc_axi[pcie_e].TDATA;
                assign DUT_U.VHDL_DUT_U.pcie_core_i.pcie_adapter_g[pcie_e].pcie_adapter_i.RC_AXI_USER  = rc_axi[pcie_e].TUSER;
                assign DUT_U.VHDL_DUT_U.pcie_core_i.pcie_adapter_g[pcie_e].pcie_adapter_i.RC_AXI_LAST  = rc_axi[pcie_e].TLAST;
                assign DUT_U.VHDL_DUT_U.pcie_core_i.pcie_adapter_g[pcie_e].pcie_adapter_i.RC_AXI_KEEP  = rc_axi[pcie_e].TKEEP;
                assign DUT_U.VHDL_DUT_U.pcie_core_i.pcie_adapter_g[pcie_e].pcie_adapter_i.RC_AXI_VALID = rc_axi[pcie_e].TVALID;
                assign rc_axi[pcie_e].TREADY = DUT_U.VHDL_DUT_U.pcie_core_i.pcie_adapter_g[pcie_e].pcie_adapter_i.RC_AXI_READY;

                assign cc_axi[pcie_e].TDATA  = DUT_U.VHDL_DUT_U.pcie_core_i.pcie_adapter_g[pcie_e].pcie_adapter_i.CC_AXI_DATA;
                assign cc_axi[pcie_e].TUSER  = DUT_U.VHDL_DUT_U.pcie_core_i.pcie_adapter_g[pcie_e].pcie_adapter_i.CC_AXI_USER;
                assign cc_axi[pcie_e].TLAST  = DUT_U.VHDL_DUT_U.pcie_core_i.pcie_adapter_g[pcie_e].pcie_adapter_i.CC_AXI_LAST;
                assign cc_axi[pcie_e].TKEEP  = DUT_U.VHDL_DUT_U.pcie_core_i.pcie_adapter_g[pcie_e].pcie_adapter_i.CC_AXI_KEEP;
                assign cc_axi[pcie_e].TVALID = DUT_U.VHDL_DUT_U.pcie_core_i.pcie_adapter_g[pcie_e].pcie_adapter_i.CC_AXI_VALID;
                assign DUT_U.VHDL_DUT_U.pcie_core_i.s_axis_cc_tready[pcie_e][0] = cc_axi[pcie_e].TREADY;

                assign rq_axi[pcie_e].TDATA  = DUT_U.VHDL_DUT_U.pcie_core_i.pcie_adapter_g[pcie_e].pcie_adapter_i.RQ_AXI_DATA;
                assign rq_axi[pcie_e].TUSER  = DUT_U.VHDL_DUT_U.pcie_core_i.pcie_adapter_g[pcie_e].pcie_adapter_i.RQ_AXI_USER;
                assign rq_axi[pcie_e].TLAST  = DUT_U.VHDL_DUT_U.pcie_core_i.pcie_adapter_g[pcie_e].pcie_adapter_i.RQ_AXI_LAST;
                assign rq_axi[pcie_e].TKEEP  = DUT_U.VHDL_DUT_U.pcie_core_i.pcie_adapter_g[pcie_e].pcie_adapter_i.RQ_AXI_KEEP;
                assign rq_axi[pcie_e].TVALID = DUT_U.VHDL_DUT_U.pcie_core_i.pcie_adapter_g[pcie_e].pcie_adapter_i.RQ_AXI_VALID;
                assign DUT_U.VHDL_DUT_U.pcie_core_i.s_axis_rq_tready[pcie_e][0] = rq_axi[pcie_e].TREADY;

                assign DUT_U.VHDL_DUT_U.pcie_core_i.cfg_rcb_status[pcie_e][0] = 1'b0;
            end
        end
        
    endgenerate

endmodule
