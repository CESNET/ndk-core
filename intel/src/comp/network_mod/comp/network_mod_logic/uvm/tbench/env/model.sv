// model.sv: Model of implementation
// Copyright (C) 2022 CESNET z. s. p. o.
// Author(s): Daniel Kondys <xkondy00@vutbr.cz>

// SPDX-License-Identifier: BSD-3-Clause 


class model #(CHANNELS, META_WIDTH) extends uvm_component;
    `uvm_component_param_utils(net_mod_logic_env::model#(CHANNELS, META_WIDTH))

    // TX path
    uvm_tlm_analysis_fifo #(byte_array::sequence_item)                 tx_input_data;
    uvm_tlm_analysis_fifo #(logic_vector::sequence_item #(META_WIDTH)) tx_input_meta;
    uvm_analysis_port #(byte_array::sequence_item)                     tx_out_data[CHANNELS];

    // RX path - a simple connection of input to output
    uvm_tlm_analysis_fifo #(byte_array::sequence_item) rx_input_data[CHANNELS];
    uvm_analysis_port #(byte_array::sequence_item)     rx_out_data[CHANNELS];

    function new(string name = "model", uvm_component parent = null);
        super.new(name, parent);

        // TX path
        tx_input_data = new("tx_input_data", this);
        tx_input_meta = new("tx_input_meta", this);
        for (int unsigned it = 0; it < CHANNELS; it++) begin
            string str_it;

            str_it.itoa(it);
            tx_out_data[it] = new({"tx_out_data_", str_it}, this);
        end

        // RX path
        for (int unsigned it = 0; it < CHANNELS; it++) begin
            string str_it;

            str_it.itoa(it);
            rx_out_data[it]   = new({"rx_out_data_", str_it}, this);
            rx_input_data[it] = new({"rx_input_data_", str_it}, this);
        end
    endfunction

    task run_phase(uvm_phase phase);
        int unsigned tx_channel;
        byte_array::sequence_item                 tr_tx_input_packet;
        logic_vector::sequence_item #(META_WIDTH) tr_tx_input_meta;

        byte_array::sequence_item                 tr_rx_input_packet;

        forever begin
            // TX path
            tx_input_data.get(tr_tx_input_packet);
            tx_input_meta.get(tr_tx_input_meta);

            // choose one !
            // tx_channel = tr_tx_input_meta.data[16]; // if CHANNELS == 1
            tx_channel = tr_tx_input_meta.data[$clog2(CHANNELS)-1 +16: 0 +16]; // if CHANNELS > 1

            if (tx_channel >= CHANNELS) begin
                string msg;
                $swrite(msg, "\n\tTX: Wrong channel num %0d Channel range is 0-%0d", tx_channel, CHANNELS-1);
                `uvm_fatal(this.get_full_name(), msg);
            end else begin
                tx_out_data[tx_channel].write(tr_tx_input_packet);
            end

            // RX path
            for (int unsigned ch = 0; ch < CHANNELS; ch++) begin
                rx_input_data[ch].get(tr_rx_input_packet);
                rx_out_data[ch].write(tr_rx_input_packet);
            end

        end
    endtask

endclass
