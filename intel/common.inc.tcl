# Quartus.inc.tcl: Quartus.tcl include for Intel FPGA cards
# Copyright (C) 2022 CESNET z. s. p. o.
# Author(s): Jakub Cabal <cabal@cesnet.cz>
#           Vladislav Valek <valekv@cesnet.cz>
#
# SPDX-License-Identifier: BSD-3-Clause

set SYNTH_FLAGS(OUTPUT) $OUTPUT_NAME

set CORE_ARCHGRP(CLOCK_GEN_ARCH)    $CLOCK_GEN_ARCH
set CORE_ARCHGRP(PCIE_MOD_ARCH)     $PCIE_MOD_ARCH
set CORE_ARCHGRP(NET_MOD_ARCH)      $NET_MOD_ARCH
set CORE_ARCHGRP(SDM_SYSMON_ARCH)   $SDM_SYSMON_ARCH
set CORE_ARCHGRP(DMA_TYPE)          $DMA_TYPE

# Prerequisites for generated USER_CONST package
set UCP_PREREQ [list $NDK_CONST $DEFAULT_CONST [expr {[info exists USER_CONST] ? $USER_CONST : ""}]]
# Let generate package from USER_CONST and add it to project
lappend HIERARCHY(PACKAGES) [nb_generate_file_register_userpkg "combo_user_const" "" $UCP_PREREQ]

# Let generate DevTree.vhd and add it to project
lappend HIERARCHY(PACKAGES) [nb_generate_file_register_devtree]

# ----- Default target: synthesis of the project ------------------------------
proc target_default {} {
    global SYNTH_FLAGS HIERARCHY
    SynthesizeProject SYNTH_FLAGS HIERARCHY
}
