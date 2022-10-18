-- dma.vhd: DMA Module Wrapper
-- Copyright (C) 2020 CESNET z. s. p. o.
-- Author(s): Jan Kubalek <kubalek@cesnet.cz>
--
-- SPDX-License-Identifier: BSD-3-Clause

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.math_pack.all;
use work.type_pack.all;

use work.dma_bus_pack.all;

architecture FULL of DMA is

    constant DMA_PER_PCIE      : natural := DMA_ENDPOINTS/PCIE_ENDPOINTS;
    constant DMA_EP_PER_DMA    : natural := DMA_ENDPOINTS/NUM_DMA;
    constant GLS_MI_OFFSET     : std_logic_vector(32-1 downto 0) := X"0000_0100";
    constant IUSR_MVB_ITEMS    : natural := tsel(DMA_400G_DEMO,4,USR_MVB_ITEMS);
    constant IUSR_MFB_REGIONS  : natural := tsel(DMA_400G_DEMO,4,USR_MFB_REGIONS);
    constant DMA_RST_REPLICAS  : natural := NUM_DMA+PCIE_ENDPOINTS;
    constant CROX_RST_REPLICAS : natural := NUM_DMA;

    function gls_mi_addr_base_f return slv_array_t is
        variable mi_addr_base_var : slv_array_t(NUM_DMA-1 downto 0)(32-1 downto 0);
    begin
        for i in 0 to NUM_DMA-1 loop
            mi_addr_base_var(i) := std_logic_vector(resize(i*unsigned(GLS_MI_OFFSET), 32));
        end loop;
        return mi_addr_base_var;
    end function;

    signal dma_rst_dup  : std_logic_vector(DMA_RST_REPLICAS-1 downto 0);
    signal crox_rst_dup : std_logic_vector(CROX_RST_REPLICAS-1 downto 0);

    -- =====================================================================
    --  MI Splitting
    -- =====================================================================

    signal gls_mi_addr  : slv_array_t     (NUM_DMA-1 downto 0)(32-1 downto 0);
    signal gls_mi_dwr   : slv_array_t     (NUM_DMA-1 downto 0)(32-1 downto 0);
    signal gls_mi_be    : slv_array_t     (NUM_DMA-1 downto 0)(32/8-1 downto 0);
    signal gls_mi_rd    : std_logic_vector(NUM_DMA-1 downto 0);
    signal gls_mi_wr    : std_logic_vector(NUM_DMA-1 downto 0);
    signal gls_mi_drd   : slv_array_t     (NUM_DMA-1 downto 0)(32-1 downto 0);
    signal gls_mi_ardy  : std_logic_vector(NUM_DMA-1 downto 0);
    signal gls_mi_drdy  : std_logic_vector(NUM_DMA-1 downto 0);

    -- =====================================================================

    -- =====================================================================
    --  MI Asynch
    -- =====================================================================

    signal dma_sync_mi_addr : slv_array_t     (PCIE_ENDPOINTS-1 downto 0)(32-1 downto 0);
    signal dma_sync_mi_dwr  : slv_array_t     (PCIE_ENDPOINTS-1 downto 0)(32-1 downto 0);
    signal dma_sync_mi_be   : slv_array_t     (PCIE_ENDPOINTS-1 downto 0)(32/8-1 downto 0);
    signal dma_sync_mi_rd   : std_logic_vector(PCIE_ENDPOINTS-1 downto 0);
    signal dma_sync_mi_wr   : std_logic_vector(PCIE_ENDPOINTS-1 downto 0);
    signal dma_sync_mi_drd  : slv_array_t     (PCIE_ENDPOINTS-1 downto 0)(32-1 downto 0);
    signal dma_sync_mi_ardy : std_logic_vector(PCIE_ENDPOINTS-1 downto 0);
    signal dma_sync_mi_drdy : std_logic_vector(PCIE_ENDPOINTS-1 downto 0);

    -- =====================================================================

    -- =====================================================================
    --  MI DMA Endpoint Splitter
    -- =====================================================================

    signal dma_end_mi_addr : slv_array_t     (DMA_ENDPOINTS-1 downto 0)(32-1 downto 0);
    signal dma_end_mi_dwr  : slv_array_t     (DMA_ENDPOINTS-1 downto 0)(32-1 downto 0);
    signal dma_end_mi_be   : slv_array_t     (DMA_ENDPOINTS-1 downto 0)(32/8-1 downto 0);
    signal dma_end_mi_rd   : std_logic_vector(DMA_ENDPOINTS-1 downto 0);
    signal dma_end_mi_wr   : std_logic_vector(DMA_ENDPOINTS-1 downto 0);
    signal dma_end_mi_drd  : slv_array_t     (DMA_ENDPOINTS-1 downto 0)(32-1 downto 0);
    signal dma_end_mi_ardy : std_logic_vector(DMA_ENDPOINTS-1 downto 0);
    signal dma_end_mi_drdy : std_logic_vector(DMA_ENDPOINTS-1 downto 0);

    -- =====================================================================

    -- =====================================================================
    --  UP MVB Endpoint tagging
    -- =====================================================================

    signal dma_up_mvb_data          : slv_array_t(DMA_ENDPOINTS-1 downto 0)(UP_MFB_REGIONS*DMA_UPHDR_WIDTH-1 downto 0);
    signal UP_MVB_DATA_arr          : slv_array_2d_t(DMA_ENDPOINTS-1 downto 0)(UP_MFB_REGIONS-1 downto 0)(DMA_UPHDR_WIDTH-1 downto 0);
    signal UP_MVB_DATA_vec          : std_logic_vector(DMA_ENDPOINTS*UP_MFB_REGIONS*DMA_UPHDR_WIDTH-1 downto 0);

    -- =====================================================================

    signal rx_usr_arr_mvb_len       : slv_array_t(NUM_DMA-1 downto 0)(IUSR_MVB_ITEMS*log2(USR_RX_PKT_SIZE_MAX+1)-1 downto 0);
    signal rx_usr_arr_mvb_hdr_meta  : slv_array_t(NUM_DMA-1 downto 0)(IUSR_MVB_ITEMS*HDR_META_WIDTH          -1 downto 0);
    signal rx_usr_arr_mvb_channel   : slv_array_t(NUM_DMA-1 downto 0)(IUSR_MVB_ITEMS*log2(RX_CHANNELS)       -1 downto 0);
    signal rx_usr_arr_mvb_discard   : slv_array_t(NUM_DMA-1 downto 0)(IUSR_MVB_ITEMS*1                       -1 downto 0);
    signal rx_usr_arr_mvb_vld       : slv_array_t(NUM_DMA-1 downto 0)(IUSR_MVB_ITEMS                         -1 downto 0);
    signal rx_usr_arr_mvb_src_rdy   : std_logic_vector(NUM_DMA-1 downto 0);
    signal rx_usr_arr_mvb_dst_rdy   : std_logic_vector(NUM_DMA-1 downto 0);

    signal rx_usr_arr_mfb_data      : slv_array_t(NUM_DMA-1 downto 0)(IUSR_MFB_REGIONS*USR_MFB_REGION_SIZE*USR_MFB_BLOCK_SIZE*USR_MFB_ITEM_WIDTH-1 downto 0);
    signal rx_usr_arr_mfb_sof       : slv_array_t(NUM_DMA-1 downto 0)(IUSR_MFB_REGIONS                                                          -1 downto 0);
    signal rx_usr_arr_mfb_eof       : slv_array_t(NUM_DMA-1 downto 0)(IUSR_MFB_REGIONS                                                          -1 downto 0);
    signal rx_usr_arr_mfb_sof_pos   : slv_array_t(NUM_DMA-1 downto 0)(IUSR_MFB_REGIONS*max(1,log2(USR_MFB_REGION_SIZE))                         -1 downto 0);
    signal rx_usr_arr_mfb_eof_pos   : slv_array_t(NUM_DMA-1 downto 0)(IUSR_MFB_REGIONS*max(1,log2(USR_MFB_REGION_SIZE*USR_MFB_BLOCK_SIZE))      -1 downto 0);
    signal rx_usr_arr_mfb_src_rdy   : std_logic_vector(NUM_DMA-1 downto 0);
    signal rx_usr_arr_mfb_dst_rdy   : std_logic_vector(NUM_DMA-1 downto 0);

    signal tx_usr_arr_mvb_len       : slv_array_t(NUM_DMA-1 downto 0)(IUSR_MVB_ITEMS*log2(USR_TX_PKT_SIZE_MAX+1)-1 downto 0);
    signal tx_usr_arr_mvb_hdr_meta  : slv_array_t(NUM_DMA-1 downto 0)(IUSR_MVB_ITEMS*HDR_META_WIDTH          -1 downto 0);
    signal tx_usr_arr_mvb_channel   : slv_array_t(NUM_DMA-1 downto 0)(IUSR_MVB_ITEMS*log2(TX_CHANNELS)       -1 downto 0);
    signal tx_usr_arr_mvb_vld       : slv_array_t(NUM_DMA-1 downto 0)(IUSR_MVB_ITEMS                         -1 downto 0);
    signal tx_usr_arr_mvb_src_rdy   : std_logic_vector(NUM_DMA-1 downto 0);
    signal tx_usr_arr_mvb_dst_rdy   : std_logic_vector(NUM_DMA-1 downto 0);

    signal tx_usr_arr_mfb_data      : slv_array_t(NUM_DMA-1 downto 0)(IUSR_MFB_REGIONS*USR_MFB_REGION_SIZE*USR_MFB_BLOCK_SIZE*USR_MFB_ITEM_WIDTH-1 downto 0);
    signal tx_usr_arr_mfb_sof       : slv_array_t(NUM_DMA-1 downto 0)(IUSR_MFB_REGIONS                                                          -1 downto 0);
    signal tx_usr_arr_mfb_eof       : slv_array_t(NUM_DMA-1 downto 0)(IUSR_MFB_REGIONS                                                          -1 downto 0);
    signal tx_usr_arr_mfb_sof_pos   : slv_array_t(NUM_DMA-1 downto 0)(IUSR_MFB_REGIONS*max(1,log2(USR_MFB_REGION_SIZE))                         -1 downto 0);
    signal tx_usr_arr_mfb_eof_pos   : slv_array_t(NUM_DMA-1 downto 0)(IUSR_MFB_REGIONS*max(1,log2(USR_MFB_REGION_SIZE*USR_MFB_BLOCK_SIZE))      -1 downto 0);
    signal tx_usr_arr_mfb_src_rdy   : std_logic_vector(NUM_DMA-1 downto 0);
    signal tx_usr_arr_mfb_dst_rdy   : std_logic_vector(NUM_DMA-1 downto 0);

    -- =====================================================================
    --  GEN_LOOP_SWITCH -> DMA Module interface
    -- =====================================================================

    signal dma_rx_usr_mvb_len       : slv_array_t(NUM_DMA-1 downto 0)(IUSR_MVB_ITEMS*log2(USR_RX_PKT_SIZE_MAX+1)-1 downto 0);
    signal dma_rx_usr_mvb_hdr_meta  : slv_array_t(NUM_DMA-1 downto 0)(IUSR_MVB_ITEMS*HDR_META_WIDTH          -1 downto 0);
    signal dma_rx_usr_mvb_channel   : slv_array_t(NUM_DMA-1 downto 0)(IUSR_MVB_ITEMS*log2(RX_CHANNELS)       -1 downto 0);
    signal dma_rx_usr_mvb_discard   : slv_array_t(NUM_DMA-1 downto 0)(IUSR_MVB_ITEMS*1                       -1 downto 0);
    signal dma_rx_usr_mvb_vld       : slv_array_t(NUM_DMA-1 downto 0)(IUSR_MVB_ITEMS                         -1 downto 0);
    signal dma_rx_usr_mvb_src_rdy   : std_logic_vector(NUM_DMA-1 downto 0);
    signal dma_rx_usr_mvb_dst_rdy   : std_logic_vector(NUM_DMA-1 downto 0);

    signal dma_rx_usr_mfb_data      : slv_array_t(NUM_DMA-1 downto 0)(IUSR_MFB_REGIONS*USR_MFB_REGION_SIZE*USR_MFB_BLOCK_SIZE*USR_MFB_ITEM_WIDTH-1 downto 0);
    signal dma_rx_usr_mfb_sof       : slv_array_t(NUM_DMA-1 downto 0)(IUSR_MFB_REGIONS                                                          -1 downto 0);
    signal dma_rx_usr_mfb_eof       : slv_array_t(NUM_DMA-1 downto 0)(IUSR_MFB_REGIONS                                                          -1 downto 0);
    signal dma_rx_usr_mfb_sof_pos   : slv_array_t(NUM_DMA-1 downto 0)(IUSR_MFB_REGIONS*max(1,log2(USR_MFB_REGION_SIZE))                         -1 downto 0);
    signal dma_rx_usr_mfb_eof_pos   : slv_array_t(NUM_DMA-1 downto 0)(IUSR_MFB_REGIONS*max(1,log2(USR_MFB_REGION_SIZE*USR_MFB_BLOCK_SIZE))      -1 downto 0);
    signal dma_rx_usr_mfb_src_rdy   : std_logic_vector(NUM_DMA-1 downto 0);
    signal dma_rx_usr_mfb_dst_rdy   : std_logic_vector(NUM_DMA-1 downto 0);

    -- =====================================================================

    -- =====================================================================
    --  DMA Module -> GEN_LOOP_SWITCH interface
    -- =====================================================================

    signal dma_tx_usr_mvb_len       : slv_array_t(NUM_DMA-1 downto 0)(IUSR_MVB_ITEMS*log2(USR_TX_PKT_SIZE_MAX+1)-1 downto 0);
    signal dma_tx_usr_mvb_hdr_meta  : slv_array_t(NUM_DMA-1 downto 0)(IUSR_MVB_ITEMS*HDR_META_WIDTH          -1 downto 0);
    signal dma_tx_usr_mvb_channel   : slv_array_t(NUM_DMA-1 downto 0)(IUSR_MVB_ITEMS*log2(TX_CHANNELS)       -1 downto 0);
    signal dma_tx_usr_mvb_vld       : slv_array_t(NUM_DMA-1 downto 0)(IUSR_MVB_ITEMS                         -1 downto 0);
    signal dma_tx_usr_mvb_src_rdy   : std_logic_vector(NUM_DMA-1 downto 0);
    signal dma_tx_usr_mvb_dst_rdy   : std_logic_vector(NUM_DMA-1 downto 0);

    signal dma_tx_usr_mfb_data      : slv_array_t(NUM_DMA-1 downto 0)(IUSR_MFB_REGIONS*USR_MFB_REGION_SIZE*USR_MFB_BLOCK_SIZE*USR_MFB_ITEM_WIDTH-1 downto 0);
    signal dma_tx_usr_mfb_sof       : slv_array_t(NUM_DMA-1 downto 0)(IUSR_MFB_REGIONS                                                          -1 downto 0);
    signal dma_tx_usr_mfb_eof       : slv_array_t(NUM_DMA-1 downto 0)(IUSR_MFB_REGIONS                                                          -1 downto 0);
    signal dma_tx_usr_mfb_sof_pos   : slv_array_t(NUM_DMA-1 downto 0)(IUSR_MFB_REGIONS*max(1,log2(USR_MFB_REGION_SIZE))                         -1 downto 0);
    signal dma_tx_usr_mfb_eof_pos   : slv_array_t(NUM_DMA-1 downto 0)(IUSR_MFB_REGIONS*max(1,log2(USR_MFB_REGION_SIZE*USR_MFB_BLOCK_SIZE))      -1 downto 0);
    signal dma_tx_usr_mfb_src_rdy   : std_logic_vector(NUM_DMA-1 downto 0);
    signal dma_tx_usr_mfb_dst_rdy   : std_logic_vector(NUM_DMA-1 downto 0);

    -- =====================================================================

