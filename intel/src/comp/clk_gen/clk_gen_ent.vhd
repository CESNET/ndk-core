-- clk_gen_ent.vhd: CLK module entity
-- Copyright (C) 2022 CESNET z. s. p. o.
-- Author(s): Jakub Cabal <cabal@cesnet.cz>
--
-- SPDX-License-Identifier: BSD-3-Clause

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.math_pack.all;
use work.type_pack.all;

entity COMMON_CLK_GEN is
    generic(
        -- Reference clock frequency in MHz
        REFCLK_FREQ        : natural := 50;
        -- Use FPGA init done signal as PLL reset input instead of async reset.
        -- It is recommended, see AN 891: Using the Reset Release Intel FPGA IP.
        -- Only for Intel Agilex and Stratix 10 FPGAs!
        INIT_DONE_AS_RESET : boolean := True;
        -- FPGA device
        DEVICE             : string := "AGILEX"
    );
    port(
        -- Reference clock input
        REFCLK      : in  std_logic;
        -- PLL async reset
        ASYNC_RESET : in  std_logic;
        -- PLL locked status
        LOCKED      : out std_logic;
        -- FPGA init done (Intel only)
        INIT_DONE_N : out std_logic;
        -- Output clock 0
        OUTCLK_0    : out std_logic;
        -- Output clock 1
        OUTCLK_1    : out std_logic;
        -- Output clock 2
        OUTCLK_2    : out std_logic;
        -- Output clock 3
        OUTCLK_3    : out std_logic
    );
end entity;
