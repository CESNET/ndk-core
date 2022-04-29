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
        AVST_REGIONS     : natural := 2;
        -- AXI configuration
        AXI_DATA_WIDTH   : natural := 512;
        AXI_CQUSER_WIDTH : natural := 183;
        AXI_CCUSER_WIDTH : natural := 81;
        AXI_RQUSER_WIDTH : natural := 137;
        AXI_RCUSER_WIDTH : natural := 161;
        -- Number of items (headers) in UP word
        MVB_UP_ITEMS     : natural := 2;
        -- P-Tile endpoint (EP) mode: 0 = one EPx16 lanes, 1 = two EPx8 lanes
        ENDPOINT_MODE    : natural := 0;
        -- Number of instantiated PCIe endpoints
            -- When ENDPOINT_MODE = 0: PCIE_ENDPOINTS=PCIE_CONS
            -- When ENDPOINT_MODE = 1: PCIE_ENDPOINTS=2*PCIE_CONS
        PCIE_ENDPOINTS   : natural := 1;
        PCIE_CLKS        : natural := 1;
        PCIE_CONS        : natural := 1;
        PCIE_LANES       : natural := 16;

        VENDOR_ID        : std_logic_vector(15 downto 0) := X"18EC";
        DEVICE_ID        : std_logic_vector(15 downto 0) := X"C400";
        SUBVENDOR_ID     : std_logic_vector(15 downto 0) := X"0000";
        SUBDEVICE_ID     : std_logic_vector(15 downto 0) := X"0000";
        XVC_ENABLE       : boolean := false;
        PF0_TOTAL_VF     : natural := 0;
        -- Total PCIe credits for down stream
        CRDT_TOTAL_PH    : natural := 128;
        CRDT_TOTAL_NPH   : natural := 128;
        CRDT_TOTAL_CPLH  : natural := 128;
        CRDT_TOTAL_PD    : natural := 1024;
        CRDT_TOTAL_NPD   : natural := 32;
        CRDT_TOTAL_CPLD  : natural := 32;
        -- Reset width
        RESET_WIDTH      : natural := 8;
        -- FPGA device
        DEVICE           : string  := "STRATIX10"
    );
    port(
        -- =====================================================================
        --  Input clock and reset (from PCIe ports, 100 MHz)
        -- =====================================================================
        -- Clock from PCIe port
        PCIE_SYSCLK_P       : in  std_logic_vector(PCIE_CONS*PCIE_CLKS-1 downto 0);
        PCIE_SYSCLK_N       : in  std_logic_vector(PCIE_CONS*PCIE_CLKS-1 downto 0);
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
        AVST_DOWN_VALID     : out slv_array_t(PCIE_ENDPOINTS-1 downto 0)(AVST_REGIONS-1 downto 0) := (others => (others => '0'));
        AVST_DOWN_READY     : in  std_logic_vector(PCIE_ENDPOINTS-1 downto 0);
        -- UP stream
        AVST_UP_DATA        : in  slv_array_t(PCIE_ENDPOINTS-1 downto 0)(AVST_REGIONS*256-1 downto 0);
        AVST_UP_HDR         : in  slv_array_t(PCIE_ENDPOINTS-1 downto 0)(AVST_REGIONS*128-1 downto 0);
        AVST_UP_PREFIX      : in  slv_array_t(PCIE_ENDPOINTS-1 downto 0)(AVST_REGIONS*32-1 downto 0);
        AVST_UP_SOP         : in  slv_array_t(PCIE_ENDPOINTS-1 downto 0)(AVST_REGIONS-1 downto 0);
        AVST_UP_EOP         : in  slv_array_t(PCIE_ENDPOINTS-1 downto 0)(AVST_REGIONS-1 downto 0);
        AVST_UP_ERROR       : in  slv_array_t(PCIE_ENDPOINTS-1 downto 0)(AVST_REGIONS-1 downto 0);
        AVST_UP_VALID       : in  slv_array_t(PCIE_ENDPOINTS-1 downto 0)(AVST_REGIONS-1 downto 0);
        AVST_UP_READY       : out std_logic_vector(PCIE_ENDPOINTS-1 downto 0) := (others => '0');

        -- =====================================================================
        --  AXI Completer Request Interfaces (CQ) - Xilinx FPGA Only
        -- =====================================================================
        -- See Xilinx PG213 (UltraScale+ Devices Integrated Block for PCI Express).

        -- CQ_AXI: Data word. For detailed specifications, see Xilinx PG213.
        CQ_AXI_DATA       : out slv_array_t(PCIE_ENDPOINTS-1 downto 0)(AXI_DATA_WIDTH-1 downto 0);
        -- CQ_AXI: Set of signals with sideband information about trasferred
        -- transaction. For detailed specifications, see Xilinx PG213.
        CQ_AXI_USER       : out slv_array_t(PCIE_ENDPOINTS-1 downto 0)(AXI_CQUSER_WIDTH-1 downto 0);
        -- CQ_AXI: Indication of the last word of a transaction. For detailed
        -- specifications, see Xilinx PG213.
        CQ_AXI_LAST       : out std_logic_vector(PCIE_ENDPOINTS-1 downto 0);
        -- CQ_AXI: Indication of valid data: each bit determines validity of
        -- different Dword. For detailed specifications, see Xilinx PG213.
        CQ_AXI_KEEP       : out slv_array_t(PCIE_ENDPOINTS-1 downto 0)(AXI_DATA_WIDTH/32-1 downto 0);
        -- CQ_AXI: Indication of valid data: i.e. completer is ready to send a
        -- transaction. For detailed specifications, see Xilinx PG213.
        CQ_AXI_VALID      : out std_logic_vector(PCIE_ENDPOINTS-1 downto 0) := (others => '0');
        -- CQ_AXI: User application is ready to receive a transaction.
        -- For detailed specifications, see Xilinx PG213.
        CQ_AXI_READY      : in  std_logic_vector(PCIE_ENDPOINTS-1 downto 0);

        -- =====================================================================
        --  AXI Completer Completion Interfaces (CC) - Xilinx FPGA Only
        -- =====================================================================
        -- See Xilinx PG213 (UltraScale+ Devices Integrated Block for PCI Express).

        -- CC_AXI: Data word. For detailed specifications, see Xilinx PG213.
        CC_AXI_DATA       : in  slv_array_t(PCIE_ENDPOINTS-1 downto 0)(AXI_DATA_WIDTH-1 downto 0);
        -- CC_AXI: Set of signals with sideband information about trasferred
        -- transaction. For detailed specifications, see Xilinx PG213.
        CC_AXI_USER       : in  slv_array_t(PCIE_ENDPOINTS-1 downto 0)(AXI_CCUSER_WIDTH-1 downto 0);
        -- CC_AXI: Indication of the last word of a transaction. For detailed
        -- specifications, see Xilinx PG213.
        CC_AXI_LAST       : in  std_logic_vector(PCIE_ENDPOINTS-1 downto 0);
        -- CC_AXI: Indication of valid data: each bit determines validity of
        -- different Dword. For detailed specifications, see Xilinx PG213.
        CC_AXI_KEEP       : in  slv_array_t(PCIE_ENDPOINTS-1 downto 0)(AXI_DATA_WIDTH/32-1 downto 0);
        -- CC_AXI: Indication of valid data: i.e. completer is ready to send a
        -- transaction. For detailed specifications, see Xilinx PG213.
        CC_AXI_VALID      : in  std_logic_vector(PCIE_ENDPOINTS-1 downto 0);
        -- CC_AXI: User application is ready to receive a transaction.
        -- For detailed specifications, see Xilinx PG213.
        CC_AXI_READY      : out std_logic_vector(PCIE_ENDPOINTS-1 downto 0) := (others => '0');

        -- =====================================================================
        --  AXI Requester Request Interfaces (RQ) - Xilinx FPGA Only
        -- =====================================================================
        -- See Xilinx PG213 (UltraScale+ Devices Integrated Block for PCI Express).

        -- RQ_AXI: Data word. For detailed specifications, see Xilinx PG213.
        RQ_AXI_DATA       : in  slv_array_t(PCIE_ENDPOINTS-1 downto 0)(AXI_DATA_WIDTH-1 downto 0);
        -- RQ_AXI: Set of signals with sideband information about trasferred
        -- transaction. For detailed specifications, see Xilinx PG213.
        RQ_AXI_USER       : in  slv_array_t(PCIE_ENDPOINTS-1 downto 0)(AXI_RQUSER_WIDTH-1 downto 0);
        -- RQ_AXI: Indication of the last word of a transaction. For detailed
        -- specifications, see Xilinx PG213.
        RQ_AXI_LAST       : in  std_logic_vector(PCIE_ENDPOINTS-1 downto 0);
        -- RQ_AXI: Indication of valid data: each bit determines validity of
        -- different Dword. For detailed specifications, see Xilinx PG213.
        RQ_AXI_KEEP       : in  slv_array_t(PCIE_ENDPOINTS-1 downto 0)(AXI_DATA_WIDTH/32-1 downto 0);
        -- RQ_AXI: Indication of valid data: i.e. completer is ready to send a
        -- transaction. For detailed specifications, see Xilinx PG213.
        RQ_AXI_VALID      : in  std_logic_vector(PCIE_ENDPOINTS-1 downto 0);
        -- RQ_AXI: User application is ready to receive a transaction.
        -- For detailed specifications, see Xilinx PG213.
        RQ_AXI_READY      : out std_logic_vector(PCIE_ENDPOINTS-1 downto 0) := (others => '0');

        -- =====================================================================
        --  AXI Requester Completion Interfaces (RC) - Xilinx FPGA Only
        -- =====================================================================
        -- See Xilinx PG213 (UltraScale+ Devices Integrated Block for PCI Express).

        -- RC_AXI: Data word. For detailed specifications, see Xilinx PG213.
        RC_AXI_DATA       : out slv_array_t(PCIE_ENDPOINTS-1 downto 0)(AXI_DATA_WIDTH-1 downto 0);
        -- RC_AXI: Set of signals with sideband information about trasferred
        -- transaction. For detailed specifications, see Xilinx PG213.
        RC_AXI_USER       : out slv_array_t(PCIE_ENDPOINTS-1 downto 0)(AXI_RCUSER_WIDTH-1 downto 0);
        -- RC_AXI: Indication of the last word of a transaction. For detailed
        -- specifications, see Xilinx PG213.
        RC_AXI_LAST       : out std_logic_vector(PCIE_ENDPOINTS-1 downto 0);
        -- RC_AXI: Indication of valid data: each bit determines validity of
        -- different Dword. For detailed specifications, see Xilinx PG213.
        RC_AXI_KEEP       : out slv_array_t(PCIE_ENDPOINTS-1 downto 0)(AXI_DATA_WIDTH/32-1 downto 0);
        -- RC_AXI: Indication of valid data: i.e. completer is ready to send a
        -- transaction. For detailed specifications, see Xilinx PG213.
        RC_AXI_VALID      : out std_logic_vector(PCIE_ENDPOINTS-1 downto 0) := (others => '0');
        -- RC_AXI: User application is ready to receive a transaction.
        -- For detailed specifications, see Xilinx PG213.
        RC_AXI_READY      : in  std_logic_vector(PCIE_ENDPOINTS-1 downto 0);

        -- =====================================================================
        --  PCIe tags interface - Xilinx FPGA Only
        -- =====================================================================
        -- PCIe tag assigned to send transaction
        TAG_ASSIGN        : out slv_array_t(PCIE_ENDPOINTS-1 downto 0)(MVB_UP_ITEMS*8-1 downto 0);
        -- Valid bit for assigned tags
        TAG_ASSIGN_VLD    : out slv_array_t(PCIE_ENDPOINTS-1 downto 0)(MVB_UP_ITEMS-1 downto 0) := (others => (others => '0'))
    );
end entity;
