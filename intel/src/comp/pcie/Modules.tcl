# Modules.tcl: Components include script
# Copyright (C) 2019 CESNET z. s. p. o.
# Author(s): Jakub Cabal <cabal@cesnet.cz>
#
# SPDX-License-Identifier: BSD-3-Clause

# Set paths

# Paths to components
set ASYNC_RESET_BASE          "$OFM_PATH/comp/base/async/reset"
set MTC_BASE                  "$OFM_PATH/comp/pcie/mtc"
set PTC_BASE                  "$OFM_PATH/comp/pcie/ptc"
set PCI_EXT_CAP_BASE          "$OFM_PATH/comp/pcie/common"
set PCIE_CONN_BLOCK_BASE      "$OFM_PATH/comp/pcie/others/connection_block"
set MI32_ASYNC_HANDSHAKE_BASE "$OFM_PATH/comp/mi_tools/async"
set MFB_ASFIFOX_BASE          "$OFM_PATH/comp/mfb_tools/storage/asfifox"
set ASYNC_HANDSHAKE_BASE      "$OFM_PATH/comp/base/async/bus_handshake"

# Packages
lappend PACKAGES "$OFM_PATH/comp/base/pkg/math_pack.vhd"
lappend PACKAGES "$OFM_PATH/comp/base/pkg/type_pack.vhd"
lappend PACKAGES "$OFM_PATH/comp/base/pkg/dma_bus_pack.vhd"

# Components
set COMPONENTS [concat $COMPONENTS [list \
    [ list "ASYNC_RESET"          $ASYNC_RESET_BASE          "FULL" ] \
    [ list "MTC"                  $MTC_BASE                  "FULL" ] \
    [ list "PTC"                  $PTC_BASE                  "FULL" ] \
    [ list "PCI_EXT_CAP"          $PCI_EXT_CAP_BASE          "FULL" ] \
    [ list "PCIE_CONN_BLOCK"      $PCIE_CONN_BLOCK_BASE      "FULL" ] \
    [ list "MI32_ASYNC_HANDSHAKE" $MI32_ASYNC_HANDSHAKE_BASE "FULL" ] \
    [ list "MFB_ASFIFOX"          $MFB_ASFIFOX_BASE          "FULL" ] \
    [ list "ASYNC_HANDSHAKE"      $ASYNC_HANDSHAKE_BASE      "FULL" ] \
]]

lappend MOD "$ENTITY_BASE/pcie_core_ent.vhd"

# Source files for implemented component
if {$ARCHGRP == "P_TILE"} {
    lappend MOD "$ENTITY_BASE/pcie_cii2cfg_ext.vhd"
    lappend MOD "$ENTITY_BASE/pcie_core_ptile.vhd"
} elseif {$ARCHGRP == "R_TILE"} {
    lappend MOD "$ENTITY_BASE/pcie_cii2cfg_ext.vhd"
    lappend MOD "$ENTITY_BASE/pcie_crdt_up_fsm.vhd"
    lappend MOD "$ENTITY_BASE/pcie_crdt_dw_fsm.vhd"
    lappend MOD "$ENTITY_BASE/pcie_crdt_logic.vhd"
    lappend MOD "$ENTITY_BASE/pcie_core_rtile.vhd"
} elseif {$ARCHGRP == "USP"} {
    lappend MOD "$ENTITY_BASE/pcie_core_usp.vhd"
} else {
    lappend MOD "$ENTITY_BASE/pcie_core_empty.vhd"
}

lappend MOD "$ENTITY_BASE/pcie_ctrl.vhd"
lappend MOD "$ENTITY_BASE/pcie_top.vhd"
