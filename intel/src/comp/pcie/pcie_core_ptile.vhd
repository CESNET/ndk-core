-- pcie_core_ptile.vhd: PCIe module
-- Copyright (C) 2019 CESNET z. s. p. o.
-- Author(s): Jakub Cabal <cabal@cesnet.cz>
--
-- SPDX-License-Identifier: BSD-3-Clause

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.math_pack.all;
use work.type_pack.all;

architecture PTILE of PCIE_CORE is

    component ptile_pcie_1x16 is
        port (
            p0_rx_st_ready_i             : in  std_logic                      := 'X';             -- ready
            p0_rx_st_sop_o               : out std_logic_vector(1 downto 0);                      -- startofpacket
            p0_rx_st_eop_o               : out std_logic_vector(1 downto 0);                      -- endofpacket
            p0_rx_st_data_o              : out std_logic_vector(511 downto 0);                    -- data
            p0_rx_st_valid_o             : out std_logic_vector(1 downto 0);                      -- valid
            p0_rx_st_empty_o             : out std_logic_vector(5 downto 0);                      -- empty
            p0_rx_st_hdr_o               : out std_logic_vector(255 downto 0);                    -- rx_st_hdr
            p0_rx_st_tlp_prfx_o          : out std_logic_vector(63 downto 0);                     -- rx_st_tlp_prfx
            p0_rx_st_bar_range_o         : out std_logic_vector(5 downto 0);                      -- rx_st_bar_range
            p0_rx_st_tlp_abort_o         : out std_logic_vector(1 downto 0);                      -- rx_st_tlp_abort
            p0_rx_par_err_o              : out std_logic;                                         -- rx_par_err
            p0_tx_st_sop_i               : in  std_logic_vector(1 downto 0)   := (others => 'X'); -- startofpacket
            p0_tx_st_eop_i               : in  std_logic_vector(1 downto 0)   := (others => 'X'); -- endofpacket
            p0_tx_st_data_i              : in  std_logic_vector(511 downto 0) := (others => 'X'); -- data
            p0_tx_st_valid_i             : in  std_logic_vector(1 downto 0)   := (others => 'X'); -- valid
            p0_tx_st_err_i               : in  std_logic_vector(1 downto 0)   := (others => 'X'); -- error
            p0_tx_st_ready_o             : out std_logic;                                         -- ready
            p0_tx_st_hdr_i               : in  std_logic_vector(255 downto 0) := (others => 'X'); -- tx_st_hdr
            p0_tx_st_tlp_prfx_i          : in  std_logic_vector(63 downto 0)  := (others => 'X'); -- tx_st_tlp_prfx
            p0_tx_par_err_o              : out std_logic;                                         -- tx_par_err
            p0_tx_cdts_limit_o           : out std_logic_vector(15 downto 0);                     -- tx_cdts_type
            p0_tx_cdts_limit_tdm_idx_o   : out std_logic_vector(2 downto 0);                      -- tx_data_cdts_consumed
            p0_tl_cfg_func_o             : out std_logic_vector(2 downto 0);                      -- tl_cfg_func
            p0_tl_cfg_add_o              : out std_logic_vector(4 downto 0);                      -- tl_cfg_add
            p0_tl_cfg_ctl_o              : out std_logic_vector(15 downto 0);                     -- tl_cfg_ctl
            p0_dl_timer_update_o         : out std_logic;                                         -- dl_timer_update
            p0_reset_status_n            : out std_logic;                                         -- reset_n
            p0_pin_perst_n               : out std_logic;                                         -- pin_perst
            p0_link_up_o                 : out std_logic;                                         -- link_up
            p0_dl_up_o                   : out std_logic;                                         -- dl_up
            p0_surprise_down_err_o       : out std_logic;                                         -- surprise_down_err
            p0_pm_state_o                : out std_logic_vector(2 downto 0);                      -- pm_state
            p0_ltssm_state_o             : out std_logic_vector(5 downto 0);                      -- ltssmstate
            p0_pm_dstate_o               : out std_logic_vector(31 downto 0);                     -- pm_dstate
            p0_apps_pm_xmt_pme_i         : in  std_logic_vector(7 downto 0)   := (others => 'X'); -- apps_pm_xmt_pme
            p0_app_req_retry_en_i        : in  std_logic_vector(7 downto 0)   := (others => 'X'); -- app_req_retry_en
            p0_cii_hdr_poisoned_o        : out std_logic;                                         -- hdr_poisoned
            p0_cii_override_en_i         : in  std_logic                      := 'X';             -- override_en
            p0_cii_hdr_first_be_o        : out std_logic_vector(3 downto 0);                      -- hdr_first_be
            p0_cii_dout_o                : out std_logic_vector(31 downto 0);                     -- dout
            p0_cii_halt_i                : in  std_logic                      := 'X';             -- halt
            p0_cii_req_o                 : out std_logic;                                         -- req
            p0_cii_addr_o                : out std_logic_vector(9 downto 0);                      -- addr
            p0_cii_wr_o                  : out std_logic;                                         -- write
            p0_cii_override_din_i        : in  std_logic_vector(31 downto 0)  := (others => 'X'); -- override_din
            rx_n_in0                     : in  std_logic                      := 'X';             -- rx_n_in0
            rx_n_in1                     : in  std_logic                      := 'X';             -- rx_n_in1
            rx_n_in2                     : in  std_logic                      := 'X';             -- rx_n_in2
            rx_n_in3                     : in  std_logic                      := 'X';             -- rx_n_in3
            rx_n_in4                     : in  std_logic                      := 'X';             -- rx_n_in4
            rx_n_in5                     : in  std_logic                      := 'X';             -- rx_n_in5
            rx_n_in6                     : in  std_logic                      := 'X';             -- rx_n_in6
            rx_n_in7                     : in  std_logic                      := 'X';             -- rx_n_in7
            rx_n_in8                     : in  std_logic                      := 'X';             -- rx_n_in8
            rx_n_in9                     : in  std_logic                      := 'X';             -- rx_n_in9
            rx_n_in10                    : in  std_logic                      := 'X';             -- rx_n_in10
            rx_n_in11                    : in  std_logic                      := 'X';             -- rx_n_in11
            rx_n_in12                    : in  std_logic                      := 'X';             -- rx_n_in12
            rx_n_in13                    : in  std_logic                      := 'X';             -- rx_n_in13
            rx_n_in14                    : in  std_logic                      := 'X';             -- rx_n_in14
            rx_n_in15                    : in  std_logic                      := 'X';             -- rx_n_in15
            rx_p_in0                     : in  std_logic                      := 'X';             -- rx_p_in0
            rx_p_in1                     : in  std_logic                      := 'X';             -- rx_p_in1
            rx_p_in2                     : in  std_logic                      := 'X';             -- rx_p_in2
            rx_p_in3                     : in  std_logic                      := 'X';             -- rx_p_in3
            rx_p_in4                     : in  std_logic                      := 'X';             -- rx_p_in4
            rx_p_in5                     : in  std_logic                      := 'X';             -- rx_p_in5
            rx_p_in6                     : in  std_logic                      := 'X';             -- rx_p_in6
            rx_p_in7                     : in  std_logic                      := 'X';             -- rx_p_in7
            rx_p_in8                     : in  std_logic                      := 'X';             -- rx_p_in8
            rx_p_in9                     : in  std_logic                      := 'X';             -- rx_p_in9
            rx_p_in10                    : in  std_logic                      := 'X';             -- rx_p_in10
            rx_p_in11                    : in  std_logic                      := 'X';             -- rx_p_in11
            rx_p_in12                    : in  std_logic                      := 'X';             -- rx_p_in12
            rx_p_in13                    : in  std_logic                      := 'X';             -- rx_p_in13
            rx_p_in14                    : in  std_logic                      := 'X';             -- rx_p_in14
            rx_p_in15                    : in  std_logic                      := 'X';             -- rx_p_in15
            tx_n_out0                    : out std_logic;                                         -- tx_n_out0
            tx_n_out1                    : out std_logic;                                         -- tx_n_out1
            tx_n_out2                    : out std_logic;                                         -- tx_n_out2
            tx_n_out3                    : out std_logic;                                         -- tx_n_out3
            tx_n_out4                    : out std_logic;                                         -- tx_n_out4
            tx_n_out5                    : out std_logic;                                         -- tx_n_out5
            tx_n_out6                    : out std_logic;                                         -- tx_n_out6
            tx_n_out7                    : out std_logic;                                         -- tx_n_out7
            tx_n_out8                    : out std_logic;                                         -- tx_n_out8
            tx_n_out9                    : out std_logic;                                         -- tx_n_out9
            tx_n_out10                   : out std_logic;                                         -- tx_n_out10
            tx_n_out11                   : out std_logic;                                         -- tx_n_out11
            tx_n_out12                   : out std_logic;                                         -- tx_n_out12
            tx_n_out13                   : out std_logic;                                         -- tx_n_out13
            tx_n_out14                   : out std_logic;                                         -- tx_n_out14
            tx_n_out15                   : out std_logic;                                         -- tx_n_out15
            tx_p_out0                    : out std_logic;                                         -- tx_p_out0
            tx_p_out1                    : out std_logic;                                         -- tx_p_out1
            tx_p_out2                    : out std_logic;                                         -- tx_p_out2
            tx_p_out3                    : out std_logic;                                         -- tx_p_out3
            tx_p_out4                    : out std_logic;                                         -- tx_p_out4
            tx_p_out5                    : out std_logic;                                         -- tx_p_out5
            tx_p_out6                    : out std_logic;                                         -- tx_p_out6
            tx_p_out7                    : out std_logic;                                         -- tx_p_out7
            tx_p_out8                    : out std_logic;                                         -- tx_p_out8
            tx_p_out9                    : out std_logic;                                         -- tx_p_out9
            tx_p_out10                   : out std_logic;                                         -- tx_p_out10
            tx_p_out11                   : out std_logic;                                         -- tx_p_out11
            tx_p_out12                   : out std_logic;                                         -- tx_p_out12
            tx_p_out13                   : out std_logic;                                         -- tx_p_out13
            tx_p_out14                   : out std_logic;                                         -- tx_p_out14
            tx_p_out15                   : out std_logic;                                         -- tx_p_out15
            coreclkout_hip               : out std_logic;                                         -- clk
            refclk0                      : in  std_logic                      := 'X';             -- clk
            refclk1                      : in  std_logic                      := 'X';             -- clk
            pin_perst_n                  : in  std_logic                      := 'X';             -- pin_perst
            ninit_done                   : in  std_logic                      := 'X'              -- ninit_done
        );
    end component ptile_pcie_1x16;

    component ptile_pcie_2x8 is
        port (
            p0_rx_st_ready_i           : in  std_logic                      := 'X';             -- ready
            p0_rx_st_sop_o             : out std_logic_vector(0 downto 0);                      -- startofpacket
            p0_rx_st_eop_o             : out std_logic_vector(0 downto 0);                      -- endofpacket
            p0_rx_st_data_o            : out std_logic_vector(255 downto 0);                    -- data
            p0_rx_st_valid_o           : out std_logic_vector(0 downto 0);                      -- valid
            p0_rx_st_empty_o           : out std_logic_vector(2 downto 0);                      -- empty
            p0_rx_st_hdr_o             : out std_logic_vector(127 downto 0);                    -- rx_st_hdr
            p0_rx_st_tlp_prfx_o        : out std_logic_vector(31 downto 0);                     -- rx_st_tlp_prfx
            p0_rx_st_bar_range_o       : out std_logic_vector(2 downto 0);                      -- rx_st_bar_range
            p0_rx_st_tlp_abort_o       : out std_logic_vector(0 downto 0);                      -- rx_st_tlp_abort
            p0_rx_par_err_o            : out std_logic;                                         -- rx_par_err
            p0_tx_st_sop_i             : in  std_logic_vector(0 downto 0)   := (others => 'X'); -- startofpacket
            p0_tx_st_eop_i             : in  std_logic_vector(0 downto 0)   := (others => 'X'); -- endofpacket
            p0_tx_st_data_i            : in  std_logic_vector(255 downto 0) := (others => 'X'); -- data
            p0_tx_st_valid_i           : in  std_logic_vector(0 downto 0)   := (others => 'X'); -- valid
            p0_tx_st_err_i             : in  std_logic_vector(0 downto 0)   := (others => 'X'); -- error
            p0_tx_st_ready_o           : out std_logic;                                         -- ready
            p0_tx_st_hdr_i             : in  std_logic_vector(127 downto 0) := (others => 'X'); -- tx_st_hdr
            p0_tx_st_tlp_prfx_i        : in  std_logic_vector(31 downto 0)  := (others => 'X'); -- tx_st_tlp_prfx
            p0_tx_par_err_o            : out std_logic;                                         -- tx_par_err
            p0_tx_cdts_limit_o         : out std_logic_vector(15 downto 0);                     -- tx_cdts_type
            p0_tx_cdts_limit_tdm_idx_o : out std_logic_vector(2 downto 0);                      -- tx_data_cdts_consumed
            p0_tl_cfg_func_o           : out std_logic_vector(2 downto 0);                      -- tl_cfg_func
            p0_tl_cfg_add_o            : out std_logic_vector(4 downto 0);                      -- tl_cfg_add
            p0_tl_cfg_ctl_o            : out std_logic_vector(15 downto 0);                     -- tl_cfg_ctl
            p0_dl_timer_update_o       : out std_logic;                                         -- dl_timer_update
            p1_rx_st_ready_i           : in  std_logic                      := 'X';             -- ready
            p1_rx_st_sop_o             : out std_logic_vector(0 downto 0);                      -- startofpacket
            p1_rx_st_eop_o             : out std_logic_vector(0 downto 0);                      -- endofpacket
            p1_rx_st_data_o            : out std_logic_vector(255 downto 0);                    -- data
            p1_rx_st_valid_o           : out std_logic_vector(0 downto 0);                      -- valid
            p1_rx_st_empty_o           : out std_logic_vector(2 downto 0);                      -- empty
            p1_rx_st_hdr_o             : out std_logic_vector(127 downto 0);                    -- rx_st_hdr
            p1_rx_st_tlp_prfx_o        : out std_logic_vector(31 downto 0);                     -- rx_st_tlp_prfx
            p1_rx_st_bar_range_o       : out std_logic_vector(2 downto 0);                      -- rx_st_bar_range
            p1_rx_st_tlp_abort_o       : out std_logic_vector(0 downto 0);                      -- rx_st_tlp_abort
            p1_rx_par_err_o            : out std_logic;                                         -- rx_par_err
            p1_tx_st_sop_i             : in  std_logic_vector(0 downto 0)   := (others => 'X'); -- startofpacket
            p1_tx_st_eop_i             : in  std_logic_vector(0 downto 0)   := (others => 'X'); -- endofpacket
            p1_tx_st_data_i            : in  std_logic_vector(255 downto 0) := (others => 'X'); -- data
            p1_tx_st_valid_i           : in  std_logic_vector(0 downto 0)   := (others => 'X'); -- valid
            p1_tx_st_err_i             : in  std_logic_vector(0 downto 0)   := (others => 'X'); -- error
            p1_tx_st_ready_o           : out std_logic;                                         -- ready
            p1_tx_st_hdr_i             : in  std_logic_vector(127 downto 0) := (others => 'X'); -- tx_st_hdr
            p1_tx_st_tlp_prfx_i        : in  std_logic_vector(31 downto 0)  := (others => 'X'); -- tx_st_tlp_prfx
            p1_tx_par_err_o            : out std_logic;                                         -- tx_par_err
            p1_tx_cdts_limit_o         : out std_logic_vector(15 downto 0);                     -- tx_cdts_type
            p1_tx_cdts_limit_tdm_idx_o : out std_logic_vector(2 downto 0);                      -- tx_data_cdts_consumed
            p1_tl_cfg_func_o           : out std_logic_vector(2 downto 0);                      -- tl_cfg_func
            p1_tl_cfg_add_o            : out std_logic_vector(4 downto 0);                      -- tl_cfg_add
            p1_tl_cfg_ctl_o            : out std_logic_vector(15 downto 0);                     -- tl_cfg_ctl
            p1_dl_timer_update_o       : out std_logic;                                         -- dl_timer_update
            p1_reset_status_n          : out std_logic;                                         -- reset_n
            p1_pin_perst_n             : out std_logic;                                         -- pin_perst
            p1_link_up_o               : out std_logic;                                         -- link_up
            p1_dl_up_o                 : out std_logic;                                         -- dl_up
            p1_surprise_down_err_o     : out std_logic;                                         -- surprise_down_err
            p1_pm_state_o              : out std_logic_vector(2 downto 0);                      -- pm_state
            p1_ltssm_state_o           : out std_logic_vector(5 downto 0);                      -- ltssmstate
            p1_pm_dstate_o             : out std_logic_vector(31 downto 0);                     -- pm_dstate
            p1_apps_pm_xmt_pme_i       : in  std_logic_vector(7 downto 0)   := (others => 'X'); -- apps_pm_xmt_pme
            p1_app_req_retry_en_i      : in  std_logic_vector(7 downto 0)   := (others => 'X'); -- app_req_retry_en
            p1_cii_hdr_poisoned_o      : out std_logic;                                         -- hdr_poisoned
            p1_cii_override_en_i       : in  std_logic                      := 'X';             -- override_en
            p1_cii_hdr_first_be_o      : out std_logic_vector(3 downto 0);                      -- hdr_first_be
            p1_cii_dout_o              : out std_logic_vector(31 downto 0);                     -- dout
            p1_cii_halt_i              : in  std_logic                      := 'X';             -- halt
            p1_cii_req_o               : out std_logic;                                         -- req
            p1_cii_addr_o              : out std_logic_vector(9 downto 0);                      -- addr
            p1_cii_wr_o                : out std_logic;                                         -- write
            p1_cii_override_din_i      : in  std_logic_vector(31 downto 0)  := (others => 'X'); -- override_din
            p0_reset_status_n          : out std_logic;                                         -- reset_n
            p0_pin_perst_n             : out std_logic;                                         -- pin_perst
            p0_link_up_o               : out std_logic;                                         -- link_up
            p0_dl_up_o                 : out std_logic;                                         -- dl_up
            p0_surprise_down_err_o     : out std_logic;                                         -- surprise_down_err
            p0_pm_state_o              : out std_logic_vector(2 downto 0);                      -- pm_state
            p0_ltssm_state_o           : out std_logic_vector(5 downto 0);                      -- ltssmstate
            p0_pm_dstate_o             : out std_logic_vector(31 downto 0);                     -- pm_dstate
            p0_apps_pm_xmt_pme_i       : in  std_logic_vector(7 downto 0)   := (others => 'X'); -- apps_pm_xmt_pme
            p0_app_req_retry_en_i      : in  std_logic_vector(7 downto 0)   := (others => 'X'); -- app_req_retry_en
            p0_cii_hdr_poisoned_o      : out std_logic;                                         -- hdr_poisoned
            p0_cii_override_en_i       : in  std_logic                      := 'X';             -- override_en
            p0_cii_hdr_first_be_o      : out std_logic_vector(3 downto 0);                      -- hdr_first_be
            p0_cii_dout_o              : out std_logic_vector(31 downto 0);                     -- dout
            p0_cii_halt_i              : in  std_logic                      := 'X';             -- halt
            p0_cii_req_o               : out std_logic;                                         -- req
            p0_cii_addr_o              : out std_logic_vector(9 downto 0);                      -- addr
            p0_cii_wr_o                : out std_logic;                                         -- write
            p0_cii_override_din_i      : in  std_logic_vector(31 downto 0)  := (others => 'X'); -- override_din
            rx_n_in0                   : in  std_logic                      := 'X';             -- rx_n_in0
            rx_n_in1                   : in  std_logic                      := 'X';             -- rx_n_in1
            rx_n_in2                   : in  std_logic                      := 'X';             -- rx_n_in2
            rx_n_in3                   : in  std_logic                      := 'X';             -- rx_n_in3
            rx_n_in4                   : in  std_logic                      := 'X';             -- rx_n_in4
            rx_n_in5                   : in  std_logic                      := 'X';             -- rx_n_in5
            rx_n_in6                   : in  std_logic                      := 'X';             -- rx_n_in6
            rx_n_in7                   : in  std_logic                      := 'X';             -- rx_n_in7
            rx_n_in8                   : in  std_logic                      := 'X';             -- rx_n_in8
            rx_n_in9                   : in  std_logic                      := 'X';             -- rx_n_in9
            rx_n_in10                  : in  std_logic                      := 'X';             -- rx_n_in10
            rx_n_in11                  : in  std_logic                      := 'X';             -- rx_n_in11
            rx_n_in12                  : in  std_logic                      := 'X';             -- rx_n_in12
            rx_n_in13                  : in  std_logic                      := 'X';             -- rx_n_in13
            rx_n_in14                  : in  std_logic                      := 'X';             -- rx_n_in14
            rx_n_in15                  : in  std_logic                      := 'X';             -- rx_n_in15
            rx_p_in0                   : in  std_logic                      := 'X';             -- rx_p_in0
            rx_p_in1                   : in  std_logic                      := 'X';             -- rx_p_in1
            rx_p_in2                   : in  std_logic                      := 'X';             -- rx_p_in2
            rx_p_in3                   : in  std_logic                      := 'X';             -- rx_p_in3
            rx_p_in4                   : in  std_logic                      := 'X';             -- rx_p_in4
            rx_p_in5                   : in  std_logic                      := 'X';             -- rx_p_in5
            rx_p_in6                   : in  std_logic                      := 'X';             -- rx_p_in6
            rx_p_in7                   : in  std_logic                      := 'X';             -- rx_p_in7
            rx_p_in8                   : in  std_logic                      := 'X';             -- rx_p_in8
            rx_p_in9                   : in  std_logic                      := 'X';             -- rx_p_in9
            rx_p_in10                  : in  std_logic                      := 'X';             -- rx_p_in10
            rx_p_in11                  : in  std_logic                      := 'X';             -- rx_p_in11
            rx_p_in12                  : in  std_logic                      := 'X';             -- rx_p_in12
            rx_p_in13                  : in  std_logic                      := 'X';             -- rx_p_in13
            rx_p_in14                  : in  std_logic                      := 'X';             -- rx_p_in14
            rx_p_in15                  : in  std_logic                      := 'X';             -- rx_p_in15
            tx_n_out0                  : out std_logic;                                         -- tx_n_out0
            tx_n_out1                  : out std_logic;                                         -- tx_n_out1
            tx_n_out2                  : out std_logic;                                         -- tx_n_out2
            tx_n_out3                  : out std_logic;                                         -- tx_n_out3
            tx_n_out4                  : out std_logic;                                         -- tx_n_out4
            tx_n_out5                  : out std_logic;                                         -- tx_n_out5
            tx_n_out6                  : out std_logic;                                         -- tx_n_out6
            tx_n_out7                  : out std_logic;                                         -- tx_n_out7
            tx_n_out8                  : out std_logic;                                         -- tx_n_out8
            tx_n_out9                  : out std_logic;                                         -- tx_n_out9
            tx_n_out10                 : out std_logic;                                         -- tx_n_out10
            tx_n_out11                 : out std_logic;                                         -- tx_n_out11
            tx_n_out12                 : out std_logic;                                         -- tx_n_out12
            tx_n_out13                 : out std_logic;                                         -- tx_n_out13
            tx_n_out14                 : out std_logic;                                         -- tx_n_out14
            tx_n_out15                 : out std_logic;                                         -- tx_n_out15
            tx_p_out0                  : out std_logic;                                         -- tx_p_out0
            tx_p_out1                  : out std_logic;                                         -- tx_p_out1
            tx_p_out2                  : out std_logic;                                         -- tx_p_out2
            tx_p_out3                  : out std_logic;                                         -- tx_p_out3
            tx_p_out4                  : out std_logic;                                         -- tx_p_out4
            tx_p_out5                  : out std_logic;                                         -- tx_p_out5
            tx_p_out6                  : out std_logic;                                         -- tx_p_out6
            tx_p_out7                  : out std_logic;                                         -- tx_p_out7
            tx_p_out8                  : out std_logic;                                         -- tx_p_out8
            tx_p_out9                  : out std_logic;                                         -- tx_p_out9
            tx_p_out10                 : out std_logic;                                         -- tx_p_out10
            tx_p_out11                 : out std_logic;                                         -- tx_p_out11
            tx_p_out12                 : out std_logic;                                         -- tx_p_out12
            tx_p_out13                 : out std_logic;                                         -- tx_p_out13
            tx_p_out14                 : out std_logic;                                         -- tx_p_out14
            tx_p_out15                 : out std_logic;                                         -- tx_p_out15
            coreclkout_hip             : out std_logic;                                         -- clk
            refclk0                    : in  std_logic                      := 'X';             -- clk
            refclk1                    : in  std_logic                      := 'X';             -- clk
            pin_perst_n                : in  std_logic                      := 'X';             -- pin_perst
            ninit_done                 : in  std_logic                      := 'X'              -- ninit_done
        );
    end component ptile_pcie_2x8;
    
    constant VSEC_BASE_ADDRESS : integer := 16#D00#;
    constant PCIE_EPS_INST     : natural := tsel(ENDPOINT_MODE=0,PCIE_CONS,2*PCIE_CONS);

    signal pcie_reset_status_n      : std_logic_vector(PCIE_EPS_INST-1 downto 0);
    signal pcie_reset_status        : std_logic_vector(PCIE_EPS_INST-1 downto 0);
    signal pcie_clk                 : std_logic_vector(PCIE_EPS_INST-1 downto 0);
    signal pcie_hip_clk             : std_logic_vector(PCIE_CONS-1 downto 0);
    signal pcie_init_done_n         : std_logic_vector(PCIE_CONS-1 downto 0);
    signal pcie_rst                 : slv_array_t(PCIE_EPS_INST-1 downto 0)(RESET_WIDTH+1-1 downto 0);

    signal pcie_avst_down_data      : slv_array_t(PCIE_EPS_INST-1 downto 0)(PCIE_DOWN_REGIONS*256-1 downto 0);
    signal pcie_avst_down_hdr       : slv_array_t(PCIE_EPS_INST-1 downto 0)(PCIE_DOWN_REGIONS*128-1 downto 0);
    signal pcie_avst_down_prefix    : slv_array_t(PCIE_EPS_INST-1 downto 0)(PCIE_DOWN_REGIONS*32-1 downto 0);
    signal pcie_avst_down_sop       : slv_array_t(PCIE_EPS_INST-1 downto 0)(PCIE_DOWN_REGIONS-1 downto 0);
    signal pcie_avst_down_eop       : slv_array_t(PCIE_EPS_INST-1 downto 0)(PCIE_DOWN_REGIONS-1 downto 0);
    signal pcie_avst_down_empty     : slv_array_t(PCIE_EPS_INST-1 downto 0)(PCIE_DOWN_REGIONS*3-1 downto 0);
    signal pcie_avst_down_bar_range : slv_array_t(PCIE_EPS_INST-1 downto 0)(PCIE_DOWN_REGIONS*3-1 downto 0);
    signal pcie_avst_down_valid     : slv_array_t(PCIE_EPS_INST-1 downto 0)(PCIE_DOWN_REGIONS-1 downto 0);
    signal pcie_avst_down_ready     : std_logic_vector(PCIE_EPS_INST-1 downto 0) := (others => '1');
    signal pcie_avst_up_data        : slv_array_t(PCIE_EPS_INST-1 downto 0)(PCIE_UP_REGIONS*256-1 downto 0);
    signal pcie_avst_up_hdr         : slv_array_t(PCIE_EPS_INST-1 downto 0)(PCIE_UP_REGIONS*128-1 downto 0);
    signal pcie_avst_up_prefix      : slv_array_t(PCIE_EPS_INST-1 downto 0)(PCIE_UP_REGIONS*32-1 downto 0);
    signal pcie_avst_up_sop         : slv_array_t(PCIE_EPS_INST-1 downto 0)(PCIE_UP_REGIONS-1 downto 0);
    signal pcie_avst_up_eop         : slv_array_t(PCIE_EPS_INST-1 downto 0)(PCIE_UP_REGIONS-1 downto 0);
    signal pcie_avst_up_error       : slv_array_t(PCIE_EPS_INST-1 downto 0)(PCIE_UP_REGIONS-1 downto 0);
    signal pcie_avst_up_valid       : slv_array_t(PCIE_EPS_INST-1 downto 0)(PCIE_UP_REGIONS-1 downto 0) := (others => (others => '0'));
    signal pcie_avst_up_ready       : std_logic_vector(PCIE_EPS_INST-1 downto 0);

    signal pcie_link_up_comb        : std_logic_vector(PCIE_EPS_INST-1 downto 0);
    signal pcie_link_up_reg         : std_logic_vector(PCIE_ENDPOINTS-1 downto 0);

    signal pcie_cfg_func            : slv_array_t(PCIE_EPS_INST-1 downto 0)(3-1 downto 0);
    signal pcie_cfg_addr            : slv_array_t(PCIE_EPS_INST-1 downto 0)(5-1 downto 0);
    signal pcie_cfg_data            : slv_array_t(PCIE_EPS_INST-1 downto 0)(16-1 downto 0);
    signal pcie_cfg_data_reg        : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(16-1 downto 0);
    signal pcie_cfg_pf0_sel         : std_logic_vector(PCIE_ENDPOINTS-1 downto 0);
    signal pcie_cfg_reg0_sel        : std_logic_vector(PCIE_ENDPOINTS-1 downto 0);
    signal pcie_cfg_reg2_sel        : std_logic_vector(PCIE_ENDPOINTS-1 downto 0);
    signal pcie_cfg_reg21_sel       : std_logic_vector(PCIE_ENDPOINTS-1 downto 0);
    signal pcie_cfg_reg0_en         : std_logic_vector(PCIE_ENDPOINTS-1 downto 0);
    signal pcie_cfg_reg2_en         : std_logic_vector(PCIE_ENDPOINTS-1 downto 0);
    signal pcie_cfg_reg21_en        : std_logic_vector(PCIE_ENDPOINTS-1 downto 0);

    signal pcie_cii_hdr_poisoned    : std_logic_vector(PCIE_EPS_INST-1 downto 0);
    signal pcie_cii_override_en     : std_logic_vector(PCIE_EPS_INST-1 downto 0) := (others => '0');
    signal pcie_cii_hdr_first_be    : slv_array_t(PCIE_EPS_INST-1 downto 0)(3 downto 0);
    signal pcie_cii_dout            : slv_array_t(PCIE_EPS_INST-1 downto 0)(31 downto 0);
    signal pcie_cii_halt            : std_logic_vector(PCIE_EPS_INST-1 downto 0) := (others => '0');
    signal pcie_cii_req             : std_logic_vector(PCIE_EPS_INST-1 downto 0);
    signal pcie_cii_addr            : slv_array_t(PCIE_EPS_INST-1 downto 0)(9 downto 0);
    signal pcie_cii_wr              : std_logic_vector(PCIE_EPS_INST-1 downto 0);
    signal pcie_cii_override_din    : slv_array_t(PCIE_EPS_INST-1 downto 0)(31 downto 0) := (others => (others => '0'));

    signal cfg_ext_read             : std_logic_vector(PCIE_ENDPOINTS-1 downto 0);
    signal cfg_ext_write            : std_logic_vector(PCIE_ENDPOINTS-1 downto 0);
    signal cfg_ext_register         : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(9 downto 0);
    signal cfg_ext_function         : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(7 downto 0);
    signal cfg_ext_write_data       : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(31 downto 0);
    signal cfg_ext_write_be         : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(3 downto 0);
    signal cfg_ext_read_data        : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(31 downto 0);
    signal cfg_ext_read_dv          : std_logic_vector(PCIE_ENDPOINTS-1 downto 0);

