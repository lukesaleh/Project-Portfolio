-- Greg Stitt
-- University of Florida
--
-- File: dram_addr_gen.vhd
-- Entity: DRAM_ADDR_GEN
--
-- Description: This entity is an address generator for DRAM. The addr gen
-- waits until the go signal is asserted, and then creates "transfer_size"
-- addresses, once per cycle. If the stall signal is assert, the address
-- generator stalls. For each address, the addr gen outputs DRAM control
-- signals based on the "rd_wr" signal.
--

-------------------------------------------------------------------------------
-- Generic
-- addr_width: width of the address signal

-- Port
-- clk: clock
-- rst (active hi): reset
-- go (active hi): starts the address generators
-- rd_wr: specifies a read/write (rd = 0, wr = 1)
-- stall (active hi): stalls the address generator
-- addr_start: the address to start from
-- addr_out: the generated address
-- done (active hi): specifies that all addresses have been generated
-- dram_ld_n (active lo): load a read or write command
-- dram_rw_n: specifies a rd/wr to the DRAM (RD = 1, WR = 0)
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity dram_addr_gen is
    generic(addr_width : natural);
    port(
        clk         : in  std_logic;
        rst         : in  std_logic; 
        go          : in  std_logic; 
        size        : in  std_logic_vector(addr_width downto 0); 
        stall       : in  std_logic; 
        addr_start  : in  std_logic_vector(addr_width-2 downto 0); 
        addr_out    : out std_logic_vector(addr_width-2 downto 0); 
        addr_valid  : out std_logic 
    );
end dram_addr_gen;

architecture bhv of dram_addr_gen is

    type STATE_TYPE is (S_START, S_ADDR);
    signal state, next_state : STATE_TYPE;

    signal addr_current      : unsigned(addr_width-2 downto 0) := (others => '0');
    signal next_addr_current : unsigned(addr_width-2 downto 0);

    signal size_counter      : unsigned(addr_width downto 0) := (others => '0'); -- Counter for size
    signal next_size_counter : unsigned(addr_width downto 0);

begin

    process(clk, rst)
    begin
        if (rst = '1') then
            addr_current     <= (others => '0');
            size_counter     <= (others => '0');
            state            <= S_START;
        elsif rising_edge(clk) then
            addr_current     <= next_addr_current;
            size_counter     <= next_size_counter;
            state            <= next_state;
        end if;
    end process;

    process(go, stall, addr_start, addr_current, size, size_counter, state)
    begin
        addr_out          <= (others => '0');
        addr_valid        <= '0';
        next_addr_current <= addr_current;
        next_size_counter <= size_counter;
        next_state        <= state;

        case state is

            -- Wait for go signal
            when S_START =>
                next_addr_current <= unsigned(addr_start);
                next_size_counter <= unsigned(size);

                if go = '1' then
                    next_state <= S_ADDR;
                end if;

            -- Generate addresses
            when S_ADDR =>
                addr_out <= std_logic_vector(addr_current);

                if size_counter = 0 then
                    next_state <= S_START;
                elsif stall = '1' then
                    -- Stall: Hold the current address
                    next_addr_current <= addr_current;
                else
                    -- Normal operation: Increment address and decrement size counter
                    addr_valid        <= '1';
                    next_addr_current <= addr_current + 1;
                    next_size_counter <= size_counter - 1;
                end if;

            when others => null;

        end case;
    end process;

end bhv;
