-- network_mod_core_etile.vhd: core of the Network module with Ethernet E-TILE(s).
-- Copyright (C) 2021 CESNET z. s. p. o.
-- Author(s): Daniel Kondys <xkondy00@vutbr.cz>
--
-- SPDX-License-Identifier: BSD-3-Clause

-- NOTE: generated 25g4 and 10g4 IPs have incorrectly generated generic settings: rx and tx_max_frame_size, rx and tx_vlan_detection
--       original values: rx_max_frame_size = tx_max_frame_size = 1518 , rx_vlan_detection = tx_vlan_detection = "disable"
--       required values: rx_max_frame_size = tx_max_frame_size = 16383, rx_vlan_detection = tx_vlan_detection = "enable"

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.math_pack.all;
use work.type_pack.all;
use work.eth_hdr_pack.all;

architecture ETILE of NETWORK_MOD_CORE is

    -- =========================================================================
    --                        COMPONENTS - E_TILE
    -- =========================================================================
    -- 100g1
    component etile_eth_1x100g is
    generic (
        am_encoding40g_0              : integer := 9467463;
        am_encoding40g_1              : integer := 15779046;
        am_encoding40g_2              : integer := 12936603;
        am_encoding40g_3              : integer := 10647869;
        enforce_max_frame_size        : string  := "disable";
        flow_control                  : string  := "both_no_xoff";
        flow_control_holdoff_mode     : string  := "uniform";
        forward_rx_pause_requests     : string  := "disable";
        hi_ber_monitor                : string  := "enable";
        holdoff_quanta                : integer := 65535;
        ipg_removed_per_am_period     : integer := 20;
        link_fault_mode               : string  := "lf_bidir";
        pause_quanta                  : integer := 65535;
        pfc_holdoff_quanta_0          : integer := 65535;
        pfc_holdoff_quanta_1          : integer := 65535;
        pfc_holdoff_quanta_2          : integer := 65535;
        pfc_holdoff_quanta_3          : integer := 65535;
        pfc_holdoff_quanta_4          : integer := 65535;
        pfc_holdoff_quanta_5          : integer := 65535;
        pfc_holdoff_quanta_6          : integer := 65535;
        pfc_holdoff_quanta_7          : integer := 65535;
        pfc_pause_quanta_0            : integer := 65535;
        pfc_pause_quanta_1            : integer := 65535;
        pfc_pause_quanta_2            : integer := 65535;
        pfc_pause_quanta_3            : integer := 65535;
        pfc_pause_quanta_4            : integer := 65535;
        pfc_pause_quanta_5            : integer := 65535;
        pfc_pause_quanta_6            : integer := 65535;
        pfc_pause_quanta_7            : integer := 65535;
        remove_pads                   : string  := "disable";
        rx_length_checking            : string  := "disable";
        rx_max_frame_size             : integer := 16383;
        rx_pause_daddr                : string  := "17483607389996";
        rx_pcs_max_skew               : integer := 47;
        rx_vlan_detection             : string  := "disable";
        rxcrc_covers_preamble         : string  := "disable";
        sim_mode                      : string  := "enable";
        source_address_insertion      : string  := "disable";
        strict_preamble_checking      : string  := "disable";
        strict_sfd_checking           : string  := "disable";
        tx_ipg_size                   : string  := "ipg_12";
        tx_max_frame_size             : integer := 16383;
        tx_pause_daddr                : string  := "1652522221569";
        tx_pause_saddr                : string  := "247393538562781";
        tx_pld_fifo_almost_full_level : integer := 16;
        tx_vlan_detection             : string  := "disable";
        txcrc_covers_preamble         : string  := "disable";
        txmac_saddr                   : string  := "73588229205";
        uniform_holdoff_quanta        : integer := 51090;
        flow_control_sl_0             : string  := "both_no_xoff"
    );
    port (
        i_stats_snapshot              : in  std_logic                      := 'X';             -- i_stats_snapshot
        o_cdr_lock                    : out std_logic_vector(0 downto 0);                      -- o_cdr_lock
        o_tx_pll_locked               : out std_logic_vector(0 downto 0);                      -- o_tx_pll_locked
        i_eth_reconfig_addr           : in  std_logic_vector(20 downto 0)  := (others => 'X'); -- i_eth_reconfig_addr
        i_eth_reconfig_read           : in  std_logic                      := 'X';             -- i_eth_reconfig_read
        i_eth_reconfig_write          : in  std_logic                      := 'X';             -- i_eth_reconfig_write
        o_eth_reconfig_readdata       : out std_logic_vector(31 downto 0);                     -- o_eth_reconfig_readdata
        o_eth_reconfig_readdata_valid : out std_logic;                                         -- o_eth_reconfig_readdata_valid
        i_eth_reconfig_writedata      : in  std_logic_vector(31 downto 0)  := (others => 'X'); -- i_eth_reconfig_writedata
        o_eth_reconfig_waitrequest    : out std_logic;                                         -- o_eth_reconfig_waitrequest
        i_rsfec_reconfig_addr         : in  std_logic_vector(10 downto 0)  := (others => 'X'); -- i_rsfec_reconfig_addr
        i_rsfec_reconfig_read         : in  std_logic                      := 'X';             -- i_rsfec_reconfig_read
        i_rsfec_reconfig_write        : in  std_logic                      := 'X';             -- i_rsfec_reconfig_write
        o_rsfec_reconfig_readdata     : out std_logic_vector(7 downto 0);                      -- o_rsfec_reconfig_readdata
        i_rsfec_reconfig_writedata    : in  std_logic_vector(7 downto 0)   := (others => 'X'); -- i_rsfec_reconfig_writedata
        o_rsfec_reconfig_waitrequest  : out std_logic;                                         -- o_rsfec_reconfig_waitrequest
        o_tx_lanes_stable             : out std_logic;                                         -- o_tx_lanes_stable
        o_rx_pcs_ready                : out std_logic;                                         -- o_rx_pcs_ready
        o_ehip_ready                  : out std_logic;                                         -- o_ehip_ready
        o_rx_block_lock               : out std_logic;                                         -- o_rx_block_lock
        o_rx_am_lock                  : out std_logic;                                         -- o_rx_am_lock
        o_rx_hi_ber                   : out std_logic;                                         -- o_rx_hi_ber
        o_local_fault_status          : out std_logic;                                         -- o_local_fault_status
        o_remote_fault_status         : out std_logic;                                         -- o_remote_fault_status
        i_clk_ref                     : in  std_logic_vector(0 downto 0)   := (others => 'X'); -- i_clk_ref
        i_clk_tx                      : in  std_logic                      := 'X';             -- clk
        i_clk_rx                      : in  std_logic                      := 'X';             -- clk
        o_clk_pll_div64               : out std_logic_vector(0 downto 0);                      -- o_clk_pll_div64
        o_clk_pll_div66               : out std_logic_vector(0 downto 0);                      -- o_clk_pll_div66
        o_clk_rec_div64               : out std_logic_vector(0 downto 0);                      -- o_clk_rec_div64
        o_clk_rec_div66               : out std_logic_vector(0 downto 0);                      -- o_clk_rec_div66
        i_csr_rst_n                   : in  std_logic                      := 'X';             -- reset
        i_tx_rst_n                    : in  std_logic                      := 'X';             -- i_tx_rst_n
        i_rx_rst_n                    : in  std_logic                      := 'X';             -- i_rx_rst_n
        o_tx_serial                   : out std_logic_vector(3 downto 0);                      -- o_tx_serial
        i_rx_serial                   : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- i_rx_serial
        o_tx_serial_n                 : out std_logic_vector(3 downto 0);                      -- o_tx_serial_n
        i_rx_serial_n                 : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- i_rx_serial_n
        i_reconfig_clk                : in  std_logic                      := 'X';             -- clk
        i_reconfig_reset              : in  std_logic                      := 'X';             -- i_reconfig_reset
        i_xcvr_reconfig_address       : in  std_logic_vector(75 downto 0)  := (others => 'X'); -- i_xcvr_reconfig_address
        i_xcvr_reconfig_read          : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- i_xcvr_reconfig_read
        i_xcvr_reconfig_write         : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- i_xcvr_reconfig_write
        o_xcvr_reconfig_readdata      : out std_logic_vector(31 downto 0);                     -- o_xcvr_reconfig_readdata
        i_xcvr_reconfig_writedata     : in  std_logic_vector(31 downto 0)  := (others => 'X'); -- i_xcvr_reconfig_writedata
        o_xcvr_reconfig_waitrequest   : out std_logic_vector(3 downto 0);                      -- o_xcvr_reconfig_waitrequest
        o_tx_ready                    : out std_logic;                                         -- o_tx_ready
        i_tx_valid                    : in  std_logic                      := 'X';             -- i_tx_valid
        i_tx_data                     : in  std_logic_vector(511 downto 0) := (others => 'X'); -- i_tx_data
        i_tx_error                    : in  std_logic                      := 'X';             -- i_tx_error
        i_tx_startofpacket            : in  std_logic                      := 'X';             -- i_tx_startofpacket
        i_tx_endofpacket              : in  std_logic                      := 'X';             -- i_tx_endofpacket
        i_tx_empty                    : in  std_logic_vector(5 downto 0)   := (others => 'X'); -- i_tx_empty
        i_tx_skip_crc                 : in  std_logic                      := 'X';             -- i_tx_skip_crc
        o_rx_valid                    : out std_logic;                                         -- o_rx_valid
        o_rx_data                     : out std_logic_vector(511 downto 0);                    -- o_rx_data
        o_rx_startofpacket            : out std_logic;                                         -- o_rx_startofpacket
        o_rx_endofpacket              : out std_logic;                                         -- o_rx_endofpacket
        o_rx_empty                    : out std_logic_vector(5 downto 0);                      -- o_rx_empty
        o_rx_error                    : out std_logic_vector(5 downto 0);                      -- o_rx_error
        o_rxstatus_data               : out std_logic_vector(39 downto 0);                     -- o_rxstatus_data
        o_rxstatus_valid              : out std_logic;                                         -- o_rxstatus_valid
        i_tx_pfc                      : in  std_logic_vector(7 downto 0)   := (others => 'X'); -- i_tx_pfc
        o_rx_pfc                      : out std_logic_vector(7 downto 0);                      -- o_rx_pfc
        i_tx_pause                    : in  std_logic                      := 'X';             -- i_tx_pause
        o_rx_pause                    : out std_logic                                          -- o_rx_pause
    );
    end component etile_eth_1x100g;

    -- 25g4
    component etile_eth_4x25g is
    generic (
        am_encoding40g_0              : integer := 9467463;
        am_encoding40g_1              : integer := 15779046;
        am_encoding40g_2              : integer := 12936603;
        am_encoding40g_3              : integer := 10647869;
        enforce_max_frame_size        : string  := "disable";
        flow_control                  : string  := "both_no_xoff";
        flow_control_holdoff_mode     : string  := "uniform";
        forward_rx_pause_requests     : string  := "disable";
        hi_ber_monitor                : string  := "enable";
        holdoff_quanta                : integer := 65535;
        ipg_removed_per_am_period     : integer := 20;
        link_fault_mode               : string  := "lf_bidir";
        pause_quanta                  : integer := 65535;
        pfc_holdoff_quanta_0          : integer := 32768;
        pfc_holdoff_quanta_1          : integer := 32768;
        pfc_holdoff_quanta_2          : integer := 32768;
        pfc_holdoff_quanta_3          : integer := 32768;
        pfc_holdoff_quanta_4          : integer := 32768;
        pfc_holdoff_quanta_5          : integer := 32768;
        pfc_holdoff_quanta_6          : integer := 32768;
        pfc_holdoff_quanta_7          : integer := 32768;
        pfc_pause_quanta_0            : integer := 65535;
        pfc_pause_quanta_1            : integer := 65535;
        pfc_pause_quanta_2            : integer := 65535;
        pfc_pause_quanta_3            : integer := 65535;
        pfc_pause_quanta_4            : integer := 65535;
        pfc_pause_quanta_5            : integer := 65535;
        pfc_pause_quanta_6            : integer := 65535;
        pfc_pause_quanta_7            : integer := 65535;
        remove_pads                   : string  := "disable";
        rx_length_checking            : string  := "disable";
        rx_max_frame_size             : integer := 16383;
        rx_pause_daddr                : string  := "17483607389996";
        rx_pcs_max_skew               : integer := 47;
        rx_vlan_detection             : string  := "disable";
        rxcrc_covers_preamble         : string  := "disable";
        sim_mode                      : string  := "enable";
        source_address_insertion      : string  := "disable";
        strict_preamble_checking      : string  := "disable";
        strict_sfd_checking           : string  := "disable";
        tx_ipg_size                   : string  := "ipg_12";
        tx_max_frame_size             : integer := 16383;
        tx_pause_daddr                : string  := "1652522221569";
        tx_pause_saddr                : string  := "73588229205";
        tx_pld_fifo_almost_full_level : integer := 16;
        tx_vlan_detection             : string  := "disable";
        txcrc_covers_preamble         : string  := "disable";
        txmac_saddr                   : string  := "73588229205";
        uniform_holdoff_quanta        : integer := 51090;
        flow_control_sl_0             : string  := "both_no_xoff"
    );
    port (
        o_cdr_lock                       : out std_logic_vector(3 downto 0);                      -- o_cdr_lock
        o_tx_pll_locked                  : out std_logic_vector(3 downto 0);                      -- o_tx_pll_locked
        i_rsfec_reconfig_addr            : in  std_logic_vector(10 downto 0)  := (others => 'X'); -- i_rsfec_reconfig_addr
        i_rsfec_reconfig_read            : in  std_logic                      := 'X';             -- i_rsfec_reconfig_read
        i_rsfec_reconfig_write           : in  std_logic                      := 'X';             -- i_rsfec_reconfig_write
        o_rsfec_reconfig_readdata        : out std_logic_vector(7 downto 0);                      -- o_rsfec_reconfig_readdata
        i_rsfec_reconfig_writedata       : in  std_logic_vector(7 downto 0)   := (others => 'X'); -- i_rsfec_reconfig_writedata
        o_rsfec_reconfig_waitrequest     : out std_logic;                                         -- o_rsfec_reconfig_waitrequest
        i_clk_ref                        : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- i_clk_ref
        o_clk_pll_div64                  : out std_logic_vector(3 downto 0);                      -- o_clk_pll_div64
        o_clk_pll_div66                  : out std_logic_vector(3 downto 0);                      -- o_clk_pll_div66
        o_clk_rec_div64                  : out std_logic_vector(3 downto 0);                      -- o_clk_rec_div64
        o_clk_rec_div66                  : out std_logic_vector(3 downto 0);                      -- o_clk_rec_div66
        o_tx_serial                      : out std_logic_vector(3 downto 0);                      -- o_tx_serial
        i_rx_serial                      : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- i_rx_serial
        o_tx_serial_n                    : out std_logic_vector(3 downto 0);                      -- o_tx_serial_n
        i_rx_serial_n                    : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- i_rx_serial_n
        i_reconfig_clk                   : in  std_logic                      := 'X';             -- clk
        i_reconfig_reset                 : in  std_logic                      := 'X';             -- i_reconfig_reset
        i_xcvr_reconfig_address          : in  std_logic_vector(75 downto 0)  := (others => 'X'); -- i_xcvr_reconfig_address
        i_xcvr_reconfig_read             : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- i_xcvr_reconfig_read
        i_xcvr_reconfig_write            : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- i_xcvr_reconfig_write
        o_xcvr_reconfig_readdata         : out std_logic_vector(31 downto 0);                     -- o_xcvr_reconfig_readdata
        i_xcvr_reconfig_writedata        : in  std_logic_vector(31 downto 0)  := (others => 'X'); -- i_xcvr_reconfig_writedata
        o_xcvr_reconfig_waitrequest      : out std_logic_vector(3 downto 0);                      -- o_xcvr_reconfig_waitrequest
        i_sl_stats_snapshot              : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- i_sl_stats_snapshot
        o_sl_rx_hi_ber                   : out std_logic_vector(3 downto 0);                      -- o_sl_rx_hi_ber
        i_sl_eth_reconfig_addr           : in  std_logic_vector(75 downto 0)  := (others => 'X'); -- i_sl_eth_reconfig_addr
        i_sl_eth_reconfig_read           : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- i_sl_eth_reconfig_read
        i_sl_eth_reconfig_write          : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- i_sl_eth_reconfig_write
        o_sl_eth_reconfig_readdata       : out std_logic_vector(127 downto 0);                    -- o_sl_eth_reconfig_readdata
        o_sl_eth_reconfig_readdata_valid : out std_logic_vector(3 downto 0);                      -- o_sl_eth_reconfig_readdata_valid
        i_sl_eth_reconfig_writedata      : in  std_logic_vector(127 downto 0) := (others => 'X'); -- i_sl_eth_reconfig_writedata
        o_sl_eth_reconfig_waitrequest    : out std_logic_vector(3 downto 0);                      -- o_sl_eth_reconfig_waitrequest
        o_sl_tx_lanes_stable             : out std_logic_vector(3 downto 0);                      -- o_sl_tx_lanes_stable
        o_sl_rx_pcs_ready                : out std_logic_vector(3 downto 0);                      -- o_sl_rx_pcs_ready
        o_sl_ehip_ready                  : out std_logic_vector(3 downto 0);                      -- o_sl_ehip_ready
        o_sl_rx_block_lock               : out std_logic_vector(3 downto 0);                      -- o_sl_rx_block_lock
        o_sl_local_fault_status          : out std_logic_vector(3 downto 0);                      -- o_sl_local_fault_status
        o_sl_remote_fault_status         : out std_logic_vector(3 downto 0);                      -- o_sl_remote_fault_status
        i_sl_clk_tx                      : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- i_sl_clk_tx
        i_sl_clk_rx                      : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- i_sl_clk_rx
        i_sl_csr_rst_n                   : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- i_sl_csr_rst_n
        i_sl_tx_rst_n                    : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- i_sl_tx_rst_n
        i_sl_rx_rst_n                    : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- i_sl_rx_rst_n
        o_sl_txfifo_pfull                : out std_logic_vector(3 downto 0);                      -- o_sl_txfifo_pfull
        o_sl_txfifo_pempty               : out std_logic_vector(3 downto 0);                      -- o_sl_txfifo_pempty
        o_sl_txfifo_overflow             : out std_logic_vector(3 downto 0);                      -- o_sl_txfifo_overflow
        o_sl_txfifo_underflow            : out std_logic_vector(3 downto 0);                      -- o_sl_txfifo_underflow
        o_sl_tx_ready                    : out std_logic_vector(3 downto 0);                      -- o_sl_tx_ready
        o_sl_rx_valid                    : out std_logic_vector(3 downto 0);                      -- o_sl_rx_valid
        i_sl_tx_valid                    : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- i_sl_tx_valid
        i_sl_tx_data                     : in  std_logic_vector(255 downto 0) := (others => 'X'); -- i_sl_tx_data
        o_sl_rx_data                     : out std_logic_vector(255 downto 0);                    -- o_sl_rx_data
        i_sl_tx_error                    : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- i_sl_tx_error
        i_sl_tx_startofpacket            : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- i_sl_tx_startofpacket
        i_sl_tx_endofpacket              : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- i_sl_tx_endofpacket
        i_sl_tx_empty                    : in  std_logic_vector(11 downto 0)  := (others => 'X'); -- i_sl_tx_empty
        i_sl_tx_skip_crc                 : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- i_sl_tx_skip_crc
        o_sl_rx_startofpacket            : out std_logic_vector(3 downto 0);                      -- o_sl_rx_startofpacket
        o_sl_rx_endofpacket              : out std_logic_vector(3 downto 0);                      -- o_sl_rx_endofpacket
        o_sl_rx_empty                    : out std_logic_vector(11 downto 0);                     -- o_sl_rx_empty
        o_sl_rx_error                    : out std_logic_vector(23 downto 0);                     -- o_sl_rx_error
        o_sl_rxstatus_data               : out std_logic_vector(159 downto 0);                    -- o_sl_rxstatus_data
        o_sl_rxstatus_valid              : out std_logic_vector(3 downto 0);                      -- o_sl_rxstatus_valid
        i_sl_tx_pfc                      : in  std_logic_vector(31 downto 0)  := (others => 'X'); -- i_sl_tx_pfc
        o_sl_rx_pfc                      : out std_logic_vector(31 downto 0);                     -- o_sl_rx_pfc
        i_sl_tx_pause                    : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- i_sl_tx_pause
        o_sl_rx_pause                    : out std_logic_vector(3 downto 0)                       -- o_sl_rx_pause
    );
    end component etile_eth_4x25g;

    -- 10g4
    component etile_eth_4x10g is
    generic (
        am_encoding40g_0              : integer := 9467463;
        am_encoding40g_1              : integer := 15779046;
        am_encoding40g_2              : integer := 12936603;
        am_encoding40g_3              : integer := 10647869;
        enforce_max_frame_size        : string  := "disable";
        flow_control                  : string  := "both_no_xoff";
        flow_control_holdoff_mode     : string  := "per_queue";
        forward_rx_pause_requests     : string  := "disable";
        hi_ber_monitor                : string  := "enable";
        holdoff_quanta                : integer := 65535;
        ipg_removed_per_am_period     : integer := 20;
        link_fault_mode               : string  := "lf_bidir";
        pause_quanta                  : integer := 65535;
        pfc_holdoff_quanta_0          : integer := 32768;
        pfc_holdoff_quanta_1          : integer := 32768;
        pfc_holdoff_quanta_2          : integer := 32768;
        pfc_holdoff_quanta_3          : integer := 32768;
        pfc_holdoff_quanta_4          : integer := 32768;
        pfc_holdoff_quanta_5          : integer := 32768;
        pfc_holdoff_quanta_6          : integer := 32768;
        pfc_holdoff_quanta_7          : integer := 32768;
        pfc_pause_quanta_0            : integer := 65535;
        pfc_pause_quanta_1            : integer := 65535;
        pfc_pause_quanta_2            : integer := 65535;
        pfc_pause_quanta_3            : integer := 65535;
        pfc_pause_quanta_4            : integer := 65535;
        pfc_pause_quanta_5            : integer := 65535;
        pfc_pause_quanta_6            : integer := 65535;
        pfc_pause_quanta_7            : integer := 65535;
        remove_pads                   : string  := "disable";
        rx_length_checking            : string  := "enable";
        rx_max_frame_size             : integer := 16383;
        rx_pause_daddr                : string  := "1652522221569";
        rx_pcs_max_skew               : integer := 47;
        rx_vlan_detection             : string  := "disable";
        rxcrc_covers_preamble         : string  := "disable";
        sim_mode                      : string  := "enable";
        source_address_insertion      : string  := "disable";
        strict_preamble_checking      : string  := "disable";
        strict_sfd_checking           : string  := "disable";
        tx_ipg_size                   : string  := "ipg_12";
        tx_max_frame_size             : integer := 16383;
        tx_pause_daddr                : string  := "1652522221569";
        tx_pause_saddr                : string  := "73588229205";
        tx_pld_fifo_almost_full_level : integer := 16;
        tx_vlan_detection             : string  := "disable";
        txcrc_covers_preamble         : string  := "disable";
        txmac_saddr                   : string  := "73588229205";
        uniform_holdoff_quanta        : integer := 65535;
        flow_control_sl_0             : string  := "both_no_xoff"
    );
    port (
        o_cdr_lock                       : out std_logic_vector(3 downto 0);                      -- o_cdr_lock
        o_tx_pll_locked                  : out std_logic_vector(3 downto 0);                      -- o_tx_pll_locked
        i_clk_ref                        : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- i_clk_ref
        o_clk_pll_div64                  : out std_logic_vector(3 downto 0);                      -- o_clk_pll_div64
        o_clk_pll_div66                  : out std_logic_vector(3 downto 0);                      -- o_clk_pll_div66
        o_clk_rec_div64                  : out std_logic_vector(3 downto 0);                      -- o_clk_rec_div64
        o_clk_rec_div66                  : out std_logic_vector(3 downto 0);                      -- o_clk_rec_div66
        o_tx_serial                      : out std_logic_vector(3 downto 0);                      -- o_tx_serial
        i_rx_serial                      : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- i_rx_serial
        o_tx_serial_n                    : out std_logic_vector(3 downto 0);                      -- o_tx_serial_n
        i_rx_serial_n                    : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- i_rx_serial_n
        i_reconfig_clk                   : in  std_logic                      := 'X';             -- clk
        i_reconfig_reset                 : in  std_logic                      := 'X';             -- i_reconfig_reset
        i_xcvr_reconfig_address          : in  std_logic_vector(75 downto 0)  := (others => 'X'); -- i_xcvr_reconfig_address
        i_xcvr_reconfig_read             : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- i_xcvr_reconfig_read
        i_xcvr_reconfig_write            : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- i_xcvr_reconfig_write
        o_xcvr_reconfig_readdata         : out std_logic_vector(31 downto 0);                     -- o_xcvr_reconfig_readdata
        i_xcvr_reconfig_writedata        : in  std_logic_vector(31 downto 0)  := (others => 'X'); -- i_xcvr_reconfig_writedata
        o_xcvr_reconfig_waitrequest      : out std_logic_vector(3 downto 0);                      -- o_xcvr_reconfig_waitrequest
        i_sl_stats_snapshot              : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- i_sl_stats_snapshot
        o_sl_rx_hi_ber                   : out std_logic_vector(3 downto 0);                      -- o_sl_rx_hi_ber
        i_sl_eth_reconfig_addr           : in  std_logic_vector(75 downto 0)  := (others => 'X'); -- i_sl_eth_reconfig_addr
        i_sl_eth_reconfig_read           : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- i_sl_eth_reconfig_read
        i_sl_eth_reconfig_write          : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- i_sl_eth_reconfig_write
        o_sl_eth_reconfig_readdata       : out std_logic_vector(127 downto 0);                    -- o_sl_eth_reconfig_readdata
        o_sl_eth_reconfig_readdata_valid : out std_logic_vector(3 downto 0);                      -- o_sl_eth_reconfig_readdata_valid
        i_sl_eth_reconfig_writedata      : in  std_logic_vector(127 downto 0) := (others => 'X'); -- i_sl_eth_reconfig_writedata
        o_sl_eth_reconfig_waitrequest    : out std_logic_vector(3 downto 0);                      -- o_sl_eth_reconfig_waitrequest
        o_sl_tx_lanes_stable             : out std_logic_vector(3 downto 0);                      -- o_sl_tx_lanes_stable
        o_sl_rx_pcs_ready                : out std_logic_vector(3 downto 0);                      -- o_sl_rx_pcs_ready
        o_sl_ehip_ready                  : out std_logic_vector(3 downto 0);                      -- o_sl_ehip_ready
        o_sl_rx_block_lock               : out std_logic_vector(3 downto 0);                      -- o_sl_rx_block_lock
        o_sl_local_fault_status          : out std_logic_vector(3 downto 0);                      -- o_sl_local_fault_status
        o_sl_remote_fault_status         : out std_logic_vector(3 downto 0);                      -- o_sl_remote_fault_status
        i_sl_clk_tx                      : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- i_sl_clk_tx
        i_sl_clk_rx                      : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- i_sl_clk_rx
        i_sl_csr_rst_n                   : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- i_sl_csr_rst_n
        i_sl_tx_rst_n                    : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- i_sl_tx_rst_n
        i_sl_rx_rst_n                    : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- i_sl_rx_rst_n
        o_sl_txfifo_pfull                : out std_logic_vector(3 downto 0);                      -- o_sl_txfifo_pfull
        o_sl_txfifo_pempty               : out std_logic_vector(3 downto 0);                      -- o_sl_txfifo_pempty
        o_sl_txfifo_overflow             : out std_logic_vector(3 downto 0);                      -- o_sl_txfifo_overflow
        o_sl_txfifo_underflow            : out std_logic_vector(3 downto 0);                      -- o_sl_txfifo_underflow
        o_sl_tx_ready                    : out std_logic_vector(3 downto 0);                      -- o_sl_tx_ready
        o_sl_rx_valid                    : out std_logic_vector(3 downto 0);                      -- o_sl_rx_valid
        i_sl_tx_valid                    : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- i_sl_tx_valid
        i_sl_tx_data                     : in  std_logic_vector(255 downto 0) := (others => 'X'); -- i_sl_tx_data
        o_sl_rx_data                     : out std_logic_vector(255 downto 0);                    -- o_sl_rx_data
        i_sl_tx_error                    : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- i_sl_tx_error
        i_sl_tx_startofpacket            : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- i_sl_tx_startofpacket
        i_sl_tx_endofpacket              : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- i_sl_tx_endofpacket
        i_sl_tx_empty                    : in  std_logic_vector(11 downto 0)  := (others => 'X'); -- i_sl_tx_empty
        i_sl_tx_skip_crc                 : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- i_sl_tx_skip_crc
        o_sl_rx_startofpacket            : out std_logic_vector(3 downto 0);                      -- o_sl_rx_startofpacket
        o_sl_rx_endofpacket              : out std_logic_vector(3 downto 0);                      -- o_sl_rx_endofpacket
        o_sl_rx_empty                    : out std_logic_vector(11 downto 0);                     -- o_sl_rx_empty
        o_sl_rx_error                    : out std_logic_vector(23 downto 0);                     -- o_sl_rx_error
        o_sl_rxstatus_data               : out std_logic_vector(159 downto 0);                    -- o_sl_rxstatus_data
        o_sl_rxstatus_valid              : out std_logic_vector(3 downto 0);                      -- o_sl_rxstatus_valid
        i_sl_tx_pfc                      : in  std_logic_vector(31 downto 0)  := (others => 'X'); -- i_sl_tx_pfc
        o_sl_rx_pfc                      : out std_logic_vector(31 downto 0);                     -- o_sl_rx_pfc
        i_sl_tx_pause                    : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- i_sl_tx_pause
        o_sl_rx_pause                    : out std_logic_vector(3 downto 0)                       -- o_sl_rx_pause
    );
    end component etile_eth_4x10g;

    -- =========================================================================
    --                               CONSTANTS
    -- =========================================================================
    -- constant LANES_PER_CHANNEL : natural := LANES/ETH_CHANNELS;

    constant MFB2AVST_FIFO_DEPTH    : natural := 512;

    -- AVST interface:
    constant AVST_DATA_WIDTH        : natural := tsel(ETH_PORT_SPEED = 100, 512, 64); -- 512 bits for "100g1" mode (one channel), 64 bits per channel for modes "25g4" and "10g4"
    constant AVST_EMPTY_WIDTH       : natural := tsel(ETH_PORT_SPEED = 100, 6  , 3 ); -- 6   bits for "100g1" mode (one channel), 3  bits per channel for modes "25g4" and "10g4"
    -- 6 bits per channel, it is not ETH_PORT_SPEED dependent
    constant RX_AVST_ERROR_WIDTH    : natural := 6;

    -- Number of MI Indirect Access' output interfaces
    --                                           eth inf       + xcvr inf + rsfec in case of 100g1 or 25g4
    constant IA_OUTPUT_INFS         : natural := ETH_PORT_CHAN + LANES    + tsel(ETH_PORT_SPEED = 10, 0, 1);

    -- =========================================================================
    --                                SIGNALS
    -- =========================================================================
    signal etile_clk_out_vec      : std_logic_vector(ETH_PORT_CHAN-1 downto 0); -- in case of multiple IP cores, only one is chosen
    signal etile_clk_out          : std_logic; -- drives i_clk_rx and i_clk_tx of one or more other IP cores

    signal tx_avst_data      : std_logic_vector(ETH_PORT_CHAN*AVST_DATA_WIDTH -1 downto 0);
    signal tx_avst_sop       : std_logic_vector(ETH_PORT_CHAN                 -1 downto 0);
    signal tx_avst_eop       : std_logic_vector(ETH_PORT_CHAN                 -1 downto 0);
    signal tx_avst_empty     : std_logic_vector(ETH_PORT_CHAN*AVST_EMPTY_WIDTH-1 downto 0);
    signal tx_avst_error     : std_logic_vector(ETH_PORT_CHAN                 -1 downto 0);
    signal tx_avst_valid     : std_logic_vector(ETH_PORT_CHAN                 -1 downto 0);
    signal tx_avst_ready     : std_logic_vector(ETH_PORT_CHAN                 -1 downto 0);

    signal tx_avst_data_arr  : slv_array_t(ETH_PORT_CHAN-1 downto 0)(AVST_DATA_WIDTH -1 downto 0);
    signal tx_avst_empty_arr : slv_array_t(ETH_PORT_CHAN-1 downto 0)(AVST_EMPTY_WIDTH-1 downto 0);

    signal rx_avst_data_arr  : slv_array_t(ETH_PORT_CHAN-1 downto 0)(AVST_DATA_WIDTH    -1 downto 0);
    signal rx_avst_empty_arr : slv_array_t(ETH_PORT_CHAN-1 downto 0)(AVST_EMPTY_WIDTH   -1 downto 0);
    signal rx_avst_error_arr : slv_array_t(ETH_PORT_CHAN-1 downto 0)(RX_AVST_ERROR_WIDTH-1 downto 0);

    signal rx_avst_data      : std_logic_vector(ETH_PORT_CHAN*AVST_DATA_WIDTH    -1 downto 0);
    signal rx_avst_valid     : std_logic_vector(ETH_PORT_CHAN                    -1 downto 0);
    signal rx_avst_sop       : std_logic_vector(ETH_PORT_CHAN                    -1 downto 0);
    signal rx_avst_eop       : std_logic_vector(ETH_PORT_CHAN                    -1 downto 0);
    signal rx_avst_empty     : std_logic_vector(ETH_PORT_CHAN*AVST_EMPTY_WIDTH   -1 downto 0);
    signal rx_avst_error     : std_logic_vector(ETH_PORT_CHAN*RX_AVST_ERROR_WIDTH-1 downto 0);

    -- Status signals
    signal rx_pcs_ready      : std_logic_vector(ETH_PORT_CHAN-1 downto 0);
    signal rx_block_lock     : std_logic_vector(ETH_PORT_CHAN-1 downto 0);
    signal rx_am_lock        : std_logic_vector(ETH_PORT_CHAN-1 downto 0);
    signal tx_lanes_stable   : std_logic_vector(ETH_PORT_CHAN-1 downto 0);

    -- MI_PHY for E-tile reconfiguration interfaces (Ethernet, Transceiver (XCVR), RS-FEC)
    -- from MI Indirect Access (-> mi_ia_)
    signal mi_ia_dwr_phy  : slv_array_t     (IA_OUTPUT_INFS-1 downto 0)(MI_DATA_WIDTH_PHY-1 downto 0);
    signal mi_ia_addr_phy : slv_array_t     (IA_OUTPUT_INFS-1 downto 0)(MI_ADDR_WIDTH_PHY-1 downto 0);
    signal mi_ia_rd_phy   : std_logic_vector(IA_OUTPUT_INFS-1 downto 0);
    signal mi_ia_wr_phy   : std_logic_vector(IA_OUTPUT_INFS-1 downto 0);
    signal mi_ia_ardy_phy : std_logic_vector(IA_OUTPUT_INFS-1 downto 0);
    signal mi_ia_drd_phy  : slv_array_t     (IA_OUTPUT_INFS-1 downto 0)(MI_DATA_WIDTH_PHY-1 downto 0);
    signal mi_ia_drdy_phy : std_logic_vector(IA_OUTPUT_INFS-1 downto 0);
    -- eth reconfig interface
    signal eth_inf_dwr_phy          : slv_array_t     (ETH_PORT_CHAN-1 downto 0)(MI_DATA_WIDTH_PHY-1 downto 0);
    signal eth_inf_dwr_phy_ser      : std_logic_vector(ETH_PORT_CHAN*            MI_DATA_WIDTH_PHY-1 downto 0);
    signal eth_inf_addr_phy         : slv_array_t     (ETH_PORT_CHAN-1 downto 0)(MI_ADDR_WIDTH_PHY-1 downto 0);
    signal eth_inf_addr_phy_res     : slv_array_t     (ETH_PORT_CHAN-1 downto 0)(tsel(ETH_PORT_SPEED = 100, 21, 19)-1 downto 0);
    signal eth_inf_addr_phy_res_ser : std_logic_vector(ETH_PORT_CHAN*            tsel(ETH_PORT_SPEED = 100, 21, 19)-1 downto 0);
    signal eth_inf_rd_phy           : std_logic_vector(ETH_PORT_CHAN-1 downto 0);
    signal eth_inf_wr_phy           : std_logic_vector(ETH_PORT_CHAN-1 downto 0);
    signal eth_inf_ardy_phy_n       : std_logic_vector(ETH_PORT_CHAN-1 downto 0);
    signal eth_inf_drd_phy          : slv_array_t     (ETH_PORT_CHAN-1 downto 0)(MI_DATA_WIDTH_PHY-1 downto 0);
    signal eth_inf_drd_phy_ser      : std_logic_vector(ETH_PORT_CHAN*            MI_DATA_WIDTH_PHY-1 downto 0);
    signal eth_inf_drdy_phy         : std_logic_vector(ETH_PORT_CHAN-1 downto 0);
    -- xcvr reconfig interface
    signal xcvr_inf_dwr_phy          : slv_array_t     (LANES-1 downto 0)(MI_DATA_WIDTH_PHY-1 downto 0);
    signal xcvr_inf_dwr_phy_res      : slv_array_t     (LANES-1 downto 0)(8                -1 downto 0);
    signal xcvr_inf_dwr_phy_res_ser  : std_logic_vector(LANES*            8                -1 downto 0);
    signal xcvr_inf_addr_phy         : slv_array_t     (LANES-1 downto 0)(MI_ADDR_WIDTH_PHY-1 downto 0);
    signal xcvr_inf_addr_phy_res     : slv_array_t     (LANES-1 downto 0)(19-1 downto 0);
    signal xcvr_inf_addr_phy_res_ser : std_logic_vector(LANES*            19-1 downto 0);
    signal xcvr_inf_rd_phy           : std_logic_vector(LANES-1 downto 0);
    signal xcvr_inf_wr_phy           : std_logic_vector(LANES-1 downto 0);
    signal xcvr_inf_ardy_phy_n       : std_logic_vector(LANES-1 downto 0);
    signal xcvr_inf_drd_phy          : slv_array_t     (LANES-1 downto 0)(MI_DATA_WIDTH_PHY-1 downto 0);
    signal xcvr_inf_drd_phy_res      : slv_array_t     (LANES-1 downto 0)(8                -1 downto 0);
    signal xcvr_inf_drd_phy_res_ser  : std_logic_vector(LANES*            8                -1 downto 0);
    -- rsfec reconfig interface
    signal rsfec_inf_dwr_phy      : std_logic_vector(MI_DATA_WIDTH_PHY-1 downto 0);
    signal rsfec_inf_dwr_phy_res  : std_logic_vector(8                -1 downto 0);
    signal rsfec_inf_addr_phy     : std_logic_vector(MI_ADDR_WIDTH_PHY-1 downto 0);
    signal rsfec_inf_addr_phy_res : std_logic_vector(11               -1 downto 0);
    signal rsfec_inf_rd_phy       : std_logic;
    signal rsfec_inf_wr_phy       : std_logic;
    signal rsfec_inf_ardy_phy_n   : std_logic;
    signal rsfec_inf_drd_phy      : std_logic_vector(MI_DATA_WIDTH_PHY-1 downto 0);
    signal rsfec_inf_drd_phy_res  : std_logic_vector(8                -1 downto 0);

