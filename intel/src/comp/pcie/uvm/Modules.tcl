# Modules.tcl: Components include script
# Copyright (C) 2023 CESNET z. s. p. o.
# Author:   Daniel Kříž <xkrizd01@vutbr.cz>
#
# SPDX-License-Identifier: BSD-3-Clause

# Set paths

lappend COMPONENTS [ list "SV_MFB_UVM_BASE"             "$OFM_PATH/comp/uvm/mfb"                      "FULL"]
lappend COMPONENTS [ list "SV_MVB_UVM_BASE"             "$OFM_PATH/comp/uvm/mvb"                      "FULL"]
lappend COMPONENTS [ list "SV_LOGIC_VECTOR_ARRAY"       "$OFM_PATH/comp/uvm/logic_vector_array"       "FULL"]
lappend COMPONENTS [ list "SV_LOGIC_VECTOR"             "$OFM_PATH/comp/uvm/logic_vector"             "FULL"]
lappend COMPONENTS [ list "SV_LOGIC_VECTOR_ARRAY_MFB"   "$OFM_PATH/comp/uvm/logic_vector_array_mfb"   "FULL"]
lappend COMPONENTS [ list "SV_LOGIC_VECTOR_MVB"         "$OFM_PATH/comp/uvm/logic_vector_mvb"         "FULL"]
lappend COMPONENTS [ list "SV_MI"                       "$OFM_PATH/comp/uvm/mi"                       "FULL"]
lappend COMPONENTS [ list "SV_LOGIC_VECTOR_ARRAY_AVST"  "$OFM_PATH/comp/uvm/logic_vector_array_avst"  "FULL"]
lappend COMPONENTS [ list "SV_LOGIC_VECTOR_ARRAY_AXI"   "$OFM_PATH/comp/uvm/logic_vector_array_axi"   "FULL"]

lappend MOD "$OFM_PATH/comp/base/pkg/dma_bus_pack.sv"
lappend MOD "$OFM_PATH/comp/pcie/ptc/uvm/tbench/info/pkg.sv"
lappend MOD "$OFM_PATH/comp/pcie/ptc/uvm/tbench/info_rc/pkg.sv"
lappend MOD "$OFM_PATH/comp/pcie/ptc/uvm/tbench/pcie_rc/pkg.sv"
lappend MOD "$OFM_PATH/comp/base/pkg/pcie_meta_pack.sv"
lappend MOD "$ENTITY_BASE/tbench/down_agent/pkg.sv"

lappend MOD "$OFM_PATH/comp/pcie/mtc/uvm/tbench/info/pkg.sv"
lappend MOD "$OFM_PATH/comp/pcie/mtc/uvm/tbench/rx_env/pkg.sv"
lappend MOD "$OFM_PATH/comp/pcie/mtc/uvm/tbench/env/pkg.sv"

lappend MOD "$ENTITY_BASE/tbench/env/pkg.sv"
lappend MOD "$ENTITY_BASE/tbench/tests/pkg.sv"

lappend MOD "$ENTITY_BASE/tbench/dut.sv"
lappend MOD "$ENTITY_BASE/tbench/testbench.sv"
