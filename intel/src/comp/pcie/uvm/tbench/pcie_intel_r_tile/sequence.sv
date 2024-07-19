// sequence.sv: AVST credit control sequence
// Copyright (C) 2024 CESNET z. s. p. o.
// Author(s): Yaroslav Marushchenko <xmarus09@stud.fit.vutbr.cz>

// SPDX-License-Identifier: BSD-3-Clause

class sequence_returning extends uvm_avst_crdt::sequence_simple;
    `uvm_object_utils(uvm_pcie_intel_r_tile::sequence_returning)
    `uvm_declare_p_sequencer(uvm_pcie_intel_r_tile::sequencer)

    // Constructor
    function new(string name = "sequence_returning");
        super.new(name);
    endfunction

    task send_frame();
        logic randomization_result;
        start_item(req);

        randomization_result = req.randomize() with {
            init_done == 1'b1;
            cnt_ph   inside {[0 : p_sequencer.total.header.p]};
            cnt_nph  inside {[0 : p_sequencer.total.header.np]};
            cnt_cplh inside {[0 : p_sequencer.total.header.cpl]};
            cnt_pd   inside {[0 : p_sequencer.total.data.p]};
            cnt_npd  inside {[0 : p_sequencer.total.data.np]};
            cnt_cpld inside {[0 : p_sequencer.total.data.cpl]};
        };
        assert(randomization_result)
        else begin
            `uvm_fatal(this.get_full_name(), "\n\tSequence randomization error.")
        end

        finish_item(req);
        get_response(rsp);

        // ------------ //
        // Reduce total //
        // ------------ //

        p_sequencer.total.header.p   -= req.update[0] ? req.cnt_ph   : 0;
        p_sequencer.total.header.np  -= req.update[1] ? req.cnt_nph  : 0;
        p_sequencer.total.header.cpl -= req.update[2] ? req.cnt_cplh : 0;
        p_sequencer.total.data.p     -= req.update[3] ? req.cnt_pd   : 0;
        p_sequencer.total.data.np    -= req.update[4] ? req.cnt_npd  : 0;
        p_sequencer.total.data.cpl   -= req.update[5] ? req.cnt_cpld : 0;
    endtask

    // Generate transactions
    task body;
        int unsigned it;
        uvm_common::sequence_cfg state;

        if(!uvm_config_db#(uvm_common::sequence_cfg)::get(p_sequencer, "", "state", state)) begin
            state = null;
        end

        // Generate transaction_count transactions
        req = uvm_avst_crdt::sequence_item::type_id::create("req");
        it = 0;
        while (it < transaction_count && (state == null || state.next())) begin
            // Create a request for sequence item
            send_frame();
            it++;
        end
    endtask

endclass