begin

    -- =========================================================================
    -- MI_PHY Indirect Access
    -- =========================================================================
    -- How to set the Output interface in MI Indirect Access: 
    -- ETH_PORT_CHAN=1: "0x0"         for Ethernet inf, "0x4" - "0x1" for Transceiver (XCVR) inf, "0x5" for RS-FEC inf
    -- ETH_PORT_CHAN=4: "0x3" - "0x0" for Ethernet inf, "0x7" - "0x4" for Transceiver (XCVR) inf, "0x8" for RS-FEC inf (RS-FEC does not exist in 10GE IP core!)
    mi_indirect_access_i : entity work.MI_INDIRECT_ACCESS
    generic map(
        ADDR_WIDTH        => MI_ADDR_WIDTH_PHY,
        DATA_WIDTH        => MI_DATA_WIDTH_PHY,
        OUTPUT_INTERFACES => IA_OUTPUT_INFS
    )
    port map(
        -- Common interface ----------------------------------------------------
        CLK         => MI_CLK_PHY  ,
        RESET       => MI_RESET_PHY,
        -- Input MI interface --------------------------------------------------
        RX_DWR      => MI_DWR_PHY     ,
        RX_ADDR     => MI_ADDR_PHY    ,
        RX_RD       => MI_RD_PHY      ,
        RX_WR       => MI_WR_PHY      ,
        RX_ARDY     => MI_ARDY_PHY    ,
        RX_DRD      => MI_DRD_PHY     ,
        RX_DRDY     => MI_DRDY_PHY    ,
        -- Output MI interfaces ------------------------------------------------
        TX_DWR     => mi_ia_dwr_phy ,
        TX_ADDR    => mi_ia_addr_phy,
        TX_RD      => mi_ia_rd_phy  ,
        TX_WR      => mi_ia_wr_phy  ,
        TX_ARDY    => mi_ia_ardy_phy,
        TX_DRD     => mi_ia_drd_phy ,
        TX_DRDY    => mi_ia_drdy_phy
    );

    -- eth ---------------------------------------------------------------------
    eth_inf_dwr_phy  <= mi_ia_dwr_phy (ETH_PORT_CHAN-1 downto 0);
    eth_inf_addr_phy <= mi_ia_addr_phy(ETH_PORT_CHAN-1 downto 0);
    eth_inf_rd_phy   <= mi_ia_rd_phy  (ETH_PORT_CHAN-1 downto 0);
    eth_inf_wr_phy   <= mi_ia_wr_phy  (ETH_PORT_CHAN-1 downto 0);
    mi_ia_ardy_phy(ETH_PORT_CHAN-1 downto 0) <= not eth_inf_ardy_phy_n;
    mi_ia_drd_phy (ETH_PORT_CHAN-1 downto 0) <= eth_inf_drd_phy ;
    mi_ia_drdy_phy(ETH_PORT_CHAN-1 downto 0) <= eth_inf_drdy_phy;

    eth_inf_res_g: for i in ETH_PORT_CHAN-1 downto 0 generate
        eth_inf_addr_phy_res(i) <= eth_inf_addr_phy(i)(tsel(ETH_PORT_SPEED = 100, 21, 19)-1 downto 0);
    end generate;

    eth_inf_dwr_phy_ser      <= slv_array_ser(eth_inf_dwr_phy);
    eth_inf_addr_phy_res_ser <= slv_array_ser(eth_inf_addr_phy_res);
    eth_inf_drd_phy <= slv_array_deser(eth_inf_drd_phy_ser, ETH_PORT_CHAN);

    -- xcvr --------------------------------------------------------------------
    xcvr_inf_dwr_phy  <= mi_ia_dwr_phy (LANES + ETH_PORT_CHAN-1 downto ETH_PORT_CHAN);
    xcvr_inf_addr_phy <= mi_ia_addr_phy(LANES + ETH_PORT_CHAN-1 downto ETH_PORT_CHAN);
    xcvr_inf_rd_phy   <= mi_ia_rd_phy  (LANES + ETH_PORT_CHAN-1 downto ETH_PORT_CHAN);
    xcvr_inf_wr_phy   <= mi_ia_wr_phy  (LANES + ETH_PORT_CHAN-1 downto ETH_PORT_CHAN);
    mi_ia_ardy_phy(LANES + ETH_PORT_CHAN-1 downto ETH_PORT_CHAN) <= not xcvr_inf_ardy_phy_n;
    mi_ia_drd_phy (LANES + ETH_PORT_CHAN-1 downto ETH_PORT_CHAN) <= xcvr_inf_drd_phy;

    xcvr_reconfig_inf_res_g: for i in LANES-1 downto 0 generate
        mi_ia_drdy_phy(i + ETH_PORT_CHAN) <= xcvr_inf_rd_phy(i) and not xcvr_inf_ardy_phy_n(i); -- DRDY not used on the xcvr inf

        xcvr_inf_dwr_phy_res (i) <= xcvr_inf_dwr_phy (i)(8 -1 downto 0);
        xcvr_inf_addr_phy_res(i) <= xcvr_inf_addr_phy(i)(19-1 downto 0);
        xcvr_inf_drd_phy(i) <= (8-1 downto 0 => xcvr_inf_drd_phy_res(i), others => '0');
    end generate;

    xcvr_inf_dwr_phy_res_ser  <= slv_array_ser(xcvr_inf_dwr_phy_res);
    xcvr_inf_addr_phy_res_ser <= slv_array_ser(xcvr_inf_addr_phy_res);
    xcvr_inf_drd_phy_res <= slv_array_deser(xcvr_inf_drd_phy_res_ser, LANES);

    -- rsfec -------------------------------------------------------------------
    rsfec_inf_g: if (ETH_PORT_SPEED /= 10) generate
        -- rsfec inf is on the last Output port of MI IA
        rsfec_inf_dwr_phy  <= mi_ia_dwr_phy (IA_OUTPUT_INFS-1);
        rsfec_inf_addr_phy <= mi_ia_addr_phy(IA_OUTPUT_INFS-1);
        rsfec_inf_rd_phy   <= mi_ia_rd_phy  (IA_OUTPUT_INFS-1);
        rsfec_inf_wr_phy   <= mi_ia_wr_phy  (IA_OUTPUT_INFS-1);
        mi_ia_ardy_phy(IA_OUTPUT_INFS-1) <= not rsfec_inf_ardy_phy_n;
        mi_ia_drd_phy (IA_OUTPUT_INFS-1) <= rsfec_inf_drd_phy;
        mi_ia_drdy_phy(IA_OUTPUT_INFS-1) <= rsfec_inf_rd_phy and not rsfec_inf_ardy_phy_n; -- DRDY not used on the rsfec inf

        rsfec_inf_dwr_phy_res  <= rsfec_inf_dwr_phy (8 -1 downto 0);
        rsfec_inf_addr_phy_res <= rsfec_inf_addr_phy(11-1 downto 0);
        rsfec_inf_drd_phy <= (8-1 downto 0 => rsfec_inf_drd_phy_res, others => '0');
    end generate;

    -- =========================================================================
    -- The actual core
    -- =========================================================================
    eth_port_speed_sel_g : case ETH_PORT_SPEED generate

        when 100 =>

            etile_clk_out <= etile_clk_out_vec(0);
            CLK_ETH       <= etile_clk_out;

            -- =========================================================================
            -- E-TILE Ethernet
            -- =========================================================================
            etile_eth_ip_i : component etile_eth_1x100g
            generic map (
                am_encoding40g_0              => 9467463,
                am_encoding40g_1              => 15779046,
                am_encoding40g_2              => 12936603,
                am_encoding40g_3              => 10647869,
                enforce_max_frame_size        => "disable",
                flow_control                  => "both_no_xoff",
                flow_control_holdoff_mode     => "uniform",
                forward_rx_pause_requests     => "disable",
                hi_ber_monitor                => "enable",
                holdoff_quanta                => 65535,
                ipg_removed_per_am_period     => 20,
                link_fault_mode               => "lf_bidir", --"lf_off",
                pause_quanta                  => 65535,
                pfc_holdoff_quanta_0          => 65535,
                pfc_holdoff_quanta_1          => 65535,
                pfc_holdoff_quanta_2          => 65535,
                pfc_holdoff_quanta_3          => 65535,
                pfc_holdoff_quanta_4          => 65535,
                pfc_holdoff_quanta_5          => 65535,
                pfc_holdoff_quanta_6          => 65535,
                pfc_holdoff_quanta_7          => 65535,
                pfc_pause_quanta_0            => 65535,
                pfc_pause_quanta_1            => 65535,
                pfc_pause_quanta_2            => 65535,
                pfc_pause_quanta_3            => 65535,
                pfc_pause_quanta_4            => 65535,
                pfc_pause_quanta_5            => 65535,
                pfc_pause_quanta_6            => 65535,
                pfc_pause_quanta_7            => 65535,
                remove_pads                   => "disable",
                rx_length_checking            => "disable",
                rx_max_frame_size             => 16383,
                rx_pause_daddr                => "17483607389996",
                rx_pcs_max_skew               => 47,
                rx_vlan_detection             => "disable",
                rxcrc_covers_preamble         => "disable",
                sim_mode                      => "enable",
                source_address_insertion      => "disable",
                strict_preamble_checking      => "disable",
                strict_sfd_checking           => "disable",
                tx_ipg_size                   => "ipg_12",
                tx_max_frame_size             => 16383,
                tx_pause_daddr                => "1652522221569",
                tx_pause_saddr                => "247393538562781",
                tx_pld_fifo_almost_full_level => 16,
                tx_vlan_detection             => "disable",
                txcrc_covers_preamble         => "disable",
                txmac_saddr                   => "73588229205",
                uniform_holdoff_quanta        => 51090,
                flow_control_sl_0             => "both_no_xoff"
            )
            port map (
                i_stats_snapshot              => '1',
                o_cdr_lock                    => open,
                o_tx_pll_locked               => open,
                -- Eth reconfig inf (0x0)
                i_eth_reconfig_addr           => eth_inf_addr_phy_res_ser,
                i_eth_reconfig_read           => eth_inf_rd_phy(0),
                i_eth_reconfig_write          => eth_inf_wr_phy(0),
                o_eth_reconfig_readdata       => eth_inf_drd_phy_ser,
                o_eth_reconfig_readdata_valid => eth_inf_drdy_phy(0),
                i_eth_reconfig_writedata      => eth_inf_dwr_phy_ser,
                o_eth_reconfig_waitrequest    => eth_inf_ardy_phy_n(0),
                -- RS-FEC reconfig inf (0x5)
                i_rsfec_reconfig_addr         => rsfec_inf_addr_phy_res,
                i_rsfec_reconfig_read         => rsfec_inf_rd_phy,
                i_rsfec_reconfig_write        => rsfec_inf_wr_phy,
                o_rsfec_reconfig_readdata     => rsfec_inf_drd_phy_res,
                i_rsfec_reconfig_writedata    => rsfec_inf_dwr_phy_res,
                o_rsfec_reconfig_waitrequest  => rsfec_inf_ardy_phy_n,
                o_tx_lanes_stable             => tx_lanes_stable(0),
                o_rx_pcs_ready                => rx_pcs_ready(0),
                o_ehip_ready                  => open,
                o_rx_block_lock               => rx_block_lock(0),
                o_rx_am_lock                  => rx_am_lock(0),
                o_rx_hi_ber                   => open,
                o_local_fault_status          => open,
                o_remote_fault_status         => open,
                i_clk_ref                     => (others => QSFP_REFCLK_P),
                i_clk_tx                      => etile_clk_out,
                i_clk_rx                      => etile_clk_out,
                o_clk_pll_div64               => etile_clk_out_vec, -- o_clk_pll_div64 is reliable only after o_tx_pll_locked is asserted
                o_clk_pll_div66               => open,
                o_clk_rec_div64               => open,
                o_clk_rec_div66               => open,
                i_csr_rst_n                   => not RESET_ETH,
                i_tx_rst_n                    => '1',
                i_rx_rst_n                    => '1',
                o_tx_serial                   => QSFP_TX_P,
                i_rx_serial                   => QSFP_RX_P,
                o_tx_serial_n                 => QSFP_TX_N,
                i_rx_serial_n                 => QSFP_RX_N,
                i_reconfig_clk                => MI_CLK_PHY,
                i_reconfig_reset              => MI_RESET_PHY,
                -- XCVR reconfig inf (0x4 downto 0x1)
                i_xcvr_reconfig_address       => xcvr_inf_addr_phy_res_ser,
                i_xcvr_reconfig_read          => xcvr_inf_rd_phy,
                i_xcvr_reconfig_write         => xcvr_inf_wr_phy,
                o_xcvr_reconfig_readdata      => xcvr_inf_drd_phy_res_ser,
                i_xcvr_reconfig_writedata     => xcvr_inf_dwr_phy_res_ser,
                o_xcvr_reconfig_waitrequest   => xcvr_inf_ardy_phy_n,
                o_tx_ready                    => tx_avst_ready(0),
                i_tx_valid                    => tx_avst_valid(0),
                i_tx_data                     => tx_avst_data,
                i_tx_error                    => tx_avst_error(0),
                i_tx_startofpacket            => tx_avst_sop(0),
                i_tx_endofpacket              => tx_avst_eop(0),
                i_tx_empty                    => tx_avst_empty,
                i_tx_skip_crc                 => '0',
                o_rx_valid                    => rx_avst_valid(0),
                o_rx_data                     => rx_avst_data,
                o_rx_startofpacket            => rx_avst_sop(0),
                o_rx_endofpacket              => rx_avst_eop(0),
                o_rx_empty                    => rx_avst_empty,
                o_rx_error                    => rx_avst_error,
                o_rxstatus_data               => open,
                o_rxstatus_valid              => open,
                i_tx_pfc                      => (others => '0'),
                o_rx_pfc                      => open,
                i_tx_pause                    => '0',
                o_rx_pause                    => open
            );

            process(etile_clk_out)
            begin
                if rising_edge(etile_clk_out) then
                    if (RESET_ETH = '1') then
                        RX_LINK_UP <= (others => '0');
                        TX_LINK_UP <= (others => '0');
                    else
                        RX_LINK_UP <= rx_pcs_ready and rx_block_lock and rx_am_lock;
                        TX_LINK_UP <= tx_lanes_stable;
                    end if;
                end if;
            end process;

            -- =========================================================================
            -- ADAPTERS
            -- =========================================================================
            -- TX adaption
            mfb2avst_i : entity work.TX_MAC_LITE_ADAPTER_AVST_100G
            generic map(
                DATA_WIDTH => AVST_DATA_WIDTH,
                FIFO_DEPTH => MFB2AVST_FIFO_DEPTH,
                DEVICE     => DEVICE
            )
            port map(
                CLK            => etile_clk_out,
                RESET          => RESET_ETH    ,

                RX_MFB_DATA    => RX_MFB_DATA   (0),
                RX_MFB_SOF     => RX_MFB_SOF    (0),
                RX_MFB_SOF_POS => RX_MFB_SOF_POS(0),
                RX_MFB_EOF     => RX_MFB_EOF    (0),
                RX_MFB_EOF_POS => RX_MFB_EOF_POS(0),
                RX_MFB_SRC_RDY => RX_MFB_SRC_RDY(0),
                RX_MFB_DST_RDY => RX_MFB_DST_RDY(0),

                TX_AVST_DATA   => tx_avst_data    ,
                TX_AVST_SOP    => tx_avst_sop  (0),
                TX_AVST_EOP    => tx_avst_eop  (0),
                TX_AVST_EMPTY  => tx_avst_empty   ,
                TX_AVST_ERROR  => tx_avst_error(0),
                TX_AVST_VALID  => tx_avst_valid(0),
                TX_AVST_READY  => tx_avst_ready(0)
            );

            -- RX adaption
            avst2mfb_i : entity work.ETH_AVST_ADAPTER
            generic map(
                DATA_WIDTH     => AVST_DATA_WIDTH,
                TX_REGION_SIZE => AVST_DATA_WIDTH/64
            )
            port map(
                CLK              => etile_clk_out,
                RESET            => RESET_ETH    ,

                IN_AVST_DATA     => rx_avst_data    ,
                IN_AVST_SOP      => rx_avst_sop  (0),
                IN_AVST_EOP      => rx_avst_eop  (0),
                IN_AVST_EMPTY    => rx_avst_empty   ,
                IN_AVST_ERROR    => rx_avst_error   ,
                IN_AVST_VALID    => rx_avst_valid(0),
                IN_RX_PCS_READY  => '0', -- rx_pcs_ready (0)
                IN_RX_BLOCK_LOCK => '0', -- rx_block_lock(0)
                IN_RX_AM_LOCK    => '0', -- rx_am_lock   (0)

                OUT_MFB_DATA     => TX_MFB_DATA   (0),
                OUT_MFB_SOF      => TX_MFB_SOF    (0),
                OUT_MFB_SOF_POS  => TX_MFB_SOF_POS(0),
                OUT_MFB_EOF      => TX_MFB_EOF    (0),
                OUT_MFB_EOF_POS  => TX_MFB_EOF_POS(0),
                OUT_MFB_ERROR    => TX_MFB_ERROR  (0),
                OUT_MFB_SRC_RDY  => TX_MFB_SRC_RDY(0),
                OUT_LINK_UP      => open -- this is done here
            );

        when 25 =>

            etile_clk_out <= etile_clk_out_vec(0);
            CLK_ETH       <= etile_clk_out;

            -- =========================================================================
            -- E-TILE Ethernet
            -- =========================================================================
            etile_eth_ip_i : component etile_eth_4x25g
            generic map (
                am_encoding40g_0              => 9467463,
                am_encoding40g_1              => 15779046,
                am_encoding40g_2              => 12936603,
                am_encoding40g_3              => 10647869,
                enforce_max_frame_size        => "disable",
                flow_control                  => "both_no_xoff",
                flow_control_holdoff_mode     => "uniform",
                forward_rx_pause_requests     => "disable",
                hi_ber_monitor                => "enable",
                holdoff_quanta                => 65535,
                ipg_removed_per_am_period     => 20,
                link_fault_mode               => "lf_bidir",
                pause_quanta                  => 65535,
                pfc_holdoff_quanta_0          => 32768,
                pfc_holdoff_quanta_1          => 32768,
                pfc_holdoff_quanta_2          => 32768,
                pfc_holdoff_quanta_3          => 32768,
                pfc_holdoff_quanta_4          => 32768,
                pfc_holdoff_quanta_5          => 32768,
                pfc_holdoff_quanta_6          => 32768,
                pfc_holdoff_quanta_7          => 32768,
                pfc_pause_quanta_0            => 65535,
                pfc_pause_quanta_1            => 65535,
                pfc_pause_quanta_2            => 65535,
                pfc_pause_quanta_3            => 65535,
                pfc_pause_quanta_4            => 65535,
                pfc_pause_quanta_5            => 65535,
                pfc_pause_quanta_6            => 65535,
                pfc_pause_quanta_7            => 65535,
                remove_pads                   => "disable",
                rx_length_checking            => "disable",
                rx_max_frame_size             => 16383,
                rx_pause_daddr                => "17483607389996",
                rx_pcs_max_skew               => 47,
                rx_vlan_detection             => "disable",
                rxcrc_covers_preamble         => "disable",
                sim_mode                      => "enable",
                source_address_insertion      => "disable",
                strict_preamble_checking      => "disable",
                strict_sfd_checking           => "disable",
                tx_ipg_size                   => "ipg_12",
                tx_max_frame_size             => 16383,
                tx_pause_daddr                => "1652522221569",
                tx_pause_saddr                => "73588229205",
                tx_pld_fifo_almost_full_level => 16,
                tx_vlan_detection             => "disable",
                txcrc_covers_preamble         => "disable",
                txmac_saddr                   => "73588229205",
                uniform_holdoff_quanta        => 51090,
                flow_control_sl_0             => "both_no_xoff"
            )
            port map (
                o_cdr_lock                       => open,
                o_tx_pll_locked                  => open,
                -- RS-FEC reconfig inf (0x8)
                i_rsfec_reconfig_addr            => rsfec_inf_addr_phy_res,
                i_rsfec_reconfig_read            => rsfec_inf_rd_phy,
                i_rsfec_reconfig_write           => rsfec_inf_wr_phy,
                o_rsfec_reconfig_readdata        => rsfec_inf_drd_phy_res,
                i_rsfec_reconfig_writedata       => rsfec_inf_dwr_phy_res,
                o_rsfec_reconfig_waitrequest     => rsfec_inf_ardy_phy_n,
                i_clk_ref                        => (others => QSFP_REFCLK_P),
                o_clk_pll_div64                  => etile_clk_out_vec,
                o_clk_pll_div66                  => open,
                o_clk_rec_div64                  => open,
                o_clk_rec_div66                  => open,
                o_tx_serial                      => QSFP_TX_P,
                i_rx_serial                      => QSFP_RX_P,
                o_tx_serial_n                    => QSFP_TX_N,
                i_rx_serial_n                    => QSFP_RX_N,
                i_reconfig_clk                   => MI_CLK_PHY,
                i_reconfig_reset                 => MI_RESET_PHY,
                -- XCVR reconfig inf (0x7 downto 0x4)
                i_xcvr_reconfig_address          => xcvr_inf_addr_phy_res_ser,
                i_xcvr_reconfig_read             => xcvr_inf_rd_phy,
                i_xcvr_reconfig_write            => xcvr_inf_wr_phy,
                o_xcvr_reconfig_readdata         => xcvr_inf_drd_phy_res_ser,
                i_xcvr_reconfig_writedata        => xcvr_inf_dwr_phy_res_ser,
                o_xcvr_reconfig_waitrequest      => xcvr_inf_ardy_phy_n,
                i_sl_stats_snapshot              => (others => '1'),
                o_sl_rx_hi_ber                   => open, -- enabled in generics
                -- Eth reconfig inf (0x3 downto 0x0)
                i_sl_eth_reconfig_addr           => eth_inf_addr_phy_res_ser,
                i_sl_eth_reconfig_read           => eth_inf_rd_phy,
                i_sl_eth_reconfig_write          => eth_inf_wr_phy,
                o_sl_eth_reconfig_readdata       => eth_inf_drd_phy_ser,
                o_sl_eth_reconfig_readdata_valid => eth_inf_drdy_phy,
                i_sl_eth_reconfig_writedata      => eth_inf_dwr_phy_ser,
                o_sl_eth_reconfig_waitrequest    => eth_inf_ardy_phy_n,
                o_sl_tx_lanes_stable             => open,
                o_sl_rx_pcs_ready                => rx_pcs_ready,
                o_sl_ehip_ready                  => open,
                o_sl_rx_block_lock               => rx_block_lock,
                o_sl_local_fault_status          => open,
                o_sl_remote_fault_status         => open,
                i_sl_clk_tx                      => (others => etile_clk_out),
                i_sl_clk_rx                      => (others => etile_clk_out),
                i_sl_csr_rst_n                   => (others => not RESET_ETH),
                i_sl_tx_rst_n                    => (others => '1'),
                i_sl_rx_rst_n                    => (others => '1'),
                o_sl_txfifo_pfull                => open,
                o_sl_txfifo_pempty               => open,
                o_sl_txfifo_overflow             => open,
                o_sl_txfifo_underflow            => open,
                o_sl_tx_ready                    => tx_avst_ready,
                o_sl_rx_valid                    => rx_avst_valid,
                i_sl_tx_valid                    => tx_avst_valid,
                i_sl_tx_data                     => tx_avst_data,
                o_sl_rx_data                     => rx_avst_data,
                i_sl_tx_error                    => tx_avst_error,
                i_sl_tx_startofpacket            => tx_avst_sop,
                i_sl_tx_endofpacket              => tx_avst_eop,
                i_sl_tx_empty                    => tx_avst_empty,
                i_sl_tx_skip_crc                 => (others => '0'),
                o_sl_rx_startofpacket            => rx_avst_sop,
                o_sl_rx_endofpacket              => rx_avst_eop,
                o_sl_rx_empty                    => rx_avst_empty,
                o_sl_rx_error                    => rx_avst_error,
                o_sl_rxstatus_data               => open,
                o_sl_rxstatus_valid              => open,
                i_sl_tx_pfc                      => (others => '0'),
                o_sl_rx_pfc                      => open,
                i_sl_tx_pause                    => (others => '0'),
                o_sl_rx_pause                    => open
            );

            process(etile_clk_out)
            begin
                if rising_edge(etile_clk_out) then
                    if (RESET_ETH = '1') then
                        RX_LINK_UP <= (others => '0');
                        TX_LINK_UP <= (others => '0');
                    else
                        RX_LINK_UP <= rx_pcs_ready and rx_block_lock and rx_am_lock;
                        TX_LINK_UP <= tx_lanes_stable;
                    end if;
                end if;
            end process;

            -- =========================================================================
            -- ADAPTERS
            -- =========================================================================
            -- TX adaption -------------------------------------------------------------
            tx_adapter_g : for i in ETH_PORT_CHAN-1 downto 0 generate

                mfb2avst_i : entity work.TX_MAC_LITE_ADAPTER_AVST_100G
                generic map(
                    DATA_WIDTH => AVST_DATA_WIDTH,
                    FIFO_DEPTH => MFB2AVST_FIFO_DEPTH,
                    DEVICE     => DEVICE
                )
                port map(
                    CLK            => etile_clk_out,
                    RESET          => RESET_ETH    ,

                    RX_MFB_DATA    => RX_MFB_DATA   (i),
                    RX_MFB_SOF     => RX_MFB_SOF    (i),
                    RX_MFB_SOF_POS => RX_MFB_SOF_POS(i),
                    RX_MFB_EOF     => RX_MFB_EOF    (i),
                    RX_MFB_EOF_POS => RX_MFB_EOF_POS(i),
                    RX_MFB_SRC_RDY => RX_MFB_SRC_RDY(i),
                    RX_MFB_DST_RDY => RX_MFB_DST_RDY(i),

                    TX_AVST_DATA   => tx_avst_data_arr (i),
                    TX_AVST_SOP    => tx_avst_sop      (i),
                    TX_AVST_EOP    => tx_avst_eop      (i),
                    TX_AVST_EMPTY  => tx_avst_empty_arr(i),
                    TX_AVST_ERROR  => tx_avst_error    (i),
                    TX_AVST_VALID  => tx_avst_valid    (i),
                    TX_AVST_READY  => tx_avst_ready    (i)
                );

            end generate;

            tx_avst_data  <= slv_array_ser(tx_avst_data_arr);
            tx_avst_empty <= slv_array_ser(tx_avst_empty_arr);

            -- RX adaption -------------------------------------------------------------
            rx_avst_data_arr  <= slv_array_deser(rx_avst_data , ETH_PORT_CHAN);
            rx_avst_empty_arr <= slv_array_deser(rx_avst_empty, ETH_PORT_CHAN);
            rx_avst_error_arr <= slv_array_deser(rx_avst_error, ETH_PORT_CHAN);

            rx_adapter_g : for i in ETH_PORT_CHAN-1 downto 0 generate

                avst2mfb_i : entity work.ETH_AVST_ADAPTER
                generic map(
                    DATA_WIDTH     => AVST_DATA_WIDTH,
                    TX_REGION_SIZE => AVST_DATA_WIDTH/64
                )
                port map(
                    CLK              => etile_clk_out,
                    RESET            => RESET_ETH    ,

                    IN_AVST_DATA     => rx_avst_data_arr (i),
                    IN_AVST_SOP      => rx_avst_sop      (i),
                    IN_AVST_EOP      => rx_avst_eop      (i),
                    IN_AVST_EMPTY    => rx_avst_empty_arr(i),
                    IN_AVST_ERROR    => rx_avst_error_arr(i),
                    IN_AVST_VALID    => rx_avst_valid    (i),
                    IN_RX_PCS_READY  => '0',
                    IN_RX_BLOCK_LOCK => '0',
                    IN_RX_AM_LOCK    => '0',

                    OUT_MFB_DATA     => TX_MFB_DATA   (i),
                    OUT_MFB_SOF      => TX_MFB_SOF    (i),
                    OUT_MFB_SOF_POS  => TX_MFB_SOF_POS(i),
                    OUT_MFB_EOF      => TX_MFB_EOF    (i),
                    OUT_MFB_EOF_POS  => TX_MFB_EOF_POS(i),
                    OUT_MFB_ERROR    => TX_MFB_ERROR  (i),
                    OUT_MFB_SRC_RDY  => TX_MFB_SRC_RDY(i),
                    OUT_LINK_UP      => open -- this is done here
                );

            end generate;

        when 10 =>

            etile_clk_out <= etile_clk_out_vec(0);
            CLK_ETH       <= etile_clk_out;

            -- =========================================================================
            -- E-TILE Ethernet
            -- =========================================================================
            etile_eth_ip_i : component etile_eth_4x10g
            generic map (
                am_encoding40g_0              => 9467463,
                am_encoding40g_1              => 15779046,
                am_encoding40g_2              => 12936603,
                am_encoding40g_3              => 10647869,
                enforce_max_frame_size        => "disable",
                flow_control                  => "both_no_xoff",
                flow_control_holdoff_mode     => "per_queue",
                forward_rx_pause_requests     => "disable",
                hi_ber_monitor                => "enable",
                holdoff_quanta                => 65535,
                ipg_removed_per_am_period     => 20,
                link_fault_mode               => "lf_bidir",
                pause_quanta                  => 65535,
                pfc_holdoff_quanta_0          => 32768,
                pfc_holdoff_quanta_1          => 32768,
                pfc_holdoff_quanta_2          => 32768,
                pfc_holdoff_quanta_3          => 32768,
                pfc_holdoff_quanta_4          => 32768,
                pfc_holdoff_quanta_5          => 32768,
                pfc_holdoff_quanta_6          => 32768,
                pfc_holdoff_quanta_7          => 32768,
                pfc_pause_quanta_0            => 65535,
                pfc_pause_quanta_1            => 65535,
                pfc_pause_quanta_2            => 65535,
                pfc_pause_quanta_3            => 65535,
                pfc_pause_quanta_4            => 65535,
                pfc_pause_quanta_5            => 65535,
                pfc_pause_quanta_6            => 65535,
                pfc_pause_quanta_7            => 65535,
                remove_pads                   => "disable",
                rx_length_checking            => "enable",
                rx_max_frame_size             => 16383,
                rx_pause_daddr                => "1652522221569",
                rx_pcs_max_skew               => 47,
                rx_vlan_detection             => "disable",
                rxcrc_covers_preamble         => "disable",
                sim_mode                      => "enable",
                source_address_insertion      => "disable",
                strict_preamble_checking      => "disable",
                strict_sfd_checking           => "disable",
                tx_ipg_size                   => "ipg_12",
                tx_max_frame_size             => 16383,
                tx_pause_daddr                => "1652522221569",
                tx_pause_saddr                => "73588229205",
                tx_pld_fifo_almost_full_level => 16,
                tx_vlan_detection             => "disable",
                txcrc_covers_preamble         => "disable",
                txmac_saddr                   => "73588229205",
                uniform_holdoff_quanta        => 65535,
                flow_control_sl_0             => "both_no_xoff"
            )
            port map (
                o_cdr_lock                       => open,
                o_tx_pll_locked                  => open,
                i_clk_ref                        => (others => QSFP_REFCLK_P),
                o_clk_pll_div64                  => etile_clk_out_vec,
                o_clk_pll_div66                  => open,
                o_clk_rec_div64                  => open,
                o_clk_rec_div66                  => open,
                o_tx_serial                      => QSFP_TX_P,
                i_rx_serial                      => QSFP_RX_P,
                o_tx_serial_n                    => QSFP_TX_N,
                i_rx_serial_n                    => QSFP_RX_N,
                i_reconfig_clk                   => MI_CLK_PHY,
                i_reconfig_reset                 => MI_RESET_PHY,
                -- XCVR reconfig inf (0x7 downto 0x4)
                i_xcvr_reconfig_address          => xcvr_inf_addr_phy_res_ser,
                i_xcvr_reconfig_read             => xcvr_inf_rd_phy,
                i_xcvr_reconfig_write            => xcvr_inf_wr_phy,
                o_xcvr_reconfig_readdata         => xcvr_inf_drd_phy_res_ser,
                i_xcvr_reconfig_writedata        => xcvr_inf_dwr_phy_res_ser,
                o_xcvr_reconfig_waitrequest      => xcvr_inf_ardy_phy_n,
                i_sl_stats_snapshot              => (others => '1'),
                o_sl_rx_hi_ber                   => open, -- enabled in generics
                -- Eth reconfig inf (0x3 downto 0x0)
                i_sl_eth_reconfig_addr           => eth_inf_addr_phy_res_ser,
                i_sl_eth_reconfig_read           => eth_inf_rd_phy,
                i_sl_eth_reconfig_write          => eth_inf_wr_phy,
                o_sl_eth_reconfig_readdata       => eth_inf_drd_phy_ser,
                o_sl_eth_reconfig_readdata_valid => eth_inf_drdy_phy,
                i_sl_eth_reconfig_writedata      => eth_inf_dwr_phy_ser,
                o_sl_eth_reconfig_waitrequest    => eth_inf_ardy_phy_n,
                o_sl_tx_lanes_stable             => open,
                o_sl_rx_pcs_ready                => rx_pcs_ready,
                o_sl_ehip_ready                  => open,
                o_sl_rx_block_lock               => rx_block_lock,
                o_sl_local_fault_status          => open,
                o_sl_remote_fault_status         => open,
                i_sl_clk_tx                      => (others => etile_clk_out),
                i_sl_clk_rx                      => (others => etile_clk_out),
                i_sl_csr_rst_n                   => (others => not RESET_ETH),
                i_sl_tx_rst_n                    => (others => '1'),
                i_sl_rx_rst_n                    => (others => '1'),
                o_sl_txfifo_pfull                => open,
                o_sl_txfifo_pempty               => open,
                o_sl_txfifo_overflow             => open,
                o_sl_txfifo_underflow            => open,
                o_sl_tx_ready                    => tx_avst_ready,
                o_sl_rx_valid                    => rx_avst_valid,
                i_sl_tx_valid                    => tx_avst_valid,
                i_sl_tx_data                     => tx_avst_data,
                o_sl_rx_data                     => rx_avst_data,
                i_sl_tx_error                    => tx_avst_error,
                i_sl_tx_startofpacket            => tx_avst_sop,
                i_sl_tx_endofpacket              => tx_avst_eop,
                i_sl_tx_empty                    => tx_avst_empty,
                i_sl_tx_skip_crc                 => (others => '0'),
                o_sl_rx_startofpacket            => rx_avst_sop,
                o_sl_rx_endofpacket              => rx_avst_eop,
                o_sl_rx_empty                    => rx_avst_empty,
                o_sl_rx_error                    => rx_avst_error,
                o_sl_rxstatus_data               => open,
                o_sl_rxstatus_valid              => open,
                i_sl_tx_pfc                      => (others => '0'),
                o_sl_rx_pfc                      => open,
                i_sl_tx_pause                    => (others => '0'),
                o_sl_rx_pause                    => open
            );

            process(etile_clk_out)
            begin
                if rising_edge(etile_clk_out) then
                    if (RESET_ETH = '1') then
                        RX_LINK_UP <= (others => '0');
                        TX_LINK_UP <= (others => '0');
                    else
                        RX_LINK_UP <= rx_pcs_ready and rx_block_lock and rx_am_lock;
                        TX_LINK_UP <= tx_lanes_stable;
                    end if;
                end if;
            end process;

            -- =========================================================================
            -- ADAPTERS
            -- =========================================================================
            -- TX adaption
            tx_adapter_g : for i in ETH_PORT_CHAN-1 downto 0 generate

                mfb2avst_i : entity work.TX_MAC_LITE_ADAPTER_AVST_100G
                generic map(
                    DATA_WIDTH => AVST_DATA_WIDTH,
                    FIFO_DEPTH => MFB2AVST_FIFO_DEPTH,
                    DEVICE     => DEVICE
                )
                port map(
                    CLK            => etile_clk_out,
                    RESET          => RESET_ETH    ,

                    RX_MFB_DATA    => RX_MFB_DATA   (i),
                    RX_MFB_SOF     => RX_MFB_SOF    (i),
                    RX_MFB_SOF_POS => RX_MFB_SOF_POS(i),
                    RX_MFB_EOF     => RX_MFB_EOF    (i),
                    RX_MFB_EOF_POS => RX_MFB_EOF_POS(i),
                    RX_MFB_SRC_RDY => RX_MFB_SRC_RDY(i),
                    RX_MFB_DST_RDY => RX_MFB_DST_RDY(i),

                    TX_AVST_DATA   => tx_avst_data_arr (i),
                    TX_AVST_SOP    => tx_avst_sop      (i),
                    TX_AVST_EOP    => tx_avst_eop      (i),
                    TX_AVST_EMPTY  => tx_avst_empty_arr(i),
                    TX_AVST_ERROR  => tx_avst_error    (i),
                    TX_AVST_VALID  => tx_avst_valid    (i),
                    TX_AVST_READY  => tx_avst_ready    (i)
                );

            end generate;

            tx_avst_data  <= slv_array_ser(tx_avst_data_arr);
            tx_avst_empty <= slv_array_ser(tx_avst_empty_arr);

            -- RX adaption
            rx_avst_data_arr  <= slv_array_deser(rx_avst_data , ETH_PORT_CHAN);
            rx_avst_empty_arr <= slv_array_deser(rx_avst_empty, ETH_PORT_CHAN);
            rx_avst_error_arr <= slv_array_deser(rx_avst_error, ETH_PORT_CHAN);

            rx_adapter_g : for i in ETH_PORT_CHAN-1 downto 0 generate

                avst2mfb_i : entity work.ETH_AVST_ADAPTER
                generic map(
                    DATA_WIDTH     => AVST_DATA_WIDTH,
                    TX_REGION_SIZE => AVST_DATA_WIDTH/64
                )
                port map(
                    CLK              => etile_clk_out,
                    RESET            => RESET_ETH    ,

                    IN_AVST_DATA     => rx_avst_data_arr (i),
                    IN_AVST_SOP      => rx_avst_sop      (i),
                    IN_AVST_EOP      => rx_avst_eop      (i),
                    IN_AVST_EMPTY    => rx_avst_empty_arr(i),
                    IN_AVST_ERROR    => rx_avst_error_arr(i),
                    IN_AVST_VALID    => rx_avst_valid    (i),
                    IN_RX_PCS_READY  => '0',
                    IN_RX_BLOCK_LOCK => '0',
                    IN_RX_AM_LOCK    => '0',

                    OUT_MFB_DATA     => TX_MFB_DATA   (i),
                    OUT_MFB_SOF      => TX_MFB_SOF    (i),
                    OUT_MFB_SOF_POS  => TX_MFB_SOF_POS(i),
                    OUT_MFB_EOF      => TX_MFB_EOF    (i),
                    OUT_MFB_EOF_POS  => TX_MFB_EOF_POS(i),
                    OUT_MFB_ERROR    => TX_MFB_ERROR  (i),
                    OUT_MFB_SRC_RDY  => TX_MFB_SRC_RDY(i),
                    OUT_LINK_UP      => open -- this is done here
                );

            end generate;

    end generate;

end architecture;
