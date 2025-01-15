library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.math_custom.all;
use work.config_pkg.all;
use work.user_pkg.all;

entity signal_buffer_tb is
end signal_buffer_tb;

architecture TB of signal_buffer_tb is 

    signal clk		: std_logic := '0';
	signal rst		: std_logic;
	signal rd_en 	: std_logic;
	signal wr_en 	: std_logic;
	signal input 	: std_logic_vector(RAM0_RD_DATA_RANGE) := (others => '0');
	signal empty 	: std_logic;
	signal full 	: std_logic;
	signal output 	: window(0 to 127);

begin

    UUT : entity work.signal_buffer
    generic map(size => C_KERNEL_SIZE)
    port map(
        clk => clk,
        rst => rst,
        rd_en => rd_en,
        wr_en => wr_en,
        input => input,
        empty => empty,
        full => full,
        output => output
    );
    
    clk <= not clk after 5 ns;

    process 
    begin
        rst <= '1';
        input <= (others => '0');
        rd_en <= '0';
        wr_en <= '0';
        wait for 10 ns;
        
        rst <= '0';
        wait for 10 ns;

        wr_en <= '1';

        for i in 0 to 500 loop 
            if (i = 10) then
                rd_en <= '0';
                wr_en <= '0';
            elsif (i = 100) then
                rd_en <= '0';
                wr_en <= '1';
            elsif (i = 229)  then
                rd_en <= '1';
                wr_en <= '0';
            elsif (i = 310) then
                rd_en <= '0';
                wr_en <= '1';
            elsif (i = 390) then
                rd_en <= '1';
                wr_en <= '0';
            elsif (i = 460) then
                rd_en <= '1';
                wr_en <= '1';
            end if; 

            input <= std_logic_vector(to_unsigned(i, C_RAM0_RD_DATA_WIDTH));
            wait until rising_edge(clk);
        end loop;
        wait for 40 ns;
        rst <= '1';
        wait for 10 ns;
        report "SIMULATION FINISHED!";
        wait;
    end process;
end TB;

