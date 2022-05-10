-- boot_ctrl.vhd: Simple boot controller
-- Copyright (C) 2022 CESNET z. s. p. o.
-- Author(s): Jakub Cabal <cabal@cesnet.cz>
--
-- SPDX-License-Identifier: BSD-3-Clause

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.math_pack.all;

entity BOOT_CTRL is
    generic(
        -- FPGA device
        DEVICE : string := "ULTRASCALE"
    );
    port(
        MI_CLK        : in  std_logic;
        MI_RESET      : in  std_logic;
        MI_DWR        : in  std_logic_vector(31 downto 0);
        MI_ADDR       : in  std_logic_vector(31 downto 0);
        MI_RD         : in  std_logic;
        MI_WR         : in  std_logic;
        MI_BE         : in  std_logic_vector(3 downto 0);
        MI_DRD        : out std_logic_vector(31 downto 0);
        MI_ARDY       : out std_logic;
        MI_DRDY       : out std_logic;
     
        BOOT_CLK      : in  std_logic;
        BOOT_RESET    : in  std_logic;

        BOOT_REQUEST  : out std_logic;
        BOOT_IMAGE    : out std_logic;

        FLASH_WR_DATA : out std_logic_vector(63 downto 0);
        FLASH_WR_EN   : out std_logic;
        FLASH_RD_DATA : in  std_logic_vector(63 downto 0) := (others => '0')
    );
end entity;

architecture FULL of BOOT_CTRL is

    signal mi_sync_dwr        : std_logic_vector(31 downto 0);
    signal mi_sync_addr       : std_logic_vector(31 downto 0);
    signal mi_sync_rd         : std_logic;
    signal mi_sync_wr         : std_logic;
    signal mi_sync_be         : std_logic_vector(3 downto 0);
    signal mi_sync_drd        : std_logic_vector(31 downto 0);
    signal mi_sync_ardy       : std_logic;
    signal mi_sync_drdy       : std_logic;

    signal boot_cmd           : std_logic := '0';
    signal boot_img           : std_logic := '0';
    signal boot_timeout       : unsigned(25 downto 0) := (others => '0');
    signal flash_wr_data0_reg : std_logic;
    signal flash_wr_cmd       : std_logic := '0';
 
begin

    mi_async_i : entity work.MI_ASYNC
    generic map(
        DEVICE => DEVICE
    )
    port map(
        -- Master interface
        CLK_M     => MI_CLK,
        RESET_M   => MI_RESET,
        MI_M_DWR  => MI_DWR,
        MI_M_ADDR => MI_ADDR,
        MI_M_RD   => MI_RD,
        MI_M_WR   => MI_WR,
        MI_M_BE   => MI_BE,
        MI_M_DRD  => MI_DRD,
        MI_M_ARDY => MI_ARDY,
        MI_M_DRDY => MI_DRDY,

        -- Slave interface
        CLK_S     => BOOT_CLK,
        RESET_S   => BOOT_RESET,
        MI_S_DWR  => mi_sync_dwr,
        MI_S_ADDR => mi_sync_addr,
        MI_S_RD   => mi_sync_rd,
        MI_S_WR   => mi_sync_wr,
        MI_S_BE   => mi_sync_be,
        MI_S_DRD  => mi_sync_drd,
        MI_S_ARDY => mi_sync_ardy,
        MI_S_DRDY => mi_sync_drdy
    );

    mi_sync_ardy <= (mi_sync_rd or mi_sync_wr);

    mi_rd_p : process(BOOT_CLK)
    begin
        if rising_edge(BOOT_CLK) then
            case mi_sync_addr(3 downto 2) is
                when "00"   => mi_sync_drd <= FLASH_RD_DATA(31 downto  0);
                when "01"   => mi_sync_drd <= FLASH_RD_DATA(63 downto 32);     
                when others => mi_sync_drd <= (others => '0');
            end case;
            mi_sync_drdy <= mi_sync_rd;
            if (BOOT_RESET = '1') then
                mi_sync_drdy <= '0';
            end if;
        end if;
    end process;

    mi_wr_p : process(BOOT_CLK)
    begin
        if rising_edge(BOOT_CLK) then
            flash_wr_cmd <= '0';
            if (mi_sync_wr = '1' and boot_cmd = '0') then
                case mi_sync_addr(3 downto 2) is
                    when "00" =>
                        FLASH_WR_DATA(31 downto  0) <= mi_sync_dwr;
                        flash_wr_data0_reg          <= mi_sync_dwr(0);
                    when "01" =>
                        FLASH_WR_DATA(63 downto 32) <= mi_sync_dwr;
                        flash_wr_cmd <= '1';
                        -- Reboot FPGA command
                        if (mi_sync_dwr(31 downto 28) = X"E") then
                            flash_wr_cmd <= '0';
                            boot_cmd <= '1';
                            boot_img <= not flash_wr_data0_reg;
                        end if;
       
                    when others => null;
               end case;
            end if;
            if (BOOT_RESET = '1') then
                boot_cmd <= '0';
            end if;
        end if;
    end process;

    boot_timeout_p : process(BOOT_CLK)
    begin
        if rising_edge(BOOT_CLK) then
            if (boot_cmd = '1') then
                boot_timeout <= boot_timeout + 1;
            else
                boot_timeout <= (others =>'0');
            end if;
        end if;
    end process;

    BOOT_REQUEST <= boot_cmd and (boot_timeout(25));
    BOOT_IMAGE   <= boot_img;

    FLASH_WR_EN <= flash_wr_cmd or BOOT_REQUEST;

end architecture;
