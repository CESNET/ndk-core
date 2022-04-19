# 1. base_mac   - base address of mac layer (IBUF, OBUF)
#### 2. base_phy   - base address of eth_phy layer (PCS/PMA)  - TODO
# 3. ports      - number of ethernet ports
# 4. port_speed - array of strings, speed (and number of channels) for all ports
proc dts_network_mod { base_mac ports ETH_PORT_SPEED ETH_PORT_CHAN card_name} {

    # use upvar to pass an array
    upvar $ETH_PORT_SPEED port_speed
    upvar $ETH_PORT_CHAN  port_chan

    set MTUI 16383
    set MTUO 16383

    set       ret ""

    set ei 0
    # MAC Lites offset (9 bits)
    set TX_RX_MAC_OFF  0x0200
    # MAC Lites offset for channels (MAC Lites offset + 1 extra bit)
    set CHAN_OFF       0x0400
    # MAC Lites offset for ports (MAC Lites offset for channels + 3 extra bits)
    set PORTS_OFF      0x2000

    set I2C_ADDR       0x800010

    set QSFP_I2C_ADDR(0) "0xA0"
    set QSFP_I2C_ADDR(1) "0xA0"
    if {$card_name == "DK-DEV-1SDX-P"} {
        set QSFP_I2C_ADDR(0) "0xF0"
        set QSFP_I2C_ADDR(1) "0xF8"
    }
    if {$card_name == "DK-DEV-AGI027RES"} {
        # Only QSFP1 cage is used, QSFP0 is completely disconnected.
        set QSFP_I2C_ADDR(0) "0xF8"
    }

    for {set p 0} {$p < $ports} {incr p} {
        append ret "i2c$p:" [dts_i2c $p [expr $I2C_ADDR + $p * 0x100]]
        append ret "pmd$p:" [dts_eth_transciever $p "QSFP" "i2c$p" $QSFP_I2C_ADDR($p)]
        for {set ch 0} {$ch < $port_chan($p)} {incr ch} {
            append ret "txmac$ei:" [dts_tx_mac_lite $ei $port_speed($p) [expr $base_mac + $p * $PORTS_OFF + $ch * $CHAN_OFF + $TX_RX_MAC_OFF * 0] $MTUO]
            append ret "rxmac$ei:" [dts_rx_mac_lite $ei $port_speed($p) [expr $base_mac + $p * $PORTS_OFF + $ch * $CHAN_OFF + $TX_RX_MAC_OFF * 1] $MTUI]
            append ret [dts_eth_channel $ei $p $ei $ei]
            incr ei
        }
    }

    return $ret
}

# 1. no   - numero sign PMD order
# 2. type - QSFP
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

# 1. no     - numero sign of eth channel (order number)
# 2. pmd    - number of transciever used by channel
# 3. ibuf   - ibuf number used by channel
# 4. obuf   - obuf number used by channel
proc dts_eth_channel {no pmd ibuf obuf} {
	set    ret ""
	append ret "eth$no {"
	append ret "compatible = \"netcope,eth\";"
	append ret "pmd = <&pmd$pmd>;"
	if {$ibuf   != -1} {append ret "rxmac = <&rxmac$ibuf>;"}
	if {$obuf   != -1} {append ret "txmac = <&txmac$obuf>;"}
	append ret "};"
	return $ret;
}
