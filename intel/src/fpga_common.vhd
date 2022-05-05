-- fpga_common.vhd: Common top level architecture for boards with S10
-- Copyright (C) 2019 CESNET z. s. p. o.
-- Author(s): Jakub Cabal <cabal@cesnet.cz>
--
-- SPDX-License-Identifier: BSD-3-Clause

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.fixed_pkg.all;

use work.combo_const.all;
use work.combo_user_const.all;

use work.math_pack.all;
use work.type_pack.all;
use work.dma_bus_pack.all;
use work.eth_hdr_pack.all;
use work.mi_addr_space_pack.all;

entity FPGA_COMMON is
generic (
    -- =========================================================================
    --  Board static constants
    -- =========================================================================
    -- System clock frequency in MHz
    SYSCLK_FREQ             : natural := 100;
    -- Number of PCIe connectors present on board
    PCIE_CONS               : integer := 1;
    -- Number of PCIe lanes per connector
    PCIE_LANES              : integer := 16;
    -- Number of PCIe clocks per connector (useful for bifurcation)
    PCIE_CLKS               : integer := 1;
    -- PCI device identification (not applicable when using XCI PCIe cores)
    PCI_VENDOR_ID           : std_logic_vector(15 downto 0) := X"18EC";
    PCI_DEVICE_ID           : std_logic_vector(15 downto 0) := X"C400";
    PCI_SUBVENDOR_ID        : std_logic_vector(15 downto 0) := X"0000";
    PCI_SUBDEVICE_ID        : std_logic_vector(15 downto 0) := X"0000";
    -- Number of Ethernet ports present on board
    ETH_PORTS               : integer := 1;
    -- Number of lanes per Ethernet port
    ETH_LANES               : integer := 8;
    -- Logical indexes and polarities of Ethernet lanes
    ETH_LANE_MAP            : integer_vector(ETH_PORTS*ETH_LANES-1 downto 0) := (others => 0);
    ETH_LANE_RXPOLARITY     : std_logic_vector(ETH_PORTS*ETH_LANES-1 downto 0) := (others => '0');
    ETH_LANE_TXPOLARITY     : std_logic_vector(ETH_PORTS*ETH_LANES-1 downto 0) := (others => '0');
    ETH_PORT_LEDS           : integer := 2;

    QSFP_PORTS              : integer := 2;
    QSFP_I2C_PORTS          : integer := 1;

    MEM_PORTS               : integer := 2;
    MEM_ADDR_WIDTH          : integer := 27;
    MEM_DATA_WIDTH          : integer := 512;
    MEM_BURST_WIDTH         : integer := 7;
    AMM_FREQ_KHZ            : integer := 266660;
    
    STATUS_LEDS             : integer := 2;
    MISC_IN_WIDTH           : integer := 0;
    MISC_OUT_WIDTH          : integer := 0;
    SYSCLK_PERIOD           : real := 8.0;

    USER_GENERIC0           : integer := 0;
    USER_GENERIC1           : integer := 0;
    USER_GENERIC2           : integer := 0;
    USER_GENERIC3           : integer := 0;

    DEVICE                  : string := "STRATIX10";
    BOARD                   : string := "400G1";

    -- =========================================================================
    --  User configurable generics
    -- =========================================================================
    -- Number of instantiated PCIe endpoints
    PCIE_ENDPOINTS          : integer := 1;
    -- Connected PCIe endpoint type ("H_TILE" or "P_TILE")
    PCIE_ENDPOINT_TYPE      : string  := "P_TILE";
    -- Connected PCIe endpoint mode: 0 = 1x16 lanes, 1 = 2x8 lanes
    PCIE_ENDPOINT_MODE      : natural := 0;
    -- Speed for all Ethernet ports
    ETH_PORT_SPEED          : integer_vector(ETH_PORTS-1 downto 0) := (others => 0);
    -- Number of channels for all Ethernet ports
    ETH_PORT_CHAN           : integer_vector(ETH_PORTS-1 downto 0) := (others => 0);
    -- Number of instantiated DMA modules
    DMA_MODULES             : integer := 1;
    -- Total number of DMA endpoints (one or two DMA endpoints per PCIe endpoint)
    DMA_ENDPOINTS           : integer := 1;
    -- Number of DMA channels per DMA module
    DMA_RX_CHANNELS         : integer := 4;
    DMA_TX_CHANNELS         : integer := 4;
    -- DMA debug parameters
    DMA_400G_DEMO           : boolean := false;
    DMA_GEN_LOOP_EN         : boolean := false
);
port (
    SYSCLK                  : in    std_logic;
    SYSRST                  : in    std_logic;

    -- PCIe interface
    PCIE_SYSCLK_P           : in    std_logic_vector(PCIE_CONS*PCIE_CLKS-1 downto 0);
    PCIE_SYSCLK_N           : in    std_logic_vector(PCIE_CONS*PCIE_CLKS-1 downto 0);
    PCIE_SYSRST_N           : in    std_logic_vector(PCIE_CONS-1 downto 0);
    PCIE_RX_P               : in    std_logic_vector(PCIE_CONS*PCIE_LANES-1 downto 0);
    PCIE_RX_N               : in    std_logic_vector(PCIE_CONS*PCIE_LANES-1 downto 0);
    PCIE_TX_P               : out   std_logic_vector(PCIE_CONS*PCIE_LANES-1 downto 0);
    PCIE_TX_N               : out   std_logic_vector(PCIE_CONS*PCIE_LANES-1 downto 0);

    -- ETH port interface
    ETH_REFCLK_P            : in    std_logic_vector(ETH_PORTS-1 downto 0);
    ETH_REFCLK_N            : in    std_logic_vector(ETH_PORTS-1 downto 0);
    ETH_RX_P                : in    std_logic_vector(ETH_PORTS*ETH_LANES-1 downto 0);
    ETH_RX_N                : in    std_logic_vector(ETH_PORTS*ETH_LANES-1 downto 0);
    ETH_TX_P                : out   std_logic_vector(ETH_PORTS*ETH_LANES-1 downto 0);
    ETH_TX_N                : out   std_logic_vector(ETH_PORTS*ETH_LANES-1 downto 0);

    ETH_LED_G               : out   std_logic_vector(ETH_PORTS*ETH_PORT_LEDS-1 downto 0);
    ETH_LED_R               : out   std_logic_vector(ETH_PORTS*ETH_PORT_LEDS-1 downto 0);

    -- QSFP management interface
    QSFP_I2C_SCL            : inout std_logic_vector(QSFP_I2C_PORTS-1 downto 0);
    QSFP_I2C_SDA            : inout std_logic_vector(QSFP_I2C_PORTS-1 downto 0);
    QSFP_MODSEL_N           : out   std_logic_vector(QSFP_PORTS-1 downto 0);
    QSFP_LPMODE             : out   std_logic_vector(QSFP_PORTS-1 downto 0);
    QSFP_RESET_N            : out   std_logic_vector(QSFP_PORTS-1 downto 0);
    QSFP_MODPRS_N           : in    std_logic_vector(QSFP_PORTS-1 downto 0);
    QSFP_INT_N              : in    std_logic_vector(QSFP_PORTS-1 downto 0);

    -- External memory interfaces (clocked at MEM_CLK)
    MEM_CLK                 : in  std_logic_vector(MEM_PORTS-1 downto 0) := (others => '0');
    MEM_RST                 : in  std_logic_vector(MEM_PORTS-1 downto 0) := (others => '0');

    MEM_AVMM_READY          : in  std_logic_vector(MEM_PORTS-1 downto 0) := (others => '0');
    MEM_AVMM_READ           : out std_logic_vector(MEM_PORTS-1 downto 0);
    MEM_AVMM_WRITE          : out std_logic_vector(MEM_PORTS-1 downto 0);
    MEM_AVMM_ADDRESS        : out slv_array_t(MEM_PORTS-1 downto 0)(MEM_ADDR_WIDTH-1 downto 0);
    MEM_AVMM_BURSTCOUNT     : out slv_array_t(MEM_PORTS-1 downto 0)(MEM_BURST_WIDTH-1 downto 0);
    MEM_AVMM_WRITEDATA      : out slv_array_t(MEM_PORTS-1 downto 0)(MEM_DATA_WIDTH-1 downto 0);
    MEM_AVMM_READDATA       : in  slv_array_t(MEM_PORTS-1 downto 0)(MEM_DATA_WIDTH-1 downto 0) := (others => (others => '0'));
    MEM_AVMM_READDATAVALID  : in  std_logic_vector(MEM_PORTS-1 downto 0) := (others => '0');

    EMIF_RST_REQ            : out std_logic_vector(MEM_PORTS-1 downto 0);
    EMIF_RST_DONE           : in  std_logic_vector(MEM_PORTS-1 downto 0) := (others => '0');
    EMIF_ECC_USR_INT        : in  std_logic_vector(MEM_PORTS-1 downto 0) := (others => '0');
    EMIF_CAL_SUCCESS        : in  std_logic_vector(MEM_PORTS-1 downto 0) := (others => '0');
    EMIF_CAL_FAIL           : in  std_logic_vector(MEM_PORTS-1 downto 0) := (others => '0');

    STATUS_LED_G            : out   std_logic_vector(STATUS_LEDS-1 downto 0);
    STATUS_LED_R            : out   std_logic_vector(STATUS_LEDS-1 downto 0);

    -- Misc interface, board specific
    MISC_IN                 : in    std_logic_vector(MISC_IN_WIDTH-1 downto 0) := (others => '0');
    MISC_OUT                : out   std_logic_vector(MISC_OUT_WIDTH-1 downto 0)
);
end entity;

