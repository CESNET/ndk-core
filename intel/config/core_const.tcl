# core_const.tcl: Generates constants to the VHDL package and fills them with
# values specified by TCL variables
# Copyright (C) 2022 CESNET, z. s. p. o.
# Author(s): Jakub Cabal <cabal@cesnet.cz>
#            Vladislav Valek <valekv@cesnet.cz>
#
# SPDX-License-Identifier: BSD-3-Clause

# NOTE: For detailed description about a purpose of this file, see the
# Parametrization section in the documentation of the NDK-CORE repository.

# Build identification (generated automatically by default)
set BUILD_TIME [format "%d" [clock seconds]]
set BUILD_UID  [format "%d" [exec id -u]]

# Fixed DMA parameters
set DMA_RX_FRAME_SIZE_MIN 60
set DMA_TX_FRAME_SIZE_MIN 60

VhdlPkgProjectText $PROJECT_NAME

VhdlPkgStr PCIE_MOD_ARCH $PCIE_MOD_ARCH
VhdlPkgStr NET_MOD_ARCH  $NET_MOD_ARCH

VhdlPkgInt    ETH_PORTS       $ETH_PORTS
VhdlPkgIntArr ETH_PORT_SPEED  $ETH_PORTS
VhdlPkgIntArr ETH_PORT_CHAN   $ETH_PORTS
VhdlPkgIntArr ETH_PORT_RX_MTU $ETH_PORTS
VhdlPkgIntArr ETH_PORT_TX_MTU $ETH_PORTS

VhdlPkgInt  PCIE_GEN           $PCIE_GEN
VhdlPkgInt  PCIE_ENDPOINTS     $PCIE_ENDPOINTS
VhdlPkgInt  PCIE_ENDPOINT_MODE $PCIE_ENDPOINT_MODE

VhdlPkgInt  DMA_RX_CHANNELS       $DMA_RX_CHANNELS
VhdlPkgInt  DMA_TX_CHANNELS       $DMA_TX_CHANNELS
VhdlPkgInt  DMA_RX_FRAME_SIZE_MAX $DMA_RX_FRAME_SIZE_MAX
VhdlPkgInt  DMA_TX_FRAME_SIZE_MAX $DMA_TX_FRAME_SIZE_MAX
#VhdlPkgInt  DMA_RX_FRAME_SIZE_MIN $DMA_RX_FRAME_SIZE_MIN
#VhdlPkgInt  DMA_TX_FRAME_SIZE_MIN $DMA_TX_FRAME_SIZE_MIN
VhdlPkgBool DMA_RX_BLOCKING_MODE  $DMA_RX_BLOCKING_MODE

VhdlPkgBool PTC_DISABLE   $PTC_DISABLE

VhdlPkgInt  DMA_RX_CHANNELS      $DMA_RX_CHANNELS
VhdlPkgInt  DMA_TX_CHANNELS      $DMA_TX_CHANNELS
VhdlPkgBool DMA_RX_BLOCKING_MODE $DMA_RX_BLOCKING_MODE

# Other parameters
VhdlPkgBool TSU_ENABLE    $TSU_ENABLE
VhdlPkgInt  TSU_FREQUENCY $TSU_FREQUENCY
