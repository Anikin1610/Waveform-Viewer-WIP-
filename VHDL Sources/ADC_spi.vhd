library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity ADC_spi is
    port (
        i_start_adc : in std_logic;
        i_sclk : in std_logic;
        i_rst : in std_logic;
        
        i_miso : in std_logic;
        o_mosi : out std_logic;
        o_cs : out std_logic;
        
        o_rx_data : out std_logic_vector(9 downto 0); 
        o_rx_data_rdy : out std_logic
    );
end entity ADC_spi;

architecture rtl of ADC_spi is
    type cmd_data_type is array (4 downto 0) of std_logic;
    signal cmd_data : cmd_data_type := ('1', '1', '0', '0', '0');

    signal s_cs : std_logic := '1';
    signal s_mosi : std_logic := '0';
    signal s_sclk, s_miso : std_logic;
    signal s_sclk_count : integer := 0;
    signal s_rx_sr : std_logic_vector(9 downto 0) := (others => '0');
    signal s_rx_data_ready : std_logic := '0';
     
begin

    s_sclk <= i_sclk;
    s_miso <= i_miso;
    o_mosi <= s_mosi;
    o_cs <= s_cs;
    o_rx_data_rdy <= s_rx_data_ready;
    o_rx_data <= s_rx_sr;
    
    sclk_counter_proc: process(s_sclk, i_rst)
    begin
        if i_rst = '0' then
            s_sclk_count <= 0;
        elsif rising_edge(s_sclk) then
            if s_sclk_count = 0 then 
                if i_start_adc = '1' then 
                    s_sclk_count <= s_sclk_count + 1;
                else
                    s_sclk_count <= 0;
                end if;
            elsif s_sclk_count < 18 then
                s_sclk_count <= s_sclk_count + 1;
            else
                s_sclk_count <= 0;
            end if;
        end if;
    end process sclk_counter_proc;

    mosi_proc: process(s_sclk)
    begin
        if i_rst = '0' then 
            s_cs <= '1';
            s_mosi <= '0';
        elsif falling_edge(s_sclk) then
            case s_sclk_count is
                when 0 =>
                    s_cs <= '1';
                    s_mosi <= '0';
                when 1 => 
                    s_cs <= '0';
                    s_mosi <= cmd_data(4);
                when 2 => 
                    s_cs <= '0';
                    s_mosi <= cmd_data(3);
                when 3 => 
                    s_cs <= '0';
                    s_mosi <= cmd_data(2);
                when 4 => 
                    s_cs <= '0';
                    s_mosi <= cmd_data(1);
                when 5 => 
                    s_cs <= '0';
                    s_mosi <= cmd_data(0);
                when others =>
                    s_cs <= '0';
                    s_mosi <= '0';
            end case;    
        end if;
    end process mosi_proc;

    miso_proc: process(s_sclk)
    begin
        if i_rst = '0' then 
            s_rx_sr <= (others => '0');
            s_rx_data_ready <= '0';    
        elsif falling_edge(s_sclk) then
            case s_sclk_count is
                when 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 =>
                    s_rx_sr <= s_rx_sr(8 downto 0) & s_miso;
                    if s_sclk_count = 18 then 
                        s_rx_data_ready <= '1';
                    else
                        s_rx_data_ready <= '0';
                    end if;
                when others =>
                    s_rx_sr <= s_rx_sr;
                    s_rx_data_ready <= '0';
            end case;
        end if;
    end process miso_proc;
end architecture rtl;