//-- input_fifo.sv: Convert to input transactions 
//-- Copyright (C) 2023 CESNET z. s. p. o.
//-- Author(s): Radek Iša  <isa@cesnet.cz>

//-- SPDX-License-Identifier: BSD-3-Clause 


class model_rc_input_fifo#(META_WIDTH, ITEM_WIDTH, PTC_DISABLE) extends uvm_common::fifo#(dma_header_rq #(ITEM_WIDTH));
    `uvm_component_param_utils(uvm_pcie::model_rc_input_fifo#(META_WIDTH, ITEM_WIDTH, PTC_DISABLE))

    uvm_tlm_analysis_fifo #(uvm_common::model_item #(uvm_logic_vector_array::sequence_item #(ITEM_WIDTH))) mfb;
    uvm_tlm_analysis_fifo #(uvm_common::model_item #(uvm_logic_vector::sequence_item #(META_WIDTH)))       meta;

    function new(string name, uvm_component parent = null);
        super.new(name, parent);
        mfb  = new("mfb", this);
        meta = new("meta", this);
    endfunction

    virtual function void flush();
        super.flush();
        mfb.flush();
        meta.flush();
    endfunction

    virtual function int unsigned used();
        return (super.used() || mfb.used() != 0 || meta.used() != 0);
    endfunction


    task run_phase(uvm_phase phase);

        uvm_common::model_item #(uvm_logic_vector_array::sequence_item#(ITEM_WIDTH)) tr_mfb;
        uvm_common::model_item #(uvm_logic_vector::sequence_item#(META_WIDTH))       tr_meta;

        forever begin
            dma_header_rq #(ITEM_WIDTH) tr;

            meta.get(tr_meta);

            tr      = dma_header_rq #(ITEM_WIDTH)::type_id::create("tr", this);
            tr.hdr  = uvm_ptc_info::sequence_item::type_id::create("tr.hdr", this);
            tr.data = uvm_common::model_item #(uvm_logic_vector_array::sequence_item #(ITEM_WIDTH))::type_id::create("tr_data", this);


            tr.hdr.relaxed     = tr_meta.item.data[sv_dma_bus_pack::DMA_REQUEST_W-1 : sv_dma_bus_pack::DMA_REQUEST_RELAXED_O];
            tr.hdr.pasidvld    = tr_meta.item.data[sv_dma_bus_pack::DMA_REQUEST_PASIDVLD_O];
            tr.hdr.pasid       = tr_meta.item.data[sv_dma_bus_pack::DMA_REQUEST_PASID_O];
            tr.hdr.vfid        = tr_meta.item.data[sv_dma_bus_pack::DMA_REQUEST_PASID_O-1 : sv_dma_bus_pack::DMA_REQUEST_VFID_O];
            tr.hdr.global_id   = tr_meta.item.data[sv_dma_bus_pack::DMA_REQUEST_VFID_O-1 : sv_dma_bus_pack::DMA_REQUEST_GLOBAL_O];
            tr.hdr.unitid      = tr_meta.item.data[sv_dma_bus_pack::DMA_REQUEST_GLOBAL_O-1 : sv_dma_bus_pack::DMA_REQUEST_UNITID_O];
            tr.hdr.tag         = tr_meta.item.data[sv_dma_bus_pack::DMA_REQUEST_UNITID_O-1 : sv_dma_bus_pack::DMA_REQUEST_TAG_O];
            tr.hdr.lastib      = tr_meta.item.data[sv_dma_bus_pack::DMA_REQUEST_TAG_O-1 : sv_dma_bus_pack::DMA_REQUEST_LASTIB_O];
            tr.hdr.firstib     = tr_meta.item.data[sv_dma_bus_pack::DMA_REQUEST_LASTIB_O-1 : sv_dma_bus_pack::DMA_REQUEST_FIRSTIB_O];
            tr.hdr.type_ide    = tr_meta.item.data[sv_dma_bus_pack::DMA_REQUEST_FIRSTIB_O-1 : sv_dma_bus_pack::DMA_REQUEST_TYPE_O];
            tr.hdr.length      = tr_meta.item.data[sv_dma_bus_pack::DMA_REQUEST_TYPE_O-1 : sv_dma_bus_pack::DMA_REQUEST_LENGTH_O]; // Size in DWORDS

            // $write("UP TAG %h\n", tr.hdr.tag);

            if (tr.hdr.type_ide == 1'b1) begin
                string msg = "";

                mfb.get(tr_mfb);
                tr.data.copy(tr_mfb);
                if (tr_mfb.item.data.size() != tr.hdr.length) begin
                    $swrite(msg, "%s\n\tDATA SIZE: %d META SIZE: %d", msg, tr_mfb.item.data.size(), tr.hdr.length);
                    `uvm_fatal(this.get_full_name(), msg);
                end
            end else begin
                tr.data.item = uvm_logic_vector_array::sequence_item #(ITEM_WIDTH)::type_id::create("tr_data_item", this);

                tr.data.item.data = {};
            end

            this.push_back(tr);
        end

    endtask
