library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

Library UNISIM;
use UNISIM.vcomponents.all;

entity waveform_viewer is
    port (
        i_clk : in std_logic;
        i_rst : in std_logic;
        
        o_cs_debug : out std_logic;
        i_miso : in std_logic;
        o_sclk : out std_logic;
        o_mosi : out std_logic;
        o_cs : out std_logic;
        
        o_uart_tx : out std_logic;
        o_rgb_red : out std_logic
        
    );
end waveform_viewer;

architecture Behavioral of waveform_viewer is   
    COMPONENT fifo_buffer
        PORT (
            wr_clk : IN STD_LOGIC;
            rd_clk : IN STD_LOGIC;
            din : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            wr_en : IN STD_LOGIC;
            rd_en : IN STD_LOGIC;
            dout : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            full : OUT STD_LOGIC;
            empty : OUT STD_LOGIC;
            valid : OUT STD_LOGIC
        );
    END COMPONENT;
    signal s_clk_count : integer := 0;
    signal s_sclk : std_logic := '0';
    signal s_sclk_n : std_logic := '1';
    signal s_adc_data : std_logic_vector(9 downto 0);
    signal s_adc_data_rdy : std_logic;
    signal s_fifo_out : std_logic_vector(7 downto 0);
    signal s_tx_busy, s_fifo_out_valid, s_rd_en : std_logic;
    signal s_baudrate_pulse, s_full, s_cs : std_logic;
begin

    o_rgb_red <= s_full;
    o_cs_debug <= s_cs;
    o_cs <= s_cs;

    sclk_gen: process(i_clk, i_rst)
    begin
        if i_rst = '0' then 
            s_clk_count <= 0;
        elsif rising_edge(i_clk) then
            if s_clk_count = 59 then 
                s_sclk <= not s_sclk;
                s_clk_count <= 0;
            else
                s_clk_count <= s_clk_count + 1;
            end if;
        end if;
    end process sclk_gen;
    
    s_sclk_n <= not s_sclk;
    
    ODDR2_inst : ODDR2
    generic map(
        DDR_ALIGNMENT => "NONE", -- Sets output alignment to "NONE", "C0", "C1" 
        INIT => '0', -- Sets initial state of the Q output to '0' or '1'
        SRTYPE => "SYNC") -- Specifies "SYNC" or "ASYNC" set/reset
    port map (
        Q => o_sclk, -- 1-bit output data
        C0 => s_sclk, -- 1-bit clock input
        C1 => s_sclk_n, -- 1-bit clock input
        CE => '1',  -- 1-bit clock enable input
        D0 => '1',   -- 1-bit data input (associated with C0)
        D1 => '0',   -- 1-bit data input (associated with C1)
        R => '0',    -- 1-bit reset input
        S => '0'     -- 1-bit set input
    );
    
    adc_interface: entity work.ADC_spi PORT MAP(
		i_start_adc => '1',
		i_sclk => s_sclk,
		i_rst => i_rst,
		i_miso => i_miso,
		o_mosi => o_mosi,
		o_cs => s_cs,
		o_rx_data => s_adc_data,
		o_rx_data_rdy => s_adc_data_rdy
	);
    
    s_rd_en <= s_fifo_out_valid and not s_tx_busy; 
    adc_data_buffer: fifo_buffer PORT MAP (
        wr_clk => s_sclk,
        rd_clk => s_baudrate_pulse,
        din => s_adc_data(9 downto 2),
        wr_en => s_adc_data_rdy,
        rd_en => s_rd_en,
        dout => s_fifo_out,
        full => s_full,
        empty => open,
        valid => s_fifo_out_valid
    );
    
    uart_interfacre: entity work.UART 
    GENERIC MAP(
        baud_rate => 19200,
        clk_freq => 12e6
    )
    PORT MAP(
		clk => i_clk,
		rst => i_rst,
		rx_in => '1',
		start_tx => s_fifo_out_valid,
		tx_data_in => s_fifo_out,
		auto_baud_en => '0',
		parity_en => '0',
		parity_select => '0',
        baudrate_pulse => s_baudrate_pulse,
		rx_tx_synced => open,
		rx_busy => open,
		tx_busy => s_tx_busy,
		rx_invalid => open,
		rx_data_out => open,
		tx_out => o_uart_tx
	);

end Behavioral;

