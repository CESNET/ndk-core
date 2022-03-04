-- pcie_core_ent.vhd: PCIe module entity
-- Copyright (C) 2019 CESNET z. s. p. o.
-- Author(s): Jakub Cabal <cabal@cesnet.cz>
--
-- SPDX-License-Identifier: BSD-3-Clause

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.math_pack.all;
use work.type_pack.all;

entity PCIE_CORE is
    generic(
        -- Number of AVST regions
            -- When ENDPOINT_MODE = 0: 2
            -- When ENDPOINT_MODE = 1: 1
        AVST_REGIONS    : natural := 2;
        -- P-Tile endpoint (EP) mode: 0 = one EPx16 lanes, 1 = two EPx8 lanes
        ENDPOINT_MODE   : natural := 0;
        -- Number of instantiated PCIe endpoints
            -- When ENDPOINT_MODE = 0: PCIE_ENDPOINTS=PCIE_CONS
            -- When ENDPOINT_MODE = 1: PCIE_ENDPOINTS=2*PCIE_CONS
        PCIE_ENDPOINTS  : natural := 1;
        PCIE_CLKS       : natural := 1;
        PCIE_CONS       : natural := 1;
        PCIE_LANES      : natural := 16;
        -- Total PCIe credits for down stream
        CRDT_TOTAL_PH   : natural := 128;
        CRDT_TOTAL_NPH  : natural := 128;
        CRDT_TOTAL_CPLH : natural := 128;
        CRDT_TOTAL_PD   : natural := 1024;
        CRDT_TOTAL_NPD  : natural := 32;
        CRDT_TOTAL_CPLD : natural := 32;
        -- Reset width
        RESET_WIDTH     : natural := 8
    );
    port(
        -- =====================================================================
        --  Input clock and reset (from PCIe ports, 100 MHz)
        -- =====================================================================
        -- Clock from PCIe port
        PCIE_SYSCLK         : in  std_logic_vector(PCIE_CONS*PCIE_CLKS-1 downto 0);
        -- PCIe reset
        PCIE_SYSRST_N       : in  std_logic_vector(PCIE_CONS-1 downto 0);
        -- nINIT_DONE output of the Reset Release Intel Stratix 10 FPGA IP
        INIT_DONE_N         : in  std_logic;
        
        -- =====================================================================
        --  PCIe interface
        -- =====================================================================
        -- Receive data
        PCIE_RX_P           : in  std_logic_vector(PCIE_CONS*PCIE_LANES-1 downto 0);
        PCIE_RX_N           : in  std_logic_vector(PCIE_CONS*PCIE_LANES-1 downto 0);
        -- Transmit data
        PCIE_TX_P           : out std_logic_vector(PCIE_CONS*PCIE_LANES-1 downto 0);
        PCIE_TX_N           : out std_logic_vector(PCIE_CONS*PCIE_LANES-1 downto 0);

        -- =====================================================================
        --  Output user PCIe clock and reset
        -- =====================================================================
        PCIE_USER_CLK       : out std_logic_vector(PCIE_ENDPOINTS-1 downto 0);
        PCIE_USER_RESET     : out slv_array_t(PCIE_ENDPOINTS-1 downto 0)(RESET_WIDTH-1 downto 0);

        -- =====================================================================
        --  Configuration status interface (PCIE_USER_CLK)
        -- =====================================================================
        -- PCIe link up flag per PCIe endpoint
        PCIE_LINK_UP        : out std_logic_vector(PCIE_ENDPOINTS-1 downto 0);
        -- PCIe maximum payload size
        PCIE_MPS            : out slv_array_t(PCIE_ENDPOINTS-1 downto 0)(3-1 downto 0);
        -- PCIe maximum read request size
        PCIE_MRRS           : out slv_array_t(PCIE_ENDPOINTS-1 downto 0)(3-1 downto 0);
        -- PCIe extended tag enable (8-bit tag)
        PCIE_EXT_TAG_EN     : out std_logic_vector(PCIE_ENDPOINTS-1 downto 0);
        -- PCIe 10-bit tag requester enable
        PCIE_10B_TAG_REQ_EN : out std_logic_vector(PCIE_ENDPOINTS-1 downto 0);
        -- PCIe RCB size control
        PCIE_RCB_SIZE       : out std_logic_vector(PCIE_ENDPOINTS-1 downto 0);

        -- =====================================================================
        --  User DOWN/UP Flow Control Interface - R-Tile only (PCIE_USER_CLK)
        -- =====================================================================
        -- In init phase the receiver must set the total number of credits using
        -- incremental credit updates. The user logic only receives the credit
        -- updates and waits for CRDT_UP_INIT_DONE to be high.
        CRDT_UP_INIT_DONE   : out std_logic_vector(PCIE_ENDPOINTS-1 downto 0);
        -- Update valid flags vector (from MSB to LSB: CPLD,NPD,PD,CPLH,NPH,PH)
        CRDT_UP_UPDATE      : out slv_array_t(PCIE_ENDPOINTS-1 downto 0)(6-1 downto 0);
        -- Update count of credits
        CRDT_UP_CNT_PH      : out slv_array_t(PCIE_ENDPOINTS-1 downto 0)(2-1 downto 0);
        CRDT_UP_CNT_NPH     : out slv_array_t(PCIE_ENDPOINTS-1 downto 0)(2-1 downto 0);
        CRDT_UP_CNT_CPLH    : out slv_array_t(PCIE_ENDPOINTS-1 downto 0)(2-1 downto 0);
        CRDT_UP_CNT_PD      : out slv_array_t(PCIE_ENDPOINTS-1 downto 0)(4-1 downto 0);
        CRDT_UP_CNT_NPD     : out slv_array_t(PCIE_ENDPOINTS-1 downto 0)(4-1 downto 0);
        CRDT_UP_CNT_CPLD    : out slv_array_t(PCIE_ENDPOINTS-1 downto 0)(4-1 downto 0);
        
        -- In init phase the receiver must set the total number of credits using
        -- incremental credit updates. The user logic only waits for
        -- CRDT_DOWN_INIT_DONE to be high.
        CRDT_DOWN_INIT_DONE : out std_logic_vector(PCIE_ENDPOINTS-1 downto 0);
        -- Update valid flags vector (from MSB to LSB: CPLD,NPD,PD,CPLH,NPH,PH)
        CRDT_DOWN_UPDATE    : in  slv_array_t(PCIE_ENDPOINTS-1 downto 0)(6-1 downto 0) := (others => (others => '0'));
        -- Update count of credits
        CRDT_DOWN_CNT_PH    : in  slv_array_t(PCIE_ENDPOINTS-1 downto 0)(2-1 downto 0);
        CRDT_DOWN_CNT_NPH   : in  slv_array_t(PCIE_ENDPOINTS-1 downto 0)(2-1 downto 0);
        CRDT_DOWN_CNT_CPLH  : in  slv_array_t(PCIE_ENDPOINTS-1 downto 0)(2-1 downto 0);
        CRDT_DOWN_CNT_PD    : in  slv_array_t(PCIE_ENDPOINTS-1 downto 0)(4-1 downto 0);
        CRDT_DOWN_CNT_NPD   : in  slv_array_t(PCIE_ENDPOINTS-1 downto 0)(4-1 downto 0);
        CRDT_DOWN_CNT_CPLD  : in  slv_array_t(PCIE_ENDPOINTS-1 downto 0)(4-1 downto 0);

        -- =====================================================================
        --  User DOWN/UP Avalon-ST streams per endpoint (PCIE_USER_CLK)
        -- =====================================================================
        -- DOWN stream
        AVST_DOWN_DATA      : out slv_array_t(PCIE_ENDPOINTS-1 downto 0)(AVST_REGIONS*256-1 downto 0);
        AVST_DOWN_HDR       : out slv_array_t(PCIE_ENDPOINTS-1 downto 0)(AVST_REGIONS*128-1 downto 0);
        AVST_DOWN_PREFIX    : out slv_array_t(PCIE_ENDPOINTS-1 downto 0)(AVST_REGIONS*32-1 downto 0);
        AVST_DOWN_SOP       : out slv_array_t(PCIE_ENDPOINTS-1 downto 0)(AVST_REGIONS-1 downto 0);
        AVST_DOWN_EOP       : out slv_array_t(PCIE_ENDPOINTS-1 downto 0)(AVST_REGIONS-1 downto 0);
        AVST_DOWN_EMPTY     : out slv_array_t(PCIE_ENDPOINTS-1 downto 0)(AVST_REGIONS*3-1 downto 0);
        AVST_DOWN_BAR_RANGE : out slv_array_t(PCIE_ENDPOINTS-1 downto 0)(AVST_REGIONS*3-1 downto 0);
        AVST_DOWN_VALID     : out slv_array_t(PCIE_ENDPOINTS-1 downto 0)(AVST_REGIONS-1 downto 0);
        AVST_DOWN_READY     : in  std_logic_vector(PCIE_ENDPOINTS-1 downto 0);
        -- UP stream
        AVST_UP_DATA        : in  slv_array_t(PCIE_ENDPOINTS-1 downto 0)(AVST_REGIONS*256-1 downto 0);
        AVST_UP_HDR         : in  slv_array_t(PCIE_ENDPOINTS-1 downto 0)(AVST_REGIONS*128-1 downto 0);
        AVST_UP_PREFIX      : in  slv_array_t(PCIE_ENDPOINTS-1 downto 0)(AVST_REGIONS*32-1 downto 0);
        AVST_UP_SOP         : in  slv_array_t(PCIE_ENDPOINTS-1 downto 0)(AVST_REGIONS-1 downto 0);
        AVST_UP_EOP         : in  slv_array_t(PCIE_ENDPOINTS-1 downto 0)(AVST_REGIONS-1 downto 0);
        AVST_UP_ERROR       : in  slv_array_t(PCIE_ENDPOINTS-1 downto 0)(AVST_REGIONS-1 downto 0);
        AVST_UP_VALID       : in  slv_array_t(PCIE_ENDPOINTS-1 downto 0)(AVST_REGIONS-1 downto 0);
        AVST_UP_READY       : out std_logic_vector(PCIE_ENDPOINTS-1 downto 0)
    );
end entity;
