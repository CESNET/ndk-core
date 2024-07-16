//-- monitor.sv: convet logic_vector and logic_vector_array to packet
//-- Copyright (C) 2024 CESNET z. s. p. o.
//-- Author(s): Radek Iša <isa@cesnet.cz>

//-- SPDX-License-Identifier: BSD-3-Clause 


class monitor #(type TR_TYPE, int unsigned ITEM_WIDTH, int unsigned META_WIDTH) extends uvm_monitor;
    `uvm_component_param_utils(uvm_app_core_top_agent::monitor #(TR_TYPE, ITEM_WIDTH, META_WIDTH))

    // ------------------------------------------------------------------------
    uvm_tlm_analysis_fifo#(uvm_logic_vector::sequence_item #(META_WIDTH))      mvb;
    uvm_tlm_analysis_fifo#(uvm_logic_vector_array::sequence_item#(ITEM_WIDTH)) mfb;

    // Analysis port used to send transactions to all connected components.
    uvm_analysis_port #(TR_TYPE) analysis_port;

    // ------------------------------------------------------------------------
    // Constructor
    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    // ------------------------------------------------------------------------
    // Functions
    function void build_phase(uvm_phase phase);
        analysis_port = new("analysis port", this);
        mvb = new("mvb", this);
        mfb = new("mfb", this);
    endfunction

    task run_phase(uvm_phase phase);
        uvm_logic_vector::sequence_item #(META_WIDTH)      mvb_tr;
        uvm_logic_vector_array::sequence_item#(ITEM_WIDTH) mfb_tr;

        forever begin
            bit bitstream [];
            TR_TYPE item;

            item = TR_TYPE::type_id::create("item", this);

            mvb.get(mvb_tr);
            mfb.get(mfb_tr);

            item.meta2item(mvb_tr.data);
            item.unpack(bitstream);

            analysis_port.write(item);
        end
    endtask

endclass


