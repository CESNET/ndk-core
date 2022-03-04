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
set PACKAGES "$PACKAGES $OFM_PATH/comp/base/pkg/math_pack.vhd"
set PACKAGES "$PACKAGES $OFM_PATH/comp/base/pkg/type_pack.vhd"
set PACKAGES "$PACKAGES $OFM_PATH/comp/base/pkg/dma_bus_pack.vhd"

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

set MOD "$MOD $ENTITY_BASE/pcie_core_ent.vhd"

# Source files for implemented component
if {$ARCHGRP == "DK-DEV-1SDX-P"} {
    #set MOD "$MOD $ENTITY_BASE/ip/pcie_ptile_ip.ip"
    #set MOD "$MOD $ENTITY_BASE/ip/pciex8_ptile_ip.ip"
    set MOD "$MOD $ENTITY_BASE/pcie_cii2cfg_ext.vhd"
    set MOD "$MOD $ENTITY_BASE/pcie_core_ptile.vhd"
} elseif {$ARCHGRP == "400G1" || $ARCHGRP == "DK-DEV-AGI027RES"} {
    #set MOD "$MOD $ENTITY_BASE/ip/agib027_rtile_pcie_2x8.ip"
    set MOD "$MOD $ENTITY_BASE/pcie_cii2cfg_ext.vhd"
    set MOD "$MOD $ENTITY_BASE/pcie_crdt_up_fsm.vhd"
    set MOD "$MOD $ENTITY_BASE/pcie_crdt_dw_fsm.vhd"
    set MOD "$MOD $ENTITY_BASE/pcie_crdt_logic.vhd"
    set MOD "$MOD $ENTITY_BASE/pcie_core_rtile.vhd"
} else {
    set MOD "$MOD $ENTITY_BASE/pcie_core_empty.vhd"
}

set MOD "$MOD $ENTITY_BASE/pcie_ctrl.vhd"
set MOD "$MOD $ENTITY_BASE/pcie_top.vhd"
