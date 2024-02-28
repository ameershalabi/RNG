--------------------------------------------------------------------------------
-- Title       : Mersenne Twister
-- Project     : rand_proj
--------------------------------------------------------------------------------
-- File        : mt_32.vhd
-- Author      : Ameer Shalabi <ameershalabi94@gmail.com>
-- Company     : -
-- Created     : Mon Feb 19 18:57:40 2024
-- Last update : Wed Feb 28 12:38:35 2024
-- Platform    : -
-- Standard    : <VHDL-2008>
--------------------------------------------------------------------------------
-- Description: 
--------------------------------------------------------------------------------
-- Revisions:
-------------------------------------------------------------------------------

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity mt_32 is
  port (
    -- ctrl ports
    clk : in std_logic; -- clock pin
    rst : in std_logic; -- active low rest pin
    clr : in std_logic; -- clear pin
    enb : in std_logic; -- enable pin

    -- seed init ports
    init_i : in std_logic;
    seed_i : in std_logic_vector(31 downto 0);

    -- output ports
    init_done_o : out std_logic;
    init_err_o  : out std_logic;

    mt_32_o : out std_logic_vector(31 downto 0)
  );

end entity mt_32;

architecture mt_32_arch of mt_32 is

  -- constants (change constants depending on desired coefficients)
  -- current coefficients are ones chosen by myself. A list of changable
  -- coefficients for width 32-bit can be found in the mt_algo.txt
  -- prime choosen is 521 mersenne prime

  -- w: word size (in number of bits)
  constant w_data_width_c : integer := 32;
  --n: degree of recurrence
  constant n_reccurance_c : integer := 101;
  --m: middle word, an offset used in the recurrence relation 
  --defining the series x, 1≤m<n
  constant m_middle_word_c : integer := 51;
  --r: separation point of one word, or the number of bits of 
  --the lower bitmask, 0≤r≤w−1
  constant r_split_idx_c : integer := 15;
  --a: coefficients of the rational normal form twist matrix
  constant a_coeffints_c : std_logic_vector(31 downto 0) := x"9908B0DF";
  --u, d, l: additional Mersenne Twister tempering bit shifts/masks
  constant u_shifts_c : integer := 11;
  --u, d, l: additional Mersenne Twister tempering bit shifts/masks
  constant d_mask_c : std_logic_vector(31 downto 0) := x"FFFFFFFF";
  --s, t: TGFSR(R) tempering bit shifts
  constant s_shifts_c : integer := 7;
  --b, c: TGFSR(R) tempering bitmasks
  constant b_mask_c : std_logic_vector(31 downto 0) := x"9D2C5680";
  --s, t: TGFSR(R) tempering bit shifts
  constant t_shifts_c : integer := 15;
  --b, c: TGFSR(R) tempering bitmasks
  constant c_mask_c : std_logic_vector(31 downto 0) := x"EFC60000";
  --u, d, l: additional Mersenne Twister tempering bit shifts/masks
  constant l_shifts_c : integer := 18;
  --The constant f forms another parameter to the generator, 
  -- though not part of the algorithm proper.
  constant f_mult_factor_c : std_logic_vector(31 downto 0) := x"6C078965";
  --  lower mask based on the spliting index r_split_idx_c
  constant lower_mask_c : std_logic_vector(31 downto 0) := (31 downto r_split_idx_c+1 => '0')&(r_split_idx_c downto 0 => '1');
  --  upper mask based on the spliting index r_split_idx_c
  constant upper_mask_c : std_logic_vector(31 downto 0) := not lower_mask_c;

  type mod_reg_arr_t is array (n_reccurance_c+m_middle_word_c-1 downto 0) of integer range 0 to n_reccurance_c+m_middle_word_c-1;

  -- this function will create x number of bit registers where
  -- x = n_reccurance_c+m_middle_word_c * rounded_up(log2(n_reccurance_c+m_middle_word_c))
  -- in this configuration case, it will be 
  -- x = 101+51 * rounded_up(log2(101+51)) = 152 * 8 = 1216 bits ~ 152 bytes
  -- at higher configuration numbers, this number will greatly increase
  -- in case the configurations MT19937 are used
  -- x = 624+397 * 10 = 1021 * 10 = 10210 bits ~ 1.3 KB of memory
  -- in that case, a ROM is more appropriate option for storing the
  -- the mod calculation (seperate ROM is not supported yet)
  function gen_mod_reg_array return mod_reg_arr_t is
    variable mod_reg_arr_v : mod_reg_arr_t;
  begin
    for i in 0 to n_reccurance_c+m_middle_word_c-1 loop
      mod_reg_arr_v(i) := i mod n_reccurance_c;
    end loop ;
    return mod_reg_arr_v;
  end function gen_mod_reg_array;

  constant mod_reg_arr : mod_reg_arr_t := gen_mod_reg_array;
  signal mod_reg_arr_r : mod_reg_arr_t;

  -- this constant controls how many MT elements are initialized
  -- before the twist stage is started. it is the same offset that
  -- controls how many MT elements are twisted before the number
  -- generation stage is started and output produced. The value
  -- of this offset can only be equal to m+1 or higher. Otherwise
  -- the twist function will not find the required data on the 
  -- mt array in time during initialisation causing wrong output
  constant init_twist_offset_c : integer := m_middle_word_c+1;


  -- type declarations and signals
  type mt_init_arr_t is array (n_reccurance_c-1 downto 0) of unsigned(31 downto 0);
  signal mt_arr_r       : mt_init_arr_t; 
  signal init_mt_arr_r  : mt_init_arr_t; 
  signal twist_mt_arr_r : mt_init_arr_t; --DEBUG only
  signal mt_xor_arr_r   : mt_init_arr_t; --DEBUG only

  -- MT control signals
  signal clr_r         : std_logic;
  signal enb_r         : std_logic;
  signal start_twist_r : std_logic;
  signal start_gen_r   : std_logic;

  -- init control signals
  signal init_r             : std_logic;
  signal init_counter_r     : integer range 1 to n_reccurance_c;
  signal init_in_progress_r : std_logic;
  signal init_done_r        : std_logic;
  signal init_err_r         : std_logic;

  -- twist control signals
  signal twist_r                   : std_logic;
  signal twist_counter_r           : integer range 0 to n_reccurance_c;
  signal twisted_word_r            : unsigned(31 downto 0);
  signal TWIST_twist_word          : unsigned(31 downto 0);
  signal TWIST_up_twist_word       : unsigned(31 downto 0);
  signal TWIST_lo_twist_word       : unsigned(31 downto 0);
  signal TWIST_up_mask_and_word    : unsigned(31 downto 0);
  signal TWIST_lo_mask_and_word    : unsigned(31 downto 0);
  signal TWIST_masked_word         : unsigned(31 downto 0);
  signal TWIST_shifted_masked_word : unsigned(31 downto 0);
  signal TWIST_twisted_word        : unsigned(31 downto 0);
  signal TWIST_i_1_mod_n           : integer range 0 to n_reccurance_c+m_middle_word_c-1;
  signal TWIST_i_m_mod_n           : integer range 0 to n_reccurance_c+m_middle_word_c-1;

  --generate control signals
  signal gen_r         : std_logic;
  signal gen_counter_r : integer range 0 to n_reccurance_c;
  signal gen_word_r    : unsigned(31 downto 0);



