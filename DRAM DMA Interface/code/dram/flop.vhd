library ieee;
use ieee.std_logic_1164.all;

entity flop is 
    port(
        clk     : in std_logic;
        input   : in std_logic;
        output  : out std_logic
    );
end flop;

architecture BHV of flop is
signal temp : std_logic;
begin
    process(clk)
    begin
        if(rising_edge(clk)) then
            temp <= input;
            output <= temp;
        end if;
    end process;
end architecture;