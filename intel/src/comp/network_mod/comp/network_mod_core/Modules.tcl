# Modules.tcl: Components include script
# Copyright (C) 2021 CESNET z. s. p. o.
# Author(s): Daniel Kondys <xkondy00@vutbr.cz>
#
# SPDX-License-Identifier: BSD-3-Clause

# Paths to components
set ASYNC_BASE          "$OFM_PATH/comp/base/async/"
set MGMT_BASE           "$OFM_PATH/comp/nic/eth_phy/comp/mgmt"
set RX_ADAPTER_BASE     "$OFM_PATH/comp/nic/mac_lite/rx_mac_lite/comp/adapters"
set TX_ADAPTER_BASE     "$OFM_PATH/comp/nic/mac_lite/tx_mac_lite/comp/adapters"
set MI_TOOLS_BASE       "$OFM_PATH/comp/mi_tools"
set CARDS_BASE          "$OFM_PATH/../cards"
set DK_1SDX_IP_BASE     "$CARDS_BASE/dk-dev-1sdx-p/src/ip"
set DK_AGI_IP_BASE      "$CARDS_BASE/dk-dev-agi027res/src/ip"
set AGI_FH400G_IP_BASE  "$CARDS_BASE/agi-fh400g/src/ip"
set CMAC_IP_BASE        "$CARDS_BASE/fb4cgg3/src/ip"

# Packages
lappend PACKAGES "$OFM_PATH/comp/base/pkg/math_pack.vhd"
lappend PACKAGES "$OFM_PATH/comp/base/pkg/type_pack.vhd"
lappend PACKAGES "$OFM_PATH/comp/base/pkg/eth_hdr_pack.vhd"

# For local synthesis only !
#set ARCHGRP FB4CGG3

lappend COMPONENTS [list "MI_INDIRECT_ACCESS"   "$MI_TOOLS_BASE/indirect_access"   "FULL"]
lappend COMPONENTS [list "MI_SPLITTER_PLUS_GEN" "$MI_TOOLS_BASE/splitter_plus_gen" "FULL"]
lappend COMPONENTS [list "MGMT"                  $MGMT_BASE                        "FULL"]

lappend MOD "$ENTITY_BASE/network_mod_core_ent.vhd"

