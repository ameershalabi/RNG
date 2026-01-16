library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

use work.casr_test_vectors_pkg.all;

entity casr_tb is
end casr_tb;

architecture rtl of casr_tb is

  signal tb_clk      : std_logic := '0';
  signal clk_period  : time      := 1 ns;
  signal tb_done     : std_logic := '0';
  signal tb_rst_n    : std_logic := '0';
  signal tb_rst_done : std_logic := '0';
  signal tb_clr      : std_logic := '0';
  signal tb_enb      : std_logic := '0';

  constant w_casr_30_c  : integer   := 64;
  constant w_casr_90_c  : integer   := 128;
  constant w_casr_150_c : integer   := 256;
  constant w_h90150_c   : integer   := 512;
  constant o_bit_c      : std_logic := '1';

  ----- CASR 30
  signal casr_30_seed_i  : std_logic_vector(w_casr_30_c-1 downto 0) := (others => '0');
  signal casr_30_init_i  : std_logic                                := '0';
  signal casr_30_gen_i   : std_logic                                := '0';
  signal casr_30_valid_o : std_logic;
  signal casr_30_state_o : std_logic_vector(w_casr_30_c-1 downto 0);

  ----- CASR 90
  signal casr_90_seed_i  : std_logic_vector(w_casr_90_c-1 downto 0) := (others => '0');
  signal casr_90_init_i  : std_logic                                := '0';
  signal casr_90_gen_i   : std_logic                                := '0';
  signal casr_90_valid_o : std_logic;
  signal casr_90_state_o : std_logic_vector(w_casr_90_c-1 downto 0);

  ----- CASR 150
  signal casr_150_seed_i  : std_logic_vector(w_casr_150_c-1 downto 0) := (others => '0');
  signal casr_150_init_i  : std_logic                                 := '0';
  signal casr_150_gen_i   : std_logic                                 := '0';
  signal casr_150_valid_o : std_logic;
  signal casr_150_state_o : std_logic_vector(w_casr_150_c-1 downto 0);

  ----- CASR 190150h
  signal h90150_seed_i  : std_logic_vector(w_h90150_c-1 downto 0) := (others => '0');
  signal h90150_rule_i  : std_logic_vector(w_h90150_c-1 downto 0) := (others => '0');
  signal h90150_init_i  : std_logic                               := '0';
  signal h90150_gen_i   : std_logic                               := '0';
  signal h90150_valid_o : std_logic;
  signal h90150_state_o : std_logic_vector(w_h90150_c-1 downto 0);

  -- test vectors
  signal casr_30_tst_vec  : std_logic_vector(w_casr_30_c-1 downto 0)  := (others => '0');
  signal casr_90_tst_vec  : std_logic_vector(w_casr_90_c-1 downto 0)  := (others => '0');
  signal casr_150_tst_vec : std_logic_vector(w_casr_150_c-1 downto 0) := (others => '0');
  signal h90150_tst_vec   : std_logic_vector(w_h90150_c-1 downto 0)   := (others => '0');

