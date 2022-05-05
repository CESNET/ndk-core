# DevTree.tcl: Component DeviceTree file
# Copyright (C) 2022 CESNET z. s. p. o.
# Author(s): Jakub Cabal <cabal@cesnet.cz>
#
# SPDX-License-Identifier: BSD-3-Clause

# 1. base - base address on MI bus
proc dts_boot_controller {base} {
    set    ret ""
    append ret "boot_controller {"
    append ret "compatible = \"netcope,boot_controller\";"
    append ret "reg = <$base 8>;"
    append ret "version = <0x00000001>;"
    append ret "type = <2>;"
    append ret "};"
    return $ret
}
