--------------------------------------------------------------------------------
-- Title       : Permuted Congruential Generator (XSH-RS)
-- Project     : hdl_rand
--------------------------------------------------------------------------------
-- File        : pcg_xsh_rs_64.vhd
-- Author      : Ameer Shalabi <ameershalabi94@gmail.com>
-- Company     : 
-- Created     : Sun Mar 17 09:20:44 2024
-- Last update : Sun Mar 17 10:40:43 2024
-- Platform    : -
-- Standard    : VHDL-2008
--------------------------------------------------------------------------------
-- Description: A PCG of type : PCG-XSH-RS - 64b to 32b
--------------------------------------------------------------------------------
-- Revisions: 
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity pcg_xsh_rs_64 is
  port (
    -- ctrl ports
    clk : in std_logic; -- clock pin
    rst : in std_logic; -- active low rest pin
    clr : in std_logic; -- clear pin
    enb : in std_logic; -- enable pin

    -- seed init ports
    init_i   : in std_logic;
    seed_i   : in std_logic_vector(63 downto 0);
    mult_i   : in std_logic_vector(63 downto 0);
    reseed_i : in std_logic;

    init_done_o     : out std_logic;
    pcg_xsh_rs_64_o : out std_logic_vector(31 downto 0)
  );

end entity pcg_xsh_rs_64;

architecture arch of pcg_xsh_rs_64 is

  signal clr_r    : std_logic;
  signal enb_r    : std_logic;
  signal init_r   : std_logic;
  signal reseed_r : std_logic;

  -- init signals
  signal seed_r   : std_logic_vector(63 downto 0);
  signal mult_r   : std_logic_vector(63 downto 0);
  signal seeded_r : std_logic; --indicate if init state is seeded

  -- gen signals
  signal state_r       : unsigned(63 downto 0);
  signal gen_r       : std_logic;
  signal gen_word_r    : unsigned(31 downto 0);

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
      mult_r   <= (others => '0');
      seeded_r <= '0';

    elsif rising_edge(clk) then
      if (enb_r = '1') then

        if (init_r = '1') then
          seed_r   <= seed_i;
          mult_r   <= mult_i;
          seeded_r <= '1';
        else
          seeded_r <= '0';
        end if;

        if (clr_r = '1') then
          seed_r   <= (others => '0');
          mult_r   <= (others => '0');
          seeded_r <= '0';

        end if; -- clr_r = '1'
      end if;   -- enb_r = '1'

    end if;
  end process init_proc;

  gen_proc : process (clk, rst)

    variable seed_v : unsigned(127 downto 0);
    -- is always equal to the cirrent state
    variable stage_0_v : unsigned(63 downto 0);
    -- two right shifts are done on stage_0
    -- since the shifting is fixed to a constant 
    -- integer the shifting logic is not needed. 
    -- instead, the unsinged bit vector is trancated.
    variable stage_0_22_r_shfts_v : unsigned(63 downto 0);
    variable stage_0_61_r_shfts_v : unsigned(2 downto 0);
    -- stage_1 is thge result of XOR op between stage_0
    -- and shifted stage_0 by 22
    variable stage_1_v : unsigned(63 downto 0);
    variable right_shfts_v : integer range 0 to 31;

    variable gen_word_v : unsigned(63 downto 0);

    variable state_mult_v : unsigned(127 downto 0);

  begin
    if (rst = '0') then

      state_r <= (others => '0');
      gen_r <= '0';

      gen_word_r <= (others => '0');

    elsif rising_edge(clk) then
      if (enb_r = '1') then
        if (seeded_r = '1') then
          seed_v  := (2 * unsigned(seed_r)) + 1;
          state_r <= seed_v(63 downto 0);
          gen_r <= '1';
        end if;
        -----------------------------------------------------------------------
        -- Gen Stage 1
        -----------------------------------------------------------------------
        if (gen_r = '1' and seeded_r = '0') then
          -- get current state
          stage_0_v    := state_r;
          state_mult_v := state_r * unsigned(mult_r);
          -- trancate the state value instead of shifting
          stage_0_22_r_shfts_v := stage_0_v(63-22 downto 0)&"0000000000000000000000";
          stage_0_61_r_shfts_v := stage_0_v(63 downto 61); -- to 61

          right_shfts_v := to_integer(stage_0_61_r_shfts_v) + 22;
          -- perform the first xor operation
          stage_1_v := stage_0_v xor stage_0_22_r_shfts_v;
          -- end gen_stage_1 by storing variables to registers
          gen_word_v := shift_right(stage_1_v,right_shfts_v);
          if (reseed_r = '1') then
            state_r <= unsigned(state_mult_v(63 downto 0));
          end if;
          gen_word_r <= gen_word_v(31 downto 0);
        end if;

        if (clr_r = '1') then
          state_r <= (others => '0');
          gen_r <= '0';

          gen_word_r <= (others => '0');


        end if; -- clr_r = '1'
      end if;   -- enb_r = '1'
    end if;
  end process gen_proc;

  init_done_o     <= seeded_r;
  pcg_xsh_rs_64_o <= std_logic_vector(gen_word_r);


end architecture arch;