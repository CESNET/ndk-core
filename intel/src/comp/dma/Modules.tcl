# Modules.tcl: Components include script
# Copyright (C) 2019 CESNET z. s. p. o.
# Author(s): Jakub Cabal <cabal@cesnet.cz>
#
# SPDX-License-Identifier: BSD-3-Clause

# Paths to components
set ASYNC_RESET_BASE          "$OFM_PATH/comp/base/async/reset"
set MI_SPLITTER_PLUS_BASE     "$OFM_PATH/comp/mi_tools/splitter_plus"
set MI32_ASYNC_HANDSHAKE_BASE "$OFM_PATH/comp/mi_tools/async"
set DMA_MEDUSA_BASE           "$ENTITY_BASE/../../../../../modules/ndk-mod-dma-medusa"
set GEN_LOOP_SWITCH_BASE      "$OFM_PATH/comp/mfb_tools/debug/gen_loop_switch"

# Packages
set PACKAGES "$PACKAGES $OFM_PATH/comp/base/pkg/math_pack.vhd"
set PACKAGES "$PACKAGES $OFM_PATH/comp/base/pkg/type_pack.vhd"
set PACKAGES "$PACKAGES $OFM_PATH/comp/base/pkg/dma_bus_pack.vhd"

set MOD "$MOD $ENTITY_BASE/dma_ent.vhd"

if {$ARCHGRP == "FULL"} {
    set COMPONENTS [ list \
        [ list "ASYNC_RESET"          $ASYNC_RESET_BASE               "FULL" ] \
        [ list "MI_SPLITTER_PLUS"     $MI_SPLITTER_PLUS_BASE          "FULL" ] \
        [ list "MI32_ASYNC_HANDSHAKE" $MI32_ASYNC_HANDSHAKE_BASE      "FULL" ] \
        [ list "DMA_MEDUSA"           $DMA_MEDUSA_BASE                "FULL" ] \
        [ list "GEN_LOOP_SWITCH"      $GEN_LOOP_SWITCH_BASE           "FULL" ] \
    ]

    # Source files for implemented component
    set MOD "$MOD $ENTITY_BASE/dma.vhd"
    set MOD "$MOD $ENTITY_BASE/DevTree.tcl"
} else {
    set COMPONENTS [ list \
        [ list "ASYNC_RESET"          $ASYNC_RESET_BASE               "FULL" ] \
        [ list "MI_SPLITTER_PLUS"     $MI_SPLITTER_PLUS_BASE          "FULL" ] \
        [ list "MI32_ASYNC_HANDSHAKE" $MI32_ASYNC_HANDSHAKE_BASE      "FULL" ] \
        [ list "GEN_LOOP_SWITCH"      $GEN_LOOP_SWITCH_BASE           "FULL" ] \
    ]

    set MOD "$MOD $ENTITY_BASE/dma_empty.vhd"
}