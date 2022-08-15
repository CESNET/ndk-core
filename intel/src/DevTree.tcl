proc dts_build_netcope {} {
    # =========================================================================
    # MI ADDRESS SPACE
    # Changes must also be made manually in mi_addr_space_pkg.vhd!
    # =========================================================================
    set ADDR_TEST_SPACE "0x00000000"
    set ADDR_SENSOR     "0x00001000"
    set ADDR_SDM_CTRL   "0x00002000"
    set ADDR_ETH_PMD    "0x00003000"
    set ADDR_TSU        "0x00004000"
    set ADDR_GEN_LOOP   "0x00005000"
    set ADDR_ETH_MAC    "0x00008000"
    set ADDR_DMA_MOD    "0x01000000"
    #set ADDR_MSIX_MOD   "0x01400000"
    set ADDR_DDR_MOD    "0x00010000"
    set ADDR_ETH_PCS    "0x00800000"
    set ADDR_USERAPP    "0x02000000"

    # =========================================================================
    # Top level Device tree file
    # =========================================================================
    set    ret ""

    global CARD_NAME DT_PROJECT_TEXT PROJECT_VARIANT PROJECT_VERSION

    append ret "card-name = \"$CARD_NAME\";"
    if { [info exists DT_PROJECT_TEXT] } {
        append ret "project-name = \"$DT_PROJECT_TEXT\";"
    }
    if { [info exists PROJECT_VARIANT] } {
        append ret "project-variant = \"$PROJECT_VARIANT\";"
    }
    if { [info exists PROJECT_VERSION] } {
        append ret "project-version = \"$PROJECT_VERSION\";"
    }

    # Create MI bus node
    append ret "mi0: mi_bus0 {"
    append ret "#address-cells = <1>;"
    append ret "#size-cells = <1>;"

    append ret "compatible = \"netcope,bus,mi\";"
    append ret "resource = \"PCI0,BAR0\";"
    append ret "width = <0x20>;"

    # BOOT component
    set BOOT_TYPE 2
    if {$CARD_NAME == "FB2CGHH"} {
        set BOOT_TYPE 3
    }
    if {$CARD_NAME == "FB4CGG3" || $CARD_NAME == "FB2CGG3" || $CARD_NAME == "FB2CGHH" || $CARD_NAME == "400G1"} {
        append ret "boot:" [dts_boot_controller $ADDR_SDM_CTRL $BOOT_TYPE]
    }

    # TSU component
    global TSU_ENABLE
    if {$TSU_ENABLE} {
        append ret "tsu:" [dts_tsugen $ADDR_TSU]
    }

    # DMA module
    global DMA_ENABLE DMA_TYPE DMA_MODULES DMA_RX_CHANNELS DMA_TX_CHANNELS PCIE_ENDPOINTS
    if {$DMA_ENABLE} {
        append ret [dts_dmamod_open $ADDR_DMA_MOD $DMA_TYPE [expr $DMA_RX_CHANNELS / $PCIE_ENDPOINTS] [expr $DMA_TX_CHANNELS / $PCIE_ENDPOINTS] "0"]
    }

    # Network module
    global NET_MOD_ARCH ETH_PORTS ETH_PORT_SPEED ETH_PORT_CHAN ETH_PORT_LANES
    if {$NET_MOD_ARCH != "EMPTY"} {
        append ret [dts_network_mod $ADDR_ETH_MAC $ADDR_ETH_PCS $ADDR_ETH_PMD $ETH_PORTS ETH_PORT_SPEED ETH_PORT_CHAN ETH_PORT_LANES $CARD_NAME]
    }

    # Gen Loop Switch debug modules
    #for {set i 0} {$i < $ETH_PORTS} {incr i} {
    #    set    gls_offset [expr $i * 0x100]
    #    append ret [dts_gen_loop_switch $i [expr $ADDR_GEN_LOOP + $gls_offset]]
    #}

    # Intel FPGA SDM controller
    if {$CARD_NAME == "400G1" || $CARD_NAME == "DK-DEV-1SDX-P" || $CARD_NAME == "DK-DEV-AGI027RES"} {
        set boot_active_serial 0
        append ret [dts_sdm_controller $ADDR_SENSOR $boot_active_serial]
    }

    # Populate application, if exists
    if { [llength [info procs dts_application]] > 0 } {
        global MEM_PORTS
        append ret "app:" [dts_application $ADDR_USERAPP $ETH_PORTS $MEM_PORTS]
    }

    append ret "};"

    for {set i 1} {$i < $PCIE_ENDPOINTS} {incr i} {
        # Create MI bus node
        append ret "mi$i: mi_bus$i {"
        append ret "#address-cells = <1>;"
        append ret "#size-cells = <1>;"

        append ret "compatible = \"netcope,bus,mi\";"
        append ret "resource = \"PCI$i,BAR0\";"
        append ret "width = <0x20>;"

        if {$DMA_ENABLE} {
            append ret [dts_dmamod_open $ADDR_DMA_MOD $DMA_TYPE [expr $DMA_RX_CHANNELS / $PCIE_ENDPOINTS] [expr $DMA_TX_CHANNELS / $PCIE_ENDPOINTS] $i]
        }
        append ret "};"
    }
    return $ret
}
