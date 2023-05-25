//-- monitor.sv: Monitor for MVB environment
//-- Copyright (C) 2022 CESNET z. s. p. o.
//-- Author(s): Daniel Kříž <xkrizd01@vutbr.cz>

//-- SPDX-License-Identifier: BSD-3-Clause 

`uvm_analysis_imp_decl (_DATA_PORT)
`uvm_analysis_imp_decl (_META_PORT)

class rc_monitor #(ITEM_WIDTH, META_WIDTH, OUT_META_WIDTH, DEVICE) extends uvm_monitor;
    `uvm_component_param_utils(uvm_pcie::rc_monitor #(ITEM_WIDTH, META_WIDTH, OUT_META_WIDTH, DEVICE))

    // Analysis port
    typedef rc_monitor #(ITEM_WIDTH, META_WIDTH, OUT_META_WIDTH, DEVICE) this_type;
    uvm_analysis_imp_DATA_PORT #(uvm_logic_vector_array::sequence_item #(ITEM_WIDTH), this_type) analysis_imp_data;
    uvm_analysis_imp_META_PORT #(uvm_logic_vector::sequence_item #(META_WIDTH), this_type)       analysis_imp_meta;

    uvm_analysis_port #(uvm_logic_vector::sequence_item #(OUT_META_WIDTH)) analysis_port;

    uvm_reset::sync_terminate reset_sync;
    local uvm_logic_vector::sequence_item #(OUT_META_WIDTH) hi_tr;
    protected logic [128-1 : 0]        hdrs[$];
    protected logic [META_WIDTH-1 : 0] metas[$];

    function new (string name, uvm_component parent);
        super.new(name, parent);
        analysis_imp_data = new("analysis_imp_data", this);
        analysis_imp_meta = new("analysis_imp_meta", this);
        analysis_port     = new("analysis_port", this);
        hi_tr = null;
        reset_sync = new();
    endfunction

    virtual function void write_DATA_PORT(uvm_logic_vector_array::sequence_item #(ITEM_WIDTH) tr);
        logic [128-1 : 0] hdr;

        if (reset_sync.has_been_reset()) begin
            hi_tr = null;
        end

        for (int unsigned it = 0; it < (128/32); it++) begin
            hdr[((it+1)*32-1) -: 32] = tr.data[it];
        end
        hdrs.push_back(hdr);
    endfunction

    virtual function void write_META_PORT(uvm_logic_vector::sequence_item #(META_WIDTH) tr);
        if (reset_sync.has_been_reset()) begin
            hi_tr = null;
        end

        metas.push_back(tr.data);
    endfunction

    virtual task run_phase(uvm_phase phase);
        logic [128-1 : 0] hdr;
        logic [META_WIDTH-1 : 0] meta;
        logic type_n = '0;

        forever begin
            hi_tr = uvm_logic_vector::sequence_item #(OUT_META_WIDTH)::type_id::create("hi_tr");

            if (DEVICE == "STRATIX10" || DEVICE == "AGILEX") begin
                wait(metas.size() != 0);

                meta = metas.pop_front();
                type_n = meta[126];

                hi_tr.data = {meta[META_WIDTH-1 : 128], meta[32-1 : 0], meta[64-1 : 32], meta[96-1 : 64], meta[128-1 : 96]};

            end else begin
                wait(hdrs.size() != 0 && metas.size() != 0);
                hdr = hdrs.pop_front();
                type_n = hdr[75];

                hi_tr.data = {metas.pop_front(), hdr};
            end

            if (type_n == 1'b0) begin
                analysis_port.write(hi_tr);
            end

        end
    endtask

endclass
