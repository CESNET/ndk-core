// tbench.sv: Testbench
// Copyright (C) 2023 CESNET z. s. p. o.
// Author(s): Radek Iša <isa@cesnet.cz>

// SPDX-License-Identifier: BSD-3-Clause



//This is hotfix please dont use this method unless it is necesary
module fix_bind#(PORTS, CHANNELS, REGIONS);

    //bind NETWORK_MOD_LOGIC : $root.testbench.DUT_U.VHDL_DUT_U.eth_core_g[0].network_mod_logic_i probe_inf #(2*USER_REGIONS) probe_drop(1'b1, '0, CLK_USER);
    //bind NETWORK_MOD_LOGIC : $root.testbench.DUT_U.VHDL_DUT_U.eth_core_g[PORT].network_mod_logic_i probe_inf #(2*USER_REGIONS) probe_drop(1'b1, '0, CLK_USER);

    //nedá se svítit
    if (PORTS == 2 &&  CHANNELS == 1) begin
        bind RX_MAC_LITE_BUFFER : $root.testbench.DUT_U.VHDL_DUT_U.eth_core_g[0].network_mod_logic_i.mac_lites_g[0].rx_mac_lite_i.buffer_i probe_inf #(2*REGIONS) probe_drop(s_rx_src_rdy_orig_reg, {s_rx_eof_orig_reg, s_rx_force_drop_reg}, RX_CLK);
        bind RX_MAC_LITE_BUFFER : $root.testbench.DUT_U.VHDL_DUT_U.eth_core_g[1].network_mod_logic_i.mac_lites_g[0].rx_mac_lite_i.buffer_i probe_inf #(2*REGIONS) probe_drop(s_rx_src_rdy_orig_reg, {s_rx_eof_orig_reg, s_rx_force_drop_reg}, RX_CLK);
    end else begin
        $error("%m UNSUPORTED COMBINATION ETH_PORTS(%0d) ETH_PORT_CHANNEL(%0d)!!!\n", PORTS, CHANNELS);
    end
endmodule

