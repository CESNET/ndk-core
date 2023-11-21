// pkg.sv: parameter pkgs 
// Copyright (C) 2023 CESNET z. s. p. o.
// Author(s): Jakub Cabal <cabal@cesnet.cz>

// SPDX-License-Identifier: BSD-3-Clause


`ifndef UVM_NETWORK_MOD_TBENCH_PARAM_SV
`define UVM_NETWORK_MOD_TBENCH_PARAM_SV

package tbench_param;
        parameter string ETH_CORE_ARCH           = "E_TILE";
        parameter int unsigned ETH_PORTS         = 2;
        parameter int unsigned ETH_PORT_SPEED[ETH_PORTS-1:0]  = '{ETH_PORTS{100}};
        parameter int unsigned ETH_PORT_CHAN[ETH_PORTS-1:0]   = '{ETH_PORTS{1}};
        //parameter int unsigned ETH_PORT_SPEED[ETH_PORTS-1:0]  = '{ETH_PORTS{25}};
        //parameter int unsigned ETH_PORT_CHAN[ETH_PORTS-1:0]   = '{ETH_PORTS{4}};
        parameter int unsigned EHIP_PORT_TYPE[ETH_PORTS-1:0]  = '{ETH_PORTS{0}};
        parameter int unsigned ETH_PORT_RX_MTU[ETH_PORTS-1:0] = '{ETH_PORTS{16383}};
        parameter int unsigned ETH_PORT_TX_MTU[ETH_PORTS-1:0] = '{ETH_PORTS{16383}};
        parameter int unsigned LANES             = 4;
        parameter int unsigned QSFP_PORTS        = 2;
        parameter int unsigned QSFP_I2C_PORTS    = 1;
        parameter int unsigned QSFP_I2C_TRISTATE = 1'b1;
        parameter int unsigned REGIONS           = 1;
        parameter int unsigned REGION_SIZE       = 8;
        parameter int unsigned BLOCK_SIZE        = 8;
        parameter int unsigned ITEM_WIDTH        = 8;
        parameter int unsigned MI_DATA_WIDTH     = 32;
        parameter int unsigned MI_ADDR_WIDTH     = 32;

        /*/ TYTO KONSTANTY JSOU K NICEMU UPOZORNIT KUBU */
        parameter MI_DATA_WIDTH_PHY = 32;
        parameter MI_ADDR_WIDTH_PHY = 32;


        parameter LANE_RX_POLARITY  = 0; //'{ETH_PORTS*LANES{1'b0}};
        parameter LANE_TX_POLARITY  = 0; //'{ETH_PORTS*LANES{1'b0}};
        parameter RESET_WIDTH       = 8;
        parameter DEVICE            = "AGILEX"; // "STRATIX10";
        parameter BOARD             = "N6010";  // "DK-DEV-1SDX-P";

        parameter ETH_TX_HDR_WIDTH = 16+8+1;
        parameter ETH_RX_HDR_WIDTH = 64+1+4+1+1+1+1+1+1+1+1+1+8+16;

        parameter time CLK_USR_PERIOD    = 4ns;
        parameter time CLK_ETH_PERIOD[ETH_PORTS] = '{ETH_PORTS{4ns}};
        parameter time CLK_MI_PERIOD     = 4ns;
        parameter time CLK_MI_PHY_PERIOD = 4ns;
        parameter time CLK_MI_PMD_PERIOD = 4ns;
        parameter time CLK_TSU_PERIOD    = 4ns;
endpackage
`endif

