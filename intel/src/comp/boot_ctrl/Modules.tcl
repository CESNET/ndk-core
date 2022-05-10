# Modules.tcl: Components include script
# Copyright (C) 2022 CESNET z. s. p. o.
# Author(s): Jakub Cabal <cabal@cesnet.cz>
#
# SPDX-License-Identifier: BSD-3-Clause

# Paths
set MI_ASYNC_BASE "$OFM_PATH/comp/mi_tools/async"

# Packages
lappend PACKAGES "$OFM_PATH/comp/base/pkg/math_pack.vhd"

# Components
lappend COMPONENTS [ list "MI_ASYNC" $MI_ASYNC_BASE "FULL" ]

# Files
lappend MOD "$ENTITY_BASE/boot_ctrl.vhd"
lappend MOD "$ENTITY_BASE/DevTree.tcl"
