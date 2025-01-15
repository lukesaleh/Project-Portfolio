library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.all;
use work.config_pkg.all;
use work.user_pkg.all;

entity dram_rd is 
    port(
        dram_clk             : in  std_logic;
        user_clk             : in  std_logic;
        dram_rst             : in  std_logic;
        user_rst             : in  std_logic;
        go                   : in  std_logic;
        rd_en                : in  std_logic;
        stall                : in  std_logic;
        start_addr           : in  std_logic_vector (14 downto 0);
        size                 : in  std_logic_vector (16 downto 0);
        valid                : out std_logic;
        data                 : out std_logic_vector (15 downto 0);
        done                 : out std_logic;
        debug_count          : out std_logic_vector (16 downto 0);
        debug_dma_size       : out std_logic_vector (15 downto 0);
        debug_dma_start_addr : out std_logic_vector (14 downto 0);
        debug_dma_addr       : out std_logic_vector (14 downto 0);
        debug_dma_prog_full  : out std_logic;
        debug_dma_empty      : out std_logic;
        dram_ready           : in  std_logic;
        dram_rd_en           : out std_logic;
        dram_rd_addr         : out std_logic_vector (14 downto 0);
        dram_rd_data         : in  std_logic_vector (31 downto 0);
        dram_rd_valid        : in  std_logic
    );
end dram_rd;

architecture arch of dram_rd is 
    signal handshake_go : std_logic;
    signal size_translation : std_logic_vector(16 downto 0);
    signal prog_full : std_logic;
    signal addr_gen_stall : std_logic;
    signal dram_rd_addr_temp : std_logic_vector(14 downto 0);
    signal valid_temp  : std_logic;
    signal dram_rd_data_rev : std_logic_vector(31 downto 0);
    signal wr_rst_busy : std_logic;
    signal done_temp : std_logic;
    signal dram_done_flop : std_logic;
    signal rd_en_temp : std_logic;
    signal fifo_rst : std_logic;

    COMPONENT fifo_generator_0
    PORT (
        rst : IN STD_LOGIC;
        wr_clk : IN STD_LOGIC;
        rd_clk : IN STD_LOGIC;
        din : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        wr_en : IN STD_LOGIC;
        rd_en : IN STD_LOGIC;
        dout : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
        full : OUT STD_LOGIC;
        empty : OUT STD_LOGIC;
        prog_full : OUT STD_LOGIC;
        wr_rst_busy : OUT STD_LOGIC;
        rd_rst_busy : OUT STD_LOGIC
    );
    END COMPONENT;

begin

    --DEBUG SIGNALS HERE
    debug_count <= (others => '0');
    debug_dma_size <= size(15 downto 0);
    debug_dma_prog_full <= prog_full;
    debug_dma_addr <= dram_rd_addr_temp;
    debug_dma_start_addr <= start_addr;
    debug_dma_empty <= valid_temp;
    --END DEBUG SIGNALS

    dram_rd_addr <= dram_rd_addr_temp; 
    U_HANDHSAKE : entity work.handshake_new
    port map (
        clk_src => user_clk,
        clk_dest => dram_clk,
        rst => user_rst,
        go => go,
        rcv => handshake_go,
        delay_ack => C_0,
        ack => open
    );
    
    --Switch order of data bits as per video instructions
    dram_rd_data_rev <= dram_rd_data(15 downto 0) & dram_rd_data(31 downto 16);
    fifo_rst <= dram_rst or dram_done_flop;
    U_FIFO : fifo_generator_0
    PORT MAP (
        rst => fifo_rst,
        wr_clk => dram_clk,
        rd_clk => user_clk,
        din => dram_rd_data_rev,
        wr_en => dram_rd_valid,
        rd_en => rd_en_temp,
        dout => data,
        full => open,
        empty => valid_temp,
        prog_full => prog_full,
        wr_rst_busy => wr_rst_busy,
        rd_rst_busy => open
    );
    
    valid <= not valid_temp;
    addr_gen_stall <= not dram_ready or prog_full or wr_rst_busy; --NOTE: wr/rst busy signal somehow factors in here. When write busy is asserted, stall generator
    rd_en_temp <= rd_en and not valid_temp;
    
    U_ADDR_GEN : entity work.dram_addr_gen
    generic map (addr_width => 16)
    port map (
        clk => dram_clk,
        rst => dram_rst,
        go => handshake_go,
        size => size_translation,
        addr_start => start_addr,
        addr_out => dram_rd_addr_temp,
        stall => addr_gen_stall,
        addr_valid => dram_rd_en
    );

    process(size) -- Size translation process
    begin
        if (unsigned(size) mod 2) = 0 then
            size_translation <= std_logic_vector(shift_right(unsigned(size), 1));
        else
            size_translation <= std_logic_vector(shift_right(unsigned(size) +1, 1));
        end if;
    end process;

    U_COUNTER : entity work.counter 
    port map (
        clk => user_clk,
        rst => user_rst,
        rd_en => rd_en_temp,
        size => size,
        go => go,
        done => done_temp
    );
    done <= done_temp;
    --Dual flop to synchronize dram_done to the dram clock domain
    U_DRAM_DONE_FLOP : entity work.flop
    port map (
        clk => dram_clk,
        input => done_temp,
        output => dram_done_flop
    );
end arch;