begin

    assert ((USR_RX_PKT_SIZE_MAX = USR_TX_PKT_SIZE_MAX) or (not GEN_LOOP_EN))
        report "DMA: The maximum frame size for RX/TX DMA must be the same or the GLS module must be disabled!"
        severity failure;

    dma_rst_i : entity work.ASYNC_RESET
    generic map (
        TWO_REG  => false,
        OUT_REG  => true,
        REPLICAS => DMA_RST_REPLICAS
    )
    port map (
        CLK         => DMA_CLK,
        ASYNC_RST   => DMA_RESET,
        OUT_RST     => dma_rst_dup
    );

    crox_rst_i : entity work.ASYNC_RESET
    generic map (
        TWO_REG  => false,
        OUT_REG  => true,
        REPLICAS => CROX_RST_REPLICAS
    )
    port map (
        CLK         => CROX_CLK,
        ASYNC_RST   => CROX_RESET,
        OUT_RST     => crox_rst_dup
    );

    -- =====================================================================
    --  MI Asynch
    -- =====================================================================

    mi_asynch_gen : for i in 0 to PCIE_ENDPOINTS-1 generate

        mi_asynch_i : entity work.MI_ASYNC
        generic map(
            ADDR_WIDTH => 32,
            DATA_WIDTH => 32,
            DEVICE     => DEVICE
        )
        port map(
            CLK_M     => MI_CLK             ,
            RESET_M   => MI_RESET           ,
            MI_M_ADDR => MI_ADDR         (i),
            MI_M_DWR  => MI_DWR          (i),
            MI_M_BE   => MI_BE           (i),
            MI_M_RD   => MI_RD           (i),
            MI_M_WR   => MI_WR           (i),
            MI_M_ARDY => MI_ARDY         (i),
            MI_M_DRDY => MI_DRDY         (i),
            MI_M_DRD  => MI_DRD          (i),

            CLK_S     => DMA_CLK            ,
            RESET_S   => dma_rst_dup(i)     ,
            MI_S_ADDR => dma_sync_mi_addr(i),
            MI_S_DWR  => dma_sync_mi_dwr (i),
            MI_S_BE   => dma_sync_mi_be  (i),
            MI_S_RD   => dma_sync_mi_rd  (i),
            MI_S_WR   => dma_sync_mi_wr  (i),
            MI_S_ARDY => dma_sync_mi_ardy(i),
            MI_S_DRDY => dma_sync_mi_drdy(i),
            MI_S_DRD  => dma_sync_mi_drd (i)
        );
    end generate;

    -- =====================================================================

    -- =====================================================================
    --  MI DMA Endpoint Splitter
    -- =====================================================================

    dma_end_mi_spl_gen : if (DMA_PER_PCIE=2) generate

        dma_end_mi_spl_end_gen : for i in 0 to PCIE_ENDPOINTS-1 generate
            signal dma_end_vec_mi_addr : std_logic_vector(2*32-1 downto 0);
            signal dma_end_vec_mi_dwr  : std_logic_vector(2*32-1 downto 0);
            signal dma_end_vec_mi_be   : std_logic_vector(2*32/8-1 downto 0);
            signal dma_end_vec_mi_rd   : std_logic_vector(2-1 downto 0);
            signal dma_end_vec_mi_wr   : std_logic_vector(2-1 downto 0);
            signal dma_end_vec_mi_drd  : std_logic_vector(2*32-1 downto 0);
            signal dma_end_vec_mi_ardy : std_logic_vector(2-1 downto 0);
            signal dma_end_vec_mi_drdy : std_logic_vector(2-1 downto 0);
            signal dma_end_mi_drd_tmp  : slv_array_t     (2-1 downto 0)(32-1 downto 0);
        begin

            dma_end_mi_spl_i : entity work.MI_SPLITTER_PLUS
            generic map(
                DATA_WIDTH    => 32,
                ITEMS         => 2 ,
                -- The splitting is determined by one of the top bits of DMA Channel selection
                ADDR_CMP_MASK => (log2(max(RX_CHANNELS,TX_CHANNELS)/PCIE_ENDPOINTS)+7-1 downto log2(max(RX_CHANNELS,TX_CHANNELS)/DMA_ENDPOINTS)+7 => '1', others => '0'),
                PORT1_BASE    => (log2(max(RX_CHANNELS,TX_CHANNELS)/PCIE_ENDPOINTS)+7-1 downto log2(max(RX_CHANNELS,TX_CHANNELS)/DMA_ENDPOINTS)+7 => '1', others => '0'),
                PIPE          => true  ,
                PIPE_OUTREG   => false ,
                DEVICE        => DEVICE
            )
            port map(
                CLK      => DMA_CLK  ,
                RESET    => dma_rst_dup(i),

                IN_DWR   => dma_sync_mi_dwr (i),
                IN_ADDR  => dma_sync_mi_addr(i),
                IN_BE    => dma_sync_mi_be  (i),
                IN_RD    => dma_sync_mi_rd  (i),
                IN_WR    => dma_sync_mi_wr  (i),
                IN_ARDY  => dma_sync_mi_ardy(i),
                IN_DRD   => dma_sync_mi_drd (i),
                IN_DRDY  => dma_sync_mi_drdy(i),

                OUT_DWR  => dma_end_vec_mi_dwr ,
                OUT_ADDR => dma_end_vec_mi_addr,
                OUT_BE   => dma_end_vec_mi_be  ,
                OUT_RD   => dma_end_vec_mi_rd  ,
                OUT_WR   => dma_end_vec_mi_wr  ,
                OUT_ARDY => dma_end_vec_mi_ardy,
                OUT_DRD  => dma_end_vec_mi_drd ,
                OUT_DRDY => dma_end_vec_mi_drdy
            );

            dma_end_mi_addr(i*2+2-1 downto i*2) <= slv_array_deser(dma_end_vec_mi_addr,2);
            dma_end_mi_dwr (i*2+2-1 downto i*2) <= slv_array_deser(dma_end_vec_mi_dwr ,2);
            dma_end_mi_be  (i*2+2-1 downto i*2) <= slv_array_deser(dma_end_vec_mi_be  ,2);
            dma_end_mi_rd  (i*2+2-1 downto i*2) <= dma_end_vec_mi_rd;
            dma_end_mi_wr  (i*2+2-1 downto i*2) <= dma_end_vec_mi_wr;

            dma_end_mi_drd_tmp  <= dma_end_mi_drd(i*2+2-1 downto i*2);
            dma_end_vec_mi_drd  <= slv_array_ser(dma_end_mi_drd_tmp);
            dma_end_vec_mi_ardy <= dma_end_mi_ardy(i*2+2-1 downto i*2);
            dma_end_vec_mi_drdy <= dma_end_mi_drdy(i*2+2-1 downto i*2);

        end generate;

    else generate

        dma_end_mi_addr (DMA_ENDPOINTS-1 downto 0) <= dma_sync_mi_addr(DMA_ENDPOINTS-1 downto 0);
        dma_end_mi_dwr  (DMA_ENDPOINTS-1 downto 0) <= dma_sync_mi_dwr (DMA_ENDPOINTS-1 downto 0);
        dma_end_mi_be   (DMA_ENDPOINTS-1 downto 0) <= dma_sync_mi_be  (DMA_ENDPOINTS-1 downto 0);
        dma_end_mi_rd   (DMA_ENDPOINTS-1 downto 0) <= dma_sync_mi_rd  (DMA_ENDPOINTS-1 downto 0);
        dma_end_mi_wr   (DMA_ENDPOINTS-1 downto 0) <= dma_sync_mi_wr  (DMA_ENDPOINTS-1 downto 0);

        dma_sync_mi_drd (DMA_ENDPOINTS-1 downto 0) <= dma_end_mi_drd  (DMA_ENDPOINTS-1 downto 0);
        dma_sync_mi_ardy(DMA_ENDPOINTS-1 downto 0) <= dma_end_mi_ardy (DMA_ENDPOINTS-1 downto 0);
        dma_sync_mi_drdy(DMA_ENDPOINTS-1 downto 0) <= dma_end_mi_drdy (DMA_ENDPOINTS-1 downto 0);

    end generate;

    -- =====================================================================

    -- =====================================================================
    --  UP MVB Endpoint tagging
    -- =====================================================================
    -- When there ade multiple DMA Endpoints for each PCIe Endpoint,
    -- the top bits of UP MVB Tag is determined by SRC DMA Endpoint.

    up_mvb_data_pr : process (all)
    begin
        UP_MVB_DATA <= dma_up_mvb_data;

        if (DMA_PER_PCIE=2) then
            for i in 0 to PCIE_ENDPOINTS-1 loop
                for e in 0 to DMA_PER_PCIE-1 loop
                    UP_MVB_DATA_arr(i*DMA_PER_PCIE+e) <= slv_array_deser(dma_up_mvb_data(i*DMA_PER_PCIE+e),UP_MFB_REGIONS);
                    for g in 0 to UP_MFB_REGIONS-1 loop
                        UP_MVB_DATA_arr(i*DMA_PER_PCIE+e)(g)(DMA_REQUEST_TAG'high downto DMA_REQUEST_TAG'high-log2(DMA_PER_PCIE)+1) <= std_logic_vector(to_unsigned(e,log2(DMA_PER_PCIE)));
                    end loop;
                end loop;
            end loop;
            UP_MVB_DATA_vec <= slv_array_2d_ser(UP_MVB_DATA_arr);
            UP_MVB_DATA     <= slv_array_deser(UP_MVB_DATA_vec,DMA_ENDPOINTS);
        end if;
    end process;

    -- =====================================================================

    -- =====================================================================
    --  DMA Module
    -- =====================================================================

    dma_g : for i in 0 to NUM_DMA-1 generate
        subtype DPE is natural range (i+1)*DMA_EP_PER_DMA-1 downto i*DMA_EP_PER_DMA;
    begin
        dma_i : entity work.DMA_MEDUSA
        generic map(
            DEVICE               => DEVICE                          ,
            USR_MVB_ITEMS        => IUSR_MVB_ITEMS                   ,
            USR_MFB_REGIONS      => IUSR_MFB_REGIONS                 ,
            USR_MFB_REGION_SIZE  => USR_MFB_REGION_SIZE             ,
            USR_MFB_BLOCK_SIZE   => USR_MFB_BLOCK_SIZE              ,
            USR_MFB_ITEM_WIDTH   => USR_MFB_ITEM_WIDTH              ,
            USR_RX_PKT_SIZE_MAX  => USR_RX_PKT_SIZE_MAX             ,
            USR_TX_PKT_SIZE_MAX  => USR_TX_PKT_SIZE_MAX             ,
            DMA_ENDPOINTS        => DMA_EP_PER_DMA                  ,
            PCIE_MPS             => PCIE_MPS                        ,
            PCIE_MRRS            => PCIE_MRRS                       ,
            DMA_TAG_WIDTH        => DMA_TAG_WIDTH-log2(DMA_PER_PCIE),
            UP_MFB_REGIONS       => UP_MFB_REGIONS                  ,
            UP_MFB_REGION_SIZE   => UP_MFB_REGION_SIZE              ,
            UP_MFB_BLOCK_SIZE    => UP_MFB_BLOCK_SIZE               ,
            UP_MFB_ITEM_WIDTH    => UP_MFB_ITEM_WIDTH               ,
            DOWN_MFB_REGIONS     => DOWN_MFB_REGIONS                ,
            DOWN_MFB_REGION_SIZE => DOWN_MFB_REGION_SIZE            ,
            DOWN_MFB_BLOCK_SIZE  => DOWN_MFB_BLOCK_SIZE             ,
            DOWN_MFB_ITEM_WIDTH  => DOWN_MFB_ITEM_WIDTH             ,
            HDR_META_WIDTH       => HDR_META_WIDTH                  ,
            RX_CHANNELS          => RX_CHANNELS                     ,
            RX_DP_WIDTH          => RX_DP_WIDTH                     ,
            RX_HP_WIDTH          => RX_HP_WIDTH                     ,
            RX_BLOCKING_MODE     => RX_BLOCKING_MODE                ,
            TX_CHANNELS          => TX_CHANNELS                     ,
            TX_SEL_CHANNELS      => TX_SEL_CHANNELS                 ,
            TX_DP_WIDTH          => TX_DP_WIDTH                     ,
            DSP_CNT_WIDTH        => 48                              ,
            RX_GEN_EN            => RX_GEN_EN                       ,
            TX_GEN_EN            => TX_GEN_EN                       ,
            SPEED_METER_EN       => true                            ,
            DBG_CNTR_EN          => false                           ,
            USR_EQ_DMA           => USR_EQ_DMA                      ,
            CROX_EQ_DMA          => CROX_EQ_DMA                     ,
            CROX_DOUBLE_DMA      => CROX_DOUBLE_DMA                 ,
            MI_WIDTH             => 32          
        )
        port map(
            DMA_CLK              => DMA_CLK                ,
            DMA_RESET            => dma_rst_dup(PCIE_ENDPOINTS+i),

            CROX_CLK             => CROX_CLK               ,
            CROX_RESET           => crox_rst_dup(i)        ,

            USR_CLK              => USR_CLK                ,
            USR_RESET            => USR_RESET              ,

            RX_USR_MVB_LEN       => dma_rx_usr_mvb_len(i)     ,
            RX_USR_MVB_HDR_META  => dma_rx_usr_mvb_hdr_meta(i),
            RX_USR_MVB_CHANNEL   => dma_rx_usr_mvb_channel(i) ,
            RX_USR_MVB_DISCARD   => dma_rx_usr_mvb_discard(i) ,
            RX_USR_MVB_VLD       => dma_rx_usr_mvb_vld(i)     ,
            RX_USR_MVB_SRC_RDY   => dma_rx_usr_mvb_src_rdy(i) ,
            RX_USR_MVB_DST_RDY   => dma_rx_usr_mvb_dst_rdy(i) ,

            RX_USR_MFB_DATA      => dma_rx_usr_mfb_data(i)    ,
            RX_USR_MFB_SOF       => dma_rx_usr_mfb_sof(i)     ,
            RX_USR_MFB_EOF       => dma_rx_usr_mfb_eof(i)     ,
            RX_USR_MFB_SOF_POS   => dma_rx_usr_mfb_sof_pos(i) ,
            RX_USR_MFB_EOF_POS   => dma_rx_usr_mfb_eof_pos(i) ,
            RX_USR_MFB_SRC_RDY   => dma_rx_usr_mfb_src_rdy(i) ,
            RX_USR_MFB_DST_RDY   => dma_rx_usr_mfb_dst_rdy(i) ,

            TX_USR_MVB_LEN       => dma_tx_usr_mvb_len(i)     ,
            TX_USR_MVB_HDR_META  => dma_tx_usr_mvb_hdr_meta(i),
            TX_USR_MVB_CHANNEL   => dma_tx_usr_mvb_channel(i) ,
            TX_USR_MVB_VLD       => dma_tx_usr_mvb_vld(i)     ,
            TX_USR_MVB_SRC_RDY   => dma_tx_usr_mvb_src_rdy(i) ,
            TX_USR_MVB_DST_RDY   => dma_tx_usr_mvb_dst_rdy(i) ,

            TX_USR_MFB_DATA      => dma_tx_usr_mfb_data(i)    ,
            TX_USR_MFB_SOF       => dma_tx_usr_mfb_sof(i)     ,
            TX_USR_MFB_EOF       => dma_tx_usr_mfb_eof(i)     ,
            TX_USR_MFB_SOF_POS   => dma_tx_usr_mfb_sof_pos(i) ,
            TX_USR_MFB_EOF_POS   => dma_tx_usr_mfb_eof_pos(i) ,
            TX_USR_MFB_SRC_RDY   => dma_tx_usr_mfb_src_rdy(i) ,
            TX_USR_MFB_DST_RDY   => dma_tx_usr_mfb_dst_rdy(i) ,

            UP_MVB_DATA          => dma_up_mvb_data(DPE),
            UP_MVB_VLD           => UP_MVB_VLD(DPE),
            UP_MVB_SRC_RDY       => UP_MVB_SRC_RDY(DPE),
            UP_MVB_DST_RDY       => UP_MVB_DST_RDY(DPE),
                                                        
            UP_MFB_DATA          => UP_MFB_DATA(DPE),
            UP_MFB_SOF           => UP_MFB_SOF(DPE),
            UP_MFB_EOF           => UP_MFB_EOF(DPE),
            UP_MFB_SOF_POS       => UP_MFB_SOF_POS(DPE),
            UP_MFB_EOF_POS       => UP_MFB_EOF_POS(DPE),
            UP_MFB_SRC_RDY       => UP_MFB_SRC_RDY(DPE),
            UP_MFB_DST_RDY       => UP_MFB_DST_RDY(DPE),
                                                        
            DOWN_MVB_DATA        => DOWN_MVB_DATA(DPE),
            DOWN_MVB_VLD         => DOWN_MVB_VLD(DPE),
            DOWN_MVB_SRC_RDY     => DOWN_MVB_SRC_RDY(DPE),
            DOWN_MVB_DST_RDY     => DOWN_MVB_DST_RDY(DPE),
                                                        
            DOWN_MFB_DATA        => DOWN_MFB_DATA(DPE),
            DOWN_MFB_SOF         => DOWN_MFB_SOF(DPE),
            DOWN_MFB_EOF         => DOWN_MFB_EOF(DPE),
            DOWN_MFB_SOF_POS     => DOWN_MFB_SOF_POS(DPE),
            DOWN_MFB_EOF_POS     => DOWN_MFB_EOF_POS(DPE),
            DOWN_MFB_SRC_RDY     => DOWN_MFB_SRC_RDY(DPE),
            DOWN_MFB_DST_RDY     => DOWN_MFB_DST_RDY(DPE),

            MI_ADDR              => dma_end_mi_addr(DPE),
            MI_DWR               => dma_end_mi_dwr(DPE),
            MI_BE                => dma_end_mi_be(DPE),
            MI_RD                => dma_end_mi_rd(DPE),
            MI_WR                => dma_end_mi_wr(DPE),
            MI_DRD               => dma_end_mi_drd(DPE),
            MI_ARDY              => dma_end_mi_ardy(DPE),
            MI_DRDY              => dma_end_mi_drdy(DPE)
        );
    end generate;

    -- =====================================================================

    dma_demo_off_g : if (not DMA_400G_DEMO) generate
        rx_usr_arr_mvb_len      <= slv_array_deser(RX_USR_MVB_LEN,NUM_DMA);
        rx_usr_arr_mvb_hdr_meta <= slv_array_deser(RX_USR_MVB_HDR_META,NUM_DMA);
        rx_usr_arr_mvb_channel  <= slv_array_deser(RX_USR_MVB_CHANNEL,NUM_DMA);
        rx_usr_arr_mvb_discard  <= slv_array_deser(RX_USR_MVB_DISCARD,NUM_DMA);
        rx_usr_arr_mvb_vld      <= slv_array_deser(RX_USR_MVB_VLD,NUM_DMA);
        rx_usr_arr_mvb_src_rdy  <= RX_USR_MVB_SRC_RDY;
        RX_USR_MVB_DST_RDY      <= rx_usr_arr_mvb_dst_rdy;
        
        rx_usr_arr_mfb_data     <= slv_array_deser(RX_USR_MFB_DATA,NUM_DMA);
        rx_usr_arr_mfb_sof      <= slv_array_deser(RX_USR_MFB_SOF,NUM_DMA);
        rx_usr_arr_mfb_eof      <= slv_array_deser(RX_USR_MFB_EOF,NUM_DMA);
        rx_usr_arr_mfb_sof_pos  <= slv_array_deser(RX_USR_MFB_SOF_POS,NUM_DMA);
        rx_usr_arr_mfb_eof_pos  <= slv_array_deser(RX_USR_MFB_EOF_POS,NUM_DMA);
        rx_usr_arr_mfb_src_rdy  <= RX_USR_MFB_SRC_RDY;
        RX_USR_MFB_DST_RDY      <= rx_usr_arr_mfb_dst_rdy;

        TX_USR_MVB_LEN          <= slv_array_ser(tx_usr_arr_mvb_len);
        TX_USR_MVB_HDR_META     <= slv_array_ser(tx_usr_arr_mvb_hdr_meta);
        TX_USR_MVB_CHANNEL      <= slv_array_ser(tx_usr_arr_mvb_channel);
        TX_USR_MVB_VLD          <= slv_array_ser(tx_usr_arr_mvb_vld);
        TX_USR_MVB_SRC_RDY      <= tx_usr_arr_mvb_src_rdy;
        tx_usr_arr_mvb_dst_rdy  <= TX_USR_MVB_DST_RDY;

        TX_USR_MFB_DATA         <= slv_array_ser(tx_usr_arr_mfb_data);
        TX_USR_MFB_SOF          <= slv_array_ser(tx_usr_arr_mfb_sof);
        TX_USR_MFB_EOF          <= slv_array_ser(tx_usr_arr_mfb_eof);
        TX_USR_MFB_SOF_POS      <= slv_array_ser(tx_usr_arr_mfb_sof_pos);
        TX_USR_MFB_EOF_POS      <= slv_array_ser(tx_usr_arr_mfb_eof_pos);
        TX_USR_MFB_SRC_RDY      <= tx_usr_arr_mfb_src_rdy;
        tx_usr_arr_mfb_dst_rdy  <= TX_USR_MFB_DST_RDY;
    end generate;

    dma_demo_on_g : if (DMA_400G_DEMO) generate
        rx_usr_arr_mvb_len      <= (others => (others => '0'));
        rx_usr_arr_mvb_hdr_meta <= (others => (others => '0'));
        rx_usr_arr_mvb_channel  <= (others => (others => '0'));
        rx_usr_arr_mvb_discard  <= (others => (others => '0'));
        rx_usr_arr_mvb_vld      <= (others => (others => '0'));
        rx_usr_arr_mvb_src_rdy  <= (others => '0');
        RX_USR_MVB_DST_RDY      <= (others => '1');
        
        rx_usr_arr_mfb_data     <= (others => (others => '0'));
        rx_usr_arr_mfb_sof      <= (others => (others => '0'));
        rx_usr_arr_mfb_eof      <= (others => (others => '0'));
        rx_usr_arr_mfb_sof_pos  <= (others => (others => '0'));
        rx_usr_arr_mfb_eof_pos  <= (others => (others => '0'));
        rx_usr_arr_mfb_src_rdy  <= (others => '0');
        RX_USR_MFB_DST_RDY      <= (others => '1');

        TX_USR_MVB_LEN          <= (others => '0');
        TX_USR_MVB_HDR_META     <= (others => '0');
        TX_USR_MVB_CHANNEL      <= (others => '0');
        TX_USR_MVB_VLD          <= (others => '0');
        TX_USR_MVB_SRC_RDY      <= (others => '0');
        tx_usr_arr_mvb_dst_rdy  <= (others => '1');

        TX_USR_MFB_DATA         <= (others => '0');
        TX_USR_MFB_SOF          <= (others => '0');
        TX_USR_MFB_EOF          <= (others => '0');
        TX_USR_MFB_SOF_POS      <= (others => '0');
        TX_USR_MFB_EOF_POS      <= (others => '0');
        TX_USR_MFB_SRC_RDY      <= (others => '0');
        tx_usr_arr_mfb_dst_rdy  <= (others => '1');
    end generate;

    mi_splitter_gls_i : entity work.MI_SPLITTER_PLUS_GEN
    generic map(
        ADDR_WIDTH  => 32,
        DATA_WIDTH  => 32,
        META_WIDTH  => 0,
        PORTS       => NUM_DMA,
        ADDR_BASE   => gls_mi_addr_base_f,
        DEVICE      => DEVICE
    )
    port map(
        CLK         => MI_CLK,
        RESET       => MI_RESET,

        RX_DWR      => GEN_LOOP_MI_DWR,
        RX_ADDR     => GEN_LOOP_MI_ADDR,
        RX_BE       => GEN_LOOP_MI_BE,
        RX_RD       => GEN_LOOP_MI_RD,
        RX_WR       => GEN_LOOP_MI_WR,
        RX_ARDY     => GEN_LOOP_MI_ARDY,
        RX_DRD      => GEN_LOOP_MI_DRD,
        RX_DRDY     => GEN_LOOP_MI_DRDY,

        TX_DWR      => gls_mi_dwr,
        TX_ADDR     => gls_mi_addr,
        TX_BE       => gls_mi_be,
        TX_RD       => gls_mi_rd,
        TX_WR       => gls_mi_wr,
        TX_ARDY     => gls_mi_ardy,
        TX_DRD      => gls_mi_drd,
        TX_DRDY     => gls_mi_drdy
    );

    gls_g : for i in 0 to NUM_DMA-1 generate
        gls_en_g : if (GEN_LOOP_EN or DMA_400G_DEMO) generate
            gen_loop_switch_i : entity work.GEN_LOOP_SWITCH
            generic map(
                REGIONS           => IUSR_MFB_REGIONS    ,
                REGION_SIZE       => USR_MFB_REGION_SIZE,
                BLOCK_SIZE        => USR_MFB_BLOCK_SIZE ,
                ITEM_WIDTH        => USR_MFB_ITEM_WIDTH ,
                PKT_MTU           => USR_RX_PKT_SIZE_MAX,
                RX_DMA_CHANNELS   => RX_CHANNELS        ,
                TX_DMA_CHANNELS   => TX_CHANNELS        ,
                HDR_META_WIDTH    => HDR_META_WIDTH     ,
                RX_HDR_INS_EN     => false              , -- only enable for version 1 to DMA Medusa
                SAME_CLK          => false              ,
                MI_PIPE_EN        => true               ,
                DEVICE            => DEVICE
            ) 
            port map(
                MI_CLK              => MI_CLK,
                MI_RESET            => MI_RESET,
                MI_DWR              => gls_mi_dwr(i),
                MI_ADDR             => gls_mi_addr(i),
                MI_BE               => gls_mi_be(i),
                MI_RD               => gls_mi_rd(i),
                MI_WR               => gls_mi_wr(i),
                MI_ARDY             => gls_mi_ardy(i),
                MI_DRD              => gls_mi_drd(i),
                MI_DRDY             => gls_mi_drdy(i),

                CLK                 => USR_CLK                ,
                RESET               => USR_RESET              ,

                ETH_RX_MVB_LEN      => rx_usr_arr_mvb_len(i)     ,
                ETH_RX_MVB_HDR_META => rx_usr_arr_mvb_hdr_meta(i),
                ETH_RX_MVB_CHANNEL  => rx_usr_arr_mvb_channel(i) ,
                ETH_RX_MVB_DISCARD  => rx_usr_arr_mvb_discard(i) ,
                ETH_RX_MVB_VLD      => rx_usr_arr_mvb_vld(i)     ,
                ETH_RX_MVB_SRC_RDY  => rx_usr_arr_mvb_src_rdy(i) ,
                ETH_RX_MVB_DST_RDY  => rx_usr_arr_mvb_dst_rdy(i) ,

                ETH_RX_MFB_DATA     => rx_usr_arr_mfb_data(i)    ,
                ETH_RX_MFB_SOF      => rx_usr_arr_mfb_sof(i)     ,
                ETH_RX_MFB_EOF      => rx_usr_arr_mfb_eof(i)     ,
                ETH_RX_MFB_SOF_POS  => rx_usr_arr_mfb_sof_pos(i) ,
                ETH_RX_MFB_EOF_POS  => rx_usr_arr_mfb_eof_pos(i) ,
                ETH_RX_MFB_SRC_RDY  => rx_usr_arr_mfb_src_rdy(i) ,
                ETH_RX_MFB_DST_RDY  => rx_usr_arr_mfb_dst_rdy(i) ,

                ETH_TX_MVB_LEN      => tx_usr_arr_mvb_len(i)     ,
                ETH_TX_MVB_HDR_META => tx_usr_arr_mvb_hdr_meta(i),
                ETH_TX_MVB_CHANNEL  => tx_usr_arr_mvb_channel(i) ,
                ETH_TX_MVB_VLD      => tx_usr_arr_mvb_vld(i)     ,
                ETH_TX_MVB_SRC_RDY  => tx_usr_arr_mvb_src_rdy(i) ,
                ETH_TX_MVB_DST_RDY  => tx_usr_arr_mvb_dst_rdy(i) ,

                ETH_TX_MFB_DATA     => tx_usr_arr_mfb_data(i)    ,
                ETH_TX_MFB_SOF      => tx_usr_arr_mfb_sof(i)     ,
                ETH_TX_MFB_EOF      => tx_usr_arr_mfb_eof(i)     ,
                ETH_TX_MFB_SOF_POS  => tx_usr_arr_mfb_sof_pos(i) ,
                ETH_TX_MFB_EOF_POS  => tx_usr_arr_mfb_eof_pos(i) ,
                ETH_TX_MFB_SRC_RDY  => tx_usr_arr_mfb_src_rdy(i) ,
                ETH_TX_MFB_DST_RDY  => tx_usr_arr_mfb_dst_rdy(i) ,

                DMA_RX_MVB_LEN      => dma_rx_usr_mvb_len(i)     ,
                DMA_RX_MVB_HDR_META => dma_rx_usr_mvb_hdr_meta(i),
                DMA_RX_MVB_CHANNEL  => dma_rx_usr_mvb_channel(i) ,
                DMA_RX_MVB_DISCARD  => dma_rx_usr_mvb_discard(i) ,
                DMA_RX_MVB_VLD      => dma_rx_usr_mvb_vld(i)     ,
                DMA_RX_MVB_SRC_RDY  => dma_rx_usr_mvb_src_rdy(i) ,
                DMA_RX_MVB_DST_RDY  => dma_rx_usr_mvb_dst_rdy(i) ,

                DMA_RX_MFB_DATA     => dma_rx_usr_mfb_data(i)    ,
                DMA_RX_MFB_SOF      => dma_rx_usr_mfb_sof(i)     ,
                DMA_RX_MFB_EOF      => dma_rx_usr_mfb_eof(i)     ,
                DMA_RX_MFB_SOF_POS  => dma_rx_usr_mfb_sof_pos(i) ,
                DMA_RX_MFB_EOF_POS  => dma_rx_usr_mfb_eof_pos(i) ,
                DMA_RX_MFB_SRC_RDY  => dma_rx_usr_mfb_src_rdy(i) ,
                DMA_RX_MFB_DST_RDY  => dma_rx_usr_mfb_dst_rdy(i) ,

                DMA_TX_MVB_LEN      => dma_tx_usr_mvb_len(i)     ,
                DMA_TX_MVB_HDR_META => dma_tx_usr_mvb_hdr_meta(i),
                DMA_TX_MVB_CHANNEL  => dma_tx_usr_mvb_channel(i) ,
                DMA_TX_MVB_VLD      => dma_tx_usr_mvb_vld(i)     ,
                DMA_TX_MVB_SRC_RDY  => dma_tx_usr_mvb_src_rdy(i) ,
                DMA_TX_MVB_DST_RDY  => dma_tx_usr_mvb_dst_rdy(i) ,
                
                DMA_TX_MFB_DATA     => dma_tx_usr_mfb_data(i)    ,
                DMA_TX_MFB_SOF      => dma_tx_usr_mfb_sof(i)     ,
                DMA_TX_MFB_EOF      => dma_tx_usr_mfb_eof(i)     ,
                DMA_TX_MFB_SOF_POS  => dma_tx_usr_mfb_sof_pos(i) ,
                DMA_TX_MFB_EOF_POS  => dma_tx_usr_mfb_eof_pos(i) ,
                DMA_TX_MFB_SRC_RDY  => dma_tx_usr_mfb_src_rdy(i) ,
                DMA_TX_MFB_DST_RDY  => dma_tx_usr_mfb_dst_rdy(i)
            );
        else generate
            dma_rx_usr_mvb_len(i)      <= rx_usr_arr_mvb_len(i)     ;
            dma_rx_usr_mvb_hdr_meta(i) <= rx_usr_arr_mvb_hdr_meta(i);
            dma_rx_usr_mvb_channel(i)  <= rx_usr_arr_mvb_channel(i) ;
            dma_rx_usr_mvb_discard(i)  <= rx_usr_arr_mvb_discard(i) ;
            dma_rx_usr_mvb_vld(i)      <= rx_usr_arr_mvb_vld(i)     ;
            dma_rx_usr_mvb_src_rdy(i)  <= rx_usr_arr_mvb_src_rdy(i) ;
            rx_usr_arr_mvb_dst_rdy(i)  <= dma_rx_usr_mvb_dst_rdy(i) ;
            dma_rx_usr_mfb_data(i)     <= rx_usr_arr_mfb_data(i)    ;
            dma_rx_usr_mfb_sof(i)      <= rx_usr_arr_mfb_sof(i)     ;
            dma_rx_usr_mfb_eof(i)      <= rx_usr_arr_mfb_eof(i)     ;
            dma_rx_usr_mfb_sof_pos(i)  <= rx_usr_arr_mfb_sof_pos(i) ;
            dma_rx_usr_mfb_eof_pos(i)  <= rx_usr_arr_mfb_eof_pos(i) ;
            dma_rx_usr_mfb_src_rdy(i)  <= rx_usr_arr_mfb_src_rdy(i) ;
            rx_usr_arr_mfb_dst_rdy(i)  <= dma_rx_usr_mfb_dst_rdy(i) ;
            tx_usr_arr_mvb_len(i)      <= dma_tx_usr_mvb_len(i)     ;
            tx_usr_arr_mvb_hdr_meta(i) <= dma_tx_usr_mvb_hdr_meta(i);
            tx_usr_arr_mvb_channel(i)  <= dma_tx_usr_mvb_channel(i) ;
            tx_usr_arr_mvb_vld(i)      <= dma_tx_usr_mvb_vld(i)     ;
            tx_usr_arr_mvb_src_rdy(i)  <= dma_tx_usr_mvb_src_rdy(i) ;
            dma_tx_usr_mvb_dst_rdy(i)  <= tx_usr_arr_mvb_dst_rdy(i) ;
            tx_usr_arr_mfb_data(i)     <= dma_tx_usr_mfb_data(i)    ;
            tx_usr_arr_mfb_sof(i)      <= dma_tx_usr_mfb_sof(i)     ;
            tx_usr_arr_mfb_eof(i)      <= dma_tx_usr_mfb_eof(i)     ;
            tx_usr_arr_mfb_sof_pos(i)  <= dma_tx_usr_mfb_sof_pos(i) ;
            tx_usr_arr_mfb_eof_pos(i)  <= dma_tx_usr_mfb_eof_pos(i) ;
            tx_usr_arr_mfb_src_rdy(i)  <= dma_tx_usr_mfb_src_rdy(i) ;
            dma_tx_usr_mfb_dst_rdy(i)  <= tx_usr_arr_mfb_dst_rdy(i) ;

            gls_mi_ardy(i) <= '1';
            gls_mi_drd(i)  <= (others => '0');
            gls_mi_drdy(i) <= '0';
        end generate;
    end generate;

    -- =====================================================================

end architecture;
