--------------------------------------------------------------------------------
-- Title       : A generic LFSR with synch load
-- Project     : hdl_rand
--------------------------------------------------------------------------------
-- File        : LFSR_generic.vhdl
-- Author      : Ameer Shalabi <ameershalabi94@gmail.com>
-- Company     : -
-- Created     : Wed Nov 11 08:47:34 2020
-- Last update : Thu Feb 29 12:24:49 2024
-- Platform    : -
-- Standard    : <VHDL-2008>
-------------------------------------------------------------------------------
-- Description: 
--------------------------------------------------------------------------------
-- Revisions:  
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity LFSR_generic is
	generic(LFSR_len : natural := 12);
	port (
		clk       : in  std_logic;
		rst       : in  std_logic;
		load      : in  std_logic;
		load_data : in  std_logic_vector(LFSR_len-1 downto 0);
		gen_e     : in  std_logic;
		LFSR_out  : out std_logic_vector(LFSR_len-1 downto 0)
	);

end entity LFSR_generic;

architecture LFSR_generic_arch of LFSR_generic is
	type XOR_placment_Type is array(2 to 32) of std_logic_vector(31 downto 0);

	constant XOR_placment_ROM : XOR_placment_Type := (
			"00000000000000000000000000000011",
			"00000000000000000000000000000101",
			"00000000000000000000000000001001",
			"00000000000000000000000000010010",
			"00000000000000000000000000100001",
			"00000000000000000000000001000001",
			"00000000000000000000000010001110",
			"00000000000000000000000100001000",
			"00000000000000000000001000000100",
			"00000000000000000000010000000010",
			"00000000000000000000100000101001",
			"00000000000000000001000000001101",
			"00000000000000000010000000010101",
			"00000000000000000100000000000001",
			"00000000000000001000000000010110",
			"00000000000000010000000000000100",
			"00000000000000100000000001000000",
			"00000000000001000000000000010011",
			"00000000000010000000000000000100",
			"00000000000100000000000000000010",
			"00000000001000000000000000000001",
			"00000000010000000000000000010000",
			"00000000100000000000000000001101",
			"00000001000000000000000000000100",
			"00000010000000000000000000100011",
			"00000100000000000000000000010011",
			"00001000000000000000000000000100",
			"00010000000000000000000000000010",
			"00100000000000000000000000101001",
			"01000000000000000000000000000100",
			"10000000000000000000000001100010"
		);
	constant XOR_placment : std_logic_vector(LFSR_len-1 downto 0) := XOR_placment_ROM(LFSR_len)(LFSR_len-1 downto 0);

	signal LFSR_Reg  : std_logic_vector(LFSR_len-1 downto 0);
	signal LFSR_feed : std_logic;

begin

	LFSR : process (clk,rst)
	begin
		if (rst='0') then
			LFSR_Reg <= XOR_placment;
		elsif rising_edge(clk) then
			LFSR_feed <= '0';
			if load = '1' then
				LFSR_Reg <= load_data;
			end if;
			if gen_e = '1' then
				LFSR_feed <= LFSR_Reg(LFSR_len-1);
				for gate in LFSR_len-1 downto 1 loop
					if (XOR_placment(gate-1)='1') then
						LFSR_Reg(gate) <= LFSR_Reg(gate-1) xor LFSR_feed;
					else
						LFSR_Reg(gate) <= LFSR_Reg(gate-1);
					end if;
				end loop;
				LFSR_Reg(0) <= LFSR_feed;
			end if;
		end if;
	end process;
	LFSR_out <= LFSR_Reg;
end LFSR_generic_arch;
