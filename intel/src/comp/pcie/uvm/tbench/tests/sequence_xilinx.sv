// sequence_xilinx.sv: Virtual sequence for Xilinx
// Copyright (C) 2023 CESNET z. s. p. o.
// Author(s): Daniel Kriz <xkrizd01@vutbr.cz>

// SPDX-License-Identifier: BSD-3-Clause

class sequence_xilinx#(RQ_MFB_REGIONS, RC_MFB_REGIONS, RC_MFB_REGION_SIZE, RC_MFB_BLOCK_SIZE, RC_MFB_ITEM_WIDTH, RC_MFB_META_W, CQ_MFB_REGIONS, CQ_MFB_REGION_SIZE, CQ_MFB_BLOCK_SIZE, CQ_MFB_ITEM_WIDTH, CQ_MFB_META_W, RQ_MFB_ITEM_WIDTH, CC_MFB_ITEM_WIDTH, RQ_MFB_META_W, CC_MFB_REGIONS, CC_MFB_REGION_SIZE, CC_MFB_BLOCK_SIZE, CC_MFB_META_W, DMA_UPHDR_WIDTH_W, DMA_DOWNHDR_WIDTH_W, AVST_UP_META_W, AVST_DOWN_META_W, DMA_PORTS, PCIE_ENDPOINTS, PCIE_CONS, TRANSACTION_COUNT, AXI_DATA_WIDTH, AXI_CQUSER_WIDTH, AXI_CCUSER_WIDTH, AXI_RCUSER_WIDTH, AXI_RQUSER_WIDTH, PCIE_TAG_WIDTH) extends sequence_base #(RC_MFB_REGIONS, RC_MFB_REGION_SIZE, RC_MFB_BLOCK_SIZE, RC_MFB_ITEM_WIDTH, RC_MFB_META_W, CQ_MFB_REGIONS, CQ_MFB_REGION_SIZE, CQ_MFB_BLOCK_SIZE, CQ_MFB_ITEM_WIDTH, CQ_MFB_META_W, RQ_MFB_ITEM_WIDTH, CC_MFB_ITEM_WIDTH, RQ_MFB_META_W, CC_MFB_REGIONS, CC_MFB_REGION_SIZE, CC_MFB_BLOCK_SIZE, CC_MFB_META_W, DMA_UPHDR_WIDTH_W, DMA_DOWNHDR_WIDTH_W, DMA_PORTS, PCIE_CONS, PCIE_ENDPOINTS, TRANSACTION_COUNT, PCIE_TAG_WIDTH);

    `uvm_object_param_utils(test::sequence_xilinx#(RQ_MFB_REGIONS, RC_MFB_REGIONS, RC_MFB_REGION_SIZE, RC_MFB_BLOCK_SIZE, RC_MFB_ITEM_WIDTH, RC_MFB_META_W, CQ_MFB_REGIONS, CQ_MFB_REGION_SIZE, CQ_MFB_BLOCK_SIZE, CQ_MFB_ITEM_WIDTH, CQ_MFB_META_W, RQ_MFB_ITEM_WIDTH, CC_MFB_ITEM_WIDTH, RQ_MFB_META_W, CC_MFB_REGIONS, CC_MFB_REGION_SIZE, CC_MFB_BLOCK_SIZE, CC_MFB_META_W, DMA_UPHDR_WIDTH_W, DMA_DOWNHDR_WIDTH_W, AVST_UP_META_W, AVST_DOWN_META_W, DMA_PORTS, PCIE_ENDPOINTS, PCIE_CONS, TRANSACTION_COUNT, AXI_DATA_WIDTH, AXI_CQUSER_WIDTH, AXI_CCUSER_WIDTH, AXI_RCUSER_WIDTH, AXI_RQUSER_WIDTH, PCIE_TAG_WIDTH))

    `uvm_declare_p_sequencer(uvm_pcie::virt_sequencer_xilinx#(RQ_MFB_REGIONS, RQ_MFB_ITEM_WIDTH, RQ_MFB_META_W, RC_MFB_REGIONS, RC_MFB_REGION_SIZE, RC_MFB_BLOCK_SIZE, RC_MFB_ITEM_WIDTH, RC_MFB_META_W, CQ_MFB_REGIONS, CQ_MFB_REGION_SIZE, CQ_MFB_BLOCK_SIZE, CQ_MFB_ITEM_WIDTH, CQ_MFB_META_W, CC_MFB_REGIONS, CC_MFB_ITEM_WIDTH, CC_MFB_META_W, DMA_UPHDR_WIDTH_W, DMA_DOWNHDR_WIDTH_W, AXI_DATA_WIDTH, AXI_CCUSER_WIDTH, AXI_RQUSER_WIDTH, AXI_CQUSER_WIDTH, DMA_PORTS, PCIE_ENDPOINTS, PCIE_CONS))

    uvm_axi::sequence_lib_tx #(AXI_DATA_WIDTH, AXI_CCUSER_WIDTH, CC_MFB_REGIONS) m_axi_cc_lib[PCIE_ENDPOINTS];
    uvm_axi::sequence_lib_tx #(AXI_DATA_WIDTH, AXI_RQUSER_WIDTH, RQ_MFB_REGIONS) m_axi_rq_lib[PCIE_ENDPOINTS];

    uvm_pcie::sequence_avst_down_meta#(128, TRANSACTION_COUNT, 1'b1, PCIE_TAG_WIDTH) m_axi_cq_meta_sq[PCIE_ENDPOINTS];
    uvm_pcie::sequence_mfb_data#(CQ_MFB_ITEM_WIDTH, TRANSACTION_COUNT, 1'b1)         m_axi_cq_data_sq[PCIE_CONS];

    function new (string name = "sequence_intel");
        super.new(name);
    endfunction

    virtual function void init(uvm_phase phase, uvm_down_hdr::tag_manager #(PCIE_TAG_WIDTH) tag_man);
        super.init(phase, tag_man);

        for (int pcie_e = 0; pcie_e < PCIE_ENDPOINTS; pcie_e++) begin
            string i_string;
            i_string.itoa(pcie_e);

            avst_size_fifo[pcie_e] = new();

            m_axi_cc_lib[pcie_e]     = uvm_axi::sequence_lib_tx#(AXI_DATA_WIDTH, AXI_CCUSER_WIDTH, CC_MFB_REGIONS)::type_id::create({"m_axi_cc_lib", i_string});
            m_axi_rq_lib[pcie_e]     = uvm_axi::sequence_lib_tx#(AXI_DATA_WIDTH, AXI_RQUSER_WIDTH, RQ_MFB_REGIONS)::type_id::create({"m_axi_rq_lib", i_string});
            m_axi_cq_meta_sq[pcie_e] = uvm_pcie::sequence_avst_down_meta#(128, TRANSACTION_COUNT, 1'b1, PCIE_TAG_WIDTH)::type_id::create({"m_axi_cq_meta_sq_", i_string});
            m_axi_cq_data_sq[pcie_e] = uvm_pcie::sequence_mfb_data#(CQ_MFB_ITEM_WIDTH, TRANSACTION_COUNT, 1'b1)::type_id::create({"m_axi_cq_data_sq_", i_string});

            m_axi_cq_meta_sq[pcie_e].size_fifo = avst_size_fifo[pcie_e];
            m_axi_cq_data_sq[pcie_e].size_fifo = avst_size_fifo[pcie_e];
            m_axi_cq_data_sq[pcie_e].mvb_size_fifo = avst_size_fifo[pcie_e];

            m_axi_cc_lib[pcie_e].init_sequence();
            m_axi_cc_lib[pcie_e].min_random_count = 100;
            m_axi_cc_lib[pcie_e].max_random_count = 200;

            m_axi_rq_lib[pcie_e].init_sequence();
            m_axi_rq_lib[pcie_e].min_random_count = 100;
            m_axi_rq_lib[pcie_e].max_random_count = 200;
        end

    endfunction

    virtual task run_axi_cc(int unsigned index);
        forever begin
            assert(m_axi_cc_lib[index].randomize());
            $write("m_axi_cc_lib running \n");
            m_axi_cc_lib[index].start(p_sequencer.m_axi_cc_rdy_sqr[index]);
        end
    endtask

    virtual task run_axi_rq(int unsigned index);
        forever begin
            assert(m_axi_rq_lib[index].randomize());
            $write("m_axi_rq_lib running \n");
            m_axi_rq_lib[index].start(p_sequencer.m_axi_rq_rdy_sqr[index]);
        end
    endtask

    virtual task run_axi_cq_meta(int unsigned index);
        $write("m_axi_cq_meta_sq running \n");
        assert(m_axi_cq_meta_sq[index].randomize());
        m_axi_cq_meta_sq[index].start(p_sequencer.m_axi_cq_meta_sqr[index]);
        done[index][0] = 1'b1;
        done[index][1] = 1'b1;
    endtask

    virtual task run_axi_cq_data(int unsigned index);
        $write("m_axi_cq_data_sq running \n");
        assert(m_axi_cq_data_sq[index].randomize());
        m_axi_cq_data_sq[index].start(p_sequencer.m_axi_cq_data_sqr[index]);
    endtask

    task body();
        super.body();

        for (int pcie_e = 0; pcie_e < PCIE_ENDPOINTS; pcie_e++) begin
            fork
                automatic int index = pcie_e;
                run_axi_cc(index);
                run_axi_rq(index);
                run_axi_cq_data(index);
                run_axi_cq_meta(index);
            join_none
        end

        for (int dma = 0; dma < DMA_PORTS; dma++) begin
            fork
                automatic int index = dma;
                run_mfb_rq_data(index);
                run_mfb_rq_meta(index);
                run_mvb_rq_data(index);
            join_any
        end
        wait(done[0] == '1);
        #(120000ns);
        $write("EVERYTHING DONE\n");
    endtask

endclass