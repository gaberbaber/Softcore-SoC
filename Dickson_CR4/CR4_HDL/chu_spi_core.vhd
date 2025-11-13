library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity chu_spi_core is
   generic(S : integer := 2);
   port(
      clk      : in  std_logic;
      reset    : in  std_logic;
      -- io bridge interface
      cs       : in  std_logic;
      write    : in  std_logic;
      read     : in  std_logic;
      addr     : in  std_logic_vector(4 downto 0);
      rd_data  : out std_logic_vector(31 downto 0);
      wr_data  : in  std_logic_vector(31 downto 0);
      -- external signals
      spi_sclk : out std_logic;
      spi_mosi : out std_logic;
      spi_miso : in  std_logic;
      spi_ss_n : out std_logic_vector(S - 1 downto 0)
   );
end;

architecture arch of chu_spi_core is
   signal wr_en, wr_ss : std_logic;
   signal wr_ctrl      : std_logic;
   signal wr_spi       : std_logic;
   signal ctrl_reg     : std_logic_vector(31 downto 0);
   signal ss_n_reg     : std_logic_vector(S - 1 downto 0);
   signal spi_out      : std_logic_vector(7 downto 0);
   signal spi_ready    : std_logic;
   signal dvsr         : std_logic_vector(15 downto 0);
   signal cpol         : std_logic;
   signal cpha         : std_logic;
begin
   -- instantiate SPI unit
   spi_unit : entity work.spi
      port map(
         clk           => clk,
         reset         => reset,
         din           => wr_data(7 downto 0),
         dvsr          => dvsr,
         start         => wr_spi,
         cpol          => cpol,
         cpha          => cpha,
         dout          => spi_out,
         sclk          => spi_sclk,
         miso          => spi_miso,
         mosi          => spi_mosi,
         spi_done_tick => open,
         ready         => spi_ready
      );
   --registers
   process(clk, reset)
   begin
      if reset = '1' then
         ctrl_reg <= x"00000200";       -- dvsr=1028 (50 KHz sclk)  
         ss_n_reg <= (others => '1');   -- de-assert all ss_n
      elsif (clk'event and clk = '1') then
         if (wr_ctrl = '1') then
            ctrl_reg <= wr_data;
         end if;
         if (wr_ss = '1') then
            ss_n_reg <= wr_data(S - 1 downto 0);
         end if;
      end if;
   end process;
   -- decoding logic  
   wr_en   <= '1' when cs='1' and write='1' else '0';
   wr_ss   <= '1' when wr_en='1' and addr(1 downto 0)="01" else '0';
   wr_spi  <= '1' when wr_en='1' and addr(1 downto 0)="10" else '0';
   wr_ctrl <= '1' when wr_en='1' and addr(1 downto 0)="11" else '0';
   -- control signals 
   dvsr     <= ctrl_reg(15 downto 0);
   cpol     <= ctrl_reg(16);
   cpha     <= ctrl_reg(17);
   spi_ss_n <= ss_n_reg;
   -- read output 
   rd_data  <= x"00000" & "000" & spi_ready & spi_out;
end arch;
