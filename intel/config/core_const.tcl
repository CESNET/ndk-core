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

set PCIE_LANES 16

if {$DMA_TYPE == 4} {
    if {$PCIE_ENDPOINTS == 1 && $PCIE_ENDPOINT_MODE == 2} {
        set PCIE_LANES 8
    }
}

if {$ETH_PORTS == 0} {
    set NET_MOD_ARCH "EMPTY"
}

# ------------------------------------------------------------------------------
# Checking of parameter compatibility
# ------------------------------------------------------------------------------

if {$ETH_PORTS <= $PCIE_ENDPOINTS} {
    if {$DMA_MODULES != $ETH_PORTS && $ETH_PORTS != 0 && $DMA_MODULES != 0} {
        error "Incompatible value of DMA_MODULES: $DMA_MODULES! Must be equal to ETH_PORTS."
    }
} else {
    if {($DMA_MODULES != $ETH_PORTS) && ($DMA_MODULES != 1)} {
        error "Incompatible value of DMA_MODULES: $DMA_MODULES! Must be equal to ETH_PORTS or equal to 1."
    }
}

if { $DMA_TYPE == 4 } {
    if { $PCIE_ENDPOINTS != 1 || $PCIE_ENDPOINT_MODE != 2} {
        error "Incompatible DMA_TYPE: $DMA_TYPE with chosen PCIE_ENDPOINTS: $PCIE_ENDPOINTS\
                and PCIE_ENDPOINT_MODE: $PCIE_ENDPOINT_MODE!"
    }

    if { $DMA_TX_FRAME_SIZE_MAX > [expr 2**$DMA_TX_DATA_PTR_W -1] } {
        error "The maximum allowed length of a packet is too large and cannot fit to data buffer:\
                DMA_TX_FRAME_SIZE_MAX: $DMA_TX_FRAME_SIZE and DMA_TX_DATA_PTR_W: $DMA_TX_DATA_PTR_W"
    }
} elseif { $DMA_TYPE == 3 } {
    if { $DMA_RX_DATA_PTR_W != 16 || $DMA_RX_HDR_PTR_W != 16 || $DMA_TX_DATA_PTR_W != 16} {
        error "This pointer configuration has never been tested on DMA Medusa: RX_DATA_PTR_W: $DMA_RX_DATA_PTR_W,\
                RX_HDR_PTR_W: $DMA_RX_HDR_PTR_W, TX_DATA_PTR_W: $DMA_TX_DATA_PTR_W!"
    }
}

VhdlPkgProjectText $PROJECT_NAME

VhdlPkgStr PCIE_MOD_ARCH $PCIE_MOD_ARCH
VhdlPkgStr NET_MOD_ARCH  $NET_MOD_ARCH

# This is only to ensure the correct package generation.
if {$ETH_PORTS == 0} {
    VhdlPkgInt    ETH_PORTS       1
    VhdlPkgIntArr ETH_PORT_SPEED  1
    VhdlPkgIntArr ETH_PORT_CHAN   1
    VhdlPkgIntArr ETH_PORT_RX_MTU 1
    VhdlPkgIntArr ETH_PORT_TX_MTU 1
} else {
    VhdlPkgInt    ETH_PORTS       $ETH_PORTS
    VhdlPkgIntArr ETH_PORT_SPEED  $ETH_PORTS
    VhdlPkgIntArr ETH_PORT_CHAN   $ETH_PORTS
    VhdlPkgIntArr ETH_PORT_RX_MTU $ETH_PORTS
    VhdlPkgIntArr ETH_PORT_TX_MTU $ETH_PORTS
}


VhdlPkgInt  PCIE_LANES         $PCIE_LANES
VhdlPkgInt  PCIE_GEN           $PCIE_GEN
VhdlPkgInt  PCIE_ENDPOINTS     $PCIE_ENDPOINTS
VhdlPkgInt  PCIE_ENDPOINT_MODE $PCIE_ENDPOINT_MODE

VhdlPkgInt  DMA_TYPE              $DMA_TYPE
VhdlPkgInt  DMA_RX_CHANNELS       $DMA_RX_CHANNELS
VhdlPkgInt  DMA_TX_CHANNELS       $DMA_TX_CHANNELS
VhdlPkgInt  DMA_RX_FRAME_SIZE_MAX $DMA_RX_FRAME_SIZE_MAX
VhdlPkgInt  DMA_TX_FRAME_SIZE_MAX $DMA_TX_FRAME_SIZE_MAX
#VhdlPkgInt  DMA_RX_FRAME_SIZE_MIN $DMA_RX_FRAME_SIZE_MIN
#VhdlPkgInt  DMA_TX_FRAME_SIZE_MIN $DMA_TX_FRAME_SIZE_MIN
VhdlPkgBool DMA_RX_BLOCKING_MODE $DMA_RX_BLOCKING_MODE
VhdlPkgInt  DMA_RX_DATA_PTR_W    $DMA_RX_DATA_PTR_W
VhdlPkgInt  DMA_RX_HDR_PTR_W     $DMA_RX_HDR_PTR_W
VhdlPkgInt  DMA_TX_DATA_PTR_W    $DMA_TX_DATA_PTR_W

# Other parameters
VhdlPkgBool TSU_ENABLE    $TSU_ENABLE
VhdlPkgInt  TSU_FREQUENCY $TSU_FREQUENCY
