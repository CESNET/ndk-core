-- qsfp_ctrl.vhd: QSFP control registerss
-- Copyright (C) 2020 CESNET z. s. p. o.
-- Author(s): Stepan Friedl <friedl@cesnet.cz>
--            Jakub Cabal   <cabal@cesnet.cz>
--
-- SPDX-License-Identifier: BSD-3-Clause
-- 0x80010..14 - I2C registers
-- 0x80010..1C - QSFP control/status


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_misc.all;
use work.math_pack.all;

entity qsfp_ctrl is
generic (
    QSFP_PORTS          : integer := 1;
    QSFP_I2C_PORTS      : integer := 1;
    FPC202_INIT_EN      : boolean := false
);
port (
    RST                  : in  std_logic;
    --
    TX_READY             : in  std_logic_vector(QSFP_PORTS-1 downto 0);
    -- QSFP control/status
    QSFP_MODSEL_N       : out   std_logic_vector(QSFP_PORTS-1 downto 0);
    QSFP_LPMODE         : out   std_logic_vector(QSFP_PORTS-1 downto 0);
    QSFP_RESET_N        : out   std_logic_vector(QSFP_PORTS-1 downto 0);
    QSFP_MODPRS_N       : in    std_logic_vector(QSFP_PORTS-1 downto 0);
    QSFP_INT_N          : in    std_logic_vector(QSFP_PORTS-1 downto 0);
    QSFP_I2C_SCL        : inout std_logic_vector(QSFP_I2C_PORTS-1 downto 0);
    QSFP_I2C_SDA        : inout std_logic_vector(QSFP_I2C_PORTS-1 downto 0);
    QSFP_I2C_DIR        : out   std_logic_vector(QSFP_I2C_PORTS-1 downto 0); -- I2C bus direction, 0 = QSFP -> FPGA, 1 = FPGA -> QSFP     
    -- Select which QSFP port is targetting during MI read/writes
    MI_QSFP_SEL           : in  std_logic_vector(max(log2(QSFP_PORTS)-1, 0) downto 0);
    -- MI32 interface - 
    MI_CLK_PHY            : in  std_logic;
    MI_RESET_PHY          : in  std_logic;
    MI_DWR_PHY            : in  std_logic_vector(31 downto 0);
    MI_ADDR_PHY           : in  std_logic_vector(31 downto 0);
    MI_RD_PHY             : in  std_logic;
    MI_WR_PHY             : in  std_logic;
    MI_BE_PHY             : in  std_logic_vector( 3 downto 0);
    MI_DRD_PHY            : out std_logic_vector(31 downto 0);
    MI_ARDY_PHY           : out std_logic;
    MI_DRDY_PHY           : out std_logic   
);
end entity;

architecture full of qsfp_ctrl is

    signal i2c_mi_wr             : std_logic;   
    signal i2c_qsfp_scl_o        : std_logic;
    signal i2c_qsfp_scl_oen      : std_logic;
    signal i2c_qsfp_sda_o        : std_logic;
    signal i2c_qsfp_sda_oen      : std_logic;

    signal i2c_qsfp_be           : std_logic_vector(7 downto 0);
    signal i2c_qsfp_dwr          : std_logic_vector(63 downto 0);
    signal i2c_qsfp_drd          : std_logic_vector(63 downto 0);
    signal i2c_qsfp_wen          : std_logic;
    signal i2c_qsfp_sel          : std_logic;

    signal i2c_qsfp_be_fsm       : std_logic_vector(7 downto 0);
    signal i2c_qsfp_dwr_fsm      : std_logic_vector(63 downto 0);
    signal i2c_qsfp_wen_fsm      : std_logic;

    type fpc_fsm_st_t is (st_reset, st_enable, st_wr_dev, st_wr_dev_wait_tip,
        st_wr_dev_wait, st_wr_reg, st_wr_reg_wait_tip, st_wr_reg_wait, st_sleep,
        st_wr_data, st_wr_data_wait_tip, st_wr_data_wait, st_wr_disable, st_done);
    signal fpc_fsm_pst           : fpc_fsm_st_t;
    signal fpc_fsm_nst           : fpc_fsm_st_t;
    signal fpc_fsm_done          : std_logic;
    signal fpc_fsm_timer_en      : std_logic;
    signal fpc_conf_st           : std_logic_vector(2-1 downto 0);
    signal fpc_conf_st_reg       : std_logic_vector(2-1 downto 0);
    signal sleep_timer           : std_logic_vector(25-1 downto 0);
      
    signal trans_ctrl            : std_logic_vector(3*QSFP_PORTS-1 downto 0);
    signal qsfp_modsel_r         : std_logic_vector(QSFP_PORTS-1 downto 0) := (0 => '1', others => '1');
    signal qsfp_i2c_scl_i        : std_logic;
    signal qsfp_i2c_sda_i        : std_logic;
    signal qsfp_status           : std_logic_vector(6*QSFP_PORTS-1 downto 0); 
    
    signal qsfp_mi_sel_i         : natural;   
    
    signal qsfp_rdy              : std_logic_vector(1 downto 0);
    signal QSFP_RESET_N_sync     : std_logic_vector(1 downto 0);
    signal qsfp_cntr             : std_logic_vector(2*20-1 downto 0); -- QSFP powerup counters
  
