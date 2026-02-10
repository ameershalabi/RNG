--------------------------------------------------------------------------------
-- Title       : Cellular Automata Shift Register (CASR) (Rule 90/150 Hybrid) 
-- Project     : hdl_rand
--------------------------------------------------------------------------------
-- File        : casr_90150h.vhd
-- Author      : Ameer Shalabi <ameershalabi94@gmail.com>
-- Created     : Sun Jan 11 10:20:17 2026
-- Last update : Tue Feb 10 09:56:44 2026
-- Platform    : -
-- Standard    : VHDL-2008
--------------------------------------------------------------------------------
-- Description: A Cellular Automata Shift Register (CASR) applying rules 90
-- and rule 150 selectively. Has three output modes: 
-- 1) State LSB output (serial LSB)
-- 2) State MSB output (serial MSB)
-- 3) Full state output (parallel)
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity casr_90150h is
  generic (
    w_casr_g : integer := 8;
    -- control which bit to output
    -- '0' : output LSB bit
    -- '1' : output MSB bit
    o_bit_g : std_logic := '0';
    -- mode
    -- '0' : output is serial mode
    -- '1' : output is parallel
    o_mode_g : std_logic := '0';
    -- rule vector mode
    -- '0' : rule vector is static
    -- stored when seed is loaded
    -- '1' : rule vector is dynamic
    -- stored when rule_i chnages
    r_dyn_g : std_logic := '0'
  );
  port (
    -- ctrl ports
    clk : in std_logic; -- clock pin
    rst : in std_logic; -- active low rest pin
    clr : in std_logic; -- clear pin
    enb : in std_logic; -- enable pin

    seed_i : in std_logic_vector(w_casr_g-1 downto 0);
    rule_i : in std_logic_vector(w_casr_g-1 downto 0);
    init_i : in std_logic;
    gen_i  : in std_logic;

    valid_o : out std_logic;
    state_o : out std_logic_vector(w_casr_g-1 downto 0)

  );

end entity casr_90150h;

architecture arch of casr_90150h is

  signal clr_r : std_logic;
  signal enb_r : std_logic;
  signal gen_r : std_logic;

  -- extended casr for generating the next state
  -- two additional bits are used to connect the 
  -- register ends
  signal ext_casr_r : std_logic_vector(w_casr_g+1 downto 0);

  -- register to store the bit rules
  signal rule_r : std_logic_vector(w_casr_g-1 downto 0);

  -- output bit signals
  signal gen_valid   : std_logic;
  signal gen_valid_r : std_logic;
  signal o_bit       : std_logic;

