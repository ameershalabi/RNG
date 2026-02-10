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

  --process begin
  --  tb_rst_n <= '0';
  --  wait for 2*clk_period; wait until rising_edge(tb_clk);
  --  tb_rst_n <= '1';
  --  wait until rising_edge(tb_clk);
  --  tb_clr <= '1';
  --  tb_enb <= '1';
  --  wait until rising_edge(tb_clk);
  --  tb_clr      <= '0';
  --  tb_rst_done <= '1';
  --  wait;
  --end process;

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

  process

    variable casr_30_counter_v  : integer := 1;
    variable casr_90_counter_v  : integer := 1;
    variable casr_150_counter_v : integer := 1;
    variable casr_h_counter_v   : integer := 1;

  begin

    --------------------------------------------------------------------------------
    -- FIRST RESET IS DONE - START MAIN TEST - NORMAL OPERATION
    --------------------------------------------------------------------------------

    tb_rst_n <= '0';
    wait for 2*clk_period; wait until rising_edge(tb_clk);
    tb_rst_n <= '1';
    wait until rising_edge(tb_clk);
    tb_clr <= '1';
    tb_enb <= '1';
    wait until rising_edge(tb_clk);
    tb_clr      <= '0';
    tb_rst_done <= '1';

    wait for 2*clk_period;
    wait until rising_edge(tb_clk);

    -- get seeds
    casr_30_seed_i  <= casr30_seed1_c;
    casr_90_seed_i  <= casr90_seed1_c;
    casr_150_seed_i <= casr150_seed1_c;
    h90150_seed_i   <= casr90150h_seed1_c;
    h90150_rule_i   <= casr90150h_rule1_c;
    -- trigger init
    casr_30_init_i  <= '1'; casr_30_gen_i <= '1';
    casr_90_init_i  <= '1'; casr_90_gen_i <= '1';
    casr_150_init_i <= '1'; casr_150_gen_i <= '1';
    h90150_init_i   <= '1'; h90150_gen_i <= '1';
    -- trigger gen
    wait until rising_edge(tb_clk);
    -- single clock init ends
    casr_30_init_i  <= '0';
    casr_90_init_i  <= '0';
    casr_150_init_i <= '0';
    h90150_init_i   <= '0';
    wait until rising_edge(tb_clk);
    casr_30_counter_v  := 1;
    casr_90_counter_v  := 1;
    casr_150_counter_v := 1;
    casr_h_counter_v   := 1;
    casr_30_tst_vec    <= casr30_vectors(0);
    casr_90_tst_vec    <= casr90_vectors(0);
    casr_150_tst_vec   <= casr150_vectors(0);
    h90150_tst_vec     <= casr90150h_vectors(0);
    main_test_loop : for o in 0 to 25 loop
      wait until rising_edge(tb_clk);
      if casr_30_valid_o = '1' then
        assert (casr_30_state_o = casr_30_tst_vec) report "main test casr_30_mismatch" severity error;
        casr_30_tst_vec   <= casr30_vectors(casr_30_counter_v);
        casr_30_counter_v := casr_30_counter_v + 1;
      end if;

      if casr_90_valid_o = '1' then
        assert (casr_90_state_o = casr_90_tst_vec) report "main test casr_90_mismatch" severity error;
        casr_90_tst_vec   <= casr90_vectors(casr_90_counter_v);
        casr_90_counter_v := casr_90_counter_v + 1;
      end if;

      if casr_150_valid_o = '1' then
        assert (casr_150_state_o = casr_150_tst_vec) report "main test casr_150_mismatch" severity error;
        casr_150_tst_vec   <= casr150_vectors(casr_150_counter_v);
        casr_150_counter_v := casr_150_counter_v + 1;
      end if;

      if h90150_valid_o = '1' then
        assert (h90150_state_o = h90150_tst_vec) report "main test casr_h_mismatch" severity error;
        h90150_tst_vec   <= casr90150h_vectors(casr_h_counter_v);
        casr_h_counter_v := casr_h_counter_v + 1;
      end if;
    end loop main_test_loop;
    casr_30_gen_i  <= '0';
    casr_90_gen_i  <= '0';
    casr_150_gen_i <= '0';
    h90150_gen_i   <= '0';
    wait for 10*clk_period;
    wait until rising_edge(tb_clk);

    --------------------------------------------------------------------------------
    -- MAIN TEST IS DONE - START CLEAR TEST - CLEAR MID OPERATION + RELOAD SEED
    --------------------------------------------------------------------------------

    --INITAIL CLEAR BLOCK FOR NEW TEST
    wait for 2*clk_period;
    wait until rising_edge(tb_clk);
    tb_clr <= '1';
    wait until rising_edge(tb_clk);
    tb_clr <= '0';
    wait until rising_edge(tb_clk);
    -- END - INITAIL CLEAR BLOCK FOR NEW TEST
    -- get seeds
    casr_30_seed_i  <= casr30_seed1_c;
    casr_90_seed_i  <= casr90_seed1_c;
    casr_150_seed_i <= casr150_seed1_c;
    h90150_seed_i   <= casr90150h_seed1_c;
    h90150_rule_i   <= casr90150h_rule1_c;
    -- trigger init
    casr_30_init_i  <= '1'; casr_30_gen_i <= '1';
    casr_90_init_i  <= '1'; casr_90_gen_i <= '1';
    casr_150_init_i <= '1'; casr_150_gen_i <= '1';
    h90150_init_i   <= '1'; h90150_gen_i <= '1';
    -- trigger gen
    wait until rising_edge(tb_clk);
    -- single clock init ends
    casr_30_init_i  <= '0';
    casr_90_init_i  <= '0';
    casr_150_init_i <= '0';
    h90150_init_i   <= '0';
    wait until rising_edge(tb_clk);
    casr_30_counter_v  := 1;
    casr_90_counter_v  := 1;
    casr_150_counter_v := 1;
    casr_h_counter_v   := 1;
    casr_30_tst_vec    <= casr30_vectors(0);
    casr_90_tst_vec    <= casr90_vectors(0);
    casr_150_tst_vec   <= casr150_vectors(0);
    h90150_tst_vec     <= casr90150h_vectors(0);
    second_test_clear_loop : for o in 0 to 25 loop
      tb_clr <= '0'; -- keep clear low
      if (o = 15) then
        tb_clr <= '1'; -- after 15 valid output, clear block
      end if;
      wait until rising_edge(tb_clk);
      if casr_30_valid_o = '1' then
        assert (casr_30_state_o = casr_30_tst_vec) report "clear test casr_30_mismatch" severity error;
        casr_30_tst_vec   <= casr30_vectors(casr_30_counter_v);
        casr_30_counter_v := casr_30_counter_v + 1;
      end if;

      if casr_90_valid_o = '1' then
        assert (casr_90_state_o = casr_90_tst_vec) report "clear test casr_90_mismatch" severity error;
        casr_90_tst_vec   <= casr90_vectors(casr_90_counter_v);
        casr_90_counter_v := casr_90_counter_v + 1;
      end if;

      if casr_150_valid_o = '1' then
        assert (casr_150_state_o = casr_150_tst_vec) report "clear test casr_150_mismatch" severity error;
        casr_150_tst_vec   <= casr150_vectors(casr_150_counter_v);
        casr_150_counter_v := casr_150_counter_v + 1;
      end if;

      if h90150_valid_o = '1' then
        assert (h90150_state_o = h90150_tst_vec) report "clear test casr_h_mismatch" severity error;
        h90150_tst_vec   <= casr90150h_vectors(casr_h_counter_v);
        casr_h_counter_v := casr_h_counter_v + 1;
      end if;

    end loop second_test_clear_loop;
    wait until rising_edge(tb_clk);
    casr_30_gen_i  <= '0';
    casr_90_gen_i  <= '0';
    casr_150_gen_i <= '0';
    h90150_gen_i   <= '0';
    wait until rising_edge(tb_clk);
    -- trigger init
    casr_30_init_i  <= '1';
    casr_90_init_i  <= '1';
    casr_150_init_i <= '1';
    h90150_init_i   <= '1';
    -- trigger gen
    wait until rising_edge(tb_clk);
    -- single clock init ends
    casr_30_init_i  <= '0';
    casr_90_init_i  <= '0';
    casr_150_init_i <= '0';
    h90150_init_i   <= '0';
    wait for 4*clk_period;
    wait until rising_edge(tb_clk);
    casr_30_gen_i  <= '1';
    casr_90_gen_i  <= '1';
    casr_150_gen_i <= '1';
    h90150_gen_i   <= '1';
    wait until rising_edge(tb_clk);
    casr_30_counter_v  := 1;
    casr_90_counter_v  := 1;
    casr_150_counter_v := 1;
    casr_h_counter_v   := 1;
    casr_30_tst_vec    <= casr30_vectors(0);
    casr_90_tst_vec    <= casr90_vectors(0);
    casr_150_tst_vec   <= casr150_vectors(0);
    h90150_tst_vec     <= casr90150h_vectors(0);
    second_reinit_test_loop : for o in 0 to 25 loop

      wait until rising_edge(tb_clk);
      if casr_30_valid_o = '1' then
        assert (casr_30_state_o = casr_30_tst_vec) report "reinit test casr_30_mismatch" severity error;
        casr_30_tst_vec   <= casr30_vectors(casr_30_counter_v);
        casr_30_counter_v := casr_30_counter_v + 1;
      end if;

      if casr_90_valid_o = '1' then
        assert (casr_90_state_o = casr_90_tst_vec) report "reinit test casr_90_mismatch" severity error;
        casr_90_tst_vec   <= casr90_vectors(casr_90_counter_v);
        casr_90_counter_v := casr_90_counter_v + 1;
      end if;

      if casr_150_valid_o = '1' then
        assert (casr_150_state_o = casr_150_tst_vec) report "reinit test casr_150_mismatch" severity error;
        casr_150_tst_vec   <= casr150_vectors(casr_150_counter_v);
        casr_150_counter_v := casr_150_counter_v + 1;
      end if;

      if h90150_valid_o = '1' then
        assert (h90150_state_o = h90150_tst_vec) report "reinit test casr_h_mismatch" severity error;
        h90150_tst_vec   <= casr90150h_vectors(casr_h_counter_v);
        casr_h_counter_v := casr_h_counter_v + 1;
      end if;

    end loop second_reinit_test_loop;
    wait until rising_edge(tb_clk);

    casr_30_gen_i  <= '0';
    casr_90_gen_i  <= '0';
    casr_150_gen_i <= '0';
    h90150_gen_i   <= '0';
    wait for 10*clk_period;
    wait until rising_edge(tb_clk);

    --------------------------------------------------------------------------------
    -- CLEAR TEST IS DONE - START GEN TEST - PULL GEN LOW DURING OPERATIONS
    --------------------------------------------------------------------------------

    --wait until tb_rst_done='1';
    wait for 2*clk_period;
    wait until rising_edge(tb_clk);
    -- get seeds
    casr_30_seed_i  <= casr30_seed1_c;
    casr_90_seed_i  <= casr90_seed1_c;
    casr_150_seed_i <= casr150_seed1_c;
    h90150_seed_i   <= casr90150h_seed1_c;
    h90150_rule_i   <= casr90150h_rule1_c;
    -- trigger init
    casr_30_init_i  <= '1'; casr_30_gen_i <= '1';
    casr_90_init_i  <= '1'; casr_90_gen_i <= '1';
    casr_150_init_i <= '1'; casr_150_gen_i <= '1';
    h90150_init_i   <= '1'; h90150_gen_i <= '1';
    -- trigger gen
    wait until rising_edge(tb_clk);
    -- single clock init ends
    casr_30_init_i  <= '0';
    casr_90_init_i  <= '0';
    casr_150_init_i <= '0';
    h90150_init_i   <= '0';
    wait until rising_edge(tb_clk);
    casr_30_counter_v  := 1;
    casr_90_counter_v  := 1;
    casr_150_counter_v := 1;
    casr_h_counter_v   := 1;
    casr_30_tst_vec    <= casr30_vectors(0);
    casr_90_tst_vec    <= casr90_vectors(0);
    casr_150_tst_vec   <= casr150_vectors(0);
    h90150_tst_vec     <= casr90150h_vectors(0);
    last_test_loop : for o in 0 to 25 loop
      casr_30_gen_i  <= '1';
      casr_90_gen_i  <= '1';
      casr_150_gen_i <= '1';
      h90150_gen_i   <= '1';
      if (o > 15 and o < 21) then
        casr_30_gen_i  <= '0'; -- pull gen for 5 cycles
        casr_90_gen_i  <= '0'; -- pull gen for 5 cycles
        casr_150_gen_i <= '0'; -- pull gen for 5 cycles
        h90150_gen_i   <= '0'; -- pull gen for 5 cycles
      end if;
      wait until rising_edge(tb_clk);
      if casr_30_valid_o = '1' then
        assert (casr_30_state_o = casr_30_tst_vec) report "gen test casr_30_mismatch" severity error;
        casr_30_tst_vec   <= casr30_vectors(casr_30_counter_v);
        casr_30_counter_v := casr_30_counter_v + 1;
      end if;

      if casr_90_valid_o = '1' then
        assert (casr_90_state_o = casr_90_tst_vec) report "gen test casr_90_mismatch" severity error;
        casr_90_tst_vec   <= casr90_vectors(casr_90_counter_v);
        casr_90_counter_v := casr_90_counter_v + 1;
      end if;

      if casr_150_valid_o = '1' then
        assert (casr_150_state_o = casr_150_tst_vec) report "gen test casr_150_mismatch" severity error;
        casr_150_tst_vec   <= casr150_vectors(casr_150_counter_v);
        casr_150_counter_v := casr_150_counter_v + 1;
      end if;

      if h90150_valid_o = '1' then
        assert (h90150_state_o = h90150_tst_vec) report "gen test casr_h_mismatch" severity error;
        h90150_tst_vec   <= casr90150h_vectors(casr_h_counter_v);
        casr_h_counter_v := casr_h_counter_v + 1;
      end if;

    end loop last_test_loop;
    casr_30_gen_i  <= '0';
    casr_90_gen_i  <= '0';
    casr_150_gen_i <= '0';
    h90150_gen_i   <= '0';
    wait for 10*clk_period;
    wait until rising_edge(tb_clk);

    wait;
  end process;



end architecture rtl;
