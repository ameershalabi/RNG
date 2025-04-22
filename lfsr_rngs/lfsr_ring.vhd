--------------------------------------------------------------------------------
-- Title       : A ring of LFSRs for randmon number generation
-- Project     : hdl_rand
--------------------------------------------------------------------------------
-- File        : lfsr_ring.vhd
-- Author      : Ameer Shalabi <ameershalabi94@gmail.com>
-- Company     : -
-- Created     : Fri Mar 15 21:55:02 2024
-- Last update : Sun Apr 13 13:51:02 2025
-- Platform    : -
-- Standard    : VHDL-2008
--------------------------------------------------------------------------------
-- Description: 
--------------------------------------------------------------------------------
-- Revisions: 
-------------------------------------------------------------------------------


library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library rng;

entity lfsr_ring is
  generic(
    w_LFSR_g : natural := 32
  );
  port (
    clk : in std_logic; -- clock pin
    rst : in std_logic; -- active low rest pin
    clr : in std_logic; -- clear pin
    enb : in std_logic; -- enable pin

    -- initial loading of selector LFSR
    init_data_i : in std_logic_vector(w_LFSR_g-1 downto 0);
    init_i      : in std_logic;

    output_rand_o : out std_logic_vector(w_LFSR_g-1 downto 0);
    init_done_o   : out std_logic

  );

end entity lfsr_ring;

architecture arch of lfsr_ring is

  constant w_LFSR_c : integer := w_LFSR_g;

  -- ctrl signals
  signal enb_r : std_logic;
  signal clr_r : std_logic;

  -- input registers
  signal init_data_r : std_logic_vector(w_LFSR_c-1 downto 0);
  signal init_r      : std_logic;

  -- init registers
  type LFSR_data_arr_t is array(0 to 3) of std_logic_vector(w_LFSR_c-1 downto 0);
  signal LFSR_RAND_in_arr  : LFSR_data_arr_t;
  signal LFSR_RAND_out_arr : LFSR_data_arr_t;
  signal LFSR_ring_arr     : LFSR_data_arr_t;

  signal init_done_r : std_logic;
  signal enb_gen_r   : std_logic;
  signal init_load   : std_logic;

  signal ring_indic_r : std_logic_vector(3 downto 0);

  signal output_vector   : std_logic_vector(w_LFSR_c-1 downto 0);
  signal output_rand_o_r : std_logic_vector(w_LFSR_c-1 downto 0);

  signal gen_indicator : std_logic_vector(3 downto 0);
  signal gen_en        : std_logic_vector(3 downto 0);

