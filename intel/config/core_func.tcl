# core_funv.tcl: CORE TCL functions
# Copyright (C) 2023 CESNET, z. s. p. o.
# Author(s): Jakub Cabal <cabal@cesnet.cz>
#
# SPDX-License-Identifier: BSD-3-Clause

# Parsing PCIE_CONF string to list of parameters (PCIE_EPS, PCIE_GEN, PCIE_MODE)
# Example PCIE_CONF = "2xGen4x8x8" returns: 2, 4, 1
proc ParsePcieConf {PCIE_CONF} {
    set pcie_const0 0
    set pcie_const1 0
    set pcie_const2 0
    set pcie_eps 0
    set pcie_gen 0

    scan $PCIE_CONF {%d%[xX]%[a-zA-Z]%d%[a-zA-Z0-9]} pcie_eps pcie_const0 pcie_const1 pcie_gen pcie_const2

    if {$pcie_eps == 0} {
        error "Parsing error pcie_eps in PCIE_CONF = $PCIE_CONF!"
    }

    if {[string compare -nocase $pcie_const2 "x16"] == 0} {
        set pcie_mode 0
    } elseif {[string compare -nocase $pcie_const2 "x8x8"] == 0} {
        set pcie_mode 1
    } elseif {[string compare -nocase $pcie_const2 "x8LL"] == 0} {
        set pcie_mode 2
    } else {
        error "Parsing error PCIE_MODE in PCIE_CONF = $PCIE_CONF!"
    }
    return [list $pcie_eps $pcie_gen $pcie_mode]
}
