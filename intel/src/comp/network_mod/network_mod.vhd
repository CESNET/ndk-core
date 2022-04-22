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

    constant REGIONS_CORE      : natural := tsel(ETH_PORT_SPEED(0) = 400, 2, 1); -- TODO: support different speeds/number of channels for each port
    constant REGION_SIZE_CORE  : natural := region_size_core_f;

    constant ETH_CHANNELS      : integer := ETH_PORT_CHAN(0); -- TODO: support different speeds/number of channels for each port
    --                                      Network mod core, ETH_CHANNELS x (TX MAC lite, RX MAC lite)
    constant RESET_REPLICAS    : natural := 1               + ETH_CHANNELS * (1          + 1          );

    constant PORTS_OFF         : std_logic_vector(MI_ADDR_WIDTH-1 downto 0) := X"0000_2000";
    constant MI_ADDR_BASES     : natural := ETH_PORTS;
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
                when others => return 0;
            end case;
        elsif (BOARD = "DK-DEV-1SDX-P") then
            case ETH_PORT_SPEED(0) is
                when 100    => return 8;
                when 25     => return 1;
                when 10     => return 1;
                when others => return 0;
            end case;
        else
            return 0;
        end if;
    end function;

    function mi_addr_base_init_f return slv_array_t is
        variable mi_addr_base_var : slv_array_t(MI_ADDR_BASES-1 downto 0)(MI_ADDR_WIDTH-1 downto 0);
    begin
        for i in 0 to MI_ADDR_BASES-1 loop
            mi_addr_base_var(i) := std_logic_vector(resize(i*unsigned(PORTS_OFF), MI_ADDR_WIDTH));
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
    signal repl_rst_arr : slv_array_t(ETH_PORTS-1 downto 0)(RESET_REPLICAS-1 downto 0);

    -- Interior signals, Network Module Core -> Network Module Logic
    signal rx_mfb_data_i    : slv_array_2d_t(ETH_PORTS-1 downto 0)(ETH_CHANNELS-1 downto 0)(MFB_WIDTH_CORE-1 downto 0);
    signal rx_mfb_sof_pos_i : slv_array_2d_t(ETH_PORTS-1 downto 0)(ETH_CHANNELS-1 downto 0)(MFB_SOFP_WIDTH_CORE-1 downto 0);
    signal rx_mfb_eof_pos_i : slv_array_2d_t(ETH_PORTS-1 downto 0)(ETH_CHANNELS-1 downto 0)(MFB_EOFP_WIDTH_CORE-1 downto 0);
    signal rx_mfb_sof_i     : slv_array_2d_t(ETH_PORTS-1 downto 0)(ETH_CHANNELS-1 downto 0)(REGIONS_CORE-1 downto 0);
    signal rx_mfb_eof_i     : slv_array_2d_t(ETH_PORTS-1 downto 0)(ETH_CHANNELS-1 downto 0)(REGIONS_CORE-1 downto 0);
    signal rx_mfb_error_i   : slv_array_2d_t(ETH_PORTS-1 downto 0)(ETH_CHANNELS-1 downto 0)(REGIONS_CORE-1 downto 0);
    signal rx_mfb_src_rdy_i : slv_array_t   (ETH_PORTS-1 downto 0)(ETH_CHANNELS-1 downto 0);

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

    -- Deserialized input for TX MAC lite(s)
    signal RX_MFB_DATA_arr      :  slv_array_t(ETH_PORTS-1 downto 0)(MFB_WIDTH-1 downto 0);
    signal RX_MFB_HDR_arr       :  slv_array_t(ETH_PORTS-1 downto 0)(REGIONS*ETH_TX_HDR_WIDTH-1 downto 0);
    signal RX_MFB_SOF_arr       :  slv_array_t(ETH_PORTS-1 downto 0)(REGIONS-1 downto 0);
    signal RX_MFB_EOF_arr       :  slv_array_t(ETH_PORTS-1 downto 0)(REGIONS-1 downto 0);
    signal RX_MFB_SOF_POS_arr   :  slv_array_t(ETH_PORTS-1 downto 0)(MFB_SOFP_WIDTH-1 downto 0);
    signal RX_MFB_EOF_POS_arr   :  slv_array_t(ETH_PORTS-1 downto 0)(MFB_EOFP_WIDTH-1 downto 0);

    -- Interior signals, Network Module Logic -> Network Module Core
    signal tx_mfb_data_i    : slv_array_2d_t(ETH_PORTS-1 downto 0)(ETH_CHANNELS-1 downto 0)(MFB_WIDTH_CORE-1 downto 0);
    signal tx_mfb_sof_i     : slv_array_2d_t(ETH_PORTS-1 downto 0)(ETH_CHANNELS-1 downto 0)(REGIONS_CORE-1 downto 0);
    signal tx_mfb_eof_i     : slv_array_2d_t(ETH_PORTS-1 downto 0)(ETH_CHANNELS-1 downto 0)(REGIONS_CORE-1 downto 0);
    signal tx_mfb_sof_pos_i : slv_array_2d_t(ETH_PORTS-1 downto 0)(ETH_CHANNELS-1 downto 0)(MFB_SOFP_WIDTH_CORE-1 downto 0);
    signal tx_mfb_eof_pos_i : slv_array_2d_t(ETH_PORTS-1 downto 0)(ETH_CHANNELS-1 downto 0)(MFB_EOFP_WIDTH_CORE-1 downto 0);
    signal tx_mfb_src_rdy_i : slv_array_t   (ETH_PORTS-1 downto 0)(ETH_CHANNELS-1 downto 0);
    signal tx_mfb_dst_rdy_i : slv_array_t   (ETH_PORTS-1 downto 0)(ETH_CHANNELS-1 downto 0);

    -- MI for MAC lites
    signal mi_split_dwr  : slv_array_t     (MI_ADDR_BASES-1 downto 0)(MI_DATA_WIDTH-1 downto 0);
    signal mi_split_addr : slv_array_t     (MI_ADDR_BASES-1 downto 0)(MI_ADDR_WIDTH-1 downto 0);
    signal mi_split_be   : slv_array_t     (MI_ADDR_BASES-1 downto 0)(MI_DATA_WIDTH/8-1 downto 0);
    signal mi_split_rd   : std_logic_vector(MI_ADDR_BASES-1 downto 0);
    signal mi_split_wr   : std_logic_vector(MI_ADDR_BASES-1 downto 0);
    signal mi_split_ardy : std_logic_vector(MI_ADDR_BASES-1 downto 0);
    signal mi_split_drd  : slv_array_t     (MI_ADDR_BASES-1 downto 0)(MI_DATA_WIDTH-1 downto 0);
    signal mi_split_drdy : std_logic_vector(MI_ADDR_BASES-1 downto 0);

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
    ports_reset_g : for p in ETH_PORTS-1 downto 0 generate
        network_mod_reset_i : entity work.ASYNC_RESET
        generic map (
            TWO_REG  => false,
            OUT_REG  => true ,
            REPLICAS => RESET_REPLICAS
        )
        port map (
            CLK         => CLK_ETH     (p),
            ASYNC_RST   => RESET_ETH   (p),
            OUT_RST     => repl_rst_arr(p)
        );
    end generate;

    -- =========================================================================
    --  MI SPLITTER for Network Module Logic (MAC Lites)
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
        -- Common interface ----------
        CLK         => MI_CLK         ,
        RESET       => MI_RESET       ,
        -- Input MI interface --------
        RX_DWR      => MI_DWR         ,
        RX_MWR      => (others => '0'),
        RX_ADDR     => MI_ADDR        ,
        RX_BE       => MI_BE          ,
        RX_RD       => MI_RD          ,
        RX_WR       => MI_WR          ,
        RX_ARDY     => MI_ARDY        ,
        RX_DRD      => MI_DRD         ,
        RX_DRDY     => MI_DRDY        ,
        -- Output MI interfaces ------
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
    --  MI SPLITTER for reconfiguration of the E/F-Tile(s) and QSFP Control
    -- =========================================================================
    -- QSFP_CTRL is at Port(0), addresses from X"0080_0000" to X"0080_1000",
    -- the rest of the Ports is for Network Module Core(s) with IA_OFF offset.
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
        -- Common interface -----------
        CLK         => MI_CLK_PHY      ,
        RESET       => MI_RESET_PHY    ,
        -- Input MI interface ---------
        RX_DWR      => MI_DWR_PHY      ,
        RX_MWR      => (others => '0') ,
        RX_ADDR     => MI_ADDR_PHY     ,
        RX_BE       => MI_BE_PHY       ,
        RX_RD       => MI_RD_PHY       ,
        RX_WR       => MI_WR_PHY       ,
        RX_ARDY     => MI_ARDY_PHY     ,
        RX_DRD      => MI_DRD_PHY      ,
        RX_DRDY     => MI_DRDY_PHY     ,
        -- Output MI interfaces -------
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
    RX_MFB_SOF_POS_arr <= slv_array_downto_deser(RX_MFB_SOF_POS, ETH_PORTS);
    RX_MFB_EOF_POS_arr <= slv_array_downto_deser(RX_MFB_EOF_POS, ETH_PORTS);
    RX_MFB_SOF_arr     <= slv_array_downto_deser(RX_MFB_SOF    , ETH_PORTS);
    RX_MFB_EOF_arr     <= slv_array_downto_deser(RX_MFB_EOF    , ETH_PORTS);

    eth_core_g : for p in 0 to ETH_PORTS-1 generate
        -- =====================================================================
        -- Network Module Logic
        -- =====================================================================
        network_mod_logic_i : entity work.NETWORK_MOD_LOGIC
        generic map(
            -- ETH
            ETH_PORT_CHAN    => ETH_PORT_CHAN(p),
            ETH_PORT_ID      => p               ,
            -- MFB
            USER_REGIONS     => REGIONS         ,
            USER_REGION_SIZE => REGION_SIZE     ,
            CORE_REGIONS     => REGIONS_CORE    ,
            CORE_REGION_SIZE => REGION_SIZE_CORE,
            BLOCK_SIZE       => BLOCK_SIZE      ,
            ITEM_WIDTH       => ITEM_WIDTH      ,
            -- MI
            MI_DATA_WIDTH    => MI_DATA_WIDTH   ,
            MI_ADDR_WIDTH    => MI_ADDR_WIDTH   ,
            -- Other
            RESET_USER_WIDTH => RESET_WIDTH     ,
            RESET_CORE_WIDTH => RESET_REPLICAS-1,
            DEVICE           => DEVICE          ,
            BOARD            => BOARD
        )
        port map(
            CLK_USER        => CLK_USER,
            CLK_CORE        => CLK_ETH(p),
            RESET_USER      => RESET_USER,
            RESET_CORE      => repl_rst_arr(p)(RESET_REPLICAS-1 downto 1),

            -- USER side
            RX_USER_MFB_DATA    => RX_MFB_DATA_arr   (p),
            RX_USER_MFB_HDR     => RX_MFB_HDR_arr    (p),
            RX_USER_MFB_SOF_POS => RX_MFB_SOF_POS_arr(p),
            RX_USER_MFB_EOF_POS => RX_MFB_EOF_POS_arr(p),
            RX_USER_MFB_SOF     => RX_MFB_SOF_arr    (p),
            RX_USER_MFB_EOF     => RX_MFB_EOF_arr    (p),
            RX_USER_MFB_SRC_RDY => RX_MFB_SRC_RDY    (p),
            RX_USER_MFB_DST_RDY => RX_MFB_DST_RDY    (p),

            TX_USER_MFB_DATA    => TX_MFB_DATA_arr   (p),
            TX_USER_MFB_SOF_POS => TX_MFB_SOF_POS_arr(p),
            TX_USER_MFB_EOF_POS => TX_MFB_EOF_POS_arr(p),
            TX_USER_MFB_SOF     => TX_MFB_SOF_arr    (p),
            TX_USER_MFB_EOF     => TX_MFB_EOF_arr    (p),
            TX_USER_MFB_SRC_RDY => TX_MFB_SRC_RDY    (p),
            TX_USER_MFB_DST_RDY => TX_MFB_DST_RDY    (p),
            TX_USER_MVB_DATA    => TX_MVB_DATA_arr   (p),
            TX_USER_MVB_VLD     => TX_MVB_VLD_arr    (p),
            TX_USER_MVB_SRC_RDY => TX_MVB_SRC_RDY    (p),
            TX_USER_MVB_DST_RDY => TX_MVB_DST_RDY    (p),

            -- CORE side
            RX_CORE_MFB_DATA    => rx_mfb_data_i   (p),
            RX_CORE_MFB_SOF_POS => rx_mfb_sof_pos_i(p),
            RX_CORE_MFB_EOF_POS => rx_mfb_eof_pos_i(p),
            RX_CORE_MFB_SOF     => rx_mfb_sof_i    (p),
            RX_CORE_MFB_EOF     => rx_mfb_eof_i    (p),
            RX_CORE_MFB_ERROR   => rx_mfb_error_i  (p),
            RX_CORE_MFB_SRC_RDY => rx_mfb_src_rdy_i(p),

            TX_CORE_MFB_DATA    => tx_mfb_data_i   (p),
            TX_CORE_MFB_SOF_POS => tx_mfb_sof_pos_i(p),
            TX_CORE_MFB_EOF_POS => tx_mfb_eof_pos_i(p),
            TX_CORE_MFB_SOF     => tx_mfb_sof_i    (p),
            TX_CORE_MFB_EOF     => tx_mfb_eof_i    (p),
            TX_CORE_MFB_SRC_RDY => tx_mfb_src_rdy_i(p),
            TX_CORE_MFB_DST_RDY => tx_mfb_dst_rdy_i(p),

            -- MI
            MI_CLK          => MI_CLK          ,
            MI_RESET        => MI_RESET        ,
            MI_DWR          => mi_split_dwr (p),
            MI_ADDR         => mi_split_addr(p),
            MI_RD           => mi_split_rd  (p),
            MI_WR           => mi_split_wr  (p),
            MI_BE           => mi_split_be  (p),
            MI_DRD          => mi_split_drd (p),
            MI_ARDY         => mi_split_ardy(p),
            MI_DRDY         => mi_split_drdy(p),

            TSU_TS_NS       => asfifox_ts_ns(p),
            TSU_TS_DV       => asfifox_ts_dv(p)
        );

        -- =====================================================================
        -- Network Module Core
        -- =====================================================================    
        network_mod_core_i: entity work.NETWORK_MOD_CORE 
        generic map (
            ETH_PORT_SPEED    => ETH_PORT_SPEED(p),
            ETH_PORT_CHAN     => ETH_PORT_CHAN (p),
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
            CLK_ETH         => CLK_ETH(p),
            RESET_ETH       => repl_rst_arr(p)(0),
            -- QSFP interface
            QSFP_REFCLK_P   => QSFP_REFCLK_P(p)                         ,
            QSFP_RX_P       => QSFP_RX_P(p*LANES+LANES-1 downto p*LANES),
            QSFP_RX_N       => QSFP_RX_N(p*LANES+LANES-1 downto p*LANES),
            QSFP_TX_P       => QSFP_TX_P(p*LANES+LANES-1 downto p*LANES),
            QSFP_TX_N       => QSFP_TX_N(p*LANES+LANES-1 downto p*LANES),
            -- RX interface (packets for transmit to Ethernet, recieved from TX MAC lite)
            RX_MFB_DATA     => tx_mfb_data_i   (p),
            RX_MFB_SOF_POS  => tx_mfb_sof_pos_i(p),
            RX_MFB_EOF_POS  => tx_mfb_eof_pos_i(p),
            RX_MFB_SOF      => tx_mfb_sof_i    (p),
            RX_MFB_EOF      => tx_mfb_eof_i    (p),
            RX_MFB_SRC_RDY  => tx_mfb_src_rdy_i(p),
            RX_MFB_DST_RDY  => tx_mfb_dst_rdy_i(p),

            -- TX interface (packets received from Ethernet, transmit to RX MAC lite)
            TX_MFB_DATA     => rx_mfb_data_i   (p),
            TX_MFB_SOF_POS  => rx_mfb_sof_pos_i(p),
            TX_MFB_EOF_POS  => rx_mfb_eof_pos_i(p),
            TX_MFB_SOF      => rx_mfb_sof_i    (p),
            TX_MFB_EOF      => rx_mfb_eof_i    (p),
            TX_MFB_ERROR    => rx_mfb_error_i  (p),
            TX_MFB_SRC_RDY  => rx_mfb_src_rdy_i(p),

            TSU_CLK         => tsu_clk_vec(p),
            TSU_RST         => tsu_rst_vec(p), -- useless port

            -- Control/status - not located in the core, TODO?
            -- REPEATER_CTRL         => REPEATER_CTRL(p*2+1 downto p*2),
            -- PORT_ENABLED          => PORT_ENABLED(p),
            -- ACTIVITY_RX           => ACTIVITY_RX(p),
            -- ACTIVITY_TX           => ACTIVITY_TX(p),
            -- LINK_UP               => LINK(p),
            -- MI interface
            MI_CLK_PHY      => MI_CLK,
            MI_RESET_PHY    => MI_RESET,
            MI_DWR_PHY      => mi_split_dwr_phy (p+1),
            MI_ADDR_PHY     => mi_split_addr_phy(p+1),
            MI_BE_PHY       => mi_split_be_phy  (p+1),
            MI_RD_PHY       => mi_split_rd_phy  (p+1),
            MI_WR_PHY       => mi_split_wr_phy  (p+1),
            MI_DRD_PHY      => mi_split_drd_phy (p+1),
            MI_ARDY_PHY     => mi_split_ardy_phy(p+1),
            MI_DRDY_PHY     => mi_split_drdy_phy(p+1)
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

            RD_CLK    => CLK_ETH        (p),
            RD_RST    => RESET_ETH      (p),
            RD_DATA   => asfifox_rd_data(p),
            RD_EN     => '1'               ,
            RD_EMPTY  => asfifox_empty  (p),
            RD_AEMPTY => open              ,
            RD_STATUS => open
        );

        asfifox_rd_data_reg_p: process(CLK_ETH)
        begin
            if (rising_edge(CLK_ETH(p))) then
                asfifox_ts_dv(p) <= asfifox_empty(p);
                asfifox_ts_ns(p) <= asfifox_rd_data(p);
            end if;
        end process;

        TSU_CLK <= tsu_clk_vec(0);
        TSU_RST <= tsu_rst_vec(0);

    end generate;

    -- =====================================================================
    -- QSFP control
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