begin

  ----------------------------------------------------------------------------
  -- Stage 0 : register all input data into registers
  ----------------------------------------------------------------------------

  -- capture inputs into registers
  input_reg_proc : process (clk, rst)
  begin
    if (rst = '0') then
      init_data_r     <= (others => '0');
      output_rand_o_r <= (others => '0');
      init_r          <= '0';
      enb_r           <= '0';
      clr_r           <= '0';
    elsif rising_edge(clk) then
      enb_r <= enb;
      clr_r <= clr;
      if (enb_r = '1') then
        init_data_r <= init_data_i;
        init_r      <= init_i;

        output_rand_o_r <= output_vector;

        if (clr_r = '1') then
          init_data_r     <= (others => '0');
          init_r          <= '0';
          output_rand_o_r <= (others => '0');
        end if;
      end if;
    end if;
  end process input_reg_proc;

  ----------------------------------------------------------------------------
  -- Stage 1 : initialise the LFSRs
  ----------------------------------------------------------------------------

  LFSR_RAND_in_proc : process (clk, rst)
  begin
    if (rst = '0') then -- reset block

      LFSR_RAND_in_arr <= (others => (others => '0'));
      init_done_r      <= '0';
      enb_gen_r        <= '0';

    elsif rising_edge(clk) then
      if (enb_r = '1') then    -- active when block is enabled
        if (init_r = '1') then -- the block is in init stage

          LFSR_RAND_in_arr(0)                         <= init_data_r;
          LFSR_RAND_in_arr(1)                         <= not init_data_r;
          LFSR_RAND_in_arr(2)                         <= not init_data_r;
          LFSR_RAND_in_arr(2)(w_LFSR_c/2 -1 downto 0) <= init_data_r(w_LFSR_c/2 -1 downto 0);
          LFSR_RAND_in_arr(3)                         <= init_data_r;
          LFSR_RAND_in_arr(3)(w_LFSR_c/2 -1 downto 0) <= not init_data_r(w_LFSR_c/2 -1 downto 0);
          init_done_r                                 <= '1';
          enb_gen_r                                   <= '0';

        else

          if init_load = '1' then
            init_done_r <= '0';
            enb_gen_r   <= '1';
          end if;
        end if;

        if (clr_r = '1' ) then -- clear block

          LFSR_RAND_in_arr <= (others => (others => '0'));
          init_done_r      <= '0';
          enb_gen_r        <= '0';

        end if;
      end if;
    end if;
  end process LFSR_RAND_in_proc;

  -- generate the enable for the selector LFSR
  enable_proc : process (init_done_r, enb_gen_r, gen_indicator, enb_r)
  begin
    init_load <= '0';
    -- when block is enabled
    gen_en <= (others => '0');
    if enb_r = '1' then
      if init_done_r = '1' then
        init_load <= '1';
      end if;
      if enb_gen_r = '1' then
        gen_en <= gen_indicator;
      end if;
    end if;
  end process enable_proc;

  RAND_LFSRs_gen : for rand_lfsr in 0 to 3 generate
    i_LFSR_RAND : entity rng.LFSR_generic
      generic map (
        LFSR_len => w_LFSR_c
      )
      port map (
        clk       => clk,
        rst       => rst,
        load      => init_load,
        load_data => LFSR_RAND_in_arr(rand_lfsr),
        gen_e     => gen_en(rand_lfsr),
        LFSR_out  => LFSR_RAND_out_arr(rand_lfsr)
      );
  end generate RAND_LFSRs_gen;


  lfsr_ring_proc : process (clk, rst)
  begin
    if (rst = '0') then
      LFSR_ring_arr <= (others => (others => '0'));
      ring_indic_r  <= x"8";
    elsif rising_edge(clk) then
      if (enb_r = '1') then -- active when block is enabled

        if init_load = '1' then
          LFSR_ring_arr <= LFSR_RAND_in_arr;
        end if;

        if enb_gen_r = '1' then
          --for ring_idx in 0 to 3 loop
          if ring_indic_r = x"8" then
            LFSR_ring_arr(3) <= LFSR_RAND_out_arr(3);
            ring_indic_r     <= x"4";

          elsif ring_indic_r = x"4" then
            LFSR_ring_arr(3) <= LFSR_RAND_out_arr(2);
            ring_indic_r     <= x"2";

          elsif ring_indic_r = x"2" then
            LFSR_ring_arr(3) <= LFSR_RAND_out_arr(1);
            ring_indic_r     <= x"1";

          elsif ring_indic_r = x"1" then
            LFSR_ring_arr(3) <= LFSR_RAND_out_arr(0);
            ring_indic_r     <= x"8";
          end if ;
          LFSR_ring_arr(2) <= LFSR_ring_arr(3);
          LFSR_ring_arr(1) <= LFSR_ring_arr(2);
          LFSR_ring_arr(0) <= LFSR_ring_arr(1);
        end if;
        if (clr_r = '1' ) then -- clear block
          LFSR_ring_arr <= (others => (others => '0'));
          ring_indic_r  <= x"8";

        end if;

      end if;
    end if;
  end process lfsr_ring_proc;

  -- generate the enable for the selector LFSR
  out_gen_proc : process (LFSR_ring_arr)
    variable lfsr_0 : std_logic_vector(w_LFSR_c-1 downto 0);
    variable lfsr_1 : std_logic_vector(w_LFSR_c-1 downto 0);
    variable lfsr_2 : std_logic_vector(w_LFSR_c-1 downto 0);
    variable lfsr_3 : std_logic_vector(w_LFSR_c-1 downto 0);

    variable cxord : std_logic;

    variable indic_0    : std_logic_vector(3 downto 0);
    variable indic_1    : std_logic_vector(3 downto 0);
    variable nand_check : std_logic_vector(3 downto 0);

  begin
    lfsr_0 := LFSR_ring_arr(0);
    lfsr_1 := LFSR_ring_arr(1);
    lfsr_2 := LFSR_ring_arr(2);
    lfsr_3 := LFSR_ring_arr(3);
    gen_output : for lfsr_bit in 0 to w_LFSR_c-1 loop
      cxord                   := lfsr_2(w_LFSR_c-1-lfsr_bit) xor lfsr_3(lfsr_bit);
      output_vector(lfsr_bit) <= lfsr_3(lfsr_bit);
      if cxord = '1' then
        output_vector(lfsr_bit) <= lfsr_0(lfsr_bit) xor not (lfsr_1(lfsr_bit) or lfsr_2(lfsr_bit));
      else
        output_vector(lfsr_bit) <= lfsr_2(lfsr_bit) xor not (lfsr_1(lfsr_bit) or lfsr_3(lfsr_bit));
      end if;

      indic_0 := lfsr_0(w_LFSR_c-1-lfsr_bit)
        & lfsr_1(w_LFSR_c-1-lfsr_bit)
        & lfsr_2(w_LFSR_c-1-lfsr_bit)
        & lfsr_3(w_LFSR_c-1-lfsr_bit);

      indic_1 := lfsr_0(lfsr_bit)
        & lfsr_1(lfsr_bit)
        & lfsr_2(lfsr_bit)
        & lfsr_3(lfsr_bit);

    end loop gen_output;
    nand_check := indic_1 nand indic_0;
    if nand_check = x"0" then
      gen_indicator <= not indic_1 nand indic_0;
    else
      gen_indicator <= indic_1 nand indic_0;
    end if;
  end process out_gen_proc;

  init_done_o   <= init_done_r;
  output_rand_o <= output_rand_o_r;
end arch;