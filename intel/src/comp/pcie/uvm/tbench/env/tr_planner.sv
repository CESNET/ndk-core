//-- tr_planner.sv: Transaction planner
//-- Copyright (C) 2022 CESNET z. s. p. o.
//-- Author(s): Daniel Kříž <xkrizd01@vutbr.cz>

//-- SPDX-License-Identifier: BSD-3-Clause

class tr_planner #(META_WIDTH) extends uvm_component;
    `uvm_component_param_utils(uvm_pcie::tr_planner #(META_WIDTH))

    uvm_analysis_imp#(uvm_logic_vector::sequence_item #(META_WIDTH), tr_planner #(META_WIDTH)) analysis_imp;
    uvm_logic_vector::sequence_item #(META_WIDTH) mi_array[$];

    function new(string name, uvm_component parent);
        super.new(name, parent);
        analysis_imp = new("analysis_imp", this);
    endfunction

    virtual function void write(uvm_logic_vector::sequence_item #(META_WIDTH) req);
        mi_array.push_back(req);
    endfunction
endclass