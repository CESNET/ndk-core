# Modules.tcl: script to compile single module
# Copyright (C) 2019 CESNET z. s. p. o.
# Author(s): Jakub Cabal <cabal@cesnet.cz>
#
# SPDX-License-Identifier: BSD-3-Clause

# Globally defined variables
global BOARD
global DMA_ENABLE
global ETH_ENABLE

# Paths to components
set ASYNC_RESET_BASE     "$OFM_PATH/comp/base/async/reset"
set ASYNC_OPEN_LOOP_BASE "$OFM_PATH/comp/base/async/open_loop"
set TSU_BASE             "$OFM_PATH/comp/tsu/tsu_gen"
set PCIE_BASE            "$ENTITY_BASE/src/comp/pcie"
set DMA_BUS_BASE         "$ENTITY_BASE/src/comp/dma"
set NETWORK_MOD_BASE     "$ENTITY_BASE/src/comp/network_mod"
set MI_SPLITTER_BASE     "$OFM_PATH/comp/mi_tools/splitter_plus_gen"
set RESET_TREE_GEN_BASE  "$OFM_PATH/comp/base/misc/reset_tree_gen"
set MI_TEST_SPACE_BASE   "$OFM_PATH/comp/mi_tools/test_space"
set ADC_SENSORS_BASE     "$OFM_PATH/comp/base/misc/adc_sensors"
set DMA_GENERATOR_BASE   "$OFM_PATH/comp/mfb_tools/debug/dma_generator"

# Packages
lappend PACKAGES "$OFM_PATH/comp/base/pkg/math_pack.vhd"
lappend PACKAGES "$OFM_PATH/comp/base/pkg/type_pack.vhd"
lappend PACKAGES "$OFM_PATH/comp/base/pkg/dma_bus_pack.vhd"
lappend PACKAGES "$OFM_PATH/comp/base/pkg/eth_hdr_pack.vhd"
lappend PACKAGES "$ENTITY_BASE/config/ndk_const.vhd"
lappend PACKAGES "$ENTITY_BASE/src/mi_addr_space_pkg.vhd"

set DMA_BUS_ARCH "EMPTY"
if {$DMA_ENABLE} {
  set DMA_BUS_ARCH "FULL"
}

set NET_MOD_ARCH "EMPTY"
if {$ETH_ENABLE} {
  set NET_MOD_ARCH $BOARD 
}

set ADC_SENSORS_ARCH "FULL"
if {$BOARD == "400G1" || $BOARD == "DK-DEV-AGI027RES"} {
  set ADC_SENSORS_ARCH "EMPTY"
}

if { $ARCHGRP == "APPLICATION_CORE_ENTYTY_ONLY" } {
  set MOD "$MOD $ENTITY_BASE/src/application_ent.vhd"
} else {
  set COMPONENTS [concat $COMPONENTS [list \
      [list "ASYNC_RESET"     $ASYNC_RESET_BASE     "FULL"           ] \
      [list "ASYNC_OPEN_LOOP" $ASYNC_OPEN_LOOP_BASE "FULL"           ] \
      [list "TSU"             $TSU_BASE             "FULL"           ] \
      [list "RESET_TREE_GEN"  $RESET_TREE_GEN_BASE  "FULL"           ] \
      [list "PCIE"            $PCIE_BASE            $BOARD           ] \
      [list "MI_SPLITTER"     $MI_SPLITTER_BASE     "FULL"           ] \
      [list "MI_TEST_SPACE"   $MI_TEST_SPACE_BASE   "FULL"           ] \
      [list "ADC_SENSORS"     $ADC_SENSORS_BASE     $ADC_SENSORS_ARCH] \
      [list "NETWORK_MOD"     $NETWORK_MOD_BASE     $NET_MOD_ARCH    ] \
      [list "DMA_BUS"         $DMA_BUS_BASE         $DMA_BUS_ARCH    ] \
      [list "DMA_GENERATOR"   $DMA_GENERATOR_BASE   "FULL"           ] \
  ]]

  #set MOD "$MOD $ENTITY_BASE/src/comp/ip/iopll_ip.ip"
  #set MOD "$MOD $ENTITY_BASE/src/comp/ip/reset_release_ip.ip"
  set MOD "$MOD $ENTITY_BASE/src/application_ent.vhd"
  set MOD "$MOD $ENTITY_BASE/src/fpga_common.vhd"

  set MOD "$MOD $ENTITY_BASE/src/DevTree.tcl"
}
