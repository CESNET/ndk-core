/*
 * file       : agent.sv
 * Copyright (C) 2021 CESNET z. s. p. o.
 * description: top_agent
 * date       : 2021
 * author     : Radek Iša <isa@cesnet.cz>
 *
 * SPDX-License-Identifier: BSD-3-Clause
*/

class driver#(ITEM_WIDTH) extends uvm_driver #(uvm_logic_vector_array::sequence_item#(ITEM_WIDTH));
    // registration of component tools
    `uvm_component_param_utils(uvm_app_core_top_agent::driver#(ITEM_WIDTH))

    //RESET reset_sync
    uvm_reset::sync_terminate reset_sync;

    uvm_logic_vector_array::sequence_item#(ITEM_WIDTH) m_sequencer;
    mailbox#(uvm_logic_vector_array::sequence_item#(ITEM_WIDTH)) logic_vector_array_export;
    mailbox#(uvm_logic_vector_array::sequence_item#(ITEM_WIDTH)) header_export;

    // Contructor, where analysis port is created.
    function new(string name, uvm_component parent = null);
        super.new(name, parent);
        logic_vector_array_export = new(10);
        header_export     = new(10);
        reset_sync = new();
    endfunction: new

    // -----------------------
    // Functions.
    // -----------------------

    task run_phase(uvm_phase phase);
        uvm_logic_vector_array::sequence_item#(ITEM_WIDTH) clone_item;

        forever begin
            // Get new sequence item to drive to interface
            wait((logic_vector_array_export.num() < 10 &&  header_export.num() < 10) || reset_sync.is_reset());
            if (reset_sync.has_been_reset()) begin
                uvm_logic_vector_array::sequence_item#(ITEM_WIDTH) tmp;

                while (logic_vector_array_export.try_get(tmp)) begin
                end

                while (header_export.try_get(tmp)) begin
                end

                while(reset_sync.has_been_reset() != 0) begin
                    #(40ns);
                end
            end

            seq_item_port.get_next_item(req);
            $cast(clone_item, req.clone());
            logic_vector_array_export.put(clone_item);
            header_export.put(clone_item);
            seq_item_port.item_done();
        end
    endtask
endclass

