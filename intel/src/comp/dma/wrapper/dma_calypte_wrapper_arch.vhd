-- dma_calypte_wrapper_arch.vhd: DMA Calypte Module Wrapper
-- Copyright (C) 2022 CESNET z. s. p. o.
-- Author(s): Vladislav Valek <valekv@cesnet.cz>
--
-- SPDX-License-Identifier: BSD-3-Clause

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.math_pack.all;
use work.type_pack.all;

use work.dma_bus_pack.all;

architecture CALYPTE of DMA_WRAPPER is

    --==============================================================================================
    --  MI Async and Splitting
    --==============================================================================================
    -- specifies the number of ports outside the MI splitter
    constant MI_SPLIT_PORTS : natural := 2;
    constant OUT_PIPE_EN : boolean := TRUE;

    -- MI split for DMA 0 and TSU
    signal mi_dmagen_dwr  : slv_array_2d_t(PCIE_ENDPOINTS -1 downto 0)(MI_SPLIT_PORTS -1 downto 0)(32-1 downto 0);
    signal mi_dmagen_addr : slv_array_2d_t(PCIE_ENDPOINTS -1 downto 0)(MI_SPLIT_PORTS -1 downto 0)(32-1 downto 0);
    signal mi_dmagen_be   : slv_array_2d_t(PCIE_ENDPOINTS -1 downto 0)(MI_SPLIT_PORTS -1 downto 0)(4-1 downto 0);
    signal mi_dmagen_rd   : slv_array_t(PCIE_ENDPOINTS -1 downto 0)(MI_SPLIT_PORTS -1 downto 0);
    signal mi_dmagen_wr   : slv_array_t(PCIE_ENDPOINTS -1 downto 0)(MI_SPLIT_PORTS -1 downto 0);
    signal mi_dmagen_drd  : slv_array_2d_t(PCIE_ENDPOINTS -1 downto 0)(MI_SPLIT_PORTS -1 downto 0)(32-1 downto 0);
    signal mi_dmagen_ardy : slv_array_t(PCIE_ENDPOINTS -1 downto 0)(MI_SPLIT_PORTS -1 downto 0);
    signal mi_dmagen_drdy : slv_array_t(PCIE_ENDPOINTS -1 downto 0)(MI_SPLIT_PORTS -1 downto 0);

    -- MI clocked on PCIE_CLOCK
    signal mi_sync_dwr  : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(32-1 downto 0);
    signal mi_sync_addr : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(32-1 downto 0);
    signal mi_sync_be   : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(4-1 downto 0);
    signal mi_sync_rd   : std_logic_vector(PCIE_ENDPOINTS-1 downto 0);
    signal mi_sync_wr   : std_logic_vector(PCIE_ENDPOINTS-1 downto 0);
    signal mi_sync_drd  : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(32-1 downto 0);
    signal mi_sync_ardy : std_logic_vector(PCIE_ENDPOINTS-1 downto 0);
    signal mi_sync_drdy : std_logic_vector(PCIE_ENDPOINTS-1 downto 0);
    --==============================================================================================


    --==============================================================================================
    -- Metadata insertor ---> FIFOX
    --==============================================================================================
    signal rx_usr_mfb_data_async      : slv_array_t(DMA_STREAMS-1 downto 0)(USR_MFB_REGIONS*USR_MFB_REGION_SIZE*USR_MFB_BLOCK_SIZE*USR_MFB_ITEM_WIDTH -1 downto 0);
    signal rx_usr_mfb_meta_async      : slv_array_t(DMA_STREAMS-1 downto 0)(log2(USR_RX_PKT_SIZE_MAX +1)+log2(RX_CHANNELS)+HDR_META_WIDTH                -1 downto 0);
    signal rx_usr_mfb_sof_async       : slv_array_t(DMA_STREAMS-1 downto 0)(USR_MFB_REGIONS                                                           -1 downto 0);
    signal rx_usr_mfb_eof_async       : slv_array_t(DMA_STREAMS-1 downto 0)(USR_MFB_REGIONS                                                           -1 downto 0);
    signal rx_usr_mfb_sof_pos_async   : slv_array_t(DMA_STREAMS-1 downto 0)(USR_MFB_REGIONS*max(1,log2(USR_MFB_REGION_SIZE))                          -1 downto 0);
    signal rx_usr_mfb_eof_pos_async   : slv_array_t(DMA_STREAMS-1 downto 0)(USR_MFB_REGIONS*max(1,log2(USR_MFB_REGION_SIZE*USR_MFB_BLOCK_SIZE))       -1 downto 0);
    signal rx_usr_mfb_src_rdy_async   : std_logic_vector(DMA_STREAMS-1 downto 0);
    signal rx_usr_mfb_dst_rdy_async   : std_logic_vector(DMA_STREAMS-1 downto 0);
    --==============================================================================================

    --==============================================================================================
    -- FIFOX ---> Metadata extractor
    --==============================================================================================
    signal tx_usr_mfb_data_async      : slv_array_t(DMA_STREAMS-1 downto 0)(USR_MFB_REGIONS*USR_MFB_REGION_SIZE*USR_MFB_BLOCK_SIZE*USR_MFB_ITEM_WIDTH-1 downto 0);
    signal tx_usr_mfb_meta_async      : slv_array_t(DMA_STREAMS-1 downto 0)(log2(USR_TX_PKT_SIZE_MAX+1)+HDR_META_WIDTH+log2(TX_CHANNELS)                -1 downto 0);
    signal tx_usr_mfb_sof_async       : slv_array_t(DMA_STREAMS-1 downto 0)(USR_MFB_REGIONS                                                          -1 downto 0);
    signal tx_usr_mfb_eof_async       : slv_array_t(DMA_STREAMS-1 downto 0)(USR_MFB_REGIONS                                                          -1 downto 0);
    signal tx_usr_mfb_sof_pos_async   : slv_array_t(DMA_STREAMS-1 downto 0)(USR_MFB_REGIONS*max(1,log2(USR_MFB_REGION_SIZE))                         -1 downto 0);
    signal tx_usr_mfb_eof_pos_async   : slv_array_t(DMA_STREAMS-1 downto 0)(USR_MFB_REGIONS*max(1,log2(USR_MFB_REGION_SIZE*USR_MFB_BLOCK_SIZE))      -1 downto 0);
    signal tx_usr_mfb_src_rdy_async   : std_logic_vector(DMA_STREAMS-1 downto 0);
    signal tx_usr_mfb_dst_rdy_async   : std_logic_vector(DMA_STREAMS-1 downto 0);
    --==============================================================================================

    --==============================================================================================
    --  MFB ASFIFOX ---> DMA Module interface
    --==============================================================================================
    signal rx_usr_mfb_meta_len       : slv_array_t(DMA_STREAMS-1 downto 0)(log2(USR_RX_PKT_SIZE_MAX+1)-1 downto 0);
    signal rx_usr_mfb_meta_hdr_meta  : slv_array_t(DMA_STREAMS-1 downto 0)(HDR_META_WIDTH          -1 downto 0);
    signal rx_usr_mfb_meta_channel   : slv_array_t(DMA_STREAMS-1 downto 0)(log2(RX_CHANNELS)       -1 downto 0);

    signal rx_usr_mfb_data_sync      : slv_array_t(DMA_STREAMS-1 downto 0)(USR_MFB_REGIONS*USR_MFB_REGION_SIZE*USR_MFB_BLOCK_SIZE*USR_MFB_ITEM_WIDTH-1 downto 0);
    signal rx_usr_mfb_meta_sync      : slv_array_t(DMA_STREAMS-1 downto 0)(log2(USR_RX_PKT_SIZE_MAX+1)+HDR_META_WIDTH+log2(RX_CHANNELS)                -1 downto 0);
    signal rx_usr_mfb_sof_sync       : slv_array_t(DMA_STREAMS-1 downto 0)(USR_MFB_REGIONS                                                          -1 downto 0);
    signal rx_usr_mfb_eof_sync       : slv_array_t(DMA_STREAMS-1 downto 0)(USR_MFB_REGIONS                                                          -1 downto 0);
    signal rx_usr_mfb_sof_pos_sync   : slv_array_t(DMA_STREAMS-1 downto 0)(USR_MFB_REGIONS*max(1,log2(USR_MFB_REGION_SIZE))                         -1 downto 0);
    signal rx_usr_mfb_eof_pos_sync   : slv_array_t(DMA_STREAMS-1 downto 0)(USR_MFB_REGIONS*max(1,log2(USR_MFB_REGION_SIZE*USR_MFB_BLOCK_SIZE))      -1 downto 0);
    signal rx_usr_mfb_src_rdy_sync   : std_logic_vector(DMA_STREAMS-1 downto 0);
    signal rx_usr_mfb_dst_rdy_sync   : std_logic_vector(DMA_STREAMS-1 downto 0);
    --==============================================================================================

    --==============================================================================================
    --  DMA Module ---> MFB ASFIFOX interface
    --==============================================================================================
    signal tx_usr_mfb_meta_len       : slv_array_t(DMA_STREAMS-1 downto 0)(log2(USR_TX_PKT_SIZE_MAX+1)-1 downto 0);
    signal tx_usr_mfb_meta_hdr_meta  : slv_array_t(DMA_STREAMS-1 downto 0)(HDR_META_WIDTH          -1 downto 0);
    signal tx_usr_mfb_meta_channel   : slv_array_t(DMA_STREAMS-1 downto 0)(log2(TX_CHANNELS)       -1 downto 0);

    signal tx_usr_mfb_data_sync      : slv_array_t(DMA_STREAMS-1 downto 0)(USR_MFB_REGIONS*USR_MFB_REGION_SIZE*USR_MFB_BLOCK_SIZE*USR_MFB_ITEM_WIDTH-1 downto 0);
    signal tx_usr_mfb_sof_sync       : slv_array_t(DMA_STREAMS-1 downto 0)(USR_MFB_REGIONS                                                          -1 downto 0);
    signal tx_usr_mfb_eof_sync       : slv_array_t(DMA_STREAMS-1 downto 0)(USR_MFB_REGIONS                                                          -1 downto 0);
    signal tx_usr_mfb_sof_pos_sync   : slv_array_t(DMA_STREAMS-1 downto 0)(USR_MFB_REGIONS*max(1,log2(USR_MFB_REGION_SIZE))                         -1 downto 0);
    signal tx_usr_mfb_eof_pos_sync   : slv_array_t(DMA_STREAMS-1 downto 0)(USR_MFB_REGIONS*max(1,log2(USR_MFB_REGION_SIZE*USR_MFB_BLOCK_SIZE))      -1 downto 0);
    signal tx_usr_mfb_src_rdy_sync   : std_logic_vector(DMA_STREAMS-1 downto 0);
    signal tx_usr_mfb_dst_rdy_sync   : std_logic_vector(DMA_STREAMS-1 downto 0);
    --==============================================================================================

    signal up_mfb_data_piped      : slv_array_t(DMA_STREAMS-1 downto 0)(UP_MFB_REGIONS*UP_MFB_REGION_SIZE*UP_MFB_BLOCK_SIZE*UP_MFB_ITEM_WIDTH -1 downto 0);
    signal up_mfb_sof_piped       : slv_array_t(DMA_STREAMS-1 downto 0)(UP_MFB_REGIONS                                                        -1 downto 0);
    signal up_mfb_eof_piped       : slv_array_t(DMA_STREAMS-1 downto 0)(UP_MFB_REGIONS                                                        -1 downto 0);
    signal up_mfb_sof_pos_piped   : slv_array_t(DMA_STREAMS-1 downto 0)(UP_MFB_REGIONS*max(1,log2(UP_MFB_REGION_SIZE))                        -1 downto 0);
    signal up_mfb_eof_pos_piped   : slv_array_t(DMA_STREAMS-1 downto 0)(UP_MFB_REGIONS*max(1,log2(UP_MFB_REGION_SIZE*UP_MFB_BLOCK_SIZE))      -1 downto 0);
    signal up_mfb_src_rdy_piped   : std_logic_vector(DMA_STREAMS-1 downto 0);
    signal up_mfb_dst_rdy_piped   : std_logic_vector(DMA_STREAMS-1 downto 0);

    --==============================================================================================
    -- Miscelaneous signals
    --==============================================================================================
    -- concatenated metadata on the output of the metadata extractor to be split into output
    -- TX_USR_MVB_* signals
    signal tx_usr_mvb_data_all  : slv_array_t(DMA_STREAMS-1 downto 0)(log2(USR_TX_PKT_SIZE_MAX +1)+log2(TX_CHANNELS)+HDR_META_WIDTH -1 downto 0);
    -- RX user data with realigned timestamp
    signal rx_usr_mfb_data_tims : slv_array_t(DMA_STREAMS-1 downto 0)(USR_MFB_REGIONS*USR_MFB_REGION_SIZE*USR_MFB_BLOCK_SIZE*USR_MFB_ITEM_WIDTH -1 downto 0);
    --==============================================================================================

    constant MI_SPLIT_BASES : slv_array_t(MI_SPLIT_PORTS-1 downto 0)(MI_WIDTH-1 downto 0) := (
        0 => X"00000000",
        1 => X"00040000");
