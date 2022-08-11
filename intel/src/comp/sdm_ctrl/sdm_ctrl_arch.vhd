-- sdm_ctrl_arch.vhd: SDM controller architecture
-- Copyright (C) 2022 CESNET z. s. p. o.
-- Author(s): Tomas Hak <xhakto01@stud.fit.vutbr.cz>
--
-- SPDX-License-Identifier: BSD-3-Clause

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

architecture FULL of SDM_CTRL is

    constant MC_ADDR_WIDTH : natural := 4;

    component mailbox_client_ip is
    port (
        in_clk_clk         : in  std_logic                     := 'X';             -- clk
        in_reset_reset     : in  std_logic                     := 'X';             -- reset
        avmm_address       : in  std_logic_vector(3 downto 0)  := (others => 'X'); -- address
        avmm_write         : in  std_logic                     := 'X';             -- write
        avmm_writedata     : in  std_logic_vector(31 downto 0) := (others => 'X'); -- writedata
        avmm_read          : in  std_logic                     := 'X';             -- read
        avmm_readdata      : out std_logic_vector(31 downto 0);                    -- readdata
        avmm_readdatavalid : out std_logic;                                        -- readdatavalid
        irq_irq            : out std_logic                                         -- irq
    );
    end component mailbox_client_ip;

    -- mailbox client signals
    signal mc_addr     : std_logic_vector(ADDR_WIDTH-1 downto 0);
    signal mc_wr       : std_logic;
    signal mc_rd       : std_logic;
    signal mc_dwr      : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal mc_drd      : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal mc_drd_vld  : std_logic;

    signal mc_offset   : std_logic_vector(MC_ADDR_WIDTH-1 downto 0);

begin

    -- MI to Avalon MM interface converter
    mi2avmm_i : entity work.MI2AVMM
    generic map(
        DATA_WIDTH => DATA_WIDTH,
        ADDR_WIDTH => ADDR_WIDTH,
        META_WIDTH => 1,
        DEVICE     => DEVICE
    )
    port map(
        CLK                => CLK,
        RESET              => RESET,

        MI_DWR             => MI_DWR,
        MI_MWR             => (others => '0'),
        MI_ADDR            => MI_ADDR,
        MI_RD              => MI_RD,
        MI_WR              => MI_WR,
        MI_BE              => MI_BE,
        MI_DRD             => MI_DRD,
        MI_ARDY            => MI_ARDY,
        MI_DRDY            => MI_DRDY,
        
        AVMM_ADDRESS       => mc_addr,
        AVMM_WRITE         => mc_wr,
        AVMM_READ          => mc_rd,
        AVMM_BYTEENABLE    => open,
        AVMM_WRITEDATA     => mc_dwr,
        AVMM_READDATA      => mc_drd,
        AVMM_READDATAVALID => mc_drd_vld,
        AVMM_WAITREQUEST   => '0'
    );

    -- Mailbox Client address is shifted 2 bits due to different addressing of both interfaces (MI - bytes, AVMM - words)
    mc_offset <= mc_addr(MC_ADDR_WIDTH+2-1 downto 2);

    -- Mailbox Client IP component
    mailbox_client_i : component mailbox_client_ip
    port map (
        in_clk_clk         => CLK,
        in_reset_reset     => RESET,
        avmm_address       => mc_offset,
        avmm_write         => mc_wr,
        avmm_writedata     => mc_dwr,
        avmm_read          => mc_rd,
        avmm_readdata      => mc_drd,
        avmm_readdatavalid => mc_drd_vld,
        irq_irq            => open
    );

end architecture;
