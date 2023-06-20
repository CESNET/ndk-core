//-- test.sv: Verification test 
//-- Copyright (C) 2023 CESNET z. s. p. o.
//-- Author:   Daniel Kříž <xkrizd01@vutbr.cz>

//-- SPDX-License-Identifier: BSD-3-Clause 

class ex_test extends uvm_test;
    `uvm_component_utils(test::ex_test);

    localparam IS_INTEL_DEV = (DEVICE == "STRATIX10" || DEVICE == "AGILEX");
    bit timeout;
    uvm_pcie::env #(CQ_MFB_REGIONS, CC_MFB_REGIONS, RQ_MFB_REGIONS, RC_MFB_REGIONS, CQ_MFB_REGION_SIZE, CC_MFB_REGION_SIZE, RQ_MFB_REGION_SIZE, RC_MFB_REGION_SIZE, CQ_MFB_BLOCK_SIZE, CC_MFB_BLOCK_SIZE, RQ_MFB_BLOCK_SIZE, RC_MFB_BLOCK_SIZE, CQ_MFB_ITEM_WIDTH, CC_MFB_ITEM_WIDTH, RQ_MFB_ITEM_WIDTH, RC_MFB_ITEM_WIDTH, RQ_MFB_META_W, RC_MFB_META_W, CQ_MFB_META_W, CC_MFB_META_W, DMA_UPHDR_WIDTH_W, DMA_DOWNHDR_WIDTH_W, DEVICE, PCIE_ENDPOINT_TYPE, DMA_PORTS, PCIE_ENDPOINTS, PCIE_CONS, AVST_DOWN_META_W, AVST_UP_META_W, AXI_DATA_WIDTH, AXI_CQUSER_WIDTH, AXI_CCUSER_WIDTH, AXI_RCUSER_WIDTH, AXI_RQUSER_WIDTH, AXI_STRADDLING, DMA_CLK_PERIOD, PCIE_UPHDR_WIDTH, PCIE_DOWNHDR_WIDTH, RCB, PTC_DISABLE, PCIE_TAG_WIDTH) m_env;

    // ------------------------------------------------------------------------
    // Functions
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        m_env = uvm_pcie::env #(CQ_MFB_REGIONS, CC_MFB_REGIONS, RQ_MFB_REGIONS, RC_MFB_REGIONS, CQ_MFB_REGION_SIZE, CC_MFB_REGION_SIZE, RQ_MFB_REGION_SIZE, RC_MFB_REGION_SIZE, CQ_MFB_BLOCK_SIZE, CC_MFB_BLOCK_SIZE, RQ_MFB_BLOCK_SIZE, RC_MFB_BLOCK_SIZE, CQ_MFB_ITEM_WIDTH, CC_MFB_ITEM_WIDTH, RQ_MFB_ITEM_WIDTH, RC_MFB_ITEM_WIDTH, RQ_MFB_META_W, RC_MFB_META_W, CQ_MFB_META_W, CC_MFB_META_W, DMA_UPHDR_WIDTH_W, DMA_DOWNHDR_WIDTH_W, DEVICE, PCIE_ENDPOINT_TYPE, DMA_PORTS, PCIE_ENDPOINTS, PCIE_CONS, AVST_DOWN_META_W, AVST_UP_META_W, AXI_DATA_WIDTH, AXI_CQUSER_WIDTH, AXI_CCUSER_WIDTH, AXI_RCUSER_WIDTH, AXI_RQUSER_WIDTH, AXI_STRADDLING, DMA_CLK_PERIOD, PCIE_UPHDR_WIDTH, PCIE_DOWNHDR_WIDTH, RCB, PTC_DISABLE, PCIE_TAG_WIDTH)::type_id::create("m_env", this);
    endfunction

    task test_wait_timeout(int unsigned time_length);
        #(time_length*1us);
    endtask

    task test_wait_result();
        do begin
            #(60000ns);
        end while (m_env.m_scoreboard.used() != 0);
        timeout = 0;
    endtask

    // ------------------------------------------------------------------------
    // Create environment and Run sequences o their sequencers
    task run_seq_rx(uvm_phase phase);

        sequence_base #(RC_MFB_REGIONS, RC_MFB_REGION_SIZE, RC_MFB_BLOCK_SIZE, RC_MFB_ITEM_WIDTH, RC_MFB_META_W, CQ_MFB_REGIONS, CQ_MFB_REGION_SIZE, CQ_MFB_BLOCK_SIZE, CQ_MFB_ITEM_WIDTH, CQ_MFB_META_W, RQ_MFB_ITEM_WIDTH, CC_MFB_ITEM_WIDTH, RQ_MFB_META_W, CC_MFB_REGIONS, CC_MFB_REGION_SIZE, CC_MFB_BLOCK_SIZE, CC_MFB_META_W, DMA_UPHDR_WIDTH_W, DMA_DOWNHDR_WIDTH_W, DMA_PORTS, PCIE_CONS, PCIE_ENDPOINTS, TRANSACTION_COUNT, PCIE_TAG_WIDTH) m_vseq;

        if (IS_INTEL_DEV) 
            m_vseq = sequence_intel #(RC_MFB_REGIONS, RC_MFB_REGION_SIZE, RC_MFB_BLOCK_SIZE, RC_MFB_ITEM_WIDTH, RC_MFB_META_W, CQ_MFB_REGIONS, CQ_MFB_REGION_SIZE, CQ_MFB_BLOCK_SIZE, CQ_MFB_ITEM_WIDTH, CQ_MFB_META_W, RQ_MFB_ITEM_WIDTH, CC_MFB_ITEM_WIDTH, RQ_MFB_META_W, CC_MFB_REGIONS, CC_MFB_REGION_SIZE, CC_MFB_BLOCK_SIZE, CC_MFB_META_W, DMA_UPHDR_WIDTH_W, DMA_DOWNHDR_WIDTH_W, AVST_UP_META_W, AVST_DOWN_META_W, DMA_PORTS, PCIE_CONS, PCIE_ENDPOINTS, TRANSACTION_COUNT, AXI_DATA_WIDTH, AXI_CQUSER_WIDTH, AXI_CCUSER_WIDTH, AXI_RCUSER_WIDTH, AXI_RQUSER_WIDTH, PCIE_TAG_WIDTH)::type_id::create("m_vseq");
        else
            m_vseq = sequence_xilinx #(RQ_MFB_REGIONS, RC_MFB_REGIONS, RC_MFB_REGION_SIZE, RC_MFB_BLOCK_SIZE, RC_MFB_ITEM_WIDTH, RC_MFB_META_W, CQ_MFB_REGIONS, CQ_MFB_REGION_SIZE, CQ_MFB_BLOCK_SIZE, CQ_MFB_ITEM_WIDTH, CQ_MFB_META_W, RQ_MFB_ITEM_WIDTH, CC_MFB_ITEM_WIDTH, RQ_MFB_META_W, CC_MFB_REGIONS, CC_MFB_REGION_SIZE, CC_MFB_BLOCK_SIZE, CC_MFB_META_W, DMA_UPHDR_WIDTH_W, DMA_DOWNHDR_WIDTH_W, AVST_UP_META_W, AVST_DOWN_META_W, DMA_PORTS, PCIE_ENDPOINTS, PCIE_CONS, TRANSACTION_COUNT, AXI_DATA_WIDTH, AXI_CQUSER_WIDTH, AXI_CCUSER_WIDTH, AXI_RCUSER_WIDTH, AXI_RQUSER_WIDTH, PCIE_TAG_WIDTH)::type_id::create("m_vseq");

        phase.raise_objection(this, "Start of rx sequence");

        m_vseq.init(phase, m_env.tag_man);

        assert(m_vseq.randomize());
        m_vseq.start(m_env.vscr);

        timeout = 1;
        fork
            test_wait_timeout(10);
            test_wait_result();
        join_any;
        timeout = 0;

        phase.drop_objection(this, "End of rx sequence");
    endtask

    virtual task run_phase(uvm_phase phase);
        run_seq_rx(phase);
    endtask

    function void report_phase(uvm_phase phase);
        `uvm_info(this.get_full_name(), {"\n\tTEST : ", this.get_type_name(), " END\n"}, UVM_NONE);
        if (timeout) begin
            `uvm_error(this.get_full_name(), "\n\t===================================================\n\tTIMEOUT SOME PACKET STUCK IN DESIGN\n\t===================================================\n\n");
        end
    endfunction
endclass
