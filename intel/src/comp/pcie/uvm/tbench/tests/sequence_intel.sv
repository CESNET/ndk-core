// sequence_intel.sv: Virtual sequence for Intel
// Copyright (C) 2023 CESNET z. s. p. o.
// Author(s): Daniel Kriz <xkrizd01@vutbr.cz>

// SPDX-License-Identifier: BSD-3-Clause

class sequence_intel#(RC_MFB_REGIONS, RC_MFB_REGION_SIZE, RC_MFB_BLOCK_SIZE, RC_MFB_ITEM_WIDTH, RC_MFB_META_W, CQ_MFB_REGIONS, CQ_MFB_REGION_SIZE, CQ_MFB_BLOCK_SIZE, CQ_MFB_ITEM_WIDTH, CQ_MFB_META_W, RQ_MFB_ITEM_WIDTH, CC_MFB_ITEM_WIDTH, RQ_MFB_META_W, CC_MFB_REGIONS, CC_MFB_REGION_SIZE, CC_MFB_BLOCK_SIZE, CC_MFB_META_W, DMA_UPHDR_WIDTH_W, DMA_DOWNHDR_WIDTH_W, AVST_UP_META_W, AVST_DOWN_META_W, DMA_PORTS, PCIE_CONS, PCIE_ENDPOINTS, TRANSACTION_COUNT, AXI_DATA_WIDTH, AXI_CQUSER_WIDTH, AXI_CCUSER_WIDTH, AXI_RCUSER_WIDTH, AXI_RQUSER_WIDTH, PCIE_TAG_WIDTH) extends sequence_base #(RC_MFB_REGIONS, RC_MFB_REGION_SIZE, RC_MFB_BLOCK_SIZE, RC_MFB_ITEM_WIDTH, RC_MFB_META_W, CQ_MFB_REGIONS, CQ_MFB_REGION_SIZE, CQ_MFB_BLOCK_SIZE, CQ_MFB_ITEM_WIDTH, CQ_MFB_META_W, RQ_MFB_ITEM_WIDTH, CC_MFB_ITEM_WIDTH, RQ_MFB_META_W, CC_MFB_REGIONS, CC_MFB_REGION_SIZE, CC_MFB_BLOCK_SIZE, CC_MFB_META_W, DMA_UPHDR_WIDTH_W, DMA_DOWNHDR_WIDTH_W, DMA_PORTS, PCIE_CONS, PCIE_ENDPOINTS, TRANSACTION_COUNT, PCIE_TAG_WIDTH);

    `uvm_object_param_utils(test::sequence_intel#(RC_MFB_REGIONS, RC_MFB_REGION_SIZE, RC_MFB_BLOCK_SIZE, RC_MFB_ITEM_WIDTH, RC_MFB_META_W, CQ_MFB_REGIONS, CQ_MFB_REGION_SIZE, CQ_MFB_BLOCK_SIZE, CQ_MFB_ITEM_WIDTH, CQ_MFB_META_W, RQ_MFB_ITEM_WIDTH, CC_MFB_ITEM_WIDTH, RQ_MFB_META_W, CC_MFB_REGIONS, CC_MFB_REGION_SIZE, CC_MFB_BLOCK_SIZE, CC_MFB_META_W, DMA_UPHDR_WIDTH_W, DMA_DOWNHDR_WIDTH_W, AVST_UP_META_W, AVST_DOWN_META_W, DMA_PORTS, PCIE_CONS, PCIE_ENDPOINTS, TRANSACTION_COUNT, AXI_DATA_WIDTH, AXI_CQUSER_WIDTH, AXI_CCUSER_WIDTH, AXI_RCUSER_WIDTH, AXI_RQUSER_WIDTH, PCIE_TAG_WIDTH))

    `uvm_declare_p_sequencer(uvm_pcie::virt_sequencer_intel#(RQ_MFB_ITEM_WIDTH, RQ_MFB_META_W, RC_MFB_REGIONS, RC_MFB_REGION_SIZE, RC_MFB_BLOCK_SIZE, RC_MFB_ITEM_WIDTH, RC_MFB_META_W, CQ_MFB_REGIONS, CQ_MFB_REGION_SIZE, CQ_MFB_BLOCK_SIZE, CQ_MFB_ITEM_WIDTH, CQ_MFB_META_W, CC_MFB_META_W, DMA_UPHDR_WIDTH_W, DMA_DOWNHDR_WIDTH_W, CC_MFB_REGIONS, CC_MFB_REGION_SIZE, CC_MFB_BLOCK_SIZE, CC_MFB_ITEM_WIDTH, AVST_UP_META_W, AVST_DOWN_META_W, DMA_PORTS, PCIE_ENDPOINTS, PCIE_CONS))

    function new (string name = "sequence_intel");
        super.new(name);
    endfunction

    uvm_pcie::sequence_mfb_data#(CQ_MFB_ITEM_WIDTH, TRANSACTION_COUNT, 1'b0)                                              m_avst_down_data_sq[PCIE_CONS];
    uvm_pcie::sequence_avst_down_meta#(AVST_DOWN_META_W, TRANSACTION_COUNT, 1'b0, PCIE_TAG_WIDTH)                         m_avst_down_meta_sq[PCIE_CONS];
    uvm_avst::sequence_lib_tx #(CC_MFB_REGIONS, CC_MFB_REGION_SIZE, CC_MFB_BLOCK_SIZE, CC_MFB_ITEM_WIDTH, AVST_UP_META_W) m_avst_up_lib[PCIE_CONS];

    virtual function void init(uvm_phase phase, uvm_down_hdr::tag_manager #(PCIE_TAG_WIDTH) tag_man);
        super.init(phase, tag_man);

        for (int pcie_c = 0; pcie_c < PCIE_CONS; pcie_c++) begin
            string i_string;
            i_string.itoa(pcie_c);

            m_avst_up_lib[pcie_c]       = uvm_avst::sequence_lib_tx#(CC_MFB_REGIONS, CC_MFB_REGION_SIZE, CC_MFB_BLOCK_SIZE, CC_MFB_ITEM_WIDTH, AVST_UP_META_W)::type_id::create({"m_avst_up_lib_", i_string});
            m_avst_down_data_sq[pcie_c] = uvm_pcie::sequence_mfb_data#(CQ_MFB_ITEM_WIDTH, TRANSACTION_COUNT, 1'b0)::type_id::create({"m_avst_down_data_sq_", i_string});
            m_avst_down_meta_sq[pcie_c] = uvm_pcie::sequence_avst_down_meta#(AVST_DOWN_META_W, TRANSACTION_COUNT, 1'b0, PCIE_TAG_WIDTH)::type_id::create({"m_avst_down_meta_sq_", i_string});

            avst_size_fifo[pcie_c] = new();

            m_avst_down_data_sq[pcie_c].size_fifo = avst_size_fifo[pcie_c];
            // m_avst_down_data_sq[pcie_c].mvb_size_fifo = dma_mvb_size_fifo[pcie_c];
            m_avst_down_data_sq[pcie_c].mvb_size_fifo = avst_size_fifo[pcie_c];
            m_avst_down_meta_sq[pcie_c].size_fifo = avst_size_fifo[pcie_c];

            m_avst_up_lib[pcie_c].init_sequence();
            m_avst_up_lib[pcie_c].min_random_count = 100;
            m_avst_up_lib[pcie_c].max_random_count = 200;
        end
    endfunction

    virtual task run_avst_up(int unsigned index);
        forever begin
            assert(m_avst_up_lib[index].randomize());
            $write("m_avst_up_lib running \n");
            m_avst_up_lib[index].start(p_sequencer.m_avst_up_rdy_sqr[index]);
        end
    endtask

    virtual task run_avst_down_data(int unsigned index);
        $write("m_avst_data_sq running \n");
        assert(m_avst_down_data_sq[index].randomize());
        m_avst_down_data_sq[index].start(p_sequencer.m_avst_down_data_sqr[index]);
    endtask

    virtual task run_avst_down_meta(int unsigned index);
        $write("m_avst_down_meta_sq running \n");
        assert(m_avst_down_meta_sq[index].randomize());
        m_avst_down_meta_sq[index].start(p_sequencer.m_avst_down_meta_sqr[index]);
        done[index][0] = 1'b1;
        done[index][1] = 1'b1;
    endtask

    task body();
        super.body();

        for (int pcie_c = 0; pcie_c < PCIE_CONS; pcie_c++) begin
            fork
                automatic int index = pcie_c;
                run_avst_up(index);
                run_avst_down_data(index);
                run_avst_down_meta(index);
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