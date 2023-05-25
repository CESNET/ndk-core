//-- model_base.sv: Model of implementation
//-- Copyright (C) 2023 CESNET z. s. p. o.
//-- Author(s): Daniel Kříž <xkrizd01@vutbr.cz>

//-- SPDX-License-Identifier: BSD-3-Clause 

class model_base #(CQ_MFB_ITEM_WIDTH, CC_MFB_ITEM_WIDTH, RQ_MFB_ITEM_WIDTH, RC_MFB_ITEM_WIDTH, RQ_MFB_META_W, RC_MFB_META_W, CQ_MFB_META_W, CC_MFB_META_W, DMA_UPHDR_WIDTH_W, DMA_DOWNHDR_WIDTH_W, DMA_PORTS, META_WIDTH, PCIE_ENDPOINTS, PCIE_TAG_WIDTH) extends uvm_component;

    `uvm_component_param_utils(uvm_pcie::model_base#(CQ_MFB_ITEM_WIDTH, CC_MFB_ITEM_WIDTH, RQ_MFB_ITEM_WIDTH, RC_MFB_ITEM_WIDTH, RQ_MFB_META_W, RC_MFB_META_W, CQ_MFB_META_W, CC_MFB_META_W, DMA_UPHDR_WIDTH_W, DMA_DOWNHDR_WIDTH_W, DMA_PORTS, META_WIDTH, PCIE_ENDPOINTS, PCIE_TAG_WIDTH))

    localparam PORTS_W_FIX = (DMA_PORTS > 1) ? $clog2(DMA_PORTS) : 1;

    // Model inputs
    uvm_tlm_analysis_fifo #(uvm_common::model_item #(uvm_logic_vector_array::sequence_item #(CC_MFB_ITEM_WIDTH))) mfb_cc_data_in[DMA_PORTS];

    uvm_analysis_port #(uvm_common::model_item #(uvm_logic_vector_array::sequence_item #(RC_MFB_ITEM_WIDTH)))   mfb_rc_data_out[DMA_PORTS];
    uvm_analysis_port #(uvm_common::model_item #(uvm_logic_vector_array::sequence_item #(CQ_MFB_ITEM_WIDTH)))   mfb_cq_data_out[DMA_PORTS];

    uvm_analysis_port #(uvm_common::model_item #(uvm_logic_vector_array::sequence_item #(RC_MFB_ITEM_WIDTH)))            avst_down_data_out[PCIE_ENDPOINTS];
    uvm_analysis_port #(uvm_common::model_item #(uvm_logic_vector::sequence_item #(sv_dma_bus_pack::DMA_DOWNHDR_WIDTH))) avst_down_meta_out[PCIE_ENDPOINTS];

    uvm_analysis_port #(uvm_common::model_item #(uvm_mtc::cc_mtc_item#(CC_MFB_ITEM_WIDTH))) rq_data_out[PCIE_ENDPOINTS];
    uvm_analysis_port #(uvm_common::model_item #(uvm_logic_vector::sequence_item #(META_WIDTH)))                     rq_meta_out[PCIE_ENDPOINTS];

    uvm_common::fifo#(uvm_pcie::dma_header_rq #(RQ_MFB_ITEM_WIDTH)) model_up[DMA_PORTS];
    uvm_common::fifo#(uvm_pcie::dma_header_rc #(RC_MFB_ITEM_WIDTH)) model_rc[DMA_PORTS];
    uvm_down_hdr::tag_manager #(PCIE_TAG_WIDTH) tag_man;

    function new(string name = "model_base", uvm_component parent = null);
        super.new(name, parent);

        for (int pcie_e = 0; pcie_e < PCIE_ENDPOINTS; pcie_e++) begin
            string i_string;
            i_string.itoa(pcie_e);

            avst_down_data_out[pcie_e] = new({"avst_down_data_out_", i_string} , this);
            avst_down_meta_out[pcie_e] = new({"avst_down_meta_out_", i_string} , this);
        end

        for (int dma = 0; dma < DMA_PORTS; dma++) begin
            string i_string;
            i_string.itoa(dma);

            mfb_cc_data_in[dma]  = new({"mfb_cc_data_in_", i_string} , this);

            mfb_rc_data_out[dma] = new({"mfb_rc_data_out_", i_string}, this);
            mfb_cq_data_out[dma] = new({"mfb_cq_data_out_", i_string}, this);

            rq_data_out[dma] = new({"rq_data_out_", i_string}, this);
            rq_meta_out[dma] = new({"rq_meta_out_", i_string}, this);

            model_up[dma] = null;
            model_rc[dma] = null;

        end

    endfunction

    task parse(int unsigned dma);
        uvm_common::model_item #(uvm_mtc::cc_mtc_item#(RQ_MFB_ITEM_WIDTH)) tr_rq_data_out;
        uvm_pcie::dma_header_rq #(RQ_MFB_ITEM_WIDTH)                       header_rq;
        uvm_down_hdr::rq_sequence_item                                     pcie_header_out;
        logic [8-1 : 0] be;
        logic [4-1 : 0] fbe;
        logic [4-1 : 0] lbe;
        int unsigned    port = 0;

        forever begin
            string msg = "\n";
            tr_rq_data_out      = uvm_common::model_item #(uvm_mtc::cc_mtc_item#(RQ_MFB_ITEM_WIDTH))::type_id::create("tr_rq_data_out", this);
            tr_rq_data_out.item = new();
            pcie_header_out = uvm_down_hdr::rq_sequence_item::type_id::create("pcie_header_out", this);

            $swrite(msg, "%s--------------------------\n", msg);
            $swrite(msg, "%s\tAVST UP RQ MODEL\n", msg);
            $swrite(msg, "%s--------------------------\n", msg);

            model_up[dma].get(header_rq);

            if (header_rq.hdr.type_ide) begin
                tr_rq_data_out.item.data_tr = header_rq.data.item;
            end else begin
                tr_rq_data_out.item.data_tr    = uvm_logic_vector_array::sequence_item #(RQ_MFB_ITEM_WIDTH)::type_id::create("tr_rq_data_out_data_tr");
                tr_rq_data_out.item.data_tr.data    = new[1];
                tr_rq_data_out.item.data_tr.data[0] = 'x;
            end

            fbe = sv_dma_bus_pack::decode_fbe(header_rq.hdr.firstib);
            lbe = sv_dma_bus_pack::decode_lbe(header_rq.hdr.lastib);
            if (header_rq.hdr.length == 0)
                be = '0;
            else if (header_rq.hdr.length == 1)
                be = {4'h0, (fbe & lbe)};
            else
                be = {lbe, fbe};

            // DW count
            pcie_header_out.len     = header_rq.hdr.length;
            // ATTR[1 : 0] - {No Snoop, Relax}
            pcie_header_out.relaxed = header_rq.hdr.relaxed;
            pcie_header_out.snoop   = '0;
            // {EP, TD, TH, LN}
            pcie_header_out.ep      = '0;
            pcie_header_out.td      = '0;
            pcie_header_out.padd_0  = '0;
            // TAG 8
            pcie_header_out.tag_8   = '0;
            // TC
            pcie_header_out.tc      = '0;
            // TAG 9
            pcie_header_out.tag_9   = '0;
            // TYPE
            pcie_header_out.type_n  = '0;
            if (|header_rq.hdr.global_id[64-1 : 32]) begin
                pcie_header_out.fmt = {1'b0, header_rq.hdr.type_ide, 1'b1};
            end else
                pcie_header_out.fmt = {1'b0, header_rq.hdr.type_ide, 1'b0};
            // FBE
            pcie_header_out.fbe     = be[4-1 : 0];
            // LBE
            pcie_header_out.lbe     = be[8-1 : 4];
            // TAG
            if (header_rq.hdr.type_ide == 1'b0) begin
                pcie_header_out.tag     = header_rq.hdr.tag;
            end else
                pcie_header_out.tag = '0;
            // REQ ID
            pcie_header_out.req_id  = {8'h00, header_rq.hdr.vfid};
            pcie_header_out.padd_1  = '0;
            if (|header_rq.hdr.global_id[64-1 : 32]) begin
                // ADDR TYPE
                pcie_header_out.at      = 2'b00;
                pcie_header_out.global_id = {header_rq.hdr.global_id[32-1 : 2], 2'b00, header_rq.hdr.global_id[64-1 : 32]};
            end else begin 
                // ADDR TYPE
                pcie_header_out.at      = 2'b01;
                pcie_header_out.global_id = {32'h0000, 2'b00, header_rq.hdr.global_id[32-1 : 2]};
            end

            tr_rq_data_out.item.tag   = pcie_header_out.tag;
            tr_rq_data_out.item.error = '0;

            port = header_rq.hdr.tag[sv_dma_bus_pack::DMA_REQUEST_TAG_W-1 : sv_dma_bus_pack::DMA_REQUEST_TAG_W-PORTS_W_FIX];

            $swrite(msg, "%s\tMFB RQ DATA %s Time %t\n", msg, tr_rq_data_out.convert2string(), $time());
            `uvm_info(get_type_name(), msg, UVM_MEDIUM)

            if (DMA_PORTS > 1) begin
                rq_meta_out[port].write(create_data(pcie_header_out, header_rq, tr_rq_data_out, dma));
            end else begin
                rq_meta_out[dma].write(create_data(pcie_header_out, header_rq, tr_rq_data_out, dma));
            end

        end
    endtask

        // (RC+CQ) Interface
    task run_down_rc(int unsigned pcie_e);
        uvm_common::model_item #(uvm_logic_vector_array::sequence_item #(RC_MFB_ITEM_WIDTH))            dma_down_data_out;
        uvm_common::model_item #(uvm_logic_vector::sequence_item #(sv_dma_bus_pack::DMA_DOWNHDR_WIDTH)) dma_down_meta_out;

        logic [8-1 : 0]                    tlp_type;
        logic [PCIE_TAG_WIDTH-1 : 0]       tag;
        logic                              rw;
        dma_header_rc #(CQ_MFB_ITEM_WIDTH) tr_rc;

        forever begin

            string debug_msg = "";

            model_rc[pcie_e].get(tr_rc);

            dma_down_meta_out = uvm_common::model_item #(uvm_logic_vector::sequence_item #(sv_dma_bus_pack::DMA_DOWNHDR_WIDTH))::type_id::create("dma_down_meta_out", this);
            dma_down_meta_out.item = uvm_logic_vector::sequence_item #(sv_dma_bus_pack::DMA_DOWNHDR_WIDTH)::type_id::create("dma_down_meta_out_item", this);
            dma_down_data_out = uvm_common::model_item #(uvm_logic_vector_array::sequence_item #(RC_MFB_ITEM_WIDTH))::type_id::create("dma_down_data_out", this);
            dma_down_data_out.item = uvm_logic_vector_array::sequence_item #(RC_MFB_ITEM_WIDTH)::type_id::create("dma_down_data_out_item", this);

            tag_man.get_and_remove(tr_rc.tag, tr_rc.completed, tag);

            dma_down_data_out                    = tr_rc.data;
            dma_down_meta_out.item.data[11-1:0]  = tr_rc.length;
            dma_down_meta_out.item.data[12-1]    = tr_rc.completed;
            dma_down_meta_out.item.data[20-1:12] = tag;
            dma_down_meta_out.item.data[28-1:20] = tr_rc.unit_id;

            if (tr_rc.port < DMA_PORTS) begin
                avst_down_data_out[tr_rc.port].write(dma_down_data_out);
                avst_down_meta_out[tr_rc.port].write(dma_down_meta_out);
            end else begin
                `uvm_error(this.get_full_name(), $sformatf("\n\tPort %0d is out of range [0:%0d]", tr_rc.port, DMA_PORTS));
            end

            $swrite(debug_msg, "%s\n\t ================ DOWN MODEL =============== \n", debug_msg);
            if (this.get_report_verbosity_level() >= UVM_FULL) begin
                $swrite(debug_msg, "%s\t PORT:                %0d\n", debug_msg, tr_rc.port);
                $swrite(debug_msg, "%s\t LENGTH:              %0d\n", debug_msg, tr_rc.length);
                $swrite(debug_msg, "%s\t COMPLETED:           %0d\n", debug_msg, tr_rc.completed);
                $swrite(debug_msg, "%s\t TAG:                 %0d\n", debug_msg, tr_rc.tag);
                $swrite(debug_msg, "%s\t UNIT ID:             %0d\n", debug_msg, tr_rc.unit_id);
                $swrite(debug_msg, "%s\t DATA:                %p\n" , debug_msg, tr_rc.data);
            end

            $swrite(debug_msg, "%s\t DOWN MODEL META OUT:  %s\n",  debug_msg, dma_down_meta_out.convert2string());
            $swrite(debug_msg, "%s\t DOWN MODEL DATA OUT:  %s\n",  debug_msg, dma_down_data_out.convert2string());
            `uvm_info(this.get_full_name(), debug_msg ,UVM_HIGH);
        end
    endtask

    virtual function uvm_common::model_item #(uvm_logic_vector::sequence_item #(META_WIDTH)) create_data(uvm_down_hdr::rq_sequence_item pcie_header_out,  dma_header_rq#(RQ_MFB_ITEM_WIDTH) header_rq, uvm_common::model_item #(uvm_mtc::cc_mtc_item#(RQ_MFB_ITEM_WIDTH)) tr_data, int unsigned index);
        `uvm_fatal(this.get_full_name(), "\n\tThis function is not implemented");
    endfunction

    task run_phase(uvm_phase phase);
        for (int dma = 0; dma < DMA_PORTS; dma++) begin
            fork
                automatic int unsigned index = dma;
                forever begin
                    parse(index);
                end
            join_none
        end

        for (int pcie_e = 0; pcie_e < PCIE_ENDPOINTS; pcie_e++) begin
            fork
                automatic int unsigned index = pcie_e;
                forever begin
                    run_down_rc(index);
                end
            join_none
        end
    endtask

endclass
