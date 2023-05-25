//-- model.sv: Model of implementation
//-- Copyright (C) 2023 CESNET z. s. p. o.
//-- Author(s): Daniel Kříž <xkrizd01@vutbr.cz>

//-- SPDX-License-Identifier: BSD-3-Clause 

class model_xilinx #(CQ_MFB_ITEM_WIDTH, CC_MFB_ITEM_WIDTH, RQ_MFB_ITEM_WIDTH, RC_MFB_ITEM_WIDTH, AXI_CQUSER_WIDTH, AXI_CCUSER_WIDTH, AXI_RCUSER_WIDTH, AXI_RQUSER_WIDTH, RQ_MFB_META_W, RC_MFB_META_W, CQ_MFB_META_W, CC_MFB_META_W, DMA_UPHDR_WIDTH_W, DMA_DOWNHDR_WIDTH_W, DMA_PORTS, PCIE_ENDPOINTS, PCIE_TAG_WIDTH) 
extends model_base #(CQ_MFB_ITEM_WIDTH, CC_MFB_ITEM_WIDTH, RQ_MFB_ITEM_WIDTH, RC_MFB_ITEM_WIDTH, RQ_MFB_META_W, RC_MFB_META_W, CQ_MFB_META_W, CC_MFB_META_W, DMA_UPHDR_WIDTH_W, DMA_DOWNHDR_WIDTH_W, DMA_PORTS, 128, PCIE_ENDPOINTS, PCIE_TAG_WIDTH);

    `uvm_component_param_utils(uvm_pcie::model_xilinx#(CQ_MFB_ITEM_WIDTH, CC_MFB_ITEM_WIDTH, RQ_MFB_ITEM_WIDTH, RC_MFB_ITEM_WIDTH, AXI_CQUSER_WIDTH, AXI_CCUSER_WIDTH, AXI_RCUSER_WIDTH, AXI_RQUSER_WIDTH, RQ_MFB_META_W, RC_MFB_META_W, CQ_MFB_META_W, CC_MFB_META_W, DMA_UPHDR_WIDTH_W, DMA_DOWNHDR_WIDTH_W, DMA_PORTS, PCIE_ENDPOINTS, PCIE_TAG_WIDTH))

    function new(string name = "model_xilinx", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function uvm_common::model_item #(uvm_logic_vector::sequence_item #(128)) create_data(uvm_down_hdr::rq_sequence_item pcie_header_out,  dma_header_rq#(RQ_MFB_ITEM_WIDTH) header_rq, uvm_common::model_item #(uvm_mtc::cc_mtc_item#(RQ_MFB_ITEM_WIDTH)) tr_data, int unsigned index);

        uvm_common::model_item #(uvm_logic_vector::sequence_item #(128))   ret;
        uvm_common::model_item #(uvm_mtc::cc_mtc_item#(RQ_MFB_ITEM_WIDTH)) tr_data_out;
        int unsigned port = 0;

        ret                      = uvm_common::model_item #(uvm_logic_vector::sequence_item #(128))::type_id::create("ret", this);
        tr_data_out              = uvm_common::model_item #(uvm_mtc::cc_mtc_item#(RQ_MFB_ITEM_WIDTH))::type_id::create("tr_data_out", this);
        tr_data_out.item         = new();
        tr_data_out.item.data_tr = uvm_logic_vector_array::sequence_item #(RQ_MFB_ITEM_WIDTH)::type_id::create("tr_data_out_data_tr");

        ret.item = uvm_logic_vector::sequence_item #(128)::type_id::create("ret_item", this);
        ret.item.data = {1'b0, pcie_header_out.relaxed, 21'b000000000000000000000, pcie_header_out.tag,
                       pcie_header_out.req_id, 1'b0, 3'b000, header_rq.hdr.type_ide, header_rq.hdr.length,
                       header_rq.hdr.global_id[63 : 2], 2'b00};
        // padding    [end : 126] ('0)
        // TAG        [103 : 96]
        // REQUEST ID [95 : 80]
        // padding    [79 : 79]
        // TYPE       [78 : 75]
        // SIZE       [74 : 64]
        // ADDRESS    [63 : 2]
        // padding    [1 : 0]

        tr_data_out.item.data_tr.data = new[tr_data.item.data_tr.data.size()];

        port = header_rq.hdr.tag[sv_dma_bus_pack::DMA_REQUEST_TAG_W-1 : sv_dma_bus_pack::DMA_REQUEST_TAG_W-PORTS_W_FIX];

        if (header_rq.hdr.type_ide) begin
            tr_data_out.item.data_tr.data = {ret.item.data[32-1 : 0], ret.item.data[64-1 : 32], ret.item.data[96-1 : 64], ret.item.data[128-1 : 96], tr_data.item.data_tr.data};
        end else begin
            tr_data_out.item.data_tr.data = {ret.item.data[32-1 : 0], ret.item.data[64-1 : 32], ret.item.data[96-1 : 64], ret.item.data[128-1 : 96]};
        end

        if (DMA_PORTS > 1) begin
            rq_data_out[port].write(tr_data_out);
        end else begin
            rq_data_out[index].write(tr_data_out);
        end

        return ret;
    endfunction

endclass