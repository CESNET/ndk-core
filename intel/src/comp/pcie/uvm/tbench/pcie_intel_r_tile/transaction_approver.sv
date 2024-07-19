// transaction_approver.sv: Approves AVST transactions based on credits
// Copyright (C) 2024 CESNET z. s. p. o.
// Author(s): Yaroslav Marushchenko <xmarus09@stud.fit.vutbr.cz>

// SPDX-License-Identifier: BSD-3-Clause

class transaction_approver extends uvm_component;
    `uvm_component_utils(uvm_pcie_intel_r_tile::transaction_approver)

    // Input fifo
    uvm_tlm_analysis_fifo #(uvm_avst_crdt::sequence_item) avst_crdt_in;

    // ---------------------------- //
    // Approval handshake variables //
    // ---------------------------- //

    mailbox #(credit_item) m_mailbox;
    event approve;

    credit_counter m_credit_counter;

    // Constructor
    function new(string name = "transaction_approver", uvm_component parent = null);
        super.new(name, parent);

        m_mailbox = new(1);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        m_credit_counter = credit_counter::type_id::create("m_credit_counter", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        avst_crdt_in = m_credit_counter.avst_crdt_in;
    endfunction

    task run_phase(uvm_phase phase);
        credit_item cost;

        forever begin
            wait(m_mailbox.num() == 1);
            m_mailbox.get(cost);
            m_credit_counter.wait_for_init_done();
            m_credit_counter.reduce_balance(cost);
            ->approve;
        end
    endtask

endclass
