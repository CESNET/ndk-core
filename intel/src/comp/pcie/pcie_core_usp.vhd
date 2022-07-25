-- pcie_core_usp.vhd: PCIe module for USP devices
-- Copyright (C) 2022 CESNET z. s. p. o.
-- Author(s): Jakub Cabal <cabal@cesnet.cz>
--
-- SPDX-License-Identifier: BSD-3-Clause

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.math_pack.all;
use work.type_pack.all;

Library UNISIM;
use UNISIM.vcomponents.all;

architecture USP of PCIE_CORE is

    component pcie4_uscale_plus
    port (
        user_clk                               :  out  std_logic;
        user_reset                             :  out  std_logic;
        user_lnk_up                            :  out  std_logic;

        pci_exp_rxp                            :  in   std_logic_vector(PCIE_LANES-1 downto 0);
        pci_exp_rxn                            :  in   std_logic_vector(PCIE_LANES-1 downto 0);
        pci_exp_txp                            :  out  std_logic_vector(PCIE_LANES-1 downto 0);
        pci_exp_txn                            :  out  std_logic_vector(PCIE_LANES-1 downto 0);

        s_axis_rq_tdata                        :  in   std_logic_vector(AXI_DATA_WIDTH-1    downto 0);
        s_axis_rq_tkeep                        :  in   std_logic_vector(AXI_DATA_WIDTH/32-1 downto 0);
        s_axis_rq_tlast                        :  in   std_logic;
        s_axis_rq_tready                       :  out  std_logic_vector(3     downto  0);
        s_axis_rq_tuser                        :  in   std_logic_vector(AXI_RQUSER_WIDTH-1  downto 0);
        s_axis_rq_tvalid                       :  in   std_logic;
        m_axis_rc_tdata                        :  out  std_logic_vector(AXI_DATA_WIDTH-1    downto 0);
        m_axis_rc_tkeep                        :  out  std_logic_vector(AXI_DATA_WIDTH/32-1 downto 0);
        m_axis_rc_tlast                        :  out  std_logic;
        m_axis_rc_tready                       :  in   std_logic;
        m_axis_rc_tuser                        :  out  std_logic_vector(AXI_RCUSER_WIDTH-1  downto 0);
        m_axis_rc_tvalid                       :  out  std_logic;
        m_axis_cq_tdata                        :  out  std_logic_vector(AXI_DATA_WIDTH-1    downto 0);
        m_axis_cq_tkeep                        :  out  std_logic_vector(AXI_DATA_WIDTH/32-1 downto 0);
        m_axis_cq_tlast                        :  out  std_logic;
        m_axis_cq_tready                       :  in   std_logic;
        m_axis_cq_tuser                        :  out  std_logic_vector(AXI_CQUSER_WIDTH-1  downto 0);
        m_axis_cq_tvalid                       :  out  std_logic;
        s_axis_cc_tdata                        :  in   std_logic_vector(AXI_DATA_WIDTH-1    downto 0);
        s_axis_cc_tkeep                        :  in   std_logic_vector(AXI_DATA_WIDTH/32-1 downto 0);
        s_axis_cc_tlast                        :  in   std_logic;
        s_axis_cc_tready                       :  out  std_logic_vector(3     downto  0);
        s_axis_cc_tuser                        :  in   std_logic_vector(AXI_CCUSER_WIDTH-1  downto 0);
        s_axis_cc_tvalid                       :  in   std_logic;
        pcie_rq_seq_num0                       :  out  std_logic_vector(5     downto  0);
        pcie_rq_seq_num_vld0                   :  out  std_logic;
        pcie_rq_seq_num1                       :  out  std_logic_vector(5     downto  0);
        pcie_rq_seq_num_vld1                   :  out  std_logic;
        pcie_rq_tag0                           :  out  std_logic_vector(7     downto  0);
        pcie_rq_tag1                           :  out  std_logic_vector(7     downto  0);
        pcie_rq_tag_av                         :  out  std_logic_vector(3     downto  0);
        pcie_rq_tag_vld0                       :  out  std_logic;
        pcie_rq_tag_vld1                       :  out  std_logic;
        pcie_tfc_nph_av                        :  out  std_logic_vector(3     downto  0);
        pcie_tfc_npd_av                        :  out  std_logic_vector(3     downto  0);
        pcie_cq_np_req                         :  in   std_logic_vector(1     downto  0);
        pcie_cq_np_req_count                   :  out  std_logic_vector(5     downto  0);
        cfg_phy_link_down                      :  out  std_logic;
        cfg_phy_link_status                    :  out  std_logic_vector(1     downto  0);
        cfg_negotiated_width                   :  out  std_logic_vector(2     downto  0);
        cfg_current_speed                      :  out  std_logic_vector(1     downto  0);
        cfg_max_payload                        :  out  std_logic_vector(1     downto  0);
        cfg_max_read_req                       :  out  std_logic_vector(2     downto  0);
        cfg_function_status                    :  out  std_logic_vector(15    downto  0);
        cfg_function_power_state               :  out  std_logic_vector(11    downto  0);
        cfg_vf_status                          :  out  std_logic_vector(503   downto  0);
        cfg_vf_power_state                     :  out  std_logic_vector(755   downto  0);
        cfg_link_power_state                   :  out  std_logic_vector(1     downto  0);
        cfg_mgmt_addr                          :  in   std_logic_vector(9     downto  0);
        cfg_mgmt_function_number               :  in   std_logic_vector(7     downto  0);
        cfg_mgmt_write                         :  in   std_logic;
        cfg_mgmt_write_data                    :  in   std_logic_vector(31    downto  0);
        cfg_mgmt_byte_enable                   :  in   std_logic_vector(3     downto  0);
        cfg_mgmt_read                          :  in   std_logic;
        cfg_mgmt_read_data                     :  out  std_logic_vector(31    downto  0);
        cfg_mgmt_read_write_done               :  out  std_logic;
        cfg_mgmt_debug_access                  :  in   std_logic;
        cfg_err_cor_out                        :  out  std_logic;
        cfg_err_nonfatal_out                   :  out  std_logic;
        cfg_err_fatal_out                      :  out  std_logic;
        cfg_local_error_valid                  :  out  std_logic;
        cfg_local_error_out                    :  out  std_logic_vector(4     downto  0);
        cfg_ltssm_state                        :  out  std_logic_vector(5     downto  0);
        cfg_rx_pm_state                        :  out  std_logic_vector(1     downto  0);
        cfg_tx_pm_state                        :  out  std_logic_vector(1     downto  0);
        cfg_rcb_status                         :  out  std_logic_vector(3     downto  0);
        cfg_obff_enable                        :  out  std_logic_vector(1     downto  0);
        cfg_pl_status_change                   :  out  std_logic;
        cfg_tph_requester_enable               :  out  std_logic_vector(3     downto  0);
        cfg_tph_st_mode                        :  out  std_logic_vector(11    downto  0);
        cfg_vf_tph_requester_enable            :  out  std_logic_vector(251   downto  0);
        cfg_vf_tph_st_mode                     :  out  std_logic_vector(755   downto  0);
        cfg_dsn                                :  in   std_logic_vector(63    downto  0);
        cfg_bus_number                         :  out  std_logic_vector(7     downto  0);
        cfg_msg_received                       :  out  std_logic;
        cfg_msg_received_data                  :  out  std_logic_vector(7    downto  0);
        cfg_msg_received_type                  :  out  std_logic_vector(4    downto  0);
        cfg_msg_transmit                       :  in   std_logic;
        cfg_msg_transmit_type                  :  in   std_logic_vector(2    downto  0);
        cfg_msg_transmit_data                  :  in   std_logic_vector(31   downto  0);
        cfg_msg_transmit_done                  :  out  std_logic;
        cfg_fc_ph                              :  out  std_logic_vector(7    downto  0);
        cfg_fc_pd                              :  out  std_logic_vector(11   downto  0);
        cfg_fc_nph                             :  out  std_logic_vector(7    downto  0);
        cfg_fc_npd                             :  out  std_logic_vector(11   downto  0);
        cfg_fc_cplh                            :  out  std_logic_vector(7    downto  0);
        cfg_fc_cpld                            :  out  std_logic_vector(11   downto  0);
        cfg_fc_sel                             :  in   std_logic_vector(2    downto  0);
        cfg_power_state_change_ack             :  in   std_logic;
        cfg_power_state_change_interrupt       :  out  std_logic;
        cfg_err_cor_in                         :  in   std_logic;
        cfg_err_uncor_in                       :  in   std_logic;
        cfg_flr_in_process                     :  out  std_logic_vector(3     downto  0);
        cfg_flr_done                           :  in   std_logic_vector(3     downto  0);
        cfg_vf_flr_in_process                  :  out  std_logic_vector(251   downto  0);
        cfg_vf_flr_func_num                    :  in   std_logic_vector(7     downto  0);
        cfg_vf_flr_done                        :  in   std_logic_vector(0     downto  0);
        cfg_link_training_enable               :  in   std_logic;
        cfg_ext_read_received                  :  out  std_logic;
        cfg_ext_write_received                 :  out  std_logic;
        cfg_ext_register_number                :  out  std_logic_vector(9     downto  0);
        cfg_ext_function_number                :  out  std_logic_vector(7     downto  0);
        cfg_ext_write_data                     :  out  std_logic_vector(31    downto  0);
        cfg_ext_write_byte_enable              :  out  std_logic_vector(3     downto  0);
        cfg_ext_read_data                      :  in   std_logic_vector(31    downto  0);
        cfg_ext_read_data_valid                :  in   std_logic;
        cfg_interrupt_int                      :  in   std_logic_vector(3    downto  0);
        cfg_interrupt_pending                  :  in   std_logic_vector(3    downto  0);
        cfg_interrupt_sent                     :  out  std_logic;
        cfg_interrupt_msi_sent                 :  out  std_logic;
        cfg_interrupt_msi_fail                 :  out  std_logic;
        cfg_interrupt_msi_function_number      :  in   std_logic_vector(7    downto  0);
        cfg_interrupt_msix_enable              :  out  std_logic_vector(3    downto  0);
        cfg_interrupt_msix_mask                :  out  std_logic_vector(3    downto  0);
        cfg_interrupt_msix_vf_enable           :  out  std_logic_vector(251  downto  0);
        cfg_interrupt_msix_vf_mask             :  out  std_logic_vector(251  downto  0);
        cfg_interrupt_msix_data                :  in   std_logic_vector(31   downto  0);
        cfg_interrupt_msix_address             :  in   std_logic_vector(63   downto  0);
        cfg_interrupt_msix_int                 :  in   std_logic;
        cfg_interrupt_msix_vec_pending         :  in   std_logic_vector(1    downto  0);
        cfg_interrupt_msix_vec_pending_status  :  out  std_logic_vector(0    downto  0);
        cfg_pm_aspm_l1_entry_reject            :  in   std_logic;
        cfg_pm_aspm_tx_l0s_entry_disable       :  in   std_logic;
        cfg_hot_reset_out                      :  out  std_logic;
        cfg_config_space_enable                :  in   std_logic;
        cfg_req_pm_transition_l23_ready        :  in   std_logic;
        cfg_hot_reset_in                       :  in   std_logic;
        cfg_ds_port_number                     :  in   std_logic_vector(7     downto  0);
        cfg_ds_bus_number                      :  in   std_logic_vector(7     downto  0);
        cfg_ds_device_number                   :  in   std_logic_vector(4     downto  0);
        sys_clk                                :  in   std_logic;
        sys_clk_gt                             :  in   std_logic;
        sys_reset                              :  in   std_logic;
        phy_rdy_out                            :  out  std_logic
    );
    end component;

    component xvc_vsec
    port (
            clk                                : in    std_logic;
            pcie3_cfg_ext_function_number      : in    std_logic_vector(7 downto 0);
            pcie3_cfg_ext_read_data            : out   std_logic_vector(31 downto 0);
            pcie3_cfg_ext_read_data_valid      : out   std_logic;
            pcie3_cfg_ext_read_received        : in    std_logic;
            pcie3_cfg_ext_register_number      : in    std_logic_vector(9 downto 0);
            pcie3_cfg_ext_write_byte_enable    : in    std_logic_vector(3 downto 0);
            pcie3_cfg_ext_write_data           : in    std_logic_vector(31 downto 0);
            pcie3_cfg_ext_write_received       : in    std_logic
    );
    end component;
    
    constant VSEC_BASE_ADDRESS : natural := 16#480#;
    constant DTB_NEXT_POINTER  : natural := tsel(XVC_ENABLE, 16#4A0#, 0);
    constant PCIE_HIPS         : natural := tsel(ENDPOINT_MODE=0,PCIE_ENDPOINTS,PCIE_ENDPOINTS/2);

    signal pcie_sysclk_buf          : std_logic_vector(PCIE_ENDPOINTS-1 downto 0);
    signal pcie_sysclk_gt_buf       : std_logic_vector(PCIE_ENDPOINTS-1 downto 0);

    signal pcie_hip_clk             : std_logic_vector(PCIE_HIPS-1 downto 0);
    signal pcie_hip_rst             : std_logic_vector(PCIE_HIPS-1 downto 0);
    signal pcie_clk                 : std_logic_vector(PCIE_ENDPOINTS-1 downto 0);
    signal pcie_rst_async           : std_logic_vector(PCIE_ENDPOINTS-1 downto 0);
    signal pcie_rst                 : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(RESET_WIDTH+1-1 downto 0);
    
    signal cfg_rcb_status           : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(3 downto 0);
    signal cfg_max_payload          : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(1 downto 0);
    signal cfg_max_read_req         : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(2 downto 0);
    signal cfg_phy_link_status      : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(1 downto 0);
    signal user_lnk_up              : std_logic_vector(PCIE_ENDPOINTS-1 downto 0);

    signal cfg_ext_read             : std_logic_vector(PCIE_ENDPOINTS-1 downto 0);
    signal cfg_ext_write            : std_logic_vector(PCIE_ENDPOINTS-1 downto 0);
    signal cfg_ext_register         : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(9 downto 0);
    signal cfg_ext_function         : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(7 downto 0);
    signal cfg_ext_write_data       : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(31 downto 0);
    signal cfg_ext_write_be         : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(3 downto 0);
    signal cfg_ext_read_xvc_data    : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(31 downto 0);
    signal cfg_ext_read_xvc_dv      : std_logic_vector(PCIE_ENDPOINTS-1 downto 0) := (others => '0');
    signal cfg_ext_read_dtb_data    : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(31 downto 0);
    signal cfg_ext_read_dtb_dv      : std_logic_vector(PCIE_ENDPOINTS-1 downto 0) := (others => '0');
    signal cfg_ext_read_data        : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(31 downto 0);
    signal cfg_ext_read_dv          : std_logic_vector(PCIE_ENDPOINTS-1 downto 0);

    signal s_axis_rq_tready         : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(3 downto 0);
    signal s_axis_cc_tready         : slv_array_t(PCIE_ENDPOINTS-1 downto 0)(3 downto 0);

begin

    assert ENDPOINT_MODE=0 report "Xilinx USP PCIe Wrapper: Only ENDPOINT_MODE=0 is now supported!"
        severity failure;

    assert DEVICE="ULTRASCALE" report "Xilinx USP PCIe Wrapper: Only ULTRASCALE+ device is supported!"
        severity failure;

    -- =========================================================================
    --  PCIE IP CORE
    -- =========================================================================

    pcie_g : for i in 0 to PCIE_HIPS-1 generate
        pcie_ibuf_i : IBUFDS_GTE4
        generic map (
            REFCLK_HROW_CK_SEL => "00"
        )
        port map (
            I     => PCIE_SYSCLK_P(i),
            IB    => PCIE_SYSCLK_N(i),
            O     => pcie_sysclk_gt_buf(i),
            ODIV2 => pcie_sysclk_buf(i),
            CEB   => '0'
        );

        gen3_1x16_g : if ENDPOINT_MODE = 0 generate

            RQ_AXI_READY(i) <= s_axis_rq_tready(i)(0);
            CC_AXI_READY(i) <= s_axis_cc_tready(i)(0);

            pcie_clk(i) <= pcie_hip_clk(i);

            pcie_i : pcie4_uscale_plus
            port map (
                sys_clk                           => pcie_sysclk_buf(i),
                sys_clk_gt                        => pcie_sysclk_gt_buf(i),
                sys_reset                         => PCIE_SYSRST_N(i),
        
                pci_exp_txn                       => PCIE_TX_N((i+1)*PCIE_LANES-1 downto i*PCIE_LANES),
                pci_exp_txp                       => PCIE_TX_P((i+1)*PCIE_LANES-1 downto i*PCIE_LANES),
                pci_exp_rxn                       => PCIE_RX_N((i+1)*PCIE_LANES-1 downto i*PCIE_LANES),
                pci_exp_rxp                       => PCIE_RX_P((i+1)*PCIE_LANES-1 downto i*PCIE_LANES),
        
                user_clk                          => pcie_hip_clk(i),
                user_reset                        => pcie_hip_rst(i),
                user_lnk_up                       => user_lnk_up(i),
        
                s_axis_rq_tlast                   => RQ_AXI_LAST(i),
                s_axis_rq_tdata                   => RQ_AXI_DATA(i),
                s_axis_rq_tuser                   => RQ_AXI_USER(i),
                s_axis_rq_tkeep                   => RQ_AXI_KEEP(i),
                s_axis_rq_tready                  => s_axis_rq_tready(i),
                s_axis_rq_tvalid                  => RQ_AXI_VALID(i),
                m_axis_rc_tdata                   => RC_AXI_DATA(i),
                m_axis_rc_tuser                   => RC_AXI_USER(i),
                m_axis_rc_tlast                   => RC_AXI_LAST(i),
                m_axis_rc_tkeep                   => RC_AXI_KEEP(i),
                m_axis_rc_tvalid                  => RC_AXI_VALID(i),
                m_axis_rc_tready                  => RC_AXI_READY(i),
                m_axis_cq_tdata                   => CQ_AXI_DATA(i),
                m_axis_cq_tuser                   => CQ_AXI_USER(i),
                m_axis_cq_tlast                   => CQ_AXI_LAST(i),
                m_axis_cq_tkeep                   => CQ_AXI_KEEP(i),
                m_axis_cq_tvalid                  => CQ_AXI_VALID(i),
                m_axis_cq_tready                  => CQ_AXI_READY(i),
                s_axis_cc_tdata                   => CC_AXI_DATA(i),
                s_axis_cc_tuser                   => CC_AXI_USER(i),
                s_axis_cc_tlast                   => CC_AXI_LAST(i),
                s_axis_cc_tkeep                   => CC_AXI_KEEP(i),
                s_axis_cc_tvalid                  => CC_AXI_VALID(i),
                s_axis_cc_tready                  => s_axis_cc_tready(i),
                pcie_rq_seq_num0                  => open,
                pcie_rq_seq_num_vld0              => open,
                pcie_rq_tag0                      => TAG_ASSIGN(i)(7 downto 0),
                pcie_rq_tag_vld0                  => TAG_ASSIGN_VLD(i)(0),
                pcie_rq_tag1                      => TAG_ASSIGN(i)(15 downto 8),
                pcie_rq_tag_vld1                  => TAG_ASSIGN_VLD(i)(1),
                pcie_cq_np_req                    => (others => '1'),
                pcie_cq_np_req_count              => open,
                cfg_phy_link_down                 => open,
                cfg_phy_link_status               => cfg_phy_link_status(i),
                cfg_negotiated_width              => open,
                cfg_current_speed                 => open,
                cfg_max_payload                   => cfg_max_payload(i),
                cfg_max_read_req                  => cfg_max_read_req(i),
                cfg_function_status               => open,
                cfg_function_power_state          => open,
                cfg_vf_status                     => open,
                cfg_vf_power_state                => open,
                cfg_link_power_state              => open,
                cfg_mgmt_addr                     => (others => '0'),
                cfg_mgmt_function_number          => (others => '0'),
                cfg_mgmt_write                    => '0',
                cfg_mgmt_write_data               => (others => '0'),
                cfg_mgmt_byte_enable              => (others => '0'),
                cfg_mgmt_read                     => '0',
                cfg_mgmt_read_data                => open,
                cfg_mgmt_read_write_done          => open,
                cfg_mgmt_debug_access             => '0',
                cfg_err_cor_out                   => open,
                cfg_err_nonfatal_out              => open,
                cfg_err_fatal_out                 => open,
                cfg_local_error_valid             => open,
                cfg_local_error_out               => open,
                cfg_ltssm_state                   => open,
                cfg_rx_pm_state                   => open,
                cfg_tx_pm_state                   => open,
                cfg_rcb_status                    => cfg_rcb_status(i),
                cfg_obff_enable                   => open,
                cfg_pl_status_change              => open,
                cfg_tph_requester_enable          => open,
                cfg_tph_st_mode                   => open,
                cfg_vf_tph_requester_enable       => open,
                cfg_vf_tph_st_mode                => open,
                cfg_dsn                           => (others => '1'),
                cfg_bus_number                    => open,
                cfg_msg_received                  => open,
                cfg_msg_received_data             => open,
                cfg_msg_received_type             => open,
                cfg_msg_transmit                  => '0',
                cfg_msg_transmit_type             => (others => '0'),
                cfg_msg_transmit_data             => (others => '0'),
                cfg_msg_transmit_done             => open,
                cfg_fc_ph                         => open,
                cfg_fc_pd                         => open,
                cfg_fc_nph                        => open,
                cfg_fc_npd                        => open,
                cfg_fc_cplh                       => open,
                cfg_fc_cpld                       => open,
                cfg_fc_sel                        => (others => '0'),
                cfg_power_state_change_ack        => '0',
                cfg_power_state_change_interrupt  => open,
                cfg_err_cor_in                    => '0',
                cfg_err_uncor_in                  => '0',
                cfg_flr_in_process                => open,
                cfg_flr_done                      => (others => '0'),
                cfg_vf_flr_in_process             => open,
                cfg_vf_flr_func_num               => (others => '0'),
                cfg_vf_flr_done                   => (others => '0'),
                cfg_link_training_enable          => '1',
                cfg_ext_read_received             => cfg_ext_read(i),
                cfg_ext_write_received            => cfg_ext_write(i),
                cfg_ext_register_number           => cfg_ext_register(i),
                cfg_ext_function_number           => cfg_ext_function(i),
                cfg_ext_write_data                => cfg_ext_write_data(i),
                cfg_ext_write_byte_enable         => cfg_ext_write_be(i),
                cfg_ext_read_data                 => cfg_ext_read_data(i),
                cfg_ext_read_data_valid           => cfg_ext_read_dv(i),
                cfg_interrupt_int                 => (others => '0'),
                cfg_interrupt_pending             => (others => '0'),
                cfg_interrupt_sent                => open,
                cfg_interrupt_msi_sent            => open,
                cfg_interrupt_msi_fail            => open,
                cfg_interrupt_msi_function_number => (others => '0'),
                cfg_interrupt_msix_enable         => open,
                cfg_interrupt_msix_mask           => open,
                cfg_interrupt_msix_vf_enable      => open,
                cfg_interrupt_msix_vf_mask        => open,
                cfg_interrupt_msix_data           => (others => '0'),
                cfg_interrupt_msix_address        => (others => '0'),
                cfg_interrupt_msix_int            => '0',
                cfg_interrupt_msix_vec_pending    => (others => '0'),
                cfg_interrupt_msix_vec_pending_status => open,
                cfg_pm_aspm_l1_entry_reject       => '0',
                cfg_pm_aspm_tx_l0s_entry_disable  => '0',
                cfg_hot_reset_out                 => open,
                cfg_config_space_enable           => '1',
                cfg_req_pm_transition_l23_ready   => '0',
                cfg_hot_reset_in                  => '0',
                cfg_ds_port_number                => (others => '0'),
                cfg_ds_bus_number                 => (others => '0'),
                cfg_ds_device_number              => (others => '0'),
                phy_rdy_out                       => open
            );
        end generate;
    end generate;

    -- =========================================================================
    --  PCIE RESET LOGIC
    -- =========================================================================

    pcie_rst_g : for i in 0 to PCIE_ENDPOINTS-1 generate
        pcie_rst_async(i) <= pcie_hip_rst(i) and not user_lnk_up(i);

        pcie_rst_sync_i : entity work.ASYNC_RESET
        generic map (
            TWO_REG  => false,
            OUT_REG  => true,
            REPLICAS => RESET_WIDTH+1
        )
        port map (
            CLK       => pcie_clk(i),
            ASYNC_RST => pcie_rst_async(i),
            OUT_RST   => pcie_rst(i)
        );

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
                PCIE_LINK_UP(i)  <= cfg_phy_link_status(i)(0) and cfg_phy_link_status(i)(1);
                PCIE_RCB_SIZE(i) <= cfg_rcb_status(i)(0);
                PCIE_MRRS(i)     <= cfg_max_read_req(i);
                PCIE_MPS(i)      <= '0' & cfg_max_payload(i);
            end if;
        end process;
        PCIE_EXT_TAG_EN(i)     <= '1';
        PCIE_10B_TAG_REQ_EN(i) <= '0';
    end generate;

    -- =========================================================================
    --  PCI EXT CAP - DEVICE TREE
    -- =========================================================================

    dt_g : for i in 0 to PCIE_ENDPOINTS-1 generate
        constant dt_en : boolean := (i = 0);
    begin
        -- Device Tree ROM
        pci_ext_cap_i: entity work.PCI_EXT_CAP
        generic map(
            ENDPOINT_ID            => i,
            ENDPOINT_ID_ENABLE     => true,
            DEVICE_TREE_ENABLE     => dt_en,
            VSEC_BASE_ADDRESS      => VSEC_BASE_ADDRESS,
            VSEC_NEXT_POINTER      => DTB_NEXT_POINTER,
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
            CFG_EXT_READ_DATA      => cfg_ext_read_dtb_data(i),
            CFG_EXT_READ_DV        => cfg_ext_read_dtb_dv(i)
        );

        xvc_g: if (XVC_ENABLE) generate
            xvc_i : xvc_vsec
            port map (
                clk                              => pcie_clk(i),
                pcie3_cfg_ext_function_number    => cfg_ext_function(i),
                pcie3_cfg_ext_read_data          => cfg_ext_read_xvc_data(i),
                pcie3_cfg_ext_read_data_valid    => cfg_ext_read_xvc_dv(i),
                pcie3_cfg_ext_read_received      => cfg_ext_read(i),
                pcie3_cfg_ext_register_number    => cfg_ext_register(i),
                pcie3_cfg_ext_write_byte_enable  => cfg_ext_write_be(i),
                pcie3_cfg_ext_write_data         => cfg_ext_write_data(i),
                pcie3_cfg_ext_write_received     => cfg_ext_write(i)
            );
        end generate;

        cfg_ext_read_dv(i) <= cfg_ext_read_dtb_dv(i) or cfg_ext_read_xvc_dv(i);
        cfg_ext_read_data(i) <= cfg_ext_read_xvc_data(i) when (cfg_ext_read_xvc_dv(i) = '1') else cfg_ext_read_dtb_data(i);
    end generate;
    
end architecture;
