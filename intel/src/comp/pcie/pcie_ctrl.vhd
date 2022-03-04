-- pcie_ctrl.vhd: PCIe module controllers
-- Copyright (C) 2019 CESNET z. s. p. o.
-- Author(s): Jakub Cabal <cabal@cesnet.cz>
--
-- SPDX-License-Identifier: BSD-3-Clause

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.math_pack.all;
use work.type_pack.all;

entity PCIE_CTRL is
    generic(
        -- BAR0 base address for PCIE->MI32 transalation
        BAR0_BASE_ADDR      : std_logic_vector(31 downto 0) := X"01000000";
        -- BAR1 base address for PCIE->MI32 transalation
        BAR1_BASE_ADDR      : std_logic_vector(31 downto 0) := X"02000000";
        -- BAR2 base address for PCIE->MI32 transalation
        BAR2_BASE_ADDR      : std_logic_vector(31 downto 0) := X"03000000";
        -- BAR3 base address for PCIE->MI32 transalation
        BAR3_BASE_ADDR      : std_logic_vector(31 downto 0) := X"04000000";
        -- BAR4 base address for PCIE->MI32 transalation
        BAR4_BASE_ADDR      : std_logic_vector(31 downto 0) := X"05000000";
        -- BAR5 base address for PCIE->MI32 transalation
        BAR5_BASE_ADDR      : std_logic_vector(31 downto 0) := X"06000000";
        -- Expansion ROM base address for PCIE->MI32 transalation
        EXP_ROM_BASE_ADDR   : std_logic_vector(31 downto 0) := X"0A000000";

        DMA_PORTS           : integer := 2;   -- Number of DMA ports per one PCIe EP

        MVB_UP_ITEMS        : integer := 2;   -- Number of items (headers) in word
        DMA_MVB_UP_ITEMS    : integer := MVB_UP_ITEMS; -- Number of items (headers) in word
        MVB_UP_ITEM_WIDTH   : integer := 32;  -- Width of one MVB item (in bits)
        MFB_UP_REGIONS      : integer := 2;   -- Number of regions in word
        DMA_MFB_UP_REGIONS  : integer := MFB_UP_REGIONS; -- Number of regions in word
        MFB_UP_REG_SIZE     : integer := 1;   -- Number of blocks in region
        MFB_UP_BLOCK_SIZE   : integer := 8;   -- Number of items in block
        MFB_UP_ITEM_WIDTH   : integer := 32;  -- Width of one item (in bits)

        MVB_DOWN_ITEMS       : integer := 2;   -- Number of items (headers) in word
        DMA_MVB_DOWN_ITEMS   : integer := MVB_DOWN_ITEMS; -- Number of items (headers) in word
        MVB_DOWN_ITEM_WIDTH  : integer := 32;  -- Width of one MVB item (in bits)
        MFB_DOWN_REGIONS     : integer := 2;   -- Number of regions in word
        DMA_MFB_DOWN_REGIONS : integer := MFB_DOWN_REGIONS; -- Number of regions in word
        MFB_DOWN_REG_SIZE    : integer := 1;   -- Number of blocks in region
        MFB_DOWN_BLOCK_SIZE  : integer := 8;   -- Number of items in block
        MFB_DOWN_ITEM_WIDTH  : integer := 32;  -- Width of one item (in bits)

        MTC_FIFO_ITEMS       : natural := 512;
        RESET_WIDTH          : natural := 8;

        -- Enable of MI transaction controller
        ENABLE_MI           : boolean := True;
        -- Connected PCIe endpoint type ("H_TILE" or "P_TILE" or "R_TILE")
        ENDPOINT_TYPE       : string  := "P_TILE";
        -- FPGA device
        DEVICE              : string  := "STRATIX10"
    );
    port(
        -- =====================================================================
        --  CLOCK AND RESETS
        -- =====================================================================
        PCIE_CLK    : in  std_logic;
        PCIE_RESET  : in  std_logic_vector(RESET_WIDTH-1 downto 0);

        DMA_CLK     : in  std_logic;
        DMA_RESET   : in  std_logic;

        MI_CLK      : in  std_logic;
        MI_RESET    : in  std_logic;

        -- =====================================================================
        --  CONFIGURATION STATUS INTERFACE
        -- =====================================================================
        CTL_MAX_PAYLOAD  : in  std_logic_vector(2 downto 0);
        CTL_BAR_APERTURE : in  std_logic_vector(5 downto 0);
        CTL_RCB_SIZE     : in  std_logic;

        -- =====================================================================
        --  CREDIT FLOW CONTROL INTERFACE - Intel R-Tile Only
        -- =====================================================================
        -- In init phase must the receiver must set the total number of credits
        -- using incremental credit updates. The user logic only receives the
        -- credit updates and waits for CRDT_UP_INIT_DONE to be high.
        CRDT_UP_INIT_DONE   : in  std_logic := '0';
        -- Update valid flags vector (from MSB to LSB: CPLD,NPD,PD,CPLH,NPH,PH)
        CRDT_UP_UPDATE      : in  std_logic_vector(6-1 downto 0);
        -- Update count of credits
        CRDT_UP_CNT_PH      : in  std_logic_vector(2-1 downto 0);
        CRDT_UP_CNT_NPH     : in  std_logic_vector(2-1 downto 0);
        CRDT_UP_CNT_CPLH    : in  std_logic_vector(2-1 downto 0);
        CRDT_UP_CNT_PD      : in  std_logic_vector(4-1 downto 0);
        CRDT_UP_CNT_NPD     : in  std_logic_vector(4-1 downto 0);
        CRDT_UP_CNT_CPLD    : in  std_logic_vector(4-1 downto 0);

        CRDT_DOWN_INIT_DONE : in  std_logic := '0';
        -- Update valid flags vector (from MSB to LSB: CPLD,NPD,PD,CPLH,NPH,PH)
        CRDT_DOWN_UPDATE    : out std_logic_vector(6-1 downto 0);
        -- Update count of credits
        CRDT_DOWN_CNT_PH    : out std_logic_vector(2-1 downto 0);
        CRDT_DOWN_CNT_NPH   : out std_logic_vector(2-1 downto 0);
        CRDT_DOWN_CNT_CPLH  : out std_logic_vector(2-1 downto 0);
        CRDT_DOWN_CNT_PD    : out std_logic_vector(4-1 downto 0);
        CRDT_DOWN_CNT_NPD   : out std_logic_vector(4-1 downto 0);
        CRDT_DOWN_CNT_CPLD  : out std_logic_vector(4-1 downto 0);

        -- =====================================================================
        --  PCIE ENDPOINT DOWN/UP Avalon-ST Stream (PCIE_CLK)
        -- =====================================================================
        -- DOWN stream
        AVST_DOWN_DATA      : in  std_logic_vector(MFB_DOWN_REGIONS*256-1 downto 0);
        AVST_DOWN_HDR       : in  std_logic_vector(MFB_DOWN_REGIONS*128-1 downto 0);
        AVST_DOWN_PREFIX    : in  std_logic_vector(MFB_DOWN_REGIONS*32-1 downto 0);
		AVST_DOWN_SOP       : in  std_logic_vector(MFB_DOWN_REGIONS-1 downto 0);
		AVST_DOWN_EOP       : in  std_logic_vector(MFB_DOWN_REGIONS-1 downto 0);
        AVST_DOWN_EMPTY     : in  std_logic_vector(MFB_DOWN_REGIONS*3-1 downto 0);
        AVST_DOWN_BAR_RANGE : in  std_logic_vector(MFB_DOWN_REGIONS*3-1 downto 0);
        AVST_DOWN_VALID     : in  std_logic_vector(MFB_DOWN_REGIONS-1 downto 0);
		AVST_DOWN_READY     : out std_logic;
        -- UP stream
        AVST_UP_DATA        : out std_logic_vector(MFB_UP_REGIONS*256-1 downto 0);
        AVST_UP_HDR         : out std_logic_vector(MFB_UP_REGIONS*128-1 downto 0);
        AVST_UP_PREFIX      : out std_logic_vector(MFB_UP_REGIONS*32-1 downto 0);
		AVST_UP_SOP         : out std_logic_vector(MFB_UP_REGIONS-1 downto 0);
		AVST_UP_EOP         : out std_logic_vector(MFB_UP_REGIONS-1 downto 0);
        AVST_UP_ERROR       : out std_logic_vector(MFB_UP_REGIONS-1 downto 0);
        AVST_UP_VALID       : out std_logic_vector(MFB_UP_REGIONS-1 downto 0);
		AVST_UP_READY       : in  std_logic;

        -- =====================================================================
        --  DMA DOWN/UP MFB/MVB Streams (DMA_CLK)
        -- =====================================================================
        UP_MVB_DATA      : in  slv_array_t(DMA_PORTS-1 downto 0)(DMA_MVB_UP_ITEMS*MVB_UP_ITEM_WIDTH-1 downto 0);
        UP_MVB_VLD       : in  slv_array_t(DMA_PORTS-1 downto 0)(DMA_MVB_UP_ITEMS                  -1 downto 0);
        UP_MVB_SRC_RDY   : in  std_logic_vector(DMA_PORTS-1 downto 0);
        UP_MVB_DST_RDY   : out std_logic_vector(DMA_PORTS-1 downto 0);

        UP_MFB_DATA      : in  slv_array_t(DMA_PORTS-1 downto 0)(DMA_MFB_UP_REGIONS*MFB_UP_REG_SIZE*MFB_UP_BLOCK_SIZE*MFB_UP_ITEM_WIDTH-1 downto 0);
        UP_MFB_SOF       : in  slv_array_t(DMA_PORTS-1 downto 0)(DMA_MFB_UP_REGIONS-1 downto 0);
        UP_MFB_EOF       : in  slv_array_t(DMA_PORTS-1 downto 0)(DMA_MFB_UP_REGIONS-1 downto 0);
        UP_MFB_SOF_POS   : in  slv_array_t(DMA_PORTS-1 downto 0)(DMA_MFB_UP_REGIONS*max(1,log2(MFB_UP_REG_SIZE))-1 downto 0);
        UP_MFB_EOF_POS   : in  slv_array_t(DMA_PORTS-1 downto 0)(DMA_MFB_UP_REGIONS*max(1,log2(MFB_UP_REG_SIZE*MFB_UP_BLOCK_SIZE))-1 downto 0);
        UP_MFB_SRC_RDY   : in  std_logic_vector(DMA_PORTS-1 downto 0);
        UP_MFB_DST_RDY   : out std_logic_vector(DMA_PORTS-1 downto 0);

        DOWN_MVB_DATA    : out slv_array_t(DMA_PORTS-1 downto 0)(DMA_MVB_DOWN_ITEMS*MVB_DOWN_ITEM_WIDTH-1 downto 0);
        DOWN_MVB_VLD     : out slv_array_t(DMA_PORTS-1 downto 0)(DMA_MVB_DOWN_ITEMS                    -1 downto 0);
        DOWN_MVB_SRC_RDY : out std_logic_vector(DMA_PORTS-1 downto 0);
        DOWN_MVB_DST_RDY : in  std_logic_vector(DMA_PORTS-1 downto 0);

        DOWN_MFB_DATA    : out slv_array_t(DMA_PORTS-1 downto 0)(DMA_MFB_DOWN_REGIONS*MFB_DOWN_REG_SIZE*MFB_DOWN_BLOCK_SIZE*MFB_DOWN_ITEM_WIDTH-1 downto 0);
        DOWN_MFB_SOF     : out slv_array_t(DMA_PORTS-1 downto 0)(DMA_MFB_DOWN_REGIONS-1 downto 0);
        DOWN_MFB_EOF     : out slv_array_t(DMA_PORTS-1 downto 0)(DMA_MFB_DOWN_REGIONS-1 downto 0);
        DOWN_MFB_SOF_POS : out slv_array_t(DMA_PORTS-1 downto 0)(DMA_MFB_DOWN_REGIONS*max(1,log2(MFB_DOWN_REG_SIZE))-1 downto 0);
        DOWN_MFB_EOF_POS : out slv_array_t(DMA_PORTS-1 downto 0)(DMA_MFB_DOWN_REGIONS*max(1,log2(MFB_DOWN_REG_SIZE*MFB_DOWN_BLOCK_SIZE))-1 downto 0);
        DOWN_MFB_SRC_RDY : out std_logic_vector(DMA_PORTS-1 downto 0);
        DOWN_MFB_DST_RDY : in  std_logic_vector(DMA_PORTS-1 downto 0);

        -- =====================================================================
        -- MI32 interface - root of the MI32 bus tree (MI_CLK)
        -- =====================================================================
        MI_DWR           : out std_logic_vector(31 downto 0);
        MI_ADDR          : out std_logic_vector(31 downto 0);
        MI_BE            : out std_logic_vector(3 downto 0);
        MI_RD            : out std_logic;
        MI_WR            : out std_logic;
        MI_DRD           : in  std_logic_vector(31 downto 0);
        MI_ARDY          : in  std_logic;
        MI_DRDY          : in  std_logic
    );
