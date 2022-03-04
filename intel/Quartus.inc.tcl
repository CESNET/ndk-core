# Quartus.inc.tcl: Quartus.tcl include for Intel FPGA cards
# Copyright (C) 2019 CESNET z. s. p. o.
# Author(s): Jakub Cabal <cabal@cesnet.cz>
#
# SPDX-License-Identifier: BSD-3-Clause

# Including synthesis procedures
source $OFM_PATH/build/Quartus.inc.tcl

set SYNTH_FLAGS(OUTPUT) $OUTPUT_NAME

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