begin

  -- control signals process
  ctrl_proc : process (clk, rst)
  begin
    if (rst = '0') then
      clr_r         <= '0';
      enb_r         <= '0';
      init_r        <= '0';
      mod_reg_arr_r <= (others => 0);


      mt_arr_r <= (others => (others => '0'));
      twist_r  <= '0';
      gen_r    <= '0';

    elsif rising_edge(clk) then
      clr_r  <= clr;
      enb_r  <= enb;
      init_r <= init_i;

      -- load the modulo ROM when init in progress
      if (init_r='1') then
        mod_reg_arr_r <= mod_reg_arr;
      end if;

      -- when block is enabled
      if (enb_r = '1') then

        --during init, the mt array receives the initlised words
        if (init_r = '1') then
          if (init_counter_r <= n_reccurance_c) then
            mt_arr_r(init_counter_r-1) <= init_mt_arr_r(init_counter_r-1);
          end if;
        end if;
        -- once generation starts, the generated word is stored in the
        -- mt array at the index where it was generated
        if (gen_r= '1') then
          mt_arr_r(gen_counter_r) <= gen_word_r;
        end if;
        -- store twist and generate control signals
        twist_r <= start_twist_r;
        gen_r   <= start_gen_r;

        -- clear the registers inside the enable block
        if (clr_r ='1') then
          mt_arr_r <= (others => (others => '0'));
          twist_r  <= '0';
          gen_r    <= '0';
        end if; -- clr_r = '1'
      end if;   -- enb_r = '1'

    end if;
  end process ctrl_proc;

  init_proc : process (clk, rst)
    variable seed_v           : unsigned(31 downto 0);
    variable init_word_v      : unsigned(31 downto 0);
    variable shifted_word_v   : unsigned(31 downto 0);
    variable xor_stage_v      : unsigned(31 downto 0);
    variable mult_add_stage_v : unsigned(63 downto 0);
    variable add_stage_v : unsigned(31 downto 0);
  begin
    if (rst = '0') then
      init_mt_arr_r      <= (others => (others => '0'));
      init_counter_r     <= 1;
      init_in_progress_r <= '0';
      init_done_r        <= '0';
      init_err_r         <= '0';
      start_twist_r      <= '0';

    elsif rising_edge(clk) then
      if (enb_r = '1') then

        if (init_r = '1' and init_counter_r < n_reccurance_c) then
          seed_v           := unsigned(seed_i);
          init_mt_arr_r(0) <= seed_v;
          mt_xor_arr_r(0)  <= (31 downto 2 => '0')&seed_v(31 downto 30);

          init_in_progress_r <= '1'; -- mark init in progress
          init_done_r        <= '0'; -- not done yet
                                     --start_twist_r      <= '0';

          if init_in_progress_r = '1' then --and init_counter_r < n_reccurance_c then
                                           -- get the previous word from the tm array
            init_word_v := init_mt_arr_r(init_counter_r - 1);
            -- shift it w_data_width_c-2 times (no actual shifting is done, only slide the MSB and pad with 0s)
            shifted_word_v := (31 downto 2 => '0')&init_word_v(31 downto 30);
            -- init_word_v XOR shifted_word_v
            xor_stage_v := init_word_v xor shifted_word_v;
            -- multiply with f_mult_factor_c and add location in tm array
            add_stage_v := xor_stage_v + to_unsigned(init_counter_r,32);
            --mult_add_stage_v :=unsigned(f_mult_factor_c) * xor_stage_v + to_unsigned(init_counter_r,32);
            -- get the w_data_width_c msb of the multiplication result
            init_mt_arr_r(init_counter_r) <= add_stage_v(31 downto 0);
            --init_mt_arr_r(init_counter_r) <= mult_add_stage_v(31 downto 0);
            -- increment counter to fetch new word
            init_counter_r <= init_counter_r +1;

            mt_xor_arr_r(init_counter_r) <= shifted_word_v; --DEBUG only
          end if;
        end if; -- init_r = '1'

        if init_counter_r = init_twist_offset_c then
          start_twist_r <= '1';
        end if;

        if init_counter_r = n_reccurance_c then
          init_done_r        <= '1'; -- mark done when all init states are created
          init_in_progress_r <= '0'; -- not in progress
        end if;

        if (
            init_in_progress_r = '1' -- if still in progress
            and init_done_r = '0'    -- init not done 
            and init_r = '0'         -- but not in init state
          ) then
          init_err_r <= '1'; -- give error flag
        else
          init_err_r <= '0'; -- give error flag
        end if;              -- error block

        if (clr_r ='1') then

          init_mt_arr_r      <= (others => (others => '0'));
          init_counter_r     <= 1;
          init_in_progress_r <= '0';
          init_done_r        <= '0';
          init_err_r         <= '0';
          start_twist_r      <= '0';

        end if; -- clr_r = '1'

      end if; -- enb_r = '1'
    end if;
  end process init_proc;

  twist_proc : process (clk, rst)
    variable twist_word_v          : unsigned(31 downto 0);
    variable up_twist_word_v       : unsigned(31 downto 0);
    variable lo_twist_word_v       : unsigned(31 downto 0);
    variable up_mask_and_word_v    : unsigned(31 downto 0);
    variable lo_mask_and_word_v    : unsigned(31 downto 0);
    variable masked_word_v         : unsigned(31 downto 0);
    variable shifted_masked_word_v : unsigned(31 downto 0);
    variable twisted_word_v        : unsigned(31 downto 0);
    variable i_1_mod_n_v           : integer range 0 to n_reccurance_c+m_middle_word_c-1;
    variable i_m_mod_n_v           : integer range 0 to n_reccurance_c+m_middle_word_c-1;
  begin
    if (rst = '0') then
      twist_counter_r <= 0;
      start_gen_r     <= '0';

    elsif rising_edge(clk) then
      if (enb_r = '1') then
        --(31 downto r_split_idx_c+1 => '0')&(r_split_idx_c downto 0 => '1');
        if (start_twist_r = '1') then
          if twist_counter_r < n_reccurance_c then
            -- get i+1 mod n from the modulo ROM
            i_1_mod_n_v := mod_reg_arr_r(twist_counter_r+1);
            -- get the mt word from the mt array at current location 
            up_twist_word_v := mt_arr_r(twist_counter_r);
            -- get the mt word from the mt array at i+1 mod n
            lo_twist_word_v := mt_arr_r(i_1_mod_n_v);
            -- perform masking on the two mt words
            up_mask_and_word_v := unsigned(std_logic_vector(up_twist_word_v)
                and std_logic_vector(upper_mask_c));
            lo_mask_and_word_v := unsigned(std_logic_vector(lo_twist_word_v)
                and std_logic_vector(lower_mask_c));
            -- concat the masked words at the mask boundries
            masked_word_v := up_mask_and_word_v(31 downto r_split_idx_c+1) &
              lo_mask_and_word_v(r_split_idx_c downto 0);
            -- check if masked word is not even
            if (masked_word_v(0) = '1') then
              -- if odd, single right shift and xor with coefficients
              shifted_masked_word_v := unsigned(std_logic_vector('0'&masked_word_v(30 downto 0)) xor a_coeffints_c);
            else
              -- if even, single right shift only
              shifted_masked_word_v := '0'&masked_word_v(30 downto 0);
            end if;
            -- get i+m mod n from modulo ROM
            i_m_mod_n_v := mod_reg_arr_r(twist_counter_r+m_middle_word_c);
            -- word result of twisting
            twisted_word_v := shifted_masked_word_v xor mt_arr_r(i_m_mod_n_v);

            TWIST_twist_word          <= twist_word_v;
            TWIST_up_twist_word       <= up_twist_word_v;
            TWIST_i_1_mod_n           <= i_1_mod_n_v;
            TWIST_lo_twist_word       <= lo_twist_word_v;
            TWIST_up_mask_and_word    <= up_mask_and_word_v;
            TWIST_lo_mask_and_word    <= lo_mask_and_word_v;
            TWIST_masked_word         <= masked_word_v;
            TWIST_shifted_masked_word <= shifted_masked_word_v;
            TWIST_twisted_word        <= twisted_word_v;
            TWIST_i_m_mod_n           <= i_m_mod_n_v;

            -- fill the debugging twist_mt_arr_r
            --twist_mt_arr_r(twist_counter_r) <= twisted_word_v;
            
            -- store twisted word 
            twisted_word_r                  <= twisted_word_v;

            twist_counter_r <= twist_counter_r +1;
            start_gen_r     <= '1';
          else
            twist_counter_r <= 0;
            start_gen_r     <= '0';
          end if;
        end if; -- twist_r = '1'
        if (clr_r = '1') then
          twist_counter_r <= 0;

          start_gen_r <= '0';
        end if;
      end if;
    end if;
  end process twist_proc;

  gen_proc : process (clk, rst)
    -- variable naming key
    -- twX : twisted_word X=0,1,2,3,4
    -- u, s, t, l : shifted by u/s/t/l_shifts_c
    -- d, b, c : d/b/c_mask_c
    variable tw0_v      : std_logic_vector(31 downto 0);
    variable tw0_long_v : std_logic_vector(63 downto 0);
    variable tw0_u_v    : std_logic_vector(63 downto 0);

    variable tw1_v   : std_logic_vector(63 downto 0);
    variable tw1_s_v : std_logic_vector(63 downto 0);

    variable tw2_v   : std_logic_vector(63 downto 0);
    variable tw2_t_v : std_logic_vector(63 downto 0);

    variable tw3_v   : std_logic_vector(63 downto 0);
    variable tw3_l_v : std_logic_vector(63 downto 0);

    variable tw4_v : std_logic_vector(63 downto 0);

    variable d_mask_c_long_v : std_logic_vector(63 downto 0);
    variable b_mask_c_long_v : std_logic_vector(63 downto 0);
    variable c_mask_c_long_v : std_logic_vector(63 downto 0);

  begin
    if (rst = '0') then
      gen_counter_r <= 0;
      gen_word_r    <= (others => '0');
    elsif rising_edge(clk) then
      if (enb_r = '1') then
        if (gen_r = '1') then
          tw0_v := std_logic_vector(twisted_word_r);
          tw0_long_v := std_logic_vector(resize(twisted_word_r,64));
          d_mask_c_long_v := (63 downto 32 => '0')&d_mask_c;
          b_mask_c_long_v := (63 downto 32 => '0')&b_mask_c;
          c_mask_c_long_v := (63 downto 32 => '0')&c_mask_c;
          -- tw0_v shifted left by u_shifts_c
          tw0_u_v := (63 downto 32+u_shifts_c => '0') & tw0_v & (u_shifts_c-1 downto 0 => '0');

          --d mask is FFFFFFFF
          tw1_v := tw0_long_v xor (tw0_u_v and d_mask_c_long_v);
          -- tw1_v shifted right by s_shifts_c
          tw1_s_v := (63 downto 64-s_shifts_c => '0')&tw1_v(63 downto s_shifts_c);
          --b mask is 9D2C5680
          tw2_v := tw1_v xor (tw1_s_v and b_mask_c_long_v);
          -- tw2_v shifted right by t_shifts_c
          tw2_t_v := (63 downto 64-t_shifts_c => '0')&tw2_v(63 downto t_shifts_c);
          --t mask is EFC60000
          tw3_v := tw2_v xor (tw2_t_v and c_mask_c_long_v);
          -- tw3_v shifted left by l_shifts_c
          tw3_l_v := tw3_v(63-l_shifts_c downto 0)&(l_shifts_c-1 downto 0 => '0');

          tw4_v := tw3_v xor tw3_l_v;

          gen_word_r <= resize(unsigned(tw4_v),32);

          gen_counter_r <= gen_counter_r +1;
          if (gen_counter_r = n_reccurance_c-1) then
            gen_counter_r <= 0;
          end if;
        end if;
        if (clr_r = '1') then
          gen_counter_r <= 0;
          gen_word_r    <= (others => '0');

        end if;
      end if;
    end if;
  end process gen_proc;

  mt_32_o <= std_logic_vector(gen_word_r);

  init_done_o <= init_done_r;
  init_err_o  <= init_err_r;
end mt_32_arch;