begin
    
    qsfp_mi_sel_i <= conv_integer(MI_QSFP_SEL);
  
    gen_qsfp_status: for i in 0 to QSFP_PORTS-1 generate
        qsfp_status((i+1)*6-1 downto i*6) <= QSFP_INT_N(i) & QSFP_MODPRS_N(i) & trans_ctrl((i+1)*3-1 downto i*3) & '1';
    end generate;

    -- Read I2C controller registers + QSFP status registers
    mi_regs_rd_p : process(MI_CLK_PHY)
    begin
        if (rising_edge(MI_CLK_PHY)) then
            MI_DRDY_PHY <= '0';
            -- Read from I2C controller or from QSFP status reg
            if (MI_RD_PHY = '1') then 
                MI_DRDY_PHY <= '1';
                if (MI_ADDR_PHY(3 downto 2) = "00") then    -- I2C reg 0x00
                    MI_DRD_PHY  <= i2c_qsfp_drd(31 downto 0);
                elsif (MI_ADDR_PHY(3 downto 2) = "01") then -- I2C reg 0x04
                    MI_DRD_PHY <= i2c_qsfp_drd(63 downto 32);
                else
                    MI_DRD_PHY(5 downto 0) <= qsfp_status((qsfp_mi_sel_i+1)*6-1 downto qsfp_mi_sel_i*6);
                end if;
            end if;
        end if;
    end process mi_regs_rd_p;

   MI_ARDY_PHY <= (MI_RD_PHY or MI_WR_PHY) and fpc_fsm_done;
  
   -- ----------------------------------------------------------------------------
   -- QSFP I2C control and management
   -------------------------------------------------------------------------------
   --   NOTE: Single I2C controller is shared for all QSFP interfaces, MI_QSFP_SEL
   --   select which interface is targeted

   -- Write enable signals
   i2c_mi_wr  <= MI_WR_PHY when (MI_ADDR_PHY(4) = '1') else '0';

   -- Writing data to registers
   i2c_regs_wr_p : process(MI_CLK_PHY)
   begin
      if (rising_edge(MI_CLK_PHY)) then
         i2c_qsfp_wen <= '0';
         i2c_qsfp_sel <= MI_ADDR_PHY(8);
         if (i2c_mi_wr = '1') then
            if (MI_ADDR_PHY(3 downto 2) = "00") then    -- 0x10 - I2C control reg - low 32 bits
               i2c_qsfp_dwr(31 downto  0) <= MI_DWR_PHY;
               i2c_qsfp_be                <= "00001111";
               i2c_qsfp_wen               <= '1';
            elsif (MI_ADDR_PHY(3 downto 2) = "01") then -- 0x14 - I2C control reg - high 32 bits
               i2c_qsfp_dwr(63 downto 32) <= MI_DWR_PHY;
               i2c_qsfp_be                <= "11110000";
               i2c_qsfp_wen               <= '1';
            elsif (MI_ADDR_PHY(3 downto 2) = "11") then -- 0x1C - QSFP control reg
               trans_ctrl(qsfp_mi_sel_i*3+2 downto qsfp_mi_sel_i*3) <= MI_DWR_PHY(3 downto 1);
            end if;
            
            -- Turn on module select on targeted QSFP
            qsfp_modsel_r <= (others => '1');
            qsfp_modsel_r(qsfp_mi_sel_i) <= '0';
         end if;
         
         if RST = '1' then
             for i in 0 to QSFP_PORTS-1 loop
                 trans_ctrl(3*i+2 downto 3*i) <= "001";
             end loop;
         end if;
         
      end if;
   end process i2c_regs_wr_p;
   
         --
