-- network_mod_ent.vhd:
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


entity NETWORK_MOD is
generic(
    -- =====================================================================
    -- Network ports configuration:
    -- =====================================================================    
    ETH_PORTS         : natural := 2; -- max 2 (MI address space limit)
    -- Speed per Ethernet port.
    -- Options: 400G1            card: 400, 200, 100, 50, 40, 25, 10;
    --          DK-DEV-AGI027RES card: 400, 200, 100, 50, 40, 25, 10;
    --          DK-DEV-1SDX-P    card: 100, 25, 10.
    ETH_PORT_SPEED    : integer_vector(ETH_PORTS-1 downto 0) := (others => 25);
    -- Number of channels per Ethernet port.
    -- Options: 400G1            card: 1, 2, 4, 8;
    --          DK-DEV-AGI027RES card: 1, 2, 4, 8;
    --          DK-DEV-1SDX-P    card: 1, 4.
    ETH_PORT_CHAN     : integer_vector(ETH_PORTS-1 downto 0) := (others => 4);
    -- Number of serial lanes.
    -- Options: 400G1            card: 8;
    --          DK-DEV-AGI027RES card: 8;
    --          DK-DEV-1SDX-P    card: 4.
    LANES             : natural := 4;
    QSFP_I2C_PORTS    : natural := 1; -- max 2

    -- =====================================================================
    -- MFB configuration:
    -- =====================================================================
    -- Recommended MFB parameters:
    --     400G1            card: 4,8,8,8.
    --     DK-DEV-AGI027RES card: 4,8,8,8.
    --     DK-DEV-1SDX-P    card: 1,8,8,8.
    REGIONS           : natural := 1;
    REGION_SIZE       : natural := 8;
    BLOCK_SIZE        : natural := 8;
    ITEM_WIDTH        : natural := 8;

    -- =====================================================================
    -- MI configuration:
    -- =====================================================================
    MI_DATA_WIDTH     : natural := 32;
    MI_ADDR_WIDTH     : natural := 32;
    
    MI_DATA_WIDTH_PHY : natural := 32;
    MI_ADDR_WIDTH_PHY : natural := 32;

    -- =====================================================================
    -- Other configuration:
    -- =====================================================================
    -- Ethernet lanes polarity
    LANE_RX_POLARITY  : std_logic_vector(ETH_PORTS*LANES-1 downto 0) := (others => '0');
    LANE_TX_POLARITY  : std_logic_vector(ETH_PORTS*LANES-1 downto 0) := (others => '0');
    -- Number of user resets.
    RESET_WIDTH       : natural := 8;
    -- Select correct FPGA device.
    DEVICE            : string := "STRATIX10"; -- AGILEX, STRATIX10, ULTRASCALE
    BOARD             : string := "DK-DEV-1SDX-P" -- 400G1, DK-DEV-AGI027RES, DK-DEV-1SDX-P
);
port(
    -- =====================================================================
    -- CLOCK AND RESET
    -- =====================================================================
    CLK_USER        : in  std_logic;
    CLK_ETH         : out std_logic_vector(ETH_PORTS-1 downto 0);

    RESET_USER      : in  std_logic_vector(RESET_WIDTH-1 downto 0);
    RESET_ETH       : in  std_logic_vector(ETH_PORTS-1 downto 0);

    -- =====================================================================
    -- QSFP INTERFACES
    -- =====================================================================
    QSFP_REFCLK_P   : in  std_logic_vector(ETH_PORTS-1 downto 0);
    QSFP_REFCLK_N   : in  std_logic_vector(ETH_PORTS-1 downto 0);
    QSFP_RX_P       : in  std_logic_vector(ETH_PORTS*LANES-1 downto 0); -- QSFP XCVR RX Data
    QSFP_RX_N       : in  std_logic_vector(ETH_PORTS*LANES-1 downto 0); -- QSFP XCVR RX Data
    QSFP_TX_P       : out std_logic_vector(ETH_PORTS*LANES-1 downto 0); -- QSFP XCVR TX Data
    QSFP_TX_N       : out std_logic_vector(ETH_PORTS*LANES-1 downto 0); -- QSFP XCVR TX Data
    -- =====================================================================
    -- QSFP Control
    -- =====================================================================        
    QSFP_I2C_SCL    : inout std_logic_vector(QSFP_I2C_PORTS-1 downto 0);
    QSFP_I2C_SDA    : inout std_logic_vector(QSFP_I2C_PORTS-1 downto 0);
    QSFP_MODSEL_N   : out   std_logic_vector(ETH_PORTS-1 downto 0);
    QSFP_LPMODE     : out   std_logic_vector(ETH_PORTS-1 downto 0);
    QSFP_RESET_N    : out   std_logic_vector(ETH_PORTS-1 downto 0);
    QSFP_MODPRS_N   : in    std_logic_vector(ETH_PORTS-1 downto 0) := (others => '0');
    QSFP_INT_N      : in    std_logic_vector(ETH_PORTS-1 downto 0) := (others => '1');

    -- =====================================================================
    -- Link control/status - runs on CLK_ETH
    -- =====================================================================        
    -- REPEATER_CTRL   : in  std_logic_vector(ETH_PORTS*2-1 downto 0);
    -- PORT_ENABLED    : out std_logic_vector(ETH_PORTS-1 downto 0);
    ACTIVITY_RX     : out std_logic_vector(ETH_PORTS*ETH_PORT_CHAN(0)-1 downto 0);
    ACTIVITY_TX     : out std_logic_vector(ETH_PORTS*ETH_PORT_CHAN(0)-1 downto 0);
    RX_LINK_UP      : out std_logic_vector(ETH_PORTS*ETH_PORT_CHAN(0)-1 downto 0);
    TX_LINK_UP      : out std_logic_vector(ETH_PORTS*ETH_PORT_CHAN(0)-1 downto 0);

    -- =====================================================================
    -- RX interface (Packets for transmit to Ethernet)
    -- =====================================================================
    RX_MFB_DATA     : in  std_logic_vector(ETH_PORTS*REGIONS*REGION_SIZE*BLOCK_SIZE*ITEM_WIDTH-1 downto 0);
    RX_MFB_HDR      : in  std_logic_vector(ETH_PORTS*REGIONS*ETH_TX_HDR_WIDTH-1 downto 0); -- valid with SOF
    RX_MFB_SOF      : in  std_logic_vector(ETH_PORTS*REGIONS-1 downto 0);
    RX_MFB_EOF      : in  std_logic_vector(ETH_PORTS*REGIONS-1 downto 0);
    RX_MFB_SOF_POS  : in  std_logic_vector(ETH_PORTS*REGIONS*max(1,log2(REGION_SIZE))-1 downto 0);
    RX_MFB_EOF_POS  : in  std_logic_vector(ETH_PORTS*REGIONS*max(1,log2(REGION_SIZE*BLOCK_SIZE))-1 downto 0);
    RX_MFB_SRC_RDY  : in  std_logic_vector(ETH_PORTS-1 downto 0);
    RX_MFB_DST_RDY  : out std_logic_vector(ETH_PORTS-1 downto 0);

    -- =====================================================================
    -- TX interface (Packets received from Ethernet)
    -- =====================================================================
    TX_MFB_DATA     : out std_logic_vector(ETH_PORTS*REGIONS*REGION_SIZE*BLOCK_SIZE*ITEM_WIDTH-1 downto 0);
    TX_MFB_SOF      : out std_logic_vector(ETH_PORTS*REGIONS-1 downto 0);
    TX_MFB_EOF      : out std_logic_vector(ETH_PORTS*REGIONS-1 downto 0);
    TX_MFB_SOF_POS  : out std_logic_vector(ETH_PORTS*REGIONS*max(1,log2(REGION_SIZE))-1 downto 0);
    TX_MFB_EOF_POS  : out std_logic_vector(ETH_PORTS*REGIONS*max(1,log2(REGION_SIZE*BLOCK_SIZE))-1 downto 0);
    TX_MFB_SRC_RDY  : out std_logic_vector(ETH_PORTS-1 downto 0);
    TX_MFB_DST_RDY  : in  std_logic_vector(ETH_PORTS-1 downto 0);

    TX_MVB_DATA     : out std_logic_vector(ETH_PORTS*REGIONS*ETH_RX_HDR_WIDTH-1 downto 0);
    TX_MVB_VLD      : out std_logic_vector(ETH_PORTS*REGIONS-1 downto 0);
    TX_MVB_SRC_RDY  : out std_logic_vector(ETH_PORTS-1 downto 0);
    TX_MVB_DST_RDY  : in  std_logic_vector(ETH_PORTS-1 downto 0);

    -- =====================================================================
    -- MI interface - ETH MAC
    -- =====================================================================
    MI_CLK          : in  std_logic;
    MI_RESET        : in  std_logic;
    MI_DWR          : in  std_logic_vector(MI_DATA_WIDTH-1 downto 0);
    MI_ADDR         : in  std_logic_vector(MI_ADDR_WIDTH-1 downto 0);
    MI_RD           : in  std_logic;
    MI_WR           : in  std_logic;
    MI_BE           : in  std_logic_vector(MI_DATA_WIDTH/8-1 downto 0);
    MI_DRD          : out std_logic_vector(MI_DATA_WIDTH-1 downto 0);
    MI_ARDY         : out std_logic;
    MI_DRDY         : out std_logic;

    -- =====================================================================
    -- MI interface - ETH PCS/PMA
    -- =====================================================================
    MI_CLK_PHY      : in  std_logic;
    MI_RESET_PHY    : in  std_logic;
    MI_DWR_PHY      : in  std_logic_vector(MI_DATA_WIDTH-1 downto 0);
    MI_ADDR_PHY     : in  std_logic_vector(MI_ADDR_WIDTH-1 downto 0);
    MI_RD_PHY       : in  std_logic;
    MI_WR_PHY       : in  std_logic;
    MI_BE_PHY       : in  std_logic_vector(MI_DATA_WIDTH/8-1 downto 0);
    MI_DRD_PHY      : out std_logic_vector(MI_DATA_WIDTH-1 downto 0);
    MI_ARDY_PHY     : out std_logic;
    MI_DRDY_PHY     : out std_logic;

    -- =====================================================================
    -- MI interface - ETH PMD (QSFP)
    -- =====================================================================
    MI_CLK_PMD      : in  std_logic;
    MI_RESET_PMD    : in  std_logic;
    MI_DWR_PMD      : in  std_logic_vector(MI_DATA_WIDTH-1 downto 0);
    MI_ADDR_PMD     : in  std_logic_vector(MI_ADDR_WIDTH-1 downto 0);
    MI_RD_PMD       : in  std_logic;
    MI_WR_PMD       : in  std_logic;
    MI_BE_PMD       : in  std_logic_vector(MI_DATA_WIDTH/8-1 downto 0);
    MI_DRD_PMD      : out std_logic_vector(MI_DATA_WIDTH-1 downto 0);
    MI_ARDY_PMD     : out std_logic;
    MI_DRDY_PMD     : out std_logic;

    -- =====================================================================
    -- TSU interface
    -- =====================================================================
    TSU_CLK         : out std_logic;
    TSU_RST         : out std_logic;
    TSU_TS_NS       : in  std_logic_vector(64-1 downto 0);
    TSU_TS_DV       : in  std_logic
);
end entity;
