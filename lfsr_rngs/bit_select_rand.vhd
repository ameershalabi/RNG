--------------------------------------------------------------------------------
-- Title       : bit_select_rand
-- Project     : rand_proj
--------------------------------------------------------------------------------
-- File        : bit_select_rand.vhd
-- Author      : Ameer Shalabi <ameershalabi94@gmail.com>
-- Company     : -
-- Created     : Tue Feb 11 10:37:34 2024
-- Last update : Thu Mar 14 23:48:30 2024
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

entity bit_select_rand is
  generic(
    n_select_bits_g : natural := 4
  );
  port (
    clk : in std_logic; -- clock pin
    rst : in std_logic; -- active low rest pin
    clr : in std_logic; -- clear pin
    enb : in std_logic; -- enable pin

    -- initial loading of selector LFSR
    init_data_i : in std_logic_vector(2**n_select_bits_g-1 downto 0);
    init_i      : in std_logic;

    output_rand_o : out std_logic_vector(2**n_select_bits_g-1 downto 0);
    init_done_o   : out std_logic

  );

end entity bit_select_rand;

architecture arch of bit_select_rand is

  function get_RAND_LFSRs_width return integer is
    variable w_RAND_LFSRs : integer range 1 to 32;
  begin
    if n_select_bits_g > 5 then
      w_RAND_LFSRs := 32;
    else
      w_RAND_LFSRs := 2**n_select_bits_g;
    end if;
    return w_RAND_LFSRs;
  end function get_RAND_LFSRs_width;


  -- constants
  constant w_LFSR_c : integer := get_RAND_LFSRs_width;

  -- ctrl signals
  signal enb_r : std_logic;
  signal clr_r : std_logic;

  -- input registers
  signal init_data_r : std_logic_vector(w_LFSR_c-1 downto 0);
  signal init_r      : std_logic;

  -- init registers
  signal selector_LFSR_data_in_r : std_logic_vector(n_select_bits_g-1 downto 0);
  type LFSR_data_arr_t is array(0 to 31) of std_logic_vector(w_LFSR_c-1 downto 0);
  signal LFSR_RAND_in_arr   : LFSR_data_arr_t;
  signal init_done_r        : std_logic;
  signal w_2_init_03_done_r : std_logic;
  signal w_2_init_12_done_r : std_logic;
  signal w_4_init_s1_done_r : std_logic;
  signal w_4_init_s2_done_r : std_logic;
  signal LFSR_RAND_out_arr  : LFSR_data_arr_t;
  signal init_load          : std_logic;


  signal LFSR_select_o : std_logic_vector(n_select_bits_g-1 downto 0);

  -- enable ctrl
  signal enb_gen_r           : std_logic;
  signal RAND_LFSR_en_vector : std_logic_vector(31 downto 0);


  -- output signal
  signal output_rand_o_r : std_logic_vector(w_LFSR_c-1 downto 0);

