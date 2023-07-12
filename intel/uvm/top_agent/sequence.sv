/*
 * file       : sequence.sv
 * Copyright (C) 2021 CESNET z. s. p. o.
 * description:  top agent
 * date       : 2021
 * author     : Radek Iša <isa@cesnet.ch>
 *
 * SPDX-License-Identifier: BSD-3-Clause
*/

class logic_vector_array_sequence_simple#(ITEM_WIDTH) extends uvm_sequence #(uvm_logic_vector_array::sequence_item#(ITEM_WIDTH));
    `uvm_object_param_utils(uvm_app_core_top_agent::logic_vector_array_sequence_simple#(ITEM_WIDTH))
    `uvm_declare_p_sequencer(uvm_logic_vector_array::sequencer#(ITEM_WIDTH));

    mailbox#(uvm_logic_vector_array::sequence_item#(ITEM_WIDTH)) packet_export;

    // Constructor - creates new instance of this class
    function new(string name = "sequence");
        super.new(name);
    endfunction

    // -----------------------
    // Functions.
    // -----------------------
    task body;
        req = uvm_logic_vector_array::sequence_item#(ITEM_WIDTH)::type_id::create("req", p_sequencer);
        if(!uvm_config_db#(mailbox#(uvm_logic_vector_array::sequence_item#(ITEM_WIDTH)))::get(p_sequencer, "", "packet_export", packet_export)) begin
            `uvm_fatal(p_sequencer.get_full_name(), "\n\tFailed to get packet msg box");
        end

        forever begin
            uvm_logic_vector_array::sequence_item#(ITEM_WIDTH) tmp_packet;

            //wait to end reset
            packet_export.get(tmp_packet);

            //generat new packet
            start_item(req);
            req.copy(tmp_packet);
            finish_item(req);
        end
    endtask

endclass


class mvb_config;
    int unsigned port_max = 16;
    int unsigned port_min = 0;
endclass

class logic_vector_sequence_simple_eth #(ITEM_WIDTH, HDR_WIDTH) extends uvm_sequence #(uvm_logic_vector::sequence_item #(HDR_WIDTH));
    `uvm_object_param_utils(uvm_app_core_top_agent::logic_vector_sequence_simple_eth  #(ITEM_WIDTH, HDR_WIDTH))
    `uvm_declare_p_sequencer(uvm_logic_vector::sequencer#(HDR_WIDTH));

    mailbox#(uvm_logic_vector_array::sequence_item#(ITEM_WIDTH)) header_export;

    // ------------------------------------------------------------------------
    // Variables
    int unsigned transaction_count_max = 2048;
    int unsigned transaction_count_min = 32;
    rand int unsigned transaction_count;
    mvb_config   m_config;

    constraint tr_cnt_cons {transaction_count inside {[transaction_count_min:transaction_count_max]};}

    // ------------------------------------------------------------------------
    // Constructor
    function new(string name = "logic_vector_sequence_simple_eth");
        super.new(name);
    endfunction

    // ------------------------------------------------------------------------
    // Generates transactions
    task body();
        logic reset;
        // Generate transaction_count transactions
        req = uvm_logic_vector::sequence_item #(HDR_WIDTH)::type_id::create("req", p_sequencer);

        if(!uvm_config_db#(mailbox#(uvm_logic_vector_array::sequence_item#(ITEM_WIDTH)))::get(p_sequencer, "", "hdr_export", header_export)) begin
            `uvm_fatal(p_sequencer.get_full_name(), "\n\tFailed to get packet msg box");
        end

        if(!uvm_config_db#(mvb_config)::get(p_sequencer, "", "m_config", m_config)) begin
            `uvm_fatal(p_sequencer.get_full_name(), "\n\tFailed to get mvb_config");
        end

        repeat(transaction_count) begin
            uvm_logic_vector_array::sequence_item#(ITEM_WIDTH) tmp_packet;
            // Create a request for sequence item

            header_export.get(tmp_packet);

            start_item(req);
            // Do not generate new data when SRC_RDY was 1 but the transaction does not transfare;
            if (!req.randomize() with {data[24-1:16] inside {[m_config.port_min:m_config.port_max]};}) begin
                `uvm_fatal(p_sequencer.get_full_name(), "\n\tSequence faile to randomize transaction.")
            end
            req.data[16-1:0] = tmp_packet.size();
            finish_item(req);
        end
    endtask
endclass

class logic_vector_sequence_lib_eth #(ITEM_WIDTH, HDR_WIDTH) extends uvm_sequence_library#(uvm_logic_vector::sequence_item#(HDR_WIDTH));
  `uvm_object_param_utils(uvm_app_core_top_agent::logic_vector_sequence_lib_eth #(ITEM_WIDTH, HDR_WIDTH))
  `uvm_sequence_library_utils(uvm_app_core_top_agent::logic_vector_sequence_lib_eth#(ITEM_WIDTH, HDR_WIDTH))

    function new(string name = "");
        super.new(name);
        init_sequence_library();
    endfunction

    // subclass can redefine and change run sequences
    // can be useful in specific tests
    virtual function void init_sequence();
        this.add_sequence(logic_vector_sequence_simple_eth #(ITEM_WIDTH, HDR_WIDTH)::get_type());
    endfunction
endclass

class logic_vector_sequence_simple #(ITEM_WIDTH, HDR_WIDTH, PKT_MTU) extends uvm_sequence #(uvm_logic_vector::sequence_item #(HDR_WIDTH));
    `uvm_object_param_utils(uvm_app_core_top_agent::logic_vector_sequence_simple #(ITEM_WIDTH, HDR_WIDTH, PKT_MTU))
    `uvm_declare_p_sequencer(uvm_logic_vector::sequencer#(HDR_WIDTH));

    mailbox#(uvm_logic_vector_array::sequence_item#(ITEM_WIDTH)) header_export;

    // ------------------------------------------------------------------------
    // Variables
    int unsigned transaction_count_max = 2048;
    int unsigned transaction_count_min = 32;
    rand int unsigned transaction_count;

    constraint tr_cnt_cons {transaction_count inside {[transaction_count_min:transaction_count_max]};}

    // ------------------------------------------------------------------------
    // Constructor
    function new(string name = "Simple sequence rx");
        super.new(name);
    endfunction

    // ------------------------------------------------------------------------
    // Generates transactions
    task body();
        // Generate transaction_count transactions
        req = uvm_logic_vector::sequence_item #(HDR_WIDTH)::type_id::create("req", p_sequencer);
        if(!uvm_config_db#(mailbox#(uvm_logic_vector_array::sequence_item#(ITEM_WIDTH)))::get(p_sequencer, "", "hdr_export", header_export)) begin
            `uvm_fatal(p_sequencer.get_full_name(), "\n\tFailed to get packet msg box");
        end

        repeat(transaction_count) begin
            // Create a request for sequence item
            uvm_logic_vector_array::sequence_item#(ITEM_WIDTH) tmp_packet;
            header_export.get(tmp_packet);

            //generat new packet
            start_item(req);
            // Do not generate new data when SRC_RDY was 1 but the transaction does not transfare;
            if (!req.randomize()) begin
                `uvm_fatal(p_sequencer.get_full_name(), "\n\tSequence faile to randomize transaction.")
            end
            req.data[PKT_MTU-1:0] = tmp_packet.size();
            finish_item(req);
        end
    endtask
endclass

class logic_vector_sequence_lib#(ITEM_WIDTH, HDR_WIDTH, PKT_MTU) extends uvm_sequence_library#(uvm_logic_vector::sequence_item#(HDR_WIDTH));
  `uvm_object_param_utils(uvm_app_core_top_agent::logic_vector_sequence_lib#(ITEM_WIDTH, HDR_WIDTH, PKT_MTU))
  `uvm_sequence_library_utils(uvm_app_core_top_agent::logic_vector_sequence_lib#(ITEM_WIDTH, HDR_WIDTH, PKT_MTU))

    function new(string name = "");
        super.new(name);
        init_sequence_library();
    endfunction

    // subclass can redefine and change run sequences
    // can be useful in specific tests
    virtual function void init_sequence();
        this.add_sequence(logic_vector_sequence_simple #(ITEM_WIDTH, HDR_WIDTH, PKT_MTU)::get_type());
    endfunction
endclass

