# ndk_pkg_gen.tcl: Generates constants to the VHDL package and fills them with
# values specified by TCL variables with same names. This file is sourced as a last step
# in the hierarchy of *_const.tcl files therefore it has the highest priority.
# Copyright (C) 2022 CESNET, z. s. p. o.
# Author(s): Jakub Cabal <cabal@cesnet.cz>
#            Vladislav Valek <valekv@cesnet.cz>
#
# SPDX-License-Identifier: BSD-3-Clause

# ==================================================================================
# WARNING: Values of constants in this file should not be changed deliberately by the user.
# ==================================================================================

# Build identification (generated automatically by default)
set BUILD_TIME [format "%d" [clock seconds]]
set BUILD_UID  [format "%d" [exec id -u]]

VhdlPkgProjectText $PROJECT_NAME

VhdlPkgStr PCIE_MOD_ARCH $PCIE_MOD_ARCH
VhdlPkgStr NET_MOD_ARCH  $NET_MOD_ARCH

VhdlPkgInt    ETH_PORTS       $ETH_PORTS
VhdlPkgIntArr ETH_PORT_SPEED  $ETH_PORTS
VhdlPkgIntArr ETH_PORT_CHAN   $ETH_PORTS
# TODO: MTU is not fully configurable right now
VhdlPkgHexVector MAX_MTU_RX      32 00003FE0
VhdlPkgHexVector MAX_MTU_TX      32 00003FE0

VhdlPkgInt  PCIE_GEN           $PCIE_GEN
VhdlPkgInt  PCIE_ENDPOINTS     $PCIE_ENDPOINTS
VhdlPkgInt  PCIE_ENDPOINT_MODE $PCIE_ENDPOINT_MODE

VhdlPkgInt  DMA_RX_CHANNELS      $DMA_RX_CHANNELS
VhdlPkgInt  DMA_TX_CHANNELS      $DMA_TX_CHANNELS
VhdlPkgBool DMA_RX_BLOCKING_MODE $DMA_RX_BLOCKING_MODE

# Other parameters
VhdlPkgBool TSU_ENABLE    $TSU_ENABLE
VhdlPkgInt  TSU_FREQUENCY $TSU_FREQUENCY

# ==================================================================================
# Add other constants which you want to export to the VHDL package
# ==================================================================================
# Examples:
#
# Boolean constant
# VhdlPkgBool <name_of_the_VHDL_constant> $<name_of_the_TCL_variable>
#
# Integer constant
# VhdlPkgInt <name_of_the_VHDL_constant> $<name_of_the_TCL_variable>
#
# The supported types can be found in the VhdlPkgGen.tcl script in the OFM repository
#
# ==================================================================================