begin

  -- Generate output bit and oputput modes
  -- When o_mode_g = '0' 
  -- Output is serial:
  -- i.e. a single bit is outputed at the LSB of the 
  -- state_o port. All other state_o bits are '0'
  -- -- if o_bit_g = '0', serial LSB mode :
  -- -- -- output bit is LSB of CASR state
  -- -- if o_bit_g = '1', serial MSB mode :
  -- -- -- output bit is MSB of CASR state

  -- connect output bit to LSB of next state
  gen_out_lsb_0 : if (o_bit_g = '0') generate
    o_bit <= ext_casr_r(w_casr_g+1);
  end generate gen_out_lsb_0;

  -- connect output bit to MSB of next state
  gen_out_lsb_1 : if (o_bit_g = '1') generate
    o_bit <= ext_casr_r(0);
  end generate gen_out_lsb_1;

  -- gen serial mode
  gen_serial_mode : if (o_mode_g = '0') generate

    serial_output_proc : process (o_bit)
    begin
      state_o    <= (others => '0');
      state_o(0) <= o_bit;
    end process serial_output_proc;

  end generate gen_serial_mode;

  -- When o_mode_g = '1'
  -- Full state output (parallel mode)
  -- i.e. all of the CASR state is put to the state_o
  -- in this mode, o_bit_g is not effective

  gen_parallel_mode : if (o_mode_g = '1') generate
    state_o <= ext_casr_r(w_casr_g downto 1);
  end generate gen_parallel_mode;

  -- when r_dyn_g = '0'
  -- store rule_i into register only when init_i is
  -- high. Only a single rule vector can be used for 
  -- each seed
  --gen_static_rule_vector : if (r_dyn_g = '0') generate
  --
  --  gen_static_rule_proc : process (clk, rst)
  --  begin
  --    if (rst = '0') then
  --      rule_r <= (others => '0');
  --    elsif rising_edge(clk) then
  --      if (enb_r = '1') then
  --        -- store the rule vector only when init is done
  --        if (init_i = '1') then
  --          rule_r <= rule_i;
  --        end if;
  --
  --        if (clr_r = '1') then
  --          rule_r <= (others => '0');
  --        end if;
  --
  --      end if;
  --    end if;
  --  end process gen_static_rule_proc;
  --
  --end generate gen_static_rule_vector;

  -- when r_dyn_g = '1'
  -- store rule_i into register at every clock cycle 
  -- when the block is enabled. multiple rule vectors
  -- can be used with a single seed
  --gen_dynamic_rule_vector : if (r_dyn_g = '0') generate
  --
  --  gen_dynamic_rule_proc : process (clk, rst)
  --  begin
  --    if (rst = '0') then
  --      rule_r <= (others => '0');
  --    elsif rising_edge(clk) then
  --      if (enb_r = '1') then
  --        -- store the rule vector at every enabled clock cycle
  --        rule_r <= rule_i;
  --        if (clr_r = '1') then
  --          rule_r <= (others => '0');
  --        end if;
  --
  --      end if;
  --    end if;
  --  end process gen_dynamic_rule_proc;
  --
  --end generate gen_dynamic_rule_vector;


  ctrl_proc : process (clk, rst)
  begin
    if (rst = '0') then
      clr_r <= '0';
      enb_r <= '0';
    elsif rising_edge(clk) then
      clr_r <= clr;
      enb_r <= enb;
    end if;
  end process ctrl_proc;

  -- the extended casr is divided into two bit groups
  -- state bits (s), extention bits (e) as follows
  -- MSBext    
  -- |<-------|
  -- ||-state-|
  -- esss...ssse
  --  |------->|
  --           LSBext

  -- output bit is valid when
  gen_valid <= '1' when gen_valid_r = '1' and gen_r = '1' else '0';

  gen_proc : process (clk, rst)
    variable l              : std_logic;
    variable c              : std_logic;
    variable r              : std_logic;
    variable exp1           : std_logic;
    variable new_ext_casr_v : std_logic_vector(w_casr_g+1 downto 0);

  begin
    if (rst = '0') then
      gen_r       <= '0';
      gen_valid_r <= '0';
      ext_casr_r  <= (others => '0');
      rule_r      <= (others => '0');
    elsif rising_edge(clk) then
      if (enb_r = '1') then
        -- output is invalid by default
        gen_valid_r <= '0';
        gen_r       <= gen_i;

        -- load the seed when init_i is high
        if (init_i = '1') then
          ext_casr_r(w_casr_g downto 1) <= seed_i;
          -- connect LSBext to the MSB of state
          ext_casr_r(0) <= seed_i(w_casr_g-1);
          -- connect MSBext to the LSB of state
          ext_casr_r(w_casr_g+1) <= seed_i(0);
          -- first output after init is invalid as
          -- it is the o_bit of the seed
          gen_valid_r <= '0';
          rule_r      <= rule_i;

        else
          -- if gen_i is high and init_i is low,
          -- generate the next state by applying the 
          -- expression on the left bit, state bit, and
          -- right bit
          if (gen_r = '1') then
            -- if generate is high, the first output is not yet
            -- valid, so valid is delayed a single clock cycle
            gen_valid_r <= '1';
            generate_next_state : for b in 1 to w_casr_g loop
              -- get left bit of state bit b
              l := ext_casr_r(b-1);
              -- get state bit b
              c := ext_casr_r(b);
              -- get right bit of state bit b
              r := ext_casr_r(b+1);

              -- for each bit, check associated rule.
              -- when rule_r(b-1) = '0', use rule 90
              -- when rule_r(b-1) = '1', use rule 150
              if (rule_r(b-1) = '0') then
                -- generate next bit state using rule 90
                exp1 := l xor r;
              else
                -- generate next bit state using rule 150
                exp1 := l xor c xor r;
              end if;

              -- store the new state bit
              new_ext_casr_v(b) := exp1;
              -- generate the extention bits for next round
              new_ext_casr_v(0)          := new_ext_casr_v(w_casr_g);
              new_ext_casr_v(w_casr_g+1) := new_ext_casr_v(1);
            end loop generate_next_state;
            ext_casr_r <= new_ext_casr_v;
          end if;
        end if;
        if (clr_r = '1') then
          gen_r       <= '0';
          gen_valid_r <= '0';
        end if;
      end if;
    end if;
  end process gen_proc;

  valid_o <= gen_valid;

end architecture arch;