if { $ARCHGRP == "400G1" || $ARCHGRP == "DK-DEV-AGI027RES"} {
    lappend COMPONENTS [list "TX_FTILE_ADAPTER" "$TX_ADAPTER_BASE/mac_seg" "FULL"]
    lappend COMPONENTS [list "RX_FTILE_ADAPTER" "$RX_ADAPTER_BASE/mac_seg" "FULL"]

    # IP are now in card (400G1) top-level Modules.tcl
    # Uncomment for network module synthesis only!
    #lappend MOD "$AGI_FH400G_IP_BASE/ftile_pll_1x400g.ip"
    #lappend MOD "$AGI_FH400G_IP_BASE/ftile_eth_1x400g.ip"
    #lappend MOD "$AGI_FH400G_IP_BASE/ftile_pll_2x200g.ip"
    #lappend MOD "$AGI_FH400G_IP_BASE/ftile_eth_2x200g.ip"
    #lappend MOD "$AGI_FH400G_IP_BASE/ftile_pll_4x100g.ip"
    #lappend MOD "$AGI_FH400G_IP_BASE/ftile_eth_4x100g.ip"
    #lappend MOD "$AGI_FH400G_IP_BASE/ftile_pll_8x50g.ip"
    #lappend MOD "$AGI_FH400G_IP_BASE/ftile_eth_8x50g.ip"
    #lappend MOD "$AGI_FH400G_IP_BASE/ftile_pll_2x40g.ip"
    #lappend MOD "$AGI_FH400G_IP_BASE/ftile_eth_2x40g.ip"
    #lappend MOD "$AGI_FH400G_IP_BASE/ftile_pll_8x25g.ip"
    #lappend MOD "$AGI_FH400G_IP_BASE/ftile_eth_8x25g.ip"
    #lappend MOD "$AGI_FH400G_IP_BASE/ftile_pll_8x10g.ip"
    #lappend MOD "$AGI_FH400G_IP_BASE/ftile_eth_8x10g.ip"

    # IP are now in card (DK-DEV-AGI027RES) top-level Modules.tcl
    # Uncomment for network module synthesis only!
    #lappend MOD "$DK_AGI_IP_BASE/ftile_pll_1x400g.ip"
    #lappend MOD "$DK_AGI_IP_BASE/ftile_eth_1x400g.ip"
    #lappend MOD "$DK_AGI_IP_BASE/ftile_pll_2x200g.ip"
    #lappend MOD "$DK_AGI_IP_BASE/ftile_eth_2x200g.ip"
    #lappend MOD "$DK_AGI_IP_BASE/ftile_pll_4x100g.ip"
    #lappend MOD "$DK_AGI_IP_BASE/ftile_eth_4x100g.ip"
    #lappend MOD "$DK_AGI_IP_BASE/ftile_pll_8x50g.ip"
    #lappend MOD "$DK_AGI_IP_BASE/ftile_eth_8x50g.ip"
    #lappend MOD "$DK_AGI_IP_BASE/ftile_pll_2x40g.ip"
    #lappend MOD "$DK_AGI_IP_BASE/ftile_eth_2x40g.ip"
    #lappend MOD "$DK_AGI_IP_BASE/ftile_pll_8x25g.ip"
    #lappend MOD "$DK_AGI_IP_BASE/ftile_eth_8x25g.ip"
    #lappend MOD "$DK_AGI_IP_BASE/ftile_pll_8x10g.ip"
    #lappend MOD "$DK_AGI_IP_BASE/ftile_eth_8x10g.ip"

    # Source files for implemented component
    lappend MOD "$ENTITY_BASE/network_mod_core_ftile.vhd"
}

if { $ARCHGRP == "DK-DEV-1SDX-P"} {
    lappend COMPONENTS [list "TX_ETILE_ADAPTER" "$TX_ADAPTER_BASE/avst_100g" "FULL"]
    lappend COMPONENTS [list "RX_ETILE_ADAPTER" "$RX_ADAPTER_BASE/eth_avst"  "FULL"]

    # IP are now in card top-level Modules.tcl
    # Uncomment for network module synthesis only!
    #lappend MOD "$DK_1SDX_IP_BASE/etile_eth_1x100g.ip"
    #lappend MOD "$DK_1SDX_IP_BASE/etile_eth_4x25g.ip"
    #lappend MOD "$DK_1SDX_IP_BASE/etile_eth_4x10g.ip"

    # Source files for implemented component
    lappend MOD "$ENTITY_BASE/network_mod_core_etile.vhd"
}
 
if { $ARCHGRP == "FB4CGG3" || $ARCHGRP == "FB2CGG3" || $ARCHGRP == "FB2CGHH"} {
    lappend COMPONENTS [list "ASYNC_RESET"     "$ASYNC_BASE/reset"     "FULL"]
    lappend COMPONENTS [list "ASYNC_OPEN_LOOP" "$ASYNC_BASE/open_loop" "FULL"]
    lappend COMPONENTS [list "TX_LBUS_ADAPTER" "$TX_ADAPTER_BASE/lbus" "FULL"]
    lappend COMPONENTS [list "RX_LBUS_ADAPTER" "$RX_ADAPTER_BASE/lbus" "FULL"]

    # IP are now in card top-level Modules.tcl
    # Uncomment for network module synthesis only!
    #lappend MOD "$CMAC_IP_BASE/cmac_eth_1x100g/cmac_eth_1x100g.xci"

    # Source files for implemented component
    lappend MOD "$ENTITY_BASE/network_mod_core_cmac.vhd"
}
