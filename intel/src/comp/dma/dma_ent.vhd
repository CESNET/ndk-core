-- dma_ent.vhd: DMA Module Entity
-- Copyright (C) 2022 CESNET z. s. p. o.
-- Author(s): Jakub Cabal <cabal@cesnet.cz>
--            Jan Kubalek <kubalek@cesnet.cz>
--
-- SPDX-License-Identifier: BSD-3-Clause

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.math_pack.all;
use work.type_pack.all;

use work.dma_bus_pack.all;

-- =========================================================================
--                                 Description
-- =========================================================================
-- Wrapper for DMA Module, Generator/Loopback Switch and MI asynch connection.
-- =========================================================================

entity DMA is
generic(
    -- =====================================================================
    --  DMA Module generics
    -- =====================================================================
    -- For description see entity of the used DMA Module

    DEVICE               : string := "STRATIX10";
    NUM_DMA              : natural := 1;
    DMA_STREAMS          : natural := NUM_DMA;

    USR_MVB_ITEMS        : natural := 1;
    USR_MFB_REGIONS      : natural := 1;
    USR_MFB_REGION_SIZE  : natural := 8;
    USR_MFB_BLOCK_SIZE   : natural := 8;
    USR_MFB_ITEM_WIDTH   : natural := 8;

    USR_PKT_SIZE_MAX     : natural := 2**12;

    DMA_ENDPOINTS        : natural := 1;
    PCIE_MPS             : natural := 256;
    PCIE_MRRS            : natural := 512;
    DMA_TAG_WIDTH        : natural := DMA_REQUEST_TAG'high-DMA_REQUEST_TAG'low+1;

    UP_MFB_REGIONS       : natural := 2;
    UP_MFB_REGION_SIZE   : natural := 1;
    UP_MFB_BLOCK_SIZE    : natural := 8;
    UP_MFB_ITEM_WIDTH    : natural := 32;

    DOWN_MFB_REGIONS     : natural := 2;
    DOWN_MFB_REGION_SIZE : natural := 1;
    DOWN_MFB_BLOCK_SIZE  : natural := 8;
    DOWN_MFB_ITEM_WIDTH  : natural := 32;

    HDR_META_WIDTH       : natural := 12;

    RX_CHANNELS          : natural := 8;
    RX_DP_WIDTH          : natural := 16;
    RX_HP_WIDTH          : natural := 16;
    RX_BLOCKING_MODE     : boolean := False;

    TX_CHANNELS          : natural := 8;
    TX_SEL_CHANNELS      : natural := 8;
    TX_DP_WIDTH          : natural := 16;

    RX_GEN_EN            : boolean := true;
    TX_GEN_EN            : boolean := true;

    USR_EQ_DMA           : boolean := false;
    CROX_EQ_DMA          : boolean := false;
    CROX_DOUBLE_DMA      : boolean := true;

    -- =====================================================================
    --  Others
    -- =====================================================================

    -- Enable presence of Generator/Loopback Switch
    GEN_LOOP_EN          : boolean := false;
    DMA_400G_DEMO        : boolean := false;

    -- Number of PCIe Endpoints
    -- Determines number of MI interfaces
    PCIE_ENDPOINTS       : natural := DMA_ENDPOINTS

    -- =====================================================================
);
port(
    -- =====================================================================
    --  Clock and Reset
    -- =====================================================================

    -- Clock for the DMA Module
    DMA_CLK             : in  std_logic;
    DMA_RESET           : in  std_logic;

    -- Clock for CrossbarX data transfers
    CROX_CLK            : in  std_logic;
    CROX_RESET          : in  std_logic;

    -- Clock for the User-side interface
    USR_CLK             : in std_logic;
    USR_RESET           : in std_logic;

    -- Clock for MI interface
    MI_CLK              : in std_logic;
    MI_RESET            : in std_logic;

    -- =====================================================================

    -- =====================================================================
    --  RX DMA User-side MVB+MFB
    -- =====================================================================

    -- RX_USR_MVB_DATA =======================
    RX_USR_MVB_LEN       : in  std_logic_vector(DMA_STREAMS*USR_MVB_ITEMS*log2(USR_PKT_SIZE_MAX+1)-1 downto 0);
    RX_USR_MVB_HDR_META  : in  std_logic_vector(DMA_STREAMS*USR_MVB_ITEMS*HDR_META_WIDTH          -1 downto 0);
    RX_USR_MVB_CHANNEL   : in  std_logic_vector(DMA_STREAMS*USR_MVB_ITEMS*log2(RX_CHANNELS)       -1 downto 0);
    RX_USR_MVB_DISCARD   : in  std_logic_vector(DMA_STREAMS*USR_MVB_ITEMS*1                       -1 downto 0);
    -- =======================================
    RX_USR_MVB_VLD       : in  std_logic_vector(DMA_STREAMS*USR_MVB_ITEMS                         -1 downto 0);
    RX_USR_MVB_SRC_RDY   : in  std_logic_vector(DMA_STREAMS-1 downto 0);
    RX_USR_MVB_DST_RDY   : out std_logic_vector(DMA_STREAMS-1 downto 0);

    RX_USR_MFB_DATA      : in  std_logic_vector(DMA_STREAMS*USR_MFB_REGIONS*USR_MFB_REGION_SIZE*USR_MFB_BLOCK_SIZE*USR_MFB_ITEM_WIDTH-1 downto 0);
    RX_USR_MFB_SOF       : in  std_logic_vector(DMA_STREAMS*USR_MFB_REGIONS                                                          -1 downto 0);
    RX_USR_MFB_EOF       : in  std_logic_vector(DMA_STREAMS*USR_MFB_REGIONS                                                          -1 downto 0);
    RX_USR_MFB_SOF_POS   : in  std_logic_vector(DMA_STREAMS*USR_MFB_REGIONS*max(1,log2(USR_MFB_REGION_SIZE))                         -1 downto 0);
    RX_USR_MFB_EOF_POS   : in  std_logic_vector(DMA_STREAMS*USR_MFB_REGIONS*max(1,log2(USR_MFB_REGION_SIZE*USR_MFB_BLOCK_SIZE))      -1 downto 0);
    RX_USR_MFB_SRC_RDY   : in  std_logic_vector(DMA_STREAMS-1 downto 0);
    RX_USR_MFB_DST_RDY   : out std_logic_vector(DMA_STREAMS-1 downto 0);

    -- =====================================================================

    -- =====================================================================
    --  TX DMA User-side MVB+MFB
    -- =====================================================================

    -- TX_USR_MVB_DATA =======================
    TX_USR_MVB_LEN       : out std_logic_vector(DMA_STREAMS*USR_MVB_ITEMS*log2(USR_PKT_SIZE_MAX+1)-1 downto 0);
    TX_USR_MVB_HDR_META  : out std_logic_vector(DMA_STREAMS*USR_MVB_ITEMS*HDR_META_WIDTH          -1 downto 0);
    TX_USR_MVB_CHANNEL   : out std_logic_vector(DMA_STREAMS*USR_MVB_ITEMS*log2(TX_CHANNELS)       -1 downto 0);
    -- =======================================
    TX_USR_MVB_VLD       : out std_logic_vector(DMA_STREAMS*USR_MVB_ITEMS                         -1 downto 0);
    TX_USR_MVB_SRC_RDY   : out std_logic_vector(DMA_STREAMS-1 downto 0);
    TX_USR_MVB_DST_RDY   : in  std_logic_vector(DMA_STREAMS-1 downto 0);

    TX_USR_MFB_DATA      : out std_logic_vector(DMA_STREAMS*USR_MFB_REGIONS*USR_MFB_REGION_SIZE*USR_MFB_BLOCK_SIZE*USR_MFB_ITEM_WIDTH-1 downto 0);
    TX_USR_MFB_SOF       : out std_logic_vector(DMA_STREAMS*USR_MFB_REGIONS                                                          -1 downto 0);
    TX_USR_MFB_EOF       : out std_logic_vector(DMA_STREAMS*USR_MFB_REGIONS                                                          -1 downto 0);
    TX_USR_MFB_SOF_POS   : out std_logic_vector(DMA_STREAMS*USR_MFB_REGIONS*max(1,log2(USR_MFB_REGION_SIZE))                         -1 downto 0);
    TX_USR_MFB_EOF_POS   : out std_logic_vector(DMA_STREAMS*USR_MFB_REGIONS*max(1,log2(USR_MFB_REGION_SIZE*USR_MFB_BLOCK_SIZE))      -1 downto 0);
    TX_USR_MFB_SRC_RDY   : out std_logic_vector(DMA_STREAMS-1 downto 0);
    TX_USR_MFB_DST_RDY   : in  std_logic_vector(DMA_STREAMS-1 downto 0);

    -- =====================================================================

    -- =====================================================================
    --  PCIe-side interfaces
    -- =====================================================================

    -- Upstream MVB interface (for sending request headers to PCIe Endpoints)
    UP_MVB_DATA          : out slv_array_t     (DMA_ENDPOINTS-1 downto 0)(UP_MFB_REGIONS*DMA_UPHDR_WIDTH-1 downto 0);
    UP_MVB_VLD           : out slv_array_t     (DMA_ENDPOINTS-1 downto 0)(UP_MFB_REGIONS                -1 downto 0);
    UP_MVB_SRC_RDY       : out std_logic_vector(DMA_ENDPOINTS-1 downto 0);
    UP_MVB_DST_RDY       : in  std_logic_vector(DMA_ENDPOINTS-1 downto 0);

    -- Upstream MFB interface (for sending data to PCIe Endpoints)
    UP_MFB_DATA          : out slv_array_t     (DMA_ENDPOINTS-1 downto 0)(UP_MFB_REGIONS*UP_MFB_REGION_SIZE*UP_MFB_BLOCK_SIZE*UP_MFB_ITEM_WIDTH-1 downto 0);
    UP_MFB_SOF           : out slv_array_t     (DMA_ENDPOINTS-1 downto 0)(UP_MFB_REGIONS                                                       -1 downto 0);
    UP_MFB_EOF           : out slv_array_t     (DMA_ENDPOINTS-1 downto 0)(UP_MFB_REGIONS                                                       -1 downto 0);
    UP_MFB_SOF_POS       : out slv_array_t     (DMA_ENDPOINTS-1 downto 0)(UP_MFB_REGIONS*max(1,log2(UP_MFB_REGION_SIZE))                       -1 downto 0);
    UP_MFB_EOF_POS       : out slv_array_t     (DMA_ENDPOINTS-1 downto 0)(UP_MFB_REGIONS*max(1,log2(UP_MFB_REGION_SIZE*UP_MFB_BLOCK_SIZE))     -1 downto 0);
    UP_MFB_SRC_RDY       : out std_logic_vector(DMA_ENDPOINTS-1 downto 0);
    UP_MFB_DST_RDY       : in  std_logic_vector(DMA_ENDPOINTS-1 downto 0);

    -- Downstream MVB interface (for receiving completion headers from PCIe Endpoints)
    DOWN_MVB_DATA        : in  slv_array_t     (DMA_ENDPOINTS-1 downto 0)(DOWN_MFB_REGIONS*DMA_DOWNHDR_WIDTH-1 downto 0);
    DOWN_MVB_VLD         : in  slv_array_t     (DMA_ENDPOINTS-1 downto 0)(DOWN_MFB_REGIONS                  -1 downto 0);
    DOWN_MVB_SRC_RDY     : in  std_logic_vector(DMA_ENDPOINTS-1 downto 0);
    DOWN_MVB_DST_RDY     : out std_logic_vector(DMA_ENDPOINTS-1 downto 0);

    -- Downstream MFB interface (for sending data from PCIe Endpoints)
    DOWN_MFB_DATA        : in  slv_array_t     (DMA_ENDPOINTS-1 downto 0)(DOWN_MFB_REGIONS*DOWN_MFB_REGION_SIZE*DOWN_MFB_BLOCK_SIZE*DOWN_MFB_ITEM_WIDTH-1 downto 0);
    DOWN_MFB_SOF         : in  slv_array_t     (DMA_ENDPOINTS-1 downto 0)(DOWN_MFB_REGIONS                                                             -1 downto 0);
    DOWN_MFB_EOF         : in  slv_array_t     (DMA_ENDPOINTS-1 downto 0)(DOWN_MFB_REGIONS                                                             -1 downto 0);
    DOWN_MFB_SOF_POS     : in  slv_array_t     (DMA_ENDPOINTS-1 downto 0)(DOWN_MFB_REGIONS*max(1,log2(DOWN_MFB_REGION_SIZE))                           -1 downto 0);
    DOWN_MFB_EOF_POS     : in  slv_array_t     (DMA_ENDPOINTS-1 downto 0)(DOWN_MFB_REGIONS*max(1,log2(DOWN_MFB_REGION_SIZE*DOWN_MFB_BLOCK_SIZE))       -1 downto 0);
    DOWN_MFB_SRC_RDY     : in  std_logic_vector(DMA_ENDPOINTS-1 downto 0);
    DOWN_MFB_DST_RDY     : out std_logic_vector(DMA_ENDPOINTS-1 downto 0);

    -- MI interface for SW access to DMA Module
    -- MI Address Space:
    --     bit 22 -> 0
    -- DMA Module Address Space:
    --     See entity of used DMA Module
    MI_ADDR              : in  slv_array_t     (PCIE_ENDPOINTS-1 downto 0)(32  -1 downto 0);
    MI_DWR               : in  slv_array_t     (PCIE_ENDPOINTS-1 downto 0)(32  -1 downto 0);
    MI_BE                : in  slv_array_t     (PCIE_ENDPOINTS-1 downto 0)(32/8-1 downto 0);
    MI_RD                : in  std_logic_vector(PCIE_ENDPOINTS-1 downto 0);
    MI_WR                : in  std_logic_vector(PCIE_ENDPOINTS-1 downto 0);
    MI_DRD               : out slv_array_t     (PCIE_ENDPOINTS-1 downto 0)(32  -1 downto 0);
    MI_ARDY              : out std_logic_vector(PCIE_ENDPOINTS-1 downto 0);
    MI_DRDY              : out std_logic_vector(PCIE_ENDPOINTS-1 downto 0);

    -- MI interface for SW access to Generator/Loopback Switch
    -- MI Address Space:
    --     bit 22 -> 1
    -- Generator/Loopback Switch Address Space:
    --     See entity of used Generator/Loopback Switch unit
    GEN_LOOP_MI_ADDR     : in  std_logic_vector(32  -1 downto 0);
    GEN_LOOP_MI_DWR      : in  std_logic_vector(32  -1 downto 0);
    GEN_LOOP_MI_BE       : in  std_logic_vector(32/8-1 downto 0);
    GEN_LOOP_MI_RD       : in  std_logic;
    GEN_LOOP_MI_WR       : in  std_logic;
    GEN_LOOP_MI_DRD      : out std_logic_vector(32  -1 downto 0);
    GEN_LOOP_MI_ARDY     : out std_logic;
    GEN_LOOP_MI_DRDY     : out std_logic

    -- =====================================================================
);
end entity;
