// sequencer.sv: Virtual sequencer
// Copyright (C) 2023 CESNET z. s. p. o.
// Author(s): Daniel Kriz <xvalek14@vutbr.cz>

// SPDX-License-Identifier: BSD-3-Clause


class virt_sequencer_base#(RC_MFB_REGIONS, RC_MFB_REGION_SIZE, RC_MFB_BLOCK_SIZE, RC_MFB_ITEM_WIDTH, RC_MFB_META_W, CQ_MFB_REGIONS, CQ_MFB_REGION_SIZE, CQ_MFB_BLOCK_SIZE, CQ_MFB_ITEM_WIDTH, CQ_MFB_META_W, RQ_MFB_ITEM_WIDTH, CC_MFB_ITEM_WIDTH, RQ_MFB_META_W, CC_MFB_META_W, DMA_UPHDR_WIDTH_W, DMA_DOWNHDR_WIDTH_W, DMA_PORTS, PCIE_ENDPOINTS) extends uvm_sequencer;

    `uvm_component_param_utils(uvm_pcie::virt_sequencer_base#(RC_MFB_REGIONS, RC_MFB_REGION_SIZE, RC_MFB_BLOCK_SIZE, RC_MFB_ITEM_WIDTH, RC_MFB_META_W, CQ_MFB_REGIONS, CQ_MFB_REGION_SIZE, CQ_MFB_BLOCK_SIZE, CQ_MFB_ITEM_WIDTH, CQ_MFB_META_W, RQ_MFB_ITEM_WIDTH, CC_MFB_ITEM_WIDTH, RQ_MFB_META_W, CC_MFB_META_W, DMA_UPHDR_WIDTH_W, DMA_DOWNHDR_WIDTH_W, DMA_PORTS, PCIE_ENDPOINTS))

    // MFB Data Sequencers
    uvm_logic_vector_array::sequencer#(RQ_MFB_ITEM_WIDTH) m_rq_mfb_data_sqr[DMA_PORTS];
    uvm_logic_vector_array::sequencer#(CC_MFB_ITEM_WIDTH) m_cc_mfb_data_sqr[DMA_PORTS];

    // MFB Metadata Sequencers
    uvm_logic_vector::sequencer#(RQ_MFB_META_W) m_rq_mfb_meta_sqr[DMA_PORTS];
    uvm_logic_vector::sequencer#(CC_MFB_META_W) m_cc_mfb_meta_sqr[DMA_PORTS];

    // MVB Data Sequencers
    uvm_logic_vector::sequencer#(DMA_UPHDR_WIDTH_W) m_rq_mvb_sqr[DMA_PORTS];

    // MFB DST RDY Sequencers
    uvm_mfb::sequencer #(RC_MFB_REGIONS, RC_MFB_REGION_SIZE, RC_MFB_BLOCK_SIZE, RC_MFB_ITEM_WIDTH, RC_MFB_META_W)    m_mfb_rc_dst_rdy_sqr[DMA_PORTS];
    uvm_mfb::sequencer #(CQ_MFB_REGIONS, CQ_MFB_REGION_SIZE, CQ_MFB_BLOCK_SIZE, CQ_MFB_ITEM_WIDTH, CQ_MFB_META_W)    m_mfb_cq_dst_rdy_sqr[DMA_PORTS];

    // MVB DST RDY Sequencers
    uvm_mvb::sequencer #(RC_MFB_REGIONS, DMA_DOWNHDR_WIDTH_W) m_mvb_rc_dst_rdy_sqr[DMA_PORTS];

    // MI Sequencer
    uvm_mi::sequencer_master#(32, 32) m_mi_sqr[PCIE_ENDPOINTS];

    // Reset sequencer
    uvm_reset::sequencer m_dma_reset;
    uvm_reset::sequencer m_mi_reset;
    uvm_reset::sequencer m_pcie_sysrst_n;

    function new(string name = "virt_sequencer", uvm_component parent);
        super.new(name, parent);
    endfunction

endclass

class virt_sequencer_intel#(RQ_MFB_ITEM_WIDTH, RQ_MFB_META_W, RC_MFB_REGIONS, RC_MFB_REGION_SIZE, RC_MFB_BLOCK_SIZE, RC_MFB_ITEM_WIDTH, RC_MFB_META_W, CQ_MFB_REGIONS, CQ_MFB_REGION_SIZE, CQ_MFB_BLOCK_SIZE, CQ_MFB_ITEM_WIDTH, CQ_MFB_META_W, CC_MFB_META_W, DMA_UPHDR_WIDTH_W, DMA_DOWNHDR_WIDTH_W, CC_MFB_REGIONS, CC_MFB_REGION_SIZE, CC_MFB_BLOCK_SIZE, CC_MFB_ITEM_WIDTH, AVST_UP_META_W, AVST_DOWN_META_W, DMA_PORTS, PCIE_ENDPOINTS, PCIE_CONS) extends virt_sequencer_base#(RC_MFB_REGIONS, RC_MFB_REGION_SIZE, RC_MFB_BLOCK_SIZE, RC_MFB_ITEM_WIDTH, RC_MFB_META_W, CQ_MFB_REGIONS, CQ_MFB_REGION_SIZE, CQ_MFB_BLOCK_SIZE, CQ_MFB_ITEM_WIDTH, CQ_MFB_META_W, RQ_MFB_ITEM_WIDTH, CC_MFB_ITEM_WIDTH, RQ_MFB_META_W, CC_MFB_META_W, DMA_UPHDR_WIDTH_W, DMA_DOWNHDR_WIDTH_W, DMA_PORTS, PCIE_ENDPOINTS);

    `uvm_component_param_utils(uvm_pcie::virt_sequencer_intel#(RQ_MFB_ITEM_WIDTH, RQ_MFB_META_W, RC_MFB_REGIONS, RC_MFB_REGION_SIZE, RC_MFB_BLOCK_SIZE, RC_MFB_ITEM_WIDTH, RC_MFB_META_W, CQ_MFB_REGIONS, CQ_MFB_REGION_SIZE, CQ_MFB_BLOCK_SIZE, CQ_MFB_ITEM_WIDTH, CQ_MFB_META_W, CC_MFB_META_W, DMA_UPHDR_WIDTH_W, DMA_DOWNHDR_WIDTH_W, CC_MFB_REGIONS, CC_MFB_REGION_SIZE, CC_MFB_BLOCK_SIZE, CC_MFB_ITEM_WIDTH, AVST_UP_META_W, AVST_DOWN_META_W, DMA_PORTS, PCIE_ENDPOINTS, PCIE_CONS))

    // AVALON Data Sequencers
    uvm_logic_vector_array::sequencer#(CQ_MFB_ITEM_WIDTH) m_avst_down_data_sqr[PCIE_CONS];

    // AVALON Metadata Sequencers
    uvm_logic_vector::sequencer#(AVST_DOWN_META_W) m_avst_down_meta_sqr[PCIE_CONS];

    // AVALON Ready Sequencer
    uvm_avst::sequencer #(CC_MFB_REGIONS, CC_MFB_REGION_SIZE, CC_MFB_BLOCK_SIZE, CC_MFB_ITEM_WIDTH, AVST_UP_META_W)  m_avst_up_rdy_sqr[PCIE_CONS];

    function new(string name = "virt_sequencer_intel", uvm_component parent);
        super.new(name, parent);
    endfunction

endclass

class virt_sequencer_xilinx#(RQ_MFB_REGIONS, RQ_MFB_ITEM_WIDTH, RQ_MFB_META_W, RC_MFB_REGIONS, RC_MFB_REGION_SIZE, RC_MFB_BLOCK_SIZE, RC_MFB_ITEM_WIDTH, RC_MFB_META_W, CQ_MFB_REGIONS, CQ_MFB_REGION_SIZE, CQ_MFB_BLOCK_SIZE, CQ_MFB_ITEM_WIDTH, CQ_MFB_META_W, CC_MFB_REGIONS, CC_MFB_ITEM_WIDTH, CC_MFB_META_W, DMA_UPHDR_WIDTH_W, DMA_DOWNHDR_WIDTH_W, AXI_DATA_WIDTH, AXI_CCUSER_WIDTH, AXI_RQUSER_WIDTH, AXI_CQUSER_WIDTH, DMA_PORTS, PCIE_ENDPOINTS, PCIE_CONS) extends virt_sequencer_base#(RC_MFB_REGIONS, RC_MFB_REGION_SIZE, RC_MFB_BLOCK_SIZE, RC_MFB_ITEM_WIDTH, RC_MFB_META_W, CQ_MFB_REGIONS, CQ_MFB_REGION_SIZE, CQ_MFB_BLOCK_SIZE, CQ_MFB_ITEM_WIDTH, CQ_MFB_META_W, RQ_MFB_ITEM_WIDTH, CC_MFB_ITEM_WIDTH, RQ_MFB_META_W, CC_MFB_META_W, DMA_UPHDR_WIDTH_W, DMA_DOWNHDR_WIDTH_W, DMA_PORTS, PCIE_ENDPOINTS);

    `uvm_component_param_utils(uvm_pcie::virt_sequencer_xilinx#(RQ_MFB_REGIONS, RQ_MFB_ITEM_WIDTH, RQ_MFB_META_W, RC_MFB_REGIONS, RC_MFB_REGION_SIZE, RC_MFB_BLOCK_SIZE, RC_MFB_ITEM_WIDTH, RC_MFB_META_W, CQ_MFB_REGIONS, CQ_MFB_REGION_SIZE, CQ_MFB_BLOCK_SIZE, CQ_MFB_ITEM_WIDTH, CQ_MFB_META_W, CC_MFB_REGIONS, CC_MFB_ITEM_WIDTH, CC_MFB_META_W, DMA_UPHDR_WIDTH_W, DMA_DOWNHDR_WIDTH_W, AXI_DATA_WIDTH, AXI_CCUSER_WIDTH, AXI_RQUSER_WIDTH, AXI_CQUSER_WIDTH, DMA_PORTS, PCIE_ENDPOINTS, PCIE_CONS))

    // AXI DATA Sequencers
    uvm_logic_vector_array::sequencer#(CQ_MFB_ITEM_WIDTH) m_axi_cq_data_sqr[PCIE_CONS];
    uvm_logic_vector_array::sequencer#(RC_MFB_ITEM_WIDTH) m_axi_rc_data_sqr[PCIE_CONS];
    // AXI HEADER Sequencer
    uvm_logic_vector::sequencer#(128) m_axi_cq_meta_sqr[PCIE_CONS];

    // AXI Ready Sequencers
    uvm_axi::sequencer #(AXI_DATA_WIDTH, AXI_CCUSER_WIDTH, CC_MFB_REGIONS) m_axi_cc_rdy_sqr[PCIE_CONS];
    uvm_axi::sequencer #(AXI_DATA_WIDTH, AXI_RQUSER_WIDTH, RQ_MFB_REGIONS) m_axi_rq_rdy_sqr[PCIE_CONS];

    function new(string name = "virt_sequencer_xilinx", uvm_component parent);
        super.new(name, parent);
    endfunction

endclass
