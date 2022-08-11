# Modules.tcl: Components include script
# Copyright (C) 2022 CESNET z. s. p. o.
# Author(s): Tomas Hak <xhakto01@stud.fit.vutbr.cz>
#
# SPDX-License-Identifier: BSD-3-Clause

# Paths
set MI2AVMM_BASE "$OFM_PATH/comp/mi_tools/converters/mi2avmm"

# Files
lappend MOD "$ENTITY_BASE/sdm_ctrl_ent.vhd"

# Components
lappend COMPONENTS [ list "MI2AVMM" $MI2AVMM_BASE "FULL" ]

# Source files for implemented component
lappend MOD "$ENTITY_BASE/sdm_ctrl_arch.vhd"
lappend MOD "$ENTITY_BASE/DevTree.tcl"
