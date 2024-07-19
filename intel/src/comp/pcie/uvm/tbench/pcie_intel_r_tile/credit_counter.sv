// credit_counter.sv: Counter of AVST credits
// Copyright (C) 2024 CESNET z. s. p. o.
// Author(s): Yaroslav Marushchenko <xmarus09@stud.fit.vutbr.cz>

// SPDX-License-Identifier: BSD-3-Clause

class credit_counter extends uvm_component;
    `uvm_component_utils(uvm_pcie_intel_r_tile::credit_counter)

    // Input fifo
    uvm_tlm_analysis_fifo #(uvm_avst_crdt::sequence_item) avst_crdt_in;

    // --------- //
    // Variables //
    // --------- //

    protected logic init_done;
    protected logic infinite_credits;
    protected credit_item balance;

    // Constructor
    function new(string name = "credit_counter", uvm_component parent = null);
        super.new(name, parent);

        avst_crdt_in = new("avst_crdt_in", this);
    endfunction

    task run_phase(uvm_phase phase);
        uvm_avst_crdt::sequence_item avst_crdt_item;

        balance = credit_item::type_id::create("balance");
        infinite_credits = 0;
        init_done        = 0;

        forever begin
            avst_crdt_in.get(avst_crdt_item);

            // Initialization
            if (init_done == 0 && avst_crdt_item.init_done === 1'b1) begin // End of initialization
                // 0 credits => inifinite credits
                if (balance.is_zero()) begin
                    infinite_credits = 1;
                end

                init_done = 1;
            end
            else if (init_done == 1 && avst_crdt_item.init_done === 1'b0) begin // Start of initialization
                balance.reset();
                infinite_credits = 0;
                init_done        = 0;
            end

            // Skip credit incrementing
            if (infinite_credits) begin
                continue;
            end

            // Header
            if (avst_crdt_item.update[0] === 1'b1) begin
                balance.header.p += avst_crdt_item.cnt_ph;
            end
            if (avst_crdt_item.update[1] === 1'b1) begin
                balance.header.np += avst_crdt_item.cnt_nph;
            end
            if (avst_crdt_item.update[2] === 1'b1) begin
                balance.header.cpl += avst_crdt_item.cnt_cplh;
            end
            // Data
            if (avst_crdt_item.update[3] === 1'b1) begin
                balance.data.p += avst_crdt_item.cnt_pd;
            end
            if (avst_crdt_item.update[4] === 1'b1) begin
                balance.data.np += avst_crdt_item.cnt_npd;
            end
            if (avst_crdt_item.update[5] === 1'b1) begin
                balance.data.cpl += avst_crdt_item.cnt_cpld;
            end
        end
    endtask

    function logic is_init_done();
        return init_done;
    endfunction

    task wait_for_init_done();
        wait(init_done);
    endtask

    task reduce_balance(credit_item cost);
        if (infinite_credits) begin
            return;
        end

        wait(balance.header.p   >= cost.header.p   &&
             balance.header.np  >= cost.header.np  &&
             balance.header.cpl >= cost.header.cpl &&
             balance.data.p     >= cost.data.p     &&
             balance.data.np    >= cost.data.np    &&
             balance.data.cpl   >= cost.data.cpl);

        balance.header.p   -= cost.header.p;
        balance.header.np  -= cost.header.np;
        balance.header.cpl -= cost.header.cpl;
        balance.data.p     -= cost.data.p;
        balance.data.np    -= cost.data.np;
        balance.data.cpl   -= cost.data.cpl;
    endtask

    function logic try_reduce_balance(credit_item cost);
        if (infinite_credits) begin
            return 1;
        end

        if (balance.header.p   >= cost.header.p   &&
            balance.header.np  >= cost.header.np  &&
            balance.header.cpl >= cost.header.cpl &&
            balance.data.p     >= cost.data.p     &&
            balance.data.np    >= cost.data.np    &&
            balance.data.cpl   >= cost.data.cpl)
        begin
            balance.header.p   -= cost.header.p;
            balance.header.np  -= cost.header.np;
            balance.header.cpl -= cost.header.cpl;
            balance.data.p     -= cost.data.p;
            balance.data.np    -= cost.data.np;
            balance.data.cpl   -= cost.data.cpl;

            return 1;
        end
        else begin
            return 0;
        end
    endfunction

endclass
