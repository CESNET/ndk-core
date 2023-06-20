//-- scoreboard.sv: Scoreboard for verification
//-- Copyright (C) 2023 CESNET z. s. p. o.
//-- Author:   Daniel Kříž <xkrizd01@vutbr.cz>

//-- SPDX-License-Identifier: BSD-3-Clause

class scoreboard #(CQ_MFB_ITEM_WIDTH, CQ_MFB_REGIONS, CC_MFB_ITEM_WIDTH, RQ_MFB_ITEM_WIDTH, RC_MFB_ITEM_WIDTH, AVST_DOWN_META_W, AVST_UP_META_W, AXI_CQUSER_WIDTH, AXI_CCUSER_WIDTH, AXI_RCUSER_WIDTH, AXI_RQUSER_WIDTH, RQ_MFB_META_W, RC_MFB_META_W, CQ_MFB_META_W, CC_MFB_META_W, DEVICE, ENDPOINT_TYPE, RQ_MFB_BLOCK_SIZE, DMA_UPHDR_WIDTH_W, DMA_DOWNHDR_WIDTH_W, PCIE_DOWNHDR_WIDTH, DMA_PORTS, PCIE_ENDPOINTS, PTC_DISABLE, PCIE_TAG_WIDTH) extends uvm_scoreboard;

    `uvm_component_utils(uvm_pcie::scoreboard #(CQ_MFB_ITEM_WIDTH, CQ_MFB_REGIONS, CC_MFB_ITEM_WIDTH, RQ_MFB_ITEM_WIDTH, RC_MFB_ITEM_WIDTH, AVST_DOWN_META_W, AVST_UP_META_W, AXI_CQUSER_WIDTH, AXI_CCUSER_WIDTH, AXI_RCUSER_WIDTH, AXI_RQUSER_WIDTH, RQ_MFB_META_W, RC_MFB_META_W, CQ_MFB_META_W, CC_MFB_META_W, DEVICE, ENDPOINT_TYPE, RQ_MFB_BLOCK_SIZE, DMA_UPHDR_WIDTH_W, DMA_DOWNHDR_WIDTH_W, PCIE_DOWNHDR_WIDTH, DMA_PORTS, PCIE_ENDPOINTS, PTC_DISABLE, PCIE_TAG_WIDTH))

    localparam IS_INTEL_DEV = (DEVICE == "STRATIX10" || DEVICE == "AGILEX");

    // Analysis components.
    uvm_analysis_export #(uvm_logic_vector_array::sequence_item#(CC_MFB_ITEM_WIDTH))    analysis_imp_avst_up_data[PCIE_ENDPOINTS];
    uvm_analysis_export #(uvm_logic_vector::sequence_item#(AVST_UP_META_W))             analysis_imp_avst_up_meta[PCIE_ENDPOINTS];

    uvm_analysis_export #(uvm_logic_vector_array::sequence_item#(RQ_MFB_ITEM_WIDTH))    analysis_imp_axi_rq_data[PCIE_ENDPOINTS];
    uvm_analysis_export #(uvm_logic_vector_array::sequence_item#(RC_MFB_ITEM_WIDTH))    analysis_imp_mfb_rc_data[DMA_PORTS];
    uvm_analysis_export #(uvm_logic_vector::sequence_item#(DMA_DOWNHDR_WIDTH_W))        analysis_imp_mvb_rc_data[DMA_PORTS];

    // TODO: Create model and make comparators (This is use in case of DMA_BAR_ENABLE)
    // uvm_analysis_export #(uvm_logic_vector_array::sequence_item#(CQ_MFB_ITEM_WIDTH))    analysis_imp_mfb_cq_data[DMA_PORTS];
    // uvm_analysis_export #(uvm_logic_vector::sequence_item#(CQ_MFB_META_W))              analysis_imp_mfb_cq_meta[DMA_PORTS];

    // TODO: Use in case of no PTC
    // uvm_analysis_export #(uvm_logic_vector::sequence_item#(RC_MFB_META_W))              analysis_imp_mfb_rc_meta[DMA_PORTS];
    // uvm_common::subscriber #(uvm_logic_vector::sequence_item#(RQ_MFB_META_W))           analysis_imp_mfb_rq_meta[DMA_PORTS];

    uvm_analysis_export #(uvm_logic_vector_array::sequence_item#(CC_MFB_ITEM_WIDTH))    analysis_imp_axi_cc_data[PCIE_ENDPOINTS];

    uvm_common::subscriber #(uvm_logic_vector_array::sequence_item#(RQ_MFB_ITEM_WIDTH)) analysis_imp_mfb_rq_data[DMA_PORTS];
    uvm_common::subscriber #(uvm_logic_vector::sequence_item#(DMA_UPHDR_WIDTH_W))       analysis_imp_mvb_rq_data[DMA_PORTS];

    // TODO: Create model and make comparators (This is use in case of DMA_BAR_ENABLE)
    // uvm_common::subscriber #(uvm_logic_vector_array::sequence_item#(CC_MFB_ITEM_WIDTH)) analysis_imp_mfb_cc_data[DMA_PORTS];
    // uvm_common::subscriber #(uvm_logic_vector::sequence_item#(CC_MFB_META_W))           analysis_imp_mfb_cc_meta[DMA_PORTS];

    uvm_common::subscriber #(uvm_logic_vector_array::sequence_item#(RC_MFB_ITEM_WIDTH)) analysis_imp_axi_rc_data[PCIE_ENDPOINTS];
    uvm_common::subscriber #(uvm_logic_vector_array::sequence_item#(CQ_MFB_ITEM_WIDTH)) analysis_imp_axi_cq_data[PCIE_ENDPOINTS];
    uvm_common::subscriber #(uvm_logic_vector::sequence_item#(AXI_CQUSER_WIDTH))        analysis_imp_axi_cq_meta[PCIE_ENDPOINTS];

    uvm_common::subscriber #(uvm_logic_vector::sequence_item#(AVST_DOWN_META_W))        analysis_imp_avst_down_meta[PCIE_ENDPOINTS];
    uvm_common::subscriber #(uvm_logic_vector_array::sequence_item#(CQ_MFB_ITEM_WIDTH)) analysis_imp_avst_down_data[PCIE_ENDPOINTS];

    uvm_common::subscriber #(uvm_mi::sequence_item_response #(32))                      analysis_export_cc_mi[PCIE_ENDPOINTS];
    uvm_mtc::mi_subscriber #(32, 32)                                                    mi_scrb[PCIE_ENDPOINTS];

    // TODO: Create model and make comparators (This is use in case of DMA_BAR_ENABLE)
    // uvm_common::comparer_ordered #(uvm_logic_vector_array::sequence_item#(CQ_MFB_ITEM_WIDTH)) mfb_cq_data_cmp[DMA_PORTS];
    // uvm_common::comparer_ordered #(uvm_logic_vector::sequence_item#(CQ_MFB_META_W))           mfb_cq_meta_cmp[DMA_PORTS];

    // AXI COMPARE
    uvm_pcie::scoreboard_mtc_mfb_xilinx #(CC_MFB_ITEM_WIDTH)                                                     axi_cc_data_cmp[PCIE_ENDPOINTS];
    uvm_pcie::scoreboard_mfb_xilinx #(CC_MFB_ITEM_WIDTH, RQ_MFB_BLOCK_SIZE, PCIE_TAG_WIDTH)                      axi_rq_data_cmp[PCIE_ENDPOINTS];
    // UP COMPARE
    uvm_pcie::scoreboard_mfb #(CC_MFB_ITEM_WIDTH, RQ_MFB_BLOCK_SIZE)                                             avst_up_data_cmp[PCIE_ENDPOINTS];
    uvm_pcie::scoreboard_mvb #(AVST_UP_META_W, PCIE_TAG_WIDTH, uvm_logic_vector::sequence_item#(AVST_UP_META_W)) avst_up_meta_cmp[PCIE_ENDPOINTS];
    // DOWN COMPARE
    uvm_common::comparer_ordered#(uvm_mi::sequence_item_request #(32, 32, 0))                                    mi_rq_cmp[PCIE_ENDPOINTS];
    uvm_common::comparer_ordered #(uvm_logic_vector_array::sequence_item #(RC_MFB_ITEM_WIDTH))                   mfb_rc_data_cmp[PCIE_ENDPOINTS];
    uvm_common::comparer_ordered #(uvm_logic_vector::sequence_item#(DMA_DOWNHDR_WIDTH_W))                        mvb_rc_data_cmp[DMA_PORTS];

    // Convertors
    uvm_pcie::down_splitter #(CQ_MFB_ITEM_WIDTH, AVST_DOWN_META_W)                                                                avst_down_splitter[PCIE_ENDPOINTS];
    uvm_pcie::cc_meta_convertor #(CC_MFB_META_W, AVST_UP_META_W)                                                                  mfb_cc2avst_up[PCIE_ENDPOINTS];
    uvm_pcie::cq_mtc_meta_convertor #(AXI_CQUSER_WIDTH, CQ_MFB_ITEM_WIDTH, sv_pcie_meta_pack::PCIE_CQ_META_WIDTH, CQ_MFB_REGIONS) m_mtc_meta_c[PCIE_ENDPOINTS];

    // Models
    model_intel #(CQ_MFB_ITEM_WIDTH, CC_MFB_ITEM_WIDTH, RQ_MFB_ITEM_WIDTH, RC_MFB_ITEM_WIDTH, AVST_DOWN_META_W, AVST_UP_META_W, RQ_MFB_META_W, RC_MFB_META_W, CQ_MFB_META_W, CC_MFB_META_W, ENDPOINT_TYPE, DMA_UPHDR_WIDTH_W, DMA_DOWNHDR_WIDTH_W, DMA_PORTS, PCIE_ENDPOINTS, PCIE_TAG_WIDTH) m_model_intel;
    model_xilinx #(CQ_MFB_ITEM_WIDTH, CC_MFB_ITEM_WIDTH, RQ_MFB_ITEM_WIDTH, RC_MFB_ITEM_WIDTH, AXI_CQUSER_WIDTH, AXI_CCUSER_WIDTH, AXI_RCUSER_WIDTH, AXI_RQUSER_WIDTH, RQ_MFB_META_W, RC_MFB_META_W, CQ_MFB_META_W, CC_MFB_META_W, DMA_UPHDR_WIDTH_W, DMA_DOWNHDR_WIDTH_W, DMA_PORTS, PCIE_ENDPOINTS, PCIE_TAG_WIDTH) m_model_xilinx;
    uvm_mtc::model #(CQ_MFB_ITEM_WIDTH, DEVICE, ENDPOINT_TYPE, 32, 32)          m_rq_mtc_model[PCIE_ENDPOINTS];
    uvm_mtc::response_model #(CQ_MFB_ITEM_WIDTH, DEVICE, ENDPOINT_TYPE, 32, 32) m_rs_mtc_model[PCIE_ENDPOINTS];

    // Contructor of scoreboard.
    function new(string name, uvm_component parent);
        super.new(name, parent);
        // INPUT Analysis ports
        if (IS_INTEL_DEV) begin
            for (int unsigned pcie_e = 0; pcie_e < PCIE_ENDPOINTS; pcie_e++) begin
                string i_string;
                i_string.itoa(pcie_e);

                analysis_imp_avst_up_data[pcie_e] = new({"analysis_imp_avst_up_data_", i_string}, this);
                analysis_imp_avst_up_meta[pcie_e] = new({"analysis_imp_avst_up_meta_", i_string}, this);
            end

        end else begin
            for (int unsigned pcie_e = 0; pcie_e < PCIE_ENDPOINTS; pcie_e++) begin
                string i_string;
                i_string.itoa(pcie_e);

                analysis_imp_axi_cc_data[pcie_e]   = new({"analysis_imp_axi_cc_data_", i_string}, this);
                analysis_imp_axi_rq_data[pcie_e]   = new({"analysis_imp_axi_rq_data_", i_string}, this);
            end
        end

        for (int unsigned dma = 0; dma < DMA_PORTS; dma++) begin
            string i_string;
            i_string.itoa(dma);

            analysis_imp_mfb_rc_data[dma]   = new({"analysis_imp_mfb_rc_data_", i_string}, this);
            analysis_imp_mvb_rc_data[dma]   = new({"analysis_imp_mvb_rc_data_", i_string}, this);
            // TODO: Use in case of no PTC
            // analysis_imp_mfb_rc_meta[dma]   = new({"analysis_imp_mfb_rc_meta_", i_string}, this);
            // TODO: Create model and make comparators (This is use in case of DMA_BAR_ENABLE)
            // analysis_imp_mfb_cq_data[dma]   = new({"analysis_imp_mfb_cq_data_", i_string}, this);
            // analysis_imp_mfb_cq_meta[dma]   = new({"analysis_imp_mfb_cq_meta_", i_string}, this);
        end

    endfunction

    function int unsigned success();
        int unsigned ret = 0;

        for (int dma = 0; dma < DMA_PORTS; dma++) begin
            ret |= mvb_rc_data_cmp[dma].success();
            ret |= mi_rq_cmp[dma].success();
            ret |= mfb_rc_data_cmp[dma].success();
            // ret |= mfb_cq_meta_cmp[dma].success();
            // ret |= mfb_cq_data_cmp[dma].success();
        end
        for (int unsigned pcie_e = 0; pcie_e < PCIE_ENDPOINTS; pcie_e++) begin
            if (IS_INTEL_DEV) begin
                ret |= avst_up_meta_cmp[pcie_e].success();
                ret |= avst_up_data_cmp[pcie_e].success();
            end else begin
                ret |= axi_cc_data_cmp[pcie_e].success();
                ret |= axi_rq_data_cmp[pcie_e].success();
            end
        end

        return ret;
    endfunction


    function int unsigned used();
        int unsigned ret = 0;

        for (int dma = 0; dma < DMA_PORTS; dma++) begin
            ret |= mvb_rc_data_cmp[dma].used();
            ret |= mi_rq_cmp[dma].used();
            ret |= mfb_rc_data_cmp[dma].used();
            // ret |= mfb_cq_meta_cmp[dma].used();
            // ret |= mfb_cq_data_cmp[dma].used();
        end
        for (int unsigned pcie_e = 0; pcie_e < PCIE_ENDPOINTS; pcie_e++) begin
            if (IS_INTEL_DEV) begin
                ret |= avst_up_meta_cmp[pcie_e].used();
                ret |= avst_up_data_cmp[pcie_e].used();
            end else begin
                ret |= axi_cc_data_cmp[pcie_e].used();
                ret |= axi_rq_data_cmp[pcie_e].used();
            end
        end

        return ret;
    endfunction

    function void build_phase(uvm_phase phase);
        if (IS_INTEL_DEV) begin

            m_model_intel = model_intel #(CQ_MFB_ITEM_WIDTH, CC_MFB_ITEM_WIDTH, RQ_MFB_ITEM_WIDTH, RC_MFB_ITEM_WIDTH, AVST_DOWN_META_W, AVST_UP_META_W, RQ_MFB_META_W, RC_MFB_META_W, CQ_MFB_META_W, CC_MFB_META_W, ENDPOINT_TYPE, DMA_UPHDR_WIDTH_W, DMA_DOWNHDR_WIDTH_W, DMA_PORTS, PCIE_ENDPOINTS, PCIE_TAG_WIDTH)::type_id::create("m_model_intel", this);

            for (int unsigned pcie_e = 0; pcie_e < PCIE_ENDPOINTS; pcie_e++) begin
                string i_string;
                i_string.itoa(pcie_e);

                analysis_imp_avst_down_data[pcie_e] = uvm_common::subscriber#(uvm_logic_vector_array::sequence_item#(CQ_MFB_ITEM_WIDTH))::type_id::create({"analysis_imp_avst_down_data_", i_string}, this);
                analysis_imp_avst_down_meta[pcie_e] = uvm_common::subscriber#(uvm_logic_vector::sequence_item#(AVST_DOWN_META_W))::type_id::create({"analysis_imp_avst_down_meta_", i_string}, this);

                avst_up_meta_cmp[pcie_e] = uvm_pcie::scoreboard_mvb #(AVST_UP_META_W, PCIE_TAG_WIDTH, uvm_logic_vector::sequence_item#(AVST_UP_META_W))::type_id::create({"avst_up_meta_cmp_", i_string}, this);
                avst_up_data_cmp[pcie_e] = uvm_pcie::scoreboard_mfb #(CC_MFB_ITEM_WIDTH, RQ_MFB_BLOCK_SIZE)::type_id::create({"avst_up_data_cmp_", i_string}, this);

                avst_down_splitter[pcie_e] = uvm_pcie::down_splitter #(CQ_MFB_ITEM_WIDTH, AVST_DOWN_META_W)::type_id::create({"avst_down_splitter_", i_string}, this);
                mfb_cc2avst_up[pcie_e] = cc_meta_convertor #(CC_MFB_META_W, AVST_UP_META_W)::type_id::create({"mfb_cc2avst_up_", i_string}, this);

                avst_down_splitter[pcie_e].model_down = uvm_pcie::splitter_down_input_fifo #(CQ_MFB_ITEM_WIDTH, AVST_DOWN_META_W)::type_id::create({"model_down_", i_string}, this);

                m_model_intel.model_rc[pcie_e] = model_down_input_fifo_intel#(sv_pcie_meta_pack::PCIE_RC_META_WIDTH, 32, RC_MFB_ITEM_WIDTH, DMA_PORTS)::type_id::create({"model_rc_", i_string}, this);

                avst_up_meta_cmp[pcie_e].model_tr_timeout_set(100000000ns);
                avst_up_data_cmp[pcie_e].model_tr_timeout_set(1000000ns);
            end


            for (int dma = 0; dma < DMA_PORTS; dma++) begin
                string i_string;
                i_string.itoa(dma);

                m_model_intel.model_up[dma] = model_rc_input_fifo#(DMA_UPHDR_WIDTH_W, RQ_MFB_ITEM_WIDTH, PTC_DISABLE)::type_id::create({"model_up_", i_string}, this);

            end

        end else begin
            m_model_xilinx = model_xilinx #(CQ_MFB_ITEM_WIDTH, CC_MFB_ITEM_WIDTH, RQ_MFB_ITEM_WIDTH, RC_MFB_ITEM_WIDTH, AXI_CQUSER_WIDTH, AXI_CCUSER_WIDTH, AXI_RCUSER_WIDTH, AXI_RQUSER_WIDTH, RQ_MFB_META_W, RC_MFB_META_W, CQ_MFB_META_W, CC_MFB_META_W, DMA_UPHDR_WIDTH_W, DMA_DOWNHDR_WIDTH_W, DMA_PORTS, PCIE_ENDPOINTS, PCIE_TAG_WIDTH)::type_id::create("m_model_xilinx", this);


            for (int dma = 0; dma < DMA_PORTS; dma++) begin
                string i_string;
                i_string.itoa(dma);

                m_model_xilinx.model_up[dma] = model_rc_input_fifo#(DMA_UPHDR_WIDTH_W, RQ_MFB_ITEM_WIDTH, PTC_DISABLE)::type_id::create({"model_up_", i_string}, this);

            end

            for (int unsigned pcie_e = 0; pcie_e < PCIE_ENDPOINTS; pcie_e++) begin
                string i_string;
                i_string.itoa(pcie_e);


                m_mtc_meta_c[pcie_e] = uvm_pcie::cq_mtc_meta_convertor #(AXI_CQUSER_WIDTH, CQ_MFB_ITEM_WIDTH, sv_pcie_meta_pack::PCIE_CQ_META_WIDTH, CQ_MFB_REGIONS)::type_id::create({"m_mtc_meta_c_", i_string}, this);

                analysis_imp_axi_rc_data[pcie_e] = uvm_common::subscriber #(uvm_logic_vector_array::sequence_item#(RC_MFB_ITEM_WIDTH))::type_id::create({"analysis_imp_axi_rc_data_", i_string}, this);

                analysis_imp_axi_cq_data[pcie_e]    = uvm_common::subscriber #(uvm_logic_vector_array::sequence_item#(CQ_MFB_ITEM_WIDTH))::type_id::create({"analysis_imp_axi_cq_data_", i_string}, this);
                analysis_imp_axi_cq_meta[pcie_e]    = uvm_common::subscriber #(uvm_logic_vector::sequence_item#(AXI_CQUSER_WIDTH))::type_id::create({"analysis_imp_axi_cq_meta_", i_string}, this);

                m_model_xilinx.model_rc[pcie_e] = model_down_input_fifo_xilinx#(PCIE_DOWNHDR_WIDTH, 32, RC_MFB_ITEM_WIDTH, DMA_PORTS)::type_id::create({"model_rc_", i_string}, this);

                axi_rq_data_cmp[pcie_e] = uvm_pcie::scoreboard_mfb_xilinx #(CC_MFB_ITEM_WIDTH, RQ_MFB_BLOCK_SIZE, PCIE_TAG_WIDTH)::type_id::create({"axi_rq_data_cmp_", i_string}, this);
                axi_cc_data_cmp[pcie_e] = uvm_pcie::scoreboard_mtc_mfb_xilinx #(CC_MFB_ITEM_WIDTH)::type_id::create({"axi_cc_data_cmp_", i_string}, this);

                axi_rq_data_cmp[pcie_e].model_tr_timeout_set(10ns);
                axi_cc_data_cmp[pcie_e].model_tr_timeout_set(10ns);
            end

        end

        for (int dma = 0; dma < DMA_PORTS; dma++) begin
            string i_string;
            i_string.itoa(dma);

            // TODO: Create model and make comparators (This is use in case of DMA_BAR_ENABLE)
            // analysis_imp_mfb_cc_data[dma] = uvm_common::subscriber #(uvm_logic_vector_array::sequence_item#(CC_MFB_ITEM_WIDTH))::type_id::create({"analysis_imp_mfb_cc_data_", i_string}, this);
            // analysis_imp_mfb_cc_meta[dma] = uvm_common::subscriber #(uvm_logic_vector::sequence_item#(CC_MFB_META_W))::type_id::create({"analysis_imp_mfb_cc_meta_", i_string}, this);

            analysis_imp_mfb_rq_data[dma] = uvm_common::subscriber #(uvm_logic_vector_array::sequence_item#(RQ_MFB_ITEM_WIDTH))::type_id::create({"analysis_imp_mfb_rq_data_", i_string}, this);
            // TODO: Use in case of no PTC
            // analysis_imp_mfb_rq_meta[dma] = uvm_common::subscriber #(uvm_logic_vector::sequence_item#(RQ_MFB_META_W))::type_id::create({"analysis_imp_mfb_rq_meta_", i_string}, this);
            analysis_imp_mvb_rq_data[dma] = uvm_common::subscriber #(uvm_logic_vector::sequence_item#(DMA_UPHDR_WIDTH_W))::type_id::create({"analysis_imp_mvb_rq_data_", i_string}, this);
            // TODO: Create model and make comparators (This is use in case of DMA_BAR_ENABLE)
            // mfb_cq_data_cmp[dma] = uvm_common::comparer_ordered #(uvm_logic_vector_array::sequence_item#(CQ_MFB_ITEM_WIDTH))::type_id::create({"mfb_cq_data_cmp_", i_string}, this);
            // mfb_cq_meta_cmp[dma] = uvm_common::comparer_ordered #(uvm_logic_vector::sequence_item#(CQ_MFB_META_W))::type_id::create({"mfb_cq_meta_cmp_", i_string}, this);

            // mfb_cq_meta_cmp[dma].model_tr_timeout_set(10ns);
            // mfb_cq_data_cmp[dma].model_tr_timeout_set(10ns);

            mvb_rc_data_cmp[dma]  = uvm_common::comparer_ordered #(uvm_logic_vector::sequence_item#(DMA_DOWNHDR_WIDTH_W))::type_id::create({"mvb_rc_data_cmp_", i_string}, this);
            mfb_rc_data_cmp[dma] = uvm_common::comparer_ordered #(uvm_logic_vector_array::sequence_item #(RC_MFB_ITEM_WIDTH))::type_id::create({"mfb_rc_data_cmp_", i_string}, this);

            mfb_rc_data_cmp[dma].model_tr_timeout_set(1000000ns);
            mvb_rc_data_cmp[dma].model_tr_timeout_set(1000000ns);
        end

        for (int unsigned pcie_e = 0; pcie_e < PCIE_ENDPOINTS; pcie_e++) begin
            string i_string;
            i_string.itoa(pcie_e);

            analysis_export_cc_mi[pcie_e] = uvm_common::subscriber #(uvm_mi::sequence_item_response #(32))::type_id::create({"analysis_export_cc_mi_", i_string}, this);

            m_rq_mtc_model[pcie_e] = uvm_mtc::model #(CQ_MFB_ITEM_WIDTH, DEVICE, ENDPOINT_TYPE, 32, 32)::type_id::create({"m_rq_mtc_model_", i_string}, this);
            m_rs_mtc_model[pcie_e] = uvm_mtc::response_model #(CQ_MFB_ITEM_WIDTH, DEVICE, ENDPOINT_TYPE, 32, 32)::type_id::create({"m_rs_mtc_model_", i_string}, this);

            mi_scrb[pcie_e] = uvm_mtc::mi_subscriber #(32, 32)::type_id::create({"mi_scrb_", i_string}, this);
            mi_rq_cmp[pcie_e] = uvm_common::comparer_ordered#(uvm_mi::sequence_item_request #(32, 32, 0))::type_id::create({"mi_rq_cmp_", i_string}, this);

            mi_rq_cmp[pcie_e].model_tr_timeout_set(1000000ns);
        end

    endfunction

    function void connect_phase(uvm_phase phase);

        if (IS_INTEL_DEV) begin
            // Model INTEL INPUTS
            for (int pcie_e = 0; pcie_e < PCIE_ENDPOINTS; pcie_e++) begin
                splitter_down_input_fifo#(CQ_MFB_ITEM_WIDTH, AVST_DOWN_META_W) fifo_model_down;
                model_down_input_fifo_intel#(sv_pcie_meta_pack::PCIE_RC_META_WIDTH, 32, RC_MFB_ITEM_WIDTH, DMA_PORTS) fifo_model_rc;

                // Connect AVST DOWN SPLITTER
                $cast(fifo_model_down, avst_down_splitter[pcie_e].model_down);
                analysis_imp_avst_down_data[pcie_e].port.connect(fifo_model_down.mfb.analysis_export);
                analysis_imp_avst_down_meta[pcie_e].port.connect(fifo_model_down.meta.analysis_export);

                $cast(fifo_model_rc, m_model_intel.model_rc[pcie_e]);
                avst_down_splitter[pcie_e].rc_data_port.connect(fifo_model_rc.mfb_in.analysis_export);
                avst_down_splitter[pcie_e].rc_meta_port.connect(fifo_model_rc.meta_in.analysis_export);

                m_rs_mtc_model[pcie_e].analysis_port_cc_meta.connect(mfb_cc2avst_up[pcie_e].in_meta.analysis_export);

                avst_down_splitter[pcie_e].cq_data_port.connect(m_rq_mtc_model[pcie_e].analysis_imp_cq_data.analysis_export);
                avst_down_splitter[pcie_e].cq_meta_port.connect(m_rq_mtc_model[pcie_e].analysis_imp_cq_meta.analysis_export);

                avst_down_splitter[pcie_e].cq_data_port.connect(m_rs_mtc_model[pcie_e].analysis_imp_cq_data.analysis_export);
                avst_down_splitter[pcie_e].cq_meta_port.connect(m_rs_mtc_model[pcie_e].analysis_imp_cq_meta.analysis_export);

                m_rs_mtc_model[pcie_e].analysis_port_cc.connect(avst_up_data_cmp[pcie_e].analysis_imp_model);
                m_model_intel.rq_data_out[pcie_e].connect(avst_up_data_cmp[pcie_e].analysis_imp_model);
                analysis_imp_avst_up_data[pcie_e].connect(avst_up_data_cmp[pcie_e].analysis_imp_dut);
    
                // MI -> UP (CC/RQ) Comparer META
                analysis_imp_avst_up_meta[pcie_e].connect(avst_up_meta_cmp[pcie_e].analysis_imp_dut);
                m_model_intel.rq_meta_out[pcie_e].connect(avst_up_meta_cmp[pcie_e].analysis_imp_model);

                mfb_cc2avst_up[pcie_e].out_meta_port.connect(avst_up_meta_cmp[pcie_e].analysis_imp_model);

            end
            // Shared INPUTS
            for (int dma = 0; dma < DMA_PORTS; dma++) begin
                model_rc_input_fifo#(DMA_UPHDR_WIDTH_W, RQ_MFB_ITEM_WIDTH, PTC_DISABLE) fifo_model_up;

                // TODO: Create model and make comparators (This is use in case of DMA_BAR_ENABLE)
                // analysis_imp_mfb_cc_data[dma].port.connect(m_model_intel.mfb_cc_data_in[dma].analysis_export);
                // analysis_imp_mfb_cc_meta[dma].port.connect(m_model_intel.mfb_cc_meta_in[dma].analysis_export);

                $cast(fifo_model_up, m_model_intel.model_up[dma]);
                analysis_imp_mfb_rq_data[dma].port.connect(fifo_model_up.mfb.analysis_export);

                m_model_intel.avst_down_data_out[dma].connect(mfb_rc_data_cmp[dma].analysis_imp_model);
                analysis_imp_mfb_rc_data[dma].connect(mfb_rc_data_cmp[dma].analysis_imp_dut);

                m_model_intel.avst_down_meta_out[dma].connect(mvb_rc_data_cmp[dma].analysis_imp_model);
                analysis_imp_mvb_rc_data[dma].connect(mvb_rc_data_cmp[dma].analysis_imp_dut);

                if (PTC_DISABLE) begin
                    // TODO: Use in case of no PTC
                    // analysis_imp_mfb_rq_meta[dma].port.connect(m_model_intel.mfb_rq_meta_in[dma].analysis_export);
                end else begin
                    analysis_imp_mvb_rq_data[dma].port.connect(fifo_model_up.meta.analysis_export);
                end

            end

        end else begin
            // Model XILINX INPUTS
            for (int pcie_e = 0; pcie_e < PCIE_ENDPOINTS; pcie_e++) begin
                model_down_input_fifo_xilinx#(PCIE_DOWNHDR_WIDTH, 32, RC_MFB_ITEM_WIDTH, DMA_PORTS) fifo_model_rc;

                analysis_imp_axi_rq_data[pcie_e].connect(axi_rq_data_cmp[pcie_e].analysis_imp_dut);
                m_model_xilinx.rq_data_out[pcie_e].connect(axi_rq_data_cmp[pcie_e].analysis_imp_model);

                $cast(fifo_model_rc, m_model_xilinx.model_rc[pcie_e]);
                analysis_imp_axi_rc_data[pcie_e].port.connect(fifo_model_rc.mfb_in.analysis_export);

                analysis_imp_axi_cq_data[pcie_e].port.connect(m_mtc_meta_c[pcie_e].in_data.analysis_export);
                analysis_imp_axi_cq_meta[pcie_e].port.connect(m_mtc_meta_c[pcie_e].in_meta.analysis_export);

                analysis_imp_axi_cq_data[pcie_e].port.connect(m_rq_mtc_model[pcie_e].analysis_imp_cq_data.analysis_export);
                m_mtc_meta_c[pcie_e].out_meta_port.connect(m_rq_mtc_model[pcie_e].analysis_imp_cq_meta.analysis_export);

                analysis_imp_axi_cq_data[pcie_e].port.connect(m_rs_mtc_model[pcie_e].analysis_imp_cq_data.analysis_export);
                m_mtc_meta_c[pcie_e].out_meta_port.connect(m_rs_mtc_model[pcie_e].analysis_imp_cq_meta.analysis_export);

                m_rs_mtc_model[pcie_e].analysis_port_cc.connect(axi_cc_data_cmp[pcie_e].analysis_imp_model);
                analysis_imp_axi_cc_data[pcie_e].connect(axi_cc_data_cmp[pcie_e].analysis_imp_dut);

            end

            for (int unsigned dma = 0; dma < DMA_PORTS; dma++) begin
                model_rc_input_fifo#(DMA_UPHDR_WIDTH_W, RQ_MFB_ITEM_WIDTH, PTC_DISABLE) fifo_model_up;

                $cast(fifo_model_up, m_model_xilinx.model_up[dma]);
                analysis_imp_mfb_rq_data[dma].port.connect(fifo_model_up.mfb.analysis_export);

                if (PTC_DISABLE) begin
                    // TODO: Use in case of no PTC
                    // analysis_imp_mfb_rq_meta[dma].port.connect(m_model_xilinx.mfb_rq_meta_in[dma].analysis_export);
                end else begin
                    analysis_imp_mvb_rq_data[dma].port.connect(fifo_model_up.meta.analysis_export);
                end


                m_model_xilinx.avst_down_data_out[dma].connect(mfb_rc_data_cmp[dma].analysis_imp_model);
                analysis_imp_mfb_rc_data[dma].connect(mfb_rc_data_cmp[dma].analysis_imp_dut);

                m_model_xilinx.avst_down_meta_out[dma].connect(mvb_rc_data_cmp[dma].analysis_imp_model);
                analysis_imp_mvb_rc_data[dma].connect(mvb_rc_data_cmp[dma].analysis_imp_dut);
            end
        end
        for (int pcie_e = 0; pcie_e < PCIE_ENDPOINTS; pcie_e++) begin
            mi_scrb[pcie_e].port.connect(mi_rq_cmp[pcie_e].analysis_imp_dut);
            m_rq_mtc_model[pcie_e].analysis_port_mi_data.connect(mi_rq_cmp[pcie_e].analysis_imp_model);
            analysis_export_cc_mi[pcie_e].port.connect(m_rs_mtc_model[pcie_e].analysis_imp_cc_mi.analysis_export);
        end
        // for (int unsigned dma = 0; dma < DMA_PORTS; dma++) begin
            // TODO: Create model and make comparators (This is use in case of DMA_BAR_ENABLE)
            // analysis_imp_mfb_cq_data[dma].connect(mfb_cq_data_cmp[dma].analysis_imp_dut);
            // analysis_imp_mfb_cq_meta[dma].connect(mfb_cq_meta_cmp[dma].analysis_imp_dut);
        // end

    endfunction

    virtual function void report_phase(uvm_phase phase);
        if (this.success() && this.used() == 0) begin
            `uvm_info(get_type_name(), "\n\n\t---------------------------------------\n\t----     VERIFICATION SUCCESS      ----\n\t---------------------------------------", UVM_NONE)
        end else begin
            `uvm_info(get_type_name(), "\n\n\t---------------------------------------\n\t----     VERIFICATION FAIL      ----\n\t---------------------------------------", UVM_NONE)
        end

    endfunction

endclass
