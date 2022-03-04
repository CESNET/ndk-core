# 1. base - base module address
# 2. type - controller type: 3 for DMA Medusa only
# 3. rxn  - number of RX channels
# 4. txn  - number of TX channels
# 5. pcie - index(es) of PCIe endpoint(s) which DMA module uses.
# 6. offset - address offset for TX controllers
proc dts_dmamod_open {base type rxn txn pcie {offset 0x00200000}} {
    set    ret ""
    append ret "dma_module@$base {"

    append ret "#address-cells = <1>;"
    append ret "#size-cells = <1>;"

    if {$type == 3} {
        set strtype "ndp"
    } else {
        error "ERROR: Unsupported DMA Type $type for DMA Module!"
    }

    # RX DMA Channels
    for {set i 0} {$i < $rxn} {incr i} {
        if {$type == 3} {
            set    var_base [expr $base + $i * 0x80]
            append ret [dts_dma_medusa_ctrl $strtype $type "rx" $i $var_base $pcie]
        }
    }

    # TX DMA channels
    for {set i 0} {$i < $txn} {incr i} {
        if {$type == 3} {
            set    var_base [expr $base + $i * 0x80 + $offset]
            append ret [dts_dma_medusa_ctrl $strtype $type "tx" $i $var_base $pcie]
        }
    }

    append ret "};"
    return $ret
}