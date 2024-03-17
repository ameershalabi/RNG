--------------------------------------------------------------------------------
-- Title       : Permuted Congruential Generator (XSS-M-XS) 
-- Project     : hdl_rand
--------------------------------------------------------------------------------
-- File        : pcg_rxs_m_xs_32.vhd
-- Author      : Ameer Shalabi <ameershalabi94@gmail.com>
-- Company     : User Company Name
-- Created     : Mon Mar 11 21:42:53 2024
-- Last update : Wed Mar 13 15:07:04 2024
-- Platform    : -
-- Standard    : VHDL-2008
--------------------------------------------------------------------------------
-- Description: A PCG of type : PCG-XSS-M-XS - 32b to 16b
--------------------------------------------------------------------------------
-- Revisions:
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pcg_rxs_m_xs_32 is
  port (
    -- ctrl ports
    clk : in std_logic; -- clock pin
    rst : in std_logic; -- active low rest pin
    clr : in std_logic; -- clear pin
    enb : in std_logic; -- enable pin

    -- seed init ports
    init_i   : in std_logic;
    seed_i   : in std_logic_vector(31 downto 0);
    incr_i   : in std_logic_vector(31 downto 0);
    reseed_i : in std_logic;

    init_done_o       : out std_logic;
    pcg_rxs_m_xs_32_o : out std_logic_vector(15 downto 0)
  );

end entity pcg_rxs_m_xs_32;

architecture arch of pcg_rxs_m_xs_32 is
  -- constants
  constant shift_added_value_c : integer := 4;
  constant mult_factor_c       : integer := 1857494364;

  signal clr_r    : std_logic;
  signal enb_r    : std_logic;
  signal init_r   : std_logic;
  signal reseed_r : std_logic;

  -- init signals  
  signal seed_r   : std_logic_vector(31 downto 0);
  signal incr_r   : std_logic_vector(31 downto 0);
  signal seeded_r : std_logic; --indicate if init state is seeded

  -- gen signals
  signal state_r    : unsigned(31 downto 0);
  signal gen_1_r    : std_logic;
  signal gen_2_r    : std_logic;
  signal stage_1_r  : unsigned(31 downto 0);
  signal gen_word_r : unsigned(15 downto 0);

  -- debug
  -- is always equal to the cirrent state
  signal stage_0_v_r            : unsigned(31 downto 0);
  signal stage_1_r_shfts_v_r    : unsigned(3 downto 0);
  signal right_shfts_v_r        : integer range 0 to 31;
  signal stage_1_shifted_v_r    : unsigned(31 downto 0);
  signal stage_1_v_r            : unsigned(31 downto 0);
  signal stage_2_mult_v_r       : unsigned(63 downto 0);
  signal stage_2_22_r_shfts_v_r : unsigned(63 downto 0);
  signal gen_word_v_r           : unsigned(63 downto 0);