--   cdc_qsfprst: xpm_cdc_single
--   generic map (
--      DEST_SYNC_FF   => 2, -- integer; range: 2-10
--      SIM_ASSERT_CHK => 0, -- integer; 0=disable simulation messages, 1=enable simulation messages
--      SRC_INPUT_REG  => 0 -- integer; 0=do not register input, 1=register input
--      )
--      port map (
--         src_clk  => '0', -- optional; required when SRC_INPUT_REG = 1
--         src_in   => qsfp_reset_n(i),
--         dest_clk => SYSCLK,
--         dest_out => qsfp_reset_n_sync(i)
--      );
--      
--      -- Delay the startup of RX path of Eth PHY after the QSFP is reset
--      QSFP_POWERUP_TIMERS: process(SYSCLK)
--      begin
--         if SYSCLK'event and SYSCLK = '1' then
--            -- Wait 10 ms for the QSFP RX data   
--            if (qsfp_reset_n_sync(i) = '0') then
--               qsfp_cntr((i+1)*20-1 downto i*20) <= (others => '0');
--            elsif (qsfp_rdy(i) = '0') then
--               qsfp_cntr((i+1)*20-1 downto i*20) <= qsfp_cntr((i+1)*20-1 downto i*20) + 1; 
--             end if;
--             qsfp_rdy(i) <= qsfp_cntr((i+1)*20-1);
--         end if;
--      end process; 
--      
--   end generate; -- ports_gen

    -- On Intel Stratix 10 DX Dev Kit is FPC202 controller which by default
    -- keeps the QSFP cages turned off and must be configured first.
    fpc202_on_g: if FPC202_INIT_EN generate
        -- FPC202 INIT FSM STATE REGISTER
        fpc202_fsm_pst_p : process (MI_CLK_PHY)
        begin
            if (rising_edge(MI_CLK_PHY)) then
                if (MI_RESET_PHY = '1') then
                    fpc_fsm_pst     <= st_reset;
                    fpc_conf_st_reg <= (others => '0');
                else
                    fpc_fsm_pst     <= fpc_fsm_nst;
                    fpc_conf_st_reg <= fpc_conf_st;
                end if;
            end if;
        end process;

        -- FPC202 INIT FSM LOGIC
        fpc202_fsm_logic_p : process (all)
        begin
            fpc_fsm_nst      <= fpc_fsm_pst;
            fpc_conf_st      <= fpc_conf_st_reg;
            i2c_qsfp_be_fsm  <= (others => '0');
            i2c_qsfp_dwr_fsm <= (others => '0');
            i2c_qsfp_wen_fsm <= '0';
            fpc_fsm_done     <= '0';
            fpc_fsm_timer_en <= '0';

            case (fpc_fsm_pst) is
                when st_reset =>
                    fpc_fsm_nst <= st_enable;

                when st_enable =>
                    i2c_qsfp_be_fsm  <= "00001111";
                    i2c_qsfp_dwr_fsm <= X"00000000008000c7";
                    i2c_qsfp_wen_fsm <= '1';
                    fpc_fsm_nst      <= st_wr_dev;

                when st_wr_dev =>
                    i2c_qsfp_be_fsm  <= "11110000";
                    i2c_qsfp_dwr_fsm <= X"00001e9000000000";
                    i2c_qsfp_wen_fsm <= '1';
                    fpc_fsm_nst      <= st_wr_dev_wait_tip;

                when st_wr_dev_wait_tip =>
                    if (i2c_qsfp_drd(33) = '1') then
                        fpc_fsm_nst <= st_wr_dev_wait;
                    end if;

                when st_wr_dev_wait =>
                    if (i2c_qsfp_drd(33) = '0' and i2c_qsfp_drd(39) = '0') then
                        fpc_fsm_nst <= st_wr_reg;
                    end if;

                when st_wr_reg =>
                    if (fpc_conf_st_reg = "00") then
                        -- Enable Output register (FPC202 - 0x08)
                        i2c_qsfp_dwr_fsm <= X"0000081000000000";
                    else
                        -- QSFP Reset register (FPC202 - 0x0A)
                        i2c_qsfp_dwr_fsm <= X"00000A1000000000";
                    end if;
                    i2c_qsfp_be_fsm  <= "11110000";
                    i2c_qsfp_wen_fsm <= '1';
                    fpc_fsm_nst      <= st_wr_reg_wait_tip;

                when st_wr_reg_wait_tip =>
                    if (i2c_qsfp_drd(33) = '1') then
                        fpc_fsm_nst <= st_wr_reg_wait;
                    end if;

                when st_wr_reg_wait =>
                    if (i2c_qsfp_drd(33) = '0' and i2c_qsfp_drd(39) = '0') then
                        fpc_fsm_nst <= st_wr_data;
                    end if;

                when st_wr_data =>
                    if (fpc_conf_st_reg = "01") then
                        -- Enable QSFP reset
                        i2c_qsfp_dwr_fsm <= X"0000005000000000";
                    elsif (fpc_conf_st_reg = "10") then
                        -- Disable QSFP reset
                        i2c_qsfp_dwr_fsm <= X"00000F5000000000";
                    else
                        -- Set Enable Output register
                        i2c_qsfp_dwr_fsm <= X"0000FF5000000000";
                    end if;
                    i2c_qsfp_be_fsm  <= "11110000";
                    i2c_qsfp_wen_fsm <= '1';
                    fpc_fsm_nst      <= st_wr_data_wait_tip;

                when st_wr_data_wait_tip =>
                    if (i2c_qsfp_drd(33) = '1') then
                        fpc_fsm_nst <= st_wr_data_wait;
                    end if;

                when st_wr_data_wait =>
                    if (i2c_qsfp_drd(33) = '0' and i2c_qsfp_drd(39) = '0') then
                        fpc_conf_st <= fpc_conf_st_reg + 1;
                        fpc_fsm_nst <= st_sleep;
                    end if;

                when st_sleep =>
                    fpc_fsm_timer_en <= '1';
                    if (sleep_timer(24) = '1') then
                        if (fpc_conf_st_reg = "11") then
                            fpc_fsm_nst <= st_wr_disable;
                        else
                            fpc_fsm_nst <= st_wr_dev;
                        end if;
                    end if;

                when st_wr_disable =>
                    i2c_qsfp_be_fsm  <= "00001111";
                    i2c_qsfp_dwr_fsm <= X"00000000000000c7";
                    i2c_qsfp_wen_fsm <= '1';
                    fpc_fsm_nst      <= st_done;

                when st_done =>
                    i2c_qsfp_be_fsm  <= i2c_qsfp_be;
                    i2c_qsfp_dwr_fsm <= i2c_qsfp_dwr;
                    i2c_qsfp_wen_fsm <= i2c_qsfp_wen;
                    fpc_fsm_done     <= '1';
            end case;
        end process;

        process (MI_CLK_PHY)
        begin
            if (rising_edge(MI_CLK_PHY)) then
                if (fpc_fsm_timer_en = '0') then
                    sleep_timer <= (others => '0');
                else
                    sleep_timer <= sleep_timer + 1;
                end if;
            end if;
        end process;

    end generate;

    fpc202_off_g: if not FPC202_INIT_EN generate
        i2c_qsfp_be_fsm  <= i2c_qsfp_be;
        i2c_qsfp_dwr_fsm <= i2c_qsfp_dwr;
        i2c_qsfp_wen_fsm <= i2c_qsfp_wen;
        fpc_fsm_done     <= '1';
    end generate;

   -- QSFP28 I2C controller 
   i2c_qsfp_i : entity work.i2c_master_top
   generic map (
      PRER_INIT    => X"00C7"  -- 250MHz CLK ~ 100KHz SCL
   )
   port map (
      CLK          => MI_CLK_PHY,
      RST_SYNC     => '0',
      RST_ASYNC    => MI_RESET_PHY,
      -- I2C interfaces
      SCL_PAD_I    => qsfp_i2c_scl_i,
      SCL_PAD_O    => i2c_qsfp_scl_o,
      SCL_PADOEN_O => i2c_qsfp_scl_oen,
      SDA_PAD_I    => qsfp_i2c_sda_i,
      SDA_PAD_O    => i2c_qsfp_sda_o,
      SDA_PADOEN_O => i2c_qsfp_sda_oen,
      -- control interface
      BE           => i2c_qsfp_be_fsm,
      DWR          => i2c_qsfp_dwr_fsm,
      DRD          => i2c_qsfp_drd,
      WEN          => i2c_qsfp_wen_fsm,
      INT          => open
   );

    i2c_mux_g : if QSFP_I2C_PORTS = 1 generate
        qsfp_i2c_sda_i  <= QSFP_I2C_SDA(0);
        qsfp_i2c_scl_i  <= QSFP_I2C_SCL(0);
        QSFP_I2C_SCL(0) <= i2c_qsfp_scl_o when (i2c_qsfp_scl_oen = '0') else 'Z';
        QSFP_I2C_SDA(0) <= i2c_qsfp_sda_o when (i2c_qsfp_sda_oen = '0') else 'Z';
    else generate
        qsfp_i2c_omux_g : for i in 0 to QSFP_I2C_PORTS-1 generate
            QSFP_I2C_SCL(i) <= i2c_qsfp_scl_o when (i2c_qsfp_scl_oen = '0') and (qsfp_modsel_r(i) = '1') else 'Z';
            QSFP_I2C_SDA(i) <= i2c_qsfp_sda_o when (i2c_qsfp_sda_oen = '0') and (qsfp_modsel_r(i) = '1') else 'Z';
        end generate;
        qsfp_i2c_scl_mux_i: entity work.GEN_MUX_ONEHOT
        generic map (
            DATA_WIDTH  => 1,
            MUX_WIDTH   => QSFP_I2C_PORTS
        )
        port map (
            DATA_IN     => QSFP_I2C_SCL,
            SEL         => qsfp_modsel_r,
            DATA_OUT(0) => qsfp_i2c_scl_i
        );

        qsfp_i2c_sda_mux_i: entity work.GEN_MUX_ONEHOT
        generic map (
            DATA_WIDTH  => 1,
            MUX_WIDTH   => QSFP_I2C_PORTS
        )
        port map (
            DATA_IN     => QSFP_I2C_SDA,
            SEL         => qsfp_modsel_r,
            DATA_OUT(0) => qsfp_i2c_sda_i
        );
    end generate;
    
   ----------------------------------------------------------------------------
   -- Assign outputs 
   ----------------------------------------------------------------------------
   qsfp_outs_g: for i in 0 to QSFP_PORTS-1 generate
      -- Startup reset for QSFP cages (TX of ETH phy should be started before releasing QSFP reset) 
      QSFP_RESET_N(i) <= trans_ctrl(i*3+0) and TX_READY(i);
      QSFP_LPMODE(i)  <= trans_ctrl(i*3+1);
      QSFP_MODSEL_N(i) <= not qsfp_modsel_r(i);
   end generate;
   QSFP_I2C_DIR   <= (others => not i2c_qsfp_sda_oen); -- I2C bus direction: 0 = QSFP -> FPGA, 1 = FPGA -> QSFP
     
end architecture;
