/*
 * file       : agent.sv
 * Copyright (C) 2021 CESNET z. s. p. o.
 * description: top_agent
 * date       : 2021
 * author     : Radek Iša <isa@cesnet.cz>
 *
 * SPDX-License-Identifier: BSD-3-Clause
*/

class agent #(ITEM_WIDTH) extends uvm_agent;
    // registration of component tools
    `uvm_component_param_utils(uvm_app_core_top_agent::agent#(ITEM_WIDTH))

    // -----------------------
    // Variables.
    // -----------------------
    uvm_reset::sync_cbs       reset_sync;
    uvm_logic_vector_array::sequencer#(ITEM_WIDTH) m_sequencer;
    driver#(ITEM_WIDTH)       m_driver;

    // Contructor, where analysis port is created.
    function new(string name, uvm_component parent = null);
        super.new(name, parent);
    endfunction: new

    // -----------------------
    // Functions.
    // -----------------------

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        reset_sync  = new();
        m_sequencer = uvm_logic_vector_array::sequencer#(ITEM_WIDTH)::type_id::create("m_sequencer", this);
        m_driver    = driver#(ITEM_WIDTH)::type_id::create("m_driver", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        m_driver.seq_item_port.connect(m_sequencer.seq_item_export);
        reset_sync.push_back(m_sequencer.reset_sync);
        reset_sync.push_back(m_driver.reset_sync);
    endfunction
endclass

