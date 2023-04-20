# Modules.tcl: script to compile single module
# Copyright (C) 2023 CESNET z. s. p. o.
# Author(s): Jakub Cabal <cabal@cesnet.cz>
#
# SPDX-License-Identifier: BSD-3-Clause

# Component paths
set MFB_MERGER_BASE   "$OFM_PATH/comp/mfb_tools/flow/merger"
set MFB_SPLITTER_BASE "$OFM_PATH/comp/mfb_tools/flow/splitter"
set MFB_FIFO_BASE     "$OFM_PATH/comp/mfb_tools/storage/fifox"

# Packages
lappend PACKAGES "$OFM_PATH/comp/base/pkg/math_pack.vhd"
lappend PACKAGES "$OFM_PATH/comp/base/pkg/type_pack.vhd"

# Components
lappend COMPONENTS [ list "MFB_MERGER"   $MFB_MERGER_BASE   "FULL" ]
lappend COMPONENTS [ list "MFB_SPLITTER" $MFB_SPLITTER_BASE "FULL" ]
lappend COMPONENTS [ list "MFB_FIFO"     $MFB_FIFO_BASE     "FULL" ]

# Files
lappend MOD "$ENTITY_BASE/app_biflow_port.vhd"
lappend MOD "$ENTITY_BASE/app_biflow_simple.vhd"
lappend MOD "$ENTITY_BASE/app_biflow_simple_top.vhd"
