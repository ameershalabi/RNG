--------------------------------------------------------------------------------
-- Title       : Permuted Congruential Generator (XSL-RR)
-- Project     : hdl_rand
--------------------------------------------------------------------------------
-- File        : pcg_xsl_rr_128.vhd
-- Author      : Ameer Shalabi <ameershalabi94@gmail.com>
-- Company     : User Company Name
-- Created     : Mon Mar 10 13:43:15 2024
-- Last update : Mon Mar 11 16:06:42 2024
-- Platform    : -
-- Standard    : VHDL-2008
-------------------------------------------------------------------------------
-- Description: PCG-XSL-RR - 128b to 64b
-- It uses an XORshift function to mix the highest MSBs of the state while using 
-- the 6 MSBs to determine the rotate amount of bits 64 to 128
--------------------------------------------------------------------------------
-- Revisions: 
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity pcg_xsl_rr_128 is
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

    init_done_o      : out std_logic;
    pcg_xsl_rr_128_o : out std_logic_vector(63 downto 0)
  );

end entity pcg_xsl_rr_128;

architecture arch of pcg_xsl_rr_128 is

  signal clr_r    : std_logic;
  signal enb_r    : std_logic;
  signal init_r   : std_logic;
  signal reseed_r : std_logic;

  -- init signals
  signal seed_init_128_r : std_logic_vector(127 downto 0);
  signal seed_128_r      : std_logic_vector(127 downto 0);
  signal seed_128_0_r    : std_logic;
  signal seed_128_1_r    : std_logic;

  signal mult_r   : std_logic_vector(63 downto 0);
  signal incr_r   : std_logic_vector(63 downto 0);
  signal seeded_r : std_logic; --indicate if init state is seeded

  -- gen signals
  signal state_128_r       : unsigned(127 downto 0);
  signal gen_1_r           : std_logic;
  signal gen_2_r           : std_logic;
  signal state_128_mult_r  : unsigned(255 downto 0);
  signal right_128_shfts_r : integer range 0 to 63;
  signal left_128_shfts_r  : integer range 0 to 63;
  signal gen_128_stage_2_r : unsigned(127 downto 0);
  signal gen_128_word_r    : unsigned(63 downto 0);

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
      seed_init_128_r <= (others => '0');
      seed_128_r      <= (others => '0');
      mult_r          <= (others => '0');
      incr_r          <= (others => '0');
      seeded_r        <= '0';
      seed_128_0_r    <= '0';
      seed_128_1_r    <= '0';


    elsif rising_edge(clk) then
      if (enb_r = '1') then

        if (init_r = '1') then
          -- in no seed is present, init
          mult_r <= mult_i;
          incr_r <= incr_i;
          -- insert the seed in two clock cycles init
          if (seed_128_1_r = '0') then
            seed_init_128_r(63 downto 0) <= seed_i;
            seed_128_0_r                 <= '1';
            if (seed_128_0_r = '1') then
              seed_init_128_r(127 downto 64) <= seed_init_128_r(63 downto 0);
              seed_128_1_r                   <= '1';
              seed_128_0_r                   <= '0';
            end if;
          else
            seeded_r   <= '1';
            seed_128_r <= seed_init_128_r;
          end if;

        else
          seeded_r     <= '0';
          seed_128_1_r <= '0';
          seed_128_0_r <= '0';
        end if;

        if (clr_r = '1') then
          seed_init_128_r <= (others => '0');
          seed_128_r      <= (others => '0');
          mult_r          <= (others => '0');
          incr_r          <= (others => '0');
          seeded_r        <= '0';
          seed_128_0_r    <= '0';
          seed_128_1_r    <= '0';

        end if; -- clr_r = '1'
      end if;   -- enb_r = '1'

    end if;
  end process init_proc;

  gen_proc : process (clk, rst)
    -- is always equal to the cirrent state
    variable stage_128_0_v : unsigned(127 downto 0);
    -- two right shifts are done on stage_0
    -- since the shifting is fixed to a constant 
    -- integerthe shifting logic is not needed. 
    -- instead, the unsinged bit vector is trancated.
    variable stage_128_0_64_l_shfts_v  : unsigned(127 downto 0); -- 18 to 64
    variable stage_128_0_122_r_shfts_v : unsigned(5 downto 0);   -- 59 to 122

    -- stage_1 is thge result of XOR op between stage_0
    -- and shifted stage_0 by 18
    variable stage_128_1_v : unsigned(127 downto 0);

    -- stage 2 is rotating the results 
    variable stage_2_128_rot_r_v : unsigned(127 downto 0);
    variable stage_2_128_rot_l_v : unsigned(127 downto 0);

    -- 2's complement for rotating shifts
    variable right_128_shfts_2scomplement_v : std_logic_vector(6 downto 0);
    variable right_shfts_63_signed_v        : std_logic_vector(6 downto 0);
    -- stage_0_122_r_shfts will have only 6 bits with actual
    -- stored value after shifting, right/left shifts will 
    -- needs to only hold the value of those 5 bits
    variable left_128_shfts_v  : integer range 0 to 63;
    variable right_128_shfts_v : integer range 0 to 63;
    variable gen_128_word_v    : unsigned(127 downto 0);


    -- to hold the larger multiplication and addition result of
    -- state before trancating
    variable state_128_add_v : unsigned(255 downto 0);


  begin
    if (rst = '0') then

      right_128_shfts_r <= 0;
      left_128_shfts_r  <= 0;
      state_128_r       <= (others => '0');
      gen_1_r           <= '0';
      gen_2_r           <= '0';
      state_128_mult_r  <= (others => '0');
      gen_128_stage_2_r <= (others => '0');
      gen_128_word_r    <= (others => '0');


    elsif rising_edge(clk) then
      if (enb_r = '1') then
        if (seeded_r = '1') then
          state_128_r <= unsigned(seed_128_r) + unsigned(incr_r);
          gen_1_r     <= '1';
          gen_2_r     <= '0';
        end if;
        -----------------------------------------------------------------------
        -- Gen Stage 1
        -----------------------------------------------------------------------
        if (gen_1_r = '1' and seeded_r = '0') then
          -- get current state
          stage_128_0_v := state_128_r;
          -- trancate the state value instead of shifting
          stage_128_0_64_l_shfts_v  := stage_128_0_v(63 downto 0)&x"0000000000000000";
          stage_128_0_122_r_shfts_v := stage_128_0_v(127 downto 122);
          -- stored value after shifting, so right shift only needs to
          -- hold the value of those 6 bits
          right_128_shfts_v := to_integer(stage_128_0_122_r_shfts_v);
          -- perform the first xor operation
          stage_128_1_v := stage_128_0_v xor stage_128_0_64_l_shfts_v;
          -- create 2s complement of the right shifts and left shift of the rotating function
          -- additional bit is added to hold the resulting sign from converting to signed.   
          right_128_shfts_2scomplement_v := std_logic_vector(unsigned(not(std_logic_vector(to_signed(right_128_shfts_v,7))))+1);
          right_shfts_63_signed_v        := std_logic_vector(to_signed(63,7));
          -- 2s complement (with ommiting the sign bit) ANDed with 31 ("11111")
          left_128_shfts_v := to_integer(unsigned(right_128_shfts_2scomplement_v and right_shfts_63_signed_v));
          -- end gen_stage_1 by storing variables to registers
          state_128_mult_r  <= state_128_r * resize(unsigned(mult_r),128);
          gen_128_stage_2_r <= stage_128_1_v;
          right_128_shfts_r <= right_128_shfts_v;
          left_128_shfts_r  <= left_128_shfts_v;
          gen_1_r           <= '0';
          gen_2_r           <= '1';
        end if;

        -----------------------------------------------------------------------
        -- Gen Stage 2
        -----------------------------------------------------------------------
        if (gen_2_r = '1') then
          stage_2_128_rot_r_v := shift_right(gen_128_stage_2_r,right_128_shfts_r);
          stage_2_128_rot_l_v := shift_left(gen_128_stage_2_r,left_128_shfts_r);
          state_128_add_v     := state_128_mult_r+ unsigned(incr_r);
          if (reseed_r = '1') then
            state_128_r <= unsigned(state_128_add_v(127 downto 0));
          end if;
          gen_128_word_v := stage_2_128_rot_r_v or stage_2_128_rot_l_v;
          gen_128_word_r <= gen_128_word_v(63 downto 0);
          gen_1_r        <= '1';
          gen_2_r        <= '0';
        end if;
        if (clr_r = '1') then

          right_128_shfts_r <= 0;
          left_128_shfts_r  <= 0;
          state_128_r       <= (others => '0');

          gen_1_r           <= '0';
          gen_2_r           <= '0';
          state_128_mult_r  <= (others => '0');
          gen_128_stage_2_r <= (others => '0');
          gen_128_word_r    <= (others => '0');

        end if; -- clr_r = '1'
      end if;   -- enb_r = '1'
    end if;

  end process gen_proc;

  init_done_o      <= seeded_r;
  pcg_xsl_rr_128_o <= std_logic_vector(gen_128_word_r);


end architecture arch;