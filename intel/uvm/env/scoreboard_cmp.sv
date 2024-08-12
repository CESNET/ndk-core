/*
 * file       : scoreboard_cmp.sv
 * Copyright (C) 2021 CESNET z. s. p. o.
 * description:  Scoreboard comparator 
 * date       : 2021
 * author     : Radek Iša <isa@cesnet.ch>
 *
 * SPDX-License-Identifier: BSD-3-Clause
*/

class scoreboard_channel_mfb #(type CLASS_TYPE) extends uvm_common::comparer_base_unordered#(CLASS_TYPE, CLASS_TYPE);
    `uvm_component_param_utils(uvm_app_core::scoreboard_channel_mfb #(CLASS_TYPE))

    function new(string name, uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function int unsigned compare(MODEL_ITEM tr_model, DUT_ITEM tr_dut);
        return tr_model.compare(tr_dut);
    endfunction

    virtual function string model_item2string(MODEL_ITEM tr);
        return tr.convert2string();
    endfunction

    virtual function string dut_item2string(DUT_ITEM tr);
        return tr.convert2string();
    endfunction
endclass


class scoreboard_channel_header #(HDR_WIDTH, META_WIDTH, CHANNELS, PKT_MTU) extends uvm_common::comparer_base_unordered #(packet_header #(META_WIDTH, CHANNELS, PKT_MTU), uvm_logic_vector::sequence_item#(HDR_WIDTH));
    `uvm_component_param_utils(uvm_app_core::scoreboard_channel_header #(HDR_WIDTH, META_WIDTH, CHANNELS, PKT_MTU))

    function new(string name, uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function int unsigned compare(packet_header #(META_WIDTH, CHANNELS, PKT_MTU) tr_model, uvm_logic_vector::sequence_item#(HDR_WIDTH) tr_dut);
        int unsigned eq = 1;
        logic [META_WIDTH-1:0]meta = 'x;
        logic [$clog2(CHANNELS)-1:0] channel;
        logic [$clog2(PKT_MTU+1)] packet_size;
        logic discard;

        if (META_WIDTH == 0) begin
            {discard, channel, packet_size} = tr_dut.data;
        end else begin
            {discard, channel, meta, packet_size} = tr_dut.data;
        end

        eq &= (discard === tr_model.discard);
        eq &= (channel === tr_model.channel);
        if (META_WIDTH != 0) begin
            eq &= (meta    === tr_model.meta);
        end
        eq &= (packet_size === tr_model.packet_size);

        return eq;
    endfunction


    virtual function string model_item2string(MODEL_ITEM tr);
        return tr.convert2string();
    endfunction

    virtual function string dut_item2string(DUT_ITEM tr);
        string error_msg; //ETH [%0d] header
        logic [META_WIDTH-1:0]meta = 'x;
        logic [$clog2(CHANNELS)-1:0] channel;
        logic [$clog2(PKT_MTU+1)] packet_size;
        logic discard;

        if (META_WIDTH == 0) begin
            {discard, channel, packet_size} = tr.data;
        end else begin
            {discard, channel, meta, packet_size} = tr.data;
        end

        error_msg = "";
        error_msg = {error_msg, $sformatf("\n\t\tdiscard %b", discard)};
        error_msg = {error_msg, $sformatf("\n\t\tchannel %0d", channel)};
        error_msg = {error_msg, $sformatf("\n\t\tmeta    %h",  meta)};
        error_msg = {error_msg, $sformatf("\n\t\tpacket_size %0d", packet_size)};

        return error_msg;
    endfunction
endclass

