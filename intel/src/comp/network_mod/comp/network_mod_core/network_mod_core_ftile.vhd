-- network_mod_core_ftile.vhd: core of the Network module with Ethernet F-TILE(s).
-- Copyright (C) 2021 CESNET z. s. p. o.
-- Author(s): Daniel Kondys <xkondy00@vutbr.cz>
--
-- SPDX-License-Identifier: BSD-3-Clause

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.math_pack.all;
use work.type_pack.all;
use work.eth_hdr_pack.all;

architecture FULL of NETWORK_MOD_CORE is

    -- =========================================================================
    --                        COMPONENTS - PLL and F_TILE
    -- =========================================================================
    -- 400g1
    component ftile_pll_1x400g is
    port (
        out_systempll_synthlock_0 : out std_logic;        -- out_systempll_synthlock
        out_systempll_clk_0       : out std_logic;        -- clk
        out_refclk_fgt_0          : out std_logic;        -- clk
        in_refclk_fgt_0           : in  std_logic := 'X'  -- in_refclk_fgt_0
    );
    end component ftile_pll_1x400g;

    component ftile_eth_1x400g is
    port (
        i_clk_tx                        : in  std_logic                       := 'X';             -- clk
        i_clk_rx                        : in  std_logic                       := 'X';             -- clk
        o_clk_pll                       : out std_logic;                                          -- clk
        o_clk_tx_div                    : out std_logic;                                          -- clk
        o_clk_rec_div64                 : out std_logic;                                          -- clk
        o_clk_rec_div                   : out std_logic;                                          -- clk
        i_tx_rst_n                      : in  std_logic                       := 'X';             -- reset
        i_rx_rst_n                      : in  std_logic                       := 'X';             -- reset
        i_rst_n                         : in  std_logic                       := 'X';             -- reset
        o_rst_ack_n                     : out std_logic;                                          -- reset
        o_tx_rst_ack_n                  : out std_logic;                                          -- reset
        o_rx_rst_ack_n                  : out std_logic;                                          -- reset
        i_reconfig_clk                  : in  std_logic                       := 'X';             -- clk
        i_reconfig_reset                : in  std_logic                       := 'X';             -- reset
        o_cdr_lock                      : out std_logic;                                          -- o_cdr_lock
        o_tx_pll_locked                 : out std_logic;                                          -- o_tx_pll_locked
        o_tx_lanes_stable               : out std_logic;                                          -- o_tx_lanes_stable
        o_rx_pcs_ready                  : out std_logic;                                          -- o_rx_pcs_ready
        o_tx_serial                     : out std_logic_vector(7 downto 0);                       -- o_tx_serial
        i_rx_serial                     : in  std_logic_vector(7 downto 0)    := (others => 'X'); -- i_rx_serial
        o_tx_serial_n                   : out std_logic_vector(7 downto 0);                       -- o_tx_serial_n
        i_rx_serial_n                   : in  std_logic_vector(7 downto 0)    := (others => 'X'); -- i_rx_serial_n
        i_clk_ref                       : in  std_logic                       := 'X';             -- clk
        i_clk_sys                       : in  std_logic                       := 'X';             -- clk
        i_reconfig_eth_addr             : in  std_logic_vector(13 downto 0)   := (others => 'X'); -- address
        i_reconfig_eth_byteenable       : in  std_logic_vector(3 downto 0)    := (others => 'X'); -- byteenable
        o_reconfig_eth_readdata_valid   : out std_logic;                                          -- readdatavalid
        i_reconfig_eth_read             : in  std_logic                       := 'X';             -- read
        i_reconfig_eth_write            : in  std_logic                       := 'X';             -- write
        o_reconfig_eth_readdata         : out std_logic_vector(31 downto 0);                      -- readdata
        i_reconfig_eth_writedata        : in  std_logic_vector(31 downto 0)   := (others => 'X'); -- writedata
        o_reconfig_eth_waitrequest      : out std_logic;                                          -- waitrequest
        i_reconfig_xcvr0_addr           : in  std_logic_vector(17 downto 0)   := (others => 'X'); -- address
        i_reconfig_xcvr0_byteenable     : in  std_logic_vector(3 downto 0)    := (others => 'X'); -- byteenable
        o_reconfig_xcvr0_readdata_valid : out std_logic;                                          -- readdatavalid
        i_reconfig_xcvr0_read           : in  std_logic                       := 'X';             -- read
        i_reconfig_xcvr0_write          : in  std_logic                       := 'X';             -- write
        o_reconfig_xcvr0_readdata       : out std_logic_vector(31 downto 0);                      -- readdata
        i_reconfig_xcvr0_writedata      : in  std_logic_vector(31 downto 0)   := (others => 'X'); -- writedata
        o_reconfig_xcvr0_waitrequest    : out std_logic;                                          -- waitrequest
        i_reconfig_xcvr1_addr           : in  std_logic_vector(17 downto 0)   := (others => 'X'); -- address
        i_reconfig_xcvr1_byteenable     : in  std_logic_vector(3 downto 0)    := (others => 'X'); -- byteenable
        o_reconfig_xcvr1_readdata_valid : out std_logic;                                          -- readdatavalid
        i_reconfig_xcvr1_read           : in  std_logic                       := 'X';             -- read
        i_reconfig_xcvr1_write          : in  std_logic                       := 'X';             -- write
        o_reconfig_xcvr1_readdata       : out std_logic_vector(31 downto 0);                      -- readdata
        i_reconfig_xcvr1_writedata      : in  std_logic_vector(31 downto 0)   := (others => 'X'); -- writedata
        o_reconfig_xcvr1_waitrequest    : out std_logic;                                          -- waitrequest
        i_reconfig_xcvr2_addr           : in  std_logic_vector(17 downto 0)   := (others => 'X'); -- address
        i_reconfig_xcvr2_byteenable     : in  std_logic_vector(3 downto 0)    := (others => 'X'); -- byteenable
        o_reconfig_xcvr2_readdata_valid : out std_logic;                                          -- readdatavalid
        i_reconfig_xcvr2_read           : in  std_logic                       := 'X';             -- read
        i_reconfig_xcvr2_write          : in  std_logic                       := 'X';             -- write
        o_reconfig_xcvr2_readdata       : out std_logic_vector(31 downto 0);                      -- readdata
        i_reconfig_xcvr2_writedata      : in  std_logic_vector(31 downto 0)   := (others => 'X'); -- writedata
        o_reconfig_xcvr2_waitrequest    : out std_logic;                                          -- waitrequest
        i_reconfig_xcvr3_addr           : in  std_logic_vector(17 downto 0)   := (others => 'X'); -- address
        i_reconfig_xcvr3_byteenable     : in  std_logic_vector(3 downto 0)    := (others => 'X'); -- byteenable
        o_reconfig_xcvr3_readdata_valid : out std_logic;                                          -- readdatavalid
        i_reconfig_xcvr3_read           : in  std_logic                       := 'X';             -- read
        i_reconfig_xcvr3_write          : in  std_logic                       := 'X';             -- write
        o_reconfig_xcvr3_readdata       : out std_logic_vector(31 downto 0);                      -- readdata
        i_reconfig_xcvr3_writedata      : in  std_logic_vector(31 downto 0)   := (others => 'X'); -- writedata
        o_reconfig_xcvr3_waitrequest    : out std_logic;                                          -- waitrequest
        i_reconfig_xcvr4_addr           : in  std_logic_vector(17 downto 0)   := (others => 'X'); -- address
        i_reconfig_xcvr4_byteenable     : in  std_logic_vector(3 downto 0)    := (others => 'X'); -- byteenable
        o_reconfig_xcvr4_readdata_valid : out std_logic;                                          -- readdatavalid
        i_reconfig_xcvr4_read           : in  std_logic                       := 'X';             -- read
        i_reconfig_xcvr4_write          : in  std_logic                       := 'X';             -- write
        o_reconfig_xcvr4_readdata       : out std_logic_vector(31 downto 0);                      -- readdata
        i_reconfig_xcvr4_writedata      : in  std_logic_vector(31 downto 0)   := (others => 'X'); -- writedata
        o_reconfig_xcvr4_waitrequest    : out std_logic;                                          -- waitrequest
        i_reconfig_xcvr5_addr           : in  std_logic_vector(17 downto 0)   := (others => 'X'); -- address
        i_reconfig_xcvr5_byteenable     : in  std_logic_vector(3 downto 0)    := (others => 'X'); -- byteenable
        o_reconfig_xcvr5_readdata_valid : out std_logic;                                          -- readdatavalid
        i_reconfig_xcvr5_read           : in  std_logic                       := 'X';             -- read
        i_reconfig_xcvr5_write          : in  std_logic                       := 'X';             -- write
        o_reconfig_xcvr5_readdata       : out std_logic_vector(31 downto 0);                      -- readdata
        i_reconfig_xcvr5_writedata      : in  std_logic_vector(31 downto 0)   := (others => 'X'); -- writedata
        o_reconfig_xcvr5_waitrequest    : out std_logic;                                          -- waitrequest
        i_reconfig_xcvr6_addr           : in  std_logic_vector(17 downto 0)   := (others => 'X'); -- address
        i_reconfig_xcvr6_byteenable     : in  std_logic_vector(3 downto 0)    := (others => 'X'); -- byteenable
        o_reconfig_xcvr6_readdata_valid : out std_logic;                                          -- readdatavalid
        i_reconfig_xcvr6_read           : in  std_logic                       := 'X';             -- read
        i_reconfig_xcvr6_write          : in  std_logic                       := 'X';             -- write
        o_reconfig_xcvr6_readdata       : out std_logic_vector(31 downto 0);                      -- readdata
        i_reconfig_xcvr6_writedata      : in  std_logic_vector(31 downto 0)   := (others => 'X'); -- writedata
        o_reconfig_xcvr6_waitrequest    : out std_logic;                                          -- waitrequest
        i_reconfig_xcvr7_addr           : in  std_logic_vector(17 downto 0)   := (others => 'X'); -- address
        i_reconfig_xcvr7_byteenable     : in  std_logic_vector(3 downto 0)    := (others => 'X'); -- byteenable
        o_reconfig_xcvr7_readdata_valid : out std_logic;                                          -- readdatavalid
        i_reconfig_xcvr7_read           : in  std_logic                       := 'X';             -- read
        i_reconfig_xcvr7_write          : in  std_logic                       := 'X';             -- write
        o_reconfig_xcvr7_readdata       : out std_logic_vector(31 downto 0);                      -- readdata
        i_reconfig_xcvr7_writedata      : in  std_logic_vector(31 downto 0)   := (others => 'X'); -- writedata
        o_reconfig_xcvr7_waitrequest    : out std_logic;                                          -- waitrequest
        o_rx_block_lock                 : out std_logic;                                          -- o_rx_block_lock
        o_rx_am_lock                    : out std_logic;                                          -- o_rx_am_lock
        o_local_fault_status            : out std_logic;                                          -- o_local_fault_status
        o_remote_fault_status           : out std_logic;                                          -- o_remote_fault_status
        i_stats_snapshot                : in  std_logic                       := 'X';             -- i_stats_snapshot
        o_rx_hi_ber                     : out std_logic;                                          -- o_rx_hi_ber
        o_rx_pcs_fully_aligned          : out std_logic;                                          -- o_rx_pcs_fully_aligned
        i_tx_mac_data                   : in  std_logic_vector(1023 downto 0) := (others => 'X'); -- i_tx_mac_data
        i_tx_mac_valid                  : in  std_logic                       := 'X';             -- i_tx_mac_valid
        i_tx_mac_inframe                : in  std_logic_vector(15 downto 0)   := (others => 'X'); -- i_tx_mac_inframe
        i_tx_mac_eop_empty              : in  std_logic_vector(47 downto 0)   := (others => 'X'); -- i_tx_mac_eop_empty
        o_tx_mac_ready                  : out std_logic;                                          -- o_tx_mac_ready
        i_tx_mac_error                  : in  std_logic_vector(15 downto 0)   := (others => 'X'); -- i_tx_mac_error
        i_tx_mac_skip_crc               : in  std_logic_vector(15 downto 0)   := (others => 'X'); -- i_tx_mac_skip_crc
        o_rx_mac_data                   : out std_logic_vector(1023 downto 0);                    -- o_rx_mac_data
        o_rx_mac_valid                  : out std_logic;                                          -- o_rx_mac_valid
        o_rx_mac_inframe                : out std_logic_vector(15 downto 0);                      -- o_rx_mac_inframe
        o_rx_mac_eop_empty              : out std_logic_vector(47 downto 0);                      -- o_rx_mac_eop_empty
        o_rx_mac_fcs_error              : out std_logic_vector(15 downto 0);                      -- o_rx_mac_fcs_error
        o_rx_mac_error                  : out std_logic_vector(31 downto 0);                      -- o_rx_mac_error
        o_rx_mac_status                 : out std_logic_vector(47 downto 0);                      -- o_rx_mac_status
        i_tx_pfc                        : in  std_logic_vector(7 downto 0)    := (others => 'X'); -- i_tx_pfc
        o_rx_pfc                        : out std_logic_vector(7 downto 0);                       -- o_rx_pfc
        i_tx_pause                      : in  std_logic                       := 'X';             -- i_tx_pause
        o_rx_pause                      : out std_logic                                           -- o_rx_pause
    );
    end component ftile_eth_1x400g;

    -- 200g2
    component ftile_pll_2x200g is
    port (
        out_systempll_synthlock_0 : out std_logic;        -- out_systempll_synthlock
        out_systempll_clk_0       : out std_logic;        -- clk
        out_refclk_fgt_0          : out std_logic;        -- clk
        in_refclk_fgt_0           : in  std_logic := 'X'  -- in_refclk_fgt_0
    );
    end component ftile_pll_2x200g;

    component ftile_eth_2x200g is
    port (
        i_clk_tx                        : in  std_logic                      := 'X';             -- clk
        i_clk_rx                        : in  std_logic                      := 'X';             -- clk
        o_clk_pll                       : out std_logic;                                         -- clk
        o_clk_tx_div                    : out std_logic;                                         -- clk
        o_clk_rec_div64                 : out std_logic;                                         -- clk
        o_clk_rec_div                   : out std_logic;                                         -- clk
        i_tx_rst_n                      : in  std_logic                      := 'X';             -- reset
        i_rx_rst_n                      : in  std_logic                      := 'X';             -- reset
        i_rst_n                         : in  std_logic                      := 'X';             -- reset
        o_rst_ack_n                     : out std_logic;                                         -- reset
        o_tx_rst_ack_n                  : out std_logic;                                         -- reset
        o_rx_rst_ack_n                  : out std_logic;                                         -- reset
        i_reconfig_clk                  : in  std_logic                      := 'X';             -- clk
        i_reconfig_reset                : in  std_logic                      := 'X';             -- reset
        o_cdr_lock                      : out std_logic;                                         -- o_cdr_lock
        o_tx_pll_locked                 : out std_logic;                                         -- o_tx_pll_locked
        o_tx_lanes_stable               : out std_logic;                                         -- o_tx_lanes_stable
        o_rx_pcs_ready                  : out std_logic;                                         -- o_rx_pcs_ready
        o_tx_serial                     : out std_logic_vector(3 downto 0);                      -- o_tx_serial
        i_rx_serial                     : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- i_rx_serial
        o_tx_serial_n                   : out std_logic_vector(3 downto 0);                      -- o_tx_serial_n
        i_rx_serial_n                   : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- i_rx_serial_n
        i_clk_ref                       : in  std_logic                      := 'X';             -- clk
        i_clk_sys                       : in  std_logic                      := 'X';             -- clk
        i_reconfig_eth_addr             : in  std_logic_vector(13 downto 0)  := (others => 'X'); -- address
        i_reconfig_eth_byteenable       : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- byteenable
        o_reconfig_eth_readdata_valid   : out std_logic;                                         -- readdatavalid
        i_reconfig_eth_read             : in  std_logic                      := 'X';             -- read
        i_reconfig_eth_write            : in  std_logic                      := 'X';             -- write
        o_reconfig_eth_readdata         : out std_logic_vector(31 downto 0);                     -- readdata
        i_reconfig_eth_writedata        : in  std_logic_vector(31 downto 0)  := (others => 'X'); -- writedata
        o_reconfig_eth_waitrequest      : out std_logic;                                         -- waitrequest
        i_reconfig_xcvr0_addr           : in  std_logic_vector(17 downto 0)  := (others => 'X'); -- address
        i_reconfig_xcvr0_byteenable     : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- byteenable
        o_reconfig_xcvr0_readdata_valid : out std_logic;                                         -- readdatavalid
        i_reconfig_xcvr0_read           : in  std_logic                      := 'X';             -- read
        i_reconfig_xcvr0_write          : in  std_logic                      := 'X';             -- write
        o_reconfig_xcvr0_readdata       : out std_logic_vector(31 downto 0);                     -- readdata
        i_reconfig_xcvr0_writedata      : in  std_logic_vector(31 downto 0)  := (others => 'X'); -- writedata
        o_reconfig_xcvr0_waitrequest    : out std_logic;                                         -- waitrequest
        i_reconfig_xcvr1_addr           : in  std_logic_vector(17 downto 0)  := (others => 'X'); -- address
        i_reconfig_xcvr1_byteenable     : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- byteenable
        o_reconfig_xcvr1_readdata_valid : out std_logic;                                         -- readdatavalid
        i_reconfig_xcvr1_read           : in  std_logic                      := 'X';             -- read
        i_reconfig_xcvr1_write          : in  std_logic                      := 'X';             -- write
        o_reconfig_xcvr1_readdata       : out std_logic_vector(31 downto 0);                     -- readdata
        i_reconfig_xcvr1_writedata      : in  std_logic_vector(31 downto 0)  := (others => 'X'); -- writedata
        o_reconfig_xcvr1_waitrequest    : out std_logic;                                         -- waitrequest
        i_reconfig_xcvr2_addr           : in  std_logic_vector(17 downto 0)  := (others => 'X'); -- address
        i_reconfig_xcvr2_byteenable     : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- byteenable
        o_reconfig_xcvr2_readdata_valid : out std_logic;                                         -- readdatavalid
        i_reconfig_xcvr2_read           : in  std_logic                      := 'X';             -- read
        i_reconfig_xcvr2_write          : in  std_logic                      := 'X';             -- write
        o_reconfig_xcvr2_readdata       : out std_logic_vector(31 downto 0);                     -- readdata
        i_reconfig_xcvr2_writedata      : in  std_logic_vector(31 downto 0)  := (others => 'X'); -- writedata
        o_reconfig_xcvr2_waitrequest    : out std_logic;                                         -- waitrequest
        i_reconfig_xcvr3_addr           : in  std_logic_vector(17 downto 0)  := (others => 'X'); -- address
        i_reconfig_xcvr3_byteenable     : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- byteenable
        o_reconfig_xcvr3_readdata_valid : out std_logic;                                         -- readdatavalid
        i_reconfig_xcvr3_read           : in  std_logic                      := 'X';             -- read
        i_reconfig_xcvr3_write          : in  std_logic                      := 'X';             -- write
        o_reconfig_xcvr3_readdata       : out std_logic_vector(31 downto 0);                     -- readdata
        i_reconfig_xcvr3_writedata      : in  std_logic_vector(31 downto 0)  := (others => 'X'); -- writedata
        o_reconfig_xcvr3_waitrequest    : out std_logic;                                         -- waitrequest
        o_rx_block_lock                 : out std_logic;                                         -- o_rx_block_lock
        o_rx_am_lock                    : out std_logic;                                         -- o_rx_am_lock
        o_local_fault_status            : out std_logic;                                         -- o_local_fault_status
        o_remote_fault_status           : out std_logic;                                         -- o_remote_fault_status
        i_stats_snapshot                : in  std_logic                      := 'X';             -- i_stats_snapshot
        o_rx_hi_ber                     : out std_logic;                                         -- o_rx_hi_ber
        o_rx_pcs_fully_aligned          : out std_logic;                                         -- o_rx_pcs_fully_aligned
        i_tx_mac_data                   : in  std_logic_vector(511 downto 0) := (others => 'X'); -- i_tx_mac_data
        i_tx_mac_valid                  : in  std_logic                      := 'X';             -- i_tx_mac_valid
        i_tx_mac_inframe                : in  std_logic_vector(7 downto 0)   := (others => 'X'); -- i_tx_mac_inframe
        i_tx_mac_eop_empty              : in  std_logic_vector(23 downto 0)  := (others => 'X'); -- i_tx_mac_eop_empty
        o_tx_mac_ready                  : out std_logic;                                         -- o_tx_mac_ready
        i_tx_mac_error                  : in  std_logic_vector(7 downto 0)   := (others => 'X'); -- i_tx_mac_error
        i_tx_mac_skip_crc               : in  std_logic_vector(7 downto 0)   := (others => 'X'); -- i_tx_mac_skip_crc
        o_rx_mac_data                   : out std_logic_vector(511 downto 0);                    -- o_rx_mac_data
        o_rx_mac_valid                  : out std_logic;                                         -- o_rx_mac_valid
        o_rx_mac_inframe                : out std_logic_vector(7 downto 0);                      -- o_rx_mac_inframe
        o_rx_mac_eop_empty              : out std_logic_vector(23 downto 0);                     -- o_rx_mac_eop_empty
        o_rx_mac_fcs_error              : out std_logic_vector(7 downto 0);                      -- o_rx_mac_fcs_error
        o_rx_mac_error                  : out std_logic_vector(15 downto 0);                     -- o_rx_mac_error
        o_rx_mac_status                 : out std_logic_vector(23 downto 0);                     -- o_rx_mac_status
        i_tx_pfc                        : in  std_logic_vector(7 downto 0)   := (others => 'X'); -- i_tx_pfc
        o_rx_pfc                        : out std_logic_vector(7 downto 0);                      -- o_rx_pfc
        i_tx_pause                      : in  std_logic                      := 'X';             -- i_tx_pause
        o_rx_pause                      : out std_logic                                          -- o_rx_pause
    );
    end component ftile_eth_2x200g;

    -- 100g4
    component ftile_pll_4x100g is
    port (
        out_systempll_synthlock_0 : out std_logic;        -- out_systempll_synthlock
        out_systempll_clk_0       : out std_logic;        -- clk
        out_refclk_fgt_0          : out std_logic;        -- clk
        in_refclk_fgt_0           : in  std_logic := 'X'  -- in_refclk_fgt_0
    );
    end component ftile_pll_4x100g;

    component ftile_eth_4x100g is
    port (
        i_clk_tx                        : in  std_logic                      := 'X';             -- clk
        i_clk_rx                        : in  std_logic                      := 'X';             -- clk
        o_clk_pll                       : out std_logic;                                         -- clk
        o_clk_tx_div                    : out std_logic;                                         -- clk
        o_clk_rec_div64                 : out std_logic;                                         -- clk
        o_clk_rec_div                   : out std_logic;                                         -- clk
        i_tx_rst_n                      : in  std_logic                      := 'X';             -- reset
        i_rx_rst_n                      : in  std_logic                      := 'X';             -- reset
        i_rst_n                         : in  std_logic                      := 'X';             -- reset
        o_rst_ack_n                     : out std_logic;                                         -- reset
        o_tx_rst_ack_n                  : out std_logic;                                         -- reset
        o_rx_rst_ack_n                  : out std_logic;                                         -- reset
        i_reconfig_clk                  : in  std_logic                      := 'X';             -- clk
        i_reconfig_reset                : in  std_logic                      := 'X';             -- reset
        o_cdr_lock                      : out std_logic;                                         -- o_cdr_lock
        o_tx_pll_locked                 : out std_logic;                                         -- o_tx_pll_locked
        o_tx_lanes_stable               : out std_logic;                                         -- o_tx_lanes_stable
        o_rx_pcs_ready                  : out std_logic;                                         -- o_rx_pcs_ready
        o_tx_serial                     : out std_logic_vector(1 downto 0);                      -- o_tx_serial
        i_rx_serial                     : in  std_logic_vector(1 downto 0)   := (others => 'X'); -- i_rx_serial
        o_tx_serial_n                   : out std_logic_vector(1 downto 0);                      -- o_tx_serial_n
        i_rx_serial_n                   : in  std_logic_vector(1 downto 0)   := (others => 'X'); -- i_rx_serial_n
        i_clk_ref                       : in  std_logic                      := 'X';             -- clk
        i_clk_sys                       : in  std_logic                      := 'X';             -- clk
        i_reconfig_eth_addr             : in  std_logic_vector(13 downto 0)  := (others => 'X'); -- address
        i_reconfig_eth_byteenable       : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- byteenable
        o_reconfig_eth_readdata_valid   : out std_logic;                                         -- readdatavalid
        i_reconfig_eth_read             : in  std_logic                      := 'X';             -- read
        i_reconfig_eth_write            : in  std_logic                      := 'X';             -- write
        o_reconfig_eth_readdata         : out std_logic_vector(31 downto 0);                     -- readdata
        i_reconfig_eth_writedata        : in  std_logic_vector(31 downto 0)  := (others => 'X'); -- writedata
        o_reconfig_eth_waitrequest      : out std_logic;                                         -- waitrequest
        i_reconfig_xcvr0_addr           : in  std_logic_vector(17 downto 0)  := (others => 'X'); -- address
        i_reconfig_xcvr0_byteenable     : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- byteenable
        o_reconfig_xcvr0_readdata_valid : out std_logic;                                         -- readdatavalid
        i_reconfig_xcvr0_read           : in  std_logic                      := 'X';             -- read
        i_reconfig_xcvr0_write          : in  std_logic                      := 'X';             -- write
        o_reconfig_xcvr0_readdata       : out std_logic_vector(31 downto 0);                     -- readdata
        i_reconfig_xcvr0_writedata      : in  std_logic_vector(31 downto 0)  := (others => 'X'); -- writedata
        o_reconfig_xcvr0_waitrequest    : out std_logic;                                         -- waitrequest
        i_reconfig_xcvr1_addr           : in  std_logic_vector(17 downto 0)  := (others => 'X'); -- address
        i_reconfig_xcvr1_byteenable     : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- byteenable
        o_reconfig_xcvr1_readdata_valid : out std_logic;                                         -- readdatavalid
        i_reconfig_xcvr1_read           : in  std_logic                      := 'X';             -- read
        i_reconfig_xcvr1_write          : in  std_logic                      := 'X';             -- write
        o_reconfig_xcvr1_readdata       : out std_logic_vector(31 downto 0);                     -- readdata
        i_reconfig_xcvr1_writedata      : in  std_logic_vector(31 downto 0)  := (others => 'X'); -- writedata
        o_reconfig_xcvr1_waitrequest    : out std_logic;                                         -- waitrequest
        o_rx_block_lock                 : out std_logic;                                         -- o_rx_block_lock
        o_rx_am_lock                    : out std_logic;                                         -- o_rx_am_lock
        o_local_fault_status            : out std_logic;                                         -- o_local_fault_status
        o_remote_fault_status           : out std_logic;                                         -- o_remote_fault_status
        i_stats_snapshot                : in  std_logic                      := 'X';             -- i_stats_snapshot
        o_rx_hi_ber                     : out std_logic;                                         -- o_rx_hi_ber
        o_rx_pcs_fully_aligned          : out std_logic;                                         -- o_rx_pcs_fully_aligned
        i_tx_mac_data                   : in  std_logic_vector(255 downto 0) := (others => 'X'); -- i_tx_mac_data
        i_tx_mac_valid                  : in  std_logic                      := 'X';             -- i_tx_mac_valid
        i_tx_mac_inframe                : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- i_tx_mac_inframe
        i_tx_mac_eop_empty              : in  std_logic_vector(11 downto 0)  := (others => 'X'); -- i_tx_mac_eop_empty
        o_tx_mac_ready                  : out std_logic;                                         -- o_tx_mac_ready
        i_tx_mac_error                  : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- i_tx_mac_error
        i_tx_mac_skip_crc               : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- i_tx_mac_skip_crc
        o_rx_mac_data                   : out std_logic_vector(255 downto 0);                    -- o_rx_mac_data
        o_rx_mac_valid                  : out std_logic;                                         -- o_rx_mac_valid
        o_rx_mac_inframe                : out std_logic_vector(3 downto 0);                      -- o_rx_mac_inframe
        o_rx_mac_eop_empty              : out std_logic_vector(11 downto 0);                     -- o_rx_mac_eop_empty
        o_rx_mac_fcs_error              : out std_logic_vector(3 downto 0);                      -- o_rx_mac_fcs_error
        o_rx_mac_error                  : out std_logic_vector(7 downto 0);                      -- o_rx_mac_error
        o_rx_mac_status                 : out std_logic_vector(11 downto 0);                     -- o_rx_mac_status
        i_tx_pfc                        : in  std_logic_vector(7 downto 0)   := (others => 'X'); -- i_tx_pfc
        o_rx_pfc                        : out std_logic_vector(7 downto 0);                      -- o_rx_pfc
        i_tx_pause                      : in  std_logic                      := 'X';             -- i_tx_pause
        o_rx_pause                      : out std_logic                                          -- o_rx_pause
    );
    end component ftile_eth_4x100g;

    -- 100g2 (NRZ)
    component ftile_eth_2x100g is
    port (
        i_clk_tx                        : in  std_logic                      := 'X';             -- clk
        i_clk_rx                        : in  std_logic                      := 'X';             -- clk
        o_clk_pll                       : out std_logic;                                         -- clk
        i_reconfig_clk                  : in  std_logic                      := 'X';             -- clk
        i_reconfig_reset                : in  std_logic                      := 'X';             -- reset
        o_sys_pll_locked                : out std_logic;                                         -- o_sys_pll_locked
        o_tx_serial                     : out std_logic_vector(3 downto 0);                      -- o_tx_serial
        i_rx_serial                     : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- i_rx_serial
        o_tx_serial_n                   : out std_logic_vector(3 downto 0);                      -- o_tx_serial_n
        i_rx_serial_n                   : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- i_rx_serial_n
        i_clk_ref                       : in  std_logic                      := 'X';             -- clk
        i_clk_sys                       : in  std_logic                      := 'X';             -- clk
        i_reconfig_eth_addr             : in  std_logic_vector(13 downto 0)  := (others => 'X'); -- address
        i_reconfig_eth_byteenable       : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- byteenable
        o_reconfig_eth_readdata_valid   : out std_logic;                                         -- readdatavalid
        i_reconfig_eth_read             : in  std_logic                      := 'X';             -- read
        i_reconfig_eth_write            : in  std_logic                      := 'X';             -- write
        o_reconfig_eth_readdata         : out std_logic_vector(31 downto 0);                     -- readdata
        i_reconfig_eth_writedata        : in  std_logic_vector(31 downto 0)  := (others => 'X'); -- writedata
        o_reconfig_eth_waitrequest      : out std_logic;                                         -- waitrequest
        i_rst_n                         : in  std_logic                      := 'X';             -- reset_n
        i_tx_rst_n                      : in  std_logic                      := 'X';             -- reset_n
        i_rx_rst_n                      : in  std_logic                      := 'X';             -- reset_n
        o_rst_ack_n                     : out std_logic;                                         -- o_rst_ack_n
        o_tx_rst_ack_n                  : out std_logic;                                         -- o_tx_rst_ack_n
        o_rx_rst_ack_n                  : out std_logic;                                         -- o_rx_rst_ack_n
        o_cdr_lock                      : out std_logic;                                         -- o_cdr_lock
        o_tx_pll_locked                 : out std_logic;                                         -- o_tx_pll_locked
        o_tx_lanes_stable               : out std_logic;                                         -- o_tx_lanes_stable
        o_rx_pcs_ready                  : out std_logic;                                         -- o_rx_pcs_ready
        o_clk_tx_div                    : out std_logic;                                         -- clk
        o_clk_rec_div64                 : out std_logic;                                         -- clk
        o_clk_rec_div                   : out std_logic;                                         -- clk
        o_rx_block_lock                 : out std_logic;                                         -- o_rx_block_lock
        o_rx_am_lock                    : out std_logic;                                         -- o_rx_am_lock
        o_local_fault_status            : out std_logic;                                         -- o_local_fault_status
        o_remote_fault_status           : out std_logic;                                         -- o_remote_fault_status
        i_stats_snapshot                : in  std_logic                      := 'X';             -- i_stats_snapshot
        o_rx_hi_ber                     : out std_logic;                                         -- o_rx_hi_ber
        o_rx_pcs_fully_aligned          : out std_logic;                                         -- o_rx_pcs_fully_aligned
        i_tx_mac_data                   : in  std_logic_vector(255 downto 0) := (others => 'X'); -- i_tx_mac_data
        i_tx_mac_valid                  : in  std_logic                      := 'X';             -- i_tx_mac_valid
        i_tx_mac_inframe                : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- i_tx_mac_inframe
        i_tx_mac_eop_empty              : in  std_logic_vector(11 downto 0)  := (others => 'X'); -- i_tx_mac_eop_empty
        o_tx_mac_ready                  : out std_logic;                                         -- o_tx_mac_ready
        i_tx_mac_error                  : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- i_tx_mac_error
        i_tx_mac_skip_crc               : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- i_tx_mac_skip_crc
        o_rx_mac_data                   : out std_logic_vector(255 downto 0);                    -- o_rx_mac_data
        o_rx_mac_valid                  : out std_logic;                                         -- o_rx_mac_valid
        o_rx_mac_inframe                : out std_logic_vector(3 downto 0);                      -- o_rx_mac_inframe
        o_rx_mac_eop_empty              : out std_logic_vector(11 downto 0);                     -- o_rx_mac_eop_empty
        o_rx_mac_fcs_error              : out std_logic_vector(3 downto 0);                      -- o_rx_mac_fcs_error
        o_rx_mac_error                  : out std_logic_vector(7 downto 0);                      -- o_rx_mac_error
        o_rx_mac_status                 : out std_logic_vector(11 downto 0);                     -- o_rx_mac_status
        i_tx_pfc                        : in  std_logic_vector(7 downto 0)   := (others => 'X'); -- i_tx_pfc
        o_rx_pfc                        : out std_logic_vector(7 downto 0);                      -- o_rx_pfc
        i_tx_pause                      : in  std_logic                      := 'X';             -- i_tx_pause
        o_rx_pause                      : out std_logic;                                         -- o_rx_pause
        i_reconfig_xcvr0_addr           : in  std_logic_vector(17 downto 0)  := (others => 'X'); -- address
        i_reconfig_xcvr0_byteenable     : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- byteenable
        o_reconfig_xcvr0_readdata_valid : out std_logic;                                         -- readdatavalid
        i_reconfig_xcvr0_read           : in  std_logic                      := 'X';             -- read
        i_reconfig_xcvr0_write          : in  std_logic                      := 'X';             -- write
        o_reconfig_xcvr0_readdata       : out std_logic_vector(31 downto 0);                     -- readdata
        i_reconfig_xcvr0_writedata      : in  std_logic_vector(31 downto 0)  := (others => 'X'); -- writedata
        o_reconfig_xcvr0_waitrequest    : out std_logic;                                         -- waitrequest
        i_reconfig_xcvr1_addr           : in  std_logic_vector(17 downto 0)  := (others => 'X'); -- address
        i_reconfig_xcvr1_byteenable     : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- byteenable
        o_reconfig_xcvr1_readdata_valid : out std_logic;                                         -- readdatavalid
        i_reconfig_xcvr1_read           : in  std_logic                      := 'X';             -- read
        i_reconfig_xcvr1_write          : in  std_logic                      := 'X';             -- write
        o_reconfig_xcvr1_readdata       : out std_logic_vector(31 downto 0);                     -- readdata
        i_reconfig_xcvr1_writedata      : in  std_logic_vector(31 downto 0)  := (others => 'X'); -- writedata
        o_reconfig_xcvr1_waitrequest    : out std_logic;                                         -- waitrequest
        i_reconfig_xcvr2_addr           : in  std_logic_vector(17 downto 0)  := (others => 'X'); -- address
        i_reconfig_xcvr2_byteenable     : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- byteenable
        o_reconfig_xcvr2_readdata_valid : out std_logic;                                         -- readdatavalid
        i_reconfig_xcvr2_read           : in  std_logic                      := 'X';             -- read
        i_reconfig_xcvr2_write          : in  std_logic                      := 'X';             -- write
        o_reconfig_xcvr2_readdata       : out std_logic_vector(31 downto 0);                     -- readdata
        i_reconfig_xcvr2_writedata      : in  std_logic_vector(31 downto 0)  := (others => 'X'); -- writedata
        o_reconfig_xcvr2_waitrequest    : out std_logic;                                         -- waitrequest
        i_reconfig_xcvr3_addr           : in  std_logic_vector(17 downto 0)  := (others => 'X'); -- address
        i_reconfig_xcvr3_byteenable     : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- byteenable
        o_reconfig_xcvr3_readdata_valid : out std_logic;                                         -- readdatavalid
        i_reconfig_xcvr3_read           : in  std_logic                      := 'X';             -- read
        i_reconfig_xcvr3_write          : in  std_logic                      := 'X';             -- write
        o_reconfig_xcvr3_readdata       : out std_logic_vector(31 downto 0);                     -- readdata
        i_reconfig_xcvr3_writedata      : in  std_logic_vector(31 downto 0)  := (others => 'X'); -- writedata
        o_reconfig_xcvr3_waitrequest    : out std_logic;                                         -- waitrequest
        i_clk_pll                       : in  std_logic                      := 'X'              -- clk
    );
    end component ftile_eth_2x100g;

    -- 50g8
    component ftile_pll_8x50g is
    port (
        out_systempll_synthlock_0 : out std_logic;        -- out_systempll_synthlock
        out_systempll_clk_0       : out std_logic;        -- clk
        out_refclk_fgt_0          : out std_logic;        -- clk
        in_refclk_fgt_0           : in  std_logic := 'X'  -- in_refclk_fgt_0
    );
    end component ftile_pll_8x50g;

    component ftile_eth_8x50g is
    port (
        i_clk_tx                        : in  std_logic                      := 'X';             -- clk
        i_clk_rx                        : in  std_logic                      := 'X';             -- clk
        o_clk_pll                       : out std_logic;                                         -- clk
        o_clk_tx_div                    : out std_logic;                                         -- clk
        o_clk_rec_div64                 : out std_logic;                                         -- clk
        o_clk_rec_div                   : out std_logic;                                         -- clk
        i_tx_rst_n                      : in  std_logic                      := 'X';             -- reset
        i_rx_rst_n                      : in  std_logic                      := 'X';             -- reset
        i_rst_n                         : in  std_logic                      := 'X';             -- reset
        o_rst_ack_n                     : out std_logic;                                         -- reset
        o_tx_rst_ack_n                  : out std_logic;                                         -- reset
        o_rx_rst_ack_n                  : out std_logic;                                         -- reset
        i_reconfig_clk                  : in  std_logic                      := 'X';             -- clk
        i_reconfig_reset                : in  std_logic                      := 'X';             -- reset
        o_cdr_lock                      : out std_logic;                                         -- o_cdr_lock
        o_tx_pll_locked                 : out std_logic;                                         -- o_tx_pll_locked
        o_tx_lanes_stable               : out std_logic;                                         -- o_tx_lanes_stable
        o_rx_pcs_ready                  : out std_logic;                                         -- o_rx_pcs_ready
        o_tx_serial                     : out std_logic_vector(0 downto 0);                      -- o_tx_serial
        i_rx_serial                     : in  std_logic_vector(0 downto 0)   := (others => 'X'); -- i_rx_serial
        o_tx_serial_n                   : out std_logic_vector(0 downto 0);                      -- o_tx_serial_n
        i_rx_serial_n                   : in  std_logic_vector(0 downto 0)   := (others => 'X'); -- i_rx_serial_n
        i_clk_ref                       : in  std_logic                      := 'X';             -- clk
        i_clk_sys                       : in  std_logic                      := 'X';             -- clk
        i_reconfig_eth_addr             : in  std_logic_vector(13 downto 0)  := (others => 'X'); -- address
        i_reconfig_eth_byteenable       : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- byteenable
        o_reconfig_eth_readdata_valid   : out std_logic;                                         -- readdatavalid
        i_reconfig_eth_read             : in  std_logic                      := 'X';             -- read
        i_reconfig_eth_write            : in  std_logic                      := 'X';             -- write
        o_reconfig_eth_readdata         : out std_logic_vector(31 downto 0);                     -- readdata
        i_reconfig_eth_writedata        : in  std_logic_vector(31 downto 0)  := (others => 'X'); -- writedata
        o_reconfig_eth_waitrequest      : out std_logic;                                         -- waitrequest
        i_reconfig_xcvr0_addr           : in  std_logic_vector(17 downto 0)  := (others => 'X'); -- address
        i_reconfig_xcvr0_byteenable     : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- byteenable
        o_reconfig_xcvr0_readdata_valid : out std_logic;                                         -- readdatavalid
        i_reconfig_xcvr0_read           : in  std_logic                      := 'X';             -- read
        i_reconfig_xcvr0_write          : in  std_logic                      := 'X';             -- write
        o_reconfig_xcvr0_readdata       : out std_logic_vector(31 downto 0);                     -- readdata
        i_reconfig_xcvr0_writedata      : in  std_logic_vector(31 downto 0)  := (others => 'X'); -- writedata
        o_reconfig_xcvr0_waitrequest    : out std_logic;                                         -- waitrequest
        o_rx_block_lock                 : out std_logic;                                         -- o_rx_block_lock
        o_rx_am_lock                    : out std_logic;                                         -- o_rx_am_lock
        o_local_fault_status            : out std_logic;                                         -- o_local_fault_status
        o_remote_fault_status           : out std_logic;                                         -- o_remote_fault_status
        i_stats_snapshot                : in  std_logic                      := 'X';             -- i_stats_snapshot
        o_rx_hi_ber                     : out std_logic;                                         -- o_rx_hi_ber
        o_rx_pcs_fully_aligned          : out std_logic;                                         -- o_rx_pcs_fully_aligned
        i_tx_mac_data                   : in  std_logic_vector(127 downto 0) := (others => 'X'); -- i_tx_mac_data
        i_tx_mac_valid                  : in  std_logic                      := 'X';             -- i_tx_mac_valid
        i_tx_mac_inframe                : in  std_logic_vector(1 downto 0)   := (others => 'X'); -- i_tx_mac_inframe
        i_tx_mac_eop_empty              : in  std_logic_vector(5 downto 0)   := (others => 'X'); -- i_tx_mac_eop_empty
        o_tx_mac_ready                  : out std_logic;                                         -- o_tx_mac_ready
        i_tx_mac_error                  : in  std_logic_vector(1 downto 0)   := (others => 'X'); -- i_tx_mac_error
        i_tx_mac_skip_crc               : in  std_logic_vector(1 downto 0)   := (others => 'X'); -- i_tx_mac_skip_crc
        o_rx_mac_data                   : out std_logic_vector(127 downto 0);                    -- o_rx_mac_data
        o_rx_mac_valid                  : out std_logic;                                         -- o_rx_mac_valid
        o_rx_mac_inframe                : out std_logic_vector(1 downto 0);                      -- o_rx_mac_inframe
        o_rx_mac_eop_empty              : out std_logic_vector(5 downto 0);                      -- o_rx_mac_eop_empty
        o_rx_mac_fcs_error              : out std_logic_vector(1 downto 0);                      -- o_rx_mac_fcs_error
        o_rx_mac_error                  : out std_logic_vector(3 downto 0);                      -- o_rx_mac_error
        o_rx_mac_status                 : out std_logic_vector(5 downto 0);                      -- o_rx_mac_status
        i_tx_pfc                        : in  std_logic_vector(7 downto 0)   := (others => 'X'); -- i_tx_pfc
        o_rx_pfc                        : out std_logic_vector(7 downto 0);                      -- o_rx_pfc
        i_tx_pause                      : in  std_logic                      := 'X';             -- i_tx_pause
        o_rx_pause                      : out std_logic                                          -- o_rx_pause
    );
    end component ftile_eth_8x50g;

    -- 40g2
    component ftile_pll_2x40g is
        port (
            out_systempll_synthlock_0 : out std_logic;        -- out_systempll_synthlock
            out_systempll_clk_0       : out std_logic;        -- clk
            out_refclk_fgt_0          : out std_logic;        -- clk
            in_refclk_fgt_0           : in  std_logic := 'X'  -- in_refclk_fgt_0
        );
    end component ftile_pll_2x40g;

    component ftile_eth_2x40g is
    port (
        i_clk_tx                        : in  std_logic                      := 'X';             -- clk
        i_clk_rx                        : in  std_logic                      := 'X';             -- clk
        o_clk_pll                       : out std_logic;                                         -- clk
        o_clk_tx_div                    : out std_logic;                                         -- clk
        o_clk_rec_div64                 : out std_logic;                                         -- clk
        o_clk_rec_div                   : out std_logic;                                         -- clk
        i_tx_rst_n                      : in  std_logic                      := 'X';             -- reset
        i_rx_rst_n                      : in  std_logic                      := 'X';             -- reset
        i_rst_n                         : in  std_logic                      := 'X';             -- reset
        o_rst_ack_n                     : out std_logic;                                         -- reset
        o_tx_rst_ack_n                  : out std_logic;                                         -- reset
        o_rx_rst_ack_n                  : out std_logic;                                         -- reset
        i_reconfig_clk                  : in  std_logic                      := 'X';             -- clk
        i_reconfig_reset                : in  std_logic                      := 'X';             -- reset
        o_cdr_lock                      : out std_logic;                                         -- o_cdr_lock
        o_tx_pll_locked                 : out std_logic;                                         -- o_tx_pll_locked
        o_tx_lanes_stable               : out std_logic;                                         -- o_tx_lanes_stable
        o_rx_pcs_ready                  : out std_logic;                                         -- o_rx_pcs_ready
        o_tx_serial                     : out std_logic_vector(3 downto 0);                      -- o_tx_serial
        i_rx_serial                     : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- i_rx_serial
        o_tx_serial_n                   : out std_logic_vector(3 downto 0);                      -- o_tx_serial_n
        i_rx_serial_n                   : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- i_rx_serial_n
        i_clk_ref                       : in  std_logic                      := 'X';             -- clk
        i_clk_sys                       : in  std_logic                      := 'X';             -- clk
        i_reconfig_eth_addr             : in  std_logic_vector(13 downto 0)  := (others => 'X'); -- address
        i_reconfig_eth_byteenable       : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- byteenable
        o_reconfig_eth_readdata_valid   : out std_logic;                                         -- readdatavalid
        i_reconfig_eth_read             : in  std_logic                      := 'X';             -- read
        i_reconfig_eth_write            : in  std_logic                      := 'X';             -- write
        o_reconfig_eth_readdata         : out std_logic_vector(31 downto 0);                     -- readdata
        i_reconfig_eth_writedata        : in  std_logic_vector(31 downto 0)  := (others => 'X'); -- writedata
        o_reconfig_eth_waitrequest      : out std_logic;                                         -- waitrequest
        i_reconfig_xcvr0_addr           : in  std_logic_vector(17 downto 0)  := (others => 'X'); -- address
        i_reconfig_xcvr0_byteenable     : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- byteenable
        o_reconfig_xcvr0_readdata_valid : out std_logic;                                         -- readdatavalid
        i_reconfig_xcvr0_read           : in  std_logic                      := 'X';             -- read
        i_reconfig_xcvr0_write          : in  std_logic                      := 'X';             -- write
        o_reconfig_xcvr0_readdata       : out std_logic_vector(31 downto 0);                     -- readdata
        i_reconfig_xcvr0_writedata      : in  std_logic_vector(31 downto 0)  := (others => 'X'); -- writedata
        o_reconfig_xcvr0_waitrequest    : out std_logic;                                         -- waitrequest
        i_reconfig_xcvr1_addr           : in  std_logic_vector(17 downto 0)  := (others => 'X'); -- address
        i_reconfig_xcvr1_byteenable     : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- byteenable
        o_reconfig_xcvr1_readdata_valid : out std_logic;                                         -- readdatavalid
        i_reconfig_xcvr1_read           : in  std_logic                      := 'X';             -- read
        i_reconfig_xcvr1_write          : in  std_logic                      := 'X';             -- write
        o_reconfig_xcvr1_readdata       : out std_logic_vector(31 downto 0);                     -- readdata
        i_reconfig_xcvr1_writedata      : in  std_logic_vector(31 downto 0)  := (others => 'X'); -- writedata
        o_reconfig_xcvr1_waitrequest    : out std_logic;                                         -- waitrequest
        i_reconfig_xcvr2_addr           : in  std_logic_vector(17 downto 0)  := (others => 'X'); -- address
        i_reconfig_xcvr2_byteenable     : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- byteenable
        o_reconfig_xcvr2_readdata_valid : out std_logic;                                         -- readdatavalid
        i_reconfig_xcvr2_read           : in  std_logic                      := 'X';             -- read
        i_reconfig_xcvr2_write          : in  std_logic                      := 'X';             -- write
        o_reconfig_xcvr2_readdata       : out std_logic_vector(31 downto 0);                     -- readdata
        i_reconfig_xcvr2_writedata      : in  std_logic_vector(31 downto 0)  := (others => 'X'); -- writedata
        o_reconfig_xcvr2_waitrequest    : out std_logic;                                         -- waitrequest
        i_reconfig_xcvr3_addr           : in  std_logic_vector(17 downto 0)  := (others => 'X'); -- address
        i_reconfig_xcvr3_byteenable     : in  std_logic_vector(3 downto 0)   := (others => 'X'); -- byteenable
        o_reconfig_xcvr3_readdata_valid : out std_logic;                                         -- readdatavalid
        i_reconfig_xcvr3_read           : in  std_logic                      := 'X';             -- read
        i_reconfig_xcvr3_write          : in  std_logic                      := 'X';             -- write
        o_reconfig_xcvr3_readdata       : out std_logic_vector(31 downto 0);                     -- readdata
        i_reconfig_xcvr3_writedata      : in  std_logic_vector(31 downto 0)  := (others => 'X'); -- writedata
        o_reconfig_xcvr3_waitrequest    : out std_logic;                                         -- waitrequest
        o_rx_block_lock                 : out std_logic;                                         -- o_rx_block_lock
        o_rx_am_lock                    : out std_logic;                                         -- o_rx_am_lock
        o_local_fault_status            : out std_logic;                                         -- o_local_fault_status
        o_remote_fault_status           : out std_logic;                                         -- o_remote_fault_status
        i_stats_snapshot                : in  std_logic                      := 'X';             -- i_stats_snapshot
        o_rx_hi_ber                     : out std_logic;                                         -- o_rx_hi_ber
        o_rx_pcs_fully_aligned          : out std_logic;                                         -- o_rx_pcs_fully_aligned
        i_tx_mac_data                   : in  std_logic_vector(127 downto 0) := (others => 'X'); -- i_tx_mac_data
        i_tx_mac_valid                  : in  std_logic                      := 'X';             -- i_tx_mac_valid
        i_tx_mac_inframe                : in  std_logic_vector(1 downto 0)   := (others => 'X'); -- i_tx_mac_inframe
        i_tx_mac_eop_empty              : in  std_logic_vector(5 downto 0)   := (others => 'X'); -- i_tx_mac_eop_empty
        o_tx_mac_ready                  : out std_logic;                                         -- o_tx_mac_ready
        i_tx_mac_error                  : in  std_logic_vector(1 downto 0)   := (others => 'X'); -- i_tx_mac_error
        i_tx_mac_skip_crc               : in  std_logic_vector(1 downto 0)   := (others => 'X'); -- i_tx_mac_skip_crc
        o_rx_mac_data                   : out std_logic_vector(127 downto 0);                    -- o_rx_mac_data
        o_rx_mac_valid                  : out std_logic;                                         -- o_rx_mac_valid
        o_rx_mac_inframe                : out std_logic_vector(1 downto 0);                      -- o_rx_mac_inframe
        o_rx_mac_eop_empty              : out std_logic_vector(5 downto 0);                      -- o_rx_mac_eop_empty
        o_rx_mac_fcs_error              : out std_logic_vector(1 downto 0);                      -- o_rx_mac_fcs_error
        o_rx_mac_error                  : out std_logic_vector(3 downto 0);                      -- o_rx_mac_error
        o_rx_mac_status                 : out std_logic_vector(5 downto 0);                      -- o_rx_mac_status
        i_tx_pfc                        : in  std_logic_vector(7 downto 0)   := (others => 'X'); -- i_tx_pfc
        o_rx_pfc                        : out std_logic_vector(7 downto 0);                      -- o_rx_pfc
        i_tx_pause                      : in  std_logic                      := 'X';             -- i_tx_pause
        o_rx_pause                      : out std_logic                                          -- o_rx_pause
    );
    end component ftile_eth_2x40g;

    -- 25g8
    component ftile_pll_8x25g is
    port (
        out_systempll_synthlock_0 : out std_logic;        -- out_systempll_synthlock
        out_systempll_clk_0       : out std_logic;        -- clk
        out_refclk_fgt_0          : out std_logic;        -- clk
        in_refclk_fgt_0           : in  std_logic := 'X'  -- in_refclk_fgt_0
    );
    end component ftile_pll_8x25g;

    component ftile_eth_8x25g is
    port (
        i_clk_tx                        : in  std_logic                     := 'X';             -- clk
        i_clk_rx                        : in  std_logic                     := 'X';             -- clk
        o_clk_pll                       : out std_logic;                                        -- clk
        o_clk_tx_div                    : out std_logic;                                        -- clk
        o_clk_rec_div64                 : out std_logic;                                        -- clk
        o_clk_rec_div                   : out std_logic;                                        -- clk
        i_tx_rst_n                      : in  std_logic                     := 'X';             -- reset
        i_rx_rst_n                      : in  std_logic                     := 'X';             -- reset
        i_rst_n                         : in  std_logic                     := 'X';             -- reset
        o_rst_ack_n                     : out std_logic;                                        -- reset
        o_tx_rst_ack_n                  : out std_logic;                                        -- reset
        o_rx_rst_ack_n                  : out std_logic;                                        -- reset
        i_reconfig_clk                  : in  std_logic                     := 'X';             -- clk
        i_reconfig_reset                : in  std_logic                     := 'X';             -- reset
        o_cdr_lock                      : out std_logic;                                        -- o_cdr_lock
        o_tx_pll_locked                 : out std_logic;                                        -- o_tx_pll_locked
        o_tx_lanes_stable               : out std_logic;                                        -- o_tx_lanes_stable
        o_rx_pcs_ready                  : out std_logic;                                        -- o_rx_pcs_ready
        o_tx_serial                     : out std_logic_vector(0 downto 0);                     -- o_tx_serial
        i_rx_serial                     : in  std_logic_vector(0 downto 0)  := (others => 'X'); -- i_rx_serial
        o_tx_serial_n                   : out std_logic_vector(0 downto 0);                     -- o_tx_serial_n
        i_rx_serial_n                   : in  std_logic_vector(0 downto 0)  := (others => 'X'); -- i_rx_serial_n
        i_clk_ref                       : in  std_logic                     := 'X';             -- clk
        i_clk_sys                       : in  std_logic                     := 'X';             -- clk
        i_reconfig_eth_addr             : in  std_logic_vector(13 downto 0) := (others => 'X'); -- address
        i_reconfig_eth_byteenable       : in  std_logic_vector(3 downto 0)  := (others => 'X'); -- byteenable
        o_reconfig_eth_readdata_valid   : out std_logic;                                        -- readdatavalid
        i_reconfig_eth_read             : in  std_logic                     := 'X';             -- read
        i_reconfig_eth_write            : in  std_logic                     := 'X';             -- write
        o_reconfig_eth_readdata         : out std_logic_vector(31 downto 0);                    -- readdata
        i_reconfig_eth_writedata        : in  std_logic_vector(31 downto 0) := (others => 'X'); -- writedata
        o_reconfig_eth_waitrequest      : out std_logic;                                        -- waitrequest
        i_reconfig_xcvr0_addr           : in  std_logic_vector(17 downto 0) := (others => 'X'); -- address
        i_reconfig_xcvr0_byteenable     : in  std_logic_vector(3 downto 0)  := (others => 'X'); -- byteenable
        o_reconfig_xcvr0_readdata_valid : out std_logic;                                        -- readdatavalid
        i_reconfig_xcvr0_read           : in  std_logic                     := 'X';             -- read
        i_reconfig_xcvr0_write          : in  std_logic                     := 'X';             -- write
        o_reconfig_xcvr0_readdata       : out std_logic_vector(31 downto 0);                    -- readdata
        i_reconfig_xcvr0_writedata      : in  std_logic_vector(31 downto 0) := (others => 'X'); -- writedata
        o_reconfig_xcvr0_waitrequest    : out std_logic;                                        -- waitrequest
        o_rx_block_lock                 : out std_logic;                                        -- o_rx_block_lock
        o_rx_am_lock                    : out std_logic;                                        -- o_rx_am_lock
        o_local_fault_status            : out std_logic;                                        -- o_local_fault_status
        o_remote_fault_status           : out std_logic;                                        -- o_remote_fault_status
        i_stats_snapshot                : in  std_logic                     := 'X';             -- i_stats_snapshot
        o_rx_hi_ber                     : out std_logic;                                        -- o_rx_hi_ber
        o_rx_pcs_fully_aligned          : out std_logic;                                        -- o_rx_pcs_fully_aligned
        i_tx_mac_data                   : in  std_logic_vector(63 downto 0) := (others => 'X'); -- i_tx_mac_data
        i_tx_mac_valid                  : in  std_logic                     := 'X';             -- i_tx_mac_valid
        i_tx_mac_inframe                : in  std_logic                     := 'X';             -- i_tx_mac_inframe
        i_tx_mac_eop_empty              : in  std_logic_vector(2 downto 0)  := (others => 'X'); -- i_tx_mac_eop_empty
        o_tx_mac_ready                  : out std_logic;                                        -- o_tx_mac_ready
        i_tx_mac_error                  : in  std_logic                     := 'X';             -- i_tx_mac_error
        i_tx_mac_skip_crc               : in  std_logic                     := 'X';             -- i_tx_mac_skip_crc
        o_rx_mac_data                   : out std_logic_vector(63 downto 0);                    -- o_rx_mac_data
        o_rx_mac_valid                  : out std_logic;                                        -- o_rx_mac_valid
        o_rx_mac_inframe                : out std_logic;                                        -- o_rx_mac_inframe
        o_rx_mac_eop_empty              : out std_logic_vector(2 downto 0);                     -- o_rx_mac_eop_empty
        o_rx_mac_fcs_error              : out std_logic;                                        -- o_rx_mac_fcs_error
        o_rx_mac_error                  : out std_logic_vector(1 downto 0);                     -- o_rx_mac_error
        o_rx_mac_status                 : out std_logic_vector(2 downto 0);                     -- o_rx_mac_status
        i_tx_pfc                        : in  std_logic_vector(7 downto 0)  := (others => 'X'); -- i_tx_pfc
        o_rx_pfc                        : out std_logic_vector(7 downto 0);                     -- o_rx_pfc
        i_tx_pause                      : in  std_logic                     := 'X';             -- i_tx_pause
        o_rx_pause                      : out std_logic                                         -- o_rx_pause
    );
    end component ftile_eth_8x25g;

    -- 10g8
    component ftile_pll_8x10g is
    port (
        out_systempll_synthlock_0 : out std_logic;        -- out_systempll_synthlock
        out_systempll_clk_0       : out std_logic;        -- clk
        out_refclk_fgt_0          : out std_logic;        -- clk
        in_refclk_fgt_0           : in  std_logic := 'X'  -- in_refclk_fgt_0
    );
    end component ftile_pll_8x10g;

    component ftile_eth_8x10g is
    port (
        i_clk_tx                        : in  std_logic                     := 'X';             -- clk
        i_clk_rx                        : in  std_logic                     := 'X';             -- clk
        o_clk_pll                       : out std_logic;                                        -- clk
        o_clk_tx_div                    : out std_logic;                                        -- clk
        o_clk_rec_div64                 : out std_logic;                                        -- clk
        o_clk_rec_div                   : out std_logic;                                        -- clk
        i_tx_rst_n                      : in  std_logic                     := 'X';             -- reset
        i_rx_rst_n                      : in  std_logic                     := 'X';             -- reset
        i_rst_n                         : in  std_logic                     := 'X';             -- reset
        o_rst_ack_n                     : out std_logic;                                        -- reset
        o_tx_rst_ack_n                  : out std_logic;                                        -- reset
        o_rx_rst_ack_n                  : out std_logic;                                        -- reset
        i_reconfig_clk                  : in  std_logic                     := 'X';             -- clk
        i_reconfig_reset                : in  std_logic                     := 'X';             -- reset
        o_cdr_lock                      : out std_logic;                                        -- o_cdr_lock
        o_tx_pll_locked                 : out std_logic;                                        -- o_tx_pll_locked
        o_tx_lanes_stable               : out std_logic;                                        -- o_tx_lanes_stable
        o_rx_pcs_ready                  : out std_logic;                                        -- o_rx_pcs_ready
        o_tx_serial                     : out std_logic_vector(0 downto 0);                     -- o_tx_serial
        i_rx_serial                     : in  std_logic_vector(0 downto 0)  := (others => 'X'); -- i_rx_serial
        o_tx_serial_n                   : out std_logic_vector(0 downto 0);                     -- o_tx_serial_n
        i_rx_serial_n                   : in  std_logic_vector(0 downto 0)  := (others => 'X'); -- i_rx_serial_n
        i_clk_ref                       : in  std_logic                     := 'X';             -- clk
        i_clk_sys                       : in  std_logic                     := 'X';             -- clk
        i_reconfig_eth_addr             : in  std_logic_vector(13 downto 0) := (others => 'X'); -- address
        i_reconfig_eth_byteenable       : in  std_logic_vector(3 downto 0)  := (others => 'X'); -- byteenable
        o_reconfig_eth_readdata_valid   : out std_logic;                                        -- readdatavalid
        i_reconfig_eth_read             : in  std_logic                     := 'X';             -- read
        i_reconfig_eth_write            : in  std_logic                     := 'X';             -- write
        o_reconfig_eth_readdata         : out std_logic_vector(31 downto 0);                    -- readdata
        i_reconfig_eth_writedata        : in  std_logic_vector(31 downto 0) := (others => 'X'); -- writedata
        o_reconfig_eth_waitrequest      : out std_logic;                                        -- waitrequest
        i_reconfig_xcvr0_addr           : in  std_logic_vector(17 downto 0) := (others => 'X'); -- address
        i_reconfig_xcvr0_byteenable     : in  std_logic_vector(3 downto 0)  := (others => 'X'); -- byteenable
        o_reconfig_xcvr0_readdata_valid : out std_logic;                                        -- readdatavalid
        i_reconfig_xcvr0_read           : in  std_logic                     := 'X';             -- read
        i_reconfig_xcvr0_write          : in  std_logic                     := 'X';             -- write
        o_reconfig_xcvr0_readdata       : out std_logic_vector(31 downto 0);                    -- readdata
        i_reconfig_xcvr0_writedata      : in  std_logic_vector(31 downto 0) := (others => 'X'); -- writedata
        o_reconfig_xcvr0_waitrequest    : out std_logic;                                        -- waitrequest
        o_rx_block_lock                 : out std_logic;                                        -- o_rx_block_lock
        o_rx_am_lock                    : out std_logic;                                        -- o_rx_am_lock
        o_local_fault_status            : out std_logic;                                        -- o_local_fault_status
        o_remote_fault_status           : out std_logic;                                        -- o_remote_fault_status
        i_stats_snapshot                : in  std_logic                     := 'X';             -- i_stats_snapshot
        o_rx_hi_ber                     : out std_logic;                                        -- o_rx_hi_ber
        o_rx_pcs_fully_aligned          : out std_logic;                                        -- o_rx_pcs_fully_aligned
        i_tx_mac_data                   : in  std_logic_vector(63 downto 0) := (others => 'X'); -- i_tx_mac_data
        i_tx_mac_valid                  : in  std_logic                     := 'X';             -- i_tx_mac_valid
        i_tx_mac_inframe                : in  std_logic                     := 'X';             -- i_tx_mac_inframe
        i_tx_mac_eop_empty              : in  std_logic_vector(2 downto 0)  := (others => 'X'); -- i_tx_mac_eop_empty
        o_tx_mac_ready                  : out std_logic;                                        -- o_tx_mac_ready
        i_tx_mac_error                  : in  std_logic                     := 'X';             -- i_tx_mac_error
        i_tx_mac_skip_crc               : in  std_logic                     := 'X';             -- i_tx_mac_skip_crc
        o_rx_mac_data                   : out std_logic_vector(63 downto 0);                    -- o_rx_mac_data
        o_rx_mac_valid                  : out std_logic;                                        -- o_rx_mac_valid
        o_rx_mac_inframe                : out std_logic;                                        -- o_rx_mac_inframe
        o_rx_mac_eop_empty              : out std_logic_vector(2 downto 0);                     -- o_rx_mac_eop_empty
        o_rx_mac_fcs_error              : out std_logic;                                        -- o_rx_mac_fcs_error
        o_rx_mac_error                  : out std_logic_vector(1 downto 0);                     -- o_rx_mac_error
        o_rx_mac_status                 : out std_logic_vector(2 downto 0);                     -- o_rx_mac_status
        i_tx_pfc                        : in  std_logic_vector(7 downto 0)  := (others => 'X'); -- i_tx_pfc
        o_rx_pfc                        : out std_logic_vector(7 downto 0);                     -- o_rx_pfc
        i_tx_pause                      : in  std_logic                     := 'X';             -- i_tx_pause
        o_rx_pause                      : out std_logic                                         -- o_rx_pause
    );
    end component ftile_eth_8x10g;

    -- =========================================================================
    --                               FUNCTIONS
    -- =========================================================================
    -- Select the width of RX and TX MAC DATA signals
    function mac_data_width_f return natural is
    begin
        case ETH_PORT_SPEED is
            when 400 => return 1024;
            when 200 => return 512;
            when 100 => return 256;
            when 50  => return 128;
            when 40  => return 128;
            when 25  => return 64;
            when 10  => return 64;
            when others  => return 0;
        end case;
    end function;

    -- Select the width of RX and TX MAC INFRAME signals
    function mac_inframe_width_f return natural is
    begin
        case ETH_PORT_SPEED is
            when 400 => return 16;
            when 200 => return 8;
            when 100 => return 4;
            when 50  => return 2;
            when 40  => return 2;
            when 25  => return 1;
            when 10  => return 1;
            when others  => return 0;
        end case;
    end function;

    -- Select the width of RX and TX MAC EOP EMPTY signals
    function mac_eop_empty_width_f return natural is
    begin
        case ETH_PORT_SPEED is
            when 400 => return 48;
            when 200 => return 24;
            when 100 => return 12;
            when 50  => return 6;
            when 40  => return 6;
            when 25  => return 3;
            when 10  => return 3;
            when others  => return 0;
        end case;
    end function;

    -- Select the width of TX MAC ERROR signal
    function tx_mac_error_width_f return natural is
    begin
        case ETH_PORT_SPEED is
            when 400 => return 16;
            when 200 => return 8;
            when 100 => return 4;
            when 50  => return 2;
            when 40  => return 2;
            when 25  => return 1;
            when 10  => return 1;
            when others  => return 0;
        end case;
    end function;

    -- Select the width of RX MAC FCS ERROR signal
    function rx_mac_fcs_error_width_f return natural is
    begin
        case ETH_PORT_SPEED is
            when 400 => return 16;
            when 200 => return 8;
            when 100 => return 4;
            when 50  => return 2;
            when 40  => return 2;
            when 25  => return 1;
            when 10  => return 1;
            when others  => return 0;
        end case;
    end function;

    -- Select the width of RX MAC ERROR signal
    function rx_mac_error_width_f return natural is
    begin
        case ETH_PORT_SPEED is
            when 400 => return 32;
            when 200 => return 16;
            when 100 => return 8;
            when 50  => return 4;
            when 40  => return 4;
            when 25  => return 2;
            when 10  => return 2;
            when others  => return 0;
        end case;
    end function;

    -- Select the width of RX MAC STATUS signals
    function rx_mac_status_width_f return natural is
    begin
        case ETH_PORT_SPEED is
            when 400 => return 48;
            when 200 => return 24;
            when 100 => return 12;
            when 50  => return 6;
            when 40  => return 6;
            when 25  => return 3;
            when 10  => return 3;
            when others  => return 100;
        end case;
    end function;

    -- Select the number of PCS lanes
    function pcs_lanes_num_f return natural is
    begin
        case ETH_PORT_SPEED is
            when 400 => return 16;
            when 200 => return 8;
            when 100 => return 20;
            when 50  => return 4;
            when 40  => return 4;
            when 25  => return 1;
            when 10  => return 1;
            when others  => return 1;
        end case;
    end function;


    function speed_cap_f return std_logic_vector is
        variable speed_cap_v : std_logic_vector(15 downto 0);
    begin
        speed_cap_v := (others => '0');
        case ETH_PORT_SPEED is
            when 400 => speed_cap_v(15) := '1';
            when 200 => speed_cap_v(12) := '1';
            when 100 => speed_cap_v(9)  := '1';
            when 50  => speed_cap_v(3)  := '1';
            when 40  => speed_cap_v(8)  := '1';
            when 25  => speed_cap_v(11) := '1';
            when others => speed_cap_v(0)  := '1'; -- 10GE
        end case;
        return speed_cap_v;
    end function;

    -- Return FS-FEC ability for selected Ethernet type
    function rsfec_cap_f return std_logic is
        variable fec_cap : std_logic;
    begin
        fec_cap := '0';
        case ETH_PORT_SPEED is
            when 400 => fec_cap := '1';
            when 200 => fec_cap := '1';
            when 100 =>
                if (LANES/ETH_PORT_CHAN) = 4 then
                    fec_cap := '0';  -- 4 lane NRZ mode: FEC off
                else
                    fec_cap := '1';  -- 1 or 2 lane PAM4 mode: FEC on
                end if;
            when 50  => fec_cap := '1';
            when 40  => fec_cap := '0';
            when 25  => fec_cap := '1';
            when others => fec_cap := '0'; -- 10GE
        end case;
        return fec_cap;
    end function;


    -- =========================================================================
    --                               CONSTANTS
    -- =========================================================================

    -- Number of MI Indirect Access' output interfaces
    --                                           eth inf       + xcvr inf
    constant IA_OUTPUT_INFS         : natural := ETH_PORT_CHAN + LANES;

    constant LANES_PER_CHANNEL      : natural := LANES/ETH_PORT_CHAN;

    -- MAC SEG common constants
    constant MAC_DATA_WIDTH         : natural := mac_data_width_f;
    constant MAC_INFRAME_WIDTH      : natural := mac_inframe_width_f;
    constant MAC_EOP_EMPTY_WIDTH    : natural := mac_eop_empty_width_f;
    -- MAC SEG TX constants
    constant TX_MAC_ERROR_WIDTH     : natural := tx_mac_error_width_f;
    -- MAC SEG RX constants
    constant RX_MAC_FCS_ERROR_WIDTH : natural := rx_mac_fcs_error_width_f;
    constant RX_MAC_ERROR_WIDTH     : natural := rx_mac_error_width_f;
    constant RX_MAC_STATUS_WIDTH    : natural := rx_mac_status_width_f;
    constant PCS_LANES_NUM          : natural := pcs_lanes_num_f;
    constant RSFEC_CAP              : std_logic := rsfec_cap_f;

    constant MI_ADDR_BASES_PHY      : natural := ETH_PORT_CHAN;
    constant MGMT_OFF               : std_logic_vector(MI_ADDR_WIDTH_PHY-1 downto 0) := X"0004_0000";
    constant SPEED_CAP              : std_logic_vector(16-1 downto 0) := speed_cap_f;
    constant RX_LINK_CNT_W          : natural := 27;

    function mi_addr_base_init_phy_f return slv_array_t is
        variable mi_addr_base_var : slv_array_t(MI_ADDR_BASES_PHY-1 downto 0)(MI_ADDR_WIDTH_PHY-1 downto 0);
    begin
        for i in 0 to MI_ADDR_BASES_PHY-1 loop
            mi_addr_base_var(i) := std_logic_vector(resize(i*unsigned(MGMT_OFF), MI_ADDR_WIDTH_PHY));
        end loop;
        return mi_addr_base_var;
    end function;

    -- =========================================================================
    --                                SIGNALS
    -- =========================================================================

    signal split_mi_dwr_phy  : slv_array_t     (MI_ADDR_BASES_PHY-1 downto 0)(MI_DATA_WIDTH_PHY-1 downto 0);
    signal split_mi_addr_phy : slv_array_t     (MI_ADDR_BASES_PHY-1 downto 0)(MI_ADDR_WIDTH_PHY-1 downto 0);
    signal split_mi_rd_phy   : std_logic_vector(MI_ADDR_BASES_PHY-1 downto 0);
    signal split_mi_wr_phy   : std_logic_vector(MI_ADDR_BASES_PHY-1 downto 0);
    signal split_mi_be_phy   : slv_array_t     (MI_ADDR_BASES_PHY-1 downto 0)(MI_DATA_WIDTH_PHY/8-1 downto 0);
    signal split_mi_ardy_phy : std_logic_vector(MI_ADDR_BASES_PHY-1 downto 0);
    signal split_mi_drd_phy  : slv_array_t     (MI_ADDR_BASES_PHY-1 downto 0)(MI_DATA_WIDTH_PHY-1 downto 0);
    signal split_mi_drdy_phy : std_logic_vector(MI_ADDR_BASES_PHY-1 downto 0);

    -- MI_PHY for E-tile reconfiguration interfaces (Ethernet, Transceiver (XCVR), RS-FEC)
    -- from MI Indirect Access (-> mi_ia_)
    signal mi_ia_dwr_phy    : slv_array_t     (IA_OUTPUT_INFS-1 downto 0)(MI_DATA_WIDTH_PHY-1 downto 0);
    signal mi_ia_addr_phy   : slv_array_t     (IA_OUTPUT_INFS-1 downto 0)(MI_ADDR_WIDTH_PHY-1 downto 0);
    signal mi_ia_rd_phy     : std_logic_vector(IA_OUTPUT_INFS-1 downto 0);
    signal mi_ia_wr_phy     : std_logic_vector(IA_OUTPUT_INFS-1 downto 0);
    signal mi_ia_ardy_phy   : std_logic_vector(IA_OUTPUT_INFS-1 downto 0);
    signal mi_ia_ardy_phy_n : std_logic_vector(IA_OUTPUT_INFS-1 downto 0);
    signal mi_ia_drd_phy    : slv_array_t     (IA_OUTPUT_INFS-1 downto 0)(MI_DATA_WIDTH_PHY-1 downto 0);
    signal mi_ia_drdy_phy   : std_logic_vector(IA_OUTPUT_INFS-1 downto 0);

    signal qsfp_rx_p_sig : slv_array_t(ETH_PORT_CHAN-1 downto 0)(LANES_PER_CHANNEL-1 downto 0); -- QSFP XCVR RX Data
    signal qsfp_rx_n_sig : slv_array_t(ETH_PORT_CHAN-1 downto 0)(LANES_PER_CHANNEL-1 downto 0); -- QSFP XCVR RX Data
    signal qsfp_tx_p_sig : slv_array_t(ETH_PORT_CHAN-1 downto 0)(LANES_PER_CHANNEL-1 downto 0); -- QSFP XCVR TX Data
    signal qsfp_tx_n_sig : slv_array_t(ETH_PORT_CHAN-1 downto 0)(LANES_PER_CHANNEL-1 downto 0); -- QSFP XCVR TX Data

    signal mi_split_dwr  : std_logic_vector(ETH_PORT_CHAN*32-1 downto 0);
    signal mi_split_addr : std_logic_vector(ETH_PORT_CHAN*22-1 downto 0);
    signal mi_split_be   : std_logic_vector(ETH_PORT_CHAN*4 -1 downto 0);
    signal mi_split_rd   : std_logic_vector(ETH_PORT_CHAN   -1 downto 0);
    signal mi_split_wr   : std_logic_vector(ETH_PORT_CHAN   -1 downto 0);
    signal mi_split_ardy : std_logic_vector(ETH_PORT_CHAN   -1 downto 0);
    signal mi_split_drd  : std_logic_vector(ETH_PORT_CHAN*32-1 downto 0);
    signal mi_split_drdy : std_logic_vector(ETH_PORT_CHAN   -1 downto 0);

    signal ftile_pll_refclk       : std_logic; -- a single PLL can drive multiple IP cores
    signal ftile_pll_clk          : std_logic; -- a single PLL can drive multiple IP cores
    signal ftile_clk_out_vec      : std_logic_vector(ETH_PORT_CHAN-1 downto 0); -- in case of multiple IP cores, only one is chosen
    signal ftile_clk_out          : std_logic; -- drives i_clk_rx and i_clk_tx of one or more other IP cores

    signal ftile_rx_hi_ber            : std_logic_vector(ETH_PORT_CHAN-1 downto 0);
    signal ftile_rx_block_lock        : std_logic_vector(ETH_PORT_CHAN-1 downto 0);
    signal ftile_rx_pcs_ready         : std_logic_vector(ETH_PORT_CHAN-1 downto 0);
    signal ftile_rx_pcs_fully_aligned : std_logic_vector(ETH_PORT_CHAN-1 downto 0);
    signal ftile_tx_lanes_stable      : std_logic_vector(ETH_PORT_CHAN-1 downto 0);
    signal ftile_rx_am_lock           : std_logic_vector(ETH_PORT_CHAN-1 downto 0);
    signal ftile_local_fault          : std_logic_vector(ETH_PORT_CHAN-1 downto 0);
    signal ftile_remote_fault         : std_logic_vector(ETH_PORT_CHAN-1 downto 0);

    signal ftile_tx_mac_data      : slv_array_t     (ETH_PORT_CHAN-1 downto 0)(MAC_DATA_WIDTH        -1 downto 0);
    signal ftile_tx_mac_valid     : std_logic_vector(ETH_PORT_CHAN-1 downto 0);
    signal ftile_tx_mac_inframe   : slv_array_t     (ETH_PORT_CHAN-1 downto 0)(MAC_INFRAME_WIDTH     -1 downto 0);
    signal ftile_tx_mac_eop_empty : slv_array_t     (ETH_PORT_CHAN-1 downto 0)(MAC_EOP_EMPTY_WIDTH   -1 downto 0);
    signal ftile_tx_mac_ready     : std_logic_vector(ETH_PORT_CHAN-1 downto 0); 
    signal ftile_tx_mac_error     : slv_array_t     (ETH_PORT_CHAN-1 downto 0)(TX_MAC_ERROR_WIDTH    -1 downto 0);

    signal ftile_rx_mac_data      : slv_array_t     (ETH_PORT_CHAN-1 downto 0)(MAC_DATA_WIDTH        -1 downto 0);
    signal ftile_rx_mac_valid     : std_logic_vector(ETH_PORT_CHAN-1 downto 0);
    signal ftile_rx_mac_inframe   : slv_array_t     (ETH_PORT_CHAN-1 downto 0)(MAC_INFRAME_WIDTH     -1 downto 0);
    signal ftile_rx_mac_eop_empty : slv_array_t     (ETH_PORT_CHAN-1 downto 0)(MAC_EOP_EMPTY_WIDTH   -1 downto 0);
    signal ftile_rx_mac_fcs_error : slv_array_t     (ETH_PORT_CHAN-1 downto 0)(RX_MAC_FCS_ERROR_WIDTH-1 downto 0);
    signal ftile_rx_mac_error     : slv_array_t     (ETH_PORT_CHAN-1 downto 0)(RX_MAC_ERROR_WIDTH    -1 downto 0);
    signal ftile_rx_mac_status    : slv_array_t     (ETH_PORT_CHAN-1 downto 0)(RX_MAC_STATUS_WIDTH   -1 downto 0);

    signal rx_link_cnt        : u_array_t(ETH_PORT_CHAN-1 downto 0)(RX_LINK_CNT_W-1 downto 0);
    signal rx_link_rst        : std_logic_vector(ETH_PORT_CHAN-1 downto 0);
    signal ftile_rx_rst_n     : std_logic_vector(ETH_PORT_CHAN-1 downto 0);
    signal ftile_rx_rst_ack_n : std_logic_vector(ETH_PORT_CHAN-1 downto 0);

    signal mgmt_pcs_reset : std_logic_vector(ETH_PORT_CHAN-1 downto 0);
    signal mgmt_pma_reset : std_logic_vector(ETH_PORT_CHAN-1 downto 0);

    -- Synchronization of REPEATER_CTRL
    -- signal sync_repeater_ctrl : std_logic_vector(REPEATER_CTRL'range);

begin

    mi_splitter_i : entity work.MI_SPLITTER_PLUS_GEN
    generic map(
        ADDR_WIDTH  => MI_ADDR_WIDTH_PHY,
        DATA_WIDTH  => MI_DATA_WIDTH_PHY,
        META_WIDTH  => 0,
        PORTS       => MI_ADDR_BASES_PHY,
        PIPE_OUT    => (others => true),
        PIPE_TYPE   => "REG",
        ADDR_BASES  => MI_ADDR_BASES_PHY,
        ADDR_BASE   => mi_addr_base_init_phy_f,
        DEVICE      => DEVICE
    )
    port map(
        CLK     => MI_CLK_PHY,
        RESET   => MI_RESET_PHY,

        RX_DWR  => MI_DWR_PHY,
        RX_MWR  => (others => '0'),
        RX_ADDR => MI_ADDR_PHY,
        RX_BE   => MI_BE_PHY,
        RX_RD   => MI_RD_PHY,
        RX_WR   => MI_WR_PHY,
        RX_ARDY => MI_ARDY_PHY,
        RX_DRD  => MI_DRD_PHY,
        RX_DRDY => MI_DRDY_PHY,

        TX_DWR  => split_mi_dwr_phy,
        TX_MWR  => open,
        TX_ADDR => split_mi_addr_phy,
        TX_BE   => split_mi_be_phy,
        TX_RD   => split_mi_rd_phy,
        TX_WR   => split_mi_wr_phy,
        TX_ARDY => split_mi_ardy_phy,
        TX_DRD  => split_mi_drd_phy,
        TX_DRDY => split_mi_drdy_phy
    );

    mgmt_g : for i in ETH_PORT_CHAN-1 downto 0 generate

    signal mi_ia_drd    : std_logic_vector(MI_DATA_WIDTH_PHY-1 downto 0);
    signal mi_ia_drdy   : std_logic;
    signal mi_ia_en     : std_logic;
    signal mi_ia_we_phy : std_logic;
    signal mi_ia_sel    : std_logic_vector(4-1 downto 0);
    signal mi_ia_addr   : std_logic_vector(32-1 downto 0);
    signal mi_ia_dwr    : std_logic_vector(MI_DATA_WIDTH_PHY-1 downto 0);
    signal mi_ia_ardy   : std_logic;
    signal ia_rd_sel    : std_logic_vector(mi_ia_sel'range);
    signal ia_rd        : std_logic;

    begin
        mgmt_i : entity work.mgmt
        generic map (
            NUM_LANES  => PCS_LANES_NUM,
            PMA_LANES  => LANES_PER_CHANNEL,
            SPEED      => ETH_PORT_SPEED,
            SPEED_CAP  => SPEED_CAP,
            DEVICE     => DEVICE,
            RSFEC_ABLE => RSFEC_CAP,
            AN_ABLE    => '0',
            DRP_DWIDTH => MI_DATA_WIDTH_PHY,
            DRP_AWIDTH => 32
        )
        port map (
            RESET         => MI_RESET_PHY,
            MI_CLK        => MI_CLK_PHY,
            MI_DWR        => split_mi_dwr_phy(i),
            MI_ADDR       => split_mi_addr_phy(i),
            MI_RD         => split_mi_rd_phy(i),
            MI_WR         => split_mi_wr_phy(i),
            MI_BE         => split_mi_be_phy(i),
            MI_DRD        => split_mi_drd_phy(i),
            MI_ARDY       => split_mi_ardy_phy(i),
            MI_DRDY       => split_mi_drdy_phy(i),
            -- PCS status
            HI_BER        => ftile_rx_hi_ber(i),
            BLK_LOCK      => (others => ftile_rx_block_lock(i)),
            LINKSTATUS    => ftile_rx_pcs_fully_aligned(i) and not ftile_rx_hi_ber(i),
            BER_COUNT     => (others => '0'),
            BER_COUNT_CLR => open,
            BLK_ERR_CNTR  => (others => '0'),
            BLK_ERR_CLR   => open,
            SCR_BYPASS    => open,
            PCS_RESET     => mgmt_pcs_reset(i), --TODO
            PCS_LPBCK     => open,
            -- PCS Lane align
            ALGN_LOCKED   => ftile_rx_am_lock(i),
            BIP_ERR_CNTRS => (others => '0'),
            BIP_ERR_CLR   => open,
            LANE_MAP      => (others => '0'),
            LANE_ALIGN    => (others => ftile_rx_pcs_fully_aligned(i)),
            -- PMA & PMD status/control
            PMA_LOPWR     => open,
            PMA_LPBCK     => open,
            PMA_REM_LPBCK => open,
            PMA_RESET     => mgmt_pma_reset(i), --TODO
            PMA_RETUNE    => open,
            PMA_CONTROL   => open,
            PMA_STATUS    => (others => '0'),
            PMA_PTRN_EN   => open,
            PMA_TX_DIS    => open,
            PMA_RX_OK     => (others => ftile_rx_pcs_ready(i)), --TODO
            PMD_SIG_DET   => (others => ftile_rx_pcs_ready(i)), --TODO
            PMA_PRECURSOR => open,
            PMA_POSTCURSOR=> open,
            PMA_DRIVE     => open,
            -- Dynamic reconfiguration interface
            DRPCLK        => MI_CLK_PHY,
            DRPDO         => mi_ia_drd,
            DRPRDY        => (mi_ia_drdy and ia_rd), -- DRDY is set during JTAG operations, therefore using ia_rd as mask 
            DRPEN         => mi_ia_en,
            DRPWE         => mi_ia_we_phy,
            DRPADDR       => mi_ia_addr,
            DRPARDY       => mi_ia_ardy,
            DRPDI         => mi_ia_dwr,
            DRPSEL        => mi_ia_sel
        );

        -- Store mi_ia_sel for read operations
        sel_reg_p: process(MI_CLK_PHY)
        begin
            if rising_edge(MI_CLK_PHY) then
                if mi_ia_en = '1' then
                    ia_rd_sel <= mi_ia_sel;
                end if;
                if (mi_ia_drdy = '1') then
                    ia_rd <= '0';
                elsif (mi_ia_en = '1') and (mi_ia_we_phy = '0') then
                    ia_rd <= '1';
                 end if;
            end if;
        end process;
        -- Assign WR/RD signals for Eth blocks
        mi_ia_addr_phy(i)   <= mi_ia_addr(mi_ia_addr_phy(i)'range);
        mi_ia_dwr_phy(i)    <= mi_ia_dwr;
        mi_ia_wr_phy(i)     <= mi_ia_en and     mi_ia_we_phy when mi_ia_sel = "0000" else '0';
        mi_ia_rd_phy(i)     <= mi_ia_en and not mi_ia_we_phy when mi_ia_sel = "0000" else '0';
        -- Generate WR/RD signals for XCVR blocks
        gen_xcvr_wr_rd: for xcvr in 0 to LANES_PER_CHANNEL-1 generate
            mi_ia_wr_phy  (xcvr + i*LANES_PER_CHANNEL + ETH_PORT_CHAN) <= mi_ia_en and     mi_ia_we_phy when mi_ia_sel = std_logic_vector(to_unsigned(xcvr+1,4)) else '0';
            mi_ia_rd_phy  (xcvr + i*LANES_PER_CHANNEL + ETH_PORT_CHAN) <= mi_ia_en and not mi_ia_we_phy when mi_ia_sel = std_logic_vector(to_unsigned(xcvr+1,4)) else '0';
            mi_ia_addr_phy(xcvr + i*LANES_PER_CHANNEL + ETH_PORT_CHAN) <= mi_ia_addr(mi_ia_addr_phy(i)'range);
            mi_ia_dwr_phy (xcvr + i*LANES_PER_CHANNEL + ETH_PORT_CHAN) <= mi_ia_dwr;
        end generate;
        -- Mux read data from Eth/xvcr to mgmt
        drd_mux_p: process(all)
        begin
            case ia_rd_sel is
                when "0001" => -- XCVR0
                    mi_ia_drd  <= mi_ia_drd_phy (0 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN);
                    mi_ia_drdy <= mi_ia_drdy_phy(0 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN);
                    mi_ia_ardy <= mi_ia_ardy_phy(0 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN);
                when "0010" => -- XCVR1
                    if (LANES_PER_CHANNEL > 1) then
                        mi_ia_drd  <= mi_ia_drd_phy (1 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN);
                        mi_ia_drdy <= mi_ia_drdy_phy(1 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN);
                        mi_ia_ardy <= mi_ia_ardy_phy(1 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN);
                    else
                        mi_ia_drd  <= (others => '0');
                        mi_ia_drdy <= '0';
                        mi_ia_ardy <= '0';
                    end if;
                when "0011" => -- XCVR2
                    if (LANES_PER_CHANNEL > 2) then
                        mi_ia_drd  <= mi_ia_drd_phy (2 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN);
                        mi_ia_drdy <= mi_ia_drdy_phy(2 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN);
                        mi_ia_ardy <= mi_ia_ardy_phy(2 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN);
                    else
                        mi_ia_drd  <= (others => '0');
                        mi_ia_drdy <= '0';
                        mi_ia_ardy <= '0';
                    end if;
                when "0100" => -- XCVR3
                    if (LANES_PER_CHANNEL > 3) then
                        mi_ia_drd  <= mi_ia_drd_phy (3 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN);
                        mi_ia_drdy <= mi_ia_drdy_phy(3 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN);
                        mi_ia_ardy <= mi_ia_ardy_phy(3 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN);
                    else
                        mi_ia_drd  <= (others => '0');
                        mi_ia_drdy <= '0';
                        mi_ia_ardy <= '0';
                    end if;
                when "0101" => -- XCVR4
                    if (LANES_PER_CHANNEL > 4) then
                        mi_ia_drd  <= mi_ia_drd_phy (4 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN);
                        mi_ia_drdy <= mi_ia_drdy_phy(4 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN);
                        mi_ia_ardy <= mi_ia_ardy_phy(4 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN);
                    else
                        mi_ia_drd  <= (others => '0');
                        mi_ia_drdy <= '0';
                        mi_ia_ardy <= '0';
                    end if;
                when "0110" => -- XCVR5
                    if (LANES_PER_CHANNEL > 5) then
                        mi_ia_drd  <= mi_ia_drd_phy (5 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN);
                        mi_ia_drdy <= mi_ia_drdy_phy(5 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN);
                        mi_ia_ardy <= mi_ia_ardy_phy(5 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN);
                    else
                        mi_ia_drd  <= (others => '0');
                        mi_ia_drdy <= '0';
                        mi_ia_ardy <= '0';
                    end if;
                when "0111" => -- XCVR6
                    if (LANES_PER_CHANNEL > 6) then
                        mi_ia_drd  <= mi_ia_drd_phy (6 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN);
                        mi_ia_drdy <= mi_ia_drdy_phy(6 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN);
                        mi_ia_ardy <= mi_ia_ardy_phy(6 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN);
                    else
                        mi_ia_drd  <= (others => '0');
                        mi_ia_drdy <= '0';
                        mi_ia_ardy <= '0';
                    end if;
                when "1000" => -- XCVR7
                    if (LANES_PER_CHANNEL > 7) then
                        mi_ia_drd  <= mi_ia_drd_phy (7 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN);
                        mi_ia_drdy <= mi_ia_drdy_phy(7 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN);
                        mi_ia_ardy <= mi_ia_ardy_phy(7 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN);
                    else
                        mi_ia_drd  <= (others => '0');
                        mi_ia_drdy <= '0';
                        mi_ia_ardy <= '0';
                    end if;
                when others => -- "0000": Ethernet core + RSFEC
                    mi_ia_drd  <= mi_ia_drd_phy(i);
                    mi_ia_drdy <= mi_ia_drdy_phy(i);
                    mi_ia_ardy <= mi_ia_ardy_phy(i);
            end case;
        end process;

        -- monitoring RX link state
        process(ftile_clk_out)
        begin
            if rising_edge(ftile_clk_out) then
                if (ftile_rx_pcs_ready(i) = '1') or (rx_link_rst(i) = '1') then
                    -- link is up, clear the counter
                    rx_link_cnt(i) <= (others => '0');
                else
                    -- link is down, increase the counter
                    rx_link_cnt(i) <= rx_link_cnt(i) + 1;
                end if;

                -- when its last bit (~100ms) is set, reset the link
                if (rx_link_cnt(i)(RX_LINK_CNT_W-1) = '1') then
                    rx_link_rst(i) <= '1';
                elsif (ftile_rx_rst_ack_n(i) = '0' and rx_link_rst(i) = '1') then
                    rx_link_rst(i) <= '0';
                end if;

                if (RESET_ETH = '1') then
                    rx_link_cnt(i) <= (others => '0');
                    rx_link_rst(i) <= '0';
                end if;
            end if;
        end process;

        ftile_rx_rst_n(i) <= not rx_link_rst(i);
    end generate;

    mi_ia_ardy_conversion_g: for i in IA_OUTPUT_INFS-1 downto 0 generate
        mi_ia_ardy_phy(i) <= not mi_ia_ardy_phy_n(i);
    end generate;

    eth_port_mode_sel_g : case ETH_PORT_SPEED generate

        when 400 =>
            -- =========================================================================
            -- F-TILE PLL
            -- =========================================================================
            ftile_pll_ip_i : component ftile_pll_1x400g
            port map (
                out_systempll_synthlock_0 => open,
                out_systempll_clk_0       => ftile_pll_clk,
                out_refclk_fgt_0          => ftile_pll_refclk,
                in_refclk_fgt_0           => QSFP_REFCLK_P
            );

            CLK_ETH <= ftile_clk_out;

            -- =========================================================================
            -- F-TILE Ethernet
            -- =========================================================================
            -- can't have more than one 400g channel
            ftile_eth_ip_i : component ftile_eth_1x400g
            port map (
                i_clk_tx                        => ftile_clk_out,
                i_clk_rx                        => ftile_clk_out,
                o_clk_pll                       => ftile_clk_out,
                o_clk_tx_div                    => open,
                o_clk_rec_div64                 => open,
                o_clk_rec_div                   => open,
                i_tx_rst_n                      => '1',
                i_rx_rst_n                      => ftile_rx_rst_n(0),
                i_rst_n                         => not RESET_ETH,
                o_rst_ack_n                     => open,
                o_tx_rst_ack_n                  => open,
                o_rx_rst_ack_n                  => ftile_rx_rst_ack_n(0),
                i_reconfig_clk                  => MI_CLK_PHY,
                i_reconfig_reset                => MI_RESET_PHY,
                o_cdr_lock                      => open,
                o_tx_pll_locked                 => open,
                o_tx_lanes_stable               => ftile_tx_lanes_stable(0),
                o_rx_pcs_ready                  => ftile_rx_pcs_ready(0),
                o_tx_serial                     => QSFP_TX_P,
                i_rx_serial                     => QSFP_RX_P,
                o_tx_serial_n                   => QSFP_TX_N,
                i_rx_serial_n                   => QSFP_RX_N,
                i_clk_ref                       => ftile_pll_refclk,
                i_clk_sys                       => ftile_pll_clk,
                -- Eth (+ RSFEC + transciever) reconfig inf (0x0)
                i_reconfig_eth_addr             => mi_ia_addr_phy  (0)(14-1 downto 0),
                i_reconfig_eth_byteenable       => (others => '1')    , -- not supported in MI IA yet
                o_reconfig_eth_readdata_valid   => mi_ia_drdy_phy  (0),
                i_reconfig_eth_read             => mi_ia_rd_phy    (0),
                i_reconfig_eth_write            => mi_ia_wr_phy    (0),
                o_reconfig_eth_readdata         => mi_ia_drd_phy   (0),
                i_reconfig_eth_writedata        => mi_ia_dwr_phy   (0),
                o_reconfig_eth_waitrequest      => mi_ia_ardy_phy_n(0),
                -- XCVR reconfig inf (0x1)
                i_reconfig_xcvr0_addr           => mi_ia_addr_phy  (1)(18-1 downto 0),
                i_reconfig_xcvr0_byteenable     => (others => '1')    ,
                o_reconfig_xcvr0_readdata_valid => mi_ia_drdy_phy  (1),
                i_reconfig_xcvr0_read           => mi_ia_rd_phy    (1),
                i_reconfig_xcvr0_write          => mi_ia_wr_phy    (1),
                o_reconfig_xcvr0_readdata       => mi_ia_drd_phy   (1),
                i_reconfig_xcvr0_writedata      => mi_ia_dwr_phy   (1),
                o_reconfig_xcvr0_waitrequest    => mi_ia_ardy_phy_n(1),
                -- XCVR reconfig inf (0x2)
                i_reconfig_xcvr1_addr           => mi_ia_addr_phy  (2)(18-1 downto 0),
                i_reconfig_xcvr1_byteenable     => (others => '1')    ,
                o_reconfig_xcvr1_readdata_valid => mi_ia_drdy_phy  (2),
                i_reconfig_xcvr1_read           => mi_ia_rd_phy    (2),
                i_reconfig_xcvr1_write          => mi_ia_wr_phy    (2),
                o_reconfig_xcvr1_readdata       => mi_ia_drd_phy   (2),
                i_reconfig_xcvr1_writedata      => mi_ia_dwr_phy   (2),
                o_reconfig_xcvr1_waitrequest    => mi_ia_ardy_phy_n(2),
                -- XCVR reconfig inf (0x3)
                i_reconfig_xcvr2_addr           => mi_ia_addr_phy  (3)(18-1 downto 0),
                i_reconfig_xcvr2_byteenable     => (others => '1')    ,
                o_reconfig_xcvr2_readdata_valid => mi_ia_drdy_phy  (3),
                i_reconfig_xcvr2_read           => mi_ia_rd_phy    (3),
                i_reconfig_xcvr2_write          => mi_ia_wr_phy    (3),
                o_reconfig_xcvr2_readdata       => mi_ia_drd_phy   (3),
                i_reconfig_xcvr2_writedata      => mi_ia_dwr_phy   (3),
                o_reconfig_xcvr2_waitrequest    => mi_ia_ardy_phy_n(3),
                -- XCVR reconfig inf (0x4)
                i_reconfig_xcvr3_addr           => mi_ia_addr_phy  (4)(18-1 downto 0),
                i_reconfig_xcvr3_byteenable     => (others => '1')    ,
                o_reconfig_xcvr3_readdata_valid => mi_ia_drdy_phy  (4),
                i_reconfig_xcvr3_read           => mi_ia_rd_phy    (4),
                i_reconfig_xcvr3_write          => mi_ia_wr_phy    (4),
                o_reconfig_xcvr3_readdata       => mi_ia_drd_phy   (4),
                i_reconfig_xcvr3_writedata      => mi_ia_dwr_phy   (4),
                o_reconfig_xcvr3_waitrequest    => mi_ia_ardy_phy_n(4),
                -- XCVR reconfig inf (0x5)
                i_reconfig_xcvr4_addr           => mi_ia_addr_phy  (5)(18-1 downto 0),
                i_reconfig_xcvr4_byteenable     => (others => '1')    ,
                o_reconfig_xcvr4_readdata_valid => mi_ia_drdy_phy  (5),
                i_reconfig_xcvr4_read           => mi_ia_rd_phy    (5),
                i_reconfig_xcvr4_write          => mi_ia_wr_phy    (5),
                o_reconfig_xcvr4_readdata       => mi_ia_drd_phy   (5),
                i_reconfig_xcvr4_writedata      => mi_ia_dwr_phy   (5),
                o_reconfig_xcvr4_waitrequest    => mi_ia_ardy_phy_n(5),
                -- XCVR reconfig inf (0x6)
                i_reconfig_xcvr5_addr           => mi_ia_addr_phy  (6)(18-1 downto 0),
                i_reconfig_xcvr5_byteenable     => (others => '1')    ,
                o_reconfig_xcvr5_readdata_valid => mi_ia_drdy_phy  (6),
                i_reconfig_xcvr5_read           => mi_ia_rd_phy    (6),
                i_reconfig_xcvr5_write          => mi_ia_wr_phy    (6),
                o_reconfig_xcvr5_readdata       => mi_ia_drd_phy   (6),
                i_reconfig_xcvr5_writedata      => mi_ia_dwr_phy   (6),
                o_reconfig_xcvr5_waitrequest    => mi_ia_ardy_phy_n(6),
                -- XCVR reconfig inf (0x7)
                i_reconfig_xcvr6_addr           => mi_ia_addr_phy  (7)(18-1 downto 0),
                i_reconfig_xcvr6_byteenable     => (others => '1')    ,
                o_reconfig_xcvr6_readdata_valid => mi_ia_drdy_phy  (7),
                i_reconfig_xcvr6_read           => mi_ia_rd_phy    (7),
                i_reconfig_xcvr6_write          => mi_ia_wr_phy    (7),
                o_reconfig_xcvr6_readdata       => mi_ia_drd_phy   (7),
                i_reconfig_xcvr6_writedata      => mi_ia_dwr_phy   (7),
                o_reconfig_xcvr6_waitrequest    => mi_ia_ardy_phy_n(7),
                -- XCVR reconfig inf (0x8)
                i_reconfig_xcvr7_addr           => mi_ia_addr_phy  (8)(18-1 downto 0),
                i_reconfig_xcvr7_byteenable     => (others => '1')    ,
                o_reconfig_xcvr7_readdata_valid => mi_ia_drdy_phy  (8),
                i_reconfig_xcvr7_read           => mi_ia_rd_phy    (8),
                i_reconfig_xcvr7_write          => mi_ia_wr_phy    (8),
                o_reconfig_xcvr7_readdata       => mi_ia_drd_phy   (8),
                i_reconfig_xcvr7_writedata      => mi_ia_dwr_phy   (8),
                o_reconfig_xcvr7_waitrequest    => mi_ia_ardy_phy_n(8),
                o_rx_block_lock                 => ftile_rx_block_lock(0),
                o_rx_am_lock                    => ftile_rx_am_lock(0),
                o_local_fault_status            => ftile_local_fault(0),
                o_remote_fault_status           => ftile_remote_fault(0),
                i_stats_snapshot                => '0',
                o_rx_hi_ber                     => ftile_rx_hi_ber(0),
                o_rx_pcs_fully_aligned          => ftile_rx_pcs_fully_aligned(0),
                i_tx_mac_data                   => ftile_tx_mac_data(0),
                i_tx_mac_valid                  => ftile_tx_mac_valid(0),
                i_tx_mac_inframe                => ftile_tx_mac_inframe(0),
                i_tx_mac_eop_empty              => ftile_tx_mac_eop_empty(0),
                o_tx_mac_ready                  => ftile_tx_mac_ready(0),
                i_tx_mac_error                  => ftile_tx_mac_error(0),
                i_tx_mac_skip_crc               => (others => '0'),
                o_rx_mac_data                   => ftile_rx_mac_data(0),
                o_rx_mac_valid                  => ftile_rx_mac_valid(0),
                o_rx_mac_inframe                => ftile_rx_mac_inframe(0),
                o_rx_mac_eop_empty              => ftile_rx_mac_eop_empty(0),
                o_rx_mac_fcs_error              => ftile_rx_mac_fcs_error(0),
                o_rx_mac_error                  => ftile_rx_mac_error(0),
                o_rx_mac_status                 => ftile_rx_mac_status(0),
                i_tx_pfc                        => (others => '0'),
                o_rx_pfc                        => open,
                i_tx_pause                      => '0',
                o_rx_pause                      => open
            );

            process(ftile_clk_out)
            begin
                if rising_edge(ftile_clk_out) then
                    if (RESET_ETH = '1') then
                        RX_LINK_UP(0) <= '0';
                        TX_LINK_UP(0) <= '0';
                    else
                        RX_LINK_UP(0) <= ftile_rx_pcs_ready(0) and ftile_rx_pcs_fully_aligned(0) and (not ftile_remote_fault(0));
                        TX_LINK_UP(0) <= ftile_tx_lanes_stable(0);
                    end if;
                end if;
            end process;

            -- =========================================================================
            --  Loopback (repeater) control
            -- =========================================================================
            -- Synchronization of REPEATER_CTRL
            -- sync_repeater_ctrl_i : entity work.ASYNC_BUS_HANDSHAKE
            -- generic map (
            --     DATA_WIDTH => 2
            -- ) port map (
            --     ACLK       => MI_CLK_PHY,
            --     ARST       => MI_RESET_PHY,
            --     ADATAIN    => REPEATER_CTRL,
            --     ASEND      => '1',
            --     AREADY     => open,
            --     BCLK       => ftile_clk_out,
            --     BRST       => '0',
            --     BDATAOUT   => sync_repeater_ctrl,
            --     BLOAD      => '1',
            --     BVALID     => open
            -- );

            -- =========================================================================
            -- ADAPTERS
            -- =========================================================================
            rx_ftile_adapter_i : entity work.RX_MAC_LITE_ADAPTER_MAC_SEG
            generic map(
                REGIONS     => REGIONS,
                REGION_SIZE => REGION_SIZE
            )
            port map(
                CLK              => ftile_clk_out,
                RESET            => RESET_ETH,

                IN_MAC_DATA      => ftile_rx_mac_data(0),
                IN_MAC_INFRAME   => ftile_rx_mac_inframe(0),
                IN_MAC_EOP_EMPTY => ftile_rx_mac_eop_empty(0),
                IN_MAC_FCS_ERROR => ftile_rx_mac_fcs_error(0),
                IN_MAC_ERROR     => ftile_rx_mac_error(0),
                IN_MAC_STATUS    => ftile_rx_mac_status(0),
                IN_MAC_VALID     => ftile_rx_mac_valid(0),

                OUT_MFB_DATA     => TX_MFB_DATA(0),
                OUT_MFB_ERROR    => TX_MFB_ERROR(0),
                OUT_MFB_SOF      => TX_MFB_SOF(0),
                OUT_MFB_EOF      => TX_MFB_EOF(0),
                OUT_MFB_SOF_POS  => TX_MFB_SOF_POS(0),
                OUT_MFB_EOF_POS  => TX_MFB_EOF_POS(0),
                OUT_MFB_SRC_RDY  => TX_MFB_SRC_RDY(0),
                OUT_LINK_UP      => open
            );

            tx_ftile_adapter_i : entity work.TX_MAC_LITE_ADAPTER_MAC_SEG
            generic map(
                REGIONS     => REGIONS,
                REGION_SIZE => REGION_SIZE
            )
            port map(
                CLK               => ftile_clk_out,
                RESET             => RESET_ETH,

                IN_MFB_DATA       => RX_MFB_DATA(0),
                IN_MFB_SOF        => RX_MFB_SOF(0),
                IN_MFB_EOF        => RX_MFB_EOF(0),
                IN_MFB_SOF_POS    => RX_MFB_SOF_POS(0),
                IN_MFB_EOF_POS    => RX_MFB_EOF_POS(0),
                IN_MFB_ERROR      => (others => '0'),
                IN_MFB_SRC_RDY    => RX_MFB_SRC_RDY(0),
                IN_MFB_DST_RDY    => RX_MFB_DST_RDY(0),

                OUT_MAC_DATA      => ftile_tx_mac_data(0),
                OUT_MAC_INFRAME   => ftile_tx_mac_inframe(0),
                OUT_MAC_EOP_EMPTY => ftile_tx_mac_eop_empty(0),
                OUT_MAC_ERROR     => ftile_tx_mac_error(0),
                OUT_MAC_VALID     => ftile_tx_mac_valid(0),
                OUT_MAC_READY     => ftile_tx_mac_ready(0)
            );

        when 200 =>
            -- =========================================================================
            -- F-TILE PLL
            -- =========================================================================
            ftile_pll_ip_i : component ftile_pll_2x200g
            port map (
                out_systempll_synthlock_0 => open,
                out_systempll_clk_0       => ftile_pll_clk,
                out_refclk_fgt_0          => ftile_pll_refclk,
                in_refclk_fgt_0           => QSFP_REFCLK_P
            );

            -- only one of these is needed to drive all other IP cores and such
            ftile_clk_out <= ftile_clk_out_vec(0);
            CLK_ETH       <= ftile_clk_out;

            -- Distribution of serial lanes to IP cores
            qsfp_rx_p_sig <= slv_array_deser(QSFP_RX_P, ETH_PORT_CHAN);
            qsfp_rx_n_sig <= slv_array_deser(QSFP_RX_N, ETH_PORT_CHAN);
            QSFP_TX_P <= slv_array_ser(qsfp_tx_p_sig);
            QSFP_TX_N <= slv_array_ser(qsfp_tx_n_sig);

            -- can have upto two 200g channels
            eth_ftile_g : for i in ETH_PORT_CHAN-1 downto 0 generate
                -- =========================================================================
                -- F-TILE Ethernet
                -- =========================================================================
                ftile_eth_ip_i : component ftile_eth_2x200g
                port map (
                    i_clk_tx                        => ftile_clk_out,
                    i_clk_rx                        => ftile_clk_out,
                    o_clk_pll                       => ftile_clk_out_vec(i),
                    o_clk_tx_div                    => open,
                    o_clk_rec_div64                 => open,
                    o_clk_rec_div                   => open,
                    i_tx_rst_n                      => '1',
                    i_rx_rst_n                      => ftile_rx_rst_n(i),
                    i_rst_n                         => not RESET_ETH,
                    o_rst_ack_n                     => open,
                    o_tx_rst_ack_n                  => open,
                    o_rx_rst_ack_n                  => ftile_rx_rst_ack_n(i),
                    i_reconfig_clk                  => MI_CLK_PHY,
                    i_reconfig_reset                => MI_RESET_PHY,
                    o_cdr_lock                      => open,
                    o_tx_pll_locked                 => open,
                    o_tx_lanes_stable               => ftile_tx_lanes_stable(i),
                    o_rx_pcs_ready                  => ftile_rx_pcs_ready(i),
                    o_tx_serial                     => qsfp_tx_p_sig(i),
                    i_rx_serial                     => qsfp_rx_p_sig(i),
                    o_tx_serial_n                   => qsfp_tx_n_sig(i),
                    i_rx_serial_n                   => qsfp_rx_n_sig(i),
                    i_clk_ref                       => ftile_pll_refclk,
                    i_clk_sys                       => ftile_pll_clk,
                    -- Eth (+ RSFEC + transciever) reconfig infs (0x1 downto 0x0)
                    i_reconfig_eth_addr             => mi_ia_addr_phy  (i)(14-1 downto 0),
                    i_reconfig_eth_byteenable       => (others => '1')    ,
                    o_reconfig_eth_readdata_valid   => mi_ia_drdy_phy  (i),
                    i_reconfig_eth_read             => mi_ia_rd_phy    (i),
                    i_reconfig_eth_write            => mi_ia_wr_phy    (i),
                    o_reconfig_eth_readdata         => mi_ia_drd_phy   (i),
                    i_reconfig_eth_writedata        => mi_ia_dwr_phy   (i),
                    o_reconfig_eth_waitrequest      => mi_ia_ardy_phy_n(i),
                    -- mi_ia_xxx(item); item = XCVR ID per IP core + IP core offset + Eth infs offset
                    -- XCVR reconfig inf (0x6 for IP core #1
                    --                 or 0x2 for IP core #0)
                    i_reconfig_xcvr0_addr           => mi_ia_addr_phy  (0 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN)(18-1 downto 0),
                    i_reconfig_xcvr0_byteenable     => (others => '1')                                          ,
                    o_reconfig_xcvr0_readdata_valid => mi_ia_drdy_phy  (0 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                    i_reconfig_xcvr0_read           => mi_ia_rd_phy    (0 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                    i_reconfig_xcvr0_write          => mi_ia_wr_phy    (0 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                    o_reconfig_xcvr0_readdata       => mi_ia_drd_phy   (0 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                    i_reconfig_xcvr0_writedata      => mi_ia_dwr_phy   (0 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                    o_reconfig_xcvr0_waitrequest    => mi_ia_ardy_phy_n(0 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                    -- XCVR reconfig inf (0x7 for IP core #1
                    --                 or 0x3 for IP core #0)
                    i_reconfig_xcvr1_addr           => mi_ia_addr_phy  (1 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN)(18-1 downto 0),
                    i_reconfig_xcvr1_byteenable     => (others => '1')                                          ,
                    o_reconfig_xcvr1_readdata_valid => mi_ia_drdy_phy  (1 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                    i_reconfig_xcvr1_read           => mi_ia_rd_phy    (1 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                    i_reconfig_xcvr1_write          => mi_ia_wr_phy    (1 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                    o_reconfig_xcvr1_readdata       => mi_ia_drd_phy   (1 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                    i_reconfig_xcvr1_writedata      => mi_ia_dwr_phy   (1 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                    o_reconfig_xcvr1_waitrequest    => mi_ia_ardy_phy_n(1 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                    -- XCVR reconfig inf (0x8 for IP core #1
                    --                 or 0x4 for IP core #0)
                    i_reconfig_xcvr2_addr           => mi_ia_addr_phy  (2 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN)(18-1 downto 0),
                    i_reconfig_xcvr2_byteenable     => (others => '1')                                          ,
                    o_reconfig_xcvr2_readdata_valid => mi_ia_drdy_phy  (2 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                    i_reconfig_xcvr2_read           => mi_ia_rd_phy    (2 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                    i_reconfig_xcvr2_write          => mi_ia_wr_phy    (2 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                    o_reconfig_xcvr2_readdata       => mi_ia_drd_phy   (2 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                    i_reconfig_xcvr2_writedata      => mi_ia_dwr_phy   (2 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                    o_reconfig_xcvr2_waitrequest    => mi_ia_ardy_phy_n(2 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                    -- XCVR reconfig inf (0x9 for IP core #1
                    --                 or 0x5 for IP core #0)
                    i_reconfig_xcvr3_addr           => mi_ia_addr_phy  (3 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN)(18-1 downto 0),
                    i_reconfig_xcvr3_byteenable     => (others => '1')                                          ,
                    o_reconfig_xcvr3_readdata_valid => mi_ia_drdy_phy  (3 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                    i_reconfig_xcvr3_read           => mi_ia_rd_phy    (3 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                    i_reconfig_xcvr3_write          => mi_ia_wr_phy    (3 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                    o_reconfig_xcvr3_readdata       => mi_ia_drd_phy   (3 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                    i_reconfig_xcvr3_writedata      => mi_ia_dwr_phy   (3 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                    o_reconfig_xcvr3_waitrequest    => mi_ia_ardy_phy_n(3 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                    o_rx_block_lock                 => ftile_rx_block_lock(i),
                    o_rx_am_lock                    => ftile_rx_am_lock(i),
                    o_local_fault_status            => ftile_local_fault(i),
                    o_remote_fault_status           => ftile_remote_fault(i),
                    i_stats_snapshot                => '0',
                    o_rx_hi_ber                     => ftile_rx_hi_ber(i),
                    o_rx_pcs_fully_aligned          => ftile_rx_pcs_fully_aligned(i),
                    i_tx_mac_data                   => ftile_tx_mac_data(i),
                    i_tx_mac_valid                  => ftile_tx_mac_valid(i),
                    i_tx_mac_inframe                => ftile_tx_mac_inframe(i),
                    i_tx_mac_eop_empty              => ftile_tx_mac_eop_empty(i),
                    o_tx_mac_ready                  => ftile_tx_mac_ready(i),
                    i_tx_mac_error                  => ftile_tx_mac_error(i),
                    i_tx_mac_skip_crc               => (others => '0'), 
                    o_rx_mac_data                   => ftile_rx_mac_data(i),
                    o_rx_mac_valid                  => ftile_rx_mac_valid(i),
                    o_rx_mac_inframe                => ftile_rx_mac_inframe(i),
                    o_rx_mac_eop_empty              => ftile_rx_mac_eop_empty(i),
                    o_rx_mac_fcs_error              => ftile_rx_mac_fcs_error(i),
                    o_rx_mac_error                  => ftile_rx_mac_error(i),
                    o_rx_mac_status                 => ftile_rx_mac_status(i),
                    i_tx_pfc                        => (others => '0'),
                    o_rx_pfc                        => open,
                    i_tx_pause                      => '0',
                    o_rx_pause                      => open
                );

                process(ftile_clk_out)
                begin
                    if rising_edge(ftile_clk_out) then
                        if (RESET_ETH = '1') then
                            RX_LINK_UP(i) <= '0';
                            TX_LINK_UP(i) <= '0';
                        else
                            RX_LINK_UP(i) <= ftile_rx_pcs_ready(i) and ftile_rx_pcs_fully_aligned(i) and (not ftile_remote_fault(i));
                            TX_LINK_UP(i) <= ftile_tx_lanes_stable(i);
                        end if;
                    end if;
                end process;

                -- =========================================================================
                --  Loopback (repeater) control
                -- =========================================================================
                -- Synchronization of REPEATER_CTRL
                -- sync_repeater_ctrl_i : entity work.ASYNC_BUS_HANDSHAKE
                -- generic map (
                --     DATA_WIDTH => 2
                -- ) port map (
                --     ACLK       => MI_CLK_PHY,
                --     ARST       => MI_RESET_PHY,
                --     ADATAIN    => REPEATER_CTRL,
                --     ASEND      => '1',
                --     AREADY     => open,
                --     BCLK       => ftile_clk_out,
                --     BRST       => '0',
                --     BDATAOUT   => sync_repeater_ctrl,
                --     BLOAD      => '1',
                --     BVALID     => open
                -- );

                -- =========================================================================
                -- ADAPTERS
                -- =========================================================================
                rx_ftile_adapter_i : entity work.RX_MAC_LITE_ADAPTER_MAC_SEG
                generic map(
                    REGIONS     => REGIONS,
                    REGION_SIZE => REGION_SIZE
                )
                port map(
                    CLK              => ftile_clk_out,
                    RESET            => RESET_ETH,

                    IN_MAC_DATA      => ftile_rx_mac_data(i),
                    IN_MAC_INFRAME   => ftile_rx_mac_inframe(i),
                    IN_MAC_EOP_EMPTY => ftile_rx_mac_eop_empty(i),
                    IN_MAC_FCS_ERROR => ftile_rx_mac_fcs_error(i),
                    IN_MAC_ERROR     => ftile_rx_mac_error(i),
                    IN_MAC_STATUS    => ftile_rx_mac_status(i),
                    IN_MAC_VALID     => ftile_rx_mac_valid(i),

                    OUT_MFB_DATA     => TX_MFB_DATA(i),
                    OUT_MFB_ERROR    => TX_MFB_ERROR(i),
                    OUT_MFB_SOF      => TX_MFB_SOF(i),
                    OUT_MFB_EOF      => TX_MFB_EOF(i),
                    OUT_MFB_SOF_POS  => TX_MFB_SOF_POS(i),
                    OUT_MFB_EOF_POS  => TX_MFB_EOF_POS(i),
                    OUT_MFB_SRC_RDY  => TX_MFB_SRC_RDY(i),
                    OUT_LINK_UP      => open
                );

                tx_ftile_adapter_i : entity work.TX_MAC_LITE_ADAPTER_MAC_SEG
                generic map(
                    REGIONS     => REGIONS,
                    REGION_SIZE => REGION_SIZE
                )
                port map(
                    CLK               => ftile_clk_out,
                    RESET             => RESET_ETH,

                    IN_MFB_DATA       => RX_MFB_DATA(i),
                    IN_MFB_SOF        => RX_MFB_SOF(i),
                    IN_MFB_EOF        => RX_MFB_EOF(i),
                    IN_MFB_SOF_POS    => RX_MFB_SOF_POS(i),
                    IN_MFB_EOF_POS    => RX_MFB_EOF_POS(i),
                    IN_MFB_ERROR      => (others => '0'),
                    IN_MFB_SRC_RDY    => RX_MFB_SRC_RDY(i),
                    IN_MFB_DST_RDY    => RX_MFB_DST_RDY(i),

                    OUT_MAC_DATA      => ftile_tx_mac_data(i),
                    OUT_MAC_INFRAME   => ftile_tx_mac_inframe(i),
                    OUT_MAC_EOP_EMPTY => ftile_tx_mac_eop_empty(i),
                    OUT_MAC_ERROR     => ftile_tx_mac_error(i),
                    OUT_MAC_VALID     => ftile_tx_mac_valid(i),
                    OUT_MAC_READY     => ftile_tx_mac_ready(i)
                );
            end generate;

        when 100 =>
            -- =========================================================================
            -- F-TILE PLL
            -- =========================================================================
            ftile_pll_ip_i : component ftile_pll_4x100g
            port map (
                out_systempll_synthlock_0 => open,
                out_systempll_clk_0       => ftile_pll_clk,
                out_refclk_fgt_0          => ftile_pll_refclk,
                in_refclk_fgt_0           => QSFP_REFCLK_P
            );

            -- only one of these is needed to drive all other IP cores and such
            ftile_clk_out <= ftile_clk_out_vec(0);
            CLK_ETH       <= ftile_clk_out;

            pam4_100g_g: if (ETH_PORT_CHAN = 4) generate

                -- Distribution of serial lanes to IP cores
                qsfp_rx_p_sig <= slv_array_deser(QSFP_RX_P, ETH_PORT_CHAN);
                qsfp_rx_n_sig <= slv_array_deser(QSFP_RX_N, ETH_PORT_CHAN);
                QSFP_TX_P <= slv_array_ser(qsfp_tx_p_sig);
                QSFP_TX_N <= slv_array_ser(qsfp_tx_n_sig);

                -- can have upto four 100g-2 (PAM4) channels
                eth_ftile_g : for i in ETH_PORT_CHAN-1 downto 0 generate
                    -- =========================================================================
                    -- F-TILE Ethernet
                    -- =========================================================================
                    ftile_eth_ip_i : component ftile_eth_4x100g
                    port map (
                        i_clk_tx                        => ftile_clk_out,
                        i_clk_rx                        => ftile_clk_out,
                        o_clk_pll                       => ftile_clk_out_vec(i),
                        o_clk_tx_div                    => open,
                        o_clk_rec_div64                 => open,
                        o_clk_rec_div                   => open,
                        i_tx_rst_n                      => '1',
                        i_rx_rst_n                      => ftile_rx_rst_n(i),
                        i_rst_n                         => not RESET_ETH,
                        o_rst_ack_n                     => open,
                        o_tx_rst_ack_n                  => open,
                        o_rx_rst_ack_n                  => ftile_rx_rst_ack_n(i),
                        i_reconfig_clk                  => MI_CLK_PHY,
                        i_reconfig_reset                => MI_RESET_PHY,
                        o_cdr_lock                      => open,
                        o_tx_pll_locked                 => open,
                        o_tx_lanes_stable               => ftile_tx_lanes_stable(i),
                        o_rx_pcs_ready                  => ftile_rx_pcs_ready(i),
                        o_tx_serial                     => qsfp_tx_p_sig(i),
                        i_rx_serial                     => qsfp_rx_p_sig(i),
                        o_tx_serial_n                   => qsfp_tx_n_sig(i),
                        i_rx_serial_n                   => qsfp_rx_n_sig(i),
                        i_clk_ref                       => ftile_pll_refclk,
                        i_clk_sys                       => ftile_pll_clk,
                        -- Eth (+ RSFEC + transciever) reconfig infs (0x3 downto 0x0)
                        i_reconfig_eth_addr             => mi_ia_addr_phy  (i)(14-1 downto 0),
                        i_reconfig_eth_byteenable       => (others => '1')    ,
                        o_reconfig_eth_readdata_valid   => mi_ia_drdy_phy  (i),
                        i_reconfig_eth_read             => mi_ia_rd_phy    (i),
                        i_reconfig_eth_write            => mi_ia_wr_phy    (i),
                        o_reconfig_eth_readdata         => mi_ia_drd_phy   (i),
                        i_reconfig_eth_writedata        => mi_ia_dwr_phy   (i),
                        o_reconfig_eth_waitrequest      => mi_ia_ardy_phy_n(i),
                        -- mi_ia_xxx(item); item = XCVR ID per IP core + IP core offset + Eth infs offset
                        -- XCVR reconfig inf (0x10 for IP core #3 or 0x8 for IP core #2 or 0x6 for IP core #1 or 0x4 for IP core #0)
                        i_reconfig_xcvr0_addr           => mi_ia_addr_phy  (0 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN)(18-1 downto 0),
                        i_reconfig_xcvr0_byteenable     => (others => '1')                                          ,
                        o_reconfig_xcvr0_readdata_valid => mi_ia_drdy_phy  (0 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                        i_reconfig_xcvr0_read           => mi_ia_rd_phy    (0 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                        i_reconfig_xcvr0_write          => mi_ia_wr_phy    (0 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                        o_reconfig_xcvr0_readdata       => mi_ia_drd_phy   (0 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                        i_reconfig_xcvr0_writedata      => mi_ia_dwr_phy   (0 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                        o_reconfig_xcvr0_waitrequest    => mi_ia_ardy_phy_n(0 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                        -- XCVR reconfig inf (0x7 for IP1 or 0x3 for IP0)
                        i_reconfig_xcvr1_addr           => mi_ia_addr_phy  (1 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN)(18-1 downto 0),
                        i_reconfig_xcvr1_byteenable     => (others => '1')                                          ,
                        o_reconfig_xcvr1_readdata_valid => mi_ia_drdy_phy  (1 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                        i_reconfig_xcvr1_read           => mi_ia_rd_phy    (1 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                        i_reconfig_xcvr1_write          => mi_ia_wr_phy    (1 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                        o_reconfig_xcvr1_readdata       => mi_ia_drd_phy   (1 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                        i_reconfig_xcvr1_writedata      => mi_ia_dwr_phy   (1 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                        o_reconfig_xcvr1_waitrequest    => mi_ia_ardy_phy_n(1 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                        o_rx_block_lock                 => ftile_rx_block_lock(i),
                        o_rx_am_lock                    => ftile_rx_am_lock(i),
                        o_local_fault_status            => ftile_local_fault(i),
                        o_remote_fault_status           => ftile_remote_fault(i),
                        i_stats_snapshot                => '0',
                        o_rx_hi_ber                     => ftile_rx_hi_ber(i),
                        o_rx_pcs_fully_aligned          => ftile_rx_pcs_fully_aligned(i),
                        i_tx_mac_data                   => ftile_tx_mac_data(i),
                        i_tx_mac_valid                  => ftile_tx_mac_valid(i),
                        i_tx_mac_inframe                => ftile_tx_mac_inframe(i),
                        i_tx_mac_eop_empty              => ftile_tx_mac_eop_empty(i),
                        o_tx_mac_ready                  => ftile_tx_mac_ready(i),
                        i_tx_mac_error                  => ftile_tx_mac_error(i),
                        i_tx_mac_skip_crc               => (others => '0'),
                        o_rx_mac_data                   => ftile_rx_mac_data(i),
                        o_rx_mac_valid                  => ftile_rx_mac_valid(i),
                        o_rx_mac_inframe                => ftile_rx_mac_inframe(i),
                        o_rx_mac_eop_empty              => ftile_rx_mac_eop_empty(i),
                        o_rx_mac_fcs_error              => ftile_rx_mac_fcs_error(i),
                        o_rx_mac_error                  => ftile_rx_mac_error(i),
                        o_rx_mac_status                 => ftile_rx_mac_status(i),
                        i_tx_pfc                        => (others => '0'),
                        o_rx_pfc                        => open,
                        i_tx_pause                      => '0',
                        o_rx_pause                      => open
                    );

                    process(ftile_clk_out)
                    begin
                        if rising_edge(ftile_clk_out) then
                            if (RESET_ETH = '1') then
                                RX_LINK_UP(i) <= '0';
                                TX_LINK_UP(i) <= '0';
                            else
                                RX_LINK_UP(i) <= ftile_rx_pcs_ready(i) and ftile_rx_pcs_fully_aligned(i) and (not ftile_remote_fault(i));
                                TX_LINK_UP(i) <= ftile_tx_lanes_stable(i);
                            end if;
                        end if;
                    end process;

                end generate;

            else generate

                -- Distribution of serial lanes to IP cores
                qsfp_rx_p_sig <= slv_array_deser(QSFP_RX_P, ETH_PORT_CHAN);
                qsfp_rx_n_sig <= slv_array_deser(QSFP_RX_N, ETH_PORT_CHAN);
                QSFP_TX_P <= slv_array_ser(qsfp_tx_p_sig);
                QSFP_TX_N <= slv_array_ser(qsfp_tx_n_sig);

                -- 100G-4 NRZ (up to 2 channels)
                eth_ftile_g : for i in ETH_PORT_CHAN-1 downto 0 generate
                begin 
                    -- =========================================================================
                    -- F-TILE Ethernet
                    -- =========================================================================

                   ftile_eth_ip_i : component ftile_eth_2x100g
                   port map (
                        i_clk_tx                        => ftile_clk_out,
                        i_clk_rx                        => ftile_clk_out,
                        o_clk_pll                       => ftile_clk_out_vec(i),
                        o_clk_tx_div                    => open,
                        o_clk_rec_div64                 => open,
                        o_clk_rec_div                   => open,
                        i_tx_rst_n                      => '1',
                        i_rx_rst_n                      => ftile_rx_rst_n(i),
                        i_rst_n                         => not RESET_ETH,
                        o_rst_ack_n                     => open,
                        o_tx_rst_ack_n                  => open,
                        o_rx_rst_ack_n                  => ftile_rx_rst_ack_n(i),
                        i_reconfig_clk                  => MI_CLK_PHY,
                        i_reconfig_reset                => MI_RESET_PHY,
                        o_cdr_lock                      => open,
                        o_tx_pll_locked                 => open,
                        o_tx_lanes_stable               => ftile_tx_lanes_stable(i),
                        o_rx_pcs_ready                  => ftile_rx_pcs_ready(i),
                        o_tx_serial                     => qsfp_tx_p_sig(i),
                        i_rx_serial                     => qsfp_rx_p_sig(i),
                        o_tx_serial_n                   => qsfp_tx_n_sig(i),
                        i_rx_serial_n                   => qsfp_rx_n_sig(i),
                        i_clk_ref                       => ftile_pll_refclk,
                        i_clk_sys                       => ftile_pll_clk,
                        -- Eth (+ RSFEC + transciever) reconfig infs (0x3 downto 0x0)
                        i_reconfig_eth_addr             => mi_ia_addr_phy  (i)(14-1 downto 0),
                        i_reconfig_eth_byteenable       => (others => '1')    ,
                        o_reconfig_eth_readdata_valid   => mi_ia_drdy_phy  (i),
                        i_reconfig_eth_read             => mi_ia_rd_phy    (i),
                        i_reconfig_eth_write            => mi_ia_wr_phy    (i),
                        o_reconfig_eth_readdata         => mi_ia_drd_phy   (i),
                        i_reconfig_eth_writedata        => mi_ia_dwr_phy   (i),
                        o_reconfig_eth_waitrequest      => mi_ia_ardy_phy_n(i),
                        -- mi_ia_xxx(item); item = XCVR ID per IP core + IP core offset + Eth infs offset
                        -- XCVR reconfig inf 
                        i_reconfig_xcvr0_addr           => mi_ia_addr_phy  (0 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN)(18-1 downto 0),
                        i_reconfig_xcvr0_byteenable     => (others => '1')                                          ,
                        o_reconfig_xcvr0_readdata_valid => mi_ia_drdy_phy  (0 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                        i_reconfig_xcvr0_read           => mi_ia_rd_phy    (0 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                        i_reconfig_xcvr0_write          => mi_ia_wr_phy    (0 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                        o_reconfig_xcvr0_readdata       => mi_ia_drd_phy   (0 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                        i_reconfig_xcvr0_writedata      => mi_ia_dwr_phy   (0 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                        o_reconfig_xcvr0_waitrequest    => mi_ia_ardy_phy_n(0 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                        -- XCVR reconfig inf
                        i_reconfig_xcvr1_addr           => mi_ia_addr_phy  (1 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN)(18-1 downto 0),
                        i_reconfig_xcvr1_byteenable     => (others => '1')                                          ,
                        o_reconfig_xcvr1_readdata_valid => mi_ia_drdy_phy  (1 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                        i_reconfig_xcvr1_read           => mi_ia_rd_phy    (1 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                        i_reconfig_xcvr1_write          => mi_ia_wr_phy    (1 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                        o_reconfig_xcvr1_readdata       => mi_ia_drd_phy   (1 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                        i_reconfig_xcvr1_writedata      => mi_ia_dwr_phy   (1 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                        o_reconfig_xcvr1_waitrequest    => mi_ia_ardy_phy_n(1 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                        -- XCVR reconfig inf (0x7 for IP1 or 0x3 for IP0)
                        i_reconfig_xcvr2_addr           => mi_ia_addr_phy  (2 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN)(18-1 downto 0),
                        i_reconfig_xcvr2_byteenable     => (others => '1')                                          ,
                        o_reconfig_xcvr2_readdata_valid => mi_ia_drdy_phy  (2 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                        i_reconfig_xcvr2_read           => mi_ia_rd_phy    (2 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                        i_reconfig_xcvr2_write          => mi_ia_wr_phy    (2 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                        o_reconfig_xcvr2_readdata       => mi_ia_drd_phy   (2 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                        i_reconfig_xcvr2_writedata      => mi_ia_dwr_phy   (2 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                        o_reconfig_xcvr2_waitrequest    => mi_ia_ardy_phy_n(2 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                        -- XCVR reconfig inf
                        i_reconfig_xcvr3_addr           => mi_ia_addr_phy  (3 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN)(18-1 downto 0),
                        i_reconfig_xcvr3_byteenable     => (others => '1')                                          ,
                        o_reconfig_xcvr3_readdata_valid => mi_ia_drdy_phy  (3 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                        i_reconfig_xcvr3_read           => mi_ia_rd_phy    (3 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                        i_reconfig_xcvr3_write          => mi_ia_wr_phy    (3 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                        o_reconfig_xcvr3_readdata       => mi_ia_drd_phy   (3 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                        i_reconfig_xcvr3_writedata      => mi_ia_dwr_phy   (3 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                        o_reconfig_xcvr3_waitrequest    => mi_ia_ardy_phy_n(3 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                        --
                        o_rx_block_lock                 => ftile_rx_block_lock(i),
                        o_rx_am_lock                    => ftile_rx_am_lock(i),
                        o_local_fault_status            => ftile_local_fault(i),
                        o_remote_fault_status           => ftile_remote_fault(i),
                        i_stats_snapshot                => '0',
                        o_rx_hi_ber                     => ftile_rx_hi_ber(i),
                        o_rx_pcs_fully_aligned          => ftile_rx_pcs_fully_aligned(i),
                        i_tx_mac_data                   => ftile_tx_mac_data(i),
                        i_tx_mac_valid                  => ftile_tx_mac_valid(i),
                        i_tx_mac_inframe                => ftile_tx_mac_inframe(i),
                        i_tx_mac_eop_empty              => ftile_tx_mac_eop_empty(i),
                        o_tx_mac_ready                  => ftile_tx_mac_ready(i),
                        i_tx_mac_error                  => ftile_tx_mac_error(i),
                        i_tx_mac_skip_crc               => (others => '0'),
                        o_rx_mac_data                   => ftile_rx_mac_data(i),
                        o_rx_mac_valid                  => ftile_rx_mac_valid(i),
                        o_rx_mac_inframe                => ftile_rx_mac_inframe(i),
                        o_rx_mac_eop_empty              => ftile_rx_mac_eop_empty(i),
                        o_rx_mac_fcs_error              => ftile_rx_mac_fcs_error(i),
                        o_rx_mac_error                  => ftile_rx_mac_error(i),
                        o_rx_mac_status                 => ftile_rx_mac_status(i),
                        i_tx_pfc                        => (others => '0'),
                        o_rx_pfc                        => open,
                        i_tx_pause                      => '0',
                        o_rx_pause                      => open
                    );

                    process(ftile_clk_out)
                    begin
                        if rising_edge(ftile_clk_out) then
                            if (RESET_ETH = '1') then
                                RX_LINK_UP(i) <= '0';
                                TX_LINK_UP(i) <= '0';
                            else
                                RX_LINK_UP(i) <= ftile_rx_pcs_ready(i) and ftile_rx_pcs_fully_aligned(i) and (not ftile_remote_fault(i));
                                TX_LINK_UP(i) <= ftile_tx_lanes_stable(i);
                            end if;
                        end if;
                    end process;

                end generate; -- for ... 2x100GE IP

                -- =========================================================================
                -- ADAPTERS
                -- =========================================================================

                eth_adapt_g : for i in ETH_PORT_CHAN-1 downto 0 generate

                    rx_ftile_adapter_i : entity work.RX_MAC_LITE_ADAPTER_MAC_SEG
                    generic map(
                        REGIONS     => REGIONS,
                        REGION_SIZE => REGION_SIZE
                    )
                    port map(
                        CLK              => ftile_clk_out,
                        RESET            => RESET_ETH,

                        IN_MAC_DATA      => ftile_rx_mac_data(i),
                        IN_MAC_INFRAME   => ftile_rx_mac_inframe(i),
                        IN_MAC_EOP_EMPTY => ftile_rx_mac_eop_empty(i),
                        IN_MAC_FCS_ERROR => ftile_rx_mac_fcs_error(i),
                        IN_MAC_ERROR     => ftile_rx_mac_error(i),
                        IN_MAC_STATUS    => ftile_rx_mac_status(i),
                        IN_MAC_VALID     => ftile_rx_mac_valid(i),

                        OUT_MFB_DATA     => TX_MFB_DATA(i),
                        OUT_MFB_ERROR    => TX_MFB_ERROR(i),
                        OUT_MFB_SOF      => TX_MFB_SOF(i),
                        OUT_MFB_EOF      => TX_MFB_EOF(i),
                        OUT_MFB_SOF_POS  => TX_MFB_SOF_POS(i),
                        OUT_MFB_EOF_POS  => TX_MFB_EOF_POS(i),
                        OUT_MFB_SRC_RDY  => TX_MFB_SRC_RDY(i),
                        OUT_LINK_UP      => open
                    );

                    tx_ftile_adapter_i : entity work.TX_MAC_LITE_ADAPTER_MAC_SEG
                    generic map(
                        REGIONS     => REGIONS,
                        REGION_SIZE => REGION_SIZE
                    )
                    port map(
                        CLK               => ftile_clk_out,
                        RESET             => RESET_ETH,

                        IN_MFB_DATA       => RX_MFB_DATA(i),
                        IN_MFB_SOF        => RX_MFB_SOF(i),
                        IN_MFB_EOF        => RX_MFB_EOF(i),
                        IN_MFB_SOF_POS    => RX_MFB_SOF_POS(i),
                        IN_MFB_EOF_POS    => RX_MFB_EOF_POS(i),
                        IN_MFB_ERROR      => (others => '0'),
                        IN_MFB_SRC_RDY    => RX_MFB_SRC_RDY(i),
                        IN_MFB_DST_RDY    => RX_MFB_DST_RDY(i),

                        OUT_MAC_DATA      => ftile_tx_mac_data(i),
                        OUT_MAC_INFRAME   => ftile_tx_mac_inframe(i),
                        OUT_MAC_EOP_EMPTY => ftile_tx_mac_eop_empty(i),
                        OUT_MAC_ERROR     => ftile_tx_mac_error(i),
                        OUT_MAC_VALID     => ftile_tx_mac_valid(i),
                        OUT_MAC_READY     => ftile_tx_mac_ready(i)
                    );
                end generate; -- eth_adapt

            end generate; -- 100

        when 50 =>
            -- =========================================================================
            -- F-TILE PLL
            -- =========================================================================
            ftile_pll_ip_i : component ftile_pll_8x50g
            port map (
                out_systempll_synthlock_0 => open,
                out_systempll_clk_0       => ftile_pll_clk,
                out_refclk_fgt_0          => ftile_pll_refclk,
                in_refclk_fgt_0           => QSFP_REFCLK_P
            );

            -- only one of these is needed to drive all other IP cores and such
            ftile_clk_out <= ftile_clk_out_vec(0);
            CLK_ETH       <= ftile_clk_out;

            -- Distribution of serial lanes to IP cores
            qsfp_rx_p_sig <= slv_array_deser(QSFP_RX_P, ETH_PORT_CHAN);
            qsfp_rx_n_sig <= slv_array_deser(QSFP_RX_N, ETH_PORT_CHAN);
            QSFP_TX_P <= slv_array_ser(qsfp_tx_p_sig);
            QSFP_TX_N <= slv_array_ser(qsfp_tx_n_sig);

            -- can have upto eight 50g lanes
            eth_ftile_g : for i in ETH_PORT_CHAN-1 downto 0 generate
                -- =========================================================================
                -- F-TILE Ethernet
                -- =========================================================================
                ftile_eth_ip_i : component ftile_eth_8x50g
                port map (
                    i_clk_tx                        => ftile_clk_out,
                    i_clk_rx                        => ftile_clk_out,
                    o_clk_pll                       => ftile_clk_out_vec(i),
                    o_clk_tx_div                    => open,
                    o_clk_rec_div64                 => open,
                    o_clk_rec_div                   => open,
                    i_tx_rst_n                      => '1',
                    i_rx_rst_n                      => ftile_rx_rst_n(i),
                    i_rst_n                         => not RESET_ETH,
                    o_rst_ack_n                     => open,
                    o_tx_rst_ack_n                  => open,
                    o_rx_rst_ack_n                  => ftile_rx_rst_ack_n(i),
                    i_reconfig_clk                  => MI_CLK_PHY,
                    i_reconfig_reset                => MI_RESET_PHY,
                    o_cdr_lock                      => open,
                    o_tx_pll_locked                 => open,
                    o_tx_lanes_stable               => ftile_tx_lanes_stable(i),
                    o_rx_pcs_ready                  => ftile_rx_pcs_ready(i),
                    o_tx_serial                     => qsfp_tx_p_sig(i),
                    i_rx_serial                     => qsfp_rx_p_sig(i),
                    o_tx_serial_n                   => qsfp_tx_n_sig(i),
                    i_rx_serial_n                   => qsfp_rx_n_sig(i),
                    i_clk_ref                       => ftile_pll_refclk,
                    i_clk_sys                       => ftile_pll_clk,
                    -- Eth (+ RSFEC + transciever) reconfig infs (0x7 downto 0x0)
                    i_reconfig_eth_addr             => mi_ia_addr_phy  (i)(14-1 downto 0),
                    i_reconfig_eth_byteenable       => (others => '1')    ,
                    o_reconfig_eth_readdata_valid   => mi_ia_drdy_phy  (i),
                    i_reconfig_eth_read             => mi_ia_rd_phy    (i),
                    i_reconfig_eth_write            => mi_ia_wr_phy    (i),
                    o_reconfig_eth_readdata         => mi_ia_drd_phy   (i),
                    i_reconfig_eth_writedata        => mi_ia_dwr_phy   (i),
                    o_reconfig_eth_waitrequest      => mi_ia_ardy_phy_n(i),
                    -- mi_ia_xxx(item); item = IP core offset + Eth infs offset
                    -- XCVR reconfig inf (0x15 for IP core #7
                    --                 or 0x14 for IP core #6
                    --                 or 0x13 for IP core #5
                    --                 or 0x12 for IP core #4
                    --                 or 0x11 for IP core #3
                    --                 or 0x10 for IP core #2
                    --                 or 0x9  for IP core #1
                    --                 or 0x8  for IP core #0)
                    i_reconfig_xcvr0_addr           => mi_ia_addr_phy  (i + ETH_PORT_CHAN)(18-1 downto 0),
                    i_reconfig_xcvr0_byteenable     => (others => '1')                    ,
                    o_reconfig_xcvr0_readdata_valid => mi_ia_drdy_phy  (i + ETH_PORT_CHAN),
                    i_reconfig_xcvr0_read           => mi_ia_rd_phy    (i + ETH_PORT_CHAN),
                    i_reconfig_xcvr0_write          => mi_ia_wr_phy    (i + ETH_PORT_CHAN),
                    o_reconfig_xcvr0_readdata       => mi_ia_drd_phy   (i + ETH_PORT_CHAN),
                    i_reconfig_xcvr0_writedata      => mi_ia_dwr_phy   (i + ETH_PORT_CHAN),
                    o_reconfig_xcvr0_waitrequest    => mi_ia_ardy_phy_n(i + ETH_PORT_CHAN),
                    o_rx_block_lock                 => ftile_rx_block_lock(i),
                    o_rx_am_lock                    => ftile_rx_am_lock(i),
                    o_local_fault_status            => ftile_local_fault(i),
                    o_remote_fault_status           => ftile_remote_fault(i),
                    i_stats_snapshot                => '0',
                    o_rx_hi_ber                     => ftile_rx_hi_ber(i),
                    o_rx_pcs_fully_aligned          => ftile_rx_pcs_fully_aligned(i),
                    i_tx_mac_data                   => ftile_tx_mac_data(i),
                    i_tx_mac_valid                  => ftile_tx_mac_valid(i),
                    i_tx_mac_inframe                => ftile_tx_mac_inframe(i),
                    i_tx_mac_eop_empty              => ftile_tx_mac_eop_empty(i),
                    o_tx_mac_ready                  => ftile_tx_mac_ready(i),
                    i_tx_mac_error                  => ftile_tx_mac_error(i),
                    i_tx_mac_skip_crc               => (others => '0'),
                    o_rx_mac_data                   => ftile_rx_mac_data(i),
                    o_rx_mac_valid                  => ftile_rx_mac_valid(i),
                    o_rx_mac_inframe                => ftile_rx_mac_inframe(i),
                    o_rx_mac_eop_empty              => ftile_rx_mac_eop_empty(i),
                    o_rx_mac_fcs_error              => ftile_rx_mac_fcs_error(i),
                    o_rx_mac_error                  => ftile_rx_mac_error(i),
                    o_rx_mac_status                 => ftile_rx_mac_status(i),
                    i_tx_pfc                        => (others => '0'),
                    o_rx_pfc                        => open,
                    i_tx_pause                      => '0',
                    o_rx_pause                      => open
                );

                process(ftile_clk_out)
                begin
                    if rising_edge(ftile_clk_out) then
                        if (RESET_ETH = '1') then
                            RX_LINK_UP(i) <= '0';
                            TX_LINK_UP(i) <= '0';
                        else
                            RX_LINK_UP(i) <= ftile_rx_pcs_ready(i) and ftile_rx_pcs_fully_aligned(i) and (not ftile_remote_fault(i));
                            TX_LINK_UP(i) <= ftile_tx_lanes_stable(i);
                        end if;
                    end if;
                end process;

                -- =========================================================================
                -- ADAPTERS
                -- =========================================================================
                rx_ftile_adapter_i : entity work.RX_MAC_LITE_ADAPTER_MAC_SEG
                generic map(
                    REGIONS     => REGIONS,
                    REGION_SIZE => REGION_SIZE
                )
                port map(
                    CLK              => ftile_clk_out,
                    RESET            => RESET_ETH,

                    IN_MAC_DATA      => ftile_rx_mac_data(i),
                    IN_MAC_INFRAME   => ftile_rx_mac_inframe(i),
                    IN_MAC_EOP_EMPTY => ftile_rx_mac_eop_empty(i),
                    IN_MAC_FCS_ERROR => ftile_rx_mac_fcs_error(i),
                    IN_MAC_ERROR     => ftile_rx_mac_error(i),
                    IN_MAC_STATUS    => ftile_rx_mac_status(i),
                    IN_MAC_VALID     => ftile_rx_mac_valid(i),

                    OUT_MFB_DATA     => TX_MFB_DATA(i),
                    OUT_MFB_ERROR    => TX_MFB_ERROR(i),
                    OUT_MFB_SOF      => TX_MFB_SOF(i),
                    OUT_MFB_EOF      => TX_MFB_EOF(i),
                    OUT_MFB_SOF_POS  => TX_MFB_SOF_POS(i),
                    OUT_MFB_EOF_POS  => TX_MFB_EOF_POS(i),
                    OUT_MFB_SRC_RDY  => TX_MFB_SRC_RDY(i),
                    OUT_LINK_UP      => open
                );

                tx_ftile_adapter_i : entity work.TX_MAC_LITE_ADAPTER_MAC_SEG
                generic map(
                    REGIONS     => REGIONS,
                    REGION_SIZE => REGION_SIZE
                )
                port map(
                    CLK               => ftile_clk_out,
                    RESET             => RESET_ETH,

                    IN_MFB_DATA       => RX_MFB_DATA(i),
                    IN_MFB_SOF        => RX_MFB_SOF(i),
                    IN_MFB_EOF        => RX_MFB_EOF(i),
                    IN_MFB_SOF_POS    => RX_MFB_SOF_POS(i),
                    IN_MFB_EOF_POS    => RX_MFB_EOF_POS(i),
                    IN_MFB_ERROR      => (others => '0'),
                    IN_MFB_SRC_RDY    => RX_MFB_SRC_RDY(i),
                    IN_MFB_DST_RDY    => RX_MFB_DST_RDY(i),

                    OUT_MAC_DATA      => ftile_tx_mac_data(i),
                    OUT_MAC_INFRAME   => ftile_tx_mac_inframe(i),
                    OUT_MAC_EOP_EMPTY => ftile_tx_mac_eop_empty(i),
                    OUT_MAC_ERROR     => ftile_tx_mac_error(i),
                    OUT_MAC_VALID     => ftile_tx_mac_valid(i),
                    OUT_MAC_READY     => ftile_tx_mac_ready(i)
                );
            end generate;

        when 40 =>
            -- =========================================================================
            -- F-TILE PLL
            -- =========================================================================
            ftile_pll_ip_i : component ftile_pll_2x40g
            port map (
                out_systempll_synthlock_0 => open,
                out_systempll_clk_0       => ftile_pll_clk,
                out_refclk_fgt_0          => ftile_pll_refclk,
                in_refclk_fgt_0           => QSFP_REFCLK_P
            );

            -- only one of these is needed to drive all other IP cores and such
            ftile_clk_out <= ftile_clk_out_vec(0);
            CLK_ETH       <= ftile_clk_out;

            -- Distribution of serial lanes to IP cores
            qsfp_rx_p_sig <= slv_array_deser(QSFP_RX_P, ETH_PORT_CHAN);
            qsfp_rx_n_sig <= slv_array_deser(QSFP_RX_N, ETH_PORT_CHAN);
            QSFP_TX_P <= slv_array_ser(qsfp_tx_p_sig);
            QSFP_TX_N <= slv_array_ser(qsfp_tx_n_sig);

            -- can have upto two 40g lanes
            eth_ftile_g : for i in ETH_PORT_CHAN-1 downto 0 generate
                -- =========================================================================
                -- F-TILE Ethernet
                -- =========================================================================
                ftile_eth_ip_i : component ftile_eth_2x40g
                port map (
                    i_clk_tx                        => ftile_clk_out,
                    i_clk_rx                        => ftile_clk_out,
                    o_clk_pll                       => ftile_clk_out_vec(i),
                    o_clk_tx_div                    => open,
                    o_clk_rec_div64                 => open,
                    o_clk_rec_div                   => open,
                    i_tx_rst_n                      => '1',
                    i_rx_rst_n                      => ftile_rx_rst_n(i),
                    i_rst_n                         => not RESET_ETH,
                    o_rst_ack_n                     => open,
                    o_tx_rst_ack_n                  => open,
                    o_rx_rst_ack_n                  => ftile_rx_rst_ack_n(i),
                    i_reconfig_clk                  => MI_CLK_PHY,
                    i_reconfig_reset                => MI_RESET_PHY,
                    o_cdr_lock                      => open,
                    o_tx_pll_locked                 => open,
                    o_tx_lanes_stable               => ftile_tx_lanes_stable(i),
                    o_rx_pcs_ready                  => ftile_rx_pcs_ready(i),
                    o_tx_serial                     => qsfp_tx_p_sig(i),
                    i_rx_serial                     => qsfp_rx_p_sig(i),
                    o_tx_serial_n                   => qsfp_tx_n_sig(i),
                    i_rx_serial_n                   => qsfp_rx_n_sig(i),
                    i_clk_ref                       => ftile_pll_refclk,
                    i_clk_sys                       => ftile_pll_clk,
                    -- Eth (+ RSFEC + transciever) reconfig infs (0x1 downto 0x0)
                    i_reconfig_eth_addr             => mi_ia_addr_phy  (i)(14-1 downto 0),
                    i_reconfig_eth_byteenable       => (others => '1')    ,
                    o_reconfig_eth_readdata_valid   => mi_ia_drdy_phy  (i),
                    i_reconfig_eth_read             => mi_ia_rd_phy    (i),
                    i_reconfig_eth_write            => mi_ia_wr_phy    (i),
                    o_reconfig_eth_readdata         => mi_ia_drd_phy   (i),
                    i_reconfig_eth_writedata        => mi_ia_dwr_phy   (i),
                    o_reconfig_eth_waitrequest      => mi_ia_ardy_phy_n(i),
                    -- mi_ia_xxx(item); item = XCVR ID per IP core + IP core offset + Eth infs offset
                    -- XCVR reconfig inf (0x6 for IP core #1
                    --                 or 0x2 for IP core #0)
                    i_reconfig_xcvr0_addr           => mi_ia_addr_phy  (0 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN)(18-1 downto 0),
                    i_reconfig_xcvr0_byteenable     => (others => '1')                                          ,
                    o_reconfig_xcvr0_readdata_valid => mi_ia_drdy_phy  (0 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                    i_reconfig_xcvr0_read           => mi_ia_rd_phy    (0 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                    i_reconfig_xcvr0_write          => mi_ia_wr_phy    (0 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                    o_reconfig_xcvr0_readdata       => mi_ia_drd_phy   (0 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                    i_reconfig_xcvr0_writedata      => mi_ia_dwr_phy   (0 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                    o_reconfig_xcvr0_waitrequest    => mi_ia_ardy_phy_n(0 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                    -- XCVR reconfig inf (0x7 for IP core #1
                    --                 or 0x3 for IP core #0)
                    i_reconfig_xcvr1_addr           => mi_ia_addr_phy  (1 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN)(18-1 downto 0),
                    i_reconfig_xcvr1_byteenable     => (others => '1')                                          ,
                    o_reconfig_xcvr1_readdata_valid => mi_ia_drdy_phy  (1 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                    i_reconfig_xcvr1_read           => mi_ia_rd_phy    (1 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                    i_reconfig_xcvr1_write          => mi_ia_wr_phy    (1 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                    o_reconfig_xcvr1_readdata       => mi_ia_drd_phy   (1 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                    i_reconfig_xcvr1_writedata      => mi_ia_dwr_phy   (1 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                    o_reconfig_xcvr1_waitrequest    => mi_ia_ardy_phy_n(1 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                    -- XCVR reconfig inf (0x8 for IP core #1
                    --                 or 0x4 for IP core #0)
                    i_reconfig_xcvr2_addr           => mi_ia_addr_phy  (2 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN)(18-1 downto 0),
                    i_reconfig_xcvr2_byteenable     => (others => '1')                                          ,
                    o_reconfig_xcvr2_readdata_valid => mi_ia_drdy_phy  (2 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                    i_reconfig_xcvr2_read           => mi_ia_rd_phy    (2 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                    i_reconfig_xcvr2_write          => mi_ia_wr_phy    (2 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                    o_reconfig_xcvr2_readdata       => mi_ia_drd_phy   (2 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                    i_reconfig_xcvr2_writedata      => mi_ia_dwr_phy   (2 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                    o_reconfig_xcvr2_waitrequest    => mi_ia_ardy_phy_n(2 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                    -- XCVR reconfig inf (0x9 for IP core #1
                    --                 or 0x5 for IP core #0)
                    i_reconfig_xcvr3_addr           => mi_ia_addr_phy  (3 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN)(18-1 downto 0),
                    i_reconfig_xcvr3_byteenable     => (others => '1')                                          ,
                    o_reconfig_xcvr3_readdata_valid => mi_ia_drdy_phy  (3 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                    i_reconfig_xcvr3_read           => mi_ia_rd_phy    (3 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                    i_reconfig_xcvr3_write          => mi_ia_wr_phy    (3 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                    o_reconfig_xcvr3_readdata       => mi_ia_drd_phy   (3 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                    i_reconfig_xcvr3_writedata      => mi_ia_dwr_phy   (3 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                    o_reconfig_xcvr3_waitrequest    => mi_ia_ardy_phy_n(3 + i*LANES_PER_CHANNEL + ETH_PORT_CHAN),
                    o_rx_block_lock                 => ftile_rx_block_lock(i),
                    o_rx_am_lock                    => ftile_rx_am_lock(i),
                    o_local_fault_status            => ftile_local_fault(i),
                    o_remote_fault_status           => ftile_remote_fault(i),
                    i_stats_snapshot                => '0',
                    o_rx_hi_ber                     => ftile_rx_hi_ber(i),
                    o_rx_pcs_fully_aligned          => ftile_rx_pcs_fully_aligned(i),
                    i_tx_mac_data                   => ftile_tx_mac_data(i),
                    i_tx_mac_valid                  => ftile_tx_mac_valid(i),
                    i_tx_mac_inframe                => ftile_tx_mac_inframe(i),
                    i_tx_mac_eop_empty              => ftile_tx_mac_eop_empty(i),
                    o_tx_mac_ready                  => ftile_tx_mac_ready(i),
                    i_tx_mac_error                  => ftile_tx_mac_error(i),
                    i_tx_mac_skip_crc               => (others => '0'),
                    o_rx_mac_data                   => ftile_rx_mac_data(i),
                    o_rx_mac_valid                  => ftile_rx_mac_valid(i),
                    o_rx_mac_inframe                => ftile_rx_mac_inframe(i),
                    o_rx_mac_eop_empty              => ftile_rx_mac_eop_empty(i),
                    o_rx_mac_fcs_error              => ftile_rx_mac_fcs_error(i),
                    o_rx_mac_error                  => ftile_rx_mac_error(i),
                    o_rx_mac_status                 => ftile_rx_mac_status(i),
                    i_tx_pfc                        => (others => '0'),
                    o_rx_pfc                        => open,
                    i_tx_pause                      => '0',
                    o_rx_pause                      => open
                );

                process(ftile_clk_out)
                begin
                    if rising_edge(ftile_clk_out) then
                        if (RESET_ETH = '1') then
                            RX_LINK_UP(i) <= '0';
                            TX_LINK_UP(i) <= '0';
                        else
                            RX_LINK_UP(i) <= ftile_rx_pcs_ready(i) and ftile_rx_pcs_fully_aligned(i) and (not ftile_remote_fault(i));
                            TX_LINK_UP(i) <= ftile_tx_lanes_stable(i);
                        end if;
                    end if;
                end process;

                -- =========================================================================
                -- ADAPTERS
                -- =========================================================================
                rx_ftile_adapter_i : entity work.RX_MAC_LITE_ADAPTER_MAC_SEG
                generic map(
                    REGIONS     => REGIONS,
                    REGION_SIZE => REGION_SIZE
                )
                port map(
                    CLK              => ftile_clk_out,
                    RESET            => RESET_ETH,

                    IN_MAC_DATA      => ftile_rx_mac_data(i),
                    IN_MAC_INFRAME   => ftile_rx_mac_inframe(i),
                    IN_MAC_EOP_EMPTY => ftile_rx_mac_eop_empty(i),
                    IN_MAC_FCS_ERROR => ftile_rx_mac_fcs_error(i),
                    IN_MAC_ERROR     => ftile_rx_mac_error(i),
                    IN_MAC_STATUS    => ftile_rx_mac_status(i),
                    IN_MAC_VALID     => ftile_rx_mac_valid(i),

                    OUT_MFB_DATA     => TX_MFB_DATA(i),
                    OUT_MFB_ERROR    => TX_MFB_ERROR(i),
                    OUT_MFB_SOF      => TX_MFB_SOF(i),
                    OUT_MFB_EOF      => TX_MFB_EOF(i),
                    OUT_MFB_SOF_POS  => TX_MFB_SOF_POS(i),
                    OUT_MFB_EOF_POS  => TX_MFB_EOF_POS(i),
                    OUT_MFB_SRC_RDY  => TX_MFB_SRC_RDY(i),
                    OUT_LINK_UP      => open
                );

                tx_ftile_adapter_i : entity work.TX_MAC_LITE_ADAPTER_MAC_SEG
                generic map(
                    REGIONS     => REGIONS,
                    REGION_SIZE => REGION_SIZE
                )
                port map(
                    CLK               => ftile_clk_out,
                    RESET             => RESET_ETH,

                    IN_MFB_DATA       => RX_MFB_DATA(i),
                    IN_MFB_SOF        => RX_MFB_SOF(i),
                    IN_MFB_EOF        => RX_MFB_EOF(i),
                    IN_MFB_SOF_POS    => RX_MFB_SOF_POS(i),
                    IN_MFB_EOF_POS    => RX_MFB_EOF_POS(i),
                    IN_MFB_ERROR      => (others => '0'),
                    IN_MFB_SRC_RDY    => RX_MFB_SRC_RDY(i),
                    IN_MFB_DST_RDY    => RX_MFB_DST_RDY(i),

                    OUT_MAC_DATA      => ftile_tx_mac_data(i),
                    OUT_MAC_INFRAME   => ftile_tx_mac_inframe(i),
                    OUT_MAC_EOP_EMPTY => ftile_tx_mac_eop_empty(i),
                    OUT_MAC_ERROR     => ftile_tx_mac_error(i),
                    OUT_MAC_VALID     => ftile_tx_mac_valid(i),
                    OUT_MAC_READY     => ftile_tx_mac_ready(i)
                );
            end generate;

        when 25 =>
            -- =========================================================================
            -- F-TILE PLL
            -- =========================================================================
            ftile_pll_ip_i : component ftile_pll_8x25g
            port map (
                out_systempll_synthlock_0 => open,
                out_systempll_clk_0       => ftile_pll_clk,
                out_refclk_fgt_0          => ftile_pll_refclk,
                in_refclk_fgt_0           => QSFP_REFCLK_P
            );

        -- only one of these is needed to drive all other IP cores and such
            ftile_clk_out <= ftile_clk_out_vec(0);
            CLK_ETH       <= ftile_clk_out;

            -- Distribution of serial lanes to IP cores
            qsfp_rx_p_sig <= slv_array_deser(QSFP_RX_P, ETH_PORT_CHAN);
            qsfp_rx_n_sig <= slv_array_deser(QSFP_RX_N, ETH_PORT_CHAN);
            QSFP_TX_P <= slv_array_ser(qsfp_tx_p_sig);
            QSFP_TX_N <= slv_array_ser(qsfp_tx_n_sig);

            -- can have upto eight 25g lanes
            eth_ftile_g : for i in ETH_PORT_CHAN-1 downto 0 generate
                -- =========================================================================
                -- F-TILE Ethernet
                -- =========================================================================
                ftile_eth_ip_i : component ftile_eth_8x25g
                port map (
                    i_clk_tx                        => ftile_clk_out,
                    i_clk_rx                        => ftile_clk_out,
                    o_clk_pll                       => ftile_clk_out_vec(i),
                    o_clk_tx_div                    => open,
                    o_clk_rec_div64                 => open,
                    o_clk_rec_div                   => open,
                    i_tx_rst_n                      => '1',
                    i_rx_rst_n                      => ftile_rx_rst_n(i),
                    i_rst_n                         => not RESET_ETH,
                    o_rst_ack_n                     => open,
                    o_tx_rst_ack_n                  => open,
                    o_rx_rst_ack_n                  => ftile_rx_rst_ack_n(i),
                    i_reconfig_clk                  => MI_CLK_PHY,
                    i_reconfig_reset                => MI_RESET_PHY,
                    o_cdr_lock                      => open,
                    o_tx_pll_locked                 => open,
                    o_tx_lanes_stable               => ftile_tx_lanes_stable(i),
                    o_rx_pcs_ready                  => ftile_rx_pcs_ready(i),
                    o_tx_serial                     => qsfp_tx_p_sig(i),
                    i_rx_serial                     => qsfp_rx_p_sig(i),
                    o_tx_serial_n                   => qsfp_tx_n_sig(i),
                    i_rx_serial_n                   => qsfp_rx_n_sig(i),
                    i_clk_ref                       => ftile_pll_refclk,
                    i_clk_sys                       => ftile_pll_clk,
                    -- Eth (+ RSFEC + transciever) reconfig infs (0x7 downto 0x0)
                    i_reconfig_eth_addr             => mi_ia_addr_phy  (i)(14-1 downto 0),
                    i_reconfig_eth_byteenable       => (others => '1')    ,
                    o_reconfig_eth_readdata_valid   => mi_ia_drdy_phy  (i),
                    i_reconfig_eth_read             => mi_ia_rd_phy    (i),
                    i_reconfig_eth_write            => mi_ia_wr_phy    (i),
                    o_reconfig_eth_readdata         => mi_ia_drd_phy   (i),
                    i_reconfig_eth_writedata        => mi_ia_dwr_phy   (i),
                    o_reconfig_eth_waitrequest      => mi_ia_ardy_phy_n(i),
                    -- mi_ia_xxx(item); item = IP core offset + Eth infs offset
                    -- XCVR reconfig inf (0x15 for IP core #7
                    --                 or 0x14 for IP core #6
                    --                 or 0x13 for IP core #5
                    --                 or 0x12 for IP core #4
                    --                 or 0x11 for IP core #3
                    --                 or 0x10 for IP core #2
                    --                 or 0x9  for IP core #1
                    --                 or 0x8  for IP core #0)
                    i_reconfig_xcvr0_addr           => mi_ia_addr_phy  (i + ETH_PORT_CHAN)(18-1 downto 0),
                    i_reconfig_xcvr0_byteenable     => (others => '1')                    ,
                    o_reconfig_xcvr0_readdata_valid => mi_ia_drdy_phy  (i + ETH_PORT_CHAN),
                    i_reconfig_xcvr0_read           => mi_ia_rd_phy    (i + ETH_PORT_CHAN),
                    i_reconfig_xcvr0_write          => mi_ia_wr_phy    (i + ETH_PORT_CHAN),
                    o_reconfig_xcvr0_readdata       => mi_ia_drd_phy   (i + ETH_PORT_CHAN),
                    i_reconfig_xcvr0_writedata      => mi_ia_dwr_phy   (i + ETH_PORT_CHAN),
                    o_reconfig_xcvr0_waitrequest    => mi_ia_ardy_phy_n(i + ETH_PORT_CHAN),
                    o_rx_block_lock                 => ftile_rx_block_lock(i),
                    o_rx_am_lock                    => ftile_rx_am_lock(i),
                    o_local_fault_status            => ftile_local_fault(i),
                    o_remote_fault_status           => ftile_remote_fault(i),
                    i_stats_snapshot                => '0',
                    o_rx_hi_ber                     => ftile_rx_hi_ber(i),
                    o_rx_pcs_fully_aligned          => ftile_rx_pcs_fully_aligned(i),
                    i_tx_mac_data                   => ftile_tx_mac_data(i),
                    i_tx_mac_valid                  => ftile_tx_mac_valid(i),
                    i_tx_mac_inframe                => ftile_tx_mac_inframe(i)(0),
                    i_tx_mac_eop_empty              => ftile_tx_mac_eop_empty(i),
                    o_tx_mac_ready                  => ftile_tx_mac_ready(i),
                    i_tx_mac_error                  => ftile_tx_mac_error(i)(0),
                    --i_tx_mac_skip_crc               => (others => '0'),
                    o_rx_mac_data                   => ftile_rx_mac_data(i),
                    o_rx_mac_valid                  => ftile_rx_mac_valid(i),
                    o_rx_mac_inframe                => ftile_rx_mac_inframe(i)(0),
                    o_rx_mac_eop_empty              => ftile_rx_mac_eop_empty(i),
                    o_rx_mac_fcs_error              => ftile_rx_mac_fcs_error(i)(0),
                    o_rx_mac_error                  => ftile_rx_mac_error(i),
                    o_rx_mac_status                 => ftile_rx_mac_status(i),
                    i_tx_pfc                        => (others => '0'),
                    o_rx_pfc                        => open,
                    i_tx_pause                      => '0',
                    o_rx_pause                      => open
                );

                process(ftile_clk_out)
                begin
                    if rising_edge(ftile_clk_out) then
                        if (RESET_ETH = '1') then
                            RX_LINK_UP(i) <= '0';
                            TX_LINK_UP(i) <= '0';
                        else
                            RX_LINK_UP(i) <= ftile_rx_pcs_ready(i) and ftile_rx_pcs_fully_aligned(i) and (not ftile_remote_fault(i));
                            TX_LINK_UP(i) <= ftile_tx_lanes_stable(i);
                        end if;
                    end if;
                end process;

                -- =========================================================================
                -- ADAPTERS
                -- =========================================================================
                rx_ftile_adapter_i : entity work.RX_MAC_LITE_ADAPTER_MAC_SEG
                generic map(
                    REGIONS     => REGIONS,
                    REGION_SIZE => REGION_SIZE
                )
                port map(
                    CLK              => ftile_clk_out,
                    RESET            => RESET_ETH,

                    IN_MAC_DATA      => ftile_rx_mac_data(i),
                    IN_MAC_INFRAME   => ftile_rx_mac_inframe(i),
                    IN_MAC_EOP_EMPTY => ftile_rx_mac_eop_empty(i),
                    IN_MAC_FCS_ERROR => ftile_rx_mac_fcs_error(i),
                    IN_MAC_ERROR     => ftile_rx_mac_error(i),
                    IN_MAC_STATUS    => ftile_rx_mac_status(i),
                    IN_MAC_VALID     => ftile_rx_mac_valid(i),

                    OUT_MFB_DATA     => TX_MFB_DATA(i),
                    OUT_MFB_ERROR    => TX_MFB_ERROR(i),
                    OUT_MFB_SOF      => TX_MFB_SOF(i),
                    OUT_MFB_EOF      => TX_MFB_EOF(i),
                    OUT_MFB_SOF_POS  => TX_MFB_SOF_POS(i),
                    OUT_MFB_EOF_POS  => TX_MFB_EOF_POS(i),
                    OUT_MFB_SRC_RDY  => TX_MFB_SRC_RDY(i),
                    OUT_LINK_UP      => open
                );

                tx_ftile_adapter_i : entity work.TX_MAC_LITE_ADAPTER_MAC_SEG
                generic map(
                    REGIONS     => REGIONS,
                    REGION_SIZE => REGION_SIZE
                )
                port map(
                    CLK               => ftile_clk_out,
                    RESET             => RESET_ETH,

                    IN_MFB_DATA       => RX_MFB_DATA(i),
                    IN_MFB_SOF        => RX_MFB_SOF(i),
                    IN_MFB_EOF        => RX_MFB_EOF(i),
                    IN_MFB_SOF_POS    => RX_MFB_SOF_POS(i),
                    IN_MFB_EOF_POS    => RX_MFB_EOF_POS(i),
                    IN_MFB_ERROR      => (others => '0'),
                    IN_MFB_SRC_RDY    => RX_MFB_SRC_RDY(i),
                    IN_MFB_DST_RDY    => RX_MFB_DST_RDY(i),

                    OUT_MAC_DATA      => ftile_tx_mac_data(i),
                    OUT_MAC_INFRAME   => ftile_tx_mac_inframe(i),
                    OUT_MAC_EOP_EMPTY => ftile_tx_mac_eop_empty(i),
                    OUT_MAC_ERROR     => ftile_tx_mac_error(i),
                    OUT_MAC_VALID     => ftile_tx_mac_valid(i),
                    OUT_MAC_READY     => ftile_tx_mac_ready(i)
                );
            end generate;

        when 10 =>
            -- =========================================================================
            -- F-TILE PLL
            -- =========================================================================
            ftile_pll_ip_i : component ftile_pll_8x10g
            port map (
                out_systempll_synthlock_0 => open,
                out_systempll_clk_0       => ftile_pll_clk,
                out_refclk_fgt_0          => ftile_pll_refclk,
                in_refclk_fgt_0           => QSFP_REFCLK_P
            );

            -- only one of these is needed to drive all other IP cores and such
            ftile_clk_out <= ftile_clk_out_vec(0);
            CLK_ETH       <= ftile_clk_out;

            -- Distribution of serial lanes to IP cores
            qsfp_rx_p_sig <= slv_array_deser(QSFP_RX_P, ETH_PORT_CHAN);
            qsfp_rx_n_sig <= slv_array_deser(QSFP_RX_N, ETH_PORT_CHAN);
            QSFP_TX_P <= slv_array_ser(qsfp_tx_p_sig);
            QSFP_TX_N <= slv_array_ser(qsfp_tx_n_sig);

            -- can have upto eight 10g channels
            eth_ftile_g : for i in ETH_PORT_CHAN-1 downto 0 generate
                -- =========================================================================
                -- F-TILE Ethernet
                -- =========================================================================
                ftile_eth_ip_i : component ftile_eth_8x10g
                port map (
                    i_clk_tx                        => ftile_clk_out,
                    i_clk_rx                        => ftile_clk_out,
                    o_clk_pll                       => ftile_clk_out_vec(i),
                    o_clk_tx_div                    => open,
                    o_clk_rec_div64                 => open,
                    o_clk_rec_div                   => open,
                    i_tx_rst_n                      => '1',
                    i_rx_rst_n                      => ftile_rx_rst_n(i),
                    i_rst_n                         => not RESET_ETH,
                    o_rst_ack_n                     => open,
                    o_tx_rst_ack_n                  => open,
                    o_rx_rst_ack_n                  => ftile_rx_rst_ack_n(i),
                    i_reconfig_clk                  => MI_CLK_PHY,
                    i_reconfig_reset                => MI_RESET_PHY,
                    o_cdr_lock                      => open,
                    o_tx_pll_locked                 => open,
                    o_tx_lanes_stable               => ftile_tx_lanes_stable(i),
                    o_rx_pcs_ready                  => ftile_rx_pcs_ready(i),
                    o_tx_serial                     => qsfp_tx_p_sig(i),
                    i_rx_serial                     => qsfp_rx_p_sig(i),
                    o_tx_serial_n                   => qsfp_tx_n_sig(i),
                    i_rx_serial_n                   => qsfp_rx_n_sig(i),
                    i_clk_ref                       => ftile_pll_refclk,
                    i_clk_sys                       => ftile_pll_clk,
                    -- Eth (+ RSFEC + transciever) reconfig infs (0x7 downto 0x0)
                    i_reconfig_eth_addr             => mi_ia_addr_phy  (i)(14-1 downto 0),
                    i_reconfig_eth_byteenable       => (others => '1')    ,
                    o_reconfig_eth_readdata_valid   => mi_ia_drdy_phy  (i),
                    i_reconfig_eth_read             => mi_ia_rd_phy    (i),
                    i_reconfig_eth_write            => mi_ia_wr_phy    (i),
                    o_reconfig_eth_readdata         => mi_ia_drd_phy   (i),
                    i_reconfig_eth_writedata        => mi_ia_dwr_phy   (i),
                    o_reconfig_eth_waitrequest      => mi_ia_ardy_phy_n(i),
                    -- mi_ia_xxx(item); item = IP core offset + Eth infs offset
                    -- XCVR reconfig inf (0x15 for IP core #7
                    --                 or 0x14 for IP core #6
                    --                 or 0x13 for IP core #5
                    --                 or 0x12 for IP core #4
                    --                 or 0x11 for IP core #3
                    --                 or 0x10 for IP core #2
                    --                 or 0x9  for IP core #1
                    --                 or 0x8  for IP core #0)
                    i_reconfig_xcvr0_addr           => mi_ia_addr_phy  (i + ETH_PORT_CHAN)(18-1 downto 0),
                    i_reconfig_xcvr0_byteenable     => (others => '1')                    ,
                    o_reconfig_xcvr0_readdata_valid => mi_ia_drdy_phy  (i + ETH_PORT_CHAN),
                    i_reconfig_xcvr0_read           => mi_ia_rd_phy    (i + ETH_PORT_CHAN),
                    i_reconfig_xcvr0_write          => mi_ia_wr_phy    (i + ETH_PORT_CHAN),
                    o_reconfig_xcvr0_readdata       => mi_ia_drd_phy   (i + ETH_PORT_CHAN),
                    i_reconfig_xcvr0_writedata      => mi_ia_dwr_phy   (i + ETH_PORT_CHAN),
                    o_reconfig_xcvr0_waitrequest    => mi_ia_ardy_phy_n(i + ETH_PORT_CHAN),
                    o_rx_block_lock                 => ftile_rx_block_lock(i),
                    o_rx_am_lock                    => ftile_rx_am_lock(i),
                    o_local_fault_status            => ftile_local_fault(i),
                    o_remote_fault_status           => ftile_remote_fault(i),
                    i_stats_snapshot                => '0',
                    o_rx_hi_ber                     => ftile_rx_hi_ber(i),
                    o_rx_pcs_fully_aligned          => ftile_rx_pcs_fully_aligned(i),
                    i_tx_mac_data                   => ftile_tx_mac_data(i),
                    i_tx_mac_valid                  => ftile_tx_mac_valid(i),
                    i_tx_mac_inframe                => ftile_tx_mac_inframe(i)(0),
                    i_tx_mac_eop_empty              => ftile_tx_mac_eop_empty(i),
                    o_tx_mac_ready                  => ftile_tx_mac_ready(i),
                    i_tx_mac_error                  => ftile_tx_mac_error(i)(0),
                    --i_tx_mac_skip_crc               => (others => '0'),
                    o_rx_mac_data                   => ftile_rx_mac_data(i),
                    o_rx_mac_valid                  => ftile_rx_mac_valid(i),
                    o_rx_mac_inframe                => ftile_rx_mac_inframe(i)(0),
                    o_rx_mac_eop_empty              => ftile_rx_mac_eop_empty(i),
                    o_rx_mac_fcs_error              => ftile_rx_mac_fcs_error(i)(0),
                    o_rx_mac_error                  => ftile_rx_mac_error(i),
                    o_rx_mac_status                 => ftile_rx_mac_status(i),
                    i_tx_pfc                        => (others => '0'),
                    o_rx_pfc                        => open,
                    i_tx_pause                      => '0',
                    o_rx_pause                      => open
                );

                process(ftile_clk_out)
                begin
                    if rising_edge(ftile_clk_out) then
                        if (RESET_ETH = '1') then
                            RX_LINK_UP(i) <= '0';
                            TX_LINK_UP(i) <= '0';
                        else
                            RX_LINK_UP(i) <= ftile_rx_pcs_ready(i) and ftile_rx_pcs_fully_aligned(i) and (not ftile_remote_fault(i));
                            TX_LINK_UP(i) <= ftile_tx_lanes_stable(i);
                        end if;
                    end if;
                end process;

                -- =========================================================================
                -- ADAPTERS
                -- =========================================================================
                rx_ftile_adapter_i : entity work.RX_MAC_LITE_ADAPTER_MAC_SEG
                generic map(
                    REGIONS     => REGIONS,
                    REGION_SIZE => REGION_SIZE
                )
                port map(
                    CLK              => ftile_clk_out,
                    RESET            => RESET_ETH,

                    IN_MAC_DATA      => ftile_rx_mac_data(i),
                    IN_MAC_INFRAME   => ftile_rx_mac_inframe(i),
                    IN_MAC_EOP_EMPTY => ftile_rx_mac_eop_empty(i),
                    IN_MAC_FCS_ERROR => ftile_rx_mac_fcs_error(i),
                    IN_MAC_ERROR     => ftile_rx_mac_error(i),
                    IN_MAC_STATUS    => ftile_rx_mac_status(i),
                    IN_MAC_VALID     => ftile_rx_mac_valid(i),

                    OUT_MFB_DATA     => TX_MFB_DATA(i),
                    OUT_MFB_ERROR    => TX_MFB_ERROR(i),
                    OUT_MFB_SOF      => TX_MFB_SOF(i),
                    OUT_MFB_EOF      => TX_MFB_EOF(i),
                    OUT_MFB_SOF_POS  => TX_MFB_SOF_POS(i),
                    OUT_MFB_EOF_POS  => TX_MFB_EOF_POS(i),
                    OUT_MFB_SRC_RDY  => TX_MFB_SRC_RDY(i),
                    OUT_LINK_UP      => open
                );

                tx_ftile_adapter_i : entity work.TX_MAC_LITE_ADAPTER_MAC_SEG
                generic map(
                    REGIONS     => REGIONS,
                    REGION_SIZE => REGION_SIZE
                )
                port map(
                    CLK               => ftile_clk_out,
                    RESET             => RESET_ETH,

                    IN_MFB_DATA       => RX_MFB_DATA(i),
                    IN_MFB_SOF        => RX_MFB_SOF(i),
                    IN_MFB_EOF        => RX_MFB_EOF(i),
                    IN_MFB_SOF_POS    => RX_MFB_SOF_POS(i),
                    IN_MFB_EOF_POS    => RX_MFB_EOF_POS(i),
                    IN_MFB_ERROR      => (others => '0'),
                    IN_MFB_SRC_RDY    => RX_MFB_SRC_RDY(i),
                    IN_MFB_DST_RDY    => RX_MFB_DST_RDY(i),

                    OUT_MAC_DATA      => ftile_tx_mac_data(i),
                    OUT_MAC_INFRAME   => ftile_tx_mac_inframe(i),
                    OUT_MAC_EOP_EMPTY => ftile_tx_mac_eop_empty(i),
                    OUT_MAC_ERROR     => ftile_tx_mac_error(i),
                    OUT_MAC_VALID     => ftile_tx_mac_valid(i),
                    OUT_MAC_READY     => ftile_tx_mac_ready(i)
                );
            end generate;

    end generate;

end architecture;
