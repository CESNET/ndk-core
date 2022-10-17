/*
 * file       : pkg.sv
 * Copyright (C) 2021 CESNET z. s. p. o.
 * description: top agent
 * date       : 2021
 * author     : Radek Iša <isa@cesnet.cz>
 *
 * SPDX-License-Identifier: BSD-3-Clause
*/

`ifndef UVM_APP_CORE_PACKET_PKG
`define UVM_APP_CORE_PACKET_PKG

package uvm_app_core_packet;

    `include "uvm_macros.svh"
    import uvm_pkg::*;

    parameter PKT_GEN_PATH = {"`dirname ", `__FILE__, "`/../pkt_gen/pkt_gen.py"};
    `include "sequence.sv"

endpackage

`endif
