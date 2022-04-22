# Modules.tcl: Components include script
# Copyright (C) 2021 CESNET z. s. p. o.
# Author(s): Daniel Kondys <xkondy00@vutbr.cz>
#
# SPDX-License-Identifier: BSD-3-Clause

# Set paths

# Paths to components
set ASYNC_RESET_BASE          "$OFM_PATH/comp/base/async/reset"
set MI_SPLITTER_BASE          "$OFM_PATH/comp/mi_tools/splitter_plus_gen"
set NETWORK_MOD_COMP_BASE     "$ENTITY_BASE/comp"
set NETWORK_MOD_CORE_BASE     "$NETWORK_MOD_COMP_BASE/network_mod_core"
set NETWORK_MOD_LOG_BASE      "$NETWORK_MOD_COMP_BASE/network_mod_logic"
set I2C_BASE                  "$OFM_PATH/comp/ctrls/i2c_hw"
set ASFIFOX_BASE              "$OFM_PATH/comp/base/fifo/asfifox"

# uncomment only for local synthesis
# options: 400G1, DK-DEV-AGI027RES, DK-DEV-1SDX-P
# set ARCHGRP  "DK-DEV-AGI027RES"

# Packages
set PACKAGES "$PACKAGES $OFM_PATH/comp/base/pkg/math_pack.vhd"
set PACKAGES "$PACKAGES $OFM_PATH/comp/base/pkg/type_pack.vhd"
set PACKAGES "$PACKAGES $OFM_PATH/comp/base/pkg/eth_hdr_pack.vhd"

set MOD "$MOD $ENTITY_BASE/network_mod_ent.vhd"

if { $ARCHGRP == "400G1" || $ARCHGRP == "DK-DEV-1SDX-P" || $ARCHGRP == "DK-DEV-AGI027RES" } {

    set COMPONENTS [concat $COMPONENTS [list \
        [ list "ASYNC_RESET"          $ASYNC_RESET_BASE          "FULL"   ] \
        [ list "MI_SPLITTER_PLUS_GEN" $MI_SPLITTER_BASE          "FULL"   ] \
        [ list "NETWORK_MOD_CORE"     $NETWORK_MOD_CORE_BASE     $ARCHGRP ] \
        [ list "NETWORK_MOD_LOGIC"    $NETWORK_MOD_LOG_BASE      "FULL"   ] \
        [ list "I2C_CTRL"             $I2C_BASE                  "FULL"   ] \
        [ list "ASFIFOX"              $ASFIFOX_BASE              "FULL"   ] \
    ]]

    # Source files for implemented component
    set MOD "$MOD $ENTITY_BASE/network_mod.vhd"
    set MOD "$MOD $ENTITY_BASE/qsfp_ctrl.vhd"
    set MOD "$MOD $ENTITY_BASE/DevTree.tcl"

} else {

    set MOD "$MOD $ENTITY_BASE/network_mod_empty.vhd"

}
