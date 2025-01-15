library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity counter is
    port (
        clk         : in  std_logic;
        rst         : in  std_logic;
        rd_en       : in  std_logic;
        go          : in  std_logic;
        size        : in  std_logic_vector(16 downto 0);
        done        : out std_logic
    );
end counter;

architecture bhv of counter is
    type STATE_TYPE is (S_START, S_COUNT);
    signal state, next_state         : STATE_TYPE;

    signal counter, next_counter     : unsigned(16 downto 0) := (others => '0');
    signal done_temp, next_done_temp : std_logic := '0';
    signal done_temp_r, next_done_temp_r : std_logic := '0';
    signal go_set, next_go_set       : std_logic := '0';

begin

    process(clk, rst)
    begin
        if rst = '1' then
            state        <= S_START;
            counter      <= (others => '0');
            go_set       <= '0';
            done_temp_r  <= '0';
        elsif rising_edge(clk) then
            state        <= next_state;
            counter      <= next_counter;
            go_set       <= next_go_set;
            done_temp_r  <= next_done_temp_r;
        end if;
    end process;

    
    done <= (done_temp or done_temp_r) and not go; 

   
    process(state, go, rd_en, size, counter, go_set, done_temp_r)
    begin
       
        next_state       <= state;
        next_counter     <= counter;
        next_go_set      <= go_set;
        next_done_temp   <= '0';      
        next_done_temp_r <= done_temp_r;

        if go = '1' then
            next_go_set      <= '1';
            next_done_temp_r <= '0';
        end if;

        if (rd_en = '1' and go_set = '1') then
            next_counter <= counter + 1;
        end if;

        if std_logic_vector(counter) = size then
            next_counter <= (others => '0');
            next_go_set  <= '0';
        end if;

        case state is
            when S_START =>
                if go = '1' then
                    next_state <= S_COUNT;
                end if;

            when S_COUNT =>
                if std_logic_vector(counter) = size then
                    next_state     <= S_START;
                    next_done_temp <= '1';   -- signal done
                end if;
        end case;

        if next_done_temp = '1' then
            
            next_done_temp_r <= '1';
        end if;
        
        -- done_temp is just a combinational signal that triggers done_temp_r update
        done_temp <= next_done_temp;
    end process;

end bhv;
