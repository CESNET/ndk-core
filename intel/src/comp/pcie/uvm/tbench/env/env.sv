//-- env.sv: Verification environment
//-- Copyright (C) 2023 CESNET z. s. p. o.
//-- Author(s): Daniel Kriz <danielkriz@cesnet.cz>

//-- SPDX-License-Identifier: BSD-3-Clause

class env #(CQ_MFB_REGIONS, CC_MFB_REGIONS, RQ_MFB_REGIONS, RC_MFB_REGIONS, CQ_MFB_REGION_SIZE, CC_MFB_REGION_SIZE, RQ_MFB_REGION_SIZE, RC_MFB_REGION_SIZE, CQ_MFB_BLOCK_SIZE, CC_MFB_BLOCK_SIZE, RQ_MFB_BLOCK_SIZE, RC_MFB_BLOCK_SIZE, CQ_MFB_ITEM_WIDTH, CC_MFB_ITEM_WIDTH, RQ_MFB_ITEM_WIDTH, RC_MFB_ITEM_WIDTH, RQ_MFB_META_W, RC_MFB_META_W, CQ_MFB_META_W, CC_MFB_META_W, DMA_UPHDR_WIDTH_W, DMA_DOWNHDR_WIDTH_W, DEVICE, ENDPOINT_TYPE, DMA_PORTS, PCIE_ENDPOINTS, PCIE_CONS, AVST_DOWN_META_W, AVST_UP_META_W, AXI_DATA_WIDTH, AXI_CQUSER_WIDTH, AXI_CCUSER_WIDTH, AXI_RCUSER_WIDTH, AXI_RQUSER_WIDTH, AXI_STRADDLING, CLK_PERIOD, PCIE_UPHDR_WIDTH, PCIE_DOWNHDR_WIDTH, RCB, PTC_DISABLE, PCIE_TAG_WIDTH) extends uvm_env;

    `uvm_component_param_utils(uvm_pcie::env #(CQ_MFB_REGIONS, CC_MFB_REGIONS, RQ_MFB_REGIONS, RC_MFB_REGIONS, CQ_MFB_REGION_SIZE, CC_MFB_REGION_SIZE, RQ_MFB_REGION_SIZE, RC_MFB_REGION_SIZE, CQ_MFB_BLOCK_SIZE, CC_MFB_BLOCK_SIZE, RQ_MFB_BLOCK_SIZE, RC_MFB_BLOCK_SIZE, CQ_MFB_ITEM_WIDTH, CC_MFB_ITEM_WIDTH, RQ_MFB_ITEM_WIDTH, RC_MFB_ITEM_WIDTH, RQ_MFB_META_W, RC_MFB_META_W, CQ_MFB_META_W, CC_MFB_META_W, DMA_UPHDR_WIDTH_W, DMA_DOWNHDR_WIDTH_W, DEVICE, ENDPOINT_TYPE, DMA_PORTS, PCIE_ENDPOINTS, PCIE_CONS, AVST_DOWN_META_W, AVST_UP_META_W, AXI_DATA_WIDTH, AXI_CQUSER_WIDTH, AXI_CCUSER_WIDTH, AXI_RCUSER_WIDTH, AXI_RQUSER_WIDTH, AXI_STRADDLING, CLK_PERIOD, PCIE_UPHDR_WIDTH, PCIE_DOWNHDR_WIDTH, RCB, PTC_DISABLE, PCIE_TAG_WIDTH));

    localparam IS_INTEL_DEV = (DEVICE == "STRATIX10" || DEVICE == "AGILEX");
    localparam RC_AXI_STRADDLING = 1;
    localparam RQ_AXI_STRADDLING = (AXI_RQUSER_WIDTH == 137) ? 1 : 0;
    // Not yet supported
    localparam CC_AXI_STRADDLING = 0;
    localparam CQ_AXI_STRADDLING = (AXI_CQUSER_WIDTH == 183 && AXI_STRADDLING) ? 1 : 0;
    localparam HDR_USER_WIDTH = (DEVICE == "STRATIX10" || DEVICE == "AGILEX") ? AVST_UP_META_W : PCIE_UPHDR_WIDTH+AXI_RQUSER_WIDTH;
    localparam META_OUT_WIDTH = (DEVICE == "STRATIX10" || DEVICE == "AGILEX") ? AVST_UP_META_W : PCIE_UPHDR_WIDTH;
    localparam IN_META_WIDTH = (DEVICE == "STRATIX10" || DEVICE == "AGILEX") ? AVST_UP_META_W : AXI_RQUSER_WIDTH;
    localparam DOWN_HDR_WIDTH = (DEVICE == "STRATIX10" || DEVICE == "AGILEX") ? AVST_DOWN_META_W : PCIE_DOWNHDR_WIDTH;

    // AVALON interface (INTEL)
    uvm_logic_vector_array_avst::env_rx #(CQ_MFB_REGIONS, CQ_MFB_REGION_SIZE, CQ_MFB_BLOCK_SIZE, CQ_MFB_ITEM_WIDTH, AVST_DOWN_META_W, 30) m_avst_down_env[PCIE_CONS];
    uvm_logic_vector_array_avst::env_tx #(CC_MFB_REGIONS, CC_MFB_REGION_SIZE, CC_MFB_BLOCK_SIZE, CC_MFB_ITEM_WIDTH, AVST_UP_META_W, 3) m_avst_up_env[PCIE_CONS];
    // AXI interface (XILINX)
    uvm_logic_vector_array_axi::env_rx #(AXI_DATA_WIDTH, AXI_CQUSER_WIDTH, CQ_MFB_ITEM_WIDTH, CQ_MFB_REGIONS, CQ_MFB_BLOCK_SIZE, CQ_AXI_STRADDLING)     m_axi_cq_env[PCIE_CONS];
    uvm_logic_vector_array_axi::env_tx #(AXI_DATA_WIDTH, AXI_CCUSER_WIDTH, CC_MFB_ITEM_WIDTH, CC_MFB_REGIONS, CC_MFB_BLOCK_SIZE, CC_AXI_STRADDLING)     m_axi_cc_env[PCIE_CONS];
    uvm_logic_vector_array_axi::env_rx #(AXI_DATA_WIDTH, AXI_RCUSER_WIDTH, RC_MFB_ITEM_WIDTH, RC_MFB_REGIONS, RC_MFB_BLOCK_SIZE, RC_AXI_STRADDLING)     m_axi_rc_env[PCIE_CONS];
    uvm_logic_vector_array_axi::env_tx #(AXI_DATA_WIDTH, AXI_RQUSER_WIDTH, RQ_MFB_ITEM_WIDTH, RQ_MFB_REGIONS, RQ_MFB_BLOCK_SIZE, RQ_AXI_STRADDLING)     m_axi_rq_env[PCIE_CONS];
    // MFB interface (XILINX and INTEL)
    uvm_logic_vector_array_mfb::env_rx #(RQ_MFB_REGIONS, RQ_MFB_REGION_SIZE, RQ_MFB_BLOCK_SIZE, RQ_MFB_ITEM_WIDTH, RQ_MFB_META_W) m_mfb_rq_env[DMA_PORTS];
    uvm_logic_vector_mvb::env_rx #(RQ_MFB_REGIONS, DMA_UPHDR_WIDTH_W)                                                             m_mvb_rq_env[DMA_PORTS];
    uvm_logic_vector_array_mfb::env_tx #(RC_MFB_REGIONS, RC_MFB_REGION_SIZE, RC_MFB_BLOCK_SIZE, RC_MFB_ITEM_WIDTH, RC_MFB_META_W) m_mfb_rc_env[DMA_PORTS];
    uvm_logic_vector_mvb::env_tx #(RC_MFB_REGIONS, DMA_DOWNHDR_WIDTH_W)                                                           m_mvb_rc_env[DMA_PORTS];

    uvm_logic_vector_array_mfb::env_tx #(CQ_MFB_REGIONS, CQ_MFB_REGION_SIZE, CQ_MFB_BLOCK_SIZE, CQ_MFB_ITEM_WIDTH, CQ_MFB_META_W) m_mfb_cq_env[DMA_PORTS];
    uvm_logic_vector_array_mfb::env_rx #(CC_MFB_REGIONS, CC_MFB_REGION_SIZE, CC_MFB_BLOCK_SIZE, CC_MFB_ITEM_WIDTH, CC_MFB_META_W) m_mfb_cc_env[DMA_PORTS];
    //CONFIGURATION INTERFACE
    uvm_mi::agent_master #(32, 32) m_mi_agent[PCIE_ENDPOINTS];
    // Reset agent
    uvm_reset::agent                m_dma_reset;
    uvm_reset::agent                m_mi_reset;
    uvm_reset::env#(PCIE_CONS)      m_pcie_sysrst_n;

    // Avalon configuration
    uvm_logic_vector_array_avst::config_item m_avst_down_cfg[PCIE_CONS];
    uvm_logic_vector_array_avst::config_item m_avst_up_cfg[PCIE_CONS];
    // AXI configuration
    uvm_logic_vector_array_axi::config_item  m_axi_cq_cfg[PCIE_CONS];
    uvm_logic_vector_array_axi::config_item  m_axi_cc_cfg[PCIE_CONS];
    uvm_logic_vector_array_axi::config_item  m_axi_rc_cfg[PCIE_CONS];
    uvm_logic_vector_array_axi::config_item  m_axi_rq_cfg[PCIE_CONS];
    // MFB configuration
    uvm_logic_vector_array_mfb::config_item  m_rq_mfb_cfg[DMA_PORTS];
    uvm_logic_vector_mvb::config_item        m_rq_mvb_cfg[DMA_PORTS];
    uvm_logic_vector_array_mfb::config_item  m_rc_mfb_cfg[DMA_PORTS];
    uvm_logic_vector_mvb::config_item        m_rc_mvb_cfg[DMA_PORTS];
    uvm_logic_vector_array_mfb::config_item  m_cq_mfb_cfg[DMA_PORTS];
    uvm_logic_vector_array_mfb::config_item  m_cc_mfb_cfg[DMA_PORTS];
    //CONFIGURATION INTERFACE
    uvm_mi::config_item                      m_mi_config[PCIE_ENDPOINTS];
    // Reset configuration
    uvm_reset::config_item                   m_dma_reset_cfg;
    uvm_reset::config_item                   m_mi_reset_cfg;
    uvm_reset::env_config_item #(PCIE_CONS)  m_pcie_sysrst_n_cfg;


    uvm_down_hdr::tag_manager #(PCIE_TAG_WIDTH) tag_man;
    uvm_pcie::tr_planner #(1)                   tr_plan[PCIE_ENDPOINTS];
    uvm_pcie::monitor #(1)                      m_monitor[PCIE_ENDPOINTS];
    uvm_pcie::rc_monitor #(RQ_MFB_ITEM_WIDTH, IN_META_WIDTH, HDR_USER_WIDTH, DEVICE)      m_rc_monitor[PCIE_ENDPOINTS];
    uvm_pcie_rc::tr_planner #(HDR_USER_WIDTH, IN_META_WIDTH, DOWN_HDR_WIDTH, RCB, CLK_PERIOD, DEVICE) rc_planner[PCIE_ENDPOINTS];

    uvm_pcie::virt_sequencer_base#(RC_MFB_REGIONS, RC_MFB_REGION_SIZE, RC_MFB_BLOCK_SIZE, RC_MFB_ITEM_WIDTH, RC_MFB_META_W, CQ_MFB_REGIONS, CQ_MFB_REGION_SIZE, CQ_MFB_BLOCK_SIZE, CQ_MFB_ITEM_WIDTH, CQ_MFB_META_W, RQ_MFB_ITEM_WIDTH, CC_MFB_ITEM_WIDTH, RQ_MFB_META_W, CC_MFB_META_W, DMA_UPHDR_WIDTH_W, DMA_DOWNHDR_WIDTH_W, DMA_PORTS, PCIE_ENDPOINTS) vscr;

    scoreboard #(CQ_MFB_ITEM_WIDTH, CQ_MFB_REGIONS, CC_MFB_ITEM_WIDTH, RQ_MFB_ITEM_WIDTH, RC_MFB_ITEM_WIDTH, AVST_DOWN_META_W, AVST_UP_META_W, AXI_CQUSER_WIDTH, AXI_CCUSER_WIDTH, AXI_RCUSER_WIDTH, AXI_RQUSER_WIDTH, RQ_MFB_META_W, RC_MFB_META_W, CQ_MFB_META_W, CC_MFB_META_W, DEVICE, ENDPOINT_TYPE, RQ_MFB_BLOCK_SIZE, DMA_UPHDR_WIDTH_W, DMA_DOWNHDR_WIDTH_W, PCIE_DOWNHDR_WIDTH, DMA_PORTS, PCIE_ENDPOINTS, PTC_DISABLE, PCIE_TAG_WIDTH) m_scoreboard;

    // Constructor of environment.
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    // Create base components of environment.
    function void build_phase(uvm_phase phase);

        m_pcie_sysrst_n_cfg = new();
        for(int unsigned pcie_c = 0; pcie_c < PCIE_CONS; pcie_c++) begin
            string i_string;
            i_string.itoa(pcie_c);

            m_pcie_sysrst_n_cfg.active[pcie_c]         = UVM_ACTIVE;
            m_pcie_sysrst_n_cfg.interface_name[pcie_c] = {"vif_pcie_sysrst_n_", i_string};
            // AVALON
            if (IS_INTEL_DEV) begin
                m_avst_down_cfg[pcie_c]                = new();
                m_avst_up_cfg[pcie_c]                  = new();
                m_avst_down_cfg[pcie_c].active         = UVM_ACTIVE;
                m_avst_up_cfg[pcie_c].active           = UVM_ACTIVE;
                m_avst_down_cfg[pcie_c].interface_name = {"vif_avst_down_", i_string};
                m_avst_up_cfg[pcie_c].interface_name   = {"vif_avst_up_", i_string};
                m_avst_down_cfg[pcie_c].meta_behav     = uvm_logic_vector_array_avst::config_item::META_SOF;
                m_avst_up_cfg[pcie_c].meta_behav       = uvm_logic_vector_array_avst::config_item::META_SOF;
                m_avst_down_cfg[pcie_c].seq_cfg        = new();
                m_avst_up_cfg[pcie_c].seq_cfg          = new();
                m_avst_down_cfg[pcie_c].seq_cfg.straddling_set(1);
                m_avst_up_cfg[pcie_c].seq_cfg.straddling_set(1);
                uvm_config_db #(uvm_logic_vector_array_avst::config_item)::set(this, {"m_avst_down_env_", i_string}, "m_config", m_avst_down_cfg[pcie_c]);
                uvm_config_db #(uvm_logic_vector_array_avst::config_item)::set(this, {"m_avst_up_env_", i_string}, "m_config", m_avst_up_cfg[pcie_c]);

                // Create AVALON environments
                m_avst_down_env[pcie_c] = uvm_logic_vector_array_avst::env_rx #(CQ_MFB_REGIONS, CQ_MFB_REGION_SIZE, CQ_MFB_BLOCK_SIZE, CQ_MFB_ITEM_WIDTH, AVST_DOWN_META_W, 30)::type_id::create({"m_avst_down_env_", i_string}, this);
                m_avst_up_env[pcie_c]   = uvm_logic_vector_array_avst::env_tx #(CC_MFB_REGIONS, CC_MFB_REGION_SIZE, CC_MFB_BLOCK_SIZE, CC_MFB_ITEM_WIDTH, AVST_UP_META_W  , 3)::type_id::create({"m_avst_up_env_", i_string}, this);
            end else begin
                // AXI
                m_axi_cq_cfg[pcie_c]                = new();
                m_axi_cc_cfg[pcie_c]                = new();
                m_axi_rc_cfg[pcie_c]                = new();
                m_axi_rq_cfg[pcie_c]                = new();
                m_axi_cq_cfg[pcie_c].active         = UVM_ACTIVE;
                m_axi_cc_cfg[pcie_c].active         = UVM_ACTIVE;
                m_axi_rc_cfg[pcie_c].active         = UVM_ACTIVE;
                m_axi_rq_cfg[pcie_c].active         = UVM_ACTIVE;
                m_axi_cq_cfg[pcie_c].meta_behav     = uvm_logic_vector_array_axi::config_item::META_EOF;
                m_axi_cc_cfg[pcie_c].meta_behav     = uvm_logic_vector_array_axi::config_item::META_EOF;
                m_axi_rc_cfg[pcie_c].meta_behav     = uvm_logic_vector_array_axi::config_item::META_EOF;
                m_axi_rq_cfg[pcie_c].meta_behav     = uvm_logic_vector_array_axi::config_item::META_EOF;
                m_axi_cq_cfg[pcie_c].interface_name = {"vif_cq_axi_", i_string};
                m_axi_cc_cfg[pcie_c].interface_name = {"vif_cc_axi_", i_string};
                m_axi_rc_cfg[pcie_c].interface_name = {"vif_rc_axi_", i_string};
                m_axi_rq_cfg[pcie_c].interface_name = {"vif_rq_axi_", i_string};
                uvm_config_db #(uvm_logic_vector_array_axi::config_item)::set(this, {"m_axi_cq_env_", i_string}, "m_config", m_axi_cq_cfg[pcie_c]);
                uvm_config_db #(uvm_logic_vector_array_axi::config_item)::set(this, {"m_axi_cc_env_", i_string}, "m_config", m_axi_cc_cfg[pcie_c]);
                uvm_config_db #(uvm_logic_vector_array_axi::config_item)::set(this, {"m_axi_rc_env_", i_string}, "m_config", m_axi_rc_cfg[pcie_c]);
                uvm_config_db #(uvm_logic_vector_array_axi::config_item)::set(this, {"m_axi_rq_env_", i_string}, "m_config", m_axi_rq_cfg[pcie_c]);

                // Create AXI environments
                m_axi_cq_env[pcie_c]    = uvm_logic_vector_array_axi::env_rx #(AXI_DATA_WIDTH, AXI_CQUSER_WIDTH, CQ_MFB_ITEM_WIDTH, CQ_MFB_REGIONS, CQ_MFB_BLOCK_SIZE, CQ_AXI_STRADDLING)::type_id::create({"m_axi_cq_env_", i_string}, this);
                m_axi_cc_env[pcie_c]    = uvm_logic_vector_array_axi::env_tx #(AXI_DATA_WIDTH, AXI_CCUSER_WIDTH, CC_MFB_ITEM_WIDTH, CC_MFB_REGIONS, CC_MFB_BLOCK_SIZE, CC_AXI_STRADDLING)::type_id::create({"m_axi_cc_env_", i_string}, this);
                m_axi_rc_env[pcie_c]    = uvm_logic_vector_array_axi::env_rx #(AXI_DATA_WIDTH, AXI_RCUSER_WIDTH, RC_MFB_ITEM_WIDTH, RC_MFB_REGIONS, RC_MFB_BLOCK_SIZE, RC_AXI_STRADDLING)::type_id::create({"m_axi_rc_env_", i_string}, this);
                m_axi_rq_env[pcie_c]    = uvm_logic_vector_array_axi::env_tx #(AXI_DATA_WIDTH, AXI_RQUSER_WIDTH, RQ_MFB_ITEM_WIDTH, RQ_MFB_REGIONS, RQ_MFB_BLOCK_SIZE, RQ_AXI_STRADDLING)::type_id::create({"m_axi_rq_env_", i_string}, this);
            end
        end
        m_pcie_sysrst_n_cfg.driver_delay = 40ns;
        uvm_config_db#(uvm_reset::env_config_item#(PCIE_CONS))::set(this, "m_pcie_sysrst_n", "m_config", m_pcie_sysrst_n_cfg);
        m_pcie_sysrst_n = uvm_reset::env#(PCIE_CONS)::type_id::create("m_pcie_sysrst_n", this);

        tag_man = uvm_down_hdr::tag_manager#(PCIE_TAG_WIDTH)::type_id::create("tag_man", this);

        for(int unsigned pcie_e = 0; pcie_e < PCIE_ENDPOINTS; pcie_e++) begin
            string i_string;
            i_string.itoa(pcie_e);

            m_mi_config[pcie_e]                = new();
            m_mi_config[pcie_e].active         = UVM_ACTIVE;
            m_mi_config[pcie_e].interface_name = {"vif_mi_", i_string};
            uvm_config_db#(uvm_mi::config_item)::set(this, {"m_mi_agent_", i_string}, "m_config", m_mi_config[pcie_e]);
            m_mi_agent[pcie_e] = uvm_mi::agent_master #(32, 32)::type_id::create({"m_mi_agent_", i_string}, this);

            m_monitor[pcie_e]    = uvm_pcie::monitor #(1)::type_id::create({"m_monitor_", i_string}, this);
            m_rc_monitor[pcie_e] = uvm_pcie::rc_monitor #(RQ_MFB_ITEM_WIDTH, IN_META_WIDTH, HDR_USER_WIDTH, DEVICE)::type_id::create({"m_rc_monitor_", i_string}, this);
            tr_plan[pcie_e]      = uvm_pcie::tr_planner #(1)::type_id::create({"tr_plan_", i_string}, this);
            rc_planner[pcie_e]   = uvm_pcie_rc::tr_planner #(HDR_USER_WIDTH, IN_META_WIDTH, DOWN_HDR_WIDTH, RCB, CLK_PERIOD, DEVICE)::type_id::create({"rc_planner_", i_string}, this);
        end

        for (int dma = 0; dma < DMA_PORTS; dma++) begin
            string i_string;
            i_string.itoa(dma);

            // MFB configuratiom
            m_rq_mfb_cfg[dma] = new();
            m_rq_mvb_cfg[dma] = new();
            m_rc_mfb_cfg[dma] = new();
            m_rc_mvb_cfg[dma] = new();
            m_cq_mfb_cfg[dma] = new();
            m_cc_mfb_cfg[dma] = new();

            // MFB configuratiom
            m_rq_mfb_cfg[dma].active = UVM_ACTIVE;
            m_rq_mvb_cfg[dma].active = UVM_ACTIVE;
            m_rc_mfb_cfg[dma].active = UVM_ACTIVE;
            m_rc_mvb_cfg[dma].active = UVM_ACTIVE;
            m_cq_mfb_cfg[dma].active = UVM_ACTIVE;
            m_cc_mfb_cfg[dma].active = UVM_ACTIVE;

            // MFB configuratiom
            m_rq_mfb_cfg[dma].interface_name    = {"vif_rq_mfb_", i_string};
            m_rq_mvb_cfg[dma].interface_name    = {"vif_rq_mvb_", i_string};
            m_rc_mfb_cfg[dma].interface_name    = {"vif_rc_mfb_", i_string};
            m_rc_mvb_cfg[dma].interface_name    = {"vif_rc_mvb_", i_string};
            m_cq_mfb_cfg[dma].interface_name    = {"vif_cq_mfb_", i_string};
            m_cc_mfb_cfg[dma].interface_name    = {"vif_cc_mfb_", i_string};

            // MFB configuratiom
            m_rq_mfb_cfg[dma].meta_behav = (IS_INTEL_DEV) ? uvm_logic_vector_array_mfb::config_item::META_SOF : uvm_logic_vector_array_mfb::config_item::META_NONE;
            m_rc_mfb_cfg[dma].meta_behav = (IS_INTEL_DEV) ? uvm_logic_vector_array_mfb::config_item::META_SOF : uvm_logic_vector_array_mfb::config_item::META_NONE;
            m_cq_mfb_cfg[dma].meta_behav = (IS_INTEL_DEV) ? uvm_logic_vector_array_mfb::config_item::META_SOF : uvm_logic_vector_array_mfb::config_item::META_NONE;
            m_cc_mfb_cfg[dma].meta_behav = (IS_INTEL_DEV) ? uvm_logic_vector_array_mfb::config_item::META_SOF : uvm_logic_vector_array_mfb::config_item::META_NONE;

            // MFB RQ
            m_rq_mfb_cfg[dma].seq_type = "PCIE";
            // MFB RC
            m_rc_mfb_cfg[dma].seq_type = "PCIE";
            // MFB CQ
            m_cq_mfb_cfg[dma].seq_type = "PCIE";
            // MFB CC
            m_cc_mfb_cfg[dma].seq_type = "PCIE";

            // MFB RQ
            m_rq_mfb_cfg[dma].seq_cfg  = new();
            m_rq_mfb_cfg[dma].seq_cfg.straddling_set(1);
            // MFB RC
            m_rc_mfb_cfg[dma].seq_cfg  = new();
            m_rc_mfb_cfg[dma].seq_cfg.straddling_set(1);
            // MFB CQ
            m_cq_mfb_cfg[dma].seq_cfg  = new();
            m_cq_mfb_cfg[dma].seq_cfg.straddling_set(1);
            // MFB CC
            m_cc_mfb_cfg[dma].seq_cfg  = new();
            m_cc_mfb_cfg[dma].seq_cfg.straddling_set(1);

            // MFB
            uvm_config_db #(uvm_logic_vector_array_mfb::config_item)::set(this, {"m_mfb_rq_env_", i_string}, "m_config", m_rq_mfb_cfg[dma]);
            uvm_config_db #(uvm_logic_vector_mvb::config_item)::set(this, {"m_mvb_rq_env_", i_string}, "m_config", m_rq_mvb_cfg[dma]);
            uvm_config_db #(uvm_logic_vector_array_mfb::config_item)::set(this, {"m_mfb_rc_env_", i_string}, "m_config", m_rc_mfb_cfg[dma]);
            uvm_config_db #(uvm_logic_vector_mvb::config_item)::set(this, {"m_mvb_rc_env_", i_string}, "m_config", m_rc_mvb_cfg[dma]);
            uvm_config_db #(uvm_logic_vector_array_mfb::config_item)::set(this, {"m_mfb_cq_env_", i_string}, "m_config", m_cq_mfb_cfg[dma]);
            uvm_config_db #(uvm_logic_vector_array_mfb::config_item)::set(this, {"m_mfb_cc_env_", i_string}, "m_config", m_cc_mfb_cfg[dma]);

            // Create MFB environments
            m_mfb_rq_env[dma]    = uvm_logic_vector_array_mfb::env_rx #(RQ_MFB_REGIONS, RQ_MFB_REGION_SIZE, RQ_MFB_BLOCK_SIZE, RQ_MFB_ITEM_WIDTH, RQ_MFB_META_W)::type_id::create({"m_mfb_rq_env_", i_string}, this);
            m_mvb_rq_env[dma]    = uvm_logic_vector_mvb::env_rx #(RQ_MFB_REGIONS, DMA_UPHDR_WIDTH_W)::type_id::create({"m_mvb_rq_env_", i_string}, this);
            m_mfb_rc_env[dma]    = uvm_logic_vector_array_mfb::env_tx #(RC_MFB_REGIONS, RC_MFB_REGION_SIZE, RC_MFB_BLOCK_SIZE, RC_MFB_ITEM_WIDTH, RC_MFB_META_W)::type_id::create({"m_mfb_rc_env_", i_string}, this);
            m_mvb_rc_env[dma]    = uvm_logic_vector_mvb::env_tx #(RC_MFB_REGIONS, DMA_DOWNHDR_WIDTH_W)::type_id::create({"m_mvb_rc_env_", i_string}, this);
            m_mfb_cq_env[dma]    = uvm_logic_vector_array_mfb::env_tx #(CQ_MFB_REGIONS, CQ_MFB_REGION_SIZE, CQ_MFB_BLOCK_SIZE, CQ_MFB_ITEM_WIDTH, CQ_MFB_META_W)::type_id::create({"m_mfb_cq_env_", i_string}, this);
            m_mfb_cc_env[dma]    = uvm_logic_vector_array_mfb::env_rx #(CC_MFB_REGIONS, CC_MFB_REGION_SIZE, CC_MFB_BLOCK_SIZE, CC_MFB_ITEM_WIDTH, CC_MFB_META_W)::type_id::create({"m_mfb_cc_env_", i_string}, this);
        end

        // DMA Reset
        m_dma_reset_cfg                = new();
        m_mi_reset_cfg                 = new();
        m_dma_reset_cfg.active         = UVM_ACTIVE;
        m_mi_reset_cfg.active          = UVM_ACTIVE;
        m_dma_reset_cfg.interface_name = "vif_dma_reset";
        m_mi_reset_cfg.interface_name  = "vif_mi_reset";
        uvm_config_db #(uvm_reset::config_item)::set(this, "m_dma_reset", "m_config", m_dma_reset_cfg);
        uvm_config_db #(uvm_reset::config_item)::set(this, "m_mi_reset", "m_config", m_mi_reset_cfg);
        m_dma_reset = uvm_reset::agent::type_id::create("m_dma_reset", this);
        m_mi_reset  = uvm_reset::agent::type_id::create("m_mi_reset", this);

        m_scoreboard = scoreboard #(CQ_MFB_ITEM_WIDTH, CQ_MFB_REGIONS, CC_MFB_ITEM_WIDTH, RQ_MFB_ITEM_WIDTH, RC_MFB_ITEM_WIDTH, AVST_DOWN_META_W, AVST_UP_META_W, AXI_CQUSER_WIDTH, AXI_CCUSER_WIDTH, AXI_RCUSER_WIDTH, AXI_RQUSER_WIDTH, RQ_MFB_META_W, RC_MFB_META_W, CQ_MFB_META_W, CC_MFB_META_W, DEVICE, ENDPOINT_TYPE, RQ_MFB_BLOCK_SIZE, DMA_UPHDR_WIDTH_W, DMA_DOWNHDR_WIDTH_W, PCIE_DOWNHDR_WIDTH, DMA_PORTS, PCIE_ENDPOINTS, PTC_DISABLE, PCIE_TAG_WIDTH)::type_id::create("m_scoreboard", this);
        if (IS_INTEL_DEV) begin
            vscr = uvm_pcie::virt_sequencer_intel#(RQ_MFB_ITEM_WIDTH, RQ_MFB_META_W, RC_MFB_REGIONS, RC_MFB_REGION_SIZE, RC_MFB_BLOCK_SIZE, RC_MFB_ITEM_WIDTH, RC_MFB_META_W, CQ_MFB_REGIONS, CQ_MFB_REGION_SIZE, CQ_MFB_BLOCK_SIZE, CQ_MFB_ITEM_WIDTH, CQ_MFB_META_W, CC_MFB_META_W, DMA_UPHDR_WIDTH_W, DMA_DOWNHDR_WIDTH_W, CC_MFB_REGIONS, CC_MFB_REGION_SIZE, CC_MFB_BLOCK_SIZE, CC_MFB_ITEM_WIDTH, AVST_UP_META_W, AVST_DOWN_META_W, DMA_PORTS, PCIE_ENDPOINTS, PCIE_CONS)::type_id::create("vscr_intel",this);
        end else begin
            vscr = uvm_pcie::virt_sequencer_xilinx#(RQ_MFB_REGIONS, RQ_MFB_ITEM_WIDTH, RQ_MFB_META_W, RC_MFB_REGIONS, RC_MFB_REGION_SIZE, RC_MFB_BLOCK_SIZE, RC_MFB_ITEM_WIDTH, RC_MFB_META_W, CQ_MFB_REGIONS, CQ_MFB_REGION_SIZE, CQ_MFB_BLOCK_SIZE, CQ_MFB_ITEM_WIDTH, CQ_MFB_META_W, CC_MFB_REGIONS, CC_MFB_ITEM_WIDTH, CC_MFB_META_W, DMA_UPHDR_WIDTH_W, DMA_DOWNHDR_WIDTH_W, AXI_DATA_WIDTH, AXI_CCUSER_WIDTH, AXI_RQUSER_WIDTH, AXI_CQUSER_WIDTH, DMA_PORTS, PCIE_ENDPOINTS, PCIE_CONS)::type_id::create("vscr_xilinx",this);
        end

    endfunction

    // Connect agent's ports with ports from scoreboard.
    function void connect_phase(uvm_phase phase);

        for (int dma = 0; dma < DMA_PORTS; dma++) begin
            // ------------------------------------------------------------------
            // Connection to the Scoreboard
            // ------------------------------------------------------------------
            m_mfb_rq_env[dma].analysis_port_data.connect(m_scoreboard.analysis_imp_mfb_rq_data[dma].analysis_export);
            m_mvb_rq_env[dma].analysis_port.connect(m_scoreboard.analysis_imp_mvb_rq_data[dma].analysis_export);

            // TODO: Use in case of no PTC
            // m_mfb_rq_env[dma].analysis_port_meta.connect(m_scoreboard.analysis_imp_mfb_rq_meta[dma].analysis_export);
            // m_mfb_cc_env[dma].analysis_port_data.connect(m_scoreboard.analysis_imp_mfb_cc_data[dma].analysis_export);
            // m_mfb_cc_env[dma].analysis_port_meta.connect(m_scoreboard.analysis_imp_mfb_cc_meta[dma].analysis_export);

            m_mfb_rc_env[dma].analysis_port_data.connect(m_scoreboard.analysis_imp_mfb_rc_data[dma]);
            // m_mfb_rc_env[dma].analysis_port_meta.connect(m_scoreboard.analysis_imp_mfb_rc_meta[dma]);
            m_mvb_rc_env[dma].analysis_port.connect(m_scoreboard.analysis_imp_mvb_rc_data[dma]);

            // TODO: Create model and make comparators (This is use in case of DMA_BAR_ENABLE)
            // m_mfb_cq_env[dma].analysis_port_data.connect(m_scoreboard.analysis_imp_mfb_cq_data[dma]);
            // m_mfb_cq_env[dma].analysis_port_meta.connect(m_scoreboard.analysis_imp_mfb_cq_meta[dma]);

            // ------------------------------------------------------------------
            // Connection to the Sequencers
            // ------------------------------------------------------------------
            vscr.m_cc_mfb_data_sqr[dma]    = m_mfb_cc_env[dma].m_sequencer.m_data;
            vscr.m_cc_mfb_meta_sqr[dma]    = m_mfb_cc_env[dma].m_sequencer.m_meta;

            vscr.m_rq_mfb_data_sqr[dma]    = m_mfb_rq_env[dma].m_sequencer.m_data;
            vscr.m_rq_mfb_meta_sqr[dma]    = m_mfb_rq_env[dma].m_sequencer.m_meta;
            vscr.m_rq_mvb_sqr[dma]         = m_mvb_rq_env[dma].m_sequencer;

            vscr.m_mfb_rc_dst_rdy_sqr[dma] = m_mfb_rc_env[dma].m_sequencer;
            vscr.m_mvb_rc_dst_rdy_sqr[dma] = m_mvb_rc_env[dma].m_sequencer;

            vscr.m_mfb_cq_dst_rdy_sqr[dma] = m_mfb_cq_env[dma].m_sequencer;

            // ------------------------------------------------------------------
            // Reset sync connection
            // ------------------------------------------------------------------

            // Create MFB environments to Reset agent sync
            m_dma_reset.sync_connect(m_mfb_rq_env[dma].reset_sync);
            m_dma_reset.sync_connect(m_mvb_rq_env[dma].reset_sync);
            m_dma_reset.sync_connect(m_mfb_rc_env[dma].reset_sync);
            m_dma_reset.sync_connect(m_mvb_rc_env[dma].reset_sync);

            m_dma_reset.sync_connect(m_mfb_cq_env[dma].reset_sync);
            m_dma_reset.sync_connect(m_mfb_cc_env[dma].reset_sync);
        end

        for (int pcie_e = 0; pcie_e < PCIE_ENDPOINTS; pcie_e++) begin
            m_mi_agent[pcie_e].analysis_port_rq.connect(m_monitor[pcie_e].analysis_export);
            m_mi_agent[pcie_e].analysis_port_rq.connect(m_scoreboard.mi_scrb[pcie_e].analysis_export);
            m_mi_agent[pcie_e].analysis_port_rs.connect(m_scoreboard.analysis_export_cc_mi[pcie_e].analysis_export);
            m_monitor[pcie_e].analysis_port.connect(tr_plan[pcie_e].analysis_imp);

            if (IS_INTEL_DEV) begin
                m_avst_up_env[pcie_e].analysis_port_meta.connect(m_rc_monitor[pcie_e].analysis_imp_meta);
                m_avst_up_env[pcie_e].analysis_port_data.connect(m_scoreboard.analysis_imp_avst_up_data[pcie_e]);
                m_avst_up_env[pcie_e].analysis_port_meta.connect(m_scoreboard.analysis_imp_avst_up_meta[pcie_e]);

                m_scoreboard.avst_up_meta_cmp[pcie_e].tag_man = tag_man;
                m_scoreboard.m_model_intel.tag_man            = tag_man;

                m_avst_down_env[pcie_e].analysis_port_data.connect(m_scoreboard.analysis_imp_avst_down_data[pcie_e].analysis_export);
                m_avst_down_env[pcie_e].analysis_port_meta.connect(m_scoreboard.analysis_imp_avst_down_meta[pcie_e].analysis_export);
            end else begin
                m_axi_rq_env[pcie_e].analysis_port_data.connect(m_rc_monitor[pcie_e].analysis_imp_data);
                m_axi_rq_env[pcie_e].analysis_port_meta.connect(m_rc_monitor[pcie_e].analysis_imp_meta);

                m_scoreboard.axi_rq_data_cmp[pcie_e].tag_man = tag_man;
                m_scoreboard.m_model_xilinx.tag_man          = tag_man;

                m_axi_rq_env[pcie_e].analysis_port_data.connect(m_scoreboard.analysis_imp_axi_rq_data[pcie_e]);
                m_axi_rc_env[pcie_e].analysis_port_data.connect(m_scoreboard.analysis_imp_axi_rc_data[pcie_e].analysis_export);

                m_axi_cq_env[pcie_e].analysis_port_data.connect(m_scoreboard.analysis_imp_axi_cq_data[pcie_e].analysis_export);
                m_axi_cq_env[pcie_e].analysis_port_meta.connect(m_scoreboard.analysis_imp_axi_cq_meta[pcie_e].analysis_export);

                m_axi_cc_env[pcie_e].analysis_port_data.connect(m_scoreboard.analysis_imp_axi_cc_data[pcie_e]);
            end
            m_rc_monitor[pcie_e].analysis_port.connect(rc_planner[pcie_e].analysis_imp);
            vscr.m_mi_sqr[pcie_e] = m_mi_agent[pcie_e].m_sequencer;
        end

        if (IS_INTEL_DEV) begin
            uvm_pcie::virt_sequencer_intel#(RQ_MFB_ITEM_WIDTH, RQ_MFB_META_W, RC_MFB_REGIONS, RC_MFB_REGION_SIZE, RC_MFB_BLOCK_SIZE, RC_MFB_ITEM_WIDTH, RC_MFB_META_W, CQ_MFB_REGIONS, CQ_MFB_REGION_SIZE, CQ_MFB_BLOCK_SIZE, CQ_MFB_ITEM_WIDTH, CQ_MFB_META_W, CC_MFB_META_W, DMA_UPHDR_WIDTH_W, DMA_DOWNHDR_WIDTH_W, CC_MFB_REGIONS, CC_MFB_REGION_SIZE, CC_MFB_BLOCK_SIZE, CC_MFB_ITEM_WIDTH, AVST_UP_META_W, AVST_DOWN_META_W, DMA_PORTS, PCIE_ENDPOINTS, PCIE_CONS) vscr_intel;
            $cast(vscr_intel, vscr);

            for (int pcie_c = 0; pcie_c < PCIE_CONS; pcie_c++) begin
                // Create AVALON environments to Reset agent sync
                m_pcie_sysrst_n.m_agent[pcie_c].sync_connect(m_avst_down_env[pcie_c].reset_sync);
                m_pcie_sysrst_n.m_agent[pcie_c].sync_connect(m_avst_up_env[pcie_c].reset_sync);

                vscr_intel.m_avst_up_rdy_sqr[pcie_c]    = m_avst_up_env[pcie_c].m_sequencer;
                vscr_intel.m_avst_down_data_sqr[pcie_c] = m_avst_down_env[pcie_c].m_sequencer.m_data;
                vscr_intel.m_avst_down_meta_sqr[pcie_c] = m_avst_down_env[pcie_c].m_sequencer.m_meta;
            end
        end else begin
            uvm_pcie::virt_sequencer_xilinx#(RQ_MFB_REGIONS, RQ_MFB_ITEM_WIDTH, RQ_MFB_META_W, RC_MFB_REGIONS, RC_MFB_REGION_SIZE, RC_MFB_BLOCK_SIZE, RC_MFB_ITEM_WIDTH, RC_MFB_META_W, CQ_MFB_REGIONS, CQ_MFB_REGION_SIZE, CQ_MFB_BLOCK_SIZE, CQ_MFB_ITEM_WIDTH, CQ_MFB_META_W, CC_MFB_REGIONS, CC_MFB_ITEM_WIDTH, CC_MFB_META_W, DMA_UPHDR_WIDTH_W, DMA_DOWNHDR_WIDTH_W, AXI_DATA_WIDTH, AXI_CCUSER_WIDTH, AXI_RQUSER_WIDTH, AXI_CQUSER_WIDTH, DMA_PORTS, PCIE_ENDPOINTS, PCIE_CONS) vscr_xilinx;
            $cast(vscr_xilinx, vscr);
            
            for (int pcie_c = 0; pcie_c < PCIE_CONS; pcie_c++) begin
                // Create AXI environments to Reset agent sync
                m_pcie_sysrst_n.m_agent[pcie_c].sync_connect(m_axi_cq_env[pcie_c].reset_sync);
                m_pcie_sysrst_n.m_agent[pcie_c].sync_connect(m_axi_cc_env[pcie_c].reset_sync);
                m_pcie_sysrst_n.m_agent[pcie_c].sync_connect(m_axi_rc_env[pcie_c].reset_sync);
                m_pcie_sysrst_n.m_agent[pcie_c].sync_connect(m_axi_rq_env[pcie_c].reset_sync);
                // Connect AXI environments to data Sequencer
                vscr_xilinx.m_axi_cq_data_sqr[pcie_c] = m_axi_cq_env[pcie_c].m_sequencer.m_data;
                vscr_xilinx.m_axi_rc_data_sqr[pcie_c] = m_axi_rc_env[pcie_c].m_sequencer.m_data;
                // Connect AXI environments to READY Sequencer
                vscr_xilinx.m_axi_cc_rdy_sqr[pcie_c]  = m_axi_cc_env[pcie_c].m_sequencer;
                vscr_xilinx.m_axi_rq_rdy_sqr[pcie_c]  = m_axi_rq_env[pcie_c].m_sequencer;
            end
        end

        // Connect Reset agent to Sequencer
        vscr.m_dma_reset     = m_dma_reset.m_sequencer;
        vscr.m_mi_reset      = m_mi_reset.m_sequencer;
        vscr.m_pcie_sysrst_n = m_pcie_sysrst_n.m_sequencer;

    endfunction

    virtual task run_phase(uvm_phase phase);
        uvm_pcie::mi_cc_sequence #(32, 32) mi_seq[PCIE_ENDPOINTS];
        uvm_pcie::logic_vector_sequence #(DOWN_HDR_WIDTH, META_OUT_WIDTH, IN_META_WIDTH, RCB, CLK_PERIOD, DEVICE) logic_vector_seq[PCIE_ENDPOINTS];
        uvm_pcie::byte_array_sequence#(META_OUT_WIDTH, DOWN_HDR_WIDTH, IN_META_WIDTH, RCB, CLK_PERIOD, DEVICE)    byte_array_seq[PCIE_ENDPOINTS];

        for (int unsigned pcie_e = 0; pcie_e < PCIE_ENDPOINTS; pcie_e++) begin
            string i_string;
            i_string.itoa(pcie_e);

            logic_vector_seq[pcie_e]         = uvm_pcie::logic_vector_sequence #(DOWN_HDR_WIDTH, META_OUT_WIDTH, IN_META_WIDTH, RCB, CLK_PERIOD, DEVICE)::type_id::create({"logic_vector_seq_", i_string}, this);
            logic_vector_seq[pcie_e].tr_plan = rc_planner[pcie_e];
            logic_vector_seq[pcie_e].randomize();

            byte_array_seq[pcie_e]         = uvm_pcie::byte_array_sequence#(META_OUT_WIDTH, DOWN_HDR_WIDTH, IN_META_WIDTH, RCB, CLK_PERIOD, DEVICE)::type_id::create({"byte_array_seq", i_string}, this);
            byte_array_seq[pcie_e].tr_plan = rc_planner[pcie_e];
            byte_array_seq[pcie_e].randomize();

            mi_seq[pcie_e] = uvm_pcie::mi_cc_sequence #(32, 32)::type_id::create({"mi_seq_", i_string}, this);
            mi_seq[pcie_e].tr_plan = tr_plan[pcie_e];
            mi_seq[pcie_e].randomize();

            fork
                automatic int index = pcie_e;
                mi_seq[index].start(m_mi_agent[index].m_sequencer);
            join_none

            if (DEVICE == "STRATIX10" || DEVICE == "AGILEX") begin
                fork
                    logic_vector_seq[pcie_e].start(m_avst_down_env[pcie_e].m_sequencer.m_meta);
                    byte_array_seq[pcie_e].start(m_avst_down_env[pcie_e].m_sequencer.m_data);
                join_any
            end else begin
                fork
                    byte_array_seq[pcie_e].start(m_axi_rc_env[pcie_e].m_sequencer.m_data);
                join_any
            end

        end
    endtask

endclass
