--------------------------------------------------------------------------------
-- Title       : Permuted Congruential Generator (XSH-RR)
-- Project     : Default Project Name
--------------------------------------------------------------------------------
-- File        : pcg_xsh_rr_64.vhd
-- Author      : Ameer Shalabi <ameershalabi94@gmail.com>
-- Company     : -
-- Created     : Sat Feb 24 19:00:58 2024
-- Last update : Sun Mar 10 17:38:52 2024
-- Platform    : -
-- Standard    : VHDL-2008
--------------------------------------------------------------------------------
-- Description: A PCG of type : PCG-XSH-RR
-- It uses an XORshift function to mix the highest MSBs of the state while using 
-- the 5 MSBs to determine the rotate amount of bits 27 to 58
--------------------------------------------------------------------------------
-- Revisions:  
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity pcg_xsh_rr_64 is
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
    incr_i   : in std_logic_vector(63 downto 0);
    reseed_i : in std_logic;

    init_done_o     : out std_logic;
    pcg_xsh_rr_64_o : out std_logic_vector(31 downto 0)
  );

end entity pcg_xsh_rr_64;

architecture arch of pcg_xsh_rr_64 is

  signal clr_r    : std_logic;
  signal enb_r    : std_logic;
  signal init_r   : std_logic;
  signal reseed_r : std_logic;

  -- init signals
  signal seed_r   : std_logic_vector(63 downto 0);
  signal mult_r   : std_logic_vector(63 downto 0);
  signal incr_r   : std_logic_vector(63 downto 0);
  signal seeded_r : std_logic; --indicate if init state is seeded

  -- gen signals
  signal state_r       : unsigned(63 downto 0);
  signal gen_1_r       : std_logic;
  signal gen_2_r       : std_logic;
  signal state_mult_r  : unsigned(127 downto 0);
  signal right_shfts_r : integer range 0 to 31;
  signal left_shfts_r  : integer range 0 to 31;
  signal gen_stage_2_r : unsigned(63 downto 0);
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
      incr_r   <= (others => '0');
      seeded_r <= '0';

    elsif rising_edge(clk) then
      if (enb_r = '1') then

        if (init_r = '1') then
          seed_r   <= seed_i;
          mult_r   <= mult_i;
          incr_r   <= incr_i;
          seeded_r <= '1';
        else
          seeded_r <= '0';
        end if;

        if (clr_r = '1') then
          seed_r   <= (others => '0');
          mult_r   <= (others => '0');
          incr_r   <= (others => '0');
          seeded_r <= '0';

        end if; -- clr_r = '1'
      end if;   -- enb_r = '1'

    end if;
  end process init_proc;

  gen_proc : process (clk, rst)
    -- is always equal to the cirrent state
    variable stage_0_v : unsigned(63 downto 0);
    -- two right shifts are done on stage_0
    -- since the shifting is fixed to a constant 
    -- integerthe shifting logic is not needed. 
    -- instead, the unsinged bit vector is trancated.
    variable stage_0_18_l_shfts_v : unsigned(63 downto 0);
    variable stage_0_59_r_shfts_v : unsigned(4 downto 0);
    -- stage_1 is thge result of XOR op between stage_0
    -- and shifted stage_0 by 18
    variable stage_1_v : unsigned(63 downto 0);
    -- stage_2 will hold the result of shifting stage_1 27
    -- bits to the right
    variable stage_2_v       : unsigned(63 downto 0);
    variable stage_2_rot_r_v : unsigned(63 downto 0);
    variable stage_2_rot_l_v : unsigned(63 downto 0);

    variable right_shfts_2scomplement_v : std_logic_vector(5 downto 0);
    variable right_shfts_31_signed_v    : std_logic_vector(5 downto 0);
    -- stage_0_59_r_shfts will have only 5 bits with actual
    -- stored value after shifting, right/left shifts will 
    -- needs to only hold the value of those 5 bits
    variable left_shfts_v  : integer range 0 to 31;
    variable right_shfts_v : integer range 0 to 31;
    variable gen_word_v    : unsigned(63 downto 0);


    -- to hold the larger addition result of
    -- state before trancating
    variable state_add_v : unsigned(127 downto 0);


  begin
    if (rst = '0') then

      right_shfts_r <= 0;
      left_shfts_r  <= 0;
      gen_stage_2_r <= (others => '0');

      state_r <= (others => '0');
      gen_1_r <= '0';
      gen_2_r <= '0';

      gen_word_r <= (others => '0');

      state_mult_r <= (others => '0');
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
          -- trancate the state value instead of shifting
          stage_0_18_l_shfts_v := stage_0_v(63-18 downto 0)&"000000000000000000";
          --stage_0_18_l_shfts_v := (63 downto 64-18 => '0')&stage_0_v(63-18 downto 0);
          stage_0_59_r_shfts_v := stage_0_v(63 downto 59);
          -- stage_0_59_r_shfts will have only 5 bits with actual
          -- stored value after shifting, so right shift only needs to
          -- hold the value of those 5 bits
          right_shfts_v := to_integer(stage_0_59_r_shfts_v);
          -- perform the first xor operation
          stage_1_v := stage_0_v xor stage_0_18_l_shfts_v;
          -- trancate by 27 
          stage_2_v := "000000000000000000000000000"&stage_1_v(63 downto 27);
          -- create 2s complement of the right shifts. additiona bit is added to hold
          -- the resulting sign from converting to signed.   
          right_shfts_2scomplement_v := std_logic_vector(unsigned(not(std_logic_vector(to_signed(right_shfts_v,6))))+1);
          right_shfts_31_signed_v    := std_logic_vector(to_signed(31,6));
          -- 2s complement (with ommiting the sign bit) ANDed with 31 ("11111")
          left_shfts_v := to_integer(unsigned(right_shfts_2scomplement_v and right_shfts_31_signed_v));
          -- end gen_stage_1 by storing variables to registers
          state_mult_r  <= state_r * unsigned(mult_r);
          gen_stage_2_r <= stage_2_v;
          right_shfts_r <= right_shfts_v;
          left_shfts_r  <= left_shfts_v; --to_integer(unsigned(right_shfts_2scomplement_v(4 downto 0)));
          gen_1_r       <= '0';
          gen_2_r       <= '1';
        end if;

        -----------------------------------------------------------------------
        -- Gen Stage 2
        -----------------------------------------------------------------------
        if (gen_2_r = '1') then
          stage_2_rot_r_v := shift_right(gen_stage_2_r,right_shfts_r);
          stage_2_rot_l_v := shift_left(gen_stage_2_r,left_shfts_r);
          state_add_v     := state_mult_r + unsigned(incr_r);
          if (reseed_r = '1') then
            state_r <= unsigned(state_add_v(63 downto 0));
          end if;
          gen_word_v := stage_2_rot_r_v or stage_2_rot_l_v;
          gen_word_r <= gen_word_v(31 downto 0);
          gen_1_r    <= '1';
          gen_2_r    <= '0';
        end if;

        if (clr_r = '1') then

          right_shfts_r <= 0;
          left_shfts_r  <= 0;
          gen_stage_2_r <= (others => '0');

          state_r <= (others => '0');
          gen_1_r <= '0';
          gen_2_r <= '0';

          gen_word_r <= (others => '0');

          state_mult_r <= (others => '0');


        end if; -- clr_r = '1'
      end if;   -- enb_r = '1'
    end if;
  end process gen_proc;

  init_done_o     <= seeded_r;
  pcg_xsh_rr_64_o <= std_logic_vector(gen_word_r);


end architecture arch;