-- pcie_top.vhd: Top level of PCIe module
-- Copyright (C) 2019 CESNET z. s. p. o.
-- Author(s): Jakub Cabal <cabal@cesnet.cz>
--
-- SPDX-License-Identifier: BSD-3-Clause

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.math_pack.all;
use work.type_pack.all;
use work.dma_bus_pack.all;

entity PCIE is
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

        VENDOR_ID           : std_logic_vector(15 downto 0) := X"18EC";
        DEVICE_ID           : std_logic_vector(15 downto 0) := X"C400";
        SUBVENDOR_ID        : std_logic_vector(15 downto 0) := X"0000";
        SUBDEVICE_ID        : std_logic_vector(15 downto 0) := X"0000";
        XVC_ENABLE          : boolean := false;
        PF0_TOTAL_VF        : natural := 0;

        DMA_ENDPOINTS       : natural := 1; -- total number of DMA_EP, DMA_EP=PCIE_EP or 2*DMA_EP=PCIE_EP

        MVB_UP_ITEMS        : natural := 2;   -- Number of items (headers) in word
        MFB_UP_REGIONS      : natural := 2;   -- Number of regions in word
        MFB_UP_REG_SIZE     : natural := 1;   -- Number of blocks in region
        MFB_UP_BLOCK_SIZE   : natural := 8;   -- Number of items in block
        MFB_UP_ITEM_WIDTH   : natural := 32;  -- Width of one item (in bits)

        MVB_DOWN_ITEMS      : natural := 2;   -- Number of items (headers) in word
        MFB_DOWN_REGIONS    : natural := 2;   -- Number of regions in word
        MFB_DOWN_REG_SIZE   : natural := 1;   -- Number of blocks in region
        MFB_DOWN_BLOCK_SIZE : natural := 8;   -- Number of items in block
        MFB_DOWN_ITEM_WIDTH : natural := 32;  -- Width of one item (in bits)
        
        -- Connected PCIe endpoint type ("H_TILE" or "P_TILE" or "R_TILE")
        ENDPOINT_TYPE       : string  := "P_TILE";
        -- Connected PCIe endpoint mode: 0 = 1x16 lanes, 1 = 2x8 lanes
        ENDPOINT_MODE       : natural := 0;
        -- Number of instantiated PCIe endpoints
            -- When ENDPOINT_MODE = 0: PCIE_ENDPOINTS=PCIE_CONS
            -- When ENDPOINT_MODE = 1: PCIE_ENDPOINTS=2*PCIE_CONS
        PCIE_ENDPOINTS      : natural := 1;
        PCIE_CLKS           : natural := 1;
        PCIE_CONS           : natural := 1;
        PCIE_LANES          : natural := 16;

        -- FPGA device
        DEVICE              : string  := "STRATIX10"
    );
    port(
        -- =====================================================================
        --  PCIE INTERFACE
        -- =====================================================================
        -- Clock from PCIe port, 100 MHz
        PCIE_SYSCLK_P    : in  std_logic_vector(PCIE_CONS*PCIE_CLKS-1 downto 0);
        PCIE_SYSCLK_N    : in  std_logic_vector(PCIE_CONS*PCIE_CLKS-1 downto 0);
        -- PCIe reset from PCIe port
        PCIE_SYSRST_N    : in  std_logic_vector(PCIE_CONS-1 downto 0);
        -- nINIT_DONE output of the Reset Release Intel Stratix 10 FPGA IP
        INIT_DONE_N      : in  std_logic;
        -- Receive data
        PCIE_RX_P        : in  std_logic_vector(PCIE_CONS*PCIE_LANES-1 downto 0);
        PCIE_RX_N        : in  std_logic_vector(PCIE_CONS*PCIE_LANES-1 downto 0);
        -- Transmit data
        PCIE_TX_P        : out std_logic_vector(PCIE_CONS*PCIE_LANES-1 downto 0);
        PCIE_TX_N        : out std_logic_vector(PCIE_CONS*PCIE_LANES-1 downto 0);
        -- PCIe user clock and reset
        PCIE_USER_CLK    : out std_logic_vector(PCIE_ENDPOINTS-1 downto 0);
        PCIE_USER_RESET  : out std_logic_vector(PCIE_ENDPOINTS-1 downto 0);
        -- Configuration status interface (PCIE_USER_CLK)
        -- ----------------------------------------------
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
        --  DMA BUS - DOWN/UP - MFB/MVB Streams (DMA_CLK)
        -- =====================================================================
        DMA_CLK          : in  std_logic;
        DMA_RESET        : in  std_logic;

        UP_MVB_DATA      : in  slv_array_t(DMA_ENDPOINTS-1 downto 0)(MVB_UP_ITEMS*DMA_UPHDR_WIDTH-1 downto 0);
        UP_MVB_VLD       : in  slv_array_t(DMA_ENDPOINTS-1 downto 0)(MVB_UP_ITEMS-1 downto 0);
        UP_MVB_SRC_RDY   : in  std_logic_vector(DMA_ENDPOINTS-1 downto 0);
        UP_MVB_DST_RDY   : out std_logic_vector(DMA_ENDPOINTS-1 downto 0);

        UP_MFB_DATA      : in  slv_array_t(DMA_ENDPOINTS-1 downto 0)(MFB_UP_REGIONS*MFB_UP_REG_SIZE*MFB_UP_BLOCK_SIZE*MFB_UP_ITEM_WIDTH-1 downto 0);
        UP_MFB_SOF       : in  slv_array_t(DMA_ENDPOINTS-1 downto 0)(MFB_UP_REGIONS-1 downto 0);
        UP_MFB_EOF       : in  slv_array_t(DMA_ENDPOINTS-1 downto 0)(MFB_UP_REGIONS-1 downto 0);
        UP_MFB_SOF_POS   : in  slv_array_t(DMA_ENDPOINTS-1 downto 0)(MFB_UP_REGIONS*max(1,log2(MFB_UP_REG_SIZE))-1 downto 0);
        UP_MFB_EOF_POS   : in  slv_array_t(DMA_ENDPOINTS-1 downto 0)(MFB_UP_REGIONS*max(1,log2(MFB_UP_REG_SIZE*MFB_UP_BLOCK_SIZE))-1 downto 0);
        UP_MFB_SRC_RDY   : in  std_logic_vector(DMA_ENDPOINTS-1 downto 0);
        UP_MFB_DST_RDY   : out std_logic_vector(DMA_ENDPOINTS-1 downto 0);

        DOWN_MVB_DATA    : out slv_array_t(DMA_ENDPOINTS-1 downto 0)(MVB_DOWN_ITEMS*DMA_DOWNHDR_WIDTH-1 downto 0);
        DOWN_MVB_VLD     : out slv_array_t(DMA_ENDPOINTS-1 downto 0)(MVB_DOWN_ITEMS-1 downto 0);
        DOWN_MVB_SRC_RDY : out std_logic_vector(DMA_ENDPOINTS-1 downto 0);
        DOWN_MVB_DST_RDY : in  std_logic_vector(DMA_ENDPOINTS-1 downto 0);

        DOWN_MFB_DATA    : out slv_array_t(DMA_ENDPOINTS-1 downto 0)(MFB_DOWN_REGIONS*MFB_DOWN_REG_SIZE*MFB_DOWN_BLOCK_SIZE*MFB_DOWN_ITEM_WIDTH-1 downto 0);
        DOWN_MFB_SOF     : out slv_array_t(DMA_ENDPOINTS-1 downto 0)(MFB_DOWN_REGIONS-1 downto 0);
        DOWN_MFB_EOF     : out slv_array_t(DMA_ENDPOINTS-1 downto 0)(MFB_DOWN_REGIONS-1 downto 0);
        DOWN_MFB_SOF_POS : out slv_array_t(DMA_ENDPOINTS-1 downto 0)(MFB_DOWN_REGIONS*max(1,log2(MFB_DOWN_REG_SIZE))-1 downto 0);
        DOWN_MFB_EOF_POS : out slv_array_t(DMA_ENDPOINTS-1 downto 0)(MFB_DOWN_REGIONS*max(1,log2(MFB_DOWN_REG_SIZE*MFB_DOWN_BLOCK_SIZE))-1 downto 0);
        DOWN_MFB_SRC_RDY : out std_logic_vector(DMA_ENDPOINTS-1 downto 0);
        DOWN_MFB_DST_RDY : in  std_logic_vector(DMA_ENDPOINTS-1 downto 0);

        -- =====================================================================
        -- MI32 interface - root of the MI32 bus tree (MI_CLK)
        -- =====================================================================
        MI_CLK           : in  std_logic;
        MI_RESET         : in  std_logic;

        MI_DWR           : out slv_array_t(PCIE_ENDPOINTS-1 downto 0)(32-1 downto 0);
        MI_ADDR          : out slv_array_t(PCIE_ENDPOINTS-1 downto 0)(32-1 downto 0);
        MI_BE            : out slv_array_t(PCIE_ENDPOINTS-1 downto 0)(32/8-1 downto 0);
        MI_RD            : out std_logic_vector(PCIE_ENDPOINTS-1 downto 0);
        MI_WR            : out std_logic_vector(PCIE_ENDPOINTS-1 downto 0);
        MI_DRD           : in  slv_array_t(PCIE_ENDPOINTS-1 downto 0)(32-1 downto 0);
        MI_ARDY          : in  std_logic_vector(PCIE_ENDPOINTS-1 downto 0);
        MI_DRDY          : in  std_logic_vector(PCIE_ENDPOINTS-1 downto 0)
    );