-- ----------------------------------------------------------------------------
--                        Architecture Declaration
-- ----------------------------------------------------------------------------

architecture FULL of FPGA_COMMON is

    function f_eth_mfb_region return natural is
    begin
        if BOARD = "400G1" or BOARD = "DK-DEV-AGI027RES" then
            return 4;
        else --DK-DEV-1SDX-P
            return 1;
        end if;
    end function;

    constant CLK_COUNT      : natural := 4+ETH_PORTS;
    constant ETH_CHANNELS   : natural := ETH_PORT_CHAN(0);
    constant ETH_STREAMS    : natural := ETH_PORTS;
    constant ETH_MFB_REGION : natural := f_eth_mfb_region;
    constant DMA_STREAMS    : natural := DMA_MODULES;

    constant PCIE_MPS     : natural := 256;
    constant PCIE_MRRS    : natural := 512;
    constant ETH_PKT_MTU  : natural := 2**12;
    constant RESET_WIDTH  : natural := 10;

    constant MI_DATA_WIDTH      : integer := 32;
    constant MI_ADDR_WIDTH      : integer := 32;

    -- MVB parameters
    constant MVB_ITEMS          : integer := ETH_MFB_REGION;  -- Number of items (headers) in word - TODO
    constant HDR_META_WIDTH     : integer := 12; 
    -- MFB parameters
    constant MFB_REGIONS      : integer := ETH_MFB_REGION;  -- Number of regions in word - TODO
    constant MFB_REGION_SIZE  : integer := 8;  -- Number of blocks in region
    constant MFB_BLOCK_SIZE   : integer := 8;  -- Number of items in block
    constant MFB_ITEM_WIDTH   : integer := 8;  -- Width of one item in bits

    -- DMA MVB UP parameters
    constant DMA_UP_MVB_ITEMS        : integer := 2;  -- Number of items (headers) in word
    constant DMA_UP_MVB_ITEM_WIDTH   : integer := DMA_UPHDR_WIDTH; -- Width of one item (header) in bits
    -- DMA MFB UP parameters
    constant DMA_UP_MFB_REGIONS      : integer := 2;  -- Number of regions in word
    constant DMA_UP_MFB_REGION_SIZE  : integer := 1;  -- Number of blocks in region
    constant DMA_UP_MFB_BLOCK_SIZE   : integer := 8;  -- Number of items in block
    constant DMA_UP_MFB_ITEM_WIDTH   : integer := 32;  -- Width of one item in bits

    -- DMA MVB DOWN parameters
    constant DMA_DOWN_MVB_ITEMS        : integer := 2;  -- Number of items (headers) in word
    constant DMA_DOWN_MVB_ITEM_WIDTH   : integer := DMA_DOWNHDR_WIDTH; -- Width of one item (header) in bits
    -- DMA MFB DOWN parameters
    constant DMA_DOWN_MFB_REGIONS      : integer := 2;  -- Number of regions in word
    constant DMA_DOWN_MFB_REGION_SIZE  : integer := 1;  -- Number of blocks in region
    constant DMA_DOWN_MFB_BLOCK_SIZE   : integer := 8;  -- Number of items in block
    constant DMA_DOWN_MFB_ITEM_WIDTH   : integer := 32;  -- Width of one item in bits

    -- DMA CrossbarX clock selection
    constant DMA_CROX_CLK_SEL    : integer := 0;
    constant DMA_USR_EQ_DMA      : boolean := false;
    constant DMA_CROX_EQ_DMA     : boolean := (DMA_CROX_CLK_SEL=1);
    constant DMA_CROX_DOUBLE_DMA : boolean := (DMA_CROX_CLK_SEL=0);

    signal init_done_n                   : std_logic;
    signal pll_locked                    : std_logic;
    signal global_reset                  : std_logic;
    signal clk_vector                    : std_logic_vector(CLK_COUNT-1 downto 0);
    signal rst_vector                    : std_logic_vector(CLK_COUNT*RESET_WIDTH-1 downto 0);

    signal clk_usr_x1                    : std_logic;
    signal clk_usr_x2                    : std_logic;
    signal clk_usr_x3                    : std_logic;
    signal clk_usr_x4                    : std_logic;

    signal rst_usr_x1                    : std_logic_vector(RESET_WIDTH-1 downto 0);
    signal rst_usr_x2                    : std_logic_vector(RESET_WIDTH-1 downto 0);
    signal rst_usr_x3                    : std_logic_vector(RESET_WIDTH-1 downto 0);
    signal rst_usr_x4                    : std_logic_vector(RESET_WIDTH-1 downto 0);

    signal clk_pci                       : std_logic_vector(PCIE_ENDPOINTS-1 downto 0);
    signal clk_eth_phy                   : std_logic_vector(ETH_PORTS-1 downto 0);
    signal clk_mi                        : std_logic;
    signal clk_dma                       : std_logic;
    signal clk_dma_x2                    : std_logic;
    signal clk_app                       : std_logic;
    
    signal rst_pci                       : std_logic_vector(PCIE_ENDPOINTS-1 downto 0);
    signal rst_eth_phy                   : std_logic_vector(ETH_PORTS-1 downto 0);
    signal rst_mi                        : std_logic_vector(RESET_WIDTH-1 downto 0);
    signal rst_dma                       : std_logic_vector(RESET_WIDTH-1 downto 0);
    signal rst_dma_x2                    : std_logic_vector(RESET_WIDTH-1 downto 0);
    signal rst_app                       : std_logic_vector(RESET_WIDTH-1 downto 0);

    signal pcie_link_up                  : std_logic_vector(PCIE_ENDPOINTS-1 downto 0);
    signal dma_pcie_link_up              : std_logic_vector(PCIE_ENDPOINTS-1 downto 0);
    signal app_pcie_link_up              : std_logic_vector(PCIE_ENDPOINTS-1 downto 0) := (others => '0');

    -- MI32 interface signals
    signal mi_dwr                        : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(31 downto 0);
    signal mi_addr                       : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(31 downto 0);
    signal mi_be                         : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(3 downto 0);
    signal mi_rd                         : std_logic_vector(PCIE_ENDPOINTS-1 downto 0);
    signal mi_wr                         : std_logic_vector(PCIE_ENDPOINTS-1 downto 0);
    signal mi_drd                        : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(31 downto 0);
    signal mi_ardy                       : std_logic_vector(PCIE_ENDPOINTS-1 downto 0);
    signal mi_drdy                       : std_logic_vector(PCIE_ENDPOINTS-1 downto 0);

    -- MI interfaces for individual components (clocked at clk_mi)
    signal mi_adc_dwr                    : slv_array_t     (MI_ADC_PORTS-1 downto 0)(32-1 downto 0);
    signal mi_adc_addr                   : slv_array_t     (MI_ADC_PORTS-1 downto 0)(32-1 downto 0);
    signal mi_adc_be                     : slv_array_t     (MI_ADC_PORTS-1 downto 0)(32/8-1 downto 0);
    signal mi_adc_rd                     : std_logic_vector(MI_ADC_PORTS-1 downto 0);
    signal mi_adc_wr                     : std_logic_vector(MI_ADC_PORTS-1 downto 0);
    signal mi_adc_drd                    : slv_array_t     (MI_ADC_PORTS-1 downto 0)(32-1 downto 0);
    signal mi_adc_ardy                   : std_logic_vector(MI_ADC_PORTS-1 downto 0);
    signal mi_adc_drdy                   : std_logic_vector(MI_ADC_PORTS-1 downto 0);

    signal dma_mi_dwr                    : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(31 downto 0);
    signal dma_mi_addr                   : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(31 downto 0);
    signal dma_mi_be                     : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(3 downto 0);
    signal dma_mi_rd                     : std_logic_vector(PCIE_ENDPOINTS-1 downto 0);
    signal dma_mi_wr                     : std_logic_vector(PCIE_ENDPOINTS-1 downto 0);
    signal dma_mi_drd                    : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(31 downto 0);
    signal dma_mi_ardy                   : std_logic_vector(PCIE_ENDPOINTS-1 downto 0);
    signal dma_mi_drdy                   : std_logic_vector(PCIE_ENDPOINTS-1 downto 0);

    signal dma_up_mvb_data               : slv_array_t(DMA_ENDPOINTS-1 downto 0)(DMA_UP_MVB_ITEMS*DMA_UP_MVB_ITEM_WIDTH-1 downto 0);
    signal dma_up_mvb_vld                : slv_array_t(DMA_ENDPOINTS-1 downto 0)(DMA_UP_MVB_ITEMS-1 downto 0);
    signal dma_up_mvb_src_rdy            : std_logic_vector(DMA_ENDPOINTS-1 downto 0);
    signal dma_up_mvb_dst_rdy            : std_logic_vector(DMA_ENDPOINTS-1 downto 0);

    signal dma_up_mfb_data               : slv_array_t(DMA_ENDPOINTS-1 downto 0)(DMA_UP_MFB_REGIONS*DMA_UP_MFB_REGION_SIZE*DMA_UP_MFB_BLOCK_SIZE*DMA_UP_MFB_ITEM_WIDTH-1 downto 0);
    signal dma_up_mfb_sof                : slv_array_t(DMA_ENDPOINTS-1 downto 0)(DMA_UP_MFB_REGIONS-1 downto 0);
    signal dma_up_mfb_eof                : slv_array_t(DMA_ENDPOINTS-1 downto 0)(DMA_UP_MFB_REGIONS-1 downto 0);
    signal dma_up_mfb_sof_pos            : slv_array_t(DMA_ENDPOINTS-1 downto 0)(DMA_UP_MFB_REGIONS*max(1,log2(DMA_UP_MFB_REGION_SIZE))-1 downto 0);
    signal dma_up_mfb_eof_pos            : slv_array_t(DMA_ENDPOINTS-1 downto 0)(DMA_UP_MFB_REGIONS*max(1,log2(DMA_UP_MFB_REGION_SIZE*DMA_UP_MFB_BLOCK_SIZE))-1 downto 0);
    signal dma_up_mfb_src_rdy            : std_logic_vector(DMA_ENDPOINTS-1 downto 0);
    signal dma_up_mfb_dst_rdy            : std_logic_vector(DMA_ENDPOINTS-1 downto 0);

    signal dma_down_mvb_data             : slv_array_t(DMA_ENDPOINTS-1 downto 0)(DMA_DOWN_MVB_ITEMS*DMA_DOWN_MVB_ITEM_WIDTH-1 downto 0);
    signal dma_down_mvb_vld              : slv_array_t(DMA_ENDPOINTS-1 downto 0)(DMA_DOWN_MVB_ITEMS-1 downto 0);
    signal dma_down_mvb_src_rdy          : std_logic_vector(DMA_ENDPOINTS-1 downto 0);
    signal dma_down_mvb_dst_rdy          : std_logic_vector(DMA_ENDPOINTS-1 downto 0);

    signal dma_down_mfb_data             : slv_array_t(DMA_ENDPOINTS-1 downto 0)(DMA_DOWN_MFB_REGIONS*DMA_DOWN_MFB_REGION_SIZE*DMA_DOWN_MFB_BLOCK_SIZE*DMA_DOWN_MFB_ITEM_WIDTH-1 downto 0);
    signal dma_down_mfb_sof              : slv_array_t(DMA_ENDPOINTS-1 downto 0)(DMA_DOWN_MFB_REGIONS-1 downto 0);
    signal dma_down_mfb_eof              : slv_array_t(DMA_ENDPOINTS-1 downto 0)(DMA_DOWN_MFB_REGIONS-1 downto 0);
    signal dma_down_mfb_sof_pos          : slv_array_t(DMA_ENDPOINTS-1 downto 0)(DMA_DOWN_MFB_REGIONS*max(1,log2(DMA_DOWN_MFB_REGION_SIZE))-1 downto 0);
    signal dma_down_mfb_eof_pos          : slv_array_t(DMA_ENDPOINTS-1 downto 0)(DMA_DOWN_MFB_REGIONS*max(1,log2(DMA_DOWN_MFB_REGION_SIZE*DMA_DOWN_MFB_BLOCK_SIZE))-1 downto 0);
    signal dma_down_mfb_src_rdy          : std_logic_vector(DMA_ENDPOINTS-1 downto 0);
    signal dma_down_mfb_dst_rdy          : std_logic_vector(DMA_ENDPOINTS-1 downto 0);

    signal app_dma_rx_mvb_len            : std_logic_vector(DMA_STREAMS*MVB_ITEMS*log2(ETH_PKT_MTU+1)-1 downto 0);
    signal app_dma_rx_mvb_hdr_meta       : std_logic_vector(DMA_STREAMS*MVB_ITEMS*HDR_META_WIDTH-1 downto 0);
    signal app_dma_rx_mvb_channel        : std_logic_vector(DMA_STREAMS*MVB_ITEMS*log2(DMA_RX_CHANNELS)-1 downto 0);
    signal app_dma_rx_mvb_discard        : std_logic_vector(DMA_STREAMS*MVB_ITEMS-1 downto 0);
    signal app_dma_rx_mvb_vld            : std_logic_vector(DMA_STREAMS*MVB_ITEMS-1 downto 0);
    signal app_dma_rx_mvb_src_rdy        : std_logic_vector(DMA_STREAMS-1 downto 0);
    signal app_dma_rx_mvb_dst_rdy        : std_logic_vector(DMA_STREAMS-1 downto 0);

    signal app_dma_rx_mfb_data           : std_logic_vector(DMA_STREAMS*MFB_REGIONS*MFB_REGION_SIZE*MFB_BLOCK_SIZE*MFB_ITEM_WIDTH-1 downto 0);
    signal app_dma_rx_mfb_sof            : std_logic_vector(DMA_STREAMS*MFB_REGIONS-1 downto 0);
    signal app_dma_rx_mfb_eof            : std_logic_vector(DMA_STREAMS*MFB_REGIONS-1 downto 0);
    signal app_dma_rx_mfb_sof_pos        : std_logic_vector(DMA_STREAMS*MFB_REGIONS*max(1,log2(MFB_REGION_SIZE))-1 downto 0);
    signal app_dma_rx_mfb_eof_pos        : std_logic_vector(DMA_STREAMS*MFB_REGIONS*max(1,log2(MFB_REGION_SIZE*MFB_BLOCK_SIZE))-1 downto 0);
    signal app_dma_rx_mfb_src_rdy        : std_logic_vector(DMA_STREAMS-1 downto 0);
    signal app_dma_rx_mfb_dst_rdy        : std_logic_vector(DMA_STREAMS-1 downto 0);

    signal app_dma_tx_mvb_len            : std_logic_vector(DMA_STREAMS*MVB_ITEMS*log2(ETH_PKT_MTU+1)-1 downto 0);
    signal app_dma_tx_mvb_hdr_meta       : std_logic_vector(DMA_STREAMS*MVB_ITEMS*HDR_META_WIDTH-1 downto 0);
    signal app_dma_tx_mvb_channel        : std_logic_vector(DMA_STREAMS*MVB_ITEMS*log2(DMA_TX_CHANNELS)-1 downto 0);
    signal app_dma_tx_mvb_vld            : std_logic_vector(DMA_STREAMS*MVB_ITEMS-1 downto 0);
    signal app_dma_tx_mvb_src_rdy        : std_logic_vector(DMA_STREAMS-1 downto 0);
    signal app_dma_tx_mvb_dst_rdy        : std_logic_vector(DMA_STREAMS-1 downto 0);

    signal app_dma_tx_mfb_data           : std_logic_vector(DMA_STREAMS*MFB_REGIONS*MFB_REGION_SIZE*MFB_BLOCK_SIZE*MFB_ITEM_WIDTH-1 downto 0);
    signal app_dma_tx_mfb_sof            : std_logic_vector(DMA_STREAMS*MFB_REGIONS-1 downto 0);
    signal app_dma_tx_mfb_eof            : std_logic_vector(DMA_STREAMS*MFB_REGIONS-1 downto 0);
    signal app_dma_tx_mfb_sof_pos        : std_logic_vector(DMA_STREAMS*MFB_REGIONS*max(1,log2(MFB_REGION_SIZE))-1 downto 0);
    signal app_dma_tx_mfb_eof_pos        : std_logic_vector(DMA_STREAMS*MFB_REGIONS*max(1,log2(MFB_REGION_SIZE*MFB_BLOCK_SIZE))-1 downto 0);
    signal app_dma_tx_mfb_src_rdy        : std_logic_vector(DMA_STREAMS-1 downto 0);
    signal app_dma_tx_mfb_dst_rdy        : std_logic_vector(DMA_STREAMS-1 downto 0);

    signal eth_rx_mvb_data               : std_logic_vector(ETH_STREAMS*MVB_ITEMS*ETH_RX_HDR_WIDTH-1 downto 0);
    signal eth_rx_mvb_vld                : std_logic_vector(ETH_STREAMS*MVB_ITEMS-1 downto 0);
    signal eth_rx_mvb_src_rdy            : std_logic_vector(ETH_STREAMS-1 downto 0) := (others => '0');
    signal eth_rx_mvb_dst_rdy            : std_logic_vector(ETH_STREAMS-1 downto 0);

    signal eth_rx_mfb_data               : std_logic_vector(ETH_STREAMS*MFB_REGIONS*MFB_REGION_SIZE*MFB_BLOCK_SIZE*MFB_ITEM_WIDTH-1 downto 0);
    signal eth_rx_mfb_sof                : std_logic_vector(ETH_STREAMS*MFB_REGIONS-1 downto 0);
    signal eth_rx_mfb_eof                : std_logic_vector(ETH_STREAMS*MFB_REGIONS-1 downto 0);
    signal eth_rx_mfb_sof_pos            : std_logic_vector(ETH_STREAMS*MFB_REGIONS*max(1,log2(MFB_REGION_SIZE))-1 downto 0);
    signal eth_rx_mfb_eof_pos            : std_logic_vector(ETH_STREAMS*MFB_REGIONS*max(1,log2(MFB_REGION_SIZE*MFB_BLOCK_SIZE))-1 downto 0);
    signal eth_rx_mfb_src_rdy            : std_logic_vector(ETH_STREAMS-1 downto 0) := (others => '0');
    signal eth_rx_mfb_dst_rdy            : std_logic_vector(ETH_STREAMS-1 downto 0);

    signal eth_tx_mfb_data               : std_logic_vector(ETH_STREAMS*MFB_REGIONS*MFB_REGION_SIZE*MFB_BLOCK_SIZE*MFB_ITEM_WIDTH-1 downto 0);
    signal eth_tx_mfb_hdr                : std_logic_vector(ETH_STREAMS*MFB_REGIONS*ETH_TX_HDR_WIDTH-1 downto 0); --valid with sof
    signal eth_tx_mfb_sof                : std_logic_vector(ETH_STREAMS*MFB_REGIONS-1 downto 0);
    signal eth_tx_mfb_eof                : std_logic_vector(ETH_STREAMS*MFB_REGIONS-1 downto 0);
    signal eth_tx_mfb_sof_pos            : std_logic_vector(ETH_STREAMS*MFB_REGIONS*max(1,log2(MFB_REGION_SIZE))-1 downto 0);
    signal eth_tx_mfb_eof_pos            : std_logic_vector(ETH_STREAMS*MFB_REGIONS*max(1,log2(MFB_REGION_SIZE*MFB_BLOCK_SIZE))-1 downto 0);
    signal eth_tx_mfb_src_rdy            : std_logic_vector(ETH_STREAMS-1 downto 0);
    signal eth_tx_mfb_dst_rdy            : std_logic_vector(ETH_STREAMS-1 downto 0) := (others => '1');

    signal tsu_clk                       : std_logic;
    signal tsu_rst                       : std_logic;
    signal tsu_freq                      : std_logic_vector(31 downto 0);
    signal tsu_ns                        : std_logic_vector(63 downto 0);
    signal tsu_dv                        : std_logic;

    signal eth_rx_link_up_ser            : std_logic_vector(ETH_PORTS*ETH_CHANNELS-1 downto 0);
    signal eth_tx_phy_rdy_ser            : std_logic_vector(ETH_PORTS*ETH_CHANNELS-1 downto 0);
    signal eth_rx_link_up                : slv_array_t(ETH_PORTS-1 downto 0)(ETH_CHANNELS-1 downto 0);
    signal eth_tx_phy_rdy                : slv_array_t(ETH_PORTS-1 downto 0)(ETH_CHANNELS-1 downto 0);
    signal eth_rx_activity_ser           : std_logic_vector(ETH_PORTS*ETH_CHANNELS-1 downto 0);
    signal eth_tx_activity_ser           : std_logic_vector(ETH_PORTS*ETH_CHANNELS-1 downto 0);
    signal eth_rx_activity               : slv_array_t(ETH_PORTS-1 downto 0)(ETH_CHANNELS-1 downto 0);
    signal eth_tx_activity               : slv_array_t(ETH_PORTS-1 downto 0)(ETH_CHANNELS-1 downto 0);

    signal flash_wr_data                 : std_logic_vector(64-1 downto 0);
    signal flash_wr_en                   : std_logic;
    signal flash_rd_data                 : std_logic_vector(64-1 downto 0);

