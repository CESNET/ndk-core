//-- driver.sv: Clone packet transaction to mfb and mvb
//-- Copyright (C) 2024 CESNET z. s. p. o.
//-- Author(s): Radek Iša <isa@cesnet.cz>

//-- SPDX-License-Identifier: BSD-3-Clause 


class driver#(ITEM_WIDTH, META_WIDTH) extends uvm_driver #(sequence_item#(ITEM_WIDTH, META_WIDTH));
    `uvm_component_param_utils(uvm_app_core_top_agent::driver#(ITEM_WIDTH, META_WIDTH))

    //RESET reset_sync
    uvm_reset::sync_terminate reset_sync;

    // Contructor, where analysis port is created.
    function new(string name, uvm_component parent = null);
        super.new(name, parent);
        reset_sync = new();
    endfunction: new

    // -----------------------
    // Functions.
    // -----------------------

    task run_phase(uvm_phase phase);
        uvm_common::fifo#(sequence_item#(ITEM_WIDTH, META_WIDTH)) fifo_mvb;
        uvm_common::fifo#(sequence_item#(ITEM_WIDTH, META_WIDTH)) fifo_mfb;

        assert (uvm_config_db#(uvm_common::fifo#(sequence_item#(ITEM_WIDTH, META_WIDTH)))::get(this, "", "fifo_mvb", fifo_mvb)) else begin
            `uvm_fatal(this.get_full_name(), "\n\tCannot get mvb fifo");
        end

        assert (uvm_config_db#(uvm_common::fifo#(sequence_item#(ITEM_WIDTH, META_WIDTH)))::get(this, "", "fifo_mfb", fifo_mfb)) else begin
            `uvm_fatal(this.get_full_name(), "\n\tCannot get mfb fifo");
        end


        forever begin
            sequence_item#(ITEM_WIDTH, META_WIDTH) gen;

            // Get new sequence item to drive to interface
            wait((fifo_mvb.size() < 20 && fifo_mfb.size() < 20) || reset_sync.is_reset());
            if (reset_sync.has_been_reset()) begin

                fifo_mvb.flush();
                fifo_mfb.flush();

                while(reset_sync.has_been_reset() != 0) begin
                    #(40ns);
                end
            end

            seq_item_port.get_next_item(req);
            $cast(gen, req.clone());

            fifo_mvb.push_back(gen);
            fifo_mfb.push_back(gen);
            seq_item_port.item_done();
        end
    endtask
endclass

