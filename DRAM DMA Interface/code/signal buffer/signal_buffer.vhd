library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.math_custom.all;
use work.config_pkg.all;
use work.user_pkg.all;

entity signal_buffer is
    generic (size : positive);
    port(
        clk     : in std_logic;
        rst     : in std_logic;
        rd_en   : in std_logic;
        wr_en   : in std_logic;
        input   : in std_logic_vector(RAM0_RD_DATA_RANGE);
        empty   : out std_logic;
        full    : out std_logic;
        output  : out window(0 to size-1)
    );
end signal_buffer;

architecture bhv of signal_buffer is
    --make the data one bigger than actual window size to account for i+1 logic
    --output will be data(1 to size) since all data will have shifted across by the final computation
    
    signal data : window(0 to size):= (others => (others => '0')); 
    
    signal count : integer := 0;

    signal count_lt_kernel_size : std_logic;

begin
    U_WINDOW : for i in 0 to size-1 generate
        U_REG : entity work.reg
            generic map (width => C_KERNEL_WIDTH)
            port map (
                clk => clk,
                rst => rst,
                en => wr_en,
                input => data(i),
                output => data(i+1) --chaining registers
            );
        end generate;
    
    output <= data(1 to size);
    count_lt_kernel_size <= '1' when count < C_KERNEL_SIZE else '0';

    process(clk, rst)
    begin
        if(rst = '1') then
            count <= 0;
        elsif(rising_edge(clk)) then
            
            if(wr_en = '1') then
                data(0) <= input;
                count <= count + 1;
            end if;
            if(rd_en = '1') then
                count <= count - 1;
            end if;
        end if;
    end process;
    empty <= '1' when (count_lt_kernel_size = '1') else '0';
    full <= '0' when (count_lt_kernel_size = '1') or (rd_en = '1') else '1';
    

end bhv;