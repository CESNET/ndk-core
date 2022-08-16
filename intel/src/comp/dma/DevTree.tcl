# 1.  base - base module address
# 2.  type - controller type: 3 for DMA Medusa only
# 3.  rxn  - number of RX channels
# 4.  txn  - number of TX channels
# 5.  pcie - index(es) of PCIe endpoint(s) which DMA module uses.
# 6.  rx_frame_size_max - maximum allowed size of DMA RX frame
# 7.  tx_frame_size_max - maximum allowed size of DMA TX frame
# 8.  rx_frame_size_min - minimum allowed size of DMA RX frame
# 9.  tx_frame_size_min - minimum allowed size of DMA TX frame
# 10. offset - address offset for TX controllers
proc dts_dmamod_open {base type rxn txn pcie rx_frame_size_max tx_frame_size_max rx_frame_size_min tx_frame_size_min {offset 0x00200000}} {
    set    ret ""
    append ret "dma_module@$base {"

    append ret "#address-cells = <1>;"
    append ret "#size-cells = <1>;"

    if {$type == 3} {
        set strtype "ndp"
    } elseif {$type == 4} {
        set strtype "calypte"
    } else {
        error "ERROR: Unsupported DMA Type $type for DMA Module!"
    }

    append ret "dma_params_rx$pcie:" [dts_dma_params "dma_params_rx$pcie" $rx_frame_size_max $rx_frame_size_min]
    append ret "dma_params_tx$pcie:" [dts_dma_params "dma_params_tx$pcie" $tx_frame_size_max $tx_frame_size_min]

    # RX DMA Channels
    for {set i 0} {$i < $rxn} {incr i} {
        if {$type == 3} {
            set    var_base [expr $base + $i * 0x80]
            append ret [dts_dma_medusa_ctrl $strtype $type "rx" $i $var_base $pcie "dma_params_rx$pcie"]
        } elseif {$type == 4} {
            set    var_base [expr $base + $i * 0x80]
            append ret [dts_dma_calypte_ctrl $strtype "rx" $i $var_base $pcie]
        }
    }

    # TX DMA channels
    for {set i 0} {$i < $txn} {incr i} {
        if {$type == 3} {
            set    var_base [expr $base + $i * 0x80 + $offset]
            append ret [dts_dma_medusa_ctrl $strtype $type "tx" $i $var_base $pcie "dma_params_tx$pcie"]
        }
    }

    append ret "};"
    return $ret
}

# 1. name - node name
# 2. frame_size_max - maximum allowed size of DMA frame
# 3. frame_size_min - minimum allowed size of DMA frame
proc dts_dma_params {name frame_size_max frame_size_min} {
    set ret ""
    append ret "$name {"
    append ret "frame_size_max = <$frame_size_max>;"
    append ret "frame_size_min = <$frame_size_min>;"
    append ret "};"
    return $ret
}
