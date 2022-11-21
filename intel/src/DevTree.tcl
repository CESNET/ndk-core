proc dts_build_netcope {} {
    # =========================================================================
    # MI ADDRESS SPACE
    # Changes must also be made manually in VHDL package:
    # <NDK-CORE_root_directory>/intel/src/mi_addr_space_pkg.vhd
    # =========================================================================
    set ADDR_TEST_SPACE "0x00000000"
    set ADDR_SDM_SYSMON "0x00001000"
    set ADDR_BOOT_CTRL  "0x00002000"
    set ADDR_ETH_PMD    "0x00003000"
    set ADDR_TSU        "0x00004000"
    set ADDR_GEN_LOOP   "0x00005000"
    set ADDR_ETH_MAC    "0x00008000"
    #set ADDR_DDR_MOD    "0x00010000"
    set ADDR_DMA_MOD    "0x01000000"
    #set ADDR_MSIX_MOD   "0x01400000"
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
    if {$CARD_NAME == "FB4CGG3" || $CARD_NAME == "FB2CGG3" || $CARD_NAME == "FB2CGHH" || $CARD_NAME == "COMBO-400G1" || $CARD_NAME == "NFB-200G2QL"} {
        append ret "boot:" [dts_boot_controller $ADDR_BOOT_CTRL $BOOT_TYPE]
    }

    append ret [dts_mi_test_space "mi_test_space" $ADDR_TEST_SPACE]

    # TSU component
    global TSU_ENABLE
    if {$TSU_ENABLE} {
        append ret "tsu:" [dts_tsugen $ADDR_TSU]
    }

    # DMA module
    global DMA_TYPE DMA_RX_CHANNELS DMA_TX_CHANNELS PCIE_ENDPOINTS DMA_RX_FRAME_SIZE_MAX DMA_TX_FRAME_SIZE_MAX DMA_RX_FRAME_SIZE_MIN DMA_TX_FRAME_SIZE_MIN
    if {$DMA_TYPE != 0} {
        append ret [dts_dmamod_open $ADDR_DMA_MOD $DMA_TYPE [expr $DMA_RX_CHANNELS / $PCIE_ENDPOINTS] [expr $DMA_TX_CHANNELS / $PCIE_ENDPOINTS] "0" $DMA_RX_FRAME_SIZE_MAX $DMA_TX_FRAME_SIZE_MAX $DMA_RX_FRAME_SIZE_MIN $DMA_TX_FRAME_SIZE_MIN]
    }

    # -----------------------------------------------------------------------------------------
    # WARNING: DMA TSU is for testing purposes only. Otherwise the corruption of data could
    # occur.
    # -----------------------------------------------------------------------------------------
    global DMA_TSU_ENABLE
    if {$DMA_TSU_ENABLE && $DMA_TYPE == 4} {
        append ret "tsu1:" [dts_tsugen [expr $ADDR_DMA_MOD + 0x40000] "tsu1"]
    }

    # Network module
    global NET_MOD_ARCH ETH_PORTS ETH_PORT_SPEED ETH_PORT_CHAN ETH_PORT_LANES ETH_PORT_RX_MTU ETH_PORT_TX_MTU NET_MOD_ARCH QSFP_CAGES QSFP_I2C_ADDR
    if {$NET_MOD_ARCH != "EMPTY"} {
        append ret [dts_network_mod $ADDR_ETH_MAC $ADDR_ETH_PCS $ADDR_ETH_PMD $ETH_PORTS ETH_PORT_SPEED ETH_PORT_CHAN ETH_PORT_LANES ETH_PORT_RX_MTU ETH_PORT_TX_MTU $NET_MOD_ARCH $QSFP_CAGES QSFP_I2C_ADDR $CARD_NAME]
    }

    global SDM_SYSMON_ARCH
    # Intel FPGA SDM controller
    if {$SDM_SYSMON_ARCH == "INTEL_SDM"} {
        set boot_active_serial 0
        append ret [dts_sdm_controller $ADDR_SDM_SYSMON $boot_active_serial]
    }
    # Deprecated ID component to access Xilinx SYSMON
    if {$SDM_SYSMON_ARCH == "USP_IDCOMP"} {
        append ret "idcomp:" [dts_idcomp $ADDR_SDM_SYSMON]
    }
    # Deprecated Intel Stratix 10 ADC Sensor Component
    if {$SDM_SYSMON_ARCH == "S10_ADC"} {
        append ret [dts_stratix_adc_sensors $ADDR_SDM_SYSMON]
    }

    # Populate application, if exists
    if { [llength [info procs dts_application]] > 0 } {
        global MEM_PORTS
        append ret "app:" [dts_application $ADDR_USERAPP $ETH_PORTS $MEM_PORTS]
    }

    # Gen Loop Switch debug modules for each DMA stream/module
    global DMA_MODULES
    for {set i 0} {$i < $DMA_MODULES} {incr i} {
        set    gls_offset [expr $i * 0x100]
        append ret [dts_gen_loop_switch [expr $ADDR_GEN_LOOP + $gls_offset] "dbg_gls$i"]
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

        if {$DMA_TYPE != 0} {
            append ret [dts_dmamod_open $ADDR_DMA_MOD $DMA_TYPE [expr $DMA_RX_CHANNELS / $PCIE_ENDPOINTS] [expr $DMA_TX_CHANNELS / $PCIE_ENDPOINTS] $i $DMA_RX_FRAME_SIZE_MAX $DMA_TX_FRAME_SIZE_MAX $DMA_RX_FRAME_SIZE_MIN $DMA_TX_FRAME_SIZE_MIN]
        }
        append ret "};"
    }

    # Creating separate space for MI bus when DMA Calypte are used, the core uses additional BAR for its function
    if {$DMA_TYPE == 4} {
        append ret "mi1: mi_bus1 {"
        append ret "#address-cells = <1>;"
        append ret "#size-cells = <1>;"

        append ret "compatible = \"netcope,bus,mi\";"
        append ret "resource = \"PCI0,BAR2\";"
        append ret "width = <0x20>;"

        set FIFO_DEPTH          512
        set MFB_BYTE_WIDTH      32
        set DMA_HDR_BYTE_WIDTH  8
        set CHAN_PER_EP         [expr $DMA_TX_CHANNELS / $PCIE_ENDPOINTS]

        # Calculation of the addres range reserved for single channel
        set TX_DATA_BUFF_BASE       "0x00000000"
        set TX_DATA_BUFF_SIZE       [expr $FIFO_DEPTH*$MFB_BYTE_WIDTH]
        set TX_DATA_BUFF_SIZE_HEX   [format "0x%x" $TX_DATA_BUFF_SIZE]

        for {set i 0} {$i < $CHAN_PER_EP} {incr i} {
            set    var_buff_base [expr $TX_DATA_BUFF_BASE + $i * $TX_DATA_BUFF_SIZE_HEX]
            append ret [dts_dma_calypte_tx_buffer "data" $i $var_buff_base $TX_DATA_BUFF_SIZE_HEX "0"]
        }

        set TX_HDR_BUFF_BASE        [expr $TX_DATA_BUFF_BASE + $CHAN_PER_EP*$TX_DATA_BUFF_SIZE]
        set TX_HDR_BUFF_SIZE        [expr $FIFO_DEPTH*$DMA_HDR_BYTE_WIDTH]
        set TX_HDR_BUFF_SIZE_HEX    [format "0x%x" $TX_HDR_BUFF_SIZE]

        for {set i 0} {$i < $CHAN_PER_EP} {incr i} {
            set    var_buff_base [expr $TX_HDR_BUFF_BASE + $i * $TX_HDR_BUFF_SIZE_HEX]
            append ret [dts_dma_calypte_tx_buffer "hdr" $i $var_buff_base $TX_HDR_BUFF_SIZE_HEX "0"]
        }
        append ret "};"
    }
    return $ret
}
