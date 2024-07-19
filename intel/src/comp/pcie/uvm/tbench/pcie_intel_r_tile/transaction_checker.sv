// transaction_checker.sv: Checks AVST transaction's validity based on credits
// Copyright (C) 2024 CESNET z. s. p. o.
// Author(s): Yaroslav Marushchenko <xmarus09@stud.fit.vutbr.cz>

// SPDX-License-Identifier: BSD-3-Clause

class transaction_checker #(REGIONS, REGION_SIZE, BLOCK_SIZE, ITEM_WIDTH, META_WIDTH, READY_LATENCY) extends uvm_component;
    `uvm_component_param_utils(uvm_pcie_intel_r_tile::transaction_checker #(REGIONS, REGION_SIZE, BLOCK_SIZE, ITEM_WIDTH, META_WIDTH, READY_LATENCY))

    localparam int unsigned HDR_WIDTH    = 128;
    localparam int unsigned PREFIX_WIDTH = 32;

    // Inputs
    uvm_tlm_analysis_fifo #(uvm_avst::sequence_item #(REGIONS, REGION_SIZE, BLOCK_SIZE, ITEM_WIDTH, META_WIDTH)) avst_in;
    uvm_tlm_analysis_fifo #(uvm_avst_crdt::sequence_item)                                                        avst_crdt_in;

    credit_counter m_credit_counter;

    // AVST items => logic vector items => credit items converting logic
    protected uvm_logic_vector_array_avst::monitor_logic_vector #(REGIONS, REGION_SIZE, BLOCK_SIZE, ITEM_WIDTH, META_WIDTH, READY_LATENCY) m_monitor;
    protected valuer #(META_WIDTH) m_valuer;
    protected uvm_tlm_analysis_fifo #(credit_item) credit_fifo;

    // Constructor
    function new(string name = "transaction_checker", uvm_component parent = null);
        super.new(name, parent);

        avst_in      = new("avst_in", this);
        avst_crdt_in = new("avst_crdt_in", this);
        credit_fifo  = new("credit_fifo", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        m_credit_counter = credit_counter::type_id::create("m_credit_counter", this);
        m_valuer = valuer #(META_WIDTH)::type_id::create("m_valuer", this);
        m_monitor = uvm_logic_vector_array_avst::monitor_logic_vector #(REGIONS, REGION_SIZE, BLOCK_SIZE, ITEM_WIDTH, META_WIDTH, READY_LATENCY)::type_id::create("m_monitor", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        m_monitor.analysis_port.connect(m_valuer.analysis_export);
        m_valuer.analysis_port.connect(credit_fifo.analysis_export);
    endfunction

    task run_phase(uvm_phase phase);
        uvm_avst::sequence_item #(REGIONS, REGION_SIZE, BLOCK_SIZE, ITEM_WIDTH, META_WIDTH) avst_item;
        uvm_avst_crdt::sequence_item                                                        avst_crdt_item;

        credit_item total_cost;
        credit_item item_cost;

        total_cost = credit_item::type_id::create("total_cost");

        forever begin
            avst_in     .get(avst_item);
            avst_crdt_in.get(avst_crdt_item);

            total_cost.reset();

            // Write AVST item to monitor
            m_monitor.write(avst_item);
            while (credit_fifo.used() > 0) begin // Get all credit items
                credit_fifo.get(item_cost);

                total_cost.header.p   += item_cost.header.p;
                total_cost.header.np  += item_cost.header.np;
                total_cost.header.cpl += item_cost.header.cpl;
                total_cost.data.p     += item_cost.data.p;
                total_cost.data.np    += item_cost.data.np;
                total_cost.data.cpl   += item_cost.data.cpl;
            end

            if (!total_cost.is_zero()) begin
                assert(m_credit_counter.is_init_done())
                else begin
                    `uvm_error(this.get_full_name(), "\n\tUser can't send the transaction while initializing phase is in progress!")
                end
                assert(m_credit_counter.try_reduce_balance(total_cost))
                else begin
                    `uvm_error(this.get_full_name(), "\n\tUser has insufficient number of credits to send the transaction!")
                end
            end

            m_credit_counter.avst_crdt_in.write(avst_crdt_item);
        end
    endtask

endclass
