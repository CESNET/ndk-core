//-- pkg.sv: test packages
//-- Copyright (C) 2023 CESNET z. s. p. o.
//-- Author(s): Radek Iša <isa@cesnet.cz>

//-- SPDX-License-Identifier: BSD-3-Clause

`ifndef NETWORK_MOD_TEST_SV
`define NETWORK_MOD_TEST_SV

package test;

    `include "uvm_macros.svh"
    import uvm_pkg::*;

    `include "base.sv"

endpackage
`endif