begin

  ctrl_proc : process (clk, rst)
  begin
    if (rst = '0') then
      clr_r    <= '0';
      enb_r    <= '0';
      init_r   <= '0';
      reseed_r <= '0';
    elsif rising_edge(clk) then
      clr_r    <= clr;
      enb_r    <= enb;
      init_r   <= init_i;
      reseed_r <= reseed_i;
    end if;
  end process ctrl_proc;

  init_proc : process (clk, rst)
  begin
    if (rst = '0') then
      seed_r   <= (others => '0');
      incr_r   <= (others => '0');
      seeded_r <= '0';

    elsif rising_edge(clk) then
      if (enb_r = '1') then
        if (init_r = '1') then
          seed_r   <= seed_i;
          incr_r   <= incr_i;
          seeded_r <= '1';
        else
          seeded_r <= '0';
        end if;

        if (clr_r = '1') then
          seed_r   <= (others => '0');
          incr_r   <= (others => '0');
          seeded_r <= '0';

        end if; -- clr_r = '1'
      end if;   -- enb_r = '1'

    end if;
  end process init_proc;

  gen_proc : process (clk, rst)
    -- is always equal to the cirrent state
    variable stage_0_v : unsigned(31 downto 0);
    -- hold the added value to the right shifting
    variable stage_1_r_shfts_v : unsigned(3 downto 0);
    -- the number of right shifts
    variable right_shfts_v : integer range 0 to 31;
    -- hold the right shifted state
    variable stage_1_shifted_v : unsigned(31 downto 0);
    -- state value after shifting
    variable stage_1_v : unsigned(31 downto 0);
    -- hold multiplication result
    variable stage_2_mult_v : unsigned(63 downto 0);
    -- hold the shifted value post multiplication
    variable stage_2_22_r_shfts_v : unsigned(63 downto 0);
    -- hold the generated value
    variable gen_word_v : unsigned(63 downto 0);


  begin
    if (rst = '0') then

      state_r    <= (others => '0');
      gen_1_r    <= '0';
      gen_2_r    <= '0';
      stage_1_r  <= (others => '0');
      gen_word_r <= (others => '0');
    elsif rising_edge(clk) then
      if (enb_r = '1') then
        if (seeded_r = '1') then
          state_r <= unsigned(seed_r) + unsigned(incr_r);
          gen_1_r <= '1';
          gen_2_r <= '0';
        end if;
        -----------------------------------------------------------------------
        -- Gen Stage 1
        -----------------------------------------------------------------------
        if (gen_1_r = '1' and seeded_r = '0') then
          -- get current state
          stage_0_v := state_r;
          -- get the 4 MSBs for shifting value
          stage_1_r_shfts_v := state_r(31 downto 28);
          -- add 4 to the shifting value
          right_shfts_v := to_integer(stage_1_r_shfts_v) + shift_added_value_c;
          -- shift state to the right using the right shifts
          stage_1_shifted_v := shift_right(stage_0_v,right_shfts_v);
          -- xor in initial state with the shifted value of the state
          stage_1_v := stage_0_v xor stage_1_shifted_v;
          stage_1_r <= stage_1_v;
          gen_1_r   <= '0';
          gen_2_r   <= '1';
        end if;

        -----------------------------------------------------------------------
        -- Gen Stage 2
        -----------------------------------------------------------------------
        if (gen_2_r = '1') then
          -- perform multiplication
          stage_2_mult_v       := stage_1_r * to_unsigned(mult_factor_c,32);
          stage_2_22_r_shfts_v := "0000000000000000000000"&stage_2_mult_v(63 downto 22);
          gen_word_v           := stage_2_mult_v xor stage_2_22_r_shfts_v;
          if (reseed_r = '1') then
            state_r <= stage_2_22_r_shfts_v(31 downto 0);
          end if;
          gen_word_r <= gen_word_v(63-shift_added_value_c downto 48-shift_added_value_c);
          gen_1_r    <= '1';
          gen_2_r    <= '0';
        end if;

        if (clr_r = '1') then

          state_r <= (others => '0');
          gen_1_r <= '0';
          gen_2_r <= '0';

          stage_1_r  <= (others => '0');
          gen_word_r <= (others => '0');
        end if; -- clr_r = '1'
      end if;   -- enb_r = '1'
    end if;
    stage_0_v_r <= stage_0_v;
    stage_1_r_shfts_v_r    <= stage_1_r_shfts_v;
    right_shfts_v_r        <= right_shfts_v;
    stage_1_shifted_v_r    <= stage_1_shifted_v;
    stage_1_v_r            <= stage_1_v;
    stage_2_mult_v_r       <= stage_2_mult_v;
    stage_2_22_r_shfts_v_r <= stage_2_22_r_shfts_v;
    gen_word_v_r           <= gen_word_v;
  end process gen_proc;

  init_done_o       <= seeded_r;
  pcg_rxs_m_xs_32_o <= std_logic_vector(gen_word_r);

end architecture arch;

