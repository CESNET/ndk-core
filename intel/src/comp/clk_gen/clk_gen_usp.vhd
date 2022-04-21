-- clk_gen_usp.vhd: CLK module for Xilinx UltraScale+ FPGAs
-- Copyright (C) 2022 CESNET z. s. p. o.
-- Author(s): Jakub Cabal <cabal@cesnet.cz>
--
-- SPDX-License-Identifier: BSD-3-Clause

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.math_pack.all;
use work.type_pack.all;

library unisim;
use unisim.vcomponents.all;

architecture USP of COMMON_CLK_GEN is

    -- Period (in ns) of input reference clock
    constant CLK_PERIOD : real := (1e3/real(REFCLK_FREQ));

    constant BASE_FREQ   : real    := 1200.0;
    constant REFCLK_DIV  : natural := 5;
    constant REFCLK_MULT : real    := BASE_FREQ/(real(REFCLK_FREQ)/REFCLK_DIV);

    constant CLK0_FREQ : natural := 400;
    constant CLK1_FREQ : natural := 300;
    constant CLK2_FREQ : natural := 200;
    constant CLK3_FREQ : natural := 100;

    constant CLK0_DIV  : real    := BASE_FREQ/CLK0_FREQ;
    constant CLK1_DIV  : natural := BASE_FREQ/CLK1_FREQ;
    constant CLK2_DIV  : natural := BASE_FREQ/CLK2_FREQ;
    constant CLK3_DIV  : natural := BASE_FREQ/CLK3_FREQ;

    signal clkfbout : std_logic;
    signal clkout0  : std_logic;
    signal clkout1  : std_logic;
    signal clkout2  : std_logic;
    signal clkout3  : std_logic;

begin

    INIT_DONE_N <= '0';

    -- NOTE: CLKOUT 0-3 are High-Performance Clocks (UG472), the rest is not!
    mmcm_i : MMCME2_BASE
    generic map (
        BANDWIDTH        => "LOW",
        DIVCLK_DIVIDE    => REFCLK_DIV, --! Divide input 125 to 25 MHz by default
        CLKFBOUT_MULT_F  => REFCLK_MULT, --! Multiply 25 to 1200 MHz by default
        CLKOUT0_DIVIDE_F => CLK0_DIV,
        CLKOUT1_DIVIDE   => CLK1_DIV,
        CLKOUT2_DIVIDE   => CLK2_DIV,
        CLKOUT3_DIVIDE   => CLK3_DIV,
        CLKOUT4_DIVIDE   => 10,
        CLKOUT5_DIVIDE   => 10,
        CLKOUT6_DIVIDE   => 10,
        CLKIN1_PERIOD    => CLK_PERIOD --! Suppose 125 MHz input
    ) port map (
        CLKFBOUT  => clkfbout,
        CLKFBOUTB => open,
        CLKOUT0   => clkout0,
        CLKOUT0B  => open,
        CLKOUT1   => clkout1,
        CLKOUT1B  => open,
        CLKOUT2   => clkout2,
        CLKOUT2B  => open,
        CLKOUT3   => clkout3,
        CLKOUT3B  => open,
        CLKOUT4   => open,
        CLKOUT5   => open,
        CLKOUT6   => open,
        CLKFBIN   => clkfbout,
        CLKIN1    => REFCLK,
        LOCKED    => LOCKED,
        PWRDWN    => '0',
        RST       => ASYNC_RESET
    );

    clkout0_buf_i : BUFG
    port map (
       O => OUTCLK_0,
       I => clkout0
    );

    clkout1_buf_i : BUFG
    port map (
       O => OUTCLK_1,
       I => clkout1
    );

    clkout2_buf_i : BUFG
    port map (
       O => OUTCLK_2,
       I => clkout2
    );

    clkout3_buf_i : BUFG
    port map (
       O => OUTCLK_3,
       I => clkout3
    );

end architecture;