end entity;

architecture FULL of PCIE is

    constant DMA_PORTS_PER_EP : natural := DMA_ENDPOINTS/PCIE_ENDPOINTS;
    constant RTILE_DEVICE     : boolean := (DEVICE="AGILEX" and ENDPOINT_TYPE="R_TILE");
    constant PCIEX8_REGIONS   : natural := tsel(RTILE_DEVICE,MFB_UP_REGIONS,MFB_UP_REGIONS/2);
    constant PCIE_MFB_REGIONS : natural := tsel((ENDPOINT_MODE=1),PCIEX8_REGIONS,2*PCIEX8_REGIONS);
    constant RESET_WIDTH      : natural := 6;
    constant MAX_PAYLOAD_SIZE : natural := 512;
    -- MPS_CODE:
    -- 000b: 128 bytes maximum payload size
    -- 001b: 256 bytes maximum payload size
    -- 010b: 512 bytes maximum payload size
    -- 011b: 1024 bytes maximum payload size
    constant MPS_CODE         : std_logic_vector(2 downto 0) := std_logic_vector(to_unsigned((log2(MAX_PAYLOAD_SIZE)-7),3));
    constant BAR_APERTURE     : natural := 26;
    -- 1credit = 16B = 128b = 4DW
    constant AVST_WORD_CRDT   : natural := (PCIE_MFB_REGIONS*MFB_DOWN_REG_SIZE*MFB_DOWN_BLOCK_SIZE*MFB_DOWN_ITEM_WIDTH)/128;
    constant MTC_FIFO_ITEMS   : natural := 512;
    constant MTC_FIFO_CRDT    : natural := MTC_FIFO_ITEMS*AVST_WORD_CRDT;
    constant CRDT_TOTAL_XPH   : natural := MTC_FIFO_CRDT/(MAX_PAYLOAD_SIZE/16);
    constant AXI_DATA_WIDTH   : natural := PCIE_MFB_REGIONS*256;
    constant AXI_CQUSER_WIDTH : natural := 183;
    constant AXI_CCUSER_WIDTH : natural := 81;
    constant AXI_RQUSER_WIDTH : natural := 137;
    constant AXI_RCUSER_WIDTH : natural := 161;

    signal pcie_clk                 : std_logic_vector(PCIE_ENDPOINTS-1 downto 0);
    signal pcie_reset               : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(RESET_WIDTH-1 downto 0);

    signal pcie_cfg_mps             : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(3-1 downto 0);
    signal pcie_cfg_mrrs            : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(3-1 downto 0);
    signal pcie_cfg_ext_tag_en      : std_logic_vector(PCIE_ENDPOINTS-1 downto 0);
    signal pcie_cfg_10b_tag_req_en  : std_logic_vector(PCIE_ENDPOINTS-1 downto 0);
    signal pcie_cfg_rcb_size        : std_logic_vector(PCIE_ENDPOINTS-1 downto 0);

    signal crdt_up_init_done        : std_logic_vector(PCIE_ENDPOINTS-1 downto 0);
    signal crdt_up_update           : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(6-1 downto 0);
    signal crdt_up_cnt_ph           : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(2-1 downto 0);
    signal crdt_up_cnt_nph          : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(2-1 downto 0);
    signal crdt_up_cnt_cplh         : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(2-1 downto 0);
    signal crdt_up_cnt_pd           : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(4-1 downto 0);
    signal crdt_up_cnt_npd          : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(4-1 downto 0);
    signal crdt_up_cnt_cpld         : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(4-1 downto 0);

    signal crdt_down_init_done      : std_logic_vector(PCIE_ENDPOINTS-1 downto 0);
    signal crdt_down_update         : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(6-1 downto 0);
    signal crdt_down_cnt_ph         : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(2-1 downto 0);
    signal crdt_down_cnt_nph        : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(2-1 downto 0);
    signal crdt_down_cnt_cplh       : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(2-1 downto 0);
    signal crdt_down_cnt_pd         : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(4-1 downto 0);
    signal crdt_down_cnt_npd        : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(4-1 downto 0);
    signal crdt_down_cnt_cpld       : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(4-1 downto 0);

    signal pcie_avst_down_data      : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(PCIE_MFB_REGIONS*256-1 downto 0);
    signal pcie_avst_down_hdr       : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(PCIE_MFB_REGIONS*128-1 downto 0);
    signal pcie_avst_down_prefix    : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(PCIE_MFB_REGIONS*32-1 downto 0);
	signal pcie_avst_down_sop       : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(PCIE_MFB_REGIONS-1 downto 0);
	signal pcie_avst_down_eop       : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(PCIE_MFB_REGIONS-1 downto 0);
    signal pcie_avst_down_empty     : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(PCIE_MFB_REGIONS*3-1 downto 0);
    signal pcie_avst_down_bar_range : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(PCIE_MFB_REGIONS*3-1 downto 0);
    signal pcie_avst_down_valid     : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(PCIE_MFB_REGIONS-1 downto 0);
	signal pcie_avst_down_ready     : std_logic_vector(PCIE_ENDPOINTS-1 downto 0);

    signal pcie_avst_up_data        : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(PCIE_MFB_REGIONS*256-1 downto 0);
    signal pcie_avst_up_hdr         : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(PCIE_MFB_REGIONS*128-1 downto 0);
    signal pcie_avst_up_prefix      : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(PCIE_MFB_REGIONS*32-1 downto 0);
	signal pcie_avst_up_sop         : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(PCIE_MFB_REGIONS-1 downto 0);
	signal pcie_avst_up_eop         : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(PCIE_MFB_REGIONS-1 downto 0);
    signal pcie_avst_up_error       : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(PCIE_MFB_REGIONS-1 downto 0);
    signal pcie_avst_up_valid       : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(PCIE_MFB_REGIONS-1 downto 0);
	signal pcie_avst_up_ready       : std_logic_vector(PCIE_ENDPOINTS-1 downto 0);

    signal pcie_cq_axi_data         : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(AXI_DATA_WIDTH-1 downto 0);
    signal pcie_cq_axi_user         : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(AXI_CQUSER_WIDTH-1 downto 0);
    signal pcie_cq_axi_last         : std_logic_vector(PCIE_ENDPOINTS-1 downto 0);
    signal pcie_cq_axi_keep         : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(AXI_DATA_WIDTH/32-1 downto 0);
    signal pcie_cq_axi_valid        : std_logic_vector(PCIE_ENDPOINTS-1 downto 0);
    signal pcie_cq_axi_ready        : std_logic_vector(PCIE_ENDPOINTS-1 downto 0);

    signal pcie_cc_axi_data         : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(AXI_DATA_WIDTH-1 downto 0);
    signal pcie_cc_axi_user         : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(AXI_CCUSER_WIDTH-1 downto 0);
    signal pcie_cc_axi_last         : std_logic_vector(PCIE_ENDPOINTS-1 downto 0);
    signal pcie_cc_axi_keep         : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(AXI_DATA_WIDTH/32-1 downto 0);
    signal pcie_cc_axi_valid        : std_logic_vector(PCIE_ENDPOINTS-1 downto 0);
    signal pcie_cc_axi_ready        : std_logic_vector(PCIE_ENDPOINTS-1 downto 0);

    signal pcie_rq_axi_data         : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(AXI_DATA_WIDTH-1 downto 0);
    signal pcie_rq_axi_user         : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(AXI_RQUSER_WIDTH-1 downto 0);
    signal pcie_rq_axi_last         : std_logic_vector(PCIE_ENDPOINTS-1 downto 0);
    signal pcie_rq_axi_keep         : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(AXI_DATA_WIDTH/32-1 downto 0);
    signal pcie_rq_axi_valid        : std_logic_vector(PCIE_ENDPOINTS-1 downto 0);
    signal pcie_rq_axi_ready        : std_logic_vector(PCIE_ENDPOINTS-1 downto 0);

    signal pcie_rc_axi_data         : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(AXI_DATA_WIDTH-1 downto 0);
    signal pcie_rc_axi_user         : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(AXI_RCUSER_WIDTH-1 downto 0);
    signal pcie_rc_axi_last         : std_logic_vector(PCIE_ENDPOINTS-1 downto 0);
    signal pcie_rc_axi_keep         : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(AXI_DATA_WIDTH/32-1 downto 0);
    signal pcie_rc_axi_valid        : std_logic_vector(PCIE_ENDPOINTS-1 downto 0);
    signal pcie_rc_axi_ready        : std_logic_vector(PCIE_ENDPOINTS-1 downto 0);

    signal pcie_tag_assign          : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(PCIE_MFB_REGIONS*8-1 downto 0);
    signal pcie_tag_assign_vld      : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(PCIE_MFB_REGIONS-1 downto 0);

