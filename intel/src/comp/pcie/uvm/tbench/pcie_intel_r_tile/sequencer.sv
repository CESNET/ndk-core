// sequencer.sv: Sequencer for AVST credit control interface
// Copyright (C) 2024 CESNET z. s. p. o.
// Author(s): Yaroslav Marushchenko <xmarus09@stud.fit.vutbr.cz>

// SPDX-License-Identifier: BSD-3-Clause

class sequencer extends uvm_avst_crdt::sequencer;
    `uvm_component_utils(uvm_pcie_intel_r_tile::sequencer)

    // Input fifo
    uvm_tlm_analysis_fifo #(credit_item) credit_fifo_in;

    // Credits in total
    credit_item total;

    // Constructor
    function new(string name = "sequencer", uvm_component parent = null);
        super.new(name, parent);

        credit_fifo_in = new("credit_fifo_in", this);
        total = credit_item::type_id::create("total", this);
    endfunction

    task run_phase(uvm_phase phase);
        credit_item item;

        forever begin
            credit_fifo_in.get(item);

            if (reset_sync.has_been_reset()) begin
                credit_fifo_in.flush();
                total.reset();
                continue;
            end

            total.header.p   += item.header.p;
            total.header.np  += item.header.np;
            total.header.cpl += item.header.cpl;
            total.data.p     += item.data.p;
            total.data.np    += item.data.np;
            total.data.cpl   += item.data.cpl;
        end
    endtask

endclass
