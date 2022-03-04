-- network_mod.vhd: this is the top component of the Network module; 
--                  it contains MI splitter(s) and one or more of the
--                  Network module cores (based on mode of the ethernet
--                  port) which is connected to a pair of MAC lites (RX + TX).
--                  TX input stream is first split per channel, RX channels
--                  are merged into one output stream.
--
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


architecture FULL of NETWORK_MOD is

    -- =========================================================================
    --                           FUNCTION declarations
    -- =========================================================================
    function region_size_core_f  return natural;

    -- =========================================================================
    --                               CONSTANTS
    -- =========================================================================

    constant REGIONS_CORE     : natural := tsel(ETH_PORT_SPEED(0) = 400, 2, 1); -- TODO: support different speeds/number of channels for each port
    constant REGION_SIZE_CORE : natural := region_size_core_f;

    constant ETH_CHANNELS     : integer := ETH_PORT_CHAN(0); -- TODO: support different speeds/number of channels for each port
    --                                     MFB splitter, Network mod core, MFB merger, ETH_CHANNELS x (TX MAC lite, RX MAC lite)
    constant RESET_REPLICAS   : natural := 1           + 1               + 1         + ETH_CHANNELS * (1          + 1          );

    constant TX_RX_MAC_OFF  : std_logic_vector(MI_ADDR_WIDTH-1 downto 0) := X"0000_0200";
    constant CHAN_OFF       : std_logic_vector(MI_ADDR_WIDTH-1 downto 0) := X"0000_0400";
    constant PORTS_OFF      : std_logic_vector(MI_ADDR_WIDTH-1 downto 0) := X"0000_2000";

    constant MI_ADDR_BASES     : natural := sum(ETH_PORT_CHAN)*2;

    -- MI_PHY for E/F-tile reconfiguration infs
    --                                      QSFP_CTRL + NETWORK_MOD_COREs
    constant MI_ADDR_BASES_PHY : natural := 1         + ETH_PORTS;
    -- MI Indirect Access offset (X"0000_0020" is enough)
    constant IA_OFF            : std_logic_vector(MI_ADDR_WIDTH_PHY-1 downto 0) := X"0000_1000";

    -- MFB adjustments
    constant MFB_WIDTH      : natural := REGIONS*REGION_SIZE*BLOCK_SIZE*ITEM_WIDTH;
    constant MFB_SOFP_WIDTH : natural := REGIONS*max(1,log2(REGION_SIZE));
    constant MFB_EOFP_WIDTH : natural := REGIONS*max(1,log2(REGION_SIZE*BLOCK_SIZE));

    constant MFB_WIDTH_CORE      : natural := REGIONS_CORE*REGION_SIZE_CORE*BLOCK_SIZE*ITEM_WIDTH;
    constant MFB_SOFP_WIDTH_CORE : natural := REGIONS_CORE*max(1,log2(REGION_SIZE_CORE));
    constant MFB_EOFP_WIDTH_CORE : natural := REGIONS_CORE*max(1,log2(REGION_SIZE_CORE*BLOCK_SIZE));

    constant FPC202_INIT_EN : boolean := (BOARD = "DK-DEV-1SDX-P" or BOARD = "DK-DEV-AGI027RES");
    constant F_TILE_DEVICE  : boolean := (BOARD = "400G1" or BOARD = "DK-DEV-AGI027RES");

    -- =========================================================================
    --                                FUNCTIONS
    -- =========================================================================
    function region_size_core_f return natural is
    begin
        if (BOARD = "400G1" or BOARD = "DK-DEV-AGI027RES") then
            case ETH_PORT_SPEED(0) is
                when 400    => return 8;
                when 200    => return 8;
                when 100    => return 4;
                when 50     => return 2;
                when 40     => return 2;
                when 25     => return 1;
                when 10     => return 1;
                when others => return 0; -- maybe other default value?
            end case;
        elsif (BOARD = "DK-DEV-1SDX-P") then
            case ETH_PORT_SPEED(0) is
                when 100    => return 8;
                when 25     => return 1;
                when 10     => return 1;
                when others => return 0; -- maybe other default value?
            end case;
        else
            return 0;                    -- maybe other default value?
        end if;
    end function;

    function mi_addr_base_init_f return slv_array_t is
        variable mi_addr_base_var : slv_array_t(MI_ADDR_BASES-1 downto 0)(MI_ADDR_WIDTH-1 downto 0);
    begin
        for i in 0 to ETH_PORTS-1 loop
            for j in 0 to ETH_CHANNELS-1 loop
                for k in 0 to 1 loop -- TX RX loop
                    mi_addr_base_var(i*ETH_CHANNELS*2 + j*2 + k) := std_logic_vector(resize(i*unsigned(PORTS_OFF) +                     -- specify port
                                                                                            j*unsigned(CHAN_OFF)  +                     -- specify channel
                                                                                            k*unsigned(TX_RX_MAC_OFF), MI_ADDR_WIDTH)); -- specify TX/RX
                end loop;
            end loop;
        end loop;
        return mi_addr_base_var;
    end function;

    function mi_addr_base_init_phy_f return slv_array_t is
        variable mi_addr_base_var : slv_array_t(MI_ADDR_BASES_PHY-1 downto 0)(MI_ADDR_WIDTH_PHY-1 downto 0);
    begin
        for i in 0 to MI_ADDR_BASES_PHY-1 loop
            mi_addr_base_var(i) := std_logic_vector(resize(i*unsigned(IA_OFF), MI_ADDR_WIDTH_PHY));
        end loop;
        return mi_addr_base_var;
    end function;

    -- =========================================================================
    --                                SIGNALS
    -- =========================================================================
    signal repl_rst : std_logic_vector(ETH_PORTS*RESET_REPLICAS-1 downto 0);

    -- from Network module core to RX MAC lite
    signal rx_mac_lite_rx_data    : slv_array_2d_t(ETH_PORTS-1 downto 0)(ETH_CHANNELS-1 downto 0)(MFB_WIDTH_CORE-1 downto 0);
    signal rx_mac_lite_rx_sof     : slv_array_2d_t(ETH_PORTS-1 downto 0)(ETH_CHANNELS-1 downto 0)(REGIONS_CORE-1 downto 0);
    signal rx_mac_lite_rx_eof     : slv_array_2d_t(ETH_PORTS-1 downto 0)(ETH_CHANNELS-1 downto 0)(REGIONS_CORE-1 downto 0);
    signal rx_mac_lite_rx_sof_pos : slv_array_2d_t(ETH_PORTS-1 downto 0)(ETH_CHANNELS-1 downto 0)(MFB_SOFP_WIDTH_CORE-1 downto 0);
    signal rx_mac_lite_rx_eof_pos : slv_array_2d_t(ETH_PORTS-1 downto 0)(ETH_CHANNELS-1 downto 0)(MFB_EOFP_WIDTH_CORE-1 downto 0);
    signal rx_mac_lite_rx_error   : slv_array_2d_t(ETH_PORTS-1 downto 0)(ETH_CHANNELS-1 downto 0)(REGIONS_CORE-1 downto 0);
    signal rx_mac_lite_rx_src_rdy : slv_array_t   (ETH_PORTS-1 downto 0)(ETH_CHANNELS-1 downto 0);

    -- From RX MAC lite to MFB Merger tree
    -- MFB signals
    signal merg_rx_mfb_data    : slv_array_2d_t(ETH_PORTS-1 downto 0)(ETH_CHANNELS-1 downto 0)(MFB_WIDTH-1 downto 0);
    signal merg_rx_mfb_sof     : slv_array_2d_t(ETH_PORTS-1 downto 0)(ETH_CHANNELS-1 downto 0)(REGIONS-1 downto 0);
    signal merg_rx_mfb_eof     : slv_array_2d_t(ETH_PORTS-1 downto 0)(ETH_CHANNELS-1 downto 0)(REGIONS-1 downto 0);
    signal merg_rx_mfb_sof_pos : slv_array_2d_t(ETH_PORTS-1 downto 0)(ETH_CHANNELS-1 downto 0)(MFB_SOFP_WIDTH-1 downto 0);
    signal merg_rx_mfb_eof_pos : slv_array_2d_t(ETH_PORTS-1 downto 0)(ETH_CHANNELS-1 downto 0)(MFB_EOFP_WIDTH-1 downto 0);
    signal merg_rx_mfb_src_rdy : slv_array_t   (ETH_PORTS-1 downto 0)(ETH_CHANNELS-1 downto 0);
    signal merg_rx_mfb_dst_rdy : slv_array_t   (ETH_PORTS-1 downto 0)(ETH_CHANNELS-1 downto 0);
    -- MVB signals
    signal merg_rx_mvb_data    : slv_array_2d_t(ETH_PORTS-1 downto 0)(ETH_CHANNELS-1 downto 0)(REGIONS*ETH_RX_HDR_WIDTH-1 downto 0);
    signal merg_rx_mvb_vld     : slv_array_2d_t(ETH_PORTS-1 downto 0)(ETH_CHANNELS-1 downto 0)(REGIONS-1 downto 0);
    signal merg_rx_mvb_src_rdy : slv_array_t   (ETH_PORTS-1 downto 0)(ETH_CHANNELS-1 downto 0);
    signal merg_rx_mvb_dst_rdy : slv_array_t   (ETH_PORTS-1 downto 0)(ETH_CHANNELS-1 downto 0);

    -- Output of MFB Merger tree (and of the whole Network modul) as an array
    -- MFB signals
    signal TX_MFB_DATA_arr     : slv_array_t(ETH_PORTS-1 downto 0)(MFB_WIDTH-1 downto 0);
    signal TX_MFB_SOF_arr      : slv_array_t(ETH_PORTS-1 downto 0)(REGIONS-1 downto 0);
    signal TX_MFB_EOF_arr      : slv_array_t(ETH_PORTS-1 downto 0)(REGIONS-1 downto 0);
    signal TX_MFB_SOF_POS_arr  : slv_array_t(ETH_PORTS-1 downto 0)(MFB_SOFP_WIDTH-1 downto 0);
    signal TX_MFB_EOF_POS_arr  : slv_array_t(ETH_PORTS-1 downto 0)(MFB_EOFP_WIDTH-1 downto 0);
    -- MVB signals
    signal TX_MVB_DATA_arr     : slv_array_t(ETH_PORTS-1 downto 0)(REGIONS*ETH_RX_HDR_WIDTH-1 downto 0);
    signal TX_MVB_VLD_arr      : slv_array_t(ETH_PORTS-1 downto 0)(REGIONS-1 downto 0);

    signal rx_mfb_hdr_2d_arr    : slv_array_2d_t  (ETH_PORTS-1 downto 0)(REGIONS-1 downto 0)(ETH_TX_HDR_WIDTH         -1 downto 0);
    signal eth_hdr_tx_port      : slv_array_2d_t  (ETH_PORTS-1 downto 0)(REGIONS-1 downto 0)(ETH_TX_HDR_PORT_W        -1 downto 0);
    signal split_addr           : slv_array_2d_t  (ETH_PORTS-1 downto 0)(REGIONS-1 downto 0)(max(1,log2(ETH_CHANNELS))-1 downto 0);
    signal split_addr_ser       : std_logic_vector(ETH_PORTS*            REGIONS*            max(1,log2(ETH_CHANNELS))-1 downto 0);

    -- Deserialized input for TX MAC lite(s)
    signal RX_MFB_SEL_arr       :  slv_array_t(ETH_PORTS-1 downto 0)(REGIONS*max(1,log2(ETH_CHANNELS))-1 downto 0);
    signal RX_MFB_DATA_arr      :  slv_array_t(ETH_PORTS-1 downto 0)(MFB_WIDTH-1 downto 0);
    signal RX_MFB_HDR_arr       :  slv_array_t(ETH_PORTS-1 downto 0)(REGIONS*ETH_TX_HDR_WIDTH-1 downto 0);
    signal RX_MFB_SOF_arr       :  slv_array_t(ETH_PORTS-1 downto 0)(REGIONS-1 downto 0);
    signal RX_MFB_EOF_arr       :  slv_array_t(ETH_PORTS-1 downto 0)(REGIONS-1 downto 0);
    signal RX_MFB_SOF_POS_arr   :  slv_array_t(ETH_PORTS-1 downto 0)(MFB_SOFP_WIDTH-1 downto 0);
    signal RX_MFB_EOF_POS_arr   :  slv_array_t(ETH_PORTS-1 downto 0)(MFB_EOFP_WIDTH-1 downto 0);

    -- From MFB Splitter tree to TX MAC lite(s)
    signal split_tx_mfb_data    : slv_array_2d_t(ETH_PORTS-1 downto 0)(ETH_CHANNELS-1 downto 0)(MFB_WIDTH-1 downto 0);
    signal split_tx_mfb_sof     : slv_array_2d_t(ETH_PORTS-1 downto 0)(ETH_CHANNELS-1 downto 0)(REGIONS-1 downto 0);
    signal split_tx_mfb_eof     : slv_array_2d_t(ETH_PORTS-1 downto 0)(ETH_CHANNELS-1 downto 0)(REGIONS-1 downto 0);
    signal split_tx_mfb_sof_pos : slv_array_2d_t(ETH_PORTS-1 downto 0)(ETH_CHANNELS-1 downto 0)(MFB_SOFP_WIDTH-1 downto 0);
    signal split_tx_mfb_eof_pos : slv_array_2d_t(ETH_PORTS-1 downto 0)(ETH_CHANNELS-1 downto 0)(MFB_EOFP_WIDTH-1 downto 0);
    signal split_tx_mfb_src_rdy : slv_array_t   (ETH_PORTS-1 downto 0)(ETH_CHANNELS-1 downto 0);
    signal split_tx_mfb_dst_rdy : slv_array_t   (ETH_PORTS-1 downto 0)(ETH_CHANNELS-1 downto 0);

    -- From TX MAC lite to Network module core
    signal tx_mac_lite_tx_data    : slv_array_2d_t(ETH_PORTS-1 downto 0)(ETH_CHANNELS-1 downto 0)(MFB_WIDTH_CORE-1 downto 0);
    signal tx_mac_lite_tx_sof     : slv_array_2d_t(ETH_PORTS-1 downto 0)(ETH_CHANNELS-1 downto 0)(REGIONS_CORE-1 downto 0);
    signal tx_mac_lite_tx_eof     : slv_array_2d_t(ETH_PORTS-1 downto 0)(ETH_CHANNELS-1 downto 0)(REGIONS_CORE-1 downto 0);
    signal tx_mac_lite_tx_sof_pos : slv_array_2d_t(ETH_PORTS-1 downto 0)(ETH_CHANNELS-1 downto 0)(MFB_SOFP_WIDTH_CORE-1 downto 0);
    signal tx_mac_lite_tx_eof_pos : slv_array_2d_t(ETH_PORTS-1 downto 0)(ETH_CHANNELS-1 downto 0)(MFB_EOFP_WIDTH_CORE-1 downto 0);
    signal tx_mac_lite_tx_src_rdy : slv_array_t   (ETH_PORTS-1 downto 0)(ETH_CHANNELS-1 downto 0);
    signal tx_mac_lite_tx_dst_rdy : slv_array_t   (ETH_PORTS-1 downto 0)(ETH_CHANNELS-1 downto 0);

    -- MI for MAC lites
    signal mi_split_dwr  : slv_array_t     (ETH_PORTS*ETH_CHANNELS*2-1 downto 0)(MI_DATA_WIDTH-1 downto 0);
    signal mi_split_addr : slv_array_t     (ETH_PORTS*ETH_CHANNELS*2-1 downto 0)(MI_ADDR_WIDTH-1 downto 0);
    signal mi_split_be   : slv_array_t     (ETH_PORTS*ETH_CHANNELS*2-1 downto 0)(MI_DATA_WIDTH/8-1 downto 0);
    signal mi_split_rd   : std_logic_vector(ETH_PORTS*ETH_CHANNELS*2-1 downto 0);
    signal mi_split_wr   : std_logic_vector(ETH_PORTS*ETH_CHANNELS*2-1 downto 0);
    signal mi_split_ardy : std_logic_vector(ETH_PORTS*ETH_CHANNELS*2-1 downto 0);
    signal mi_split_drd  : slv_array_t     (ETH_PORTS*ETH_CHANNELS*2-1 downto 0)(MI_DATA_WIDTH-1 downto 0);
    signal mi_split_drdy : std_logic_vector(ETH_PORTS*ETH_CHANNELS*2-1 downto 0);

    -- MI_PHY for E/F-tile reconfiguration infs
    signal mi_split_dwr_phy  : slv_array_t     (MI_ADDR_BASES_PHY-1 downto 0)(MI_DATA_WIDTH_PHY-1 downto 0);
    signal mi_split_addr_phy : slv_array_t     (MI_ADDR_BASES_PHY-1 downto 0)(MI_ADDR_WIDTH_PHY-1 downto 0);
    signal mi_split_be_phy   : slv_array_t     (MI_ADDR_BASES_PHY-1 downto 0)(MI_DATA_WIDTH_PHY/8-1 downto 0);
    signal mi_split_rd_phy   : std_logic_vector(MI_ADDR_BASES_PHY-1 downto 0);
    signal mi_split_wr_phy   : std_logic_vector(MI_ADDR_BASES_PHY-1 downto 0);
    signal mi_split_ardy_phy : std_logic_vector(MI_ADDR_BASES_PHY-1 downto 0);
    signal mi_split_drd_phy  : slv_array_t     (MI_ADDR_BASES_PHY-1 downto 0)(MI_DATA_WIDTH_PHY-1 downto 0);
    signal mi_split_drdy_phy : std_logic_vector(MI_ADDR_BASES_PHY-1 downto 0);

    -- TSU
    signal tsu_clk_vec     : std_logic_vector(ETH_PORTS-1 downto 0);
    signal tsu_rst_vec     : std_logic_vector(ETH_PORTS-1 downto 0);
    signal asfifox_wr_en   : std_logic_vector(ETH_PORTS-1 downto 0);
    signal asfifox_full    : std_logic_vector(ETH_PORTS-1 downto 0);
    signal asfifox_rd_data : slv_array_t     (ETH_PORTS-1 downto 0)(64-1 downto 0);
    signal asfifox_empty   : std_logic_vector(ETH_PORTS-1 downto 0);
    signal asfifox_ts_ns   : slv_array_t     (ETH_PORTS-1 downto 0)(64-1 downto 0);
    signal asfifox_ts_dv   : std_logic_vector(ETH_PORTS-1 downto 0);

