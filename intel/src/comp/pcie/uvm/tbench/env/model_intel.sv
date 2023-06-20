//-- model_intel.sv: Model of implementation
//-- Copyright (C) 2023 CESNET z. s. p. o.
//-- Author(s): Daniel Kriz <danielkriz@cesnet.cz>

//-- SPDX-License-Identifier: BSD-3-Clause 

class model_intel #(CQ_MFB_ITEM_WIDTH, CC_MFB_ITEM_WIDTH, RQ_MFB_ITEM_WIDTH, RC_MFB_ITEM_WIDTH, AVST_DOWN_META_W, AVST_UP_META_W, RQ_MFB_META_W, RC_MFB_META_W, CQ_MFB_META_W, CC_MFB_META_W, ENDPOINT_TYPE, DMA_UPHDR_WIDTH_W, DMA_DOWNHDR_WIDTH_W, DMA_PORTS, PCIE_ENDPOINTS, PCIE_TAG_WIDTH)
extends model_base #(CQ_MFB_ITEM_WIDTH, CC_MFB_ITEM_WIDTH, RQ_MFB_ITEM_WIDTH, RC_MFB_ITEM_WIDTH, RQ_MFB_META_W, RC_MFB_META_W, CQ_MFB_META_W, CC_MFB_META_W, DMA_UPHDR_WIDTH_W, DMA_DOWNHDR_WIDTH_W, DMA_PORTS, AVST_UP_META_W, PCIE_ENDPOINTS, PCIE_TAG_WIDTH);

    `uvm_component_param_utils(uvm_pcie::model_intel#(CQ_MFB_ITEM_WIDTH, CC_MFB_ITEM_WIDTH, RQ_MFB_ITEM_WIDTH, RC_MFB_ITEM_WIDTH, AVST_DOWN_META_W, AVST_UP_META_W, RQ_MFB_META_W, RC_MFB_META_W, CQ_MFB_META_W, CC_MFB_META_W, ENDPOINT_TYPE, DMA_UPHDR_WIDTH_W, DMA_DOWNHDR_WIDTH_W, DMA_PORTS, PCIE_ENDPOINTS, PCIE_TAG_WIDTH))

    // TODO: Create model and make comparators (This is use in case of DMA_BAR_ENABLE)
    // uvm_tlm_analysis_fifo #(uvm_common::model_item #(uvm_logic_vector::sequence_item #(CC_MFB_META_W))) mfb_cc_meta_in[DMA_PORTS];
    // uvm_tlm_analysis_fifo #(uvm_common::model_item #(uvm_logic_vector::sequence_item #(RQ_MFB_META_W))) mfb_rq_meta_in[DMA_PORTS];

    function new(string name = "model_intel", uvm_component parent = null);
        super.new(name, parent);

        for (int dma = 0; dma < DMA_PORTS; dma++) begin
            string i_string;
            i_string.itoa(dma);

            // TODO: Create model and make comparators (This is use in case of DMA_BAR_ENABLE)
            // mfb_cc_meta_in[dma] = new({"mfb_cc_meta_in_", i_string}, this);
            // mfb_rq_meta_in[dma] = new({"mfb_rq_meta_in_", i_string}, this);
        end

    endfunction

    virtual function uvm_common::model_item #(uvm_logic_vector::sequence_item #(AVST_UP_META_W)) create_data(uvm_down_hdr::rq_sequence_item pcie_header_out,  dma_header_rq#(RQ_MFB_ITEM_WIDTH) header_rq, uvm_common::model_item #(uvm_mtc::cc_mtc_item#(RQ_MFB_ITEM_WIDTH)) tr_data, int unsigned index);

        uvm_common::model_item #(uvm_logic_vector::sequence_item #(AVST_UP_META_W)) ret;
        int unsigned port = 0;

        ret      = uvm_common::model_item #(uvm_logic_vector::sequence_item #(AVST_UP_META_W))::type_id::create("ret", this);
        ret.item = uvm_logic_vector::sequence_item #(AVST_UP_META_W)::type_id::create("ret_item", this);
        ret.item.data = {pcie_header_out.global_id, pcie_header_out.req_id, pcie_header_out.tag,
                    pcie_header_out.lbe, pcie_header_out.fbe, pcie_header_out.fmt, pcie_header_out.type_n,
                    pcie_header_out.tag_9, pcie_header_out.tc, pcie_header_out.tag_8, pcie_header_out.padd_0,
                    pcie_header_out.td, pcie_header_out.ep, pcie_header_out.relaxed, pcie_header_out.snoop,
                    pcie_header_out.at, pcie_header_out.len[10-1 : 0]};
    
        port = header_rq.hdr.tag[sv_dma_bus_pack::DMA_REQUEST_TAG_W-1 : sv_dma_bus_pack::DMA_REQUEST_TAG_W-PORTS_W_FIX];

        ret.item.data = {1'b0, ret.item.data[AVST_UP_META_W-2 : 128], ret.item.data[32-1 : 0], ret.item.data[64-1 : 32], ret.item.data[96-1 : 64], ret.item.data[128-1 : 96]};

        if (DMA_PORTS > 1) begin
            rq_data_out[port].write(tr_data);
        end else begin
            rq_data_out[index].write(tr_data);
        end
        return ret;
    endfunction

endclass
