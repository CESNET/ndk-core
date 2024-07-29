//-- scoreboard_cmp.sv: scoreboard 
//-- Copyright (C) 2023 CESNET z. s. p. o.
//-- Author(s): Radek Iša <isa@cesnet.cz>

//-- SPDX-License-Identifier: BSD-3-Clause


class comparer_tx_hdr #(int unsigned ITEM_WIDTH) extends uvm_common::comparer_base_ordered#(uvm_logic_vector::sequence_item#(ITEM_WIDTH), uvm_logic_vector::sequence_item#(ITEM_WIDTH));
    `uvm_component_param_utils(uvm_network_mod_env::comparer_tx_hdr#(ITEM_WIDTH))

    function new(string name, uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function int unsigned compare(uvm_common::model_item #(MODEL_ITEM) tr_model, uvm_common::dut_item #(DUT_ITEM) tr_dut);
        int unsigned ret = 1;
        logic [16-1:0] dut_length;
        logic [8-1:0]  dut_port;
        logic [1-1:0]  dut_error;
        logic [1-1:0]  dut_error_frame;
        logic [1-1:0]  dut_error_min_tu;
        logic [1-1:0]  dut_error_max_tu;
        logic [1-1:0]  dut_error_crc;
        logic [1-1:0]  dut_error_mac;
        logic [1-1:0]  dut_broadcast;
        logic [1-1:0]  dut_multicast;
        logic [1-1:0]  dut_mac_hit_vld;
        logic [4-1:0]  dut_mac_hit;
        logic [1-1:0]  dut_timestamp_vld;
        logic [64-1:0] dut_timestamp;

        logic [16-1:0] model_length;
        logic [8-1:0]  model_port;
        logic [1-1:0]  model_error;
        logic [1-1:0]  model_error_frame;
        logic [1-1:0]  model_error_min_tu;
        logic [1-1:0]  model_error_max_tu;
        logic [1-1:0]  model_error_crc;
        logic [1-1:0]  model_error_mac;
        logic [1-1:0]  model_broadcast;
        logic [1-1:0]  model_multicast;
        logic [1-1:0]  model_mac_hit_vld;
        logic [4-1:0]  model_mac_hit;
        logic [1-1:0]  model_timestamp_vld;
        logic [64-1:0] model_timestamp;

        {dut_timestamp, dut_timestamp_vld, dut_mac_hit, dut_mac_hit_vld, dut_multicast, dut_broadcast, dut_error_mac, dut_error_crc, dut_error_max_tu, dut_error_min_tu, dut_error_frame, dut_error, dut_port, dut_length} = tr_dut.in_item.data;
        {model_timestamp, model_timestamp_vld, model_mac_hit, model_mac_hit_vld, model_multicast, model_broadcast, model_error_mac, model_error_crc, model_error_max_tu, model_error_min_tu, model_error_frame, model_error, model_port, model_length} = tr_model.item.data;

        ret &= dut_length === model_length            ; 
        ret &= dut_port === model_port                ;
        ret &= dut_error === model_error              ;
        ret &= dut_error_frame === model_error_frame  ;
        ret &= dut_error_min_tu === model_error_min_tu;
        ret &= dut_error_max_tu === model_error_max_tu;
        ret &= dut_error_crc === model_error_crc      ;
        ret &= dut_error_mac === model_error_mac      ;
        ret &= dut_broadcast === model_broadcast      ;
        ret &= dut_multicast === model_multicast      ;
        ret &= dut_mac_hit_vld === model_mac_hit_vld ;
        ret &= (model_mac_hit_vld === 1'b0 || dut_mac_hit === model_mac_hit);
        ret &= dut_timestamp_vld === model_timestamp_vld;
        ret &= (model_timestamp_vld === 1'b0 || dut_timestamp === model_timestamp); 

        return ret;
    endfunction

    virtual function string message(uvm_common::model_item#(MODEL_ITEM) tr_model, uvm_common::dut_item #(DUT_ITEM) tr_dut);
        string msg;
        logic [16-1:0] dut_length;
        logic [8-1:0]  dut_port;
        logic [1-1:0]  dut_error;
        logic [1-1:0]  dut_error_frame;
        logic [1-1:0]  dut_error_min_tu;
        logic [1-1:0]  dut_error_max_tu;
        logic [1-1:0]  dut_error_crc;
        logic [1-1:0]  dut_error_mac;
        logic [1-1:0]  dut_broadcast;
        logic [1-1:0]  dut_multicast;
        logic [1-1:0]  dut_mac_hit_vld;
        logic [4-1:0]  dut_mac_hit;
        logic [1-1:0]  dut_timestamp_vld;
        logic [64-1:0] dut_timestamp;

        logic [16-1:0] model_length;
        logic [8-1:0]  model_port;
        logic [1-1:0]  model_error;
        logic [1-1:0]  model_error_frame;
        logic [1-1:0]  model_error_min_tu;
        logic [1-1:0]  model_error_max_tu;
        logic [1-1:0]  model_error_crc;
        logic [1-1:0]  model_error_mac;
        logic [1-1:0]  model_broadcast;
        logic [1-1:0]  model_multicast;
        logic [1-1:0]  model_mac_hit_vld;
        logic [4-1:0]  model_mac_hit;
        logic [1-1:0]  model_timestamp_vld;
        logic [64-1:0] model_timestamp;

        {dut_timestamp, dut_timestamp_vld, dut_mac_hit, dut_mac_hit_vld, dut_multicast, dut_broadcast, dut_error_mac, dut_error_crc, dut_error_max_tu, dut_error_min_tu, dut_error_frame, dut_error, dut_port, dut_length} = tr_dut.in_item.data;
        {model_timestamp, model_timestamp_vld, model_mac_hit, model_mac_hit_vld, model_multicast, model_broadcast, model_error_mac, model_error_crc, model_error_max_tu, model_error_min_tu, model_error_frame, model_error, model_port, model_length} = tr_model.item.data;

        
        msg = "\n\t\t\tCMP [DUT MODEL]"; 
        msg = {msg, $sformatf("\n\tlength %b [%0d %0d]"     , dut_length === model_length            , dut_length, model_length)}; 
        msg = {msg, $sformatf("\n\tport   %b [%0d %0d]"     , dut_port === model_port                , dut_port, model_port)}; 
        msg = {msg, $sformatf("\n\terror  %b [0x%h  0x%h]"      , dut_error === model_error              , dut_error, model_error)}; 
        msg = {msg, $sformatf("\n\terror frame   %b [0x%h 0x%h]", dut_error_frame === model_error_frame  , dut_error_frame, model_error_frame)}; 
        msg = {msg, $sformatf("\n\terror min MTU %b [0x%h 0x%h]", dut_error_min_tu === model_error_min_tu, dut_error_min_tu, model_error_min_tu)}; 
        msg = {msg, $sformatf("\n\terror max MTU %b [0x%h 0x%h]", dut_error_max_tu === model_error_max_tu, dut_error_max_tu, model_error_max_tu)}; 
        msg = {msg, $sformatf("\n\terror CRC     %b [0x%h 0x%h]", dut_error_crc === model_error_crc      , dut_error_crc, model_error_crc)}; 
        msg = {msg, $sformatf("\n\terror MAC     %b [0x%h 0x%h]", dut_error_mac === model_error_mac      , dut_error_mac, model_error_mac)}; 
        msg = {msg, $sformatf("\n\tbroadcast     %b [0x%h 0x%h]", dut_broadcast === model_broadcast      , dut_broadcast, model_broadcast)}; 
        msg = {msg, $sformatf("\n\tmulticast     %b [0x%h 0x%h]", dut_multicast === model_multicast      , dut_multicast, model_multicast)}; 
        msg = {msg, $sformatf("\n\tMAC HIT VLD   %b [0x%h 0x%h]", dut_mac_hit_vld === model_mac_hit_vld  , dut_mac_hit_vld, model_mac_hit_vld)}; 
        msg = {msg, $sformatf("\n\t\tMAC HIT     %b [0x%h 0x%h]", dut_mac_hit === model_mac_hit          , dut_mac_hit, model_mac_hit)}; 
        msg = {msg, $sformatf("\n\ttimestamp VLD %b [0x%h 0x%h]", dut_timestamp_vld === model_timestamp_vld, dut_timestamp_vld, model_timestamp_vld)}; 
        msg = {msg, $sformatf("\n\t\ttimestamp   %b [0x%h 0x%h]", dut_timestamp === model_timestamp      , dut_timestamp, model_timestamp)}; 
        return msg;
    endfunction
endclass