begin

    -- =========================================================================
    --  PCIE CORE
    -- =========================================================================

    -- the architecture depends on the selected board, see Modules.tcl
    pcie_core_i : entity work.PCIE_CORE
    generic map (
        AVST_REGIONS     => PCIE_MFB_REGIONS,
        AXI_DATA_WIDTH   => AXI_DATA_WIDTH,
        AXI_CQUSER_WIDTH => AXI_CQUSER_WIDTH,
        AXI_CCUSER_WIDTH => AXI_CCUSER_WIDTH,
        AXI_RQUSER_WIDTH => AXI_RQUSER_WIDTH,
        AXI_RCUSER_WIDTH => AXI_RCUSER_WIDTH,
        MVB_UP_ITEMS     => PCIE_MFB_REGIONS,
        ENDPOINT_MODE    => ENDPOINT_MODE,
        PCIE_ENDPOINTS   => PCIE_ENDPOINTS,
        PCIE_CLKS        => PCIE_CLKS,
        PCIE_CONS        => PCIE_CONS,
        PCIE_LANES       => PCIE_LANES,
        VENDOR_ID        => VENDOR_ID,
        DEVICE_ID        => DEVICE_ID,
        SUBVENDOR_ID     => SUBVENDOR_ID,
        SUBDEVICE_ID     => SUBDEVICE_ID,
        XVC_ENABLE       => XVC_ENABLE,
        PF0_TOTAL_VF     => PF0_TOTAL_VF,
        CRDT_TOTAL_PH    => CRDT_TOTAL_XPH/2,
        CRDT_TOTAL_NPH   => CRDT_TOTAL_XPH/2,
        CRDT_TOTAL_CPLH  => 0,
        CRDT_TOTAL_PD    => MTC_FIFO_CRDT/2,
        CRDT_TOTAL_NPD   => MTC_FIFO_CRDT/2,
        CRDT_TOTAL_CPLD  => 0,
        RESET_WIDTH      => RESET_WIDTH,
        DEVICE           => DEVICE
    )
    port map (
        PCIE_SYSCLK_P       => PCIE_SYSCLK_P,
        PCIE_SYSCLK_N       => PCIE_SYSCLK_N,
        PCIE_SYSRST_N       => PCIE_SYSRST_N,
        INIT_DONE_N         => INIT_DONE_N,
        
        PCIE_RX_P           => PCIE_RX_P,
        PCIE_RX_N           => PCIE_RX_N,
        PCIE_TX_P           => PCIE_TX_P,
        PCIE_TX_N           => PCIE_TX_N,

        PCIE_USER_CLK       => pcie_clk,
        PCIE_USER_RESET     => pcie_reset,

        PCIE_LINK_UP        => PCIE_LINK_UP,
        PCIE_MPS            => pcie_cfg_mps,
        PCIE_MRRS           => pcie_cfg_mrrs,
        PCIE_EXT_TAG_EN     => pcie_cfg_ext_tag_en,
        PCIE_10B_TAG_REQ_EN => pcie_cfg_10b_tag_req_en,
        PCIE_RCB_SIZE       => pcie_cfg_rcb_size,

        CRDT_UP_INIT_DONE   => crdt_up_init_done,
        CRDT_UP_UPDATE      => crdt_up_update,
        CRDT_UP_CNT_PH      => crdt_up_cnt_ph,
        CRDT_UP_CNT_NPH     => crdt_up_cnt_nph,
        CRDT_UP_CNT_CPLH    => crdt_up_cnt_cplh,
        CRDT_UP_CNT_PD      => crdt_up_cnt_pd,
        CRDT_UP_CNT_NPD     => crdt_up_cnt_npd,
        CRDT_UP_CNT_CPLD    => crdt_up_cnt_cpld,

        CRDT_DOWN_INIT_DONE => crdt_down_init_done,
        CRDT_DOWN_UPDATE    => crdt_down_update,
        CRDT_DOWN_CNT_PH    => crdt_down_cnt_ph,
        CRDT_DOWN_CNT_NPH   => crdt_down_cnt_nph,
        CRDT_DOWN_CNT_CPLH  => crdt_down_cnt_cplh,
        CRDT_DOWN_CNT_PD    => crdt_down_cnt_pd,
        CRDT_DOWN_CNT_NPD   => crdt_down_cnt_npd,
        CRDT_DOWN_CNT_CPLD  => crdt_down_cnt_cpld,

        AVST_DOWN_DATA      => pcie_avst_down_data,
        AVST_DOWN_HDR       => pcie_avst_down_hdr,
        AVST_DOWN_PREFIX    => pcie_avst_down_prefix,
        AVST_DOWN_BAR_RANGE => pcie_avst_down_bar_range,
		AVST_DOWN_SOP       => pcie_avst_down_sop,
		AVST_DOWN_EOP       => pcie_avst_down_eop,
        AVST_DOWN_EMPTY     => pcie_avst_down_empty,
        AVST_DOWN_VALID     => pcie_avst_down_valid,
		AVST_DOWN_READY     => pcie_avst_down_ready,

        AVST_UP_DATA        => pcie_avst_up_data,
        AVST_UP_HDR         => pcie_avst_up_hdr,
        AVST_UP_PREFIX      => pcie_avst_up_prefix,
        AVST_UP_SOP         => pcie_avst_up_sop,
        AVST_UP_EOP         => pcie_avst_up_eop, 
        AVST_UP_ERROR       => pcie_avst_up_error, 
        AVST_UP_VALID       => pcie_avst_up_valid,
        AVST_UP_READY       => pcie_avst_up_ready,

        CQ_AXI_DATA         => pcie_cq_axi_data,
        CQ_AXI_USER         => pcie_cq_axi_user,
        CQ_AXI_LAST         => pcie_cq_axi_last,
        CQ_AXI_KEEP         => pcie_cq_axi_keep,
        CQ_AXI_VALID        => pcie_cq_axi_valid,
        CQ_AXI_READY        => pcie_cq_axi_ready,

        CC_AXI_DATA         => pcie_cc_axi_data,
        CC_AXI_USER         => pcie_cc_axi_user,
        CC_AXI_LAST         => pcie_cc_axi_last,
        CC_AXI_KEEP         => pcie_cc_axi_keep,
        CC_AXI_VALID        => pcie_cc_axi_valid,
        CC_AXI_READY        => pcie_cc_axi_ready,

        RQ_AXI_DATA         => pcie_rq_axi_data,
        RQ_AXI_USER         => pcie_rq_axi_user,
        RQ_AXI_LAST         => pcie_rq_axi_last,
        RQ_AXI_KEEP         => pcie_rq_axi_keep,
        RQ_AXI_VALID        => pcie_rq_axi_valid,
        RQ_AXI_READY        => pcie_rq_axi_ready,

        RC_AXI_DATA         => pcie_rc_axi_data,
        RC_AXI_USER         => pcie_rc_axi_user,
        RC_AXI_LAST         => pcie_rc_axi_last,
        RC_AXI_KEEP         => pcie_rc_axi_keep,
        RC_AXI_VALID        => pcie_rc_axi_valid,
        RC_AXI_READY        => pcie_rc_axi_ready,

        TAG_ASSIGN          => pcie_tag_assign,
        TAG_ASSIGN_VLD      => pcie_tag_assign_vld
    );

    PCIE_USER_CLK <= pcie_clk;
    pcie_user_reset_g: for i in 0 to PCIE_ENDPOINTS-1 generate
        PCIE_USER_RESET(i) <= pcie_reset(i)(0);
    end generate;

    PCIE_MPS            <= pcie_cfg_mps;
    PCIE_MRRS           <= pcie_cfg_mrrs;
    PCIE_EXT_TAG_EN     <= pcie_cfg_ext_tag_en;
    PCIE_10B_TAG_REQ_EN <= pcie_cfg_10b_tag_req_en;
    PCIE_RCB_SIZE       <= pcie_cfg_rcb_size;

    -- =========================================================================
    --  PCIE CONTROLLERS
    -- =========================================================================

    pcie_ctrl_g: for i in 0 to PCIE_ENDPOINTS-1 generate
        pcie_ctrl_i : entity work.PCIE_CTRL
        generic map (
            AXI_DATA_WIDTH       => AXI_DATA_WIDTH,
            AXI_CQUSER_WIDTH     => AXI_CQUSER_WIDTH,
            AXI_CCUSER_WIDTH     => AXI_CCUSER_WIDTH,
            AXI_RQUSER_WIDTH     => AXI_RQUSER_WIDTH,
            AXI_RCUSER_WIDTH     => AXI_RCUSER_WIDTH,

            BAR0_BASE_ADDR       => BAR0_BASE_ADDR,
            BAR1_BASE_ADDR       => BAR1_BASE_ADDR,
            BAR2_BASE_ADDR       => BAR2_BASE_ADDR,
            BAR3_BASE_ADDR       => BAR3_BASE_ADDR,
            BAR4_BASE_ADDR       => BAR4_BASE_ADDR,
            BAR5_BASE_ADDR       => BAR5_BASE_ADDR,
            EXP_ROM_BASE_ADDR    => EXP_ROM_BASE_ADDR,

            DMA_PORTS            => DMA_PORTS_PER_EP,
    
            MVB_UP_ITEMS         => PCIE_MFB_REGIONS,
            DMA_MVB_UP_ITEMS     => MVB_UP_ITEMS,
            MVB_UP_ITEM_WIDTH    => DMA_UPHDR_WIDTH,
            MFB_UP_REGIONS       => PCIE_MFB_REGIONS,
            DMA_MFB_UP_REGIONS   => MFB_UP_REGIONS,
            MFB_UP_REG_SIZE      => MFB_UP_REG_SIZE,
            MFB_UP_BLOCK_SIZE    => MFB_UP_BLOCK_SIZE,
            MFB_UP_ITEM_WIDTH    => MFB_UP_ITEM_WIDTH,

            MVB_DOWN_ITEMS       => PCIE_MFB_REGIONS,
            DMA_MVB_DOWN_ITEMS   => MVB_DOWN_ITEMS,
            MVB_DOWN_ITEM_WIDTH  => DMA_DOWNHDR_WIDTH,
            MFB_DOWN_REGIONS     => PCIE_MFB_REGIONS,
            DMA_MFB_DOWN_REGIONS => MFB_DOWN_REGIONS,
            MFB_DOWN_REG_SIZE    => MFB_DOWN_REG_SIZE,
            MFB_DOWN_BLOCK_SIZE  => MFB_DOWN_BLOCK_SIZE,
            MFB_DOWN_ITEM_WIDTH  => MFB_DOWN_ITEM_WIDTH,

            MTC_FIFO_ITEMS      => MTC_FIFO_ITEMS,
            RESET_WIDTH         => RESET_WIDTH,

            ENDPOINT_TYPE       => ENDPOINT_TYPE,
            ENABLE_MI           => true,
            DEVICE              => DEVICE
        )
        port map (
            PCIE_CLK            => pcie_clk(i),
            PCIE_RESET          => pcie_reset(i),

            DMA_CLK             => DMA_CLK,
            DMA_RESET           => DMA_RESET,

            MI_CLK              => MI_CLK,
            MI_RESET            => MI_RESET,

            CTL_MAX_PAYLOAD     => pcie_cfg_mps(i),
            CTL_BAR_APERTURE    => std_logic_vector(to_unsigned(BAR_APERTURE,6)),
            CTL_RCB_SIZE        => pcie_cfg_rcb_size(i),

            CRDT_UP_INIT_DONE   => crdt_up_init_done(i),
            CRDT_UP_UPDATE      => crdt_up_update(i),
            CRDT_UP_CNT_PH      => crdt_up_cnt_ph(i),
            CRDT_UP_CNT_NPH     => crdt_up_cnt_nph(i),
            CRDT_UP_CNT_CPLH    => crdt_up_cnt_cplh(i),
            CRDT_UP_CNT_PD      => crdt_up_cnt_pd(i),
            CRDT_UP_CNT_NPD     => crdt_up_cnt_npd(i),
            CRDT_UP_CNT_CPLD    => crdt_up_cnt_cpld(i),

            CRDT_DOWN_INIT_DONE => crdt_down_init_done(i),
            CRDT_DOWN_UPDATE    => crdt_down_update(i),
            CRDT_DOWN_CNT_PH    => crdt_down_cnt_ph(i),
            CRDT_DOWN_CNT_NPH   => crdt_down_cnt_nph(i),
            CRDT_DOWN_CNT_CPLH  => crdt_down_cnt_cplh(i),
            CRDT_DOWN_CNT_PD    => crdt_down_cnt_pd(i),
            CRDT_DOWN_CNT_NPD   => crdt_down_cnt_npd(i),
            CRDT_DOWN_CNT_CPLD  => crdt_down_cnt_cpld(i),

            AVST_DOWN_DATA      => pcie_avst_down_data(i),
            AVST_DOWN_HDR       => pcie_avst_down_hdr(i),
            AVST_DOWN_PREFIX    => pcie_avst_down_prefix(i),
            AVST_DOWN_BAR_RANGE => pcie_avst_down_bar_range(i),
            AVST_DOWN_SOP       => pcie_avst_down_sop(i),
            AVST_DOWN_EOP       => pcie_avst_down_eop(i),
            AVST_DOWN_EMPTY     => pcie_avst_down_empty(i),
            AVST_DOWN_VALID     => pcie_avst_down_valid(i),
            AVST_DOWN_READY     => pcie_avst_down_ready(i),

            AVST_UP_DATA        => pcie_avst_up_data(i),
            AVST_UP_HDR         => pcie_avst_up_hdr(i),
            AVST_UP_PREFIX      => pcie_avst_up_prefix(i),
            AVST_UP_SOP         => pcie_avst_up_sop(i),
            AVST_UP_EOP         => pcie_avst_up_eop(i), 
            AVST_UP_ERROR       => pcie_avst_up_error(i), 
            AVST_UP_VALID       => pcie_avst_up_valid(i),
            AVST_UP_READY       => pcie_avst_up_ready(i),

            CQ_AXI_DATA         => pcie_cq_axi_data(i),
            CQ_AXI_USER         => pcie_cq_axi_user(i),
            CQ_AXI_LAST         => pcie_cq_axi_last(i),
            CQ_AXI_KEEP         => pcie_cq_axi_keep(i),
            CQ_AXI_VALID        => pcie_cq_axi_valid(i),
            CQ_AXI_READY        => pcie_cq_axi_ready(i),
    
            CC_AXI_DATA         => pcie_cc_axi_data(i),
            CC_AXI_USER         => pcie_cc_axi_user(i),
            CC_AXI_LAST         => pcie_cc_axi_last(i),
            CC_AXI_KEEP         => pcie_cc_axi_keep(i),
            CC_AXI_VALID        => pcie_cc_axi_valid(i),
            CC_AXI_READY        => pcie_cc_axi_ready(i),

            RQ_AXI_DATA         => pcie_rq_axi_data(i),
            RQ_AXI_USER         => pcie_rq_axi_user(i),
            RQ_AXI_LAST         => pcie_rq_axi_last(i),
            RQ_AXI_KEEP         => pcie_rq_axi_keep(i),
            RQ_AXI_VALID        => pcie_rq_axi_valid(i),
            RQ_AXI_READY        => pcie_rq_axi_ready(i),

            RC_AXI_DATA         => pcie_rc_axi_data(i),
            RC_AXI_USER         => pcie_rc_axi_user(i),
            RC_AXI_LAST         => pcie_rc_axi_last(i),
            RC_AXI_KEEP         => pcie_rc_axi_keep(i),
            RC_AXI_VALID        => pcie_rc_axi_valid(i),
            RC_AXI_READY        => pcie_rc_axi_ready(i),

            TAG_ASSIGN          => pcie_tag_assign(i),
            TAG_ASSIGN_VLD      => pcie_tag_assign_vld(i),

            UP_MVB_DATA         => UP_MVB_DATA((i+1)*DMA_PORTS_PER_EP-1 downto i*DMA_PORTS_PER_EP),
            UP_MVB_VLD          => UP_MVB_VLD((i+1)*DMA_PORTS_PER_EP-1 downto i*DMA_PORTS_PER_EP),
            UP_MVB_SRC_RDY      => UP_MVB_SRC_RDY((i+1)*DMA_PORTS_PER_EP-1 downto i*DMA_PORTS_PER_EP),
            UP_MVB_DST_RDY      => UP_MVB_DST_RDY((i+1)*DMA_PORTS_PER_EP-1 downto i*DMA_PORTS_PER_EP),
            UP_MFB_DATA         => UP_MFB_DATA((i+1)*DMA_PORTS_PER_EP-1 downto i*DMA_PORTS_PER_EP),
            UP_MFB_SOF          => UP_MFB_SOF((i+1)*DMA_PORTS_PER_EP-1 downto i*DMA_PORTS_PER_EP),
            UP_MFB_EOF          => UP_MFB_EOF((i+1)*DMA_PORTS_PER_EP-1 downto i*DMA_PORTS_PER_EP),
            UP_MFB_SOF_POS      => UP_MFB_SOF_POS((i+1)*DMA_PORTS_PER_EP-1 downto i*DMA_PORTS_PER_EP),
            UP_MFB_EOF_POS      => UP_MFB_EOF_POS((i+1)*DMA_PORTS_PER_EP-1 downto i*DMA_PORTS_PER_EP),
            UP_MFB_SRC_RDY      => UP_MFB_SRC_RDY((i+1)*DMA_PORTS_PER_EP-1 downto i*DMA_PORTS_PER_EP),
            UP_MFB_DST_RDY      => UP_MFB_DST_RDY((i+1)*DMA_PORTS_PER_EP-1 downto i*DMA_PORTS_PER_EP),
            DOWN_MVB_DATA       => DOWN_MVB_DATA((i+1)*DMA_PORTS_PER_EP-1 downto i*DMA_PORTS_PER_EP),
            DOWN_MVB_VLD        => DOWN_MVB_VLD((i+1)*DMA_PORTS_PER_EP-1 downto i*DMA_PORTS_PER_EP),
            DOWN_MVB_SRC_RDY    => DOWN_MVB_SRC_RDY((i+1)*DMA_PORTS_PER_EP-1 downto i*DMA_PORTS_PER_EP),
            DOWN_MVB_DST_RDY    => DOWN_MVB_DST_RDY((i+1)*DMA_PORTS_PER_EP-1 downto i*DMA_PORTS_PER_EP),
            DOWN_MFB_DATA       => DOWN_MFB_DATA((i+1)*DMA_PORTS_PER_EP-1 downto i*DMA_PORTS_PER_EP),
            DOWN_MFB_SOF        => DOWN_MFB_SOF((i+1)*DMA_PORTS_PER_EP-1 downto i*DMA_PORTS_PER_EP),
            DOWN_MFB_EOF        => DOWN_MFB_EOF((i+1)*DMA_PORTS_PER_EP-1 downto i*DMA_PORTS_PER_EP),
            DOWN_MFB_SOF_POS    => DOWN_MFB_SOF_POS((i+1)*DMA_PORTS_PER_EP-1 downto i*DMA_PORTS_PER_EP),
            DOWN_MFB_EOF_POS    => DOWN_MFB_EOF_POS((i+1)*DMA_PORTS_PER_EP-1 downto i*DMA_PORTS_PER_EP),
            DOWN_MFB_SRC_RDY    => DOWN_MFB_SRC_RDY((i+1)*DMA_PORTS_PER_EP-1 downto i*DMA_PORTS_PER_EP),
            DOWN_MFB_DST_RDY    => DOWN_MFB_DST_RDY((i+1)*DMA_PORTS_PER_EP-1 downto i*DMA_PORTS_PER_EP),

            MI_DWR              => MI_DWR (i),
            MI_ADDR             => MI_ADDR(i),
            MI_BE               => MI_BE  (i),
            MI_RD               => MI_RD  (i),
            MI_WR               => MI_WR  (i),
            MI_DRD              => MI_DRD (i),
            MI_ARDY             => MI_ARDY(i),
            MI_DRDY             => MI_DRDY(i)
        );
    end generate;

end architecture;
