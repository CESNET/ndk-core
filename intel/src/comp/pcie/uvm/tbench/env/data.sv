//-- data.sv: Model of implementation
//-- Copyright (C) 2023 CESNET z. s. p. o.
//-- Author(s): Radek Iša  <isa@cesnet.cz>

//-- SPDX-License-Identifier: BSD-3-Clause 

class dma_header_rq #(ITEM_WIDTH) extends uvm_object;
    `uvm_object_param_utils(uvm_pcie::dma_header_rq #(ITEM_WIDTH))

    uvm_ptc_info::sequence_item hdr;
    uvm_common::model_item #(uvm_logic_vector_array::sequence_item #(ITEM_WIDTH)) data;

    function new(string name = "");
        super.new(name);
    endfunction
endclass


class down_tr #(ITEM_WIDTH, META_WIDTH) extends uvm_object;
    `uvm_object_param_utils(uvm_pcie::down_tr #(ITEM_WIDTH, META_WIDTH))

    uvm_common::model_item #(uvm_logic_vector::sequence_item #(META_WIDTH))       meta;
    uvm_common::model_item #(uvm_logic_vector_array::sequence_item #(ITEM_WIDTH)) data;

    function new(string name = "");
        super.new(name);
    endfunction
endclass

class dma_header_rc #(ITEM_WIDTH) extends uvm_object;
    `uvm_object_utils(uvm_pcie::dma_header_rc #(ITEM_WIDTH))

    int unsigned port; 
    int unsigned length;
    int unsigned completed;
    int unsigned tag;
    int unsigned unit_id;

    uvm_common::model_item #(uvm_logic_vector_array::sequence_item #(ITEM_WIDTH)) data;

    function new(string name = "");
        super.new(name);
    endfunction
endclass