begin

    -- =========================================================================
    --  CLOCK AND RESET GENERATOR
    -- =========================================================================

    clk_gen_i : entity work.COMMON_CLK_GEN
    generic map(
        REFCLK_FREQ        => SYSCLK_FREQ,
        INIT_DONE_AS_RESET => True,
        DEVICE             => DEVICE
    )
    port map (
        REFCLK      => SYSCLK,
        ASYNC_RESET => SYSRST,
        LOCKED      => pll_locked,
        INIT_DONE_N => init_done_n,
        OUTCLK_0    => clk_usr_x4, -- 400 MHz
        OUTCLK_1    => clk_usr_x3, -- 300 MHz
        OUTCLK_2    => clk_usr_x2, -- 200 MHz
        OUTCLK_3    => clk_usr_x1  -- 100 MHz
    );

    clk_vector <= clk_eth_phy & clk_usr_x4 & clk_usr_x3 & clk_usr_x2 & clk_usr_x1;

    global_reset_i : entity work.ASYNC_RESET
    generic map (
        TWO_REG  => false,
        OUT_REG  => true,
        REPLICAS => 1
    )
    port map (
        CLK        => SYSCLK,
        ASYNC_RST  => not pll_locked,
        OUT_RST(0) => global_reset
    );

    reset_tree_gen_i : entity work.RESET_TREE_GEN
    generic map(
        CLK_COUNT    => CLK_COUNT,
        RST_REPLICAS => RESET_WIDTH
    )
    port map (
        STABLE_CLK   => SYSCLK,
        GLOBAL_RESET => global_reset,
        CLK_VECTOR   => clk_vector,
        RST_VECTOR   => rst_vector
    );

    rst_usr_x1 <= rst_vector((0+1)*RESET_WIDTH-1 downto 0*RESET_WIDTH);
    rst_usr_x2 <= rst_vector((1+1)*RESET_WIDTH-1 downto 1*RESET_WIDTH);
    rst_usr_x3 <= rst_vector((2+1)*RESET_WIDTH-1 downto 2*RESET_WIDTH);
    rst_usr_x4 <= rst_vector((3+1)*RESET_WIDTH-1 downto 3*RESET_WIDTH);

    rst_eth_phy_g: for i in 0 to ETH_PORTS-1 generate
        rst_eth_phy(i) <= rst_vector((4+i)*RESET_WIDTH);
    end generate;

    -- =========================================================================
    --                      PCIe module instance and connections
    -- =========================================================================

    pcie_i : entity work.PCIE
    generic map (
        BAR0_BASE_ADDR      => BAR0_BASE_ADDR,
        BAR1_BASE_ADDR      => BAR1_BASE_ADDR,
        BAR2_BASE_ADDR      => BAR2_BASE_ADDR,
        BAR3_BASE_ADDR      => BAR3_BASE_ADDR,
        BAR4_BASE_ADDR      => BAR4_BASE_ADDR,
        BAR5_BASE_ADDR      => BAR5_BASE_ADDR,
        EXP_ROM_BASE_ADDR   => EXP_ROM_BASE_ADDR,

        VENDOR_ID           => PCI_VENDOR_ID,
        DEVICE_ID           => PCI_DEVICE_ID,
        SUBVENDOR_ID        => PCI_SUBVENDOR_ID,
        SUBDEVICE_ID        => PCI_SUBDEVICE_ID,
        XVC_ENABLE          => false,
        PF0_TOTAL_VF        => 0,

        DMA_ENDPOINTS       => DMA_ENDPOINTS,

        MVB_UP_ITEMS        => DMA_UP_MVB_ITEMS,
        MFB_UP_REGIONS      => DMA_UP_MFB_REGIONS,
        MFB_UP_REG_SIZE     => DMA_UP_MFB_REGION_SIZE,
        MFB_UP_BLOCK_SIZE   => DMA_UP_MFB_BLOCK_SIZE,
        MFB_UP_ITEM_WIDTH   => DMA_UP_MFB_ITEM_WIDTH,

        MVB_DOWN_ITEMS      => DMA_DOWN_MVB_ITEMS,
        MFB_DOWN_REGIONS    => DMA_DOWN_MFB_REGIONS,
        MFB_DOWN_REG_SIZE   => DMA_DOWN_MFB_REGION_SIZE,
        MFB_DOWN_BLOCK_SIZE => DMA_DOWN_MFB_BLOCK_SIZE,
        MFB_DOWN_ITEM_WIDTH => DMA_DOWN_MFB_ITEM_WIDTH,

        ENDPOINT_TYPE       => PCIE_ENDPOINT_TYPE,
        ENDPOINT_MODE       => PCIE_ENDPOINT_MODE,
        PCIE_ENDPOINTS      => PCIE_ENDPOINTS,
        PCIE_CLKS           => PCIE_CLKS,
        PCIE_CONS           => PCIE_CONS,
        PCIE_LANES          => PCIE_LANES,
        DEVICE              => DEVICE
    )
    port map (
        PCIE_SYSCLK_P      => PCIE_SYSCLK_P,
        PCIE_SYSCLK_N      => PCIE_SYSCLK_N,
        PCIE_SYSRST_N      => PCIE_SYSRST_N,
        INIT_DONE_N        => init_done_n,
        PCIE_RX_P          => PCIE_RX_P,
        PCIE_RX_N          => PCIE_RX_N,
        PCIE_TX_P          => PCIE_TX_P,
        PCIE_TX_N          => PCIE_TX_N,
        PCIE_USER_CLK      => clk_pci,
        PCIE_USER_RESET    => rst_pci,
        PCIE_LINK_UP       => pcie_link_up,

        DMA_CLK            => clk_dma,
        DMA_RESET          => rst_dma(0),
        
        UP_MFB_DATA        => dma_up_mfb_data,
        UP_MFB_SOF         => dma_up_mfb_sof,
        UP_MFB_EOF         => dma_up_mfb_eof,
        UP_MFB_SOF_POS     => dma_up_mfb_sof_pos,
        UP_MFB_EOF_POS     => dma_up_mfb_eof_pos,
        UP_MFB_SRC_RDY     => dma_up_mfb_src_rdy,
        UP_MFB_DST_RDY     => dma_up_mfb_dst_rdy,

        UP_MVB_DATA        => dma_up_mvb_data,
        UP_MVB_VLD         => dma_up_mvb_vld,
        UP_MVB_SRC_RDY     => dma_up_mvb_src_rdy,
        UP_MVB_DST_RDY     => dma_up_mvb_dst_rdy,

        DOWN_MFB_DATA      => dma_down_mfb_data,
        DOWN_MFB_SOF       => dma_down_mfb_sof,
        DOWN_MFB_EOF       => dma_down_mfb_eof,
        DOWN_MFB_SOF_POS   => dma_down_mfb_sof_pos,
        DOWN_MFB_EOF_POS   => dma_down_mfb_eof_pos,
        DOWN_MFB_SRC_RDY   => dma_down_mfb_src_rdy,
        DOWN_MFB_DST_RDY   => dma_down_mfb_dst_rdy,

        DOWN_MVB_DATA      => dma_down_mvb_data,
        DOWN_MVB_VLD       => dma_down_mvb_vld,
        DOWN_MVB_SRC_RDY   => dma_down_mvb_src_rdy,
        DOWN_MVB_DST_RDY   => dma_down_mvb_dst_rdy,

        MI_CLK             => clk_mi,
        MI_RESET           => rst_mi(0),
        MI_DWR             => mi_dwr,
        MI_ADDR            => mi_addr,
        MI_BE              => mi_be,
        MI_RD              => mi_rd,
        MI_WR              => mi_wr,
        MI_DRD             => mi_drd,
        MI_ARDY            => mi_ardy,
        MI_DRDY            => mi_drdy
    );

    cdc_pcie_up_g: for i in 0 to PCIE_ENDPOINTS-1 generate
        cdc_pcie_up_dma_i: entity work.ASYNC_OPEN_LOOP
        generic map (
            IN_REG  => true,
            TWO_REG => false     
        )  
        port map(
            ACLK     => clk_pci(i),
            BCLK     => clk_dma,
            ARST     => '0',
            BRST     => '0',
            ADATAIN  => pcie_link_up(i),                
            BDATAOUT => dma_pcie_link_up(i) 
        );

        cdc_pcie_up_app_i: entity work.ASYNC_OPEN_LOOP
        generic map (
            IN_REG  => true,
            TWO_REG => false     
        )  
        port map(
            ACLK     => clk_pci(i),
            BCLK     => clk_app,
            ARST     => '0',
            BRST     => '0',
            ADATAIN  => pcie_link_up(i),                
            BDATAOUT => app_pcie_link_up(i) 
        );
    end generate;

    -- =========================================================================
    --  MI ADDRESS DECODER
    -- =========================================================================

    mi_adc_i : entity work.MI_SPLITTER_PLUS_GEN
    generic map(
        ADDR_WIDTH    => 32,
        DATA_WIDTH    => 32,
        -- defined in mi_addr_space_pack
        PORTS         => MI_ADC_PORTS,
        --PIPE_OUT      => MI_ADC_PIPE_EN,
        --ADDR_BASES    => MI_ADC_ADDR_BASES,
        ADDR_BASE     => MI_ADC_ADDR_BASE,
        --ADDR_MASK     => get_addr_mask(MI_ADC_ADDR_BASE),
        --PORT_MAPPING  => MI_ADC_PORT_MAPPING(0),
        DEVICE        => DEVICE
    )
    port map(
        CLK        => clk_mi,
        RESET      => rst_mi(1),

        RX_DWR     => mi_dwr (0),
        RX_ADDR    => mi_addr(0),
        RX_BE      => mi_be  (0),
        RX_RD      => mi_rd  (0),
        RX_WR      => mi_wr  (0),
        RX_ARDY    => mi_ardy(0),
        RX_DRD     => mi_drd (0),
        RX_DRDY    => mi_drdy(0),

        TX_DWR     => mi_adc_dwr ,
        TX_ADDR    => mi_adc_addr,
        TX_BE      => mi_adc_be  ,
        TX_RD      => mi_adc_rd  ,
        TX_WR      => mi_adc_wr  ,
        TX_ARDY    => mi_adc_ardy,
        TX_DRD     => mi_adc_drd ,
        TX_DRDY    => mi_adc_drdy
    );

    boot_ctrl_g: if BOARD = "FB4CGG3" generate
        boot_ctrl_i : entity work.BOOT_CTRL
        generic map(
            DEVICE => DEVICE
        )
        port map(
            MI_CLK        => clk_mi,
            MI_RESET      => rst_mi(1),
            MI_DWR        => mi_adc_dwr (MI_ADC_PORT_BOOT),
            MI_ADDR       => mi_adc_addr(MI_ADC_PORT_BOOT),
            MI_BE         => mi_adc_be  (MI_ADC_PORT_BOOT),
            MI_RD         => mi_adc_rd  (MI_ADC_PORT_BOOT),
            MI_WR         => mi_adc_wr  (MI_ADC_PORT_BOOT),
            MI_ARDY       => mi_adc_ardy(MI_ADC_PORT_BOOT),
            MI_DRD        => mi_adc_drd (MI_ADC_PORT_BOOT),
            MI_DRDY       => mi_adc_drdy(MI_ADC_PORT_BOOT),

            BOOT_CLK      => clk_pci(0),
            BOOT_RESET    => rst_pci(0),

            BOOT_REQUEST  => open,
            BOOT_IMAGE    => open,

            FLASH_WR_DATA => flash_wr_data,
            FLASH_WR_EN   => flash_wr_en,
            FLASH_RD_DATA => flash_rd_data
        );

        flash_rd_data <= MISC_IN;
        MISC_OUT <= flash_wr_data & flash_wr_en & rst_pci(0) & clk_pci(0);
    else generate
        mi_adc_ardy(MI_ADC_PORT_BOOT) <= '1';
        mi_adc_drdy(MI_ADC_PORT_BOOT) <= '0';
        mi_adc_drd (MI_ADC_PORT_BOOT) <= (others => '0');
    end generate;

    -- unused MI ports
    mi_adc_ardy(MI_ADC_PORT_MSIX) <= '1';
    mi_adc_drdy(MI_ADC_PORT_MSIX) <= '0';
    mi_adc_drd (MI_ADC_PORT_MSIX) <= (others => '0');

    -- =========================================================================
    --  MI TEST SPACE AND SENSOR INTERFACE
    -- =========================================================================

    mi_test_space_i : entity work.MI_TEST_SPACE
    generic map (
        DEVICE  => DEVICE
    )
    port map (
        CLK     => clk_mi,
        RESET   => rst_mi(3),
        MI_DWR  => mi_adc_dwr(MI_ADC_PORT_TEST),
        MI_ADDR => mi_adc_addr(MI_ADC_PORT_TEST),
        MI_BE   => mi_adc_be(MI_ADC_PORT_TEST),
        MI_RD   => mi_adc_rd(MI_ADC_PORT_TEST),
        MI_WR   => mi_adc_wr(MI_ADC_PORT_TEST),
        MI_DRD  => mi_adc_drd(MI_ADC_PORT_TEST),
        MI_ARDY => mi_adc_ardy(MI_ADC_PORT_TEST),
        MI_DRDY => mi_adc_drdy(MI_ADC_PORT_TEST)
    );

    sensor_interface_i: entity work.SENSOR_INTERFACE
    Generic map (
        VERI => false
    )
    Port map (
        CLK   => clk_mi,
        RESET => rst_mi(2),
        DWR   => mi_adc_dwr(MI_ADC_PORT_SENSOR),
        ADDR  => mi_adc_addr(MI_ADC_PORT_SENSOR),
        RD    => mi_adc_rd(MI_ADC_PORT_SENSOR),
        WR    => mi_adc_wr(MI_ADC_PORT_SENSOR),
        BE    => mi_adc_be(MI_ADC_PORT_SENSOR),
        DRD   => mi_adc_drd(MI_ADC_PORT_SENSOR),
        ARDY  => mi_adc_ardy(MI_ADC_PORT_SENSOR),
        DRDY  => mi_adc_drdy(MI_ADC_PORT_SENSOR)
    );


    -- =========================================================================
    --  DMA MODULE
    -- =========================================================================

    dma_i : entity work.DMA
    generic map (
        DEVICE               => DEVICE                    ,
        NUM_DMA              => DMA_MODULES               ,
        DMA_STREAMS          => DMA_STREAMS               ,

        USR_MVB_ITEMS        => MVB_ITEMS                 ,
        USR_MFB_REGIONS      => MFB_REGIONS               ,
        USR_MFB_REGION_SIZE  => MFB_REGION_SIZE           ,
        USR_MFB_BLOCK_SIZE   => MFB_BLOCK_SIZE            ,
        USR_MFB_ITEM_WIDTH   => MFB_ITEM_WIDTH            ,

        USR_PKT_SIZE_MAX     => ETH_PKT_MTU               ,

        DMA_ENDPOINTS        => DMA_ENDPOINTS             ,
        PCIE_MPS             => PCIE_MPS                  ,
        PCIE_MRRS            => PCIE_MRRS                 ,
        DMA_TAG_WIDTH        => 8                         ,

        UP_MFB_REGIONS       => DMA_UP_MFB_REGIONS        ,
        UP_MFB_REGION_SIZE   => DMA_UP_MFB_REGION_SIZE    ,
        UP_MFB_BLOCK_SIZE    => DMA_UP_MFB_BLOCK_SIZE     ,
        UP_MFB_ITEM_WIDTH    => DMA_UP_MFB_ITEM_WIDTH     ,

        DOWN_MFB_REGIONS     => DMA_DOWN_MFB_REGIONS      ,
        DOWN_MFB_REGION_SIZE => DMA_DOWN_MFB_REGION_SIZE  ,
        DOWN_MFB_BLOCK_SIZE  => DMA_DOWN_MFB_BLOCK_SIZE   ,
        DOWN_MFB_ITEM_WIDTH  => DMA_DOWN_MFB_ITEM_WIDTH   ,

        HDR_META_WIDTH       => HDR_META_WIDTH            ,

        RX_CHANNELS          => DMA_RX_CHANNELS           ,
        RX_DP_WIDTH          => 16                        ,
        RX_HP_WIDTH          => 16                        ,
        RX_BLOCKING_MODE     => DMA_RX_BLOCKING_MODE      ,

        TX_CHANNELS          => DMA_TX_CHANNELS           ,
        TX_SEL_CHANNELS      => minimum(8,DMA_TX_CHANNELS),
        TX_DP_WIDTH          => 16                        ,

        RX_GEN_EN            => true                      ,
        TX_GEN_EN            => true                      ,

        USR_EQ_DMA           => DMA_USR_EQ_DMA            ,
        CROX_EQ_DMA          => DMA_CROX_EQ_DMA           ,
        CROX_DOUBLE_DMA      => DMA_CROX_DOUBLE_DMA       ,

        GEN_LOOP_EN          => DMA_GEN_LOOP_EN           ,
        DMA_400G_DEMO        => DMA_400G_DEMO             ,
 
        PCIE_ENDPOINTS       => PCIE_ENDPOINTS
    )
    port map (
        DMA_CLK             => clk_dma   ,
        DMA_RESET           => rst_dma(1),

        CROX_CLK            => clk_dma_x2   ,
        CROX_RESET          => rst_dma_x2(1),

        USR_CLK             => clk_app   ,
        USR_RESET           => rst_app(1),

        MI_CLK              => clk_mi    ,
        MI_RESET            => rst_mi(4) ,

        RX_USR_MVB_LEN      => app_dma_rx_mvb_len,
        RX_USR_MVB_HDR_META => app_dma_rx_mvb_hdr_meta,
        RX_USR_MVB_CHANNEL  => app_dma_rx_mvb_channel,
        RX_USR_MVB_DISCARD  => app_dma_rx_mvb_discard,
        RX_USR_MVB_VLD      => app_dma_rx_mvb_vld,
        RX_USR_MVB_SRC_RDY  => app_dma_rx_mvb_src_rdy,
        RX_USR_MVB_DST_RDY  => app_dma_rx_mvb_dst_rdy,

        RX_USR_MFB_DATA     => app_dma_rx_mfb_data,
        RX_USR_MFB_SOF      => app_dma_rx_mfb_sof,
        RX_USR_MFB_EOF      => app_dma_rx_mfb_eof,
        RX_USR_MFB_SOF_POS  => app_dma_rx_mfb_sof_pos,
        RX_USR_MFB_EOF_POS  => app_dma_rx_mfb_eof_pos,
        RX_USR_MFB_SRC_RDY  => app_dma_rx_mfb_src_rdy,
        RX_USR_MFB_DST_RDY  => app_dma_rx_mfb_dst_rdy,

        TX_USR_MVB_LEN      => app_dma_tx_mvb_len,
        TX_USR_MVB_HDR_META => app_dma_tx_mvb_hdr_meta,
        TX_USR_MVB_CHANNEL  => app_dma_tx_mvb_channel,
        TX_USR_MVB_VLD      => app_dma_tx_mvb_vld,
        TX_USR_MVB_SRC_RDY  => app_dma_tx_mvb_src_rdy,
        TX_USR_MVB_DST_RDY  => app_dma_tx_mvb_dst_rdy,

        TX_USR_MFB_DATA     => app_dma_tx_mfb_data,
        TX_USR_MFB_SOF      => app_dma_tx_mfb_sof,
        TX_USR_MFB_EOF      => app_dma_tx_mfb_eof,
        TX_USR_MFB_SOF_POS  => app_dma_tx_mfb_sof_pos,
        TX_USR_MFB_EOF_POS  => app_dma_tx_mfb_eof_pos,
        TX_USR_MFB_SRC_RDY  => app_dma_tx_mfb_src_rdy,
        TX_USR_MFB_DST_RDY  => app_dma_tx_mfb_dst_rdy,

        UP_MVB_DATA         => dma_up_mvb_data,
        UP_MVB_VLD          => dma_up_mvb_vld,
        UP_MVB_SRC_RDY      => dma_up_mvb_src_rdy,
        UP_MVB_DST_RDY      => dma_up_mvb_dst_rdy,

        UP_MFB_DATA         => dma_up_mfb_data,
        UP_MFB_SOF          => dma_up_mfb_sof,
        UP_MFB_EOF          => dma_up_mfb_eof,
        UP_MFB_SOF_POS      => dma_up_mfb_sof_pos,
        UP_MFB_EOF_POS      => dma_up_mfb_eof_pos,
        UP_MFB_SRC_RDY      => dma_up_mfb_src_rdy,
        UP_MFB_DST_RDY      => dma_up_mfb_dst_rdy,

        DOWN_MVB_DATA       => dma_down_mvb_data,
        DOWN_MVB_VLD        => dma_down_mvb_vld,
        DOWN_MVB_SRC_RDY    => dma_down_mvb_src_rdy,
        DOWN_MVB_DST_RDY    => dma_down_mvb_dst_rdy,

        DOWN_MFB_DATA       => dma_down_mfb_data,
        DOWN_MFB_SOF        => dma_down_mfb_sof,
        DOWN_MFB_EOF        => dma_down_mfb_eof,
        DOWN_MFB_SOF_POS    => dma_down_mfb_sof_pos,
        DOWN_MFB_EOF_POS    => dma_down_mfb_eof_pos,
        DOWN_MFB_SRC_RDY    => dma_down_mfb_src_rdy,
        DOWN_MFB_DST_RDY    => dma_down_mfb_dst_rdy,

        MI_ADDR             => dma_mi_addr,
        MI_DWR              => dma_mi_dwr,
        MI_BE               => dma_mi_be,
        MI_RD               => dma_mi_rd,
        MI_WR               => dma_mi_wr,
        MI_DRD              => dma_mi_drd,
        MI_ARDY             => dma_mi_ardy,
        MI_DRDY             => dma_mi_drdy,

        GEN_LOOP_MI_ADDR    => mi_adc_addr(MI_ADC_PORT_GENLOOP),
        GEN_LOOP_MI_DWR     => mi_adc_dwr(MI_ADC_PORT_GENLOOP),
        GEN_LOOP_MI_BE      => mi_adc_be(MI_ADC_PORT_GENLOOP),
        GEN_LOOP_MI_RD      => mi_adc_rd(MI_ADC_PORT_GENLOOP),
        GEN_LOOP_MI_WR      => mi_adc_wr(MI_ADC_PORT_GENLOOP),
        GEN_LOOP_MI_DRD     => mi_adc_drd(MI_ADC_PORT_GENLOOP),
        GEN_LOOP_MI_ARDY    => mi_adc_ardy(MI_ADC_PORT_GENLOOP),
        GEN_LOOP_MI_DRDY    => mi_adc_drdy(MI_ADC_PORT_GENLOOP)
    );

    -- MI interface connection
    dma_mi_pr : process (all)
    begin
        -- Connect directly to MTC by default
        dma_mi_dwr  <= mi_dwr;
        dma_mi_addr <= mi_addr;
        dma_mi_rd   <= mi_rd;
        dma_mi_wr   <= mi_wr;
        dma_mi_be   <= mi_be;
        mi_drd (PCIE_ENDPOINTS-1 downto 1) <= dma_mi_drd (PCIE_ENDPOINTS-1 downto 1);
        mi_ardy(PCIE_ENDPOINTS-1 downto 1) <= dma_mi_ardy(PCIE_ENDPOINTS-1 downto 1);
        mi_drdy(PCIE_ENDPOINTS-1 downto 1) <= dma_mi_drdy(PCIE_ENDPOINTS-1 downto 1);

        -- Connect to MI ADC for PCIe Endpoint 0
        dma_mi_dwr (0) <= mi_adc_dwr(MI_ADC_PORT_DMA);
        dma_mi_addr(0) <= mi_adc_addr(MI_ADC_PORT_DMA);
        dma_mi_rd  (0) <= mi_adc_rd(MI_ADC_PORT_DMA);
        dma_mi_wr  (0) <= mi_adc_wr(MI_ADC_PORT_DMA);
        dma_mi_be  (0) <= mi_adc_be(MI_ADC_PORT_DMA);
        mi_adc_drd(MI_ADC_PORT_DMA)  <= dma_mi_drd (0);
        mi_adc_ardy(MI_ADC_PORT_DMA) <= dma_mi_ardy(0);
        mi_adc_drdy(MI_ADC_PORT_DMA) <= dma_mi_drdy(0);
    end process;

    -- =========================================================================
    --  APPLICATION CORE
    -- =========================================================================

    application_core_i : entity work.APPLICATION_CORE
    generic map (
        ETH_PORTS          => ETH_PORTS,
        ETH_CHANNELS       => ETH_CHANNELS,
        ETH_STREAMS        => ETH_STREAMS,
        ETH_PKT_MTU        => ETH_PKT_MTU,
        PCIE_ENDPOINTS     => PCIE_ENDPOINTS,
        DMA_STREAMS        => DMA_STREAMS,
        DMA_RX_CHANNELS    => DMA_RX_CHANNELS,
        DMA_TX_CHANNELS    => DMA_TX_CHANNELS,
        DMA_HDR_META_WIDTH => HDR_META_WIDTH,
        DMA_PKT_MTU        => ETH_PKT_MTU,
        MFB_REGIONS        => MFB_REGIONS,
        MFB_REG_SIZE       => MFB_REGION_SIZE,
        MFB_BLOCK_SIZE     => MFB_BLOCK_SIZE,
        MFB_ITEM_WIDTH     => MFB_ITEM_WIDTH,
        MEM_PORTS          => MEM_PORTS,
        MEM_ADDR_WIDTH     => MEM_ADDR_WIDTH,
        MEM_BURST_WIDTH    => MEM_BURST_WIDTH,
        MEM_DATA_WIDTH     => MEM_DATA_WIDTH,
        MI_DATA_WIDTH      => MI_DATA_WIDTH,
        MI_ADDR_WIDTH      => MI_ADDR_WIDTH,
        RESET_WIDTH        => RESET_WIDTH,
        BOARD              => BOARD,
        DEVICE             => DEVICE
    )
    port map (
        CLK_USER           => clk_usr_x1,
        CLK_USER_X2        => clk_usr_x2,
        CLK_USER_X3        => clk_usr_x3,
        CLK_USER_X4        => clk_usr_x4,
    
        RESET_USER         => rst_usr_x1,
        RESET_USER_X2      => rst_usr_x2,
        RESET_USER_X3      => rst_usr_x3,
        RESET_USER_X4      => rst_usr_x4,

        MI_CLK             => clk_mi,
        DMA_CLK            => clk_dma,
        DMA_CLK_X2         => clk_dma_x2,
        APP_CLK            => clk_app,

        MI_RESET           => rst_mi,
        DMA_RESET          => rst_dma,
        DMA_RESET_X2       => rst_dma_x2,
        APP_RESET          => rst_app,

        PCIE_LINK_UP       => app_pcie_link_up,
        ETH_RX_LINK_UP     => eth_rx_link_up_ser,
        ETH_TX_PHY_RDY     => eth_tx_phy_rdy_ser,

        ETH_RX_MVB_DATA    => eth_rx_mvb_data,
        ETH_RX_MVB_VLD     => eth_rx_mvb_vld,
        ETH_RX_MVB_SRC_RDY => eth_rx_mvb_src_rdy,
        ETH_RX_MVB_DST_RDY => eth_rx_mvb_dst_rdy,

        ETH_RX_MFB_DATA    => eth_rx_mfb_data,
        ETH_RX_MFB_SOF     => eth_rx_mfb_sof,
        ETH_RX_MFB_EOF     => eth_rx_mfb_eof,
        ETH_RX_MFB_SOF_POS => eth_rx_mfb_sof_pos,
        ETH_RX_MFB_EOF_POS => eth_rx_mfb_eof_pos,
        ETH_RX_MFB_SRC_RDY => eth_rx_mfb_src_rdy,
        ETH_RX_MFB_DST_RDY => eth_rx_mfb_dst_rdy,

        ETH_TX_MFB_DATA    => eth_tx_mfb_data,
        ETH_TX_MFB_HDR     => eth_tx_mfb_hdr,
        ETH_TX_MFB_SOF     => eth_tx_mfb_sof,
        ETH_TX_MFB_EOF     => eth_tx_mfb_eof,
        ETH_TX_MFB_SOF_POS => eth_tx_mfb_sof_pos,
        ETH_TX_MFB_EOF_POS => eth_tx_mfb_eof_pos,
        ETH_TX_MFB_SRC_RDY => eth_tx_mfb_src_rdy,
        ETH_TX_MFB_DST_RDY => eth_tx_mfb_dst_rdy,

        DMA_RX_MVB_LEN      => app_dma_rx_mvb_len,
        DMA_RX_MVB_HDR_META => app_dma_rx_mvb_hdr_meta,
        DMA_RX_MVB_CHANNEL  => app_dma_rx_mvb_channel,
        DMA_RX_MVB_DISCARD  => app_dma_rx_mvb_discard,
        DMA_RX_MVB_VLD      => app_dma_rx_mvb_vld,
        DMA_RX_MVB_SRC_RDY  => app_dma_rx_mvb_src_rdy,
        DMA_RX_MVB_DST_RDY  => app_dma_rx_mvb_dst_rdy,

        DMA_RX_MFB_DATA     => app_dma_rx_mfb_data,
        DMA_RX_MFB_SOF      => app_dma_rx_mfb_sof,
        DMA_RX_MFB_EOF      => app_dma_rx_mfb_eof,
        DMA_RX_MFB_SOF_POS  => app_dma_rx_mfb_sof_pos,
        DMA_RX_MFB_EOF_POS  => app_dma_rx_mfb_eof_pos,
        DMA_RX_MFB_SRC_RDY  => app_dma_rx_mfb_src_rdy,
        DMA_RX_MFB_DST_RDY  => app_dma_rx_mfb_dst_rdy,

        DMA_TX_MVB_LEN      => app_dma_tx_mvb_len,
        DMA_TX_MVB_HDR_META => app_dma_tx_mvb_hdr_meta,
        DMA_TX_MVB_CHANNEL  => app_dma_tx_mvb_channel,
        DMA_TX_MVB_VLD      => app_dma_tx_mvb_vld,
        DMA_TX_MVB_SRC_RDY  => app_dma_tx_mvb_src_rdy,
        DMA_TX_MVB_DST_RDY  => app_dma_tx_mvb_dst_rdy,

        DMA_TX_MFB_DATA     => app_dma_tx_mfb_data,
        DMA_TX_MFB_SOF      => app_dma_tx_mfb_sof,
        DMA_TX_MFB_EOF      => app_dma_tx_mfb_eof,
        DMA_TX_MFB_SOF_POS  => app_dma_tx_mfb_sof_pos,
        DMA_TX_MFB_EOF_POS  => app_dma_tx_mfb_eof_pos,
        DMA_TX_MFB_SRC_RDY  => app_dma_tx_mfb_src_rdy,
        DMA_TX_MFB_DST_RDY  => app_dma_tx_mfb_dst_rdy,

        MEM_CLK                => MEM_CLK,
        MEM_RST                => MEM_RST,
                               
        MEM_AVMM_READY         => MEM_AVMM_READY,
        MEM_AVMM_READ          => MEM_AVMM_READ,
        MEM_AVMM_WRITE         => MEM_AVMM_WRITE,
        MEM_AVMM_ADDRESS       => MEM_AVMM_ADDRESS,
        MEM_AVMM_BURSTCOUNT    => MEM_AVMM_BURSTCOUNT,
        MEM_AVMM_WRITEDATA     => MEM_AVMM_WRITEDATA,
        MEM_AVMM_READDATA      => MEM_AVMM_READDATA,
        MEM_AVMM_READDATAVALID => MEM_AVMM_READDATAVALID,
                               
        EMIF_RST_REQ           => EMIF_RST_REQ,
        EMIF_RST_DONE          => EMIF_RST_DONE,
        EMIF_ECC_USR_INT       => EMIF_ECC_USR_INT,
        EMIF_CAL_SUCCESS       => EMIF_CAL_SUCCESS,
        EMIF_CAL_FAIL          => EMIF_CAL_FAIL,

        MI_DWR             => mi_adc_dwr(MI_ADC_PORT_USERAPP),
        MI_ADDR            => mi_adc_addr(MI_ADC_PORT_USERAPP),
        MI_BE              => mi_adc_be(MI_ADC_PORT_USERAPP),
        MI_RD              => mi_adc_rd(MI_ADC_PORT_USERAPP),
        MI_WR              => mi_adc_wr(MI_ADC_PORT_USERAPP),
        MI_DRD             => mi_adc_drd(MI_ADC_PORT_USERAPP),
        MI_ARDY            => mi_adc_ardy(MI_ADC_PORT_USERAPP),
        MI_DRDY            => mi_adc_drdy(MI_ADC_PORT_USERAPP)
    );

    -- =========================================================================
    --  NETWORK MODULE
    -- =========================================================================

    network_mod_i : entity work.NETWORK_MOD
    generic map (  
        ETH_PORTS         => ETH_PORTS      ,
        ETH_PORT_SPEED    => ETH_PORT_SPEED ,
        ETH_PORT_CHAN     => ETH_PORT_CHAN  ,
        LANES             => ETH_LANES      ,
        QSFP_I2C_PORTS    => QSFP_I2C_PORTS ,

        REGIONS           => MFB_REGIONS    ,
        REGION_SIZE       => MFB_REGION_SIZE,
        BLOCK_SIZE        => MFB_BLOCK_SIZE ,
        ITEM_WIDTH        => MFB_ITEM_WIDTH ,

        MI_DATA_WIDTH     => 32             ,
        MI_ADDR_WIDTH     => 32             ,

        MI_DATA_WIDTH_PHY => 32             ,
        MI_ADDR_WIDTH_PHY => 32             ,

        RESET_WIDTH       => 1              ,
        DEVICE            => DEVICE         ,
        BOARD             => BOARD
    )
    port map (
        CLK_USER        => clk_app,
        CLK_ETH         => clk_eth_phy,
        RESET_USER(0)   => rst_app(2),
        RESET_ETH       => rst_eth_phy,

        QSFP_REFCLK_P   => ETH_REFCLK_P,
        QSFP_RX_P       => ETH_RX_P,
        QSFP_RX_N       => ETH_RX_N,
        QSFP_TX_P       => ETH_TX_P,
        QSFP_TX_N       => ETH_TX_N,

        QSFP_I2C_SCL    => QSFP_I2C_SCL,
        QSFP_I2C_SDA    => QSFP_I2C_SDA,
        QSFP_MODSEL_N   => QSFP_MODSEL_N,
        QSFP_LPMODE     => QSFP_LPMODE,
        QSFP_RESET_N    => QSFP_RESET_N,
        QSFP_MODPRS_N   => QSFP_MODPRS_N,
        QSFP_INT_N      => QSFP_INT_N,

        --REPEATER_CTRL   => (others => '0'), --TBD
        --PORT_ENABLED    => open, --TBD
        ACTIVITY_RX     => eth_rx_activity_ser,
        ACTIVITY_TX     => eth_tx_activity_ser,
        RX_LINK_UP      => eth_rx_link_up_ser,
        TX_LINK_UP      => eth_tx_phy_rdy_ser,

        RX_MFB_DATA     => eth_tx_mfb_data,
        RX_MFB_HDR      => eth_tx_mfb_hdr,
        RX_MFB_SOF_POS  => eth_tx_mfb_sof_pos,
        RX_MFB_EOF_POS  => eth_tx_mfb_eof_pos,
        RX_MFB_SOF      => eth_tx_mfb_sof,
        RX_MFB_EOF      => eth_tx_mfb_eof,
        RX_MFB_SRC_RDY  => eth_tx_mfb_src_rdy,
        RX_MFB_DST_RDY  => eth_tx_mfb_dst_rdy,

        TX_MFB_DATA     => eth_rx_mfb_data,
        TX_MFB_SOF_POS  => eth_rx_mfb_sof_pos,
        TX_MFB_EOF_POS  => eth_rx_mfb_eof_pos,
        TX_MFB_SOF      => eth_rx_mfb_sof,
        TX_MFB_EOF      => eth_rx_mfb_eof,
        TX_MFB_SRC_RDY  => eth_rx_mfb_src_rdy,
        TX_MFB_DST_RDY  => eth_rx_mfb_dst_rdy,
        TX_MVB_DATA     => eth_rx_mvb_data,
        TX_MVB_VLD      => eth_rx_mvb_vld,
        TX_MVB_SRC_RDY  => eth_rx_mvb_src_rdy,
        TX_MVB_DST_RDY  => eth_rx_mvb_dst_rdy,

        MI_CLK          => clk_mi,
        MI_RESET        => rst_mi(5),
        MI_DWR          => mi_adc_dwr(MI_ADC_PORT_NETMOD),
        MI_ADDR         => mi_adc_addr(MI_ADC_PORT_NETMOD),
        MI_RD           => mi_adc_rd(MI_ADC_PORT_NETMOD),
        MI_WR           => mi_adc_wr(MI_ADC_PORT_NETMOD),
        MI_BE           => mi_adc_be(MI_ADC_PORT_NETMOD),
        MI_DRD          => mi_adc_drd(MI_ADC_PORT_NETMOD),
        MI_ARDY         => mi_adc_ardy(MI_ADC_PORT_NETMOD),
        MI_DRDY         => mi_adc_drdy(MI_ADC_PORT_NETMOD),

        MI_CLK_PHY      => clk_mi,
        MI_RESET_PHY    => rst_mi(6),
        MI_DWR_PHY      => mi_adc_dwr(MI_ADC_PORT_ETHMOD),
        MI_ADDR_PHY     => mi_adc_addr(MI_ADC_PORT_ETHMOD),
        MI_RD_PHY       => mi_adc_rd(MI_ADC_PORT_ETHMOD),
        MI_WR_PHY       => mi_adc_wr(MI_ADC_PORT_ETHMOD),
        MI_BE_PHY       => mi_adc_be(MI_ADC_PORT_ETHMOD),
        MI_DRD_PHY      => mi_adc_drd(MI_ADC_PORT_ETHMOD),
        MI_ARDY_PHY     => mi_adc_ardy(MI_ADC_PORT_ETHMOD),
        MI_DRDY_PHY     => mi_adc_drdy(MI_ADC_PORT_ETHMOD),

        TSU_CLK         => tsu_clk,
        TSU_RST         => tsu_rst,
        TSU_TS_NS       => tsu_ns,
        TSU_TS_DV       => tsu_dv
    );

    eth_rx_link_up  <= slv_array_deser(eth_rx_link_up_ser,ETH_PORTS,ETH_CHANNELS);
    eth_tx_phy_rdy  <= slv_array_deser(eth_tx_phy_rdy_ser,ETH_PORTS,ETH_CHANNELS);
    eth_rx_activity <= slv_array_deser(eth_rx_activity_ser,ETH_PORTS,ETH_CHANNELS);
    eth_tx_activity <= slv_array_deser(eth_tx_activity_ser,ETH_PORTS,ETH_CHANNELS);

    led_eth_g: for i in 0 to ETH_PORTS-1 generate
        process (clk_eth_phy)
        begin
            if rising_edge(clk_eth_phy(i)) then
                ETH_LED_G(i) <= (and eth_rx_link_up(i)) and (and eth_tx_phy_rdy(i));
                ETH_LED_R(i) <= (or eth_rx_activity(i)) or (or eth_tx_activity(i));
            end if;
        end process;
    end generate;

    -- =========================================================================
    --  TimeStamp Unit
    -- =========================================================================

    tsu_freq <= std_logic_vector(to_unsigned(TSU_FREQUENCY-1, 32)); -- input frequency is from only a single source

    tsu_gen_i: entity work.tsu_gen
    generic map (
        TS_MULT_SMART_DSP => false,
        TS_MULT_USE_DSP   => false,
        PPS_SEL_WIDTH     => 0    ,
        CLK_SEL_WIDTH     => 0
    )
    port map (
        MI_CLK            => clk_mi   ,
        MI_RESET          => rst_mi(7),
        MI_DWR            => mi_adc_dwr(MI_ADC_PORT_TSU) ,
        MI_ADDR           => mi_adc_addr(MI_ADC_PORT_TSU),
        MI_RD             => mi_adc_rd(MI_ADC_PORT_TSU)  ,
        MI_WR             => mi_adc_wr(MI_ADC_PORT_TSU)  ,
        MI_BE             => mi_adc_be(MI_ADC_PORT_TSU)  ,
        MI_DRD            => mi_adc_drd(MI_ADC_PORT_TSU) ,
        MI_ARDY           => mi_adc_ardy(MI_ADC_PORT_TSU),
        MI_DRDY           => mi_adc_drdy(MI_ADC_PORT_TSU),
        PPS_N             => '0',
        PPS_SRC           => (others => '0'),
        PPS_SEL           => open,
        CLK               => tsu_clk,
        RESET             => tsu_rst,
        CLK_FREQ          => tsu_freq,
        CLK_SRC           => X"0001",
        CLK_SEL           => open,
        TS                => open,
        TS_NS             => tsu_ns,
        TS_DV             => tsu_dv
    );

    -- =========================================================================
    --  STATUS LEDs
    -- =========================================================================
    
    STATUS_LED_G(0) <= app_pcie_link_up(0);  
    pcie_link_up1_g: if (PCIE_ENDPOINTS > 1) generate
        STATUS_LED_G(1) <= app_pcie_link_up(1);
    end generate;

end architecture;
