# 1. base_mac   - base address of MAC layer
# 2. base_pcs   - base address of PCS/PMA layer
# 2. base_pmd   - base address of PMD/I2C layer
# 3. ports      - number of ethernet ports
# 4. port_speed - array of strings, speed (and number of channels) for all ports
proc dts_network_mod { base_mac base_pcs base_pmd ports ETH_PORT_SPEED ETH_PORT_CHAN card_name} {

    # use upvar to pass an array
    upvar $ETH_PORT_SPEED port_speed
    upvar $ETH_PORT_CHAN  port_chan

    set MTUI 16383
    set MTUO 16383

    set ei 0
    # MAC Lites offset (9 bits)
    set TX_RX_MAC_OFF  0x0200
    # MAC Lites offset for channels (MAC Lites offset + 1 extra bit)
    set CHAN_OFF       0x0400
    # MAC Lites offset for ports (MAC Lites offset for channels + 3 extra bits)
    set PORTS_OFF      0x2000
    # Port offset of MGMT PCS registers
    set MGMT_PORT_OFF  0x200000
    # Chan offset of MGMT PCS registers
    set MGMT_CHAN_OFF  0x40000
    # Port offset of PMD registers
    set PMD_PORT_OFF   0x100

    set I2C_ADDR       0x800010

    set QSFP_I2C_ADDR(0) "0xA0"
    set QSFP_I2C_ADDR(1) "0xA0"
    set QSFP_I2C_ADDR(2) "0xA0"
    set QSFP_I2C_ADDR(3) "0xA0"
    if {$card_name == "DK-DEV-1SDX-P"} {
        set QSFP_I2C_ADDR(0) "0xF0"
        set QSFP_I2C_ADDR(1) "0xF8"
    }
    if {$card_name == "DK-DEV-AGI027RES"} {
        # Only QSFP1 cage is used, QSFP0 is completely disconnected.
        set QSFP_I2C_ADDR(0) "0xF8"
    }

    set ret ""

    for {set p 0} {$p < $ports} {incr p} {
        append ret "i2c$p:" [dts_i2c $p [expr $base_pmd + $PMD_PORT_OFF * $p + 0x10]]
	    append ret "pmdctrl$p:" [dts_pmd_ctrl $p [expr $base_pmd + $PMD_PORT_OFF * $p + 0x1c]]
        append ret "pmd$p:" [dts_eth_transciever $p "QSFP" "i2c$p" $QSFP_I2C_ADDR($p)]
        for {set ch 0} {$ch < $port_chan($p)} {incr ch} {
            append ret "regarr$ei:" [dts_pcs_regs $ei [expr $base_pcs + $MGMT_PORT_OFF * $p + $MGMT_CHAN_OFF * $ch]]
			append ret "pcspma$ei:" [dts_mgmt $ei "$port_speed($p)G" "regarr$ei" ""]
            append ret "txmac$ei:" [dts_tx_mac_lite $ei $port_speed($p) [expr $base_mac + $p * $PORTS_OFF + $ch * $CHAN_OFF + $TX_RX_MAC_OFF * 0] $MTUO]
            append ret "rxmac$ei:" [dts_rx_mac_lite $ei $port_speed($p) [expr $base_mac + $p * $PORTS_OFF + $ch * $CHAN_OFF + $TX_RX_MAC_OFF * 1] $MTUI]
            append ret [dts_eth_channel $ei $p $ei $ei $ei]
            incr ei
        }
    }

    return $ret
}

# 1. no            - node index
# 2. type          - QSFP,...
# 3. control       - name of control module node
# 3. qsfp_i2c_addr - PMD I2C address
proc dts_eth_transciever {no type control qsfp_i2c_addr} {
	set    ret ""
	append ret "pmd$no {"
	append ret "compatible = \"netcope,transceiver\";"
	append ret "type = \"$type\";"
    append ret "control = <&$control>;"
    append ret "control-param{i2c-addr=<$qsfp_i2c_addr>;};"
	append ret "};"
	return $ret
}

# 1. no   - node index
# 2. base - base address
proc dts_pmd_ctrl {no base} {
	set ret ""
	append ret "pmdctrl$no {"
	append ret "reg = <$base 1>;"
	append ret "version = <0x00010000>;"
	append ret "};"
	return $ret;
}

# 1. no        - node index
# 2. pmd       - number of transciever used by channel
# 3. rxmac_num - number of rxmac used by channel
# 4. txmac_num - number of txmac used by channel
# 5. phy_num   - number of PCS/PMS used by channel
proc dts_eth_channel {no pmd rxmac_num txmac_num phy_num} {
	set    ret ""
	append ret "eth$no {"
	append ret "compatible = \"netcope,eth\";"
	append ret "pmd = <&pmd$pmd>;"
	if {$phy_num   != -1} {append ret "pcspma = <&pcspma$phy_num>;"}
	if {$rxmac_num != -1} {append ret "rxmac = <&rxmac$rxmac_num>;"}
	if {$txmac_num != -1} {append ret "txmac = <&txmac$txmac_num>;"}
	append ret "};"
	return $ret;
}