begin

    -- =========================================================================
    --  Resets replication
    -- =========================================================================
    ports_reset_g : for i in ETH_PORTS-1 downto 0 generate
        network_mod_reset_i : entity work.ASYNC_RESET
        generic map (
            TWO_REG  => false,
            OUT_REG  => true ,
            REPLICAS => RESET_REPLICAS
        )
        port map (
            CLK         => CLK_ETH  (i),
            ASYNC_RST   => RESET_ETH(i),
            OUT_RST     => repl_rst((i+1)*RESET_REPLICAS-1 downto i*RESET_REPLICAS)
        );
    end generate;

    -- =========================================================================
    --  MI SPLITTER for MAC lites
    -- =========================================================================
    mi_splitter_plus_gen_i : entity work.MI_SPLITTER_PLUS_GEN
    generic map(
        ADDR_WIDTH  => MI_ADDR_WIDTH      ,
        DATA_WIDTH  => MI_DATA_WIDTH      ,
        META_WIDTH  => 0                  ,
        PORTS       => MI_ADDR_BASES      ,
        PIPE_OUT    => (others => true)   ,
        PIPE_TYPE   => "REG"              ,
        ADDR_BASES  => MI_ADDR_BASES      ,
        ADDR_BASE   => mi_addr_base_init_f,
        DEVICE      => DEVICE
    )
    port map(
        -- Common interface -----------------------------------------------------
        CLK         => MI_CLK  ,
        RESET       => MI_RESET,
        -- Input MI interface ---------------------------------------------------
        RX_DWR      => MI_DWR         ,
        RX_MWR      => (others => '0'),
        RX_ADDR     => MI_ADDR        ,
        RX_BE       => MI_BE          ,
        RX_RD       => MI_RD          ,
        RX_WR       => MI_WR          ,
        RX_ARDY     => MI_ARDY        ,
        RX_DRD      => MI_DRD         ,
        RX_DRDY     => MI_DRDY        ,
        -- Output MI interfaces -------------------------------------------------
        TX_DWR     => mi_split_dwr    ,
        TX_MWR     => open            ,
        TX_ADDR    => mi_split_addr   ,
        TX_BE      => mi_split_be     ,
        TX_RD      => mi_split_rd     ,
        TX_WR      => mi_split_wr     ,
        TX_ARDY    => mi_split_ardy   ,
        TX_DRD     => mi_split_drd    ,
        TX_DRDY    => mi_split_drdy
    );

    -- =========================================================================
    --  MI SPLITTER for reconfiguration of the E/F-Tile(s)
    -- =========================================================================
    -- QSFP_CTRL is at Port(0), addresses from X"0080_0000" to X"0080_1000",
    -- the rest of the Ports is for Netw module cores (MI_PHY inf) with IA_OFF offset.
    mi_splitter_plus_gen_phy_i : entity work.MI_SPLITTER_PLUS_GEN
    generic map(
        ADDR_WIDTH  => MI_ADDR_WIDTH_PHY      ,
        DATA_WIDTH  => MI_DATA_WIDTH_PHY      ,
        META_WIDTH  => 0                      ,
        PORTS       => MI_ADDR_BASES_PHY      ,
        PIPE_OUT    => (others => true)       ,
        PIPE_TYPE   => "REG"                  ,
        ADDR_BASES  => MI_ADDR_BASES_PHY      ,
        ADDR_BASE   => mi_addr_base_init_phy_f,
        DEVICE      => DEVICE
    )
    port map(
        -- Common interface -----------------------------------------------------
        CLK         => MI_CLK_PHY  ,
        RESET       => MI_RESET_PHY,
        -- Input MI interface ---------------------------------------------------
        RX_DWR      => MI_DWR_PHY      ,
        RX_MWR      => (others => '0') ,
        RX_ADDR     => MI_ADDR_PHY     ,
        RX_BE       => MI_BE_PHY       ,
        RX_RD       => MI_RD_PHY       ,
        RX_WR       => MI_WR_PHY       ,
        RX_ARDY     => MI_ARDY_PHY     ,
        RX_DRD      => MI_DRD_PHY      ,
        RX_DRDY     => MI_DRDY_PHY     ,
        -- Output MI interfaces -------------------------------------------------
        TX_DWR     => mi_split_dwr_phy ,
        TX_ADDR    => mi_split_addr_phy,
        TX_BE      => mi_split_be_phy  ,
        TX_RD      => mi_split_rd_phy  ,
        TX_WR      => mi_split_wr_phy  ,
        TX_ARDY    => mi_split_ardy_phy,
        TX_DRD     => mi_split_drd_phy ,
        TX_DRDY    => mi_split_drdy_phy
    );

    RX_MFB_DATA_arr    <= slv_array_downto_deser(RX_MFB_DATA   , ETH_PORTS);
    RX_MFB_HDR_arr     <= slv_array_downto_deser(RX_MFB_HDR    , ETH_PORTS);
    RX_MFB_SOF_arr     <= slv_array_downto_deser(RX_MFB_SOF    , ETH_PORTS);
    RX_MFB_EOF_arr     <= slv_array_downto_deser(RX_MFB_EOF    , ETH_PORTS);
    RX_MFB_SOF_POS_arr <= slv_array_downto_deser(RX_MFB_SOF_POS, ETH_PORTS);
    RX_MFB_EOF_POS_arr <= slv_array_downto_deser(RX_MFB_EOF_POS, ETH_PORTS);

    eth_core_g : for i in 0 to ETH_PORTS-1 generate
        -- =====================================================================
        -- TX path
        -- =====================================================================
        -- Split one ETH_STREAM into ETH_CHANNELS
        rx_mfb_hdr_2d_arr(i) <= slv_array_downto_deser(RX_MFB_HDR_arr(i), REGIONS);
        splitter_addr_p : for j in REGIONS-1 downto 0 generate
            eth_hdr_tx_port(i)(j) <= rx_mfb_hdr_2d_arr(i)(j)(ETH_TX_HDR_PORT);
            split_addr     (i)(j) <= eth_hdr_tx_port  (i)(j)(max(1,log2(ETH_CHANNELS))-1 downto 0);
        end generate;
        RX_MFB_SEL_arr(i) <= slv_array_ser(split_addr(i));
        
        mfb_splitter_tree_i : entity work.MFB_SPLITTER_SIMPLE_GEN
        generic map(
            SPLITTER_OUTPUTS => ETH_CHANNELS    ,
            REGIONS          => REGIONS         ,
            REGION_SIZE      => REGION_SIZE     ,
            BLOCK_SIZE       => BLOCK_SIZE      ,
            ITEM_WIDTH       => ITEM_WIDTH      ,
            META_WIDTH       => ETH_TX_HDR_WIDTH
        )
        port map(
            CLK             => CLK_USER     ,
            RESET           => RESET_USER(0),

            RX_MFB_SEL      => RX_MFB_SEL_arr    (i),
            RX_MFB_DATA     => RX_MFB_DATA_arr   (i),
            RX_MFB_META     => RX_MFB_HDR_arr    (i),
            RX_MFB_SOF      => RX_MFB_SOF_arr    (i),
            RX_MFB_EOF      => RX_MFB_EOF_arr    (i),
            RX_MFB_SOF_POS  => RX_MFB_SOF_POS_arr(i),
            RX_MFB_EOF_POS  => RX_MFB_EOF_POS_arr(i),
            RX_MFB_SRC_RDY  => RX_MFB_SRC_RDY    (i),
            RX_MFB_DST_RDY  => RX_MFB_DST_RDY    (i),

            TX_MFB_DATA     => split_tx_mfb_data   (i),
            --TX_MFB_META     => split_tx_mfb_meta(i), --TODO?
            TX_MFB_SOF      => split_tx_mfb_sof    (i),
            TX_MFB_EOF      => split_tx_mfb_eof    (i),
            TX_MFB_SOF_POS  => split_tx_mfb_sof_pos(i),
            TX_MFB_EOF_POS  => split_tx_mfb_eof_pos(i),
            TX_MFB_SRC_RDY  => split_tx_mfb_src_rdy(i),
            TX_MFB_DST_RDY  => split_tx_mfb_dst_rdy(i)
        );

        tx_mac_lites_g : for j in ETH_CHANNELS-1 downto 0 generate
            tx_mac_lite_i : entity work.TX_MAC_LITE
            generic map(
                RX_REGIONS      => REGIONS         ,
                RX_REGION_SIZE  => REGION_SIZE     ,
                RX_BLOCK_SIZE   => BLOCK_SIZE      ,
                RX_ITEM_WIDTH   => ITEM_WIDTH      ,
                TX_REGIONS      => REGIONS_CORE    ,
                TX_REGION_SIZE  => REGION_SIZE_CORE,
                TX_BLOCK_SIZE   => BLOCK_SIZE      ,
                TX_ITEM_WIDTH   => ITEM_WIDTH      ,
                RESIZE_ON_TX    => True            ,
                RX_INCLUDE_CRC  => false           ,
                RX_INCLUDE_IPG  => false           ,
                CRC_INSERT_EN   => false           ,
                IPG_GENERATE_EN => false           ,
                USE_DSP_CNT     => true            ,--todo
                --TRANS_FIFO_SIZE => ,
                --ETH_VERSION     => ,
                DEVICE          => DEVICE
            )
            port map(
                MI_CLK         => MI_CLK  ,
                MI_RESET       => MI_RESET,
                MI_DWR         => mi_split_dwr (i*ETH_CHANNELS*2+j*2+0),
                MI_ADDR        => mi_split_addr(i*ETH_CHANNELS*2+j*2+0),
                MI_RD          => mi_split_rd  (i*ETH_CHANNELS*2+j*2+0),
                MI_WR          => mi_split_wr  (i*ETH_CHANNELS*2+j*2+0),
                MI_BE          => mi_split_be  (i*ETH_CHANNELS*2+j*2+0),
                MI_DRD         => mi_split_drd (i*ETH_CHANNELS*2+j*2+0),
                MI_ARDY        => mi_split_ardy(i*ETH_CHANNELS*2+j*2+0),
                MI_DRDY        => mi_split_drdy(i*ETH_CHANNELS*2+j*2+0),

                RX_CLK         => CLK_USER     ,
                RX_CLK_X2      => CLK_USER     , -- CX inside is not used, else use CLK_X2
                RX_RESET       => RESET_USER(0),
                RX_MFB_DATA    => split_tx_mfb_data   (i)(j),
                RX_MFB_SOF_POS => split_tx_mfb_sof_pos(i)(j),
                RX_MFB_EOF_POS => split_tx_mfb_eof_pos(i)(j),
                RX_MFB_SOF     => split_tx_mfb_sof    (i)(j),
                RX_MFB_EOF     => split_tx_mfb_eof    (i)(j),
                RX_MFB_SRC_RDY => split_tx_mfb_src_rdy(i)(j),
                RX_MFB_DST_RDY => split_tx_mfb_dst_rdy(i)(j),

                TX_CLK         => CLK_ETH (i),
                TX_RESET       => repl_rst(i*(3+ETH_CHANNELS*2)+j*2+3),
                TX_MFB_DATA    => tx_mac_lite_tx_data   (i)(j),
                TX_MFB_SOF     => tx_mac_lite_tx_sof    (i)(j),
                TX_MFB_EOF     => tx_mac_lite_tx_eof    (i)(j),
                TX_MFB_SOF_POS => tx_mac_lite_tx_sof_pos(i)(j),
                TX_MFB_EOF_POS => tx_mac_lite_tx_eof_pos(i)(j),
                TX_MFB_SRC_RDY => tx_mac_lite_tx_src_rdy(i)(j),
                TX_MFB_DST_RDY => tx_mac_lite_tx_dst_rdy(i)(j),

                OUTGOING_FRAME => open--todo
            );
        end generate;

        -- =====================================================================
        -- Module core
        -- =====================================================================    
        network_mod_core_i: entity work.NETWORK_MOD_CORE 
        generic map (
            ETH_PORT_SPEED    => ETH_PORT_SPEED(i),
            ETH_PORT_CHAN     => ETH_PORT_CHAN (i),
            LANES             => LANES            ,
            REGIONS           => REGIONS_CORE     ,
            REGION_SIZE       => REGION_SIZE_CORE ,
            BLOCK_SIZE        => BLOCK_SIZE       ,
            ITEM_WIDTH        => ITEM_WIDTH       ,
            MI_DATA_WIDTH_PHY => MI_DATA_WIDTH_PHY,
            MI_ADDR_WIDTH_PHY => MI_ADDR_WIDTH_PHY,
            DEVICE            => DEVICE
        )
        port map (
            -- clock and reset
            CLK_ETH         => CLK_ETH(i),
            RESET_ETH       => repl_rst(i*(3+ETH_CHANNELS*2)+1),
            -- QSFP interface
            QSFP_REFCLK_P   => QSFP_REFCLK_P(i)                         ,
            QSFP_RX_P       => QSFP_RX_P(i*LANES+LANES-1 downto i*LANES),
            QSFP_RX_N       => QSFP_RX_N(i*LANES+LANES-1 downto i*LANES),
            QSFP_TX_P       => QSFP_TX_P(i*LANES+LANES-1 downto i*LANES),
            QSFP_TX_N       => QSFP_TX_N(i*LANES+LANES-1 downto i*LANES),
            -- RX interface (packets for transmit to Ethernet, recieved from TX MAC lite)
            RX_MFB_DATA     => tx_mac_lite_tx_data   (i),
            RX_MFB_SOF_POS  => tx_mac_lite_tx_sof_pos(i),
            RX_MFB_EOF_POS  => tx_mac_lite_tx_eof_pos(i),
            RX_MFB_SOF      => tx_mac_lite_tx_sof    (i),
            RX_MFB_EOF      => tx_mac_lite_tx_eof    (i),
            RX_MFB_SRC_RDY  => tx_mac_lite_tx_src_rdy(i),
            RX_MFB_DST_RDY  => tx_mac_lite_tx_dst_rdy(i),

            -- TX interface (packets received from Ethernet, transmit to RX MAC lite)
            TX_MFB_DATA     => rx_mac_lite_rx_data   (i),
            TX_MFB_ERROR    => rx_mac_lite_rx_error  (i),
            TX_MFB_SOF_POS  => rx_mac_lite_rx_sof_pos(i),
            TX_MFB_EOF_POS  => rx_mac_lite_rx_eof_pos(i),
            TX_MFB_SOF      => rx_mac_lite_rx_sof    (i),
            TX_MFB_EOF      => rx_mac_lite_rx_eof    (i),
            TX_MFB_SRC_RDY  => rx_mac_lite_rx_src_rdy(i),

            TSU_CLK         => tsu_clk_vec(i),
            TSU_RST         => tsu_rst_vec(i),

            -- Control/status - not located in the core, TODO?
            -- REPEATER_CTRL         => REPEATER_CTRL(i*2+1 downto i*2),
            -- PORT_ENABLED          => PORT_ENABLED(i),
            -- ACTIVITY_RX           => ACTIVITY_RX(i),
            -- ACTIVITY_TX           => ACTIVITY_TX(i),
            -- LINK_UP               => LINK(i),
            -- MI interface
            MI_CLK_PHY      => MI_CLK,
            MI_RESET_PHY    => MI_RESET,
            MI_DWR_PHY      => mi_split_dwr_phy (i+1),
            MI_ADDR_PHY     => mi_split_addr_phy(i+1),
            MI_BE_PHY       => mi_split_be_phy  (i+1),
            MI_RD_PHY       => mi_split_rd_phy  (i+1),
            MI_WR_PHY       => mi_split_wr_phy  (i+1),
            MI_DRD_PHY      => mi_split_drd_phy (i+1),
            MI_ARDY_PHY     => mi_split_ardy_phy(i+1),
            MI_DRDY_PHY     => mi_split_drdy_phy(i+1)
        );

        -- =====================================================================
        -- RX path
        -- =====================================================================
        mac_lites_g : for j in ETH_CHANNELS-1 downto 0 generate
            rx_mac_lite_i : entity work.RX_MAC_LITE
            generic map(
                RX_REGIONS      => REGIONS_CORE    ,
                RX_REGION_SIZE  => REGION_SIZE_CORE,
                RX_BLOCK_SIZE   => BLOCK_SIZE      ,
                RX_ITEM_WIDTH   => ITEM_WIDTH      ,
                TX_REGIONS      => REGIONS         ,
                TX_REGION_SIZE  => REGION_SIZE     ,
                TX_BLOCK_SIZE   => BLOCK_SIZE      ,
                TX_ITEM_WIDTH   => ITEM_WIDTH      ,
                RESIZE_BUFFER   => F_TILE_DEVICE   ,
                NETWORK_PORT_ID => i*ETH_CHANNELS+j,
                CRC_IS_RECEIVED => false           ,
                CRC_CHECK_EN    => false           ,
                CRC_REMOVE_EN   => false           ,
                MAC_CHECK_EN    => true            ,
                MAC_COUNT       => 16              ,
                TIMESTAMP_EN    => true            ,
                DEVICE          => DEVICE
            )
            port map(
                RX_CLK          => CLK_ETH (i)  ,
                RX_RESET        => repl_rst(i*(3+ETH_CHANNELS*2)+j*2+4),
                TX_CLK          => CLK_USER     ,
                TX_RESET        => RESET_USER(0),

                RX_MFB_DATA     => rx_mac_lite_rx_data   (i)(j),
                RX_MFB_SOF      => rx_mac_lite_rx_sof    (i)(j),
                RX_MFB_EOF      => rx_mac_lite_rx_eof    (i)(j),
                RX_MFB_SOF_POS  => rx_mac_lite_rx_sof_pos(i)(j),
                RX_MFB_EOF_POS  => rx_mac_lite_rx_eof_pos(i)(j),
                RX_MFB_ERROR    => rx_mac_lite_rx_error  (i)(j),
                RX_MFB_SRC_RDY  => rx_mac_lite_rx_src_rdy(i)(j),

                ADAPTER_LINK_UP => '1', --TODO

                TSU_TS_NS       => asfifox_ts_ns(i),
                TSU_TS_DV       => asfifox_ts_dv(i),

                TX_MFB_DATA     => merg_rx_mfb_data   (i)(j),
                TX_MFB_SOF      => merg_rx_mfb_sof    (i)(j),
                TX_MFB_EOF      => merg_rx_mfb_eof    (i)(j),
                TX_MFB_SOF_POS  => merg_rx_mfb_sof_pos(i)(j),
                TX_MFB_EOF_POS  => merg_rx_mfb_eof_pos(i)(j),
                TX_MFB_SRC_RDY  => merg_rx_mfb_src_rdy(i)(j),
                TX_MFB_DST_RDY  => merg_rx_mfb_dst_rdy(i)(j),
                TX_MVB_DATA     => merg_rx_mvb_data   (i)(j),
                TX_MVB_VLD      => merg_rx_mvb_vld    (i)(j),
                TX_MVB_SRC_RDY  => merg_rx_mvb_src_rdy(i)(j),
                TX_MVB_DST_RDY  => merg_rx_mvb_dst_rdy(i)(j),

                --LINK_UP         => LINK_UP,
                INCOMING_FRAME  => open,

                MI_CLK          => MI_CLK  ,
                MI_RESET        => MI_RESET,
                MI_DWR          => mi_split_dwr (i*ETH_CHANNELS*2+j*2+1),
                MI_ADDR         => mi_split_addr(i*ETH_CHANNELS*2+j*2+1),
                MI_RD           => mi_split_rd  (i*ETH_CHANNELS*2+j*2+1),
                MI_WR           => mi_split_wr  (i*ETH_CHANNELS*2+j*2+1),
                MI_BE           => mi_split_be  (i*ETH_CHANNELS*2+j*2+1),
                MI_DRD          => mi_split_drd (i*ETH_CHANNELS*2+j*2+1),
                MI_ARDY         => mi_split_ardy(i*ETH_CHANNELS*2+j*2+1),
                MI_DRDY         => mi_split_drdy(i*ETH_CHANNELS*2+j*2+1)
            );
        end generate;

        -- Merge all ETH_CHANNELS into one ETH_STREAM
        mfb_merger_tree_i : entity work.MFB_MERGER_GEN
        generic map(
            MERGER_INPUTS   => ETH_CHANNELS    ,
            MVB_ITEMS       => REGIONS         ,
            MVB_ITEM_WIDTH  => ETH_RX_HDR_WIDTH,
            MFB_REGIONS     => REGIONS         ,
            MFB_REG_SIZE    => REGION_SIZE     ,
            MFB_BLOCK_SIZE  => BLOCK_SIZE      ,
            MFB_ITEM_WIDTH  => ITEM_WIDTH      ,
            INPUT_FIFO_SIZE => 8               ,
            RX_PAYLOAD_EN   => (others => true),
            IN_PIPE_EN      => true            ,
            OUT_PIPE_EN     => true            ,
            DEVICE          => DEVICE
        )
        port map(
            CLK             => CLK_USER              ,
            RESET           => RESET_USER(0)         ,

            RX_MFB_DATA     => merg_rx_mfb_data   (i),
            RX_MFB_SOF      => merg_rx_mfb_sof    (i),
            RX_MFB_EOF      => merg_rx_mfb_eof    (i),
            RX_MFB_SOF_POS  => merg_rx_mfb_sof_pos(i),
            RX_MFB_EOF_POS  => merg_rx_mfb_eof_pos(i),
            RX_MFB_SRC_RDY  => merg_rx_mfb_src_rdy(i),
            RX_MFB_DST_RDY  => merg_rx_mfb_dst_rdy(i),

            RX_MVB_DATA     => merg_rx_mvb_data   (i),
            RX_MVB_PAYLOAD  => (others => (others => '1')),
            RX_MVB_VLD      => merg_rx_mvb_vld    (i),
            RX_MVB_SRC_RDY  => merg_rx_mvb_src_rdy(i),
            RX_MVB_DST_RDY  => merg_rx_mvb_dst_rdy(i),

            TX_MFB_DATA     => TX_MFB_DATA_arr    (i),
            TX_MFB_SOF      => TX_MFB_SOF_arr     (i),
            TX_MFB_EOF      => TX_MFB_EOF_arr     (i),
            TX_MFB_SOF_POS  => TX_MFB_SOF_POS_arr (i),
            TX_MFB_EOF_POS  => TX_MFB_EOF_POS_arr (i),
            TX_MFB_SRC_RDY  => TX_MFB_SRC_RDY     (i),
            TX_MFB_DST_RDY  => TX_MFB_DST_RDY     (i),

            TX_MVB_DATA     => TX_MVB_DATA_arr    (i),
            TX_MVB_VLD      => TX_MVB_VLD_arr     (i),
            TX_MVB_SRC_RDY  => TX_MVB_SRC_RDY     (i),
            TX_MVB_DST_RDY  => TX_MVB_DST_RDY     (i)
        );

        TX_MFB_DATA    <= slv_array_ser(TX_MFB_DATA_arr);
        TX_MFB_SOF     <= slv_array_ser(TX_MFB_SOF_arr);
        TX_MFB_EOF     <= slv_array_ser(TX_MFB_EOF_arr);
        TX_MFB_SOF_POS <= slv_array_ser(TX_MFB_SOF_POS_arr);
        TX_MFB_EOF_POS <= slv_array_ser(TX_MFB_EOF_POS_arr);

        TX_MVB_DATA <= slv_array_ser(TX_MVB_DATA_arr);
        TX_MVB_VLD  <= slv_array_ser(TX_MVB_VLD_arr);

        -- =====================================================================
        -- ASFIFOX
        -- =====================================================================
        asfifox_i : entity work.ASFIFOX
        generic map(
            DATA_WIDTH => 64    ,
            ITEMS      => 32    ,
            RAM_TYPE   => "LUT" ,
            FWFT_MODE  => true  ,
            OUTPUT_REG => true  ,
            DEVICE     => DEVICE
        )
        port map (
            WR_CLK    => tsu_clk_vec(0),
            WR_RST    => tsu_rst_vec(0),
            WR_DATA   => TSU_TS_NS     ,
            WR_EN     => TSU_TS_DV     ,
            WR_FULL   => open          ,
            WR_AFULL  => open          ,
            WR_STATUS => open          ,

            RD_CLK    => CLK_ETH        (i),
            RD_RST    => RESET_ETH      (i),
            RD_DATA   => asfifox_rd_data(i),
            RD_EN     => '1'               ,
            RD_EMPTY  => asfifox_empty  (i),
            RD_AEMPTY => open              ,
            RD_STATUS => open
        );

        asfifox_rd_data_reg_p: process(CLK_ETH)
        begin
            if (rising_edge(CLK_ETH(i))) then
                asfifox_ts_dv(i) <= asfifox_empty(i);
                asfifox_ts_ns(i) <= asfifox_rd_data(i);
            end if;
        end process;

        TSU_CLK <= tsu_clk_vec(0);
        TSU_RST <= tsu_rst_vec(0);

    end generate;

    -- =====================================================================
    -- QSOF control
    -- =====================================================================
    qsfp_ctrl_i : entity work.QSFP_CTRL
    generic map (
       QSFP_PORTS          => 2,
       QSFP_I2C_PORTS      => 1,
       FPC202_INIT_EN      => FPC202_INIT_EN
    )
    port map (
       RST            => MI_RESET_PHY   ,
       --
       TX_READY       => (others => '1'),
       -- QSFP control/status
       QSFP_MODSEL_N  => open           ,
       QSFP_LPMODE    => open           ,
       QSFP_RESET_N   => open           ,
       QSFP_MODPRS_N  => (others => '0'),
       QSFP_INT_N     => (others => '0'),
       QSFP_I2C_SCL   => QSFP_I2C_SCL   ,
       QSFP_I2C_SDA   => QSFP_I2C_SDA   ,
       QSFP_I2C_DIR   => open           ,
       -- Select which QSFP port is targetting during MI read/writes
       MI_QSFP_SEL    => (others => '0'),
       -- MI interface
       MI_CLK_PHY     => MI_CLK_PHY          ,
       MI_RESET_PHY   => MI_RESET_PHY        ,
       MI_DWR_PHY     => mi_split_dwr_phy (0),
       MI_ADDR_PHY    => mi_split_addr_phy(0),
       MI_RD_PHY      => mi_split_rd_phy  (0),
       MI_WR_PHY      => mi_split_wr_phy  (0),
       MI_BE_PHY      => mi_split_be_phy  (0),
       MI_DRD_PHY     => mi_split_drd_phy (0),
       MI_ARDY_PHY    => mi_split_ardy_phy(0),
       MI_DRDY_PHY    => mi_split_drdy_phy(0)
    );

end architecture;
