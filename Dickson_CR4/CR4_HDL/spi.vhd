library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity spi is
   port(
      clk, reset    : in  std_logic;
      din           : in  std_logic_vector(7 downto 0);
      dvsr          : in  std_logic_vector(15 downto 0); 
      start         : in  std_logic;
      cpol, cpha    : in  std_logic;
      dout          : out std_logic_vector(7 downto 0);
      spi_done_tick : out std_logic;
      ready         : out std_logic;
      sclk          : out std_logic;
      miso          : in  std_logic;
      mosi          : out std_logic
   );
end spi;

architecture arch of spi is
   type statetype is (idle, p0, p1);
   signal state_reg       : statetype;
   signal state_next      : statetype;
   signal p_clk           : std_logic;
   signal c_reg, c_next   : unsigned(15 downto 0);
   signal spi_clk_next    : std_logic;
   signal spi_clk_reg     : std_logic;
   signal n_reg, n_next   : unsigned(2 downto 0);
   signal si_reg, si_next : std_logic_vector(7 downto 0);
   signal so_reg, so_next : std_logic_vector(7 downto 0);
begin
   -- registers
   process(clk, reset)
   begin
      if reset = '1' then
         state_reg   <= idle;
         si_reg      <= (others => '0');
         so_reg      <= (others => '0');
         n_reg       <= (others => '0');
         c_reg       <= (others => '0');
         spi_clk_reg <= '0';
      elsif (clk'event and clk = '1') then
         state_reg   <= state_next;
         si_reg      <= si_next;
         so_reg      <= so_next;
         n_reg       <= n_next;
         c_reg       <= c_next;
         spi_clk_reg <= spi_clk_next;
      end if;
   end process;
   -- next-state logic and data path
   process(state_reg,si_reg,so_reg,n_reg,c_reg,din,dvsr,start,cpha,miso)
   begin
      state_next    <= state_reg;
      ready         <= '0';
      spi_done_tick <= '0';
      si_next       <= si_reg;
      so_next       <= so_reg;
      n_next        <= n_reg;
      c_next        <= c_reg;
      case state_reg is
         when idle =>
            ready <= '1';
            if start = '1' then
               so_next    <= din;
               n_next     <= (others => '0');
               c_next     <= (others => '0');
               state_next <= p0;
            end if;
         when p0 =>
            if c_reg = unsigned(dvsr) then -- sclk 0-to-1
               state_next <= p1;
               si_next    <= si_reg(6 downto 0) & miso;
               c_next     <= (others => '0');
            else
               c_next <= c_reg + 1;
            end if;
         when p1 =>
            if c_reg = unsigned(dvsr) then -- sclk 1-to-0
               if n_reg = 7 then
                  spi_done_tick <= '1';
                  state_next    <= idle;
               else
                  so_next    <= so_reg(6 downto 0) & '0';
                  state_next <= p0;
                  n_next     <= n_reg + 1;
                  c_next     <= (others => '0');
               end if;
            else
               c_next <= c_reg + 1;
            end if;
      end case;
   end process;
   -- lookahead output decoding
   p_clk <= '1' when ((state_next = p1 and cpha = '0') or 
                      (state_next = p0 and cpha = '1')) else '0';
   spi_clk_next <= p_clk when (cpol = '0') else not p_clk;
   -- output
   dout  <= si_reg;
   mosi  <= so_reg(7);
   sclk  <= spi_clk_reg;
end arch;