endclass

class splitter_down_input_fifo#(ITEM_WIDTH, META_WIDTH) extends uvm_common::fifo#(down_tr #(ITEM_WIDTH, META_WIDTH));
    `uvm_component_param_utils(uvm_pcie::splitter_down_input_fifo#(ITEM_WIDTH, META_WIDTH))

    uvm_tlm_analysis_fifo #(uvm_common::model_item #(uvm_logic_vector_array::sequence_item #(ITEM_WIDTH))) mfb;
    uvm_tlm_analysis_fifo #(uvm_common::model_item #(uvm_logic_vector::sequence_item #(META_WIDTH)))       meta;

    function new(string name, uvm_component parent = null);
        super.new(name, parent);
        mfb  = new("mfb", this);
        meta = new("meta", this);
    endfunction

    virtual function void flush();
        super.flush();
        mfb.flush();
        meta.flush();
    endfunction

    virtual function int unsigned used();
        return (super.used() || mfb.used() != 0 || meta.used() != 0);
    endfunction

    task run_phase(uvm_phase phase);

        uvm_common::model_item #(uvm_logic_vector_array::sequence_item#(ITEM_WIDTH)) tr_mfb;
        uvm_common::model_item #(uvm_logic_vector::sequence_item#(META_WIDTH))       tr_meta;

        forever begin
            down_tr #(ITEM_WIDTH, META_WIDTH) tr;

            meta.get(tr_meta);
            mfb.get(tr_mfb);

            tr      = down_tr #(ITEM_WIDTH, META_WIDTH)::type_id::create("tr", this);
            tr.data = uvm_common::model_item #(uvm_logic_vector_array::sequence_item #(ITEM_WIDTH))::type_id::create("tr_data", this);
            tr.meta = uvm_common::model_item #(uvm_logic_vector::sequence_item #(META_WIDTH))::type_id::create("tr_meta", this);

            tr.data.copy(tr_mfb);
            tr.meta.copy(tr_meta);

            this.push_back(tr);
        end

    endtask

endclass

virtual class model_down_input_fifo#(PCIE_DOWNHDR_WIDTH, PCIE_PREFIX_WIDTH, ITEM_WIDTH) extends uvm_common::fifo#(dma_header_rc #(ITEM_WIDTH));

    uvm_tlm_analysis_fifo #(uvm_common::model_item #(uvm_logic_vector_array::sequence_item #(ITEM_WIDTH)))   mfb_in;
    uvm_tlm_analysis_fifo #(uvm_common::model_item #(uvm_logic_vector::sequence_item #(PCIE_DOWNHDR_WIDTH))) meta_in;
    uvm_tlm_analysis_fifo #(uvm_common::model_item #(uvm_logic_vector::sequence_item #(PCIE_PREFIX_WIDTH)))  prefix_in;

    function new(string name, uvm_component parent = null);
        super.new(name, parent);
        mfb_in    = new("model_rc_mfb_in",        this);
        meta_in   = new("model_rc_meta_in",       this);
        prefix_in = new("model_rc_prefix_mvb_in", this);
    endfunction

    virtual function void flush();
        super.flush();
        mfb_in.flush();
        meta_in.flush();
        prefix_in.flush();
    endfunction

    virtual function int unsigned used();
        //return (super.used() || mfb_in.used() != 0 || meta_in.used() != 0 || prefix_in.used() != 0);
        return (super.used() || mfb_in.used() != 0);
    endfunction
endclass

class model_down_input_fifo_intel#(PCIE_DOWNHDR_WIDTH, PCIE_PREFIX_WIDTH, ITEM_WIDTH, DMA_PORTS) extends model_down_input_fifo#(PCIE_DOWNHDR_WIDTH, PCIE_PREFIX_WIDTH, ITEM_WIDTH);
    `uvm_component_param_utils(uvm_pcie::model_down_input_fifo_intel#(PCIE_DOWNHDR_WIDTH, PCIE_PREFIX_WIDTH, ITEM_WIDTH, DMA_PORTS))

    localparam DMA_PORT_WIDTH = DMA_PORTS > 1 ? $clog2(DMA_PORTS) : 1;

    function new(string name, uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        uvm_common::model_item #(uvm_logic_vector_array::sequence_item #(ITEM_WIDTH))   tr_data;
        uvm_common::model_item #(uvm_logic_vector::sequence_item #(PCIE_DOWNHDR_WIDTH)) tr_meta;

        forever begin
            dma_header_rc #(ITEM_WIDTH) tr_out;

            mfb_in.get(tr_data);
            meta_in.get(tr_meta);

            tr_out = dma_header_rc#(ITEM_WIDTH)::type_id::create("tr_out", this);
            tr_out.port = DMA_PORTS > 1 ? tr_meta.item.data[(PCIE_DOWNHDR_WIDTH-16)+DMA_PORT_WIDTH-1 : (PCIE_DOWNHDR_WIDTH-16)] : 0;
            tr_out.length    = tr_meta.item.data[10-1 : 0];
            if (signed'(tr_meta.item.data[43 : 32] - tr_out.length*4) <= 0)
                tr_out.completed = 1'b1;
            else
                tr_out.completed = 1'b0;
            tr_out.tag       = tr_meta.item.data[80-1 : 72];
            tr_out.unit_id   = 0;
            tr_out.data      = tr_data;

            this.push_back(tr_out);
        end
    endtask
endclass

class model_down_input_fifo_xilinx#(PCIE_DOWNHDR_WIDTH, PCIE_PREFIX_WIDTH, ITEM_WIDTH, DMA_PORTS) extends model_down_input_fifo#(PCIE_DOWNHDR_WIDTH, PCIE_PREFIX_WIDTH, ITEM_WIDTH);
    `uvm_component_param_utils(uvm_pcie::model_down_input_fifo_xilinx#(PCIE_DOWNHDR_WIDTH, PCIE_PREFIX_WIDTH, ITEM_WIDTH, DMA_PORTS))

    localparam DMA_PORT_WIDTH = DMA_PORTS > 1 ? $clog2(DMA_PORTS) : 1;

    function new(string name, uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        uvm_common::model_item #(uvm_logic_vector_array::sequence_item #(ITEM_WIDTH))   tr_data;

        forever begin
            logic [PCIE_DOWNHDR_WIDTH-1:0] meta;
            dma_header_rc #(ITEM_WIDTH) tr_out;

            mfb_in.get(tr_data);

            for (int unsigned it = 0; it < (PCIE_DOWNHDR_WIDTH/32); it++) begin
                meta[((it+1)*32-1) -: 32] = tr_data.item.data[it];
            end

            tr_out                = dma_header_rc #(ITEM_WIDTH)::type_id::create("tr_out", this);
            tr_out.data           = uvm_common::model_item #(uvm_logic_vector_array::sequence_item #(ITEM_WIDTH))::type_id::create("tr_out_item", this);
            tr_out.data.item      = uvm_logic_vector_array::sequence_item #(ITEM_WIDTH)::type_id::create("tr_out_item_data", this);
            tr_out.port           = DMA_PORTS > 1 ? meta[48+DMA_PORT_WIDTH-1 : 48] : 0;
            tr_out.length         = meta[43-1 : 32];
            tr_out.completed      = meta[30];
            tr_out.tag            = meta[72-1 : 64];
            tr_out.unit_id        = 0;
            tr_out.data.item.data = new[tr_data.item.data.size() - (PCIE_DOWNHDR_WIDTH/32)];
            for (int it = 0; it < tr_data.item.data.size() - (PCIE_DOWNHDR_WIDTH/32); it++) begin
                tr_out.data.item.data[it] = tr_data.item.data[it+(PCIE_DOWNHDR_WIDTH/32)];
            end
            this.push_back(tr_out);
        end
    endtask
endclass
