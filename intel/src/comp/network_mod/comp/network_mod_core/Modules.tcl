# Modules.tcl: Components include script
# Copyright (C) 2021 CESNET z. s. p. o.
# Author(s): Daniel Kondys <xkondy00@vutbr.cz>
#
# SPDX-License-Identifier: BSD-3-Clause

# Set paths

# Paths to components
set RX_ADAPTER_BASE     "$OFM_PATH/comp/nic/mac_lite/rx_mac_lite/comp/adapters/"
set TX_ADAPTER_BASE     "$OFM_PATH/comp/nic/mac_lite/tx_mac_lite/comp/adapters/"
set MI_TOOLS_BASE       "$OFM_PATH/comp/mi_tools/"

# Packages
set PACKAGES "$PACKAGES $OFM_PATH/comp/base/pkg/math_pack.vhd"
set PACKAGES "$PACKAGES $OFM_PATH/comp/base/pkg/type_pack.vhd"
set PACKAGES "$PACKAGES $OFM_PATH/comp/base/pkg/eth_hdr_pack.vhd"

set MOD "$MOD $ENTITY_BASE/network_mod_core_ent.vhd"

if { $ARCHGRP == "400G1" || $ARCHGRP == "DK-DEV-AGI027RES" } {

    set COMPONENTS [concat $COMPONENTS [list \
        [ list "TX_FTILE_ADAPTER"    "$TX_ADAPTER_BASE/mac_seg"  "FULL" ] \
        [ list "RX_FTILE_ADAPTER"    "$RX_ADAPTER_BASE/mac_seg"  "FULL" ] \
    ]]

    # Source files for implemented component
    # now in fpga top-level
    #set MOD "$MOD $ENTITY_BASE/ip/agib027_ftile_pll_1x400g.ip"
    #set MOD "$MOD $ENTITY_BASE/ip/agib027_ftile_eth_1x400g.ip"
    #set MOD "$MOD $ENTITY_BASE/ip/agib027_ftile_pll_2x200g.ip"
    #set MOD "$MOD $ENTITY_BASE/ip/agib027_ftile_eth_2x200g.ip"
    #set MOD "$MOD $ENTITY_BASE/ip/agib027_ftile_pll_4x100g.ip"
    #set MOD "$MOD $ENTITY_BASE/ip/agib027_ftile_eth_4x100g.ip"
    #set MOD "$MOD $ENTITY_BASE/ip/agib027_ftile_pll_8x50g.ip"
    #set MOD "$MOD $ENTITY_BASE/ip/agib027_ftile_eth_8x50g.ip"
    #set MOD "$MOD $ENTITY_BASE/ip/agib027_ftile_pll_2x40g.ip"
    #set MOD "$MOD $ENTITY_BASE/ip/agib027_ftile_eth_2x40g.ip"
    #set MOD "$MOD $ENTITY_BASE/ip/agib027_ftile_pll_8x25g.ip"
    #set MOD "$MOD $ENTITY_BASE/ip/agib027_ftile_eth_8x25g.ip"
    #set MOD "$MOD $ENTITY_BASE/ip/agib027_ftile_pll_8x10g.ip"
    #set MOD "$MOD $ENTITY_BASE/ip/agib027_ftile_eth_8x10g.ip"

    set MOD "$MOD $ENTITY_BASE/network_mod_core_ftile.vhd"
    #set MOD "$MOD $ENTITY_BASE/qsfp_ctrl.vhd"
    #set MOD "$MOD $ENTITY_BASE/DevTree.tcl"

# $ARCHGRP == "DK-DEV-1SDX-P"
} else {

    set COMPONENTS [concat $COMPONENTS [list \
        [ list "TX_ETILE_ADAPTER"    "$TX_ADAPTER_BASE/avst_100g"    "FULL" ] \
        [ list "RX_ETILE_ADAPTER"    "$RX_ADAPTER_BASE/eth_avst"     "FULL" ] \
    ]]

    #set MOD "$MOD $ENTITY_BASE/ip/s10dx280_etile_eth_1x100g.ip"
    #set MOD "$MOD $ENTITY_BASE/ip/s10dx280_etile_eth_4x25g.ip"
    #set MOD "$MOD $ENTITY_BASE/ip/s10dx280_etile_eth_4x10g.ip"

    set MOD "$MOD $ENTITY_BASE/network_mod_core_etile.vhd"

}

set COMPONENTS [concat $COMPONENTS [list \
        [ list "MI_INDIRECT_ACCESS"    "$MI_TOOLS_BASE/indirect_access"  "FULL" ] \
    ]]
