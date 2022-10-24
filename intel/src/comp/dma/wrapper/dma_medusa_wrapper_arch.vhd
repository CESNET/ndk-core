-- dma.vhd: DMA Module Wrapper
-- Copyright (C) 2020 CESNET z. s. p. o.
-- Author(s): Jan Kubalek <kubalek@cesnet.cz>
--            Vladislav Valek <valekv@cesnet.cz>
--
-- SPDX-License-Identifier: BSD-3-Clause

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.math_pack.all;
use work.type_pack.all;

use work.dma_bus_pack.all;

architecture MEDUSA of DMA_WRAPPER is

    constant DMA_PER_PCIE      : natural := DMA_ENDPOINTS/PCIE_ENDPOINTS;
    constant DMA_EP_PER_DMA    : natural := DMA_ENDPOINTS/DMA_STREAMS;
    constant DMA_RST_REPLICAS  : natural := DMA_STREAMS+PCIE_ENDPOINTS;
    constant CROX_RST_REPLICAS : natural := DMA_STREAMS;

    signal dma_rst_dup  : std_logic_vector(DMA_RST_REPLICAS-1 downto 0);
    signal crox_rst_dup : std_logic_vector(CROX_RST_REPLICAS-1 downto 0);

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

    signal dma_up_mvb_data : slv_array_t(DMA_ENDPOINTS-1 downto 0)(UP_MFB_REGIONS*DMA_UPHDR_WIDTH-1 downto 0);
    signal UP_MVB_DATA_arr : slv_array_2d_t(DMA_ENDPOINTS-1 downto 0)(UP_MFB_REGIONS-1 downto 0)(DMA_UPHDR_WIDTH-1 downto 0);
    signal UP_MVB_DATA_vec : std_logic_vector(DMA_ENDPOINTS*UP_MFB_REGIONS*DMA_UPHDR_WIDTH-1 downto 0);

    -- =====================================================================
begin

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
            ADDR_WIDTH => MI_WIDTH,
            DATA_WIDTH => MI_WIDTH,
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
    --  DMA Medusa Module
    -- =====================================================================

    dma_medusa_g : for i in 0 to DMA_STREAMS-1 generate
        subtype DPE is natural range (i+1)*DMA_EP_PER_DMA-1 downto i*DMA_EP_PER_DMA;
    begin
        dma_medusa_i : entity work.DMA_MEDUSA
        generic map(
            DEVICE               => DEVICE                          ,

            USR_MVB_ITEMS        => USR_MVB_ITEMS                   ,
            USR_MFB_REGIONS      => USR_MFB_REGIONS                 ,
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
            RX_BLOCKING_MODE     => RX_BLOCKING_MODE,

            TX_CHANNELS          => TX_CHANNELS                     ,
            TX_SEL_CHANNELS      => TX_SEL_CHANNELS                 ,
            TX_DP_WIDTH          => TX_DP_WIDTH                     ,

            DSP_CNT_WIDTH        => DSP_CNT_WIDTH                   ,

            RX_GEN_EN            => RX_GEN_EN                       ,
            TX_GEN_EN            => TX_GEN_EN                       ,

            SPEED_METER_EN       => true                            ,
            DBG_CNTR_EN          => false                           ,
            USR_EQ_DMA           => USR_EQ_DMA                      ,
            CROX_EQ_DMA          => CROX_EQ_DMA                     ,
            CROX_DOUBLE_DMA      => CROX_DOUBLE_DMA                 ,

            MI_WIDTH             => MI_WIDTH
        )
        port map(
            DMA_CLK              => DMA_CLK                ,
            DMA_RESET            => dma_rst_dup(PCIE_ENDPOINTS+i),

            CROX_CLK             => CROX_CLK               ,
            CROX_RESET           => crox_rst_dup(i)        ,

            USR_CLK              => USR_CLK                ,
            USR_RESET            => USR_RESET              ,

            RX_USR_MVB_LEN       => RX_USR_MVB_LEN(i)     ,
            RX_USR_MVB_HDR_META  => RX_USR_MVB_HDR_META(i),
            RX_USR_MVB_CHANNEL   => RX_USR_MVB_CHANNEL(i) ,
            RX_USR_MVB_DISCARD   => RX_USR_MVB_DISCARD(i) ,
            RX_USR_MVB_VLD       => RX_USR_MVB_VLD(i)     ,
            RX_USR_MVB_SRC_RDY   => RX_USR_MVB_SRC_RDY(i) ,
            RX_USR_MVB_DST_RDY   => RX_USR_MVB_DST_RDY(i) ,

            RX_USR_MFB_DATA      => RX_USR_MFB_DATA(i)    ,
            RX_USR_MFB_SOF       => RX_USR_MFB_SOF(i)     ,
            RX_USR_MFB_EOF       => RX_USR_MFB_EOF(i)     ,
            RX_USR_MFB_SOF_POS   => RX_USR_MFB_SOF_POS(i) ,
            RX_USR_MFB_EOF_POS   => RX_USR_MFB_EOF_POS(i) ,
            RX_USR_MFB_SRC_RDY   => RX_USR_MFB_SRC_RDY(i) ,
            RX_USR_MFB_DST_RDY   => RX_USR_MFB_DST_RDY(i) ,

            TX_USR_MVB_LEN       => TX_USR_MVB_LEN(i)     ,
            TX_USR_MVB_HDR_META  => TX_USR_MVB_HDR_META(i),
            TX_USR_MVB_CHANNEL   => TX_USR_MVB_CHANNEL(i) ,
            TX_USR_MVB_VLD       => TX_USR_MVB_VLD(i)     ,
            TX_USR_MVB_SRC_RDY   => TX_USR_MVB_SRC_RDY(i) ,
            TX_USR_MVB_DST_RDY   => TX_USR_MVB_DST_RDY(i) ,

            TX_USR_MFB_DATA      => TX_USR_MFB_DATA(i)    ,
            TX_USR_MFB_SOF       => TX_USR_MFB_SOF(i)     ,
            TX_USR_MFB_EOF       => TX_USR_MFB_EOF(i)     ,
            TX_USR_MFB_SOF_POS   => TX_USR_MFB_SOF_POS(i) ,
            TX_USR_MFB_EOF_POS   => TX_USR_MFB_EOF_POS(i) ,
            TX_USR_MFB_SRC_RDY   => TX_USR_MFB_SRC_RDY(i) ,
            TX_USR_MFB_DST_RDY   => TX_USR_MFB_DST_RDY(i) ,

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

end architecture;