begin

  ----------------------------------------------------------------------------
  -- Stage 0 : register all input data into registers
  ----------------------------------------------------------------------------

  -- capture inputs into registers
  input_reg_proc : process (clk, rst)
  begin
    if (rst = '0') then
      init_data_r <= (others => '0');
      init_r      <= '0';
      enb_r       <= '0';
      clr_r       <= '0';
    elsif rising_edge(clk) then
      enb_r <= enb;
      clr_r <= clr;
      if (enb_r = '1') then
        init_data_r <= init_data_i;
        init_r      <= init_i;
        if (clr_r = '1') then
          init_data_r <= (others => '0');
          init_r      <= '0';
        end if;
      end if;
    end if;
  end process input_reg_proc;

  ----------------------------------------------------------------------------
  -- Stage 1 : initialise the LFSRs. The selector LFSR is loaded directly with
  -- the init_data_r and init_r signals. The RAND_LFSRs are loaded after
  -- data manipulation is done on the init_data_r to create the input vectors. 
  ----------------------------------------------------------------------------
  -- ENTIRE PROCESS NEEDS TO BE CONVERTED INTO GEN IF STATMENTS


  LFSR_RAND_in_proc : process (clk, rst)
  begin
    if (rst = '0') then -- reset block
      selector_LFSR_data_in_r <= (others => '0');

      LFSR_RAND_in_arr <= (others => (others => '0'));

      w_2_init_03_done_r <= '0';
      w_2_init_12_done_r <= '0';
      w_4_init_s1_done_r <= '0';
      w_4_init_s2_done_r <= '0';

    elsif rising_edge(clk) then
      if (enb_r = '1') then                          -- active when block is enabled
        if (init_r = '1' and init_done_r = '0') then -- the block is in init stage

          -- set data for selctor LFSR
          --selector_LFSR_data_in_r <= init_data_r(n_select_bits_g-1 downto 0);
          selector_LFSR_data_in_r <= (others => '1');

          -- set data for first and last RAND_LFSR
          LFSR_RAND_in_arr(0)                    <= not init_data_r;
          LFSR_RAND_in_arr(2**n_select_bits_g-1) <= init_data_r;

          w_2_init_03_done_r <= '1';

          if w_2_init_03_done_r = '1' then
            -- set data for RAND_LFSR(1) and second to last RAND_LFSR
            LFSR_RAND_in_arr(1) <=
              LFSR_RAND_in_arr(0)(w_LFSR_c-1 downto w_LFSR_c/2) &
              LFSR_RAND_in_arr(2**n_select_bits_g-1)(w_LFSR_c-1 downto w_LFSR_c/2);

            LFSR_RAND_in_arr(2**n_select_bits_g-2) <=
              LFSR_RAND_in_arr(0)(w_LFSR_c/2 -1 downto 0) &
              LFSR_RAND_in_arr(2**n_select_bits_g-1)(w_LFSR_c/2 -1 downto 0);

            w_2_init_12_done_r <= '1';
            if (w_2_init_12_done_r = '1') then -- the block is in init stage
              reverse_RAND_LFSR_bits_loop : for xbit in 0 to w_LFSR_c-1 loop
                LFSR_RAND_in_arr(2)(xbit)                    <= LFSR_RAND_in_arr(0)(w_LFSR_c-1-xbit);
                LFSR_RAND_in_arr(3)(xbit)                    <= LFSR_RAND_in_arr(1)(w_LFSR_c-1-xbit);
                LFSR_RAND_in_arr(2**n_select_bits_g-4)(xbit) <= LFSR_RAND_in_arr(2**n_select_bits_g-2)(w_LFSR_c-1-xbit);
                LFSR_RAND_in_arr(2**n_select_bits_g-3)(xbit) <= LFSR_RAND_in_arr(2**n_select_bits_g-1)(w_LFSR_c-1-xbit);
              end loop reverse_RAND_LFSR_bits_loop;

              w_4_init_s1_done_r <= '1';
              if (w_4_init_s1_done_r = '1') then
                LFSR_RAND_in_arr(4)  <= not LFSR_RAND_in_arr(0);
                LFSR_RAND_in_arr(5)  <= not LFSR_RAND_in_arr(1);
                LFSR_RAND_in_arr(6)  <= not LFSR_RAND_in_arr(2);
                LFSR_RAND_in_arr(7)  <= not LFSR_RAND_in_arr(3);
                LFSR_RAND_in_arr(8)  <= not LFSR_RAND_in_arr(2**n_select_bits_g-4);
                LFSR_RAND_in_arr(9)  <= not LFSR_RAND_in_arr(2**n_select_bits_g-3);
                LFSR_RAND_in_arr(10) <= not LFSR_RAND_in_arr(2**n_select_bits_g-2);
                LFSR_RAND_in_arr(11) <= not LFSR_RAND_in_arr(2**n_select_bits_g-1);

                LFSR_RAND_in_arr(12) <= not LFSR_RAND_in_arr(0);
                LFSR_RAND_in_arr(13) <= not LFSR_RAND_in_arr(1);
                LFSR_RAND_in_arr(14) <= not LFSR_RAND_in_arr(2);
                LFSR_RAND_in_arr(15) <= not LFSR_RAND_in_arr(3);
                LFSR_RAND_in_arr(16) <= not LFSR_RAND_in_arr(2**n_select_bits_g-4);
                LFSR_RAND_in_arr(17) <= not LFSR_RAND_in_arr(2**n_select_bits_g-3);
                LFSR_RAND_in_arr(18) <= not LFSR_RAND_in_arr(2**n_select_bits_g-2);
                LFSR_RAND_in_arr(19) <= not LFSR_RAND_in_arr(2**n_select_bits_g-1);

                LFSR_RAND_in_arr(20) <= not LFSR_RAND_in_arr(0);
                LFSR_RAND_in_arr(21) <= not LFSR_RAND_in_arr(1);
                LFSR_RAND_in_arr(22) <= not LFSR_RAND_in_arr(2);
                LFSR_RAND_in_arr(23) <= not LFSR_RAND_in_arr(3);
                LFSR_RAND_in_arr(24) <= not LFSR_RAND_in_arr(2**n_select_bits_g-4);
                LFSR_RAND_in_arr(25) <= not LFSR_RAND_in_arr(2**n_select_bits_g-3);
                LFSR_RAND_in_arr(26) <= not LFSR_RAND_in_arr(2**n_select_bits_g-2);
                LFSR_RAND_in_arr(27) <= not LFSR_RAND_in_arr(2**n_select_bits_g-1);

                w_4_init_s2_done_r <= '1';

              end if;
            end if;
          end if;
        end if;
        if (clr_r = '1' or init_load = '1') then -- clear block
          selector_LFSR_data_in_r <= (others => '0');
          LFSR_RAND_in_arr        <= (others => (others => '0'));
          w_2_init_03_done_r      <= '0';
          w_2_init_12_done_r      <= '0';
          w_4_init_s1_done_r      <= '0';
          w_4_init_s2_done_r      <= '0';
        end if;
      end if;
    end if;
  end process LFSR_RAND_in_proc;


  init_ctrl_proc : process (clk, rst)
  begin
    if (rst = '0') then
      init_done_r <= '0';
      enb_gen_r   <= '0';
    elsif rising_edge(clk) then
      if (enb_r = '1') then
        if init_r = '1' then
          enb_gen_r <= '0';
          if (w_4_init_s2_done_r = '1') then
            init_done_r <= '1';
          end if;
        else
          if init_load = '1' then
            init_done_r <= '0';
            enb_gen_r   <= '1';
          end if;
        end if;
        if (clr_r = '1') then -- clear block
          init_done_r <= '0';
          enb_gen_r   <= '0';

        end if;
      end if;
    end if;
  end process init_ctrl_proc;
  ----------------------------------------------------------------------------
  -- Stage 2 : start generation by enabling the selector and RAND LFSRs and
  -- loading the initial values to them.
  ----------------------------------------------------------------------------

  -- generate the enable for the selector LFSR
  enable_proc : process (init_done_r, enb_r)
  begin
    init_load <= '0';
    -- when block is enabled
    if enb_r = '1' then
      if init_done_r = '1' then
        init_load <= '1';
      end if;
    end if;
  end process enable_proc;



  i_selector_LFSR : entity work.LFSR_generic
    generic map (
      LFSR_len => n_select_bits_g
    )
    port map (
      clk       => clk,
      rst       => rst,
      load      => init_load,
      load_data => selector_LFSR_data_in_r,
      gen_e     => enb_gen_r,
      LFSR_out  => LFSR_select_o
    );


  -- TO DO : generate enable for the RAND_LFSRs
  -- the intention is to create logic that determins which of
  -- the RAND_LFSRs to enable gen. This is not important and 
  -- only intended as an extra layer of randomization
  enb_gen_proc : process (clk, rst)
  begin
    if (rst = '0') then
      RAND_LFSR_en_vector <= (others => '0');
    elsif rising_edge(clk) then
      if (enb_r = '1') then
        if enb_gen_r = '1' then
          en_gen_vector : for en_bit in 0 to 2**n_select_bits_g-1 loop
            if RAND_LFSR_en_vector(en_bit) = '0' then
              RAND_LFSR_en_vector(en_bit) <= (output_rand_o_r(en_bit) or init_data_r(2**n_select_bits_g-1-en_bit));
            else
              RAND_LFSR_en_vector(en_bit) <= (output_rand_o_r(en_bit) nand init_data_r(2**n_select_bits_g-1-en_bit));
            end if;
            --RAND_LFSR_en_vector(en_bit) <= (output_rand_o_r(2**n_select_bits_g-1-en_bit) xor RAND_LFSR_en_vector(en_bit));
          end loop en_gen_vector;
        end if;

        if (clr_r = '1') then -- clear block
          RAND_LFSR_en_vector <= (others => '0');
        end if;
      end if;
    end if;
  end process enb_gen_proc;

  RAND_LFSRs_gen : for rand_lfsr in 0 to 2**n_select_bits_g-1 generate
    i_LFSR_RAND : entity work.LFSR_generic
      generic map (
        LFSR_len => w_LFSR_c
      )
      port map (
        clk       => clk,
        rst       => rst,
        load      => init_load,
        load_data => LFSR_RAND_in_arr(rand_lfsr),
        gen_e     => RAND_LFSR_en_vector(rand_lfsr),
        LFSR_out  => LFSR_RAND_out_arr(rand_lfsr)
      );

    get_selected_bit : process (clk, rst)
      variable sel : integer range 0 to w_LFSR_c-1;
    begin
      if (rst = '0') then
        output_rand_o_r(rand_lfsr) <= '0';
      elsif rising_edge(clk) then
        if enb_r = '1' then
          sel                        := to_integer(unsigned(LFSR_select_o));
          output_rand_o_r(rand_lfsr) <= LFSR_RAND_out_arr(rand_lfsr)(sel);
          if clr_r = '1' then
            output_rand_o_r(rand_lfsr) <= '0';
          end if;
        end if;
      end if;
    end process get_selected_bit;
  end generate RAND_LFSRs_gen;


  init_done_o   <= init_done_r;
  output_rand_o <= output_rand_o_r;

end arch;