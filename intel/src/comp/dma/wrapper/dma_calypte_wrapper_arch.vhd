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
use work.pcie_meta_pack.all;

architecture CALYPTE of DMA_WRAPPER is

    --==============================================================================================
    --  MI Async and Splitting
    --==============================================================================================
    constant MI_SPLIT_PORTS : natural := 4;
    constant MI_SPLIT_BASES : slv_array_t(MI_SPLIT_PORTS-1 downto 0)(MI_WIDTH-1 downto 0) := (
        0 => X"00000000",               -- DMA Controller
        1 => X"00300000",               -- TSU unit
        2 => X"00380000",               -- MFB loopback
        3 => X"003C0000");              -- TX DMA Debug Core
    constant MI_SPLIT_ADDR_MASK : std_logic_vector(MI_WIDTH -1 downto 0) := X"003C0000";

    constant OUT_PIPE_EN : boolean := TRUE;

    constant TX_DMA_DBG_CORE_EN   : boolean := FALSE;
    constant DMA_LOOPBACK_EN      : boolean := FALSE;
    constant ST_SP_DBG_META_WIDTH : natural := 4;

    constant DMA_MFB_REGIONS      : integer := 1;
    constant DMA_MFB_REGION_SIZE  : integer := PCIE_RQ_MFB_REGIONS*4;
    constant DMA_MFB_BLOCK_SIZE   : integer := 8;
    constant DMA_MFB_ITEM_WIDTH   : integer := 8;

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
    -- Metadata insertor ---> FIFOX
    --==============================================================================================
    signal rx_usr_mfb_data_res        : slv_array_t(DMA_STREAMS-1 downto 0)(USR_MFB_REGIONS*USR_MFB_REGION_SIZE*USR_MFB_BLOCK_SIZE*USR_MFB_ITEM_WIDTH -1 downto 0);
    signal rx_usr_mfb_meta_res        : slv_array_t(DMA_STREAMS-1 downto 0)(log2(USR_RX_PKT_SIZE_MAX +1)+log2(RX_CHANNELS)+HDR_META_WIDTH             -1 downto 0);
    signal rx_usr_mfb_sof_res         : slv_array_t(DMA_STREAMS-1 downto 0)(USR_MFB_REGIONS                                                           -1 downto 0);
    signal rx_usr_mfb_eof_res         : slv_array_t(DMA_STREAMS-1 downto 0)(USR_MFB_REGIONS                                                           -1 downto 0);
    signal rx_usr_mfb_sof_pos_res     : slv_array_t(DMA_STREAMS-1 downto 0)(USR_MFB_REGIONS*max(1,log2(USR_MFB_REGION_SIZE))                          -1 downto 0);
    signal rx_usr_mfb_eof_pos_res     : slv_array_t(DMA_STREAMS-1 downto 0)(USR_MFB_REGIONS*max(1,log2(USR_MFB_REGION_SIZE*USR_MFB_BLOCK_SIZE))       -1 downto 0);
    signal rx_usr_mfb_src_rdy_res     : std_logic_vector(DMA_STREAMS-1 downto 0);
    signal rx_usr_mfb_dst_rdy_res     : std_logic_vector(DMA_STREAMS-1 downto 0);

    signal rx_usr_mfb_data_async      : slv_array_t(DMA_STREAMS-1 downto 0)(DMA_MFB_REGIONS*DMA_MFB_REGION_SIZE*DMA_MFB_BLOCK_SIZE*DMA_MFB_ITEM_WIDTH -1 downto 0);
    signal rx_usr_mfb_meta_async      : slv_array_t(DMA_STREAMS-1 downto 0)(log2(USR_RX_PKT_SIZE_MAX +1)+log2(RX_CHANNELS)+HDR_META_WIDTH             -1 downto 0);
    signal rx_usr_mfb_sof_async       : slv_array_t(DMA_STREAMS-1 downto 0)(DMA_MFB_REGIONS                                                           -1 downto 0);
    signal rx_usr_mfb_eof_async       : slv_array_t(DMA_STREAMS-1 downto 0)(DMA_MFB_REGIONS                                                           -1 downto 0);
    signal rx_usr_mfb_sof_pos_async   : slv_array_t(DMA_STREAMS-1 downto 0)(DMA_MFB_REGIONS*max(1,log2(DMA_MFB_REGION_SIZE))                          -1 downto 0);
    signal rx_usr_mfb_eof_pos_async   : slv_array_t(DMA_STREAMS-1 downto 0)(DMA_MFB_REGIONS*max(1,log2(DMA_MFB_REGION_SIZE*DMA_MFB_BLOCK_SIZE))       -1 downto 0);
    signal rx_usr_mfb_src_rdy_async   : std_logic_vector(DMA_STREAMS-1 downto 0);
    signal rx_usr_mfb_dst_rdy_async   : std_logic_vector(DMA_STREAMS-1 downto 0);

    --==============================================================================================
    -- FIFOX ---> Metadata extractor
    --==============================================================================================
    signal tx_usr_mfb_data_res        : slv_array_t(DMA_STREAMS-1 downto 0)(USR_MFB_REGIONS*USR_MFB_REGION_SIZE*USR_MFB_BLOCK_SIZE*USR_MFB_ITEM_WIDTH-1 downto 0);
    signal tx_usr_mfb_meta_res        : slv_array_t(DMA_STREAMS-1 downto 0)(log2(USR_TX_PKT_SIZE_MAX+1)+HDR_META_WIDTH+log2(TX_CHANNELS)             -1 downto 0);
    signal tx_usr_mfb_sof_res         : slv_array_t(DMA_STREAMS-1 downto 0)(USR_MFB_REGIONS                                                          -1 downto 0);
    signal tx_usr_mfb_eof_res         : slv_array_t(DMA_STREAMS-1 downto 0)(USR_MFB_REGIONS                                                          -1 downto 0);
    signal tx_usr_mfb_sof_pos_res     : slv_array_t(DMA_STREAMS-1 downto 0)(USR_MFB_REGIONS*max(1,log2(USR_MFB_REGION_SIZE))                         -1 downto 0);
    signal tx_usr_mfb_eof_pos_res     : slv_array_t(DMA_STREAMS-1 downto 0)(USR_MFB_REGIONS*max(1,log2(USR_MFB_REGION_SIZE*USR_MFB_BLOCK_SIZE))      -1 downto 0);
    signal tx_usr_mfb_src_rdy_res     : std_logic_vector(DMA_STREAMS-1 downto 0);
    signal tx_usr_mfb_dst_rdy_res     : std_logic_vector(DMA_STREAMS-1 downto 0);

    signal tx_usr_mfb_data_async      : slv_array_t(DMA_STREAMS-1 downto 0)(DMA_MFB_REGIONS*DMA_MFB_REGION_SIZE*DMA_MFB_BLOCK_SIZE*DMA_MFB_ITEM_WIDTH-1 downto 0);
    signal tx_usr_mfb_meta_async      : slv_array_t(DMA_STREAMS-1 downto 0)(log2(USR_TX_PKT_SIZE_MAX+1)+HDR_META_WIDTH+log2(TX_CHANNELS)             -1 downto 0);
    signal tx_usr_mfb_sof_async       : slv_array_t(DMA_STREAMS-1 downto 0)(DMA_MFB_REGIONS                                                          -1 downto 0);
    signal tx_usr_mfb_eof_async       : slv_array_t(DMA_STREAMS-1 downto 0)(DMA_MFB_REGIONS                                                          -1 downto 0);
    signal tx_usr_mfb_sof_pos_async   : slv_array_t(DMA_STREAMS-1 downto 0)(DMA_MFB_REGIONS*max(1,log2(DMA_MFB_REGION_SIZE))                         -1 downto 0);
    signal tx_usr_mfb_eof_pos_async   : slv_array_t(DMA_STREAMS-1 downto 0)(DMA_MFB_REGIONS*max(1,log2(DMA_MFB_REGION_SIZE*DMA_MFB_BLOCK_SIZE))      -1 downto 0);
    signal tx_usr_mfb_src_rdy_async   : std_logic_vector(DMA_STREAMS-1 downto 0);
    signal tx_usr_mfb_dst_rdy_async   : std_logic_vector(DMA_STREAMS-1 downto 0);

    --==============================================================================================
    --  MFB ASFIFOX ---> Loopback Module interface
    --==============================================================================================
    signal rx_usr_mfb_data_sync      : slv_array_t(DMA_STREAMS-1 downto 0)(DMA_MFB_REGIONS*DMA_MFB_REGION_SIZE*DMA_MFB_BLOCK_SIZE*DMA_MFB_ITEM_WIDTH-1 downto 0);
    signal rx_usr_mfb_meta_sync      : slv_array_t(DMA_STREAMS-1 downto 0)(log2(USR_RX_PKT_SIZE_MAX+1)+HDR_META_WIDTH+log2(RX_CHANNELS)             -1 downto 0);
    signal rx_usr_mfb_sof_sync       : slv_array_t(DMA_STREAMS-1 downto 0)(DMA_MFB_REGIONS                                                          -1 downto 0);
    signal rx_usr_mfb_eof_sync       : slv_array_t(DMA_STREAMS-1 downto 0)(DMA_MFB_REGIONS                                                          -1 downto 0);
    signal rx_usr_mfb_sof_pos_sync   : slv_array_t(DMA_STREAMS-1 downto 0)(DMA_MFB_REGIONS*max(1,log2(DMA_MFB_REGION_SIZE))                         -1 downto 0);
    signal rx_usr_mfb_eof_pos_sync   : slv_array_t(DMA_STREAMS-1 downto 0)(DMA_MFB_REGIONS*max(1,log2(DMA_MFB_REGION_SIZE*DMA_MFB_BLOCK_SIZE))      -1 downto 0);
    signal rx_usr_mfb_src_rdy_sync   : std_logic_vector(DMA_STREAMS-1 downto 0);
    signal rx_usr_mfb_dst_rdy_sync   : std_logic_vector(DMA_STREAMS-1 downto 0);

    --==============================================================================================
    --  Loopback Module ---> MFB ASFIFOX interface
    --==============================================================================================
    signal tx_usr_mfb_data_sync      : slv_array_t(DMA_STREAMS-1 downto 0)(DMA_MFB_REGIONS*DMA_MFB_REGION_SIZE*DMA_MFB_BLOCK_SIZE*DMA_MFB_ITEM_WIDTH-1 downto 0);
    signal tx_usr_mfb_meta_sync      : slv_array_t(DMA_STREAMS-1 downto 0)(log2(USR_TX_PKT_SIZE_MAX+1)+HDR_META_WIDTH+log2(TX_CHANNELS)             -1 downto 0);
    signal tx_usr_mfb_sof_sync       : slv_array_t(DMA_STREAMS-1 downto 0)(DMA_MFB_REGIONS                                                          -1 downto 0);
    signal tx_usr_mfb_eof_sync       : slv_array_t(DMA_STREAMS-1 downto 0)(DMA_MFB_REGIONS                                                          -1 downto 0);
    signal tx_usr_mfb_sof_pos_sync   : slv_array_t(DMA_STREAMS-1 downto 0)(DMA_MFB_REGIONS*max(1,log2(DMA_MFB_REGION_SIZE))                         -1 downto 0);
    signal tx_usr_mfb_eof_pos_sync   : slv_array_t(DMA_STREAMS-1 downto 0)(DMA_MFB_REGIONS*max(1,log2(DMA_MFB_REGION_SIZE*DMA_MFB_BLOCK_SIZE))      -1 downto 0);
    signal tx_usr_mfb_src_rdy_sync   : std_logic_vector(DMA_STREAMS-1 downto 0);
    signal tx_usr_mfb_dst_rdy_sync   : std_logic_vector(DMA_STREAMS-1 downto 0);

    --==============================================================================================
    --  Loopback ---> DMA Module interface
    --==============================================================================================
    signal rx_usr_mfb_meta_len       : slv_array_t(DMA_STREAMS-1 downto 0)(log2(USR_RX_PKT_SIZE_MAX+1)-1 downto 0);
    signal rx_usr_mfb_meta_hdr_meta  : slv_array_t(DMA_STREAMS-1 downto 0)(HDR_META_WIDTH             -1 downto 0);
    signal rx_usr_mfb_meta_channel   : slv_array_t(DMA_STREAMS-1 downto 0)(log2(RX_CHANNELS)          -1 downto 0);

    signal rx_usr_mfb_data_lbk      : slv_array_t(DMA_STREAMS-1 downto 0)(DMA_MFB_REGIONS*DMA_MFB_REGION_SIZE*DMA_MFB_BLOCK_SIZE*DMA_MFB_ITEM_WIDTH-1 downto 0);
    signal rx_usr_mfb_meta_lbk      : slv_array_t(DMA_STREAMS-1 downto 0)(log2(USR_RX_PKT_SIZE_MAX+1)+HDR_META_WIDTH+log2(RX_CHANNELS)             -1 downto 0);
    signal rx_usr_mfb_sof_lbk       : slv_array_t(DMA_STREAMS-1 downto 0)(DMA_MFB_REGIONS                                                          -1 downto 0);
    signal rx_usr_mfb_eof_lbk       : slv_array_t(DMA_STREAMS-1 downto 0)(DMA_MFB_REGIONS                                                          -1 downto 0);
    signal rx_usr_mfb_sof_pos_lbk   : slv_array_t(DMA_STREAMS-1 downto 0)(DMA_MFB_REGIONS*max(1,log2(DMA_MFB_REGION_SIZE))                         -1 downto 0);
    signal rx_usr_mfb_eof_pos_lbk   : slv_array_t(DMA_STREAMS-1 downto 0)(DMA_MFB_REGIONS*max(1,log2(DMA_MFB_REGION_SIZE*DMA_MFB_BLOCK_SIZE))      -1 downto 0);
    signal rx_usr_mfb_src_rdy_lbk   : std_logic_vector(DMA_STREAMS-1 downto 0);
    signal rx_usr_mfb_dst_rdy_lbk   : std_logic_vector(DMA_STREAMS-1 downto 0);

    --==============================================================================================
    --  DMA Module --->  Debug Core interface
    --==============================================================================================
    signal force_reset_dbg              : std_logic_vector(DMA_STREAMS-1 downto 0);
    signal tx_usr_mfb_meta_len_dbg      : slv_array_t(DMA_STREAMS-1 downto 0)(log2(USR_TX_PKT_SIZE_MAX+1)-1 downto 0);
    signal tx_usr_mfb_meta_hdr_meta_dbg : slv_array_t(DMA_STREAMS-1 downto 0)(HDR_META_WIDTH             -1 downto 0);
    signal tx_usr_mfb_meta_channel_dbg  : slv_array_t(DMA_STREAMS-1 downto 0)(log2(TX_CHANNELS)          -1 downto 0);

    signal tx_usr_mfb_data_dbg          : slv_array_t(DMA_STREAMS-1 downto 0)(DMA_MFB_REGIONS*DMA_MFB_REGION_SIZE*DMA_MFB_BLOCK_SIZE*DMA_MFB_ITEM_WIDTH-1 downto 0);
    signal tx_usr_mfb_sof_dbg           : slv_array_t(DMA_STREAMS-1 downto 0)(DMA_MFB_REGIONS                                                          -1 downto 0);
    signal tx_usr_mfb_eof_dbg           : slv_array_t(DMA_STREAMS-1 downto 0)(DMA_MFB_REGIONS                                                          -1 downto 0);
    signal tx_usr_mfb_sof_pos_dbg       : slv_array_t(DMA_STREAMS-1 downto 0)(DMA_MFB_REGIONS*max(1,log2(DMA_MFB_REGION_SIZE))                         -1 downto 0);
    signal tx_usr_mfb_eof_pos_dbg       : slv_array_t(DMA_STREAMS-1 downto 0)(DMA_MFB_REGIONS*max(1,log2(DMA_MFB_REGION_SIZE*DMA_MFB_BLOCK_SIZE))      -1 downto 0);
    signal tx_usr_mfb_src_rdy_dbg       : std_logic_vector(DMA_STREAMS-1 downto 0);
    signal tx_usr_mfb_dst_rdy_dbg       : std_logic_vector(DMA_STREAMS-1 downto 0);

    --==============================================================================================
    --  Debug Core --->  Loopback interface
    --==============================================================================================
    signal tx_usr_mfb_data_lbk      : slv_array_t(DMA_STREAMS-1 downto 0)(DMA_MFB_REGIONS*DMA_MFB_REGION_SIZE*DMA_MFB_BLOCK_SIZE*DMA_MFB_ITEM_WIDTH-1 downto 0);
    signal tx_usr_mfb_meta_lbk      : slv_array_t(DMA_STREAMS-1 downto 0)(log2(USR_TX_PKT_SIZE_MAX+1)+HDR_META_WIDTH+log2(TX_CHANNELS)             -1 downto 0);
    signal tx_usr_mfb_sof_lbk       : slv_array_t(DMA_STREAMS-1 downto 0)(DMA_MFB_REGIONS                                                          -1 downto 0);
    signal tx_usr_mfb_eof_lbk       : slv_array_t(DMA_STREAMS-1 downto 0)(DMA_MFB_REGIONS                                                          -1 downto 0);
    signal tx_usr_mfb_sof_pos_lbk   : slv_array_t(DMA_STREAMS-1 downto 0)(DMA_MFB_REGIONS*max(1,log2(DMA_MFB_REGION_SIZE))                         -1 downto 0);
    signal tx_usr_mfb_eof_pos_lbk   : slv_array_t(DMA_STREAMS-1 downto 0)(DMA_MFB_REGIONS*max(1,log2(DMA_MFB_REGION_SIZE*DMA_MFB_BLOCK_SIZE))      -1 downto 0);
    signal tx_usr_mfb_src_rdy_lbk   : std_logic_vector(DMA_STREAMS-1 downto 0);
    signal tx_usr_mfb_dst_rdy_lbk   : std_logic_vector(DMA_STREAMS-1 downto 0);

    -- =============================================================================================
    -- Piped PCIE interfaces
    -- =============================================================================================
    signal pcie_rq_mfb_data_piped      : slv_array_t(DMA_STREAMS-1 downto 0)(PCIE_RQ_MFB_REGIONS*PCIE_RQ_MFB_REGION_SIZE*PCIE_RQ_MFB_BLOCK_SIZE*PCIE_RQ_MFB_ITEM_WIDTH -1 downto 0);
    signal pcie_rq_mfb_meta_piped      : slv_array_t(DMA_STREAMS-1 downto 0)(PCIE_RQ_MFB_REGIONS*PCIE_RQ_META_WIDTH                                                    -1 downto 0);
    signal pcie_rq_mfb_sof_piped       : slv_array_t(DMA_STREAMS-1 downto 0)(PCIE_RQ_MFB_REGIONS                                                                       -1 downto 0);
    signal pcie_rq_mfb_eof_piped       : slv_array_t(DMA_STREAMS-1 downto 0)(PCIE_RQ_MFB_REGIONS                                                                       -1 downto 0);
    signal pcie_rq_mfb_sof_pos_piped   : slv_array_t(DMA_STREAMS-1 downto 0)(PCIE_RQ_MFB_REGIONS*max(1,log2(PCIE_RQ_MFB_REGION_SIZE))                                  -1 downto 0);
    signal pcie_rq_mfb_eof_pos_piped   : slv_array_t(DMA_STREAMS-1 downto 0)(PCIE_RQ_MFB_REGIONS*max(1,log2(PCIE_RQ_MFB_REGION_SIZE*PCIE_RQ_MFB_BLOCK_SIZE))           -1 downto 0);
    signal pcie_rq_mfb_src_rdy_piped   : std_logic_vector(DMA_STREAMS-1 downto 0);
    signal pcie_rq_mfb_dst_rdy_piped   : std_logic_vector(DMA_STREAMS-1 downto 0);

    signal pcie_cq_mfb_data_piped      : slv_array_t(DMA_STREAMS-1 downto 0)(PCIE_CQ_MFB_REGIONS*PCIE_CQ_MFB_REGION_SIZE*PCIE_CQ_MFB_BLOCK_SIZE*PCIE_CQ_MFB_ITEM_WIDTH -1 downto 0);
    signal pcie_cq_mfb_meta_piped      : slv_array_t(DMA_STREAMS-1 downto 0)(PCIE_CQ_MFB_REGIONS*PCIE_CQ_META_WIDTH                                                    -1 downto 0);
    signal pcie_cq_mfb_sof_piped       : slv_array_t(DMA_STREAMS-1 downto 0)(PCIE_CQ_MFB_REGIONS                                                                       -1 downto 0);
    signal pcie_cq_mfb_eof_piped       : slv_array_t(DMA_STREAMS-1 downto 0)(PCIE_CQ_MFB_REGIONS                                                                       -1 downto 0);
    signal pcie_cq_mfb_sof_pos_piped   : slv_array_t(DMA_STREAMS-1 downto 0)(PCIE_CQ_MFB_REGIONS*max(1,log2(PCIE_CQ_MFB_REGION_SIZE))                                  -1 downto 0);
    signal pcie_cq_mfb_eof_pos_piped   : slv_array_t(DMA_STREAMS-1 downto 0)(PCIE_CQ_MFB_REGIONS*max(1,log2(PCIE_CQ_MFB_REGION_SIZE*PCIE_CQ_MFB_BLOCK_SIZE))           -1 downto 0);
    signal pcie_cq_mfb_src_rdy_piped   : std_logic_vector(DMA_STREAMS-1 downto 0);
    signal pcie_cq_mfb_dst_rdy_piped   : std_logic_vector(DMA_STREAMS-1 downto 0);

    signal pcie_cc_mfb_data_piped      : slv_array_t(DMA_STREAMS-1 downto 0)(PCIE_CC_MFB_REGIONS*PCIE_CC_MFB_REGION_SIZE*PCIE_CC_MFB_BLOCK_SIZE*PCIE_CC_MFB_ITEM_WIDTH -1 downto 0);
    signal pcie_cc_mfb_meta_piped      : slv_array_t(DMA_STREAMS-1 downto 0)(PCIE_CC_MFB_REGIONS*PCIE_CC_META_WIDTH                                                    -1 downto 0);
    signal pcie_cc_mfb_sof_piped       : slv_array_t(DMA_STREAMS-1 downto 0)(PCIE_CC_MFB_REGIONS                                                                       -1 downto 0);
    signal pcie_cc_mfb_eof_piped       : slv_array_t(DMA_STREAMS-1 downto 0)(PCIE_CC_MFB_REGIONS                                                                       -1 downto 0);
    signal pcie_cc_mfb_sof_pos_piped   : slv_array_t(DMA_STREAMS-1 downto 0)(PCIE_CC_MFB_REGIONS*max(1,log2(PCIE_CC_MFB_REGION_SIZE))                                  -1 downto 0);
    signal pcie_cc_mfb_eof_pos_piped   : slv_array_t(DMA_STREAMS-1 downto 0)(PCIE_CC_MFB_REGIONS*max(1,log2(PCIE_CC_MFB_REGION_SIZE*PCIE_CC_MFB_BLOCK_SIZE))           -1 downto 0);
    signal pcie_cc_mfb_src_rdy_piped   : std_logic_vector(DMA_STREAMS-1 downto 0);
    signal pcie_cc_mfb_dst_rdy_piped   : std_logic_vector(DMA_STREAMS-1 downto 0);

    --==============================================================================================
    -- Miscelaneous signals
    --==============================================================================================
    -- concatenated metadata on the output of the metadata extractor to be split into output
    -- TX_USR_MVB_* signals
    signal tx_usr_mvb_data_all  : slv_array_t(DMA_STREAMS-1 downto 0)(log2(USR_TX_PKT_SIZE_MAX +1)+log2(TX_CHANNELS)+HDR_META_WIDTH -1 downto 0);

    -- =============================================================================================
    -- Debugging signals
    -- =============================================================================================
    signal st_sp_dbg_chan : slv_array_t(DMA_STREAMS -1 downto 0)(log2(TX_CHANNELS) -1 downto 0);
    signal st_sp_dbg_meta : slv_array_t(DMA_STREAMS -1 downto 0)(ST_SP_DBG_META_WIDTH -1 downto 0);

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

                ADDR_MASK   => MI_SPLIT_ADDR_MASK,
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

                TX_MFB_DATA     => rx_usr_mfb_data_res(i),
                TX_MFB_META     => open,
                TX_MFB_META_NEW => rx_usr_mfb_meta_res(i),
                TX_MFB_SOF      => rx_usr_mfb_sof_res(i),
                TX_MFB_EOF      => rx_usr_mfb_eof_res(i),
                TX_MFB_SOF_POS  => rx_usr_mfb_sof_pos_res(i),
                TX_MFB_EOF_POS  => rx_usr_mfb_eof_pos_res(i),
                TX_MFB_SRC_RDY  => rx_usr_mfb_src_rdy_res(i),
                TX_MFB_DST_RDY  => rx_usr_mfb_dst_rdy_res(i));

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

                RX_MFB_DATA    => tx_usr_mfb_data_res(i),
                RX_MFB_META    => tx_usr_mfb_meta_res(i),
                RX_MFB_SOF     => tx_usr_mfb_sof_res(i),
                RX_MFB_EOF     => tx_usr_mfb_eof_res(i),
                RX_MFB_SOF_POS => tx_usr_mfb_sof_pos_res(i),
                RX_MFB_EOF_POS => tx_usr_mfb_eof_pos_res(i),
                RX_MFB_SRC_RDY => tx_usr_mfb_src_rdy_res(i),
                RX_MFB_DST_RDY => tx_usr_mfb_dst_rdy_res(i),

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
        -- Reconfig
        --==========================================================================================

        urs_rx_mfb_reconf_i : entity work.MFB_RECONFIGURATOR
        generic map(
            RX_REGIONS           => USR_MFB_REGIONS,
            RX_REGION_SIZE       => USR_MFB_REGION_SIZE,
            RX_BLOCK_SIZE        => USR_MFB_BLOCK_SIZE,
            RX_ITEM_WIDTH        => USR_MFB_ITEM_WIDTH,
            TX_REGIONS           => DMA_MFB_REGIONS,
            TX_REGION_SIZE       => DMA_MFB_REGION_SIZE,
            TX_BLOCK_SIZE        => DMA_MFB_BLOCK_SIZE,
            TX_ITEM_WIDTH        => DMA_MFB_ITEM_WIDTH,
            META_WIDTH           => log2(USR_RX_PKT_SIZE_MAX + 1) + HDR_META_WIDTH + log2(RX_CHANNELS),
            META_MODE            => 0,
            FIFO_SIZE            => 32,
            FRAMES_OVER_TX_BLOCK => 0,
            DEVICE               => DEVICE
        )
        port map(
            CLK        => USR_CLK,
            RESET      => USR_RESET,
    
            RX_DATA    => rx_usr_mfb_data_res(i),
            RX_META    => rx_usr_mfb_meta_res(i),
            RX_SOF     => rx_usr_mfb_sof_res(i),
            RX_EOF     => rx_usr_mfb_eof_res(i),
            RX_SOF_POS => rx_usr_mfb_sof_pos_res(i),
            RX_EOF_POS => rx_usr_mfb_eof_pos_res(i),
            RX_SRC_RDY => rx_usr_mfb_src_rdy_res(i),
            RX_DST_RDY => rx_usr_mfb_dst_rdy_res(i),
    
            TX_DATA    => rx_usr_mfb_data_async(i),
            TX_META    => rx_usr_mfb_meta_async(i),
            TX_SOF     => rx_usr_mfb_sof_async(i),
            TX_EOF     => rx_usr_mfb_eof_async(i),
            TX_SOF_POS => rx_usr_mfb_sof_pos_async(i),
            TX_EOF_POS => rx_usr_mfb_eof_pos_async(i),
            TX_SRC_RDY => rx_usr_mfb_src_rdy_async(i),
            TX_DST_RDY => rx_usr_mfb_dst_rdy_async(i)
        );
    
        urs_tx_mfb_reconf_i : entity work.MFB_RECONFIGURATOR
        generic map(
            RX_REGIONS           => DMA_MFB_REGIONS,
            RX_REGION_SIZE       => DMA_MFB_REGION_SIZE,
            RX_BLOCK_SIZE        => DMA_MFB_BLOCK_SIZE,
            RX_ITEM_WIDTH        => DMA_MFB_ITEM_WIDTH,
            TX_REGIONS           => USR_MFB_REGIONS,
            TX_REGION_SIZE       => USR_MFB_REGION_SIZE,
            TX_BLOCK_SIZE        => USR_MFB_BLOCK_SIZE,
            TX_ITEM_WIDTH        => USR_MFB_ITEM_WIDTH,
            META_WIDTH           => log2(USR_TX_PKT_SIZE_MAX + 1) + HDR_META_WIDTH + log2(TX_CHANNELS),
            META_MODE            => 0,
            FIFO_SIZE            => 32,
            FRAMES_OVER_TX_BLOCK => 0,
            DEVICE               => DEVICE
        )
        port map(
            CLK        => USR_CLK,
            RESET      => USR_RESET,
    
            RX_DATA    => tx_usr_mfb_data_async(i),
            RX_META    => tx_usr_mfb_meta_async(i),
            RX_SOF     => tx_usr_mfb_sof_async(i),
            RX_EOF     => tx_usr_mfb_eof_async(i),
            RX_SOF_POS => tx_usr_mfb_sof_pos_async(i),
            RX_EOF_POS => tx_usr_mfb_eof_pos_async(i),
            RX_SRC_RDY => tx_usr_mfb_src_rdy_async(i),
            RX_DST_RDY => tx_usr_mfb_dst_rdy_async(i),
    
            TX_DATA    => tx_usr_mfb_data_res(i),
            TX_META    => tx_usr_mfb_meta_res(i),
            TX_SOF     => tx_usr_mfb_sof_res(i),
            TX_EOF     => tx_usr_mfb_eof_res(i),
            TX_SOF_POS => tx_usr_mfb_sof_pos_res(i),
            TX_EOF_POS => tx_usr_mfb_eof_pos_res(i),
            TX_SRC_RDY => tx_usr_mfb_src_rdy_res(i),
            TX_DST_RDY => tx_usr_mfb_dst_rdy_res(i)
        );

        --==========================================================================================
        -- Asynchronous FIFOX components
        --==========================================================================================
        usr_rx_mfb_asfifox_i : entity work.MFB_ASFIFOX
            generic map (
                MFB_REGIONS         => DMA_MFB_REGIONS,
                MFB_REG_SIZE        => DMA_MFB_REGION_SIZE,
                MFB_BLOCK_SIZE      => DMA_MFB_BLOCK_SIZE,
                MFB_ITEM_WIDTH      => DMA_MFB_ITEM_WIDTH,
                FIFO_ITEMS          => 512,
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

        usr_tx_mfb_asfifox_i : entity work.MFB_ASFIFOX
            generic map (
                MFB_REGIONS         => DMA_MFB_REGIONS,
                MFB_REG_SIZE        => DMA_MFB_REGION_SIZE,
                MFB_BLOCK_SIZE      => DMA_MFB_BLOCK_SIZE,
                MFB_ITEM_WIDTH      => DMA_MFB_ITEM_WIDTH,
                FIFO_ITEMS          => 512,
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
                RX_META    => tx_usr_mfb_meta_sync(i),
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
    end generate;

    --==============================================================================================
    --  DMA Calypte Module
    --==============================================================================================
    dma_calypte_g : for i in 0 to DMA_STREAMS-1 generate
    begin

        dma_calypte_i : entity work.DMA_CALYPTE
            generic map(
                DEVICE => DEVICE,

                USR_MFB_REGIONS     => DMA_MFB_REGIONS,
                USR_MFB_REGION_SIZE => DMA_MFB_REGION_SIZE,
                USR_MFB_BLOCK_SIZE  => DMA_MFB_BLOCK_SIZE,
                USR_MFB_ITEM_WIDTH  => DMA_MFB_ITEM_WIDTH,

                PCIE_RQ_MFB_REGIONS     => PCIE_RQ_MFB_REGIONS,
                PCIE_RQ_MFB_REGION_SIZE => PCIE_RQ_MFB_REGION_SIZE,
                PCIE_RQ_MFB_BLOCK_SIZE  => PCIE_RQ_MFB_BLOCK_SIZE,
                PCIE_RQ_MFB_ITEM_WIDTH  => PCIE_RQ_MFB_ITEM_WIDTH,

                PCIE_CQ_MFB_REGIONS     => PCIE_CQ_MFB_REGIONS,
                PCIE_CQ_MFB_REGION_SIZE => PCIE_CQ_MFB_REGION_SIZE,
                PCIE_CQ_MFB_BLOCK_SIZE  => PCIE_CQ_MFB_BLOCK_SIZE,
                PCIE_CQ_MFB_ITEM_WIDTH  => PCIE_CQ_MFB_ITEM_WIDTH,

                PCIE_CC_MFB_REGIONS     => PCIE_CC_MFB_REGIONS,
                PCIE_CC_MFB_REGION_SIZE => PCIE_CC_MFB_REGION_SIZE,
                PCIE_CC_MFB_BLOCK_SIZE  => PCIE_CC_MFB_BLOCK_SIZE,
                PCIE_CC_MFB_ITEM_WIDTH  => PCIE_CC_MFB_ITEM_WIDTH,

                HDR_META_WIDTH => HDR_META_WIDTH,

                RX_CHANNELS         => RX_CHANNELS,
                RX_PTR_WIDTH        => RX_DP_WIDTH,
                USR_RX_PKT_SIZE_MAX => USR_RX_PKT_SIZE_MAX,

                TX_CHANNELS         => TX_CHANNELS,
                TX_PTR_WIDTH        => TX_DP_WIDTH,
                USR_TX_PKT_SIZE_MAX => USR_TX_PKT_SIZE_MAX,

                DSP_CNT_WIDTH => DSP_CNT_WIDTH,

                RX_GEN_EN     => RX_GEN_EN,
                TX_GEN_EN     => TX_GEN_EN,

                ST_SP_DBG_SIGNAL_W => ST_SP_DBG_META_WIDTH,
                MI_WIDTH      => MI_WIDTH
                )
            port map(
                CLK   => PCIE_USR_CLK(i),
                RESET => PCIE_USR_RESET(i) or force_reset_dbg(i),

                USR_RX_MFB_META_PKT_SIZE => rx_usr_mfb_meta_len(i),
                USR_RX_MFB_META_HDR_META => rx_usr_mfb_meta_hdr_meta(i),
                USR_RX_MFB_META_CHAN     => rx_usr_mfb_meta_channel(i),

                USR_RX_MFB_DATA    => rx_usr_mfb_data_lbk(i),
                USR_RX_MFB_SOF     => rx_usr_mfb_sof_lbk(i),
                USR_RX_MFB_EOF     => rx_usr_mfb_eof_lbk(i),
                USR_RX_MFB_SOF_POS => rx_usr_mfb_sof_pos_lbk(i),
                USR_RX_MFB_EOF_POS => rx_usr_mfb_eof_pos_lbk(i),
                USR_RX_MFB_SRC_RDY => rx_usr_mfb_src_rdy_lbk(i),
                USR_RX_MFB_DST_RDY => rx_usr_mfb_dst_rdy_lbk(i),

                USR_TX_MFB_META_PKT_SIZE => tx_usr_mfb_meta_len_dbg(i),
                USR_TX_MFB_META_HDR_META => tx_usr_mfb_meta_hdr_meta_dbg(i),
                USR_TX_MFB_META_CHAN     => tx_usr_mfb_meta_channel_dbg(i),

                USR_TX_MFB_DATA    => tx_usr_mfb_data_dbg(i),
                USR_TX_MFB_SOF     => tx_usr_mfb_sof_dbg(i),
                USR_TX_MFB_EOF     => tx_usr_mfb_eof_dbg(i),
                USR_TX_MFB_SOF_POS => tx_usr_mfb_sof_pos_dbg(i),
                USR_TX_MFB_EOF_POS => tx_usr_mfb_eof_pos_dbg(i),
                USR_TX_MFB_SRC_RDY => tx_usr_mfb_src_rdy_dbg(i),
                USR_TX_MFB_DST_RDY => tx_usr_mfb_dst_rdy_dbg(i),

                ST_SP_DBG_CHAN => st_sp_dbg_chan(i),
                ST_SP_DBG_META => st_sp_dbg_meta(i),

                PCIE_RQ_MFB_DATA    => pcie_rq_mfb_data_piped(i),
                PCIE_RQ_MFB_META    => pcie_rq_mfb_meta_piped(i),
                PCIE_RQ_MFB_SOF     => pcie_rq_mfb_sof_piped(i),
                PCIE_RQ_MFB_EOF     => pcie_rq_mfb_eof_piped(i),
                PCIE_RQ_MFB_SOF_POS => pcie_rq_mfb_sof_pos_piped(i),
                PCIE_RQ_MFB_EOF_POS => pcie_rq_mfb_eof_pos_piped(i),
                PCIE_RQ_MFB_SRC_RDY => pcie_rq_mfb_src_rdy_piped(i),
                PCIE_RQ_MFB_DST_RDY => pcie_rq_mfb_dst_rdy_piped(i),

                PCIE_CQ_MFB_DATA    => pcie_cq_mfb_data_piped(i),
                PCIE_CQ_MFB_META    => pcie_cq_mfb_meta_piped(i),
                PCIE_CQ_MFB_SOF     => pcie_cq_mfb_sof_piped(i),
                PCIE_CQ_MFB_EOF     => pcie_cq_mfb_eof_piped(i),
                PCIE_CQ_MFB_SOF_POS => pcie_cq_mfb_sof_pos_piped(i),
                PCIE_CQ_MFB_EOF_POS => pcie_cq_mfb_eof_pos_piped(i),
                PCIE_CQ_MFB_SRC_RDY => pcie_cq_mfb_src_rdy_piped(i),
                PCIE_CQ_MFB_DST_RDY => pcie_cq_mfb_dst_rdy_piped(i),

                PCIE_CC_MFB_DATA    => pcie_cc_mfb_data_piped(i),
                PCIE_CC_MFB_META    => pcie_cc_mfb_meta_piped(i),
                PCIE_CC_MFB_SOF     => pcie_cc_mfb_sof_piped(i),
                PCIE_CC_MFB_EOF     => pcie_cc_mfb_eof_piped(i),
                PCIE_CC_MFB_SOF_POS => pcie_cc_mfb_sof_pos_piped(i),
                PCIE_CC_MFB_EOF_POS => pcie_cc_mfb_eof_pos_piped(i),
                PCIE_CC_MFB_SRC_RDY => pcie_cc_mfb_src_rdy_piped(i),
                PCIE_CC_MFB_DST_RDY => pcie_cc_mfb_dst_rdy_piped(i),

                MI_ADDR => mi_sync_addr(i),
                MI_DWR  => mi_sync_dwr(i),
                MI_BE   => mi_sync_be(i),
                MI_RD   => mi_sync_rd(i),
                MI_WR   => mi_sync_wr(i),
                MI_DRD  => mi_sync_drd(i),
                MI_ARDY => mi_sync_ardy(i),
                MI_DRDY => mi_sync_drdy(i));

        rx_usr_mfb_meta_len(i)      <= rx_usr_mfb_meta_lbk(i)(log2(USR_RX_PKT_SIZE_MAX + 1) + log2(RX_CHANNELS) + HDR_META_WIDTH -1 downto log2(RX_CHANNELS) + HDR_META_WIDTH);
        rx_usr_mfb_meta_hdr_meta(i) <= rx_usr_mfb_meta_lbk(i)(HDR_META_WIDTH + log2(RX_CHANNELS) -1 downto log2(RX_CHANNELS));
        rx_usr_mfb_meta_channel(i)  <= rx_usr_mfb_meta_lbk(i)(log2(RX_CHANNELS) -1 downto 0);

        debug_core_g: if (TX_DMA_DBG_CORE_EN) generate
            tx_dma_debug_core_i: entity work.TX_DMA_DEBUG_CORE
                generic map (
                    DEVICE          => DEVICE,

                    MFB_REGIONS     => DMA_MFB_REGIONS,
                    MFB_REGION_SIZE => DMA_MFB_REGION_SIZE,
                    MFB_BLOCK_SIZE  => DMA_MFB_BLOCK_SIZE,
                    MFB_ITEM_WIDTH  => DMA_MFB_ITEM_WIDTH,

                    DMA_META_WIDTH  => HDR_META_WIDTH,
                    PKT_SIZE_MAX    => USR_TX_PKT_SIZE_MAX,
                    CHANNELS        => TX_CHANNELS,

                    DBG_CNTRS_WIDTH => 64,
                    ST_SP_DBG_SIGNAL_W => ST_SP_DBG_META_WIDTH,

                    MI_WIDTH        => MI_WIDTH)
                port map (
                    CLK                  => PCIE_USR_CLK(i),
                    RESET                => PCIE_USR_RESET(i),

                    FORCE_RESET          => force_reset_dbg(i),
                    ST_SP_DBG_CHAN       => st_sp_dbg_chan(i),
                    ST_SP_DBG_META       => st_sp_dbg_meta(i),

                    RX_MFB_META_PKT_SIZE => tx_usr_mfb_meta_len_dbg(i),
                    RX_MFB_META_CHAN     => tx_usr_mfb_meta_channel_dbg(i),
                    RX_MFB_META_HDR_META => tx_usr_mfb_meta_hdr_meta_dbg(i),

                    RX_MFB_DATA          => tx_usr_mfb_data_dbg(i),
                    RX_MFB_SOF_POS       => tx_usr_mfb_sof_pos_dbg(i),
                    RX_MFB_EOF_POS       => tx_usr_mfb_eof_pos_dbg(i),
                    RX_MFB_SOF           => tx_usr_mfb_sof_dbg(i),
                    RX_MFB_EOF           => tx_usr_mfb_eof_dbg(i),
                    RX_MFB_SRC_RDY       => tx_usr_mfb_src_rdy_dbg(i),
                    RX_MFB_DST_RDY       => tx_usr_mfb_dst_rdy_dbg(i),

                    TX_MFB_DATA          => tx_usr_mfb_data_lbk(i),
                    TX_MFB_META          => tx_usr_mfb_meta_lbk(i),
                    TX_MFB_SOF_POS       => tx_usr_mfb_sof_pos_lbk(i),
                    TX_MFB_EOF_POS       => tx_usr_mfb_eof_pos_lbk(i),
                    TX_MFB_SOF           => tx_usr_mfb_sof_lbk(i),
                    TX_MFB_EOF           => tx_usr_mfb_eof_lbk(i),
                    TX_MFB_SRC_RDY       => tx_usr_mfb_src_rdy_lbk(i),
                    TX_MFB_DST_RDY       => tx_usr_mfb_dst_rdy_lbk(i),

                    MI_CLK               => MI_CLK,
                    MI_RESET             => MI_RESET,

                    MI_ADDR              => mi_dmagen_addr(i)(3),
                    MI_DWR               => mi_dmagen_dwr(i)(3),
                    MI_BE                => mi_dmagen_be(i)(3),
                    MI_RD                => mi_dmagen_rd(i)(3),
                    MI_WR                => mi_dmagen_wr(i)(3),
                    MI_DRD               => mi_dmagen_drd(i)(3),
                    MI_ARDY              => mi_dmagen_ardy(i)(3),
                    MI_DRDY              => mi_dmagen_drdy(i)(3));
        else generate
            tx_usr_mfb_meta_lbk(i)(log2(TX_CHANNELS) -1 downto 0)                                  <= tx_usr_mfb_meta_channel_dbg(i);
            tx_usr_mfb_meta_lbk(i)(HDR_META_WIDTH + log2(TX_CHANNELS) -1 downto log2(TX_CHANNELS)) <= tx_usr_mfb_meta_hdr_meta_dbg(i);
            tx_usr_mfb_meta_lbk(i)(log2(USR_TX_PKT_SIZE_MAX+1) + HDR_META_WIDTH + log2(TX_CHANNELS) -1 downto HDR_META_WIDTH + log2(TX_CHANNELS)) <= tx_usr_mfb_meta_len_dbg(i);

            tx_usr_mfb_data_lbk(i)    <= tx_usr_mfb_data_dbg(i);
            tx_usr_mfb_sof_pos_lbk(i) <= tx_usr_mfb_sof_pos_dbg(i);
            tx_usr_mfb_eof_pos_lbk(i) <= tx_usr_mfb_eof_pos_dbg(i);
            tx_usr_mfb_sof_lbk(i)     <= tx_usr_mfb_sof_dbg(i);
            tx_usr_mfb_eof_lbk(i)     <= tx_usr_mfb_eof_dbg(i);
            tx_usr_mfb_src_rdy_lbk(i) <= tx_usr_mfb_src_rdy_dbg(i);
            tx_usr_mfb_dst_rdy_dbg(i) <= tx_usr_mfb_dst_rdy_lbk(i);

            force_reset_dbg(i) <= '0';

            mi_dmagen_ardy(i)(3) <= mi_dmagen_rd(i)(3) or mi_dmagen_wr(i)(3);
            mi_dmagen_drd(i)(3)  <= (others => '0');
            mi_dmagen_drdy(i)(3) <= mi_dmagen_rd(i)(3);
        end generate;

        mfb_loopback_i : entity work.MFB_LOOPBACK
            generic map (
                REGIONS       => DMA_MFB_REGIONS,
                REGION_SIZE   => DMA_MFB_REGION_SIZE,
                BLOCK_SIZE    => DMA_MFB_BLOCK_SIZE,
                ITEM_WIDTH    => DMA_MFB_ITEM_WIDTH,
                META_WIDTH    => log2(maximum(TX_CHANNELS,RX_CHANNELS)) + log2(maximum(USR_RX_PKT_SIZE_MAX,USR_TX_PKT_SIZE_MAX)+1) + HDR_META_WIDTH,

                FAKE_LOOPBACK => not DMA_LOOPBACK_EN,
                SAME_CLK      => FALSE)
            port map (
                MI_CLK             => MI_CLK,
                MI_RESET           => MI_RESET,

                MI_DWR             => mi_dmagen_dwr(i)(2),
                MI_ADDR            => mi_dmagen_addr(i)(2),
                MI_RD              => mi_dmagen_rd(i)(2),
                MI_WR              => mi_dmagen_wr(i)(2),
                MI_ARDY            => mi_dmagen_ardy(i)(2),
                MI_DRD             => mi_dmagen_drd(i)(2),
                MI_DRDY            => mi_dmagen_drdy(i)(2),

                CLK                => PCIE_USR_CLK(i),
                RESET              => PCIE_USR_RESET(i),

                RX_MFB_DATA_IN     => rx_usr_mfb_data_sync(i),
                RX_MFB_META_IN     => rx_usr_mfb_meta_sync(i),
                RX_MFB_SOF_IN      => rx_usr_mfb_sof_sync(i),
                RX_MFB_EOF_IN      => rx_usr_mfb_eof_sync(i),
                RX_MFB_SOF_POS_IN  => rx_usr_mfb_sof_pos_sync(i),
                RX_MFB_EOF_POS_IN  => rx_usr_mfb_eof_pos_sync(i),
                RX_MFB_SRC_RDY_IN  => rx_usr_mfb_src_rdy_sync(i),
                RX_MFB_DST_RDY_IN  => rx_usr_mfb_dst_rdy_sync(i),

                RX_MFB_DATA_OUT    => rx_usr_mfb_data_lbk(i),
                RX_MFB_META_OUT    => rx_usr_mfb_meta_lbk(i),
                RX_MFB_SOF_OUT     => rx_usr_mfb_sof_lbk(i),
                RX_MFB_EOF_OUT     => rx_usr_mfb_eof_lbk(i),
                RX_MFB_SOF_POS_OUT => rx_usr_mfb_sof_pos_lbk(i),
                RX_MFB_EOF_POS_OUT => rx_usr_mfb_eof_pos_lbk(i),
                RX_MFB_SRC_RDY_OUT => rx_usr_mfb_src_rdy_lbk(i),
                RX_MFB_DST_RDY_OUT => rx_usr_mfb_dst_rdy_lbk(i),

                TX_MFB_DATA_OUT    => tx_usr_mfb_data_sync(i),
                TX_MFB_META_OUT    => tx_usr_mfb_meta_sync(i),
                TX_MFB_SOF_OUT     => tx_usr_mfb_sof_sync(i),
                TX_MFB_EOF_OUT     => tx_usr_mfb_eof_sync(i),
                TX_MFB_SOF_POS_OUT => tx_usr_mfb_sof_pos_sync(i),
                TX_MFB_EOF_POS_OUT => tx_usr_mfb_eof_pos_sync(i),
                TX_MFB_SRC_RDY_OUT => tx_usr_mfb_src_rdy_sync(i),
                TX_MFB_DST_RDY_OUT => tx_usr_mfb_dst_rdy_sync(i),

                TX_MFB_DATA_IN     => tx_usr_mfb_data_lbk(i),
                TX_MFB_META_IN     => tx_usr_mfb_meta_lbk(i),
                TX_MFB_SOF_IN      => tx_usr_mfb_sof_lbk(i),
                TX_MFB_EOF_IN      => tx_usr_mfb_eof_lbk(i),
                TX_MFB_SOF_POS_IN  => tx_usr_mfb_sof_pos_lbk(i),
                TX_MFB_EOF_POS_IN  => tx_usr_mfb_eof_pos_lbk(i),
                TX_MFB_SRC_RDY_IN  => tx_usr_mfb_src_rdy_lbk(i),
                TX_MFB_DST_RDY_IN  => tx_usr_mfb_dst_rdy_lbk(i));

    end generate;

    -- =============================================================================================
    -- Generating output pipes to PCIe interface
    -- =============================================================================================
    pipes_g: for i in 0 to (PCIE_ENDPOINTS -1) generate
        pcie_rq_mfb_pipe_i : entity work.MFB_PIPE
            generic map (
                REGIONS     => PCIE_RQ_MFB_REGIONS,
                REGION_SIZE => PCIE_RQ_MFB_REGION_SIZE,
                BLOCK_SIZE  => PCIE_RQ_MFB_BLOCK_SIZE,
                ITEM_WIDTH  => PCIE_RQ_MFB_ITEM_WIDTH,

                META_WIDTH  => PCIE_RQ_META_WIDTH,
                FAKE_PIPE   => not OUT_PIPE_EN,
                USE_DST_RDY => TRUE,
                PIPE_TYPE   => "REG",
                DEVICE      => DEVICE)
            port map (
                CLK        => PCIE_USR_CLK(i),
                RESET      => PCIE_USR_RESET(i),

                RX_DATA    => pcie_rq_mfb_data_piped(i),
                RX_META    => pcie_rq_mfb_meta_piped(i),
                RX_SOF_POS => pcie_rq_mfb_sof_pos_piped(i),
                RX_EOF_POS => pcie_rq_mfb_eof_pos_piped(i),
                RX_SOF     => pcie_rq_mfb_sof_piped(i),
                RX_EOF     => pcie_rq_mfb_eof_piped(i),
                RX_SRC_RDY => pcie_rq_mfb_src_rdy_piped(i),
                RX_DST_RDY => pcie_rq_mfb_dst_rdy_piped(i),

                TX_DATA    => PCIE_RQ_MFB_DATA(i),
                TX_META    => PCIE_RQ_MFB_META(i),
                TX_SOF_POS => PCIE_RQ_MFB_SOF_POS(i),
                TX_EOF_POS => PCIE_RQ_MFB_EOF_POS(i),
                TX_SOF     => PCIE_RQ_MFB_SOF(i),
                TX_EOF     => PCIE_RQ_MFB_EOF(i),
                TX_SRC_RDY => PCIE_RQ_MFB_SRC_RDY(i),
                TX_DST_RDY => PCIE_RQ_MFB_DST_RDY(i));

        pcie_cc_mfb_pipe_i : entity work.MFB_PIPE
            generic map (
                REGIONS     => PCIE_CC_MFB_REGIONS,
                REGION_SIZE => PCIE_CC_MFB_REGION_SIZE,
                BLOCK_SIZE  => PCIE_CC_MFB_BLOCK_SIZE,
                ITEM_WIDTH  => PCIE_CC_MFB_ITEM_WIDTH,

                META_WIDTH  => PCIE_CC_META_WIDTH,
                FAKE_PIPE   => not OUT_PIPE_EN,
                USE_DST_RDY => TRUE,
                PIPE_TYPE   => "REG",
                DEVICE      => DEVICE)
            port map (
                CLK        => PCIE_USR_CLK(i),
                RESET      => PCIE_USR_RESET(i),

                RX_DATA    => pcie_cc_mfb_data_piped(i),
                RX_META    => pcie_cc_mfb_meta_piped(i),
                RX_SOF_POS => pcie_cc_mfb_sof_pos_piped(i),
                RX_EOF_POS => pcie_cc_mfb_eof_pos_piped(i),
                RX_SOF     => pcie_cc_mfb_sof_piped(i),
                RX_EOF     => pcie_cc_mfb_eof_piped(i),
                RX_SRC_RDY => pcie_cc_mfb_src_rdy_piped(i),
                RX_DST_RDY => pcie_cc_mfb_dst_rdy_piped(i),

                TX_DATA    => PCIE_CC_MFB_DATA(i),
                TX_META    => PCIE_CC_MFB_META(i),
                TX_SOF_POS => PCIE_CC_MFB_SOF_POS(i),
                TX_EOF_POS => PCIE_CC_MFB_EOF_POS(i),
                TX_SOF     => PCIE_CC_MFB_SOF(i),
                TX_EOF     => PCIE_CC_MFB_EOF(i),
                TX_SRC_RDY => PCIE_CC_MFB_SRC_RDY(i),
                TX_DST_RDY => PCIE_CC_MFB_DST_RDY(i));

        pcie_cq_mfb_pipe_i : entity work.MFB_PIPE
            generic map (
                REGIONS     => PCIE_CQ_MFB_REGIONS,
                REGION_SIZE => PCIE_CQ_MFB_REGION_SIZE,
                BLOCK_SIZE  => PCIE_CQ_MFB_BLOCK_SIZE,
                ITEM_WIDTH  => PCIE_CQ_MFB_ITEM_WIDTH,

                META_WIDTH  => PCIE_CQ_META_WIDTH,
                FAKE_PIPE   => not OUT_PIPE_EN,
                USE_DST_RDY => TRUE,
                PIPE_TYPE   => "REG",
                DEVICE      => DEVICE)
            port map (
                CLK        => PCIE_USR_CLK(i),
                RESET      => PCIE_USR_RESET(i),

                RX_DATA    => PCIE_CQ_MFB_DATA(i),
                RX_META    => PCIE_CQ_MFB_META(i),
                RX_SOF_POS => PCIE_CQ_MFB_SOF_POS(i),
                RX_EOF_POS => PCIE_CQ_MFB_EOF_POS(i),
                RX_SOF     => PCIE_CQ_MFB_SOF(i),
                RX_EOF     => PCIE_CQ_MFB_EOF(i),
                RX_SRC_RDY => PCIE_CQ_MFB_SRC_RDY(i),
                RX_DST_RDY => PCIE_CQ_MFB_DST_RDY(i),

                TX_DATA    => pcie_cq_mfb_data_piped(i),
                TX_META    => pcie_cq_mfb_meta_piped(i),
                TX_SOF_POS => pcie_cq_mfb_sof_pos_piped(i),
                TX_EOF_POS => pcie_cq_mfb_eof_pos_piped(i),
                TX_SOF     => pcie_cq_mfb_sof_piped(i),
                TX_EOF     => pcie_cq_mfb_eof_piped(i),
                TX_SRC_RDY => pcie_cq_mfb_src_rdy_piped(i),
                TX_DST_RDY => pcie_cq_mfb_dst_rdy_piped(i));
    end generate;
end architecture;
