--------------------------------------------------------------------------------
-- Title       : select_slide_rand
-- Project     : rand_proj
--------------------------------------------------------------------------------
-- File        : select_slide_rand.vhd
-- Author      : Ameer Shalabi <ameershalabi94@gmail.com>
-- Company     : -
-- Created     : Tue Feb 1  19:38:26 2024
-- Last update : Sun Apr 13 13:51:54 2025
-- Platform    : -
-- Standard    : <VHDL-2008>
-------------------------------------------------------------------------------
-- Description: 
--------------------------------------------------------------------------------
-- Revisions:  
-------------------------------------------------------------------------------

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library rng;

entity select_slide_rand is
    generic(
        w_LFSR_g   : natural := 32;
        w_slider_g : natural := 4
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

end entity select_slide_rand;

architecture select_slide_rand_arch of select_slide_rand is

    function check_slider_width return integer is
        variable w_slider : integer range 1 to 4;
    begin
        if w_slider_g < 4 then
            w_slider := 2;
        elsif w_slider_g >= 4 then
            w_slider := 4;
        else
            w_slider := 2;
        end if;
        return w_slider;
    end function check_slider_width;

    function get_RAND_LFSRs_width return integer is
        variable w_RAND_LFSRs : integer range 2 to 32;
    begin
        if w_LFSR_g < 2 or w_LFSR_g > 32 then
            w_RAND_LFSRs := 32;
        else
            w_RAND_LFSRs := w_LFSR_g;
        end if;
        return w_RAND_LFSRs;
    end function get_RAND_LFSRs_width;

    -- constants
    constant w_slider_c : integer := check_slider_width;
    constant w_LFSR_c   : integer := get_RAND_LFSRs_width;

    constant n_sliders_c : integer := w_LFSR_c/w_slider_c;

    -- ctrl signals
    signal enb_r : std_logic;
    signal clr_r : std_logic;


    -- input registers
    signal init_data_r : std_logic_vector(w_LFSR_c-1 downto 0);
    signal init_r      : std_logic;

    -- init registers
    signal selector_LFSR_data_in_r : std_logic_vector(w_LFSR_c-1 downto 0);
    type LFSR_data_arr_t is array(0 to 2**w_slider_c-1) of std_logic_vector(w_LFSR_c-1 downto 0);
    signal LFSR_RAND_in_arr : LFSR_data_arr_t;
    signal init_done_r      : std_logic;
    --signal w_2_init_done_r    : std_logic;
    signal w_2_init_03_done_r : std_logic;
    signal w_2_init_12_done_r : std_logic;
    --signal w_4_init_done_r    : std_logic;
    signal w_4_init_s1_done_r : std_logic;
    signal w_4_init_s2_done_r : std_logic;
    signal LFSR_RAND_out_arr  : LFSR_data_arr_t;
    signal init_load          : std_logic;

    -- slider registers
    type sliders_arr_t is array(0 to n_sliders_c -1) of std_logic_vector(w_slider_c-1 downto 0);
    signal sliders_arr_r : sliders_arr_t;

    signal slide_sel : integer range 0 to n_sliders_c - 1;

    signal LFSR_select_o : std_logic_vector(w_LFSR_c-1 downto 0);
    signal slider_r      : std_logic_vector(w_slider_c-1 downto 0);

    -- enable ctrl
    signal enb_gen_r : std_logic;
    --signal RAND_LFSR_enb_gen : std_logic_vector (2**w_slider_c-1 downto 0);

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


    w_slider_is_2 : if (w_slider_c >= 2) generate

        --w_2_init_done_r <= w_2_init_03_done_r and w_2_init_12_done_r;

        LFSR_RAND_in_proc : process (clk, rst)
        begin
            if (rst = '0') then -- reset block
                selector_LFSR_data_in_r <= (others => '0');

                LFSR_RAND_in_arr(0)               <= (others => '0');
                LFSR_RAND_in_arr(1)               <= (others => '0');
                LFSR_RAND_in_arr(2**w_slider_c-2) <= (others => '0');
                LFSR_RAND_in_arr(2**w_slider_c-1) <= (others => '0');

                w_2_init_03_done_r <= '0';

                w_2_init_12_done_r <= '0';

                --w_2_init_done_r  <= '0';

            elsif rising_edge(clk) then
                if (enb_r = '1') then      -- active when block is enabled
                    if (init_r = '1') then -- the block is in init stage

                        -- set data for selctor LFSR
                        selector_LFSR_data_in_r <= init_data_r;

                        -- set data for first and last RAND_LFSR
                        LFSR_RAND_in_arr(0)               <= not init_data_r;
                        LFSR_RAND_in_arr(2**w_slider_c-1) <= init_data_r;

                        w_2_init_03_done_r <= '1';

                        if w_2_init_03_done_r = '1' then
                            -- set data for RAND_LFSR(1) and second to last RAND_LFSR
                            LFSR_RAND_in_arr(1) <=
                                LFSR_RAND_in_arr(0)(w_LFSR_c-1 downto w_LFSR_c/2) &
                                LFSR_RAND_in_arr(2**w_slider_c-1)(w_LFSR_c-1 downto w_LFSR_c/2);

                            LFSR_RAND_in_arr(2**w_slider_c-2) <=
                                LFSR_RAND_in_arr(0)(w_LFSR_c/2 -1 downto 0) &
                                LFSR_RAND_in_arr(2**w_slider_c-1)(w_LFSR_c/2 -1 downto 0);

                            w_2_init_12_done_r <= '1';

                        end if;
                    end if;

                    if (init_load='1') then
                        w_2_init_03_done_r <= '0';
                        w_2_init_12_done_r <= '0';
                    end if;

                    --if (clr_r = '1' or init_load='1') then -- clear block
                    if (clr_r = '1' ) then -- clear block
                        selector_LFSR_data_in_r <= (others => '0');

                        LFSR_RAND_in_arr(0)               <= (others => '0');
                        LFSR_RAND_in_arr(1)               <= (others => '0');
                        LFSR_RAND_in_arr(2**w_slider_c-2) <= (others => '0');
                        LFSR_RAND_in_arr(2**w_slider_c-1) <= (others => '0');

                        w_2_init_03_done_r <= '0';
                        w_2_init_12_done_r <= '0';
                    --w_2_init_done_r  <= '0';
                    end if;
                end if;
            end if;
        end process LFSR_RAND_in_proc;
    end generate w_slider_is_2;

    w_slider_is_4 : if (w_slider_c = 4) generate


        --w_4_init_done_r <= w_4_init_s1_done_r and w_4_init_s2_done_r;
        LFSR_RAND_in_proc : process (clk, rst)
        begin
            if (rst = '0') then -- reset block

                LFSR_RAND_in_arr(2 to 11) <= (others => (others => '0'));

                LFSR_RAND_in_arr(2**w_slider_c-4) <= (others => '0');
                LFSR_RAND_in_arr(2**w_slider_c-3) <= (others => '0');

                w_4_init_s1_done_r <= '0';
                w_4_init_s2_done_r <= '0';

            --w_4_init_done_r  <= '0';
            elsif rising_edge(clk) then
                if (enb_r = '1') then                                   -- active when block is enabled
                    if (init_r = '1' and w_2_init_12_done_r = '1') then -- the block is in init stage
                        reverse_RAND_LFSR_bits_loop : for xbit in 0 to w_LFSR_c-1 loop
                            LFSR_RAND_in_arr(2)(xbit)               <= LFSR_RAND_in_arr(0)(w_LFSR_c-1-xbit);
                            LFSR_RAND_in_arr(3)(xbit)               <= LFSR_RAND_in_arr(1)(w_LFSR_c-1-xbit);
                            LFSR_RAND_in_arr(2**w_slider_c-4)(xbit) <= LFSR_RAND_in_arr(2**w_slider_c-2)(w_LFSR_c-1-xbit);
                            LFSR_RAND_in_arr(2**w_slider_c-3)(xbit) <= LFSR_RAND_in_arr(2**w_slider_c-1)(w_LFSR_c-1-xbit);
                        end loop reverse_RAND_LFSR_bits_loop;

                        w_4_init_s1_done_r <= '1';
                        if (w_4_init_s1_done_r = '1') then
                            LFSR_RAND_in_arr(4)  <= not LFSR_RAND_in_arr(0);
                            LFSR_RAND_in_arr(5)  <= not LFSR_RAND_in_arr(1);
                            LFSR_RAND_in_arr(6)  <= not LFSR_RAND_in_arr(2);
                            LFSR_RAND_in_arr(7)  <= not LFSR_RAND_in_arr(3);
                            LFSR_RAND_in_arr(8)  <= not LFSR_RAND_in_arr(2**w_slider_c-4);
                            LFSR_RAND_in_arr(9)  <= not LFSR_RAND_in_arr(2**w_slider_c-3);
                            LFSR_RAND_in_arr(10) <= not LFSR_RAND_in_arr(2**w_slider_c-2);
                            LFSR_RAND_in_arr(11) <= not LFSR_RAND_in_arr(2**w_slider_c-1);

                            w_4_init_s2_done_r <= '1';
                        end if;

                    end if;

                    --w_4_init_done_r  <= w_4_init_s1_done_r and w_4_init_s2_done_r;

                    if (init_load='1') then
                        w_4_init_s1_done_r <= '0';
                        w_4_init_s2_done_r <= '0';
                    end if;

                    --if (clr_r = '1' or init_load='1') then -- clear block
                    if (clr_r = '1') then -- clear block
                        LFSR_RAND_in_arr(2 to 11) <= (others => (others => '0'));

                        LFSR_RAND_in_arr(2**w_slider_c-4) <= (others => '0');
                        LFSR_RAND_in_arr(2**w_slider_c-3) <= (others => '0');

                        w_4_init_s1_done_r <= '0';
                        w_4_init_s2_done_r <= '0';
                    end if;
                end if;

            end if;
        end process LFSR_RAND_in_proc;
    end generate w_slider_is_4;

    gen_init_for_w_slider_2 : if (w_slider_c = 2) generate

        init_ctrl_proc : process (clk, rst)
        begin
            if (rst = '0') then
                init_done_r <= '0';
                enb_gen_r   <= '0';
            elsif rising_edge(clk) then
                if (enb_r = '1') then
                    if init_r = '1' then
                        enb_gen_r <= '0';
                        if (w_2_init_12_done_r = '1') then
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
    end generate gen_init_for_w_slider_2;

    gen_init_for_w_slider_4 : if (w_slider_c = 4) generate

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
    end generate gen_init_for_w_slider_4;


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


    i_selector_LFSR : entity rng.LFSR_generic
        generic map (
            LFSR_len => w_LFSR_c
        )
        port map (
            clk       => clk,
            rst       => rst,
            load      => init_load,
            load_data => selector_LFSR_data_in_r,
            gen_e     => enb_gen_r,
            LFSR_out  => LFSR_select_o
        );

    ----------------------------------------------------------------
    -- the slider is a std_logic_vector of width of w_slider_g.
    ----------------------------------------------------------------

    slider_r_proc : process (clk, rst)
    begin
        if (rst = '0') then
            slide_sel     <= n_sliders_c-1;
            sliders_arr_r <= (others => (others => '0'));
        elsif rising_edge(clk) then
            if (enb_gen_r = '1') then
                --if init_done_r = '1' then
                sliders_loop : for slider in 0 to n_sliders_c-1 loop
                    sliders_arr_r(slider) <= LFSR_select_o(slider*w_slider_c + w_slider_c -1 downto slider*w_slider_c);
                end loop sliders_loop;

                if (slide_sel = 0) then
                    slide_sel <= n_sliders_c-1;
                else
                    slide_sel <= slide_sel-1;
                end if;
                --end if;
                if (clr_r = '1') then
                    slide_sel     <= n_sliders_c-1;
                    sliders_arr_r <= (others => (others => '0'));
                end if;

            end if;
        end if;
    end process slider_r_proc;

    slider_r <= sliders_arr_r(slide_sel);

    -- TO DO : generate enable for the RAND_LFSRs
    -- the intention is to create logic that determins which of
    -- the RAND_LFSRs to enable gen. This is not important and 
    -- only intended as an extra layer of randomization
    --enable_RAND_proc : process ()
    --begin

    --end process enable_RAND_proc;

    RAND_LFSRs_gen : for rand_lfsr in 0 to 2**w_slider_c-1 generate
        i_LFSR_RAND : entity rng.LFSR_generic
            generic map (
                LFSR_len => w_LFSR_c
            )
            port map (
                clk       => clk,
                rst       => rst,
                load      => init_load,
                load_data => LFSR_RAND_in_arr(rand_lfsr),
                gen_e     => enb_gen_r,
                LFSR_out  => LFSR_RAND_out_arr(rand_lfsr)
            );
    end generate RAND_LFSRs_gen;

    select_rand_o_proc : process (clk, rst)
        variable sel : integer range 0 to 2**w_slider_c-1;
    begin
        if (rst = '0') then
            output_rand_o_r <= (others => '0');
        elsif rising_edge(clk) then
            if enb_r = '1' then
                sel := to_integer(unsigned(slider_r));
                if (enb_gen_r = '1') then
                    output_rand_o_r <= LFSR_RAND_out_arr(sel);
                end if;
                if clr_r = '1' then
                    output_rand_o_r <= (others => '0');
                end if;
            end if;
        end if;
    end process select_rand_o_proc;

    init_done_o   <= init_done_r;
    output_rand_o <= output_rand_o_r;

end select_slide_rand_arch;