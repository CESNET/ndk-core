// property.sv: check property
// Copyright (C) 2023 CESNET z. s. p. o.
// Author(s): Radek Iša <isa@cesnet.cz>

// SPDX-License-Identifier: BSD-3-Clause


module PROPERTY #(
    string       ETH_CORE_ARCH    ,
    int unsigned ETH_PORTS        ,
    int unsigned ETH_PORT_SPEED[ETH_PORTS-1:0],

    int unsigned ETH_PORT_CHAN[ETH_PORTS-1:0]    ,
    int unsigned EHIP_PORT_TYPE[ETH_PORTS-1:0]   ,
    int unsigned ETH_PORT_RX_MTU[ETH_PORTS-1:0]  ,
    int unsigned ETH_PORT_TX_MTU[ETH_PORTS-1:0]  ,
    int unsigned LANES            ,
    int unsigned QSFP_PORTS       ,
    int unsigned QSFP_I2C_PORTS   ,
    int unsigned QSFP_I2C_TRISTATE,

    int unsigned ETH_TX_HDR_WIDTH,
    int unsigned ETH_RX_HDR_WIDTH,

    int unsigned REGIONS          ,
    int unsigned REGION_SIZE      ,
    int unsigned BLOCK_SIZE       ,
    int unsigned ITEM_WIDTH       ,

    int unsigned MI_DATA_WIDTH    ,
    int unsigned MI_ADDR_WIDTH    ,

    int unsigned MI_DATA_WIDTH_PHY,
    int unsigned MI_ADDR_WIDTH_PHY,

    int unsigned LANE_RX_POLARITY ,
    int unsigned LANE_TX_POLARITY ,
    int unsigned RESET_WIDTH      ,
    string DEVICE           ,
    string BOARD
)(
    input wire logic CLK_USR   ,
    input wire logic CLK_ETH[ETH_PORTS],
    input wire logic CLK_MI    ,
    input wire logic CLK_MI_PHY,
    input wire logic CLK_MI_PMD,
    input wire logic CLK_TSU   ,

    reset_if rst_usr   ,
    reset_if rst_eth[ETH_PORTS],
    reset_if rst_mi    ,
    reset_if rst_mi_phy,
    reset_if rst_mi_pmd,
    reset_if rst_tsu   ,

    avst_if eth_rx[ETH_PORTS],
    avst_if eth_tx[ETH_PORTS],

    mfb_if usr_rx     [ETH_PORTS],
    mfb_if usr_tx_data[ETH_PORTS],
    mvb_if usr_tx_hdr [ETH_PORTS],

    mi_if  mi,
    mi_if  mi_phy,
    mi_if  mi_pmd,

    mvb_if   tsu
);

endmodule
