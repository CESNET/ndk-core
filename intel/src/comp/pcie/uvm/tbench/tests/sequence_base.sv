// sequence_base.sv: Virtual sequence
// Copyright (C) 2023 CESNET z. s. p. o.
// Author(s): Daniel Kriz <xkrizd01@vutbr.cz>

// SPDX-License-Identifier: BSD-3-Clause

class sequence_base#(RC_MFB_REGIONS, RC_MFB_REGION_SIZE, RC_MFB_BLOCK_SIZE, RC_MFB_ITEM_WIDTH, RC_MFB_META_W, CQ_MFB_REGIONS, CQ_MFB_REGION_SIZE, CQ_MFB_BLOCK_SIZE, CQ_MFB_ITEM_WIDTH, CQ_MFB_META_W, RQ_MFB_ITEM_WIDTH, CC_MFB_ITEM_WIDTH, RQ_MFB_META_W, CC_MFB_REGIONS, CC_MFB_REGION_SIZE, CC_MFB_BLOCK_SIZE, CC_MFB_META_W, DMA_UPHDR_WIDTH_W, DMA_DOWNHDR_WIDTH_W, DMA_PORTS, PCIE_CONS, PCIE_ENDPOINTS, TRANSACTION_COUNT, PCIE_TAG_WIDTH) extends uvm_sequence;

    `uvm_object_param_utils(test::sequence_base#(RC_MFB_REGIONS, RC_MFB_REGION_SIZE, RC_MFB_BLOCK_SIZE, RC_MFB_ITEM_WIDTH, RC_MFB_META_W, CQ_MFB_REGIONS, CQ_MFB_REGION_SIZE, CQ_MFB_BLOCK_SIZE, CQ_MFB_ITEM_WIDTH, CQ_MFB_META_W, RQ_MFB_ITEM_WIDTH, CC_MFB_ITEM_WIDTH, RQ_MFB_META_W, CC_MFB_REGIONS, CC_MFB_REGION_SIZE, CC_MFB_BLOCK_SIZE, CC_MFB_META_W, DMA_UPHDR_WIDTH_W, DMA_DOWNHDR_WIDTH_W, DMA_PORTS, PCIE_CONS, PCIE_ENDPOINTS, TRANSACTION_COUNT, PCIE_TAG_WIDTH))

    `uvm_declare_p_sequencer(uvm_pcie::virt_sequencer_base#(RC_MFB_REGIONS, RC_MFB_REGION_SIZE, RC_MFB_BLOCK_SIZE, RC_MFB_ITEM_WIDTH, RC_MFB_META_W, CQ_MFB_REGIONS, CQ_MFB_REGION_SIZE, CQ_MFB_BLOCK_SIZE, CQ_MFB_ITEM_WIDTH, CQ_MFB_META_W, RQ_MFB_ITEM_WIDTH, CC_MFB_ITEM_WIDTH, RQ_MFB_META_W, CC_MFB_META_W, DMA_UPHDR_WIDTH_W, DMA_DOWNHDR_WIDTH_W, DMA_PORTS, PCIE_ENDPOINTS))

    function new (string name = "sequence");
        super.new(name);
    endfunction

    logic[2-1 : 0] done[PCIE_CONS] = '{default:'0};
    uvm_pcie::fifo dma_size_fifo[DMA_PORTS];
    uvm_pcie::fifo dma_mvb_size_fifo[DMA_PORTS];
    uvm_pcie::fifo avst_size_fifo[PCIE_ENDPOINTS];
    // Start reset sequence
    uvm_reset::sequence_start m_dma_reset;
    uvm_reset::sequence_start m_mi_reset;
    uvm_reset::sequence_start m_pcie_sysrst_n;
    // DMA INTERFACES
    uvm_pcie::sequence_mfb_data#(RQ_MFB_ITEM_WIDTH, TRANSACTION_COUNT, 1'b0)                 m_mfb_rq_data_sq[DMA_PORTS];
    uvm_pcie::sequence_meta#(RQ_MFB_META_W, TRANSACTION_COUNT)                               m_mfb_rq_meta_sq[DMA_PORTS];
    uvm_pcie::sequence_mvb#(DMA_UPHDR_WIDTH_W, DMA_PORTS, TRANSACTION_COUNT, PCIE_TAG_WIDTH) m_mvb_rq_data_sq[DMA_PORTS];
    // High level data sequence libraries
    uvm_logic_vector_array::sequence_lib#(RQ_MFB_ITEM_WIDTH) m_mfb_rq_data_lib[DMA_PORTS];
    uvm_logic_vector_array::sequence_lib#(CC_MFB_ITEM_WIDTH) m_mfb_cc_data_lib[DMA_PORTS];
    uvm_logic_vector::sequence_endless#(RQ_MFB_META_W) m_mfb_rq_meta[DMA_PORTS];
    uvm_logic_vector::sequence_endless#(CC_MFB_META_W) m_mfb_cc_meta[DMA_PORTS];
    uvm_mfb::sequence_lib_tx  #(RC_MFB_REGIONS, RC_MFB_REGION_SIZE, RC_MFB_BLOCK_SIZE, RC_MFB_ITEM_WIDTH, RC_MFB_META_W)              m_mfb_rc_lib[DMA_PORTS];
    uvm_mvb::sequence_lib_tx #(RC_MFB_REGIONS, DMA_DOWNHDR_WIDTH_W)                                                                   m_mvb_rc_lib[DMA_PORTS];
    uvm_sequence #(uvm_mfb::sequence_item #(RC_MFB_REGIONS, RC_MFB_REGION_SIZE, RC_MFB_BLOCK_SIZE, RC_MFB_ITEM_WIDTH, RC_MFB_META_W)) m_mfb_rc_seq[DMA_PORTS];
    uvm_sequence #(uvm_mvb::sequence_item #(RC_MFB_REGIONS, DMA_DOWNHDR_WIDTH_W))                                                     m_mvb_rc_seq[DMA_PORTS];
    uvm_mfb::sequence_lib_tx  #(CQ_MFB_REGIONS, CQ_MFB_REGION_SIZE, CQ_MFB_BLOCK_SIZE, CQ_MFB_ITEM_WIDTH, CQ_MFB_META_W)              m_mfb_cq_lib[DMA_PORTS];
    uvm_sequence #(uvm_mfb::sequence_item #(CQ_MFB_REGIONS, CQ_MFB_REGION_SIZE, CQ_MFB_BLOCK_SIZE, CQ_MFB_ITEM_WIDTH, CQ_MFB_META_W)) m_mfb_cq_seq[DMA_PORTS];
    uvm_phase phase;

    virtual function void init(uvm_phase phase, uvm_down_hdr::tag_manager #(PCIE_TAG_WIDTH) tag_man);

        m_dma_reset     = uvm_reset::sequence_start::type_id::create("m_dma_reset");
        m_mi_reset      = uvm_reset::sequence_start::type_id::create("m_mi_reset");
        m_pcie_sysrst_n = uvm_reset::sequence_start::type_id::create("m_pcie_sysrst_n");

        for (int dma = 0; dma < DMA_PORTS; dma++) begin
            string i_string;
            i_string.itoa(dma);

            dma_size_fifo[dma]     = new();
            dma_mvb_size_fifo[dma] = new();

            m_mfb_rq_data_sq[dma] = uvm_pcie::sequence_mfb_data#(RQ_MFB_ITEM_WIDTH, TRANSACTION_COUNT, 1'b0)::type_id::create({"m_mfb_rq_data_sq_", i_string});
            m_mfb_rq_meta_sq[dma] = uvm_pcie::sequence_meta#(RQ_MFB_META_W, TRANSACTION_COUNT)::type_id::create({"m_mfb_rq_meta_sq_", i_string});
            m_mvb_rq_data_sq[dma] = uvm_pcie::sequence_mvb#(DMA_UPHDR_WIDTH_W, DMA_PORTS, TRANSACTION_COUNT, PCIE_TAG_WIDTH)::type_id::create({"m_mvb_rq_data_sq_", i_string});

            m_mfb_rq_meta[dma]     = uvm_logic_vector::sequence_endless#(RQ_MFB_META_W)::type_id::create({"m_mfb_rq_meta_", i_string});
            m_mfb_cc_meta[dma]     = uvm_logic_vector::sequence_endless#(CC_MFB_META_W)::type_id::create({"m_mfb_cc_meta_", i_string});
            m_mfb_rq_data_lib[dma] = uvm_logic_vector_array::sequence_lib#(RQ_MFB_ITEM_WIDTH)::type_id::create({"m_mfb_rq_data_lib_", i_string});
            m_mfb_cc_data_lib[dma] = uvm_logic_vector_array::sequence_lib#(CC_MFB_ITEM_WIDTH)::type_id::create({"m_mfb_cc_data_lib_", i_string});

            m_mfb_rq_data_sq[dma].size_fifo     = dma_size_fifo[dma];
            m_mfb_rq_data_sq[dma].mvb_size_fifo = dma_mvb_size_fifo[dma];
            m_mfb_rq_meta_sq[dma].size_fifo     = dma_size_fifo[dma];
            // m_mvb_rq_data_sq[dma].size_fifo     = dma_mvb_size_fifo[dma];
            m_mvb_rq_data_sq[dma].size_fifo     = dma_size_fifo[dma];
            m_mvb_rq_data_sq[dma].port          = dma;
            m_mvb_rq_data_sq[dma].tag_man       = tag_man;

            m_mfb_rq_data_lib[dma].init_sequence();
            m_mfb_rq_data_lib[dma].min_random_count = 50;
            m_mfb_rq_data_lib[dma].max_random_count = 100;
            m_mfb_rq_data_lib[dma].cfg = new();
            m_mfb_rq_data_lib[dma].cfg.array_size_set(1, 1500);

            assert(m_mfb_rq_data_lib[dma].randomize());

            m_mfb_cc_data_lib[dma].init_sequence();
            m_mfb_cc_data_lib[dma].min_random_count = 50;
            m_mfb_cc_data_lib[dma].max_random_count = 100;
            m_mfb_cc_data_lib[dma].cfg = new();
            m_mfb_cc_data_lib[dma].cfg.array_size_set(1, 1500);
            assert(m_mfb_cc_data_lib[dma].randomize());

            m_mfb_rc_lib[dma]  = uvm_mfb::sequence_lib_tx#(RC_MFB_REGIONS, RC_MFB_REGION_SIZE, RC_MFB_BLOCK_SIZE, RC_MFB_ITEM_WIDTH, RC_MFB_META_W)::type_id::create({"m_mfb_rc_lib_", i_string});
            m_mvb_rc_lib[dma]  = uvm_mvb::sequence_lib_tx#(RC_MFB_REGIONS, DMA_DOWNHDR_WIDTH_W)::type_id::create({"m_mvb_rc_lib_", i_string});
            m_mfb_cq_lib[dma]  = uvm_mfb::sequence_lib_tx#(CQ_MFB_REGIONS, CQ_MFB_REGION_SIZE, CQ_MFB_BLOCK_SIZE, CQ_MFB_ITEM_WIDTH, CQ_MFB_META_W)::type_id::create({"m_mfb_cq_lib_", i_string});

            m_mfb_rc_lib[dma].init_sequence();
            m_mfb_rc_lib[dma].min_random_count = 100;
            m_mfb_rc_lib[dma].max_random_count = 200;
            m_mfb_rc_seq[dma] = m_mfb_rc_lib[dma];

            m_mvb_rc_lib[dma].init_sequence();
            m_mvb_rc_lib[dma].min_random_count = 100;
            m_mvb_rc_lib[dma].max_random_count = 200;
            m_mvb_rc_seq[dma] = m_mvb_rc_lib[dma];

            m_mfb_cq_lib[dma].init_sequence();
            m_mfb_cq_lib[dma].min_random_count = 100;
            m_mfb_cq_lib[dma].max_random_count = 200;
            m_mfb_cq_seq[dma] = m_mfb_cq_lib[dma];
        end

        this.phase = phase;

    endfunction

    virtual task run_mfb_rc(int unsigned index);
        forever begin
            assert(m_mfb_rc_seq[index].randomize());
            $write("m_mfb_rc_seq running \n");
            m_mfb_rc_seq[index].start(p_sequencer.m_mfb_rc_dst_rdy_sqr[index]);
        end
    endtask

    virtual task run_mvb_rc(int unsigned index);
        forever begin
            assert(m_mvb_rc_seq[index].randomize());
            $write("m_mvb_rc_seq running \n");
            m_mvb_rc_seq[index].start(p_sequencer.m_mvb_rc_dst_rdy_sqr[index]);
        end
    endtask

    virtual task run_mfb_cq(int unsigned index);
        forever begin
            assert(m_mfb_cq_seq[index].randomize());
            $write("m_mfb_cq_seq running \n");
            m_mfb_cq_seq[index].start(p_sequencer.m_mfb_cq_dst_rdy_sqr[index]);
        end
    endtask

    virtual task run_reset(uvm_reset::sequence_start m_reset, uvm_reset::sequencer m_reset_sqr);
        assert(m_reset.randomize());
        m_reset.start(m_reset_sqr);
    endtask

    virtual task run_mfb_rq_data(int unsigned index);
        $write("m_mfb_rq_data_sq running \n");
        assert(m_mfb_rq_data_sq[index].randomize());
        m_mfb_rq_data_sq[index].start(p_sequencer.m_rq_mfb_data_sqr[index]);
        // done[index][0] = 1'b1;
    endtask

    virtual task run_mfb_rq_meta(int unsigned index);
        $write("m_mfb_rq_meta_sq running \n");
        assert(m_mfb_rq_meta_sq[index].randomize());
        m_mfb_rq_meta_sq[index].start(p_sequencer.m_rq_mfb_meta_sqr[index]);
        // done[index][1] = 1'b1;
    endtask

    virtual task run_mvb_rq_data(int unsigned index);
        $write("m_mvb_rq_data_sq running \n");
        assert(m_mvb_rq_data_sq[index].randomize());
        m_mvb_rq_data_sq[index].start(p_sequencer.m_rq_mvb_sqr[index]);
        // done[index][2] = 1'b1;
    endtask

    virtual task run_mfb_cc_data(int unsigned index);
        $write("m_mfb_cc_data_lib running \n");
        m_mfb_cc_data_lib[index].start(p_sequencer.m_cc_mfb_data_sqr[index]);
    endtask

    virtual task run_mfb_cc_meta(int unsigned index);
        $write("m_mfb_cc_meta running \n");
        assert(m_mfb_cc_meta[index].randomize());
        m_mfb_cc_meta[index].start(p_sequencer.m_cc_mfb_meta_sqr[index]);
    endtask

    task body();
        fork
            run_reset(m_dma_reset, p_sequencer.m_dma_reset);
            run_reset(m_mi_reset, p_sequencer.m_mi_reset);
            run_reset(m_pcie_sysrst_n, p_sequencer.m_pcie_sysrst_n);
        join_none

        #(1000ns);

        for (int dma = 0; dma < DMA_PORTS; dma++) begin
            fork
                automatic int index = dma;
                run_mfb_rc(index);
                run_mvb_rc(index);
                run_mfb_cq(index);
            join_none
        end

    endtask

endclass