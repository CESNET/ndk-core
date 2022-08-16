/*
 * file       : pkg.sv
 * Copyright (C) 2021 CESNET z. s. p. o.
 * description: top agent 
 * date       : 2021
 * author     : Radek Iša <isa@cesnet.cz>
 *
 * SPDX-License-Identifier: BSD-3-Clause
*/

`ifndef APP_CORE_TOP_AGENT_PKG
`define APP_CORE_TOP_AGENT_PKG

package uvm_app_core_top_agent;

    `include "uvm_macros.svh"
    import uvm_pkg::*;

    `include "driver.sv"
    `include "sequence.sv"
    `include "agent.sv"

endpackage

`endif
