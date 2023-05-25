//-- monitor.sv: Monitor for MVB environment
//-- Copyright (C) 2022 CESNET z. s. p. o.
//-- Author(s): Daniel Kříž <xkrizd01@vutbr.cz>

//-- SPDX-License-Identifier: BSD-3-Clause 

class monitor #(META_WIDTH) extends uvm_logic_vector::monitor#(META_WIDTH);
    `uvm_component_param_utils(uvm_pcie::monitor #(META_WIDTH))

    // Analysis port
    typedef monitor #(META_WIDTH) this_type;
    uvm_analysis_imp #(uvm_mi::sequence_item_request #(32, 32, 0), this_type) analysis_export;

    uvm_reset::sync_terminate reset_sync;
    local uvm_logic_vector::sequence_item #(META_WIDTH) hi_tr;

    function new (string name, uvm_component parent);
        super.new(name, parent);
        analysis_export = new("analysis_export", this);
        hi_tr = null;
        reset_sync = new();
    endfunction

    virtual function void write(uvm_mi::sequence_item_request #(32, 32, 0) tr);
        if (reset_sync.has_been_reset()) begin
            hi_tr = null;
        end

        if (tr.ardy && (tr.wr || tr.rd)) begin
            if (tr.rd) begin
                hi_tr = uvm_logic_vector::sequence_item #(META_WIDTH)::type_id::create("hi_tr");
                hi_tr.data = '1;
                analysis_port.write(hi_tr);
            end
        end

    endfunction
endclass