end entity;

architecture FULL of PCIE_CTRL is
    constant PCI_HDR_W           : natural := 128;
    constant PCI_CHDR_W          : natural := 96;
    constant PCI_PREFIX_W        : natural := 32;
    constant AXI_DATA_WIDTH      : natural := 512;
    constant AXI_CQUSER_WIDTH    : natural := 183;
    constant AXI_CCUSER_WIDTH    : natural := 81;
    constant MFB_DOWN_META_WIDTH : natural := PCI_HDR_W+PCI_PREFIX_W+3;
    constant MFB_UP_META_WIDTH   : natural := PCI_HDR_W+PCI_PREFIX_W;

    signal ptc_up_mfb_data         : std_logic_vector(MFB_UP_REGIONS*MFB_UP_REG_SIZE*MFB_UP_BLOCK_SIZE*MFB_UP_ITEM_WIDTH-1 downto 0);
    signal ptc_up_mfb_meta         : std_logic_vector(MFB_UP_REGIONS*MFB_UP_META_WIDTH-1 downto 0);
    signal ptc_up_mfb_meta_arr     : slv_array_t(MFB_UP_REGIONS-1 downto 0)(MFB_UP_META_WIDTH-1 downto 0);
    signal ptc_up_mfb_hdr_arr      : slv_array_t(MFB_UP_REGIONS-1 downto 0)(PCI_HDR_W-1 downto 0);
    signal ptc_up_mfb_prefix_arr   : slv_array_t(MFB_UP_REGIONS-1 downto 0)(PCI_PREFIX_W-1 downto 0);
    signal ptc_up_mfb_hdr          : std_logic_vector(MFB_UP_REGIONS*PCI_HDR_W-1 downto 0);
    signal ptc_up_mfb_prefix       : std_logic_vector(MFB_UP_REGIONS*PCI_PREFIX_W-1 downto 0);
    signal ptc_up_mfb_sof          : std_logic_vector(MFB_UP_REGIONS-1 downto 0);
    signal ptc_up_mfb_eof          : std_logic_vector(MFB_UP_REGIONS-1 downto 0);
    signal ptc_up_mfb_sof_pos      : std_logic_vector(MFB_UP_REGIONS*max(1,log2(MFB_UP_REG_SIZE))-1 downto 0);
    signal ptc_up_mfb_eof_pos      : std_logic_vector(MFB_UP_REGIONS*max(1,log2(MFB_UP_REG_SIZE*MFB_UP_BLOCK_SIZE))-1 downto 0);
    signal ptc_up_mfb_src_rdy      : std_logic;
    signal ptc_up_mfb_dst_rdy      : std_logic;

    signal ptc_down_mfb_data       : std_logic_vector(MFB_DOWN_REGIONS*MFB_DOWN_REG_SIZE*MFB_DOWN_BLOCK_SIZE*MFB_DOWN_ITEM_WIDTH-1 downto 0);
    signal ptc_down_mfb_meta       : std_logic_vector(MFB_DOWN_REGIONS*MFB_DOWN_META_WIDTH-1 downto 0);
    signal ptc_down_mfb_meta_arr   : slv_array_t(MFB_UP_REGIONS-1 downto 0)(MFB_DOWN_META_WIDTH-1 downto 0);
    signal ptc_down_mfb_hdr_arr    : slv_array_t(MFB_UP_REGIONS-1 downto 0)(PCI_CHDR_W-1 downto 0);
    signal ptc_down_mfb_prefix_arr : slv_array_t(MFB_UP_REGIONS-1 downto 0)(PCI_PREFIX_W-1 downto 0);
    signal ptc_down_mfb_hdr        : std_logic_vector(MFB_UP_REGIONS*PCI_CHDR_W-1 downto 0);
    signal ptc_down_mfb_prefix     : std_logic_vector(MFB_UP_REGIONS*PCI_PREFIX_W-1 downto 0);
    signal ptc_down_mfb_sof        : std_logic_vector(MFB_DOWN_REGIONS-1 downto 0);
    signal ptc_down_mfb_eof        : std_logic_vector(MFB_DOWN_REGIONS-1 downto 0);
    signal ptc_down_mfb_sof_pos    : std_logic_vector(MFB_DOWN_REGIONS*max(1,log2(MFB_DOWN_REG_SIZE))-1 downto 0);
    signal ptc_down_mfb_eof_pos    : std_logic_vector(MFB_DOWN_REGIONS*max(1,log2(MFB_DOWN_REG_SIZE*MFB_DOWN_BLOCK_SIZE))-1 downto 0);
    signal ptc_down_mfb_src_rdy    : std_logic;
    signal ptc_down_mfb_dst_rdy    : std_logic;

    signal mtc_up_mfb_data         : std_logic_vector(MFB_UP_REGIONS*MFB_UP_REG_SIZE*MFB_UP_BLOCK_SIZE*MFB_UP_ITEM_WIDTH-1 downto 0);
    signal mtc_up_mfb_meta         : std_logic_vector(MFB_UP_REGIONS*MFB_UP_META_WIDTH-1 downto 0);
    signal mtc_up_mfb_sof          : std_logic_vector(MFB_UP_REGIONS-1 downto 0);
    signal mtc_up_mfb_eof          : std_logic_vector(MFB_UP_REGIONS-1 downto 0);
    signal mtc_up_mfb_sof_pos      : std_logic_vector(MFB_UP_REGIONS*max(1,log2(MFB_UP_REG_SIZE))-1 downto 0);
    signal mtc_up_mfb_eof_pos      : std_logic_vector(MFB_UP_REGIONS*max(1,log2(MFB_UP_REG_SIZE*MFB_UP_BLOCK_SIZE))-1 downto 0);
    signal mtc_up_mfb_src_rdy      : std_logic;
    signal mtc_up_mfb_dst_rdy      : std_logic;

    signal mtc_down_mfb_data       : std_logic_vector(MFB_DOWN_REGIONS*MFB_DOWN_REG_SIZE*MFB_DOWN_BLOCK_SIZE*MFB_DOWN_ITEM_WIDTH-1 downto 0);
    signal mtc_down_mfb_meta       : std_logic_vector(MFB_DOWN_REGIONS*MFB_DOWN_META_WIDTH-1 downto 0);
    signal mtc_down_mfb_sof        : std_logic_vector(MFB_DOWN_REGIONS-1 downto 0);
    signal mtc_down_mfb_eof        : std_logic_vector(MFB_DOWN_REGIONS-1 downto 0);
    signal mtc_down_mfb_sof_pos    : std_logic_vector(MFB_DOWN_REGIONS*max(1,log2(MFB_DOWN_REG_SIZE))-1 downto 0);
    signal mtc_down_mfb_eof_pos    : std_logic_vector(MFB_DOWN_REGIONS*max(1,log2(MFB_DOWN_REG_SIZE*MFB_DOWN_BLOCK_SIZE))-1 downto 0);
    signal mtc_down_mfb_src_rdy    : std_logic;
    signal mtc_down_mfb_dst_rdy    : std_logic;

    signal ctl_max_payload_reg     : std_logic_vector(3-1 downto 0);

    signal mtc_mi_dwr              : std_logic_vector(31 downto 0);
    signal mtc_mi_addr             : std_logic_vector(31 downto 0);
    signal mtc_mi_be               : std_logic_vector(3 downto 0);
    signal mtc_mi_rd               : std_logic;
    signal mtc_mi_wr               : std_logic;
    signal mtc_mi_drd              : std_logic_vector(31 downto 0);
    signal mtc_mi_ardy             : std_logic;
    signal mtc_mi_drdy             : std_logic;

    signal mi_sync_dwr             : std_logic_vector(31 downto 0);
    signal mi_sync_addr            : std_logic_vector(31 downto 0);
    signal mi_sync_be              : std_logic_vector(3 downto 0);
    signal mi_sync_rd              : std_logic;
    signal mi_sync_wr              : std_logic;
    signal mi_sync_drd             : std_logic_vector(31 downto 0);
    signal mi_sync_ardy            : std_logic;
    signal mi_sync_drdy            : std_logic;

