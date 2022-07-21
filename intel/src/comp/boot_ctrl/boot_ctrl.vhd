-- boot_ctrl.vhd: Simple boot controller
-- Copyright (C) 2022 CESNET z. s. p. o.
-- Author(s): Jakub Cabal <cabal@cesnet.cz>
--
-- SPDX-License-Identifier: BSD-3-Clause

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.math_pack.all;
use work.type_pack.all;

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
        FLASH_RD_DATA : in  std_logic_vector(63 downto 0) := (others => '0');

        AXI_MI_ADDR : out std_logic_vector(8 - 1 downto 0);
        AXI_MI_DWR  : out std_logic_vector(32 - 1 downto 0);
        AXI_MI_WR   : out std_logic;
        AXI_MI_RD   : out std_logic;
        AXI_MI_BE   : out std_logic_vector((32/8)-1 downto 0);
        AXI_MI_ARDY : in  std_logic :='0';
        AXI_MI_DRD  : in  std_logic_vector(32 - 1 downto 0) :=(others => '0');
        AXI_MI_DRDY : in  std_logic :='0'
    );
end entity;

architecture FULL of BOOT_CTRL is
    -- MI SPLITTER
    constant MI_BOOT_PORTS : natural := 2;
    constant MI_BOOT_ADDR_BASE : slv_array_t(MI_BOOT_PORTS-1 downto 0)(32-1 downto 0)
    := ( 0 => X"0000_0000",     -- BMC
         1 => X"0000_2100");    -- AXI Quad SPI 
    constant MASK :std_logic_vector(32 -1 downto 0):=(8 => '1', others => '0');

    -- MI ASYNC
    signal mi_sync_dwr        : std_logic_vector(31 downto 0);
    signal mi_sync_addr       : std_logic_vector(31 downto 0);
    signal mi_sync_rd         : std_logic;
    signal mi_sync_wr         : std_logic;
    signal mi_sync_be         : std_logic_vector(3 downto 0);
    signal mi_sync_drd        : std_logic_vector(31 downto 0);
    signal mi_sync_ardy       : std_logic;
    signal mi_sync_drdy       : std_logic;
    -- MI SPLITTER
    signal mi_split_dwr        : slv_array_t(MI_BOOT_PORTS-1 downto 0)(31 downto 0);
    signal mi_split_addr       : slv_array_t(MI_BOOT_PORTS-1 downto 0)(31 downto 0);
    signal mi_split_rd         : std_logic_vector(MI_BOOT_PORTS-1 downto 0);
    signal mi_split_wr         : std_logic_vector(MI_BOOT_PORTS-1 downto 0);
    signal mi_split_be         : slv_array_t(MI_BOOT_PORTS-1 downto 0)( 3 downto 0);
    signal mi_split_drd        : slv_array_t(MI_BOOT_PORTS-1 downto 0)(31 downto 0):=(others => (others => '0'));
    signal mi_split_ardy       : std_logic_vector(MI_BOOT_PORTS-1 downto 0);
    signal mi_split_drdy       : std_logic_vector(MI_BOOT_PORTS-1 downto 0):=(others => '0');

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

    mi_splitter_i : entity work.MI_SPLITTER_PLUS_GEN
    generic map(
        ADDR_WIDTH    => 32,
        DATA_WIDTH    => 32,
        PORTS         => MI_BOOT_PORTS,
        PIPE_OUTREG   => true,
        ADDR_BASE     => MI_BOOT_ADDR_BASE,
        ADDR_MASK     => MASK,
        DEVICE        => DEVICE
    )
    port map(
        CLK        => BOOT_CLK,
        RESET      => BOOT_RESET,

        RX_DWR     => mi_sync_dwr,
        RX_ADDR    => mi_sync_addr,
        RX_BE      => mi_sync_be,
        RX_RD      => mi_sync_rd,
        RX_WR      => mi_sync_wr,
        RX_ARDY    => mi_sync_ardy,
        RX_DRD     => mi_sync_drd,
        RX_DRDY    => mi_sync_drdy,

        TX_DWR     => mi_split_dwr,
        TX_ADDR    => mi_split_addr,
        TX_BE      => mi_split_be,
        TX_RD      => mi_split_rd,
        TX_WR      => mi_split_wr,
        TX_ARDY    => mi_split_ardy,
        TX_DRD     => mi_split_drd,
        TX_DRDY    => mi_split_drdy
    );


    -- Axi Quad SPI interface
    AXI_MI_ADDR         <= mi_split_addr(1)(8 - 1  downto 0);
    AXI_MI_DWR          <= mi_split_dwr(1);
    AXI_MI_WR           <= mi_split_wr(1);
    AXI_MI_RD           <= mi_split_rd(1);
    AXI_MI_BE           <= mi_split_be(1);
    mi_split_ardy(1)    <= AXI_MI_ARDY;
    mi_split_drd(1)     <= AXI_MI_DRD;
    mi_split_drdy(1)    <= AXI_MI_DRDY;


    mi_split_ardy(0)<= (mi_split_rd(0) or mi_split_wr(0));
    mi_rd_p : process(BOOT_CLK)
    begin
        if rising_edge(BOOT_CLK) then
            case mi_split_addr(0)(3 downto 2) is
                when "00"   => mi_split_drd(0) <= FLASH_RD_DATA(31 downto  0);
                when "01"   => mi_split_drd(0) <= FLASH_RD_DATA(63 downto 32);
                when others => mi_split_drd(0) <= (others => '0');
            end case;
            mi_split_drdy(0) <= mi_split_rd(0);
                
            if (BOOT_RESET = '1') then
                mi_split_drdy(0) <= '0';
            end if;
        end if;
    end process;


    mi_wr_p : process(BOOT_CLK)
    begin
        if rising_edge(BOOT_CLK) then
            flash_wr_cmd <= '0';
            if (mi_split_wr(0) = '1' and boot_cmd = '0') then
                case mi_split_addr(0)(3 downto 2) is
                    when "00" =>
                        FLASH_WR_DATA(31 downto  0) <= mi_split_dwr(0);
                        flash_wr_data0_reg          <= mi_split_dwr(0)(0);
                    when "01" =>
                        FLASH_WR_DATA(63 downto 32) <= mi_split_dwr(0);
                        flash_wr_cmd <= '1';
                        -- Reboot FPGA command
                        if (mi_split_dwr(0)(31 downto 28) = X"E") then
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
