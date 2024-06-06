# common.tcl: script with common IP properties
# Copyright (C) 2024 CESNET z. s. p. o.
# Author(s): Tomas Hak <hak@cesnet.cz>
#
# SPDX-License-Identifier: BSD-3-Clause

proc get_ip_filename {ip_name {synth "QUARTUS"}} {
    if {$synth == "QUARTUS"} {
        return $ip_name.ip
    } elseif {$synth == "VIVADO"} {
        return $ip_name.xci
    }
}