begin

    -- =========================================================================
    -- PCIE CONNECTION BLOCK
    -- =========================================================================

    pcie_connection_block_i : entity work.PCIE_CONNECTION_BLOCK
    generic map (
        MFB_REGIONS         => MFB_UP_REGIONS,
        MFB_REGION_SIZE     => MFB_UP_REG_SIZE,
        MFB_BLOCK_SIZE      => MFB_UP_BLOCK_SIZE,
        MFB_ITEM_WIDTH      => MFB_UP_ITEM_WIDTH,
        MFB_UP_META_WIDTH   => MFB_UP_META_WIDTH,
        MFB_DOWN_META_WIDTH => MFB_DOWN_META_WIDTH,
        MTC_FIFO_DEPTH      => MTC_FIFO_ITEMS,
        ENDPOINT_TYPE       => ENDPOINT_TYPE,
        DEVICE              => DEVICE
    )
    port map (
        CLK               => PCIE_CLK,
        RESET             => PCIE_RESET(1),
        -- =====================================================================
        -- TO/FROM PCIE IP CORE
        -- =====================================================================
        -- DOWN stream
        RX_AVST_DATA      => AVST_DOWN_DATA,
        RX_AVST_HDR       => AVST_DOWN_HDR,
        RX_AVST_PREFIX    => AVST_DOWN_PREFIX,
        RX_AVST_BAR_RANGE => AVST_DOWN_BAR_RANGE,
		RX_AVST_SOP       => AVST_DOWN_SOP,
		RX_AVST_EOP       => AVST_DOWN_EOP,
        RX_AVST_EMPTY     => AVST_DOWN_EMPTY,
        RX_AVST_VALID     => AVST_DOWN_VALID,
		RX_AVST_READY     => AVST_DOWN_READY,
        -- UP stream
        TX_AVST_DATA      => AVST_UP_DATA,
        TX_AVST_HDR       => AVST_UP_HDR,
        TX_AVST_PREFIX    => AVST_UP_PREFIX,
        TX_AVST_SOP       => AVST_UP_SOP,
        TX_AVST_EOP       => AVST_UP_EOP, 
        TX_AVST_ERROR     => AVST_UP_ERROR, 
        TX_AVST_VALID     => AVST_UP_VALID,
        TX_AVST_READY     => AVST_UP_READY,
        -- DOWN stream credits - R-TILE only
        CRDT_DOWN_INIT_DONE => CRDT_DOWN_INIT_DONE,
        CRDT_DOWN_UPDATE    => CRDT_DOWN_UPDATE,
        CRDT_DOWN_CNT_PH    => CRDT_DOWN_CNT_PH,
        CRDT_DOWN_CNT_NPH   => CRDT_DOWN_CNT_NPH,
        CRDT_DOWN_CNT_CPLH  => CRDT_DOWN_CNT_CPLH,
        CRDT_DOWN_CNT_PD    => CRDT_DOWN_CNT_PD,
        CRDT_DOWN_CNT_NPD   => CRDT_DOWN_CNT_NPD,
        CRDT_DOWN_CNT_CPLD  => CRDT_DOWN_CNT_CPLD,
        -- UP stream credits - R-TILE only
        CRDT_UP_INIT_DONE => CRDT_UP_INIT_DONE,
        CRDT_UP_UPDATE    => CRDT_UP_UPDATE,
        CRDT_UP_CNT_PH    => CRDT_UP_CNT_PH,
        CRDT_UP_CNT_NPH   => CRDT_UP_CNT_NPH,
        CRDT_UP_CNT_CPLH  => CRDT_UP_CNT_CPLH,
        CRDT_UP_CNT_PD    => CRDT_UP_CNT_PD,
        CRDT_UP_CNT_NPD   => CRDT_UP_CNT_NPD,
        CRDT_UP_CNT_CPLD  => CRDT_UP_CNT_CPLD,
        -- =====================================================================
        -- TO/FROM PCIE TRANSACTION CONTROLER (PTC)
        -- =====================================================================
        -- UP stream
        RQ_MFB_DATA       => ptc_up_mfb_data,
        RQ_MFB_META       => ptc_up_mfb_meta,
        RQ_MFB_SOF        => ptc_up_mfb_sof,
        RQ_MFB_EOF        => ptc_up_mfb_eof,
        RQ_MFB_SOF_POS    => ptc_up_mfb_sof_pos,
        RQ_MFB_EOF_POS    => ptc_up_mfb_eof_pos,
        RQ_MFB_SRC_RDY    => ptc_up_mfb_src_rdy,
        RQ_MFB_DST_RDY    => ptc_up_mfb_dst_rdy,
        -- DOWN stream
        RC_MFB_DATA       => ptc_down_mfb_data,
        RC_MFB_META       => ptc_down_mfb_meta,
        RC_MFB_SOF        => ptc_down_mfb_sof,
        RC_MFB_EOF        => ptc_down_mfb_eof,
        RC_MFB_SOF_POS    => ptc_down_mfb_sof_pos,
        RC_MFB_EOF_POS    => ptc_down_mfb_eof_pos,
        RC_MFB_SRC_RDY    => ptc_down_mfb_src_rdy,
        RC_MFB_DST_RDY    => ptc_down_mfb_dst_rdy,
        -- =====================================================================
        -- TO/FROM MI32 TRANSACTION CONTROLER (MTC)
        -- =====================================================================
        -- UP stream
        CC_MFB_DATA       => mtc_up_mfb_data,
        CC_MFB_META       => mtc_up_mfb_meta,
        CC_MFB_SOF        => mtc_up_mfb_sof,
        CC_MFB_EOF        => mtc_up_mfb_eof,
        CC_MFB_SOF_POS    => mtc_up_mfb_sof_pos,
        CC_MFB_EOF_POS    => mtc_up_mfb_eof_pos,
        CC_MFB_SRC_RDY    => mtc_up_mfb_src_rdy,
        CC_MFB_DST_RDY    => mtc_up_mfb_dst_rdy,
        -- DOWN stream
        CQ_MFB_DATA       => mtc_down_mfb_data,
        CQ_MFB_META       => mtc_down_mfb_meta,
        CQ_MFB_SOF        => mtc_down_mfb_sof,
        CQ_MFB_EOF        => mtc_down_mfb_eof,
        CQ_MFB_SOF_POS    => mtc_down_mfb_sof_pos,
        CQ_MFB_EOF_POS    => mtc_down_mfb_eof_pos,
        CQ_MFB_SRC_RDY    => mtc_down_mfb_src_rdy,
        CQ_MFB_DST_RDY    => mtc_down_mfb_dst_rdy
    );

    -- =========================================================================
    --  PCIE TRANSACTION CTRL
    -- =========================================================================

    ptc_down_mfb_meta_arr <= slv_array_deser(ptc_down_mfb_meta,MFB_DOWN_REGIONS,MFB_DOWN_META_WIDTH);

    ptc_down_mfb_meta_unpack_g : for i in 0 to MFB_DOWN_REGIONS-1 generate
        ptc_down_mfb_hdr_arr(i)    <= ptc_down_mfb_meta_arr(i)(PCI_CHDR_W-1 downto 0);
        ptc_down_mfb_prefix_arr(i) <= ptc_down_mfb_meta_arr(i)(PCI_HDR_W+PCI_PREFIX_W-1 downto PCI_HDR_W);
    end generate;

    ptc_down_mfb_hdr    <= slv_array_ser(ptc_down_mfb_hdr_arr,MFB_DOWN_REGIONS,PCI_CHDR_W);
    ptc_down_mfb_prefix <= slv_array_ser(ptc_down_mfb_prefix_arr,MFB_DOWN_REGIONS,PCI_PREFIX_W);

    ptc_up_mfb_hdr_arr    <= slv_array_deser(ptc_up_mfb_hdr,MFB_UP_REGIONS,PCI_HDR_W);
    ptc_up_mfb_prefix_arr <= slv_array_deser(ptc_up_mfb_prefix,MFB_UP_REGIONS,PCI_PREFIX_W);

    ptc_up_mfb_meta_pack_g : for i in 0 to MFB_UP_REGIONS-1 generate
        ptc_up_mfb_meta_arr(i)(PCI_HDR_W-1 downto 0)                      <= ptc_up_mfb_hdr_arr(i);
        ptc_up_mfb_meta_arr(i)(PCI_HDR_W+PCI_PREFIX_W-1 downto PCI_HDR_W) <= ptc_up_mfb_prefix_arr(i);
    end generate;

    ptc_up_mfb_meta <= slv_array_ser(ptc_up_mfb_meta_arr,MFB_UP_REGIONS,MFB_UP_META_WIDTH);

    ptc_i : entity work.PCIE_TRANSACTION_CTRL
    generic map(
        DMA_PORTS            => DMA_PORTS,

        MVB_UP_ITEMS         => MVB_UP_ITEMS,
        DMA_MVB_UP_ITEMS     => DMA_MVB_UP_ITEMS,
        MFB_UP_REGIONS       => MFB_UP_REGIONS,
        DMA_MFB_UP_REGIONS   => DMA_MFB_UP_REGIONS,
        MFB_UP_REG_SIZE      => MFB_UP_REG_SIZE,
        MFB_UP_BLOCK_SIZE    => MFB_UP_BLOCK_SIZE,
        MFB_UP_ITEM_WIDTH    => MFB_UP_ITEM_WIDTH,

        MVB_DOWN_ITEMS       => MVB_DOWN_ITEMS,
        DMA_MVB_DOWN_ITEMS   => DMA_MVB_DOWN_ITEMS,
        MFB_DOWN_REGIONS     => MFB_DOWN_REGIONS,
        DMA_MFB_DOWN_REGIONS => DMA_MFB_DOWN_REGIONS,
        MFB_DOWN_REG_SIZE    => MFB_DOWN_REG_SIZE,
        MFB_DOWN_BLOCK_SIZE  => MFB_DOWN_BLOCK_SIZE,
        MFB_DOWN_ITEM_WIDTH  => MFB_DOWN_ITEM_WIDTH,

        DOWN_FIFO_ITEMS      => 1024,
        AUTO_ASSIGN_TAGS     => true,

        ENDPOINT_TYPE        => ENDPOINT_TYPE,
        DEVICE               => DEVICE
    )
    port map(
        CLK                => PCIE_CLK,
        RESET              => PCIE_RESET(2),

        CLK_DMA            => DMA_CLK,
        RESET_DMA          => DMA_RESET,

        RQ_MVB_HDR_DATA    => ptc_up_mfb_hdr,
        RQ_MVB_PREFIX_DATA => ptc_up_mfb_prefix,
        RQ_MVB_VLD         => open,
        RQ_MFB_DATA        => ptc_up_mfb_data,
        RQ_MFB_SOF         => ptc_up_mfb_sof,
        RQ_MFB_EOF         => ptc_up_mfb_eof,
        RQ_MFB_SOF_POS     => ptc_up_mfb_sof_pos,
        RQ_MFB_EOF_POS     => ptc_up_mfb_eof_pos,
        RQ_MFB_SRC_RDY     => ptc_up_mfb_src_rdy,
        RQ_MFB_DST_RDY     => ptc_up_mfb_dst_rdy,

        RC_MVB_HDR_DATA    => ptc_down_mfb_hdr,
        RC_MVB_PREFIX_DATA => ptc_down_mfb_prefix,
        RC_MVB_VLD         => ptc_down_mfb_sof,
        RC_MFB_DATA        => ptc_down_mfb_data,
        RC_MFB_SOF         => ptc_down_mfb_sof,
        RC_MFB_EOF         => ptc_down_mfb_eof,
        RC_MFB_SOF_POS     => ptc_down_mfb_sof_pos,
        RC_MFB_EOF_POS     => ptc_down_mfb_eof_pos,
        RC_MFB_SRC_RDY     => ptc_down_mfb_src_rdy,
        RC_MFB_DST_RDY     => ptc_down_mfb_dst_rdy,

        UP_MVB_DATA      => UP_MVB_DATA,
        UP_MVB_VLD       => UP_MVB_VLD,
        UP_MVB_SRC_RDY   => UP_MVB_SRC_RDY,
        UP_MVB_DST_RDY   => UP_MVB_DST_RDY,

        UP_MFB_DATA      => UP_MFB_DATA,
        UP_MFB_SOF       => UP_MFB_SOF,
        UP_MFB_EOF       => UP_MFB_EOF,
        UP_MFB_SOF_POS   => UP_MFB_SOF_POS,
        UP_MFB_EOF_POS   => UP_MFB_EOF_POS,
        UP_MFB_SRC_RDY   => UP_MFB_SRC_RDY,
        UP_MFB_DST_RDY   => UP_MFB_DST_RDY,

        DOWN_MVB_DATA    => DOWN_MVB_DATA,
        DOWN_MVB_VLD     => DOWN_MVB_VLD,
        DOWN_MVB_SRC_RDY => DOWN_MVB_SRC_RDY,
        DOWN_MVB_DST_RDY => DOWN_MVB_DST_RDY,

        DOWN_MFB_DATA    => DOWN_MFB_DATA,
        DOWN_MFB_SOF     => DOWN_MFB_SOF,
        DOWN_MFB_EOF     => DOWN_MFB_EOF,
        DOWN_MFB_SOF_POS => DOWN_MFB_SOF_POS,
        DOWN_MFB_EOF_POS => DOWN_MFB_EOF_POS,
        DOWN_MFB_SRC_RDY => DOWN_MFB_SRC_RDY,
        DOWN_MFB_DST_RDY => DOWN_MFB_DST_RDY,

        RCB_SIZE         => CTL_RCB_SIZE,

        TAG_ASSIGN       => (others => '0'),
        TAG_ASSIGN_VLD   => (others => '0')
    );

    -- =========================================================================
    -- MI32 CONTROLLER
    -- =========================================================================

    gen_mtc : if (ENABLE_MI) generate

        process (PCIE_CLK)
        begin
            if (rising_edge(PCIE_CLK)) then
                ctl_max_payload_reg <= CTL_MAX_PAYLOAD;
            end if;
        end process;

        mtc_i : entity work.MTC
        generic map (
            AXI_DATA_WIDTH    => AXI_DATA_WIDTH,
            AXI_CQUSER_WIDTH  => AXI_CQUSER_WIDTH,
            AXI_CCUSER_WIDTH  => AXI_CCUSER_WIDTH,
            MFB_REGIONS       => MFB_UP_REGIONS,
            MFB_REGION_SIZE   => MFB_UP_REG_SIZE,
            MFB_BLOCK_SIZE    => MFB_UP_BLOCK_SIZE,
            MFB_ITEM_WIDTH    => MFB_UP_ITEM_WIDTH,
            MFB_CQ_META_WIDTH => MFB_DOWN_META_WIDTH,
            MFB_CC_META_WIDTH => MFB_UP_META_WIDTH,

            BAR0_BASE_ADDR    => BAR0_BASE_ADDR,
            BAR1_BASE_ADDR    => BAR1_BASE_ADDR,
            BAR2_BASE_ADDR    => BAR2_BASE_ADDR,
            BAR3_BASE_ADDR    => BAR3_BASE_ADDR,
            BAR4_BASE_ADDR    => BAR4_BASE_ADDR,
            BAR5_BASE_ADDR    => BAR5_BASE_ADDR,
            EXP_ROM_BASE_ADDR => EXP_ROM_BASE_ADDR,
            
            ENDPOINT_TYPE     => ENDPOINT_TYPE,
            DEVICE            => DEVICE
        )
        port map (
            -- Common signals
            CLK               => PCIE_CLK,
            RESET             => PCIE_RESET(5),

            CTL_MAX_PAYLOAD_SIZE => ctl_max_payload_reg,
            CTL_BAR_APERTURE     => CTL_BAR_APERTURE,

            CQ_MFB_DATA       => mtc_down_mfb_data,
            CQ_MFB_META       => mtc_down_mfb_meta,
            CQ_MFB_SOF        => mtc_down_mfb_sof,
            CQ_MFB_EOF        => mtc_down_mfb_eof,
            CQ_MFB_SOF_POS    => mtc_down_mfb_sof_pos,
            CQ_MFB_EOF_POS    => mtc_down_mfb_eof_pos,
            CQ_MFB_SRC_RDY    => mtc_down_mfb_src_rdy,
            CQ_MFB_DST_RDY    => mtc_down_mfb_dst_rdy,

            CC_MFB_DATA       => mtc_up_mfb_data,
            CC_MFB_META       => mtc_up_mfb_meta,
            CC_MFB_SOF        => mtc_up_mfb_sof,
            CC_MFB_EOF        => mtc_up_mfb_eof,
            CC_MFB_SOF_POS    => mtc_up_mfb_sof_pos,
            CC_MFB_EOF_POS    => mtc_up_mfb_eof_pos,
            CC_MFB_SRC_RDY    => mtc_up_mfb_src_rdy,
            CC_MFB_DST_RDY    => mtc_up_mfb_dst_rdy,

            CQ_AXI_DATA       => (others => '0'),
            CQ_AXI_USER       => (others => '0'),
            CQ_AXI_LAST       => '0',
            CQ_AXI_KEEP       => (others => '0'),
            CQ_AXI_VALID      => '0',
            CQ_AXI_READY      => open,

            CC_AXI_DATA       => open,
            CC_AXI_USER       => open,
            CC_AXI_LAST       => open,
            CC_AXI_KEEP       => open,
            CC_AXI_VALID      => open,
            CC_AXI_READY      => '0',

            MI_DWR            => mtc_mi_dwr,
            MI_ADDR           => mtc_mi_addr,
            MI_BE             => mtc_mi_be,
            MI_RD             => mtc_mi_rd,
            MI_WR             => mtc_mi_wr,
            MI_DRD            => mtc_mi_drd,
            MI_ARDY           => mtc_mi_ardy,
            MI_DRDY           => mtc_mi_drdy
        );

        mi_async_i : entity work.MI_ASYNC
        generic map(
            DEVICE => DEVICE
        )
        port map(
            -- Master interface
            CLK_M     => PCIE_CLK,
            RESET_M   => PCIE_RESET(4),
            MI_M_DWR  => mtc_mi_dwr,
            MI_M_ADDR => mtc_mi_addr,
            MI_M_RD   => mtc_mi_rd,
            MI_M_WR   => mtc_mi_wr,
            MI_M_BE   => mtc_mi_be,
            MI_M_DRD  => mtc_mi_drd,
            MI_M_ARDY => mtc_mi_ardy,
            MI_M_DRDY => mtc_mi_drdy,

            -- Slave interface
            CLK_S     => MI_CLK,
            RESET_S   => MI_RESET,
            MI_S_DWR  => mi_sync_dwr,
            MI_S_ADDR => mi_sync_addr,
            MI_S_RD   => mi_sync_rd,
            MI_S_WR   => mi_sync_wr,
            MI_S_BE   => mi_sync_be,
            MI_S_DRD  => mi_sync_drd,
            MI_S_ARDY => mi_sync_ardy,
            MI_S_DRDY => mi_sync_drdy
        );

        mi_pipe_i : entity work.MI_PIPE
        generic map(
            DEVICE      => DEVICE,
            DATA_WIDTH  => 32,
            ADDR_WIDTH  => 32,
            PIPE_TYPE   => "REG",
            USE_OUTREG  => True,
            FAKE_PIPE   => False
        )
        port map(
            -- Common interface
            CLK      => MI_CLK,
            RESET    => MI_RESET,
            
            -- Input MI interface
            IN_DWR   => mi_sync_dwr,
            IN_ADDR  => mi_sync_addr,
            IN_RD    => mi_sync_rd,
            IN_WR    => mi_sync_wr,
            IN_BE    => mi_sync_be,
            IN_DRD   => mi_sync_drd,
            IN_ARDY  => mi_sync_ardy,
            IN_DRDY  => mi_sync_drdy,
            
            -- Output MI interface
            OUT_DWR  => MI_DWR,
            OUT_ADDR => MI_ADDR,
            OUT_RD   => MI_RD,
            OUT_WR   => MI_WR,
            OUT_BE   => MI_BE,
            OUT_DRD  => MI_DRD,
            OUT_ARDY => MI_ARDY,
            OUT_DRDY => MI_DRDY
        );
    else generate
        mtc_down_mfb_dst_rdy <= '1';
        mtc_up_mfb_data      <= (others => '0');
        mtc_up_mfb_meta      <= (others => '0');
        mtc_up_mfb_sof       <= (others => '0');
        mtc_up_mfb_eof       <= (others => '0');
        mtc_up_mfb_sof_pos   <= (others => '0');
        mtc_up_mfb_eof_pos   <= (others => '0');
        mtc_up_mfb_src_rdy   <= '0';

        MI_DWR  <= (others => '0');
        MI_ADDR <= (others => '0');
        MI_BE   <= (others => '0');
        MI_RD   <= '0';
        MI_WR   <= '0';
    end generate;

end architecture;
