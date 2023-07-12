/*
 * file       : scoreboard_cmp.sv
 * Copyright (C) 2021 CESNET z. s. p. o.
 * description:  Scoreboard comparator 
 * date       : 2021
 * author     : Radek Iša <isa@cesnet.ch>
 *
 * SPDX-License-Identifier: BSD-3-Clause
*/

class scoreboard_channel_mfb #(type CLASS_TYPE) extends uvm_common::comparer_base_tagged#(CLASS_TYPE, CLASS_TYPE);
    `uvm_component_param_utils(uvm_app_core::scoreboard_channel_mfb #(CLASS_TYPE))

    function new(string name, uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function int unsigned compare(uvm_common::model_item #(MODEL_ITEM) tr_model, uvm_common::dut_item #(DUT_ITEM) tr_dut);
        string msg = message(tr_model, tr_dut);
        return tr_model.item.compare(tr_dut.in_item);
    endfunction

    virtual function string message(uvm_common::model_item #(MODEL_ITEM) tr_model, uvm_common::dut_item #(DUT_ITEM) tr_dut);
        string msg = "";
        $swrite(msg, "%s\n\tDUT PACKET %s\n\n",   msg, tr_dut.convert2string());
        $swrite(msg, "%s\n\tMODEL PACKET%s\n\n",  msg, tr_model.convert2string());
        return msg;
    endfunction

endclass


class scoreboard_channel_header #(HDR_WIDTH, META_WIDTH, CHANNELS, PKT_MTU) extends uvm_common::comparer_base_tagged #(packet_header #(META_WIDTH, CHANNELS, PKT_MTU), uvm_logic_vector::sequence_item#(HDR_WIDTH));
    `uvm_component_param_utils(uvm_app_core::scoreboard_channel_header #(HDR_WIDTH, META_WIDTH, CHANNELS, PKT_MTU))

    function new(string name, uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function int unsigned compare(uvm_common::model_item #(packet_header #(META_WIDTH, CHANNELS, PKT_MTU)) tr_model, uvm_common::dut_item #(uvm_logic_vector::sequence_item#(HDR_WIDTH)) tr_dut);
        int unsigned eq = 1;
        logic [META_WIDTH-1:0]meta = 'x;
        logic [$clog2(CHANNELS)-1:0] channel;
        logic [$clog2(PKT_MTU+1)] packet_size;
        logic discard;
        string msg = message(tr_model, tr_dut);

        if (META_WIDTH == 0) begin
            {discard, channel, packet_size} = tr_dut.in_item.data;
        end else begin
            {discard, channel, meta, packet_size} = tr_dut.in_item.data;
        end

        eq &= (discard === tr_model.item.discard);
        eq &= (channel === tr_model.item.channel);
        if (META_WIDTH != 0) begin
            eq &= (meta    === tr_model.item.meta);
        end
        eq &= (packet_size === tr_model.item.packet_size);

        return eq;
    endfunction

    virtual function string message(uvm_common::model_item #(packet_header #(META_WIDTH, CHANNELS, PKT_MTU)) tr_model, uvm_common::dut_item #(uvm_logic_vector::sequence_item#(HDR_WIDTH)) tr_dut);
        string error_msg; //ETH [%0d] header
        logic [META_WIDTH-1:0]meta = 'x;
        logic [$clog2(CHANNELS)-1:0] channel;
        logic [$clog2(PKT_MTU+1)] packet_size;
        logic discard;

        if (META_WIDTH == 0) begin
            {discard, channel, packet_size} = tr_dut.in_item.data;
        end else begin
            {discard, channel, meta, packet_size} = tr_dut.in_item.data;
        end
        $swrite(error_msg, "\n\t\t          [DUT model]");
        $swrite(error_msg, "%s\n\t\tTAG     [%b]", error_msg, tr_model.tag);
        $swrite(error_msg, "%s\n\t\tdiscard [%b %b]", error_msg, discard, tr_model.item.discard);
        $swrite(error_msg, "%s\n\t\tchannel [%0d %0d]", error_msg, channel, tr_model.item.channel);
        $swrite(error_msg, "%s\n\t\tmeta    [%h %h]", error_msg, meta, tr_model.item.meta);
        $swrite(error_msg, "%s\n\t\tpacket_size [%0d %0d]", error_msg, packet_size, tr_model.item.packet_size);

        return error_msg;
    endfunction
endclass