begin

    -- =========================================================================
    --  PCIE IP CORE
    -- =========================================================================

    pcie_core_g : for i in 0 to PCIE_CONS-1 generate       
        pcie_core_1x16_g : if ENDPOINT_MODE = 0 generate
            pcie_core_i : component ptile_pcie_1x16
            port map (
                p0_rx_st_ready_i             => pcie_avst_down_ready(i),             --          p0_rx_st.ready
                p0_rx_st_sop_o               => pcie_avst_down_sop(i),               --                  .startofpacket
                p0_rx_st_eop_o               => pcie_avst_down_eop(i),               --                  .endofpacket
                p0_rx_st_data_o              => pcie_avst_down_data(i),              --                  .data
                p0_rx_st_valid_o             => pcie_avst_down_valid(i),             --                  .valid
                p0_rx_st_empty_o             => pcie_avst_down_empty(i),             --                  .empty
                p0_rx_st_hdr_o               => pcie_avst_down_hdr(i),               --     p0_rx_st_misc.rx_st_hdr
                p0_rx_st_tlp_prfx_o          => pcie_avst_down_prefix(i),            --                  .rx_st_tlp_prfx
                p0_rx_st_bar_range_o         => pcie_avst_down_bar_range(i),         --                  .rx_st_bar_range
                p0_rx_st_tlp_abort_o         => open,                           --                  .rx_st_tlp_abort
                p0_rx_par_err_o              => open,                           --                  .rx_par_err
                p0_tx_st_sop_i               => pcie_avst_up_sop(i),                 --          p0_tx_st.startofpacket
                p0_tx_st_eop_i               => pcie_avst_up_eop(i),                 --                  .endofpacket
                p0_tx_st_data_i              => pcie_avst_up_data(i),                --                  .data
                p0_tx_st_valid_i             => pcie_avst_up_valid(i),               --                  .valid
                p0_tx_st_err_i               => pcie_avst_up_error(i),               --                  .error
                p0_tx_st_ready_o             => pcie_avst_up_ready(i),               --                  .ready
                p0_tx_st_hdr_i               => pcie_avst_up_hdr(i),                 --     p0_tx_st_misc.tx_st_hdr
                p0_tx_st_tlp_prfx_i          => pcie_avst_up_prefix(i),              --                  .tx_st_tlp_prfx
                p0_tx_par_err_o              => open,                           --                  .tx_par_err
                p0_tx_cdts_limit_o           => open,                           --        p0_tx_cred.tx_cdts_type
                p0_tx_cdts_limit_tdm_idx_o   => open,                           --                  .tx_data_cdts_consumed
                p0_tl_cfg_func_o             => pcie_cfg_func(i),               --      p0_config_tl.tl_cfg_func
                p0_tl_cfg_add_o              => pcie_cfg_addr(i),               --                  .tl_cfg_add
                p0_tl_cfg_ctl_o              => pcie_cfg_data(i),               --                  .tl_cfg_ctl
                p0_dl_timer_update_o         => open,                           --                  .dl_timer_update
                p0_reset_status_n            => pcie_reset_status_n(i),         -- p0_reset_status_n.reset_n
                p0_pin_perst_n               => open,                           --      p0_pin_perst.pin_perst
                p0_link_up_o                 => pcie_link_up_comb(i),           --     p0_power_mgnt.link_up
                p0_dl_up_o                   => open,                           --                  .dl_up
                p0_surprise_down_err_o       => open,                           --                  .surprise_down_err
                p0_pm_state_o                => open,                           --                  .pm_state
                p0_ltssm_state_o             => open,                           --                  .ltssmstate
                p0_pm_dstate_o               => open,                           --                  .pm_dstate
                p0_apps_pm_xmt_pme_i         => (others => '0'),                --                  .apps_pm_xmt_pme
                p0_app_req_retry_en_i        => (others => '0'),                --                  .app_req_retry_en
                p0_cii_hdr_poisoned_o        => pcie_cii_hdr_poisoned(i),       --            p0_cii.hdr_poisoned
                p0_cii_override_en_i         => pcie_cii_override_en(i),        --                  .override_en
                p0_cii_hdr_first_be_o        => pcie_cii_hdr_first_be(i),       --                  .hdr_first_be
                p0_cii_dout_o                => pcie_cii_dout(i),               --                  .dout
                p0_cii_halt_i                => pcie_cii_halt(i),               --                  .halt
                p0_cii_req_o                 => pcie_cii_req(i),                --                  .req
                p0_cii_addr_o                => pcie_cii_addr(i),               --                  .addr
                p0_cii_wr_o                  => pcie_cii_wr(i),                 --                  .write
                p0_cii_override_din_i        => pcie_cii_override_din(i),       --                  .override_din
                rx_n_in0                     => PCIE_RX_N(i*PCIE_LANES+0),      --        hip_serial.rx_n_in0
                rx_n_in1                     => PCIE_RX_N(i*PCIE_LANES+1),      --                  .rx_n_in1
                rx_n_in2                     => PCIE_RX_N(i*PCIE_LANES+2),      --                  .rx_n_in2
                rx_n_in3                     => PCIE_RX_N(i*PCIE_LANES+3),      --                  .rx_n_in3
                rx_n_in4                     => PCIE_RX_N(i*PCIE_LANES+4),      --                  .rx_n_in4
                rx_n_in5                     => PCIE_RX_N(i*PCIE_LANES+5),      --                  .rx_n_in5
                rx_n_in6                     => PCIE_RX_N(i*PCIE_LANES+6),      --                  .rx_n_in6
                rx_n_in7                     => PCIE_RX_N(i*PCIE_LANES+7),      --                  .rx_n_in7
                rx_n_in8                     => PCIE_RX_N(i*PCIE_LANES+8),      --                  .rx_n_in8
                rx_n_in9                     => PCIE_RX_N(i*PCIE_LANES+9),      --                  .rx_n_in9
                rx_n_in10                    => PCIE_RX_N(i*PCIE_LANES+10),     --                  .rx_n_in10
                rx_n_in11                    => PCIE_RX_N(i*PCIE_LANES+11),     --                  .rx_n_in11
                rx_n_in12                    => PCIE_RX_N(i*PCIE_LANES+12),     --                  .rx_n_in12
                rx_n_in13                    => PCIE_RX_N(i*PCIE_LANES+13),     --                  .rx_n_in13
                rx_n_in14                    => PCIE_RX_N(i*PCIE_LANES+14),     --                  .rx_n_in14
                rx_n_in15                    => PCIE_RX_N(i*PCIE_LANES+15),     --                  .rx_n_in15
                rx_p_in0                     => PCIE_RX_P(i*PCIE_LANES+0),      --                  .rx_p_in0
                rx_p_in1                     => PCIE_RX_P(i*PCIE_LANES+1),      --                  .rx_p_in1
                rx_p_in2                     => PCIE_RX_P(i*PCIE_LANES+2),      --                  .rx_p_in2
                rx_p_in3                     => PCIE_RX_P(i*PCIE_LANES+3),      --                  .rx_p_in3
                rx_p_in4                     => PCIE_RX_P(i*PCIE_LANES+4),      --                  .rx_p_in4
                rx_p_in5                     => PCIE_RX_P(i*PCIE_LANES+5),      --                  .rx_p_in5
                rx_p_in6                     => PCIE_RX_P(i*PCIE_LANES+6),      --                  .rx_p_in6
                rx_p_in7                     => PCIE_RX_P(i*PCIE_LANES+7),      --                  .rx_p_in7
                rx_p_in8                     => PCIE_RX_P(i*PCIE_LANES+8),      --                  .rx_p_in8
                rx_p_in9                     => PCIE_RX_P(i*PCIE_LANES+9),      --                  .rx_p_in9
                rx_p_in10                    => PCIE_RX_P(i*PCIE_LANES+10),     --                  .rx_p_in10
                rx_p_in11                    => PCIE_RX_P(i*PCIE_LANES+11),     --                  .rx_p_in11
                rx_p_in12                    => PCIE_RX_P(i*PCIE_LANES+12),     --                  .rx_p_in12
                rx_p_in13                    => PCIE_RX_P(i*PCIE_LANES+13),     --                  .rx_p_in13
                rx_p_in14                    => PCIE_RX_P(i*PCIE_LANES+14),     --                  .rx_p_in14
                rx_p_in15                    => PCIE_RX_P(i*PCIE_LANES+15),     --                  .rx_p_in15
                tx_n_out0                    => PCIE_TX_N(i*PCIE_LANES+0),      --                  .tx_n_out0
                tx_n_out1                    => PCIE_TX_N(i*PCIE_LANES+1),      --                  .tx_n_out1
                tx_n_out2                    => PCIE_TX_N(i*PCIE_LANES+2),      --                  .tx_n_out2
                tx_n_out3                    => PCIE_TX_N(i*PCIE_LANES+3),      --                  .tx_n_out3
                tx_n_out4                    => PCIE_TX_N(i*PCIE_LANES+4),      --                  .tx_n_out4
                tx_n_out5                    => PCIE_TX_N(i*PCIE_LANES+5),      --                  .tx_n_out5
                tx_n_out6                    => PCIE_TX_N(i*PCIE_LANES+6),      --                  .tx_n_out6
                tx_n_out7                    => PCIE_TX_N(i*PCIE_LANES+7),      --                  .tx_n_out7
                tx_n_out8                    => PCIE_TX_N(i*PCIE_LANES+8),      --                  .tx_n_out8
                tx_n_out9                    => PCIE_TX_N(i*PCIE_LANES+9),      --                  .tx_n_out9
                tx_n_out10                   => PCIE_TX_N(i*PCIE_LANES+10),     --                  .tx_n_out10
                tx_n_out11                   => PCIE_TX_N(i*PCIE_LANES+11),     --                  .tx_n_out11
                tx_n_out12                   => PCIE_TX_N(i*PCIE_LANES+12),     --                  .tx_n_out12
                tx_n_out13                   => PCIE_TX_N(i*PCIE_LANES+13),     --                  .tx_n_out13
                tx_n_out14                   => PCIE_TX_N(i*PCIE_LANES+14),     --                  .tx_n_out14
                tx_n_out15                   => PCIE_TX_N(i*PCIE_LANES+15),     --                  .tx_n_out15
                tx_p_out0                    => PCIE_TX_P(i*PCIE_LANES+0),      --                  .tx_p_out0
                tx_p_out1                    => PCIE_TX_P(i*PCIE_LANES+1),      --                  .tx_p_out1
                tx_p_out2                    => PCIE_TX_P(i*PCIE_LANES+2),      --                  .tx_p_out2
                tx_p_out3                    => PCIE_TX_P(i*PCIE_LANES+3),      --                  .tx_p_out3
                tx_p_out4                    => PCIE_TX_P(i*PCIE_LANES+4),      --                  .tx_p_out4
                tx_p_out5                    => PCIE_TX_P(i*PCIE_LANES+5),      --                  .tx_p_out5
                tx_p_out6                    => PCIE_TX_P(i*PCIE_LANES+6),      --                  .tx_p_out6
                tx_p_out7                    => PCIE_TX_P(i*PCIE_LANES+7),      --                  .tx_p_out7
                tx_p_out8                    => PCIE_TX_P(i*PCIE_LANES+8),      --                  .tx_p_out8
                tx_p_out9                    => PCIE_TX_P(i*PCIE_LANES+9),      --                  .tx_p_out9
                tx_p_out10                   => PCIE_TX_P(i*PCIE_LANES+10),     --                  .tx_p_out10
                tx_p_out11                   => PCIE_TX_P(i*PCIE_LANES+11),     --                  .tx_p_out11
                tx_p_out12                   => PCIE_TX_P(i*PCIE_LANES+12),     --                  .tx_p_out12
                tx_p_out13                   => PCIE_TX_P(i*PCIE_LANES+13),     --                  .tx_p_out13
                tx_p_out14                   => PCIE_TX_P(i*PCIE_LANES+14),     --                  .tx_p_out14
                tx_p_out15                   => PCIE_TX_P(i*PCIE_LANES+15),     --                  .tx_p_out15
                coreclkout_hip               => pcie_hip_clk(i),                --    coreclkout_hip.clk
                refclk0                      => PCIE_SYSCLK_P(i*PCIE_CLKS),       --           refclk0.clk
                refclk1                      => PCIE_SYSCLK_P(i*PCIE_CLKS+1),     --           refclk1.clk
                pin_perst_n                  => PCIE_SYSRST_N(i),               --         pin_perst.pin_perst
                ninit_done                   => pcie_init_done_n(i)             --        ninit_done.ninit_done
            );
            pcie_clk(i) <= pcie_hip_clk(i);
            init_done_g : if (PCIE_ENDPOINTS > i) generate
                pcie_init_done_n(i) <= INIT_DONE_N;
            else generate
                pcie_init_done_n(i) <= '1';
            end generate;
        end generate;

        pcie_core_2x8_g : if ENDPOINT_MODE = 1 generate
            pcie_core_i : component ptile_pcie_2x8
            port map (
                p0_rx_st_ready_i             => pcie_avst_down_ready(i*2),             --          p0_rx_st.ready
                p0_rx_st_sop_o               => pcie_avst_down_sop(i*2),               --                  .startofpacket
                p0_rx_st_eop_o               => pcie_avst_down_eop(i*2),               --                  .endofpacket
                p0_rx_st_data_o              => pcie_avst_down_data(i*2),              --                  .data
                p0_rx_st_valid_o             => pcie_avst_down_valid(i*2),             --                  .valid
                p0_rx_st_empty_o             => pcie_avst_down_empty(i*2),             --                  .empty
                p0_rx_st_hdr_o               => pcie_avst_down_hdr(i*2),               --     p0_rx_st_misc.rx_st_hdr
                p0_rx_st_tlp_prfx_o          => pcie_avst_down_prefix(i*2),            --                  .rx_st_tlp_prfx
                p0_rx_st_bar_range_o         => pcie_avst_down_bar_range(i*2),         --                  .rx_st_bar_range
                p0_rx_st_tlp_abort_o         => open,                           --                  .rx_st_tlp_abort
                p0_rx_par_err_o              => open,                           --                  .rx_par_err
                p0_tx_st_sop_i               => pcie_avst_up_sop(i*2),                 --          p0_tx_st.startofpacket
                p0_tx_st_eop_i               => pcie_avst_up_eop(i*2),                 --                  .endofpacket
                p0_tx_st_data_i              => pcie_avst_up_data(i*2),                --                  .data
                p0_tx_st_valid_i             => pcie_avst_up_valid(i*2),               --                  .valid
                p0_tx_st_err_i               => pcie_avst_up_error(i*2),               --                  .error
                p0_tx_st_ready_o             => pcie_avst_up_ready(i*2),               --                  .ready
                p0_tx_st_hdr_i               => pcie_avst_up_hdr(i*2),                 --     p0_tx_st_misc.tx_st_hdr
                p0_tx_st_tlp_prfx_i          => pcie_avst_up_prefix(i*2),              --                  .tx_st_tlp_prfx
                p0_tx_par_err_o              => open,                           --                  .tx_par_err
                p0_tx_cdts_limit_o           => open,                           --        p0_tx_cred.tx_cdts_type
                p0_tx_cdts_limit_tdm_idx_o   => open,                           --                  .tx_data_cdts_consumed
                p0_tl_cfg_func_o             => pcie_cfg_func(i*2),               --      p0_config_tl.tl_cfg_func
                p0_tl_cfg_add_o              => pcie_cfg_addr(i*2),               --                  .tl_cfg_add
                p0_tl_cfg_ctl_o              => pcie_cfg_data(i*2),               --                  .tl_cfg_ctl
                p0_dl_timer_update_o         => open,                           --                  .dl_timer_update
                p0_reset_status_n            => pcie_reset_status_n(i*2),         -- p0_reset_status_n.reset_n
                p0_pin_perst_n               => open,                           --      p0_pin_perst.pin_perst
                p0_link_up_o                 => pcie_link_up_comb(i*2),           --     p0_power_mgnt.link_up
                p0_dl_up_o                   => open,                           --                  .dl_up
                p0_surprise_down_err_o       => open,                           --                  .surprise_down_err
                p0_pm_state_o                => open,                           --                  .pm_state
                p0_ltssm_state_o             => open,                           --                  .ltssmstate
                p0_pm_dstate_o               => open,                           --                  .pm_dstate
                p0_apps_pm_xmt_pme_i         => (others => '0'),                --                  .apps_pm_xmt_pme
                p0_app_req_retry_en_i        => (others => '0'),                --                  .app_req_retry_en
                p0_cii_hdr_poisoned_o        => pcie_cii_hdr_poisoned(i*2),       --            p0_cii.hdr_poisoned
                p0_cii_override_en_i         => pcie_cii_override_en(i*2),        --                  .override_en
                p0_cii_hdr_first_be_o        => pcie_cii_hdr_first_be(i*2),       --                  .hdr_first_be
                p0_cii_dout_o                => pcie_cii_dout(i*2),               --                  .dout
                p0_cii_halt_i                => pcie_cii_halt(i*2),               --                  .halt
                p0_cii_req_o                 => pcie_cii_req(i*2),                --                  .req
                p0_cii_addr_o                => pcie_cii_addr(i*2),               --                  .addr
                p0_cii_wr_o                  => pcie_cii_wr(i*2),                 --                  .write
                p0_cii_override_din_i        => pcie_cii_override_din(i*2),       --                  .override_din
                
                p1_rx_st_ready_i             => pcie_avst_down_ready(i*2+1),             --          p0_rx_st.ready
                p1_rx_st_sop_o               => pcie_avst_down_sop(i*2+1),               --                  .startofpacket
                p1_rx_st_eop_o               => pcie_avst_down_eop(i*2+1),               --                  .endofpacket
                p1_rx_st_data_o              => pcie_avst_down_data(i*2+1),              --                  .data
                p1_rx_st_valid_o             => pcie_avst_down_valid(i*2+1),             --                  .valid
                p1_rx_st_empty_o             => pcie_avst_down_empty(i*2+1),             --                  .empty
                p1_rx_st_hdr_o               => pcie_avst_down_hdr(i*2+1),               --     p0_rx_st_misc.rx_st_hdr
                p1_rx_st_tlp_prfx_o          => pcie_avst_down_prefix(i*2+1),            --                  .rx_st_tlp_prfx
                p1_rx_st_bar_range_o         => pcie_avst_down_bar_range(i*2+1),         --                  .rx_st_bar_range
                p1_rx_st_tlp_abort_o         => open,                           --                  .rx_st_tlp_abort
                p1_rx_par_err_o              => open,                           --                  .rx_par_err
                p1_tx_st_sop_i               => pcie_avst_up_sop(i*2+1),                 --          p0_tx_st.startofpacket
                p1_tx_st_eop_i               => pcie_avst_up_eop(i*2+1),                 --                  .endofpacket
                p1_tx_st_data_i              => pcie_avst_up_data(i*2+1),                --                  .data
                p1_tx_st_valid_i             => pcie_avst_up_valid(i*2+1),               --                  .valid
                p1_tx_st_err_i               => pcie_avst_up_error(i*2+1),               --                  .error
                p1_tx_st_ready_o             => pcie_avst_up_ready(i*2+1),               --                  .ready
                p1_tx_st_hdr_i               => pcie_avst_up_hdr(i*2+1),                 --     p0_tx_st_misc.tx_st_hdr
                p1_tx_st_tlp_prfx_i          => pcie_avst_up_prefix(i*2+1),              --                  .tx_st_tlp_prfx
                p1_tx_par_err_o              => open,                           --                  .tx_par_err
                p1_tx_cdts_limit_o           => open,                           --        p0_tx_cred.tx_cdts_type
                p1_tx_cdts_limit_tdm_idx_o   => open,                           --                  .tx_data_cdts_consumed
                p1_tl_cfg_func_o             => pcie_cfg_func(i*2+1),               --      p0_config_tl.tl_cfg_func
                p1_tl_cfg_add_o              => pcie_cfg_addr(i*2+1),               --                  .tl_cfg_add
                p1_tl_cfg_ctl_o              => pcie_cfg_data(i*2+1),               --                  .tl_cfg_ctl
                p1_dl_timer_update_o         => open,                           --                  .dl_timer_update
                p1_reset_status_n            => pcie_reset_status_n(i*2+1),         -- p0_reset_status_n.reset_n
                p1_pin_perst_n               => open,                           --      p0_pin_perst.pin_perst
                p1_link_up_o                 => pcie_link_up_comb(i*2+1),           --     p0_power_mgnt.link_up
                p1_dl_up_o                   => open,                           --                  .dl_up
                p1_surprise_down_err_o       => open,                           --                  .surprise_down_err
                p1_pm_state_o                => open,                           --                  .pm_state
                p1_ltssm_state_o             => open,                           --                  .ltssmstate
                p1_pm_dstate_o               => open,                           --                  .pm_dstate
                p1_apps_pm_xmt_pme_i         => (others => '0'),                --                  .apps_pm_xmt_pme
                p1_app_req_retry_en_i        => (others => '0'),                --                  .app_req_retry_en
                p1_cii_hdr_poisoned_o        => pcie_cii_hdr_poisoned(i*2+1),       --            p0_cii.hdr_poisoned
                p1_cii_override_en_i         => pcie_cii_override_en(i*2+1),        --                  .override_en
                p1_cii_hdr_first_be_o        => pcie_cii_hdr_first_be(i*2+1),       --                  .hdr_first_be
                p1_cii_dout_o                => pcie_cii_dout(i*2+1),               --                  .dout
                p1_cii_halt_i                => pcie_cii_halt(i*2+1),               --                  .halt
                p1_cii_req_o                 => pcie_cii_req(i*2+1),                --                  .req
                p1_cii_addr_o                => pcie_cii_addr(i*2+1),               --                  .addr
                p1_cii_wr_o                  => pcie_cii_wr(i*2+1),                 --                  .write
                p1_cii_override_din_i        => pcie_cii_override_din(i*2+1),       --                  .override_din

                rx_n_in0                     => PCIE_RX_N(i*PCIE_LANES+0),      --        hip_serial.rx_n_in0
                rx_n_in1                     => PCIE_RX_N(i*PCIE_LANES+1),      --                  .rx_n_in1
                rx_n_in2                     => PCIE_RX_N(i*PCIE_LANES+2),      --                  .rx_n_in2
                rx_n_in3                     => PCIE_RX_N(i*PCIE_LANES+3),      --                  .rx_n_in3
                rx_n_in4                     => PCIE_RX_N(i*PCIE_LANES+4),      --                  .rx_n_in4
                rx_n_in5                     => PCIE_RX_N(i*PCIE_LANES+5),      --                  .rx_n_in5
                rx_n_in6                     => PCIE_RX_N(i*PCIE_LANES+6),      --                  .rx_n_in6
                rx_n_in7                     => PCIE_RX_N(i*PCIE_LANES+7),      --                  .rx_n_in7
                rx_n_in8                     => PCIE_RX_N(i*PCIE_LANES+8),      --                  .rx_n_in8
                rx_n_in9                     => PCIE_RX_N(i*PCIE_LANES+9),      --                  .rx_n_in9
                rx_n_in10                    => PCIE_RX_N(i*PCIE_LANES+10),     --                  .rx_n_in10
                rx_n_in11                    => PCIE_RX_N(i*PCIE_LANES+11),     --                  .rx_n_in11
                rx_n_in12                    => PCIE_RX_N(i*PCIE_LANES+12),     --                  .rx_n_in12
                rx_n_in13                    => PCIE_RX_N(i*PCIE_LANES+13),     --                  .rx_n_in13
                rx_n_in14                    => PCIE_RX_N(i*PCIE_LANES+14),     --                  .rx_n_in14
                rx_n_in15                    => PCIE_RX_N(i*PCIE_LANES+15),     --                  .rx_n_in15
                rx_p_in0                     => PCIE_RX_P(i*PCIE_LANES+0),      --                  .rx_p_in0
                rx_p_in1                     => PCIE_RX_P(i*PCIE_LANES+1),      --                  .rx_p_in1
                rx_p_in2                     => PCIE_RX_P(i*PCIE_LANES+2),      --                  .rx_p_in2
                rx_p_in3                     => PCIE_RX_P(i*PCIE_LANES+3),      --                  .rx_p_in3
                rx_p_in4                     => PCIE_RX_P(i*PCIE_LANES+4),      --                  .rx_p_in4
                rx_p_in5                     => PCIE_RX_P(i*PCIE_LANES+5),      --                  .rx_p_in5
                rx_p_in6                     => PCIE_RX_P(i*PCIE_LANES+6),      --                  .rx_p_in6
                rx_p_in7                     => PCIE_RX_P(i*PCIE_LANES+7),      --                  .rx_p_in7
                rx_p_in8                     => PCIE_RX_P(i*PCIE_LANES+8),      --                  .rx_p_in8
                rx_p_in9                     => PCIE_RX_P(i*PCIE_LANES+9),      --                  .rx_p_in9
                rx_p_in10                    => PCIE_RX_P(i*PCIE_LANES+10),     --                  .rx_p_in10
                rx_p_in11                    => PCIE_RX_P(i*PCIE_LANES+11),     --                  .rx_p_in11
                rx_p_in12                    => PCIE_RX_P(i*PCIE_LANES+12),     --                  .rx_p_in12
                rx_p_in13                    => PCIE_RX_P(i*PCIE_LANES+13),     --                  .rx_p_in13
                rx_p_in14                    => PCIE_RX_P(i*PCIE_LANES+14),     --                  .rx_p_in14
                rx_p_in15                    => PCIE_RX_P(i*PCIE_LANES+15),     --                  .rx_p_in15
                tx_n_out0                    => PCIE_TX_N(i*PCIE_LANES+0),      --                  .tx_n_out0
                tx_n_out1                    => PCIE_TX_N(i*PCIE_LANES+1),      --                  .tx_n_out1
                tx_n_out2                    => PCIE_TX_N(i*PCIE_LANES+2),      --                  .tx_n_out2
                tx_n_out3                    => PCIE_TX_N(i*PCIE_LANES+3),      --                  .tx_n_out3
                tx_n_out4                    => PCIE_TX_N(i*PCIE_LANES+4),      --                  .tx_n_out4
                tx_n_out5                    => PCIE_TX_N(i*PCIE_LANES+5),      --                  .tx_n_out5
                tx_n_out6                    => PCIE_TX_N(i*PCIE_LANES+6),      --                  .tx_n_out6
                tx_n_out7                    => PCIE_TX_N(i*PCIE_LANES+7),      --                  .tx_n_out7
                tx_n_out8                    => PCIE_TX_N(i*PCIE_LANES+8),      --                  .tx_n_out8
                tx_n_out9                    => PCIE_TX_N(i*PCIE_LANES+9),      --                  .tx_n_out9
                tx_n_out10                   => PCIE_TX_N(i*PCIE_LANES+10),     --                  .tx_n_out10
                tx_n_out11                   => PCIE_TX_N(i*PCIE_LANES+11),     --                  .tx_n_out11
                tx_n_out12                   => PCIE_TX_N(i*PCIE_LANES+12),     --                  .tx_n_out12
                tx_n_out13                   => PCIE_TX_N(i*PCIE_LANES+13),     --                  .tx_n_out13
                tx_n_out14                   => PCIE_TX_N(i*PCIE_LANES+14),     --                  .tx_n_out14
                tx_n_out15                   => PCIE_TX_N(i*PCIE_LANES+15),     --                  .tx_n_out15
                tx_p_out0                    => PCIE_TX_P(i*PCIE_LANES+0),      --                  .tx_p_out0
                tx_p_out1                    => PCIE_TX_P(i*PCIE_LANES+1),      --                  .tx_p_out1
                tx_p_out2                    => PCIE_TX_P(i*PCIE_LANES+2),      --                  .tx_p_out2
                tx_p_out3                    => PCIE_TX_P(i*PCIE_LANES+3),      --                  .tx_p_out3
                tx_p_out4                    => PCIE_TX_P(i*PCIE_LANES+4),      --                  .tx_p_out4
                tx_p_out5                    => PCIE_TX_P(i*PCIE_LANES+5),      --                  .tx_p_out5
                tx_p_out6                    => PCIE_TX_P(i*PCIE_LANES+6),      --                  .tx_p_out6
                tx_p_out7                    => PCIE_TX_P(i*PCIE_LANES+7),      --                  .tx_p_out7
                tx_p_out8                    => PCIE_TX_P(i*PCIE_LANES+8),      --                  .tx_p_out8
                tx_p_out9                    => PCIE_TX_P(i*PCIE_LANES+9),      --                  .tx_p_out9
                tx_p_out10                   => PCIE_TX_P(i*PCIE_LANES+10),     --                  .tx_p_out10
                tx_p_out11                   => PCIE_TX_P(i*PCIE_LANES+11),     --                  .tx_p_out11
                tx_p_out12                   => PCIE_TX_P(i*PCIE_LANES+12),     --                  .tx_p_out12
                tx_p_out13                   => PCIE_TX_P(i*PCIE_LANES+13),     --                  .tx_p_out13
                tx_p_out14                   => PCIE_TX_P(i*PCIE_LANES+14),     --                  .tx_p_out14
                tx_p_out15                   => PCIE_TX_P(i*PCIE_LANES+15),     --                  .tx_p_out15
                coreclkout_hip               => pcie_hip_clk(i),                --    coreclkout_hip.clk
                refclk0                      => PCIE_SYSCLK_P(i*PCIE_CLKS),       --           refclk0.clk
                refclk1                      => PCIE_SYSCLK_P(i*PCIE_CLKS+1),     --           refclk1.clk
                pin_perst_n                  => PCIE_SYSRST_N(i),               --         pin_perst.pin_perst
                ninit_done                   => pcie_init_done_n(i)             --        ninit_done.ninit_done
            );
            pcie_clk(i*2)   <= pcie_hip_clk(i);
            pcie_clk(i*2+1) <= pcie_hip_clk(i);
            init_done_g : if (PCIE_ENDPOINTS > i*2) generate
                pcie_init_done_n(i) <= INIT_DONE_N;
            else generate
                pcie_init_done_n(i) <= '1';
            end generate;
        end generate;
    end generate;

    pcie_avst_g : for i in 0 to PCIE_ENDPOINTS-1 generate
        AVST_DOWN_DATA(i)       <= pcie_avst_down_data(i);
        AVST_DOWN_HDR(i)        <= pcie_avst_down_hdr(i);
        AVST_DOWN_PREFIX(i)     <= pcie_avst_down_prefix(i);
        AVST_DOWN_SOP(i)        <= pcie_avst_down_sop(i);
        AVST_DOWN_EOP(i)        <= pcie_avst_down_eop(i);
        AVST_DOWN_EMPTY(i)      <= pcie_avst_down_empty(i);
        AVST_DOWN_BAR_RANGE(i)  <= pcie_avst_down_bar_range(i);
        AVST_DOWN_VALID(i)      <= pcie_avst_down_valid(i);
        pcie_avst_down_ready(i) <= AVST_DOWN_READY(i);

        pcie_avst_up_data(i)   <= AVST_UP_DATA(i);
        pcie_avst_up_hdr(i)    <= AVST_UP_HDR(i);
        pcie_avst_up_prefix(i) <= AVST_UP_PREFIX(i);
        pcie_avst_up_sop(i)    <= AVST_UP_SOP(i);
        pcie_avst_up_eop(i)    <= AVST_UP_EOP(i);
        pcie_avst_up_error(i)  <= AVST_UP_ERROR(i);
        pcie_avst_up_valid(i)  <= AVST_UP_VALID(i);
        AVST_UP_READY(i)       <= pcie_avst_up_ready(i);
    end generate;

    -- user PCI reset
    pcie_reset_status <= not pcie_reset_status_n;

    pcie_rst_g : for i in 0 to PCIE_EPS_INST-1 generate
        pcie_rst_sync_i : entity work.ASYNC_RESET
        generic map (
            TWO_REG  => false,
            OUT_REG  => true,
            REPLICAS => RESET_WIDTH+1
        )
        port map (
            CLK       => pcie_clk(i),
            ASYNC_RST => pcie_reset_status(i),
            OUT_RST   => pcie_rst(i)
        );
    end generate;

    pcie_clk_rst_g : for i in 0 to PCIE_ENDPOINTS-1 generate
        PCIE_USER_CLK(i)   <= pcie_clk(i);
        PCIE_USER_RESET(i) <= pcie_rst(i)(RESET_WIDTH+1-1 downto 1);
    end generate;

    -- =========================================================================
    --  PCIE CONFIGURATION REGISTERS
    -- =========================================================================

    pcie_cfg_g : for i in 0 to PCIE_ENDPOINTS-1 generate
        process (pcie_clk(i))
        begin
            if (rising_edge(pcie_clk(i))) then
                pcie_link_up_reg(i) <= pcie_link_up_comb(i);
                PCIE_LINK_UP(i)     <= pcie_link_up_reg(i);
            end if;
        end process;

        pcie_cfg_pf0_sel(i)   <= '1' when (unsigned(pcie_cfg_func(i)) = 0) else '0';
        pcie_cfg_reg0_sel(i)  <= '1' when (unsigned(pcie_cfg_addr(i)) = 0) else '0';
        pcie_cfg_reg2_sel(i)  <= '1' when (unsigned(pcie_cfg_addr(i)) = 2) else '0';
        pcie_cfg_reg21_sel(i) <= '1' when (unsigned(pcie_cfg_addr(i)) = 21) else '0';

        process (pcie_clk(i))
        begin
            if (rising_edge(pcie_clk(i))) then
                pcie_cfg_reg0_en(i)  <= pcie_cfg_reg0_sel(i) and pcie_cfg_pf0_sel(i);
                pcie_cfg_reg2_en(i)  <= pcie_cfg_reg2_sel(i) and pcie_cfg_pf0_sel(i);
                pcie_cfg_reg21_en(i) <= pcie_cfg_reg21_sel(i) and pcie_cfg_pf0_sel(i);
                pcie_cfg_data_reg(i) <= pcie_cfg_data(i);
            end if;
        end process;

        process (pcie_clk(i))
        begin
            if (rising_edge(pcie_clk(i))) then
                if (pcie_cfg_reg0_en(i) = '1') then
                    PCIE_MPS(i)        <= pcie_cfg_data_reg(i)(2 downto 0);
                    PCIE_MRRS(i)       <= pcie_cfg_data_reg(i)(5 downto 3);
                    PCIE_EXT_TAG_EN(i) <= pcie_cfg_data_reg(i)(6);
                end if;
                if (pcie_cfg_reg2_en(i) = '1') then
                    PCIE_RCB_SIZE(i) <= pcie_cfg_data_reg(i)(14);
                end if;
                if (pcie_cfg_reg21_en(i) = '1') then
                    PCIE_10B_TAG_REQ_EN(i) <= pcie_cfg_data_reg(i)(14);
                end if;
            end if;
        end process;
    end generate;

    -- =========================================================================
    --  PCI EXT CAP - DEVICE TREE
    -- =========================================================================

    dt_g : for i in 0 to PCIE_ENDPOINTS-1 generate
        constant dt_en : boolean := (i = 0);
    begin
        cii2cfg_ext_i: entity work.PCIE_CII2CFG_EXT
        port map(
            CLK                    => pcie_clk(i),
            RESET                  => pcie_rst(i)(0),

            PCIE_CII_HDR_POISONED  => pcie_cii_hdr_poisoned(i),
            PCIE_CII_OVERRIDE_EN   => pcie_cii_override_en(i),
            PCIE_CII_HDR_FIRST_BE  => pcie_cii_hdr_first_be(i),
            PCIE_CII_DOUT          => pcie_cii_dout(i),
            PCIE_CII_HALT          => pcie_cii_halt(i),
            PCIE_CII_REQ           => pcie_cii_req(i),
            PCIE_CII_ADDR          => pcie_cii_addr(i),
            PCIE_CII_WR            => pcie_cii_wr(i),
            PCIE_CII_OVERRIDE_DIN  => pcie_cii_override_din(i),

            CFG_EXT_READ           => cfg_ext_read(i),
            CFG_EXT_WRITE          => cfg_ext_write(i),
            CFG_EXT_REGISTER       => cfg_ext_register(i),
            CFG_EXT_FUNCTION       => cfg_ext_function(i),
            CFG_EXT_WRITE_DATA     => cfg_ext_write_data(i),
            CFG_EXT_WRITE_BE       => cfg_ext_write_be(i),
            CFG_EXT_READ_DATA      => cfg_ext_read_data(i),
            CFG_EXT_READ_DV        => cfg_ext_read_dv(i)
        );

        -- Device Tree ROM
        pci_ext_cap_i: entity work.PCI_EXT_CAP
        generic map(
            ENDPOINT_ID            => i,
            ENDPOINT_ID_ENABLE     => true,
            DEVICE_TREE_ENABLE     => dt_en,
            VSEC_BASE_ADDRESS      => VSEC_BASE_ADDRESS,
            VSEC_NEXT_POINTER      => 16#000#,
            CFG_EXT_READ_DV_HOTFIX => false
        )
        port map(
            CLK                    => pcie_clk(i),
            CFG_EXT_READ           => cfg_ext_read(i),
            CFG_EXT_WRITE          => cfg_ext_write(i),
            CFG_EXT_REGISTER       => cfg_ext_register(i),
            CFG_EXT_FUNCTION       => cfg_ext_function(i),
            CFG_EXT_WRITE_DATA     => cfg_ext_write_data(i),
            CFG_EXT_WRITE_BE       => cfg_ext_write_be(i),
            CFG_EXT_READ_DATA      => cfg_ext_read_data(i),
            CFG_EXT_READ_DV        => cfg_ext_read_dv(i)
        );
    end generate;

end architecture;