begin

  tb_clk <= not tb_clk after clk_period when tb_done /= '1' else '0';

  process begin
    tb_rst_n <= '0';
    wait for 2*clk_period; wait until rising_edge(tb_clk);
    tb_rst_n <= '1';
    wait until rising_edge(tb_clk);
    tb_clr <= '1';
    tb_enb <= '1';
    wait until rising_edge(tb_clk);
    tb_clr      <= '0';
    tb_rst_done <= '1';
    wait;
  end process;

  u_casr_30_p : entity work.casr_30
    Generic map(
      w_casr_g => w_casr_30_c,
      o_bit_g  => '0',
      o_mode_g => '1'
    )
    Port map (
      clk     => tb_clk,
      rst     => tb_rst_n,
      clr     => tb_clr,
      enb     => tb_enb,
      seed_i  => casr_30_seed_i,
      init_i  => casr_30_init_i,
      gen_i   => casr_30_gen_i,
      valid_o => casr_30_valid_o,
      state_o => casr_30_state_o
    );

  u_casr_90 : entity work.casr_90
    Generic map(
      w_casr_g => w_casr_90_c,
      o_bit_g  => '0',
      o_mode_g => '1'
    )
    Port map (
      clk     => tb_clk,
      rst     => tb_rst_n,
      clr     => tb_clr,
      enb     => tb_enb,
      seed_i  => casr_90_seed_i,
      init_i  => casr_90_init_i,
      gen_i   => casr_90_gen_i,
      valid_o => casr_90_valid_o,
      state_o => casr_90_state_o
    );

  u_casr_150 : entity work.casr_150
    Generic map(
      w_casr_g => w_casr_150_c,
      o_bit_g  => '0',
      o_mode_g => '1'
    )
    Port map (
      clk     => tb_clk,
      rst     => tb_rst_n,
      clr     => tb_clr,
      enb     => tb_enb,
      seed_i  => casr_150_seed_i,
      init_i  => casr_150_init_i,
      gen_i   => casr_150_gen_i,
      valid_o => casr_150_valid_o,
      state_o => casr_150_state_o
    );

  u_casr_90150h : entity work.casr_90150h
    Generic map(
      w_casr_g => w_h90150_c,
      o_bit_g  => '0',
      o_mode_g => '1',
      r_dyn_g  => '0'
    )
    Port map (
      clk     => tb_clk,
      rst     => tb_rst_n,
      clr     => tb_clr,
      enb     => tb_enb,
      seed_i  => h90150_seed_i,
      rule_i  => h90150_rule_i,
      init_i  => h90150_init_i,
      gen_i   => h90150_gen_i,
      valid_o => h90150_valid_o,
      state_o => h90150_state_o
    );

  process begin
    wait until tb_rst_done='1';
    wait for 2*clk_period;
    wait until rising_edge(tb_clk);

    -- get seeds
    casr_30_seed_i  <= casr30_seed1_c;
    casr_90_seed_i  <= casr90_seed1_c;
    casr_150_seed_i <= casr150_seed1_c;
    h90150_seed_i   <= casr90150h_seed1_c;
    h90150_rule_i   <= casr90150h_rule1_c;
    -- trigger init
    casr_30_init_i  <= '1';
    casr_90_init_i  <= '1';
    casr_150_init_i <= '1';
    h90150_init_i   <= '1';
    -- trigger gen
    casr_30_gen_i  <= '1';
    casr_90_gen_i  <= '1';
    casr_150_gen_i <= '1';
    h90150_gen_i   <= '1';
    wait until rising_edge(tb_clk);
    -- single clock init ends
    casr_30_init_i  <= '0';
    casr_90_init_i  <= '0';
    casr_150_init_i <= '0';
    h90150_init_i   <= '0';
    wait until rising_edge(tb_clk);
      casr_30_tst_vec  <= casr30_vectors(0);
      casr_90_tst_vec  <= casr90_vectors(0);
      casr_150_tst_vec <= casr150_vectors(0);
      h90150_tst_vec   <= casr90150h_vectors(0);
    out_check_loop : for o in 0 to 50 loop
      wait until rising_edge(tb_clk);
      if casr_30_valid_o = '1' then
        assert (casr_30_state_o = casr30_vectors(o)) report "casr_30_mismatch" severity error;
      end if;

      if casr_90_valid_o = '1' then
        assert (casr_90_state_o = casr90_vectors(o)) report "casr_90_mismatch" severity error;
      end if;

      if casr_150_valid_o = '1' then
        assert (casr_150_state_o = casr150_vectors(o)) report "casr_150_mismatch" severity error;
      end if;

      if h90150_valid_o = '1' then
        assert (h90150_state_o = casr90150h_vectors(o)) report "casr_h_mismatch" severity error;
      end if;
      casr_30_tst_vec  <= casr30_vectors(o+1);
      casr_90_tst_vec  <= casr90_vectors(o+1);
      casr_150_tst_vec <= casr150_vectors(o+1);
      h90150_tst_vec   <= casr90150h_vectors(o+1);
    end loop out_check_loop;
    casr_30_gen_i  <= '0';
    casr_90_gen_i  <= '0';
    casr_150_gen_i <= '0';
    h90150_gen_i   <= '0';
    wait for 10*clk_period;
    wait until rising_edge(tb_clk);

    wait;
  end process;



end architecture rtl;