begin

    assert (DMA_STREAMS = DMA_ENDPOINTS and DMA_STREAMS = PCIE_ENDPOINTS)
        report "DMA_WRAPPER(CALYPTE): This DMA core does not support multiple DMA endpoints. Only one DMA Module is allowed per PCIE endpoint"
        severity FAILURE;

    dma_pcie_endp_g : for i in 0 to PCIE_ENDPOINTS-1 generate

        --==========================================================================================
        --  MI Splitting and CDC
        --==========================================================================================
        -- splitting the MI bus for the DMA Calypte module and the TSU unit
        mi_gen_spl_i : entity work.MI_SPLITTER_PLUS_GEN
            generic map(
                ADDR_WIDTH   => MI_WIDTH,
                DATA_WIDTH   => MI_WIDTH,
                META_WIDTH   => 0,
                PORTS        => MI_SPLIT_PORTS,
                PIPE_OUT     => (others => FALSE),

                ADDR_MASK   => X"0004_0000",
                ADDR_BASES  => MI_SPLIT_PORTS,
                ADDR_BASE   => MI_SPLIT_BASES,

                DEVICE       => DEVICE
                )
            port map(
                CLK   => MI_CLK,
                RESET => MI_RESET,

                RX_DWR  => MI_DWR(i),
                RX_MWR  => (others => '0'),
                RX_ADDR => MI_ADDR(i),
                RX_BE   => MI_BE(i),
                RX_RD   => MI_RD(i),
                RX_WR   => MI_WR(i),
                RX_ARDY => MI_ARDY(i),
                RX_DRD  => MI_DRD(i),
                RX_DRDY => MI_DRDY(i),

                TX_DWR  => mi_dmagen_dwr(i),
                TX_MWR  => open,
                TX_ADDR => mi_dmagen_addr(i),
                TX_BE   => mi_dmagen_be(i),
                TX_RD   => mi_dmagen_rd(i),
                TX_WR   => mi_dmagen_wr(i),
                TX_ARDY => mi_dmagen_ardy(i),
                TX_DRD  => mi_dmagen_drd(i),
                TX_DRDY => mi_dmagen_drdy(i));


        -- syncing the MI data to the clock which drives the DMA Calypte MI bus
        mi_async_i : entity work.MI_ASYNC
            generic map(
                ADDR_WIDTH => MI_WIDTH,
                DATA_WIDTH => MI_WIDTH,
                DEVICE     => DEVICE
                )
            port map(
                CLK_M     => MI_CLK,
                RESET_M   => MI_RESET,
                MI_M_ADDR => mi_dmagen_addr(i)(0),
                MI_M_DWR  => mi_dmagen_dwr(i)(0),
                MI_M_BE   => mi_dmagen_be(i)(0),
                MI_M_RD   => mi_dmagen_rd(i)(0),
                MI_M_WR   => mi_dmagen_wr(i)(0),
                MI_M_ARDY => mi_dmagen_ardy(i)(0),
                MI_M_DRDY => mi_dmagen_drdy(i)(0),
                MI_M_DRD  => mi_dmagen_drd(i)(0),

                CLK_S     => PCIE_USR_CLK(i),
                RESET_S   => PCIE_USR_RESET(i),
                MI_S_ADDR => mi_sync_addr(i),
                MI_S_DWR  => mi_sync_dwr(i),
                MI_S_BE   => mi_sync_be(i),
                MI_S_RD   => mi_sync_rd(i),
                MI_S_WR   => mi_sync_wr(i),
                MI_S_ARDY => mi_sync_ardy(i),
                MI_S_DRDY => mi_sync_drdy(i),
                MI_S_DRD  => mi_sync_drd (i)
                );
        --==========================================================================================


        --==========================================================================================
        -- Metadata Insertor/Extractor
        --==========================================================================================
        usr_rx_dma_meta_insert_i : entity work.METADATA_INSERTOR
            generic map (
                MVB_ITEMS       => USR_MVB_ITEMS,
                MVB_ITEM_WIDTH  => log2(USR_RX_PKT_SIZE_MAX + 1) + HDR_META_WIDTH + log2(RX_CHANNELS),
                MFB_REGIONS     => USR_MFB_REGIONS,
                MFB_REGION_SIZE => USR_MFB_REGION_SIZE,
                MFB_BLOCK_SIZE  => USR_MFB_BLOCK_SIZE,
                MFB_ITEM_WIDTH  => USR_MFB_ITEM_WIDTH,
                MFB_META_WIDTH  => 0,
                INSERT_MODE     => 0,
                MVB_FIFO_SIZE   => 0,
                DEVICE          => DEVICE)
            port map (
                CLK   => USR_CLK,
                RESET => USR_RESET,

                RX_MVB_DATA    => RX_USR_MVB_LEN(i) & RX_USR_MVB_HDR_META(i) & RX_USR_MVB_CHANNEL(i) ,
                RX_MVB_VLD     => RX_USR_MVB_VLD(i),
                RX_MVB_SRC_RDY => RX_USR_MVB_SRC_RDY(i),
                RX_MVB_DST_RDY => RX_USR_MVB_DST_RDY(i),

                RX_MFB_DATA    => RX_USR_MFB_DATA(i),
                RX_MFB_META    => (others => '0'),
                RX_MFB_SOF     => RX_USR_MFB_SOF(i),
                RX_MFB_EOF     => RX_USR_MFB_EOF(i),
                RX_MFB_SOF_POS => RX_USR_MFB_SOF_POS(i),
                RX_MFB_EOF_POS => RX_USR_MFB_EOF_POS(i),
                RX_MFB_SRC_RDY => RX_USR_MFB_SRC_RDY(i),
                RX_MFB_DST_RDY => RX_USR_MFB_DST_RDY(i),

                TX_MFB_DATA     => rx_usr_mfb_data_async(i),
                TX_MFB_META     => open,
                TX_MFB_META_NEW => rx_usr_mfb_meta_async(i),
                TX_MFB_SOF      => rx_usr_mfb_sof_async(i),
                TX_MFB_EOF      => rx_usr_mfb_eof_async(i),
                TX_MFB_SOF_POS  => rx_usr_mfb_sof_pos_async(i),
                TX_MFB_EOF_POS  => rx_usr_mfb_eof_pos_async(i),
                TX_MFB_SRC_RDY  => rx_usr_mfb_src_rdy_async(i),
                TX_MFB_DST_RDY  => rx_usr_mfb_dst_rdy_async(i));

        usr_tx_dma_meta_ext_i : entity work.METADATA_EXTRACTOR
            generic map (
                MVB_ITEMS       => USR_MVB_ITEMS,
                MFB_REGIONS     => USR_MFB_REGIONS,
                MFB_REGION_SIZE => USR_MFB_REGION_SIZE,
                MFB_BLOCK_SIZE  => USR_MFB_BLOCK_SIZE,
                MFB_ITEM_WIDTH  => USR_MFB_ITEM_WIDTH,
                MFB_META_WIDTH  => log2(USR_TX_PKT_SIZE_MAX + 1) + HDR_META_WIDTH + log2(TX_CHANNELS),
                EXTRACT_MODE    => 0,
                OUT_MVB_PIPE_EN => FALSE,
                OUT_MFB_PIPE_EN => FALSE,
                DEVICE          => DEVICE)
            port map (
                CLK   => USR_CLK,
                RESET => USR_RESET,

                RX_MFB_DATA    => tx_usr_mfb_data_async(i),
                RX_MFB_META    => tx_usr_mfb_meta_async(i),
                RX_MFB_SOF     => tx_usr_mfb_sof_async(i),
                RX_MFB_EOF     => tx_usr_mfb_eof_async(i),
                RX_MFB_SOF_POS => tx_usr_mfb_sof_pos_async(i),
                RX_MFB_EOF_POS => tx_usr_mfb_eof_pos_async(i),
                RX_MFB_SRC_RDY => tx_usr_mfb_src_rdy_async(i),
                RX_MFB_DST_RDY => tx_usr_mfb_dst_rdy_async(i),

                TX_MVB_DATA    => tx_usr_mvb_data_all(i),
                TX_MVB_VLD     => TX_USR_MVB_VLD(i),
                TX_MVB_SRC_RDY => TX_USR_MVB_SRC_RDY(i),
                TX_MVB_DST_RDY => TX_USR_MVB_DST_RDY(i),

                TX_MFB_DATA    => TX_USR_MFB_DATA(i),
                TX_MFB_META    => open,
                TX_MFB_SOF     => TX_USR_MFB_SOF(i),
                TX_MFB_EOF     => TX_USR_MFB_EOF(i),
                TX_MFB_SOF_POS => TX_USR_MFB_SOF_POS(i),
                TX_MFB_EOF_POS => TX_USR_MFB_EOF_POS(i),
                TX_MFB_SRC_RDY => TX_USR_MFB_SRC_RDY(i),
                TX_MFB_DST_RDY => TX_USR_MFB_DST_RDY(i));

        TX_USR_MVB_LEN(i)      <= tx_usr_mvb_data_all(i)(log2(USR_TX_PKT_SIZE_MAX + 1) + HDR_META_WIDTH + log2(TX_CHANNELS) -1 downto HDR_META_WIDTH + log2(TX_CHANNELS));
        TX_USR_MVB_HDR_META(i) <= tx_usr_mvb_data_all(i)(HDR_META_WIDTH + log2(TX_CHANNELS) -1 downto log2(TX_CHANNELS));
        TX_USR_MVB_CHANNEL(i)  <= tx_usr_mvb_data_all(i)(log2(TX_CHANNELS) -1 downto 0);
        --==========================================================================================


        --==========================================================================================
        -- Asynchronous FIFOX components
        --==========================================================================================
        usr_rx_mfb_fifox_i : entity work.MFB_ASFIFOX
            generic map (
                MFB_REGIONS         => USR_MFB_REGIONS,
                MFB_REG_SIZE        => USR_MFB_REGION_SIZE,
                MFB_BLOCK_SIZE      => USR_MFB_BLOCK_SIZE,
                MFB_ITEM_WIDTH      => USR_MFB_ITEM_WIDTH,
                FIFO_ITEMS          => 128,
                RAM_TYPE            => "BRAM",
                FWFT_MODE           => TRUE,
                OUTPUT_REG          => FALSE,
                METADATA_WIDTH      => log2(USR_RX_PKT_SIZE_MAX + 1) + HDR_META_WIDTH + log2(RX_CHANNELS),
                DEVICE              => DEVICE,
                ALMOST_FULL_OFFSET  => 2,
                ALMOST_EMPTY_OFFSET => 2)
            port map (
                RX_CLK   => USR_CLK,
                RX_RESET => USR_RESET,

                RX_DATA    => rx_usr_mfb_data_async(i),
                RX_META    => rx_usr_mfb_meta_async(i),
                RX_SOF     => rx_usr_mfb_sof_async(i),
                RX_EOF     => rx_usr_mfb_eof_async(i),
                RX_SOF_POS => rx_usr_mfb_sof_pos_async(i),
                RX_EOF_POS => rx_usr_mfb_eof_pos_async(i),
                RX_SRC_RDY => rx_usr_mfb_src_rdy_async(i),
                RX_DST_RDY => rx_usr_mfb_dst_rdy_async(i),
                RX_AFULL   => open,
                RX_STATUS  => open,

                TX_CLK   => PCIE_USR_CLK(i),
                TX_RESET => PCIE_USR_RESET(i),

                TX_DATA    => rx_usr_mfb_data_sync(i),
                TX_META    => rx_usr_mfb_meta_sync(i),
                TX_SOF     => rx_usr_mfb_sof_sync(i),
                TX_EOF     => rx_usr_mfb_eof_sync(i),
                TX_SOF_POS => rx_usr_mfb_sof_pos_sync(i),
                TX_EOF_POS => rx_usr_mfb_eof_pos_sync(i),
                TX_SRC_RDY => rx_usr_mfb_src_rdy_sync(i),
                TX_DST_RDY => rx_usr_mfb_dst_rdy_sync(i),
                TX_AEMPTY  => open,
                TX_STATUS  => open);

        rx_usr_mfb_meta_len(i)      <= rx_usr_mfb_meta_sync(i)(log2(USR_RX_PKT_SIZE_MAX + 1) + log2(RX_CHANNELS) + HDR_META_WIDTH -1 downto log2(RX_CHANNELS) + HDR_META_WIDTH);
        rx_usr_mfb_meta_hdr_meta(i) <= rx_usr_mfb_meta_sync(i)(HDR_META_WIDTH + log2(RX_CHANNELS) -1 downto log2(RX_CHANNELS));
        rx_usr_mfb_meta_channel(i)  <= rx_usr_mfb_meta_sync(i)(log2(RX_CHANNELS) -1 downto 0);

        usr_tx_mfb_fifox_i : entity work.MFB_ASFIFOX
            generic map (
                MFB_REGIONS         => USR_MFB_REGIONS,
                MFB_REG_SIZE        => USR_MFB_REGION_SIZE,
                MFB_BLOCK_SIZE      => USR_MFB_BLOCK_SIZE,
                MFB_ITEM_WIDTH      => USR_MFB_ITEM_WIDTH,
                FIFO_ITEMS          => 128,
                RAM_TYPE            => "BRAM",
                FWFT_MODE           => TRUE,
                OUTPUT_REG          => FALSE,
                METADATA_WIDTH      => log2(USR_TX_PKT_SIZE_MAX + 1) + HDR_META_WIDTH + log2(TX_CHANNELS),
                DEVICE              => DEVICE,
                ALMOST_FULL_OFFSET  => 2,
                ALMOST_EMPTY_OFFSET => 2)
            port map (

                RX_CLK   => PCIE_USR_CLK(i),
                RX_RESET => PCIE_USR_RESET(i),

                RX_DATA    => tx_usr_mfb_data_sync(i),
                RX_META    => tx_usr_mfb_meta_len(i) & tx_usr_mfb_meta_hdr_meta(i) & tx_usr_mfb_meta_channel(i),
                RX_SOF     => tx_usr_mfb_sof_sync(i),
                RX_EOF     => tx_usr_mfb_eof_sync(i),
                RX_SOF_POS => tx_usr_mfb_sof_pos_sync(i),
                RX_EOF_POS => tx_usr_mfb_eof_pos_sync(i),
                RX_SRC_RDY => tx_usr_mfb_src_rdy_sync(i),
                RX_DST_RDY => tx_usr_mfb_dst_rdy_sync(i),
                RX_AFULL   => open,
                RX_STATUS  => open,

                TX_CLK   => USR_CLK,
                TX_RESET => USR_RESET,

                TX_DATA    => tx_usr_mfb_data_async(i),
                TX_META    => tx_usr_mfb_meta_async(i),
                TX_SOF     => tx_usr_mfb_sof_async(i),
                TX_EOF     => tx_usr_mfb_eof_async(i),
                TX_SOF_POS => tx_usr_mfb_sof_pos_async(i),
                TX_EOF_POS => tx_usr_mfb_eof_pos_async(i),
                TX_SRC_RDY => tx_usr_mfb_src_rdy_async(i),
                TX_DST_RDY => tx_usr_mfb_dst_rdy_async(i),
                TX_AEMPTY  => open,
                TX_STATUS  => open);
        --==========================================================================================


        --==========================================================================================
        -- Timestamping logic
        --==========================================================================================
        -- This unit is for each DMA module
        dma_tsu_g: if (DMA_TSU_ENABLE) generate

            constant MAX_MFB_SOF_POS_VAL : unsigned(RX_USR_MFB_SOF_POS(i)'range) := (others => '1');

            signal tsu_ts_ns : std_logic_vector(63 downto 0);
            signal tsu_ts_dv : std_logic;

        begin

            assert (USR_MFB_BLOCK_SIZE = 8 and USR_MFB_ITEM_WIDTH = 8)
                report "dma_calypte_wrapper_arch: The Timestamp insertion logic expects the size of the block to be at 8 bytes, when you do not need the TSU, disable it."
                severity FAILURE;

            dma_tsu_i : entity work.TSU_GEN
                generic map (
                    TS_MULT_SMART_DSP => (DEVICE="ULTRASCALE"),
                    TS_MULT_USE_DSP   => (DEVICE="ULTRASCALE"),
                    PPS_SEL_WIDTH     => 0,
                    CLK_SEL_WIDTH     => 0,
                    DEVICE            => DEVICE)
                port map (
                    MI_CLK   => MI_CLK,
                    MI_RESET => MI_RESET,

                    MI_DWR   => mi_dmagen_dwr(i)(1),
                    MI_ADDR  => mi_dmagen_addr(i)(1),
                    MI_RD    => mi_dmagen_rd(i)(1),
                    MI_WR    => mi_dmagen_wr(i)(1),
                    MI_BE    => mi_dmagen_be(i)(1),
                    MI_DRD   => mi_dmagen_drd(i)(1),
                    MI_ARDY  => mi_dmagen_ardy(i)(1),
                    MI_DRDY  => mi_dmagen_drdy(i)(1),

                    PPS_N    => '0',
                    PPS_SRC  => (others => '0'),
                    PPS_SEL  => open,

                    CLK      => PCIE_USR_CLK(i),
                    RESET    => PCIE_USR_RESET(i),

                    CLK_FREQ => std_logic_vector(to_unsigned(250000000-1,32)),
                    CLK_SRC  => x"0001",
                    CLK_SEL  => open,

                    TS       => open,
                    TS_NS    => tsu_ts_ns,
                    TS_DV    => tsu_ts_dv);

            ts_ins_reg_p: process (all) is
                variable sof_pos_un : unsigned(RX_USR_MFB_SOF_POS(i)'range);
            begin
                rx_usr_mfb_data_tims(i)     <= rx_usr_mfb_data_sync(i);

                if (rx_usr_mfb_sof_sync(i) = "1" and rx_usr_mfb_src_rdy_sync(i) = '1') then

                    sof_pos_un := unsigned(rx_usr_mfb_sof_pos_sync(i));

                    for j in 0 to to_integer(MAX_MFB_SOF_POS_VAL) loop
                        if (j = sof_pos_un) then
                            rx_usr_mfb_data_tims(i)(j*64 + 63 downto j*64) <= tsu_ts_ns;
                        end if;
                    end loop;

                end if;
            end process;

        else generate

            rx_usr_mfb_data_tims(i) <= rx_usr_mfb_data_sync(i);
            mi_dmagen_drd(i)(1)     <= (others => '0');
            mi_dmagen_drdy(i)(1)    <= '0';
            mi_dmagen_ardy(i)(1)    <= '1';

        end generate;
        --==========================================================================================

    end generate;
    --==============================================================================================


    --==============================================================================================
    --  DMA Calypte Module
    --==============================================================================================
    dma_calypte_g : for i in 0 to DMA_STREAMS-1 generate
    begin

        dma_calypte_i : entity work.DMA_CALYPTE
            generic map(
                DEVICE => DEVICE,

                USR_MFB_REGIONS     => USR_MFB_REGIONS,
                USR_MFB_REGION_SIZE => USR_MFB_REGION_SIZE,
                USR_MFB_BLOCK_SIZE  => USR_MFB_BLOCK_SIZE,
                USR_MFB_ITEM_WIDTH  => USR_MFB_ITEM_WIDTH,

                PKT_SIZE_MAX => USR_RX_PKT_SIZE_MAX,

                PCIE_UP_MFB_REGIONS     => UP_MFB_REGIONS,
                PCIE_UP_MFB_REGION_SIZE => UP_MFB_REGION_SIZE,
                PCIE_UP_MFB_BLOCK_SIZE  => UP_MFB_BLOCK_SIZE,
                PCIE_UP_MFB_ITEM_WIDTH  => UP_MFB_ITEM_WIDTH,

                PCIE_DOWN_MFB_REGIONS     => DOWN_MFB_REGIONS,
                PCIE_DOWN_MFB_REGION_SIZE => DOWN_MFB_REGION_SIZE,
                PCIE_DOWN_MFB_BLOCK_SIZE  => DOWN_MFB_BLOCK_SIZE,
                PCIE_DOWN_MFB_ITEM_WIDTH  => DOWN_MFB_ITEM_WIDTH,

                HDR_META_WIDTH => HDR_META_WIDTH,

                RX_CHANNELS  => RX_CHANNELS,
                RX_PTR_WIDTH => RX_DP_WIDTH,

                TX_CHANNELS  => TX_CHANNELS,
                TX_PTR_WIDTH => TX_DP_WIDTH,

                DSP_CNT_WIDTH => DSP_CNT_WIDTH,

                RX_GEN_EN     => RX_GEN_EN,
                TX_GEN_EN     => TX_GEN_EN,

                MI_WIDTH      => MI_WIDTH
                )
            port map(
                CLK   => PCIE_USR_CLK(i),
                RESET => PCIE_USR_RESET(i),

                USR_RX_MFB_META_PKT_SIZE => rx_usr_mfb_meta_len(i),
                USR_RX_MFB_META_HDR_META => rx_usr_mfb_meta_hdr_meta(i),
                USR_RX_MFB_META_CHAN     => rx_usr_mfb_meta_channel(i),

                USR_RX_MFB_DATA    => rx_usr_mfb_data_tims(i),
                USR_RX_MFB_SOF     => rx_usr_mfb_sof_sync(i),
                USR_RX_MFB_EOF     => rx_usr_mfb_eof_sync(i),
                USR_RX_MFB_SOF_POS => rx_usr_mfb_sof_pos_sync(i),
                USR_RX_MFB_EOF_POS => rx_usr_mfb_eof_pos_sync(i),
                USR_RX_MFB_SRC_RDY => rx_usr_mfb_src_rdy_sync(i),
                USR_RX_MFB_DST_RDY => rx_usr_mfb_dst_rdy_sync(i),

                USR_TX_MFB_META_PKT_SIZE => tx_usr_mfb_meta_len(i),
                USR_TX_MFB_META_HDR_META => tx_usr_mfb_meta_hdr_meta(i),
                USR_TX_MFB_META_CHAN     => tx_usr_mfb_meta_channel(i),

                USR_TX_MFB_DATA    => tx_usr_mfb_data_sync(i),
                USR_TX_MFB_SOF     => tx_usr_mfb_sof_sync(i),
                USR_TX_MFB_EOF     => tx_usr_mfb_eof_sync(i),
                USR_TX_MFB_SOF_POS => tx_usr_mfb_sof_pos_sync(i),
                USR_TX_MFB_EOF_POS => tx_usr_mfb_eof_pos_sync(i),
                USR_TX_MFB_SRC_RDY => tx_usr_mfb_src_rdy_sync(i),
                USR_TX_MFB_DST_RDY => tx_usr_mfb_dst_rdy_sync(i),

                PCIE_UP_MFB_DATA    => up_mfb_data_piped(i),
                PCIE_UP_MFB_SOF     => up_mfb_sof_piped(i),
                PCIE_UP_MFB_EOF     => up_mfb_eof_piped(i),
                PCIE_UP_MFB_SOF_POS => up_mfb_sof_pos_piped(i),
                PCIE_UP_MFB_EOF_POS => up_mfb_eof_pos_piped(i),
                PCIE_UP_MFB_SRC_RDY => up_mfb_src_rdy_piped(i),
                PCIE_UP_MFB_DST_RDY => up_mfb_dst_rdy_piped(i),

                PCIE_DOWN_MFB_DATA    => DOWN_MFB_DATA(i),
                PCIE_DOWN_MFB_SOF     => DOWN_MFB_SOF(i),
                PCIE_DOWN_MFB_EOF     => DOWN_MFB_EOF(i),
                PCIE_DOWN_MFB_SOF_POS => DOWN_MFB_SOF_POS(i),
                PCIE_DOWN_MFB_EOF_POS => DOWN_MFB_EOF_POS(i),
                PCIE_DOWN_MFB_SRC_RDY => DOWN_MFB_SRC_RDY(i),
                PCIE_DOWN_MFB_DST_RDY => DOWN_MFB_DST_RDY(i),

                MI_ADDR => mi_sync_addr(i),
                MI_DWR  => mi_sync_dwr(i),
                MI_BE   => mi_sync_be(i),
                MI_RD   => mi_sync_rd(i),
                MI_WR   => mi_sync_wr(i),
                MI_DRD  => mi_sync_drd(i),
                MI_ARDY => mi_sync_ardy(i),
                MI_DRDY => mi_sync_drdy(i)
                );

    end generate;

    pipes_g: for i in 0 to (PCIE_ENDPOINTS -1) generate
        up_mfb_pipe_i : entity work.MFB_PIPE
            generic map (
                REGIONS     => UP_MFB_REGIONS,
                REGION_SIZE => UP_MFB_REGION_SIZE,
                BLOCK_SIZE  => UP_MFB_BLOCK_SIZE,
                ITEM_WIDTH  => UP_MFB_ITEM_WIDTH,

                META_WIDTH  => 0,
                FAKE_PIPE   => not OUT_PIPE_EN,
                USE_DST_RDY => TRUE,
                PIPE_TYPE   => "REG",
                DEVICE      => DEVICE)
            port map (
                CLK        => PCIE_USR_CLK(i),
                RESET      => PCIE_USR_RESET(i),

                RX_DATA    => up_mfb_data_piped(i),
                RX_META    => (others => '0'),
                RX_SOF_POS => up_mfb_sof_pos_piped(i),
                RX_EOF_POS => up_mfb_eof_pos_piped(i),
                RX_SOF     => up_mfb_sof_piped(i),
                RX_EOF     => up_mfb_eof_piped(i),
                RX_SRC_RDY => up_mfb_src_rdy_piped(i),
                RX_DST_RDY => up_mfb_dst_rdy_piped(i),

                TX_DATA    => UP_MFB_DATA(i),
                TX_META    => open,
                TX_SOF_POS => UP_MFB_SOF_POS(i),
                TX_EOF_POS => UP_MFB_EOF_POS(i),
                TX_SOF     => UP_MFB_SOF(i),
                TX_EOF     => UP_MFB_EOF(i),
                TX_SRC_RDY => UP_MFB_SRC_RDY(i),
                TX_DST_RDY => UP_MFB_DST_RDY(i));
    end generate;

end architecture;
