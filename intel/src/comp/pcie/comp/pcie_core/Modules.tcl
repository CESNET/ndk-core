# Modules.tcl: Components include script
# Copyright (C) 2022 CESNET z. s. p. o.
# Author(s): Jakub Cabal <cabal@cesnet.cz>
#
# SPDX-License-Identifier: BSD-3-Clause

# Paths to components
set ASYNC_RESET_BASE "$OFM_PATH/comp/base/async/reset"
set PCI_EXT_CAP_BASE "$OFM_PATH/comp/pcie/common"
set PCIE_COMP_BASE   "$ENTITY_BASE/../"

# Packages
lappend PACKAGES "$OFM_PATH/comp/base/pkg/math_pack.vhd"
lappend PACKAGES "$OFM_PATH/comp/base/pkg/type_pack.vhd"
lappend PACKAGES "$OFM_PATH/comp/base/pkg/pcie_meta_pack.vhd"

# Components
lappend COMPONENTS [ list "ASYNC_RESET" $ASYNC_RESET_BASE               "FULL" ]
lappend COMPONENTS [ list "PCI_EXT_CAP" $PCI_EXT_CAP_BASE               "FULL" ]
lappend COMPONENTS [ list "PCIE_ADAPTER" "$PCIE_COMP_BASE/pcie_adapter" "FULL" ]

lappend MOD "$ENTITY_BASE/pcie_core_ent.vhd"

# Source files for implemented component
if {$ARCHGRP == "P_TILE"} {
    lappend COMPONENTS [ list "PCIE_CII2CFG" "$PCIE_COMP_BASE/pcie_cii2cfg" "FULL" ]
    lappend MOD "$ENTITY_BASE/pcie_core_ptile.vhd"
} elseif {$ARCHGRP == "R_TILE"} {
    lappend COMPONENTS [ list "PCIE_CII2CFG" "$PCIE_COMP_BASE/pcie_cii2cfg" "FULL" ]
    lappend COMPONENTS [ list "PCIE_CRDT"    "$PCIE_COMP_BASE/pcie_crdt"    "FULL" ]
    lappend MOD "$ENTITY_BASE/pcie_core_rtile.vhd"
} elseif {$ARCHGRP == "USP"} {
    lappend MOD "$ENTITY_BASE/pcie_core_usp.vhd"
} else {
    lappend MOD "$ENTITY_BASE/pcie_core_empty.vhd"
}
