//-- pkg.sv: Package for environment
//-- Copyright (C) 2022 CESNET z. s. p. o.
//-- Author:   Daniel Kříž <xkrizd01@vutbr.cz>

//-- SPDX-License-Identifier: BSD-3-Clause

`ifndef PCIE_ENV_SV
`define PCIE_ENV_SV

package uvm_pcie;
    
    `include "uvm_macros.svh"
    import uvm_pkg::*;

    `include "sequencer.sv"
    `include "sequence_tb.sv"
    `include "monitor.sv"
    `include "rc_monitor.sv"
    `include "tr_planner.sv"
    `include "sequence_mi.sv"
    `include "sequence.sv"
    `include "data.sv"
    `include "down_splitter.sv"
    `include "input_fifo.sv"
    `include "model_base.sv"
    `include "model_xilinx.sv"
    `include "model_intel.sv"
    `include "scoreboard_cmp.sv"
    `include "scoreboard.sv"
    `include "env.sv"

endpackage

`endif
