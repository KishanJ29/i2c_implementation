	library ieee;
		use ieee.std_logic_1164.all;
		use ieee.Numeric_std.all;

entity DummyPiso is 
	port(	clk : in std_logic;
			rst :in std_logic;
			
			
			Data_Txn : in std_logic_vector(7 downto 0);
			SDA : inout std_logic
		);
end entity;

architecture test of DummyPiso is
	signal temp : std_logic_vector(7 downto 0);
	signal temp_Data:  unsigned(7 downto 0);
	signal WrCount  : integer range 0 to 8;
	signal piso_reg_Data: std_logic_vector(7 downto 0);
	signal a : std_logic;
begin
	SDA <= temp_data(7);
	temp <="10101010";
a <= and temp;
Data_PISO:	process(clk,rst)
			begin
			if(rst = '1')then
				piso_reg_Data <= Data_Txn;
				temp_Data <= unsigned(piso_reg_Data);				
			elsif(falling_edge(clk))then

					if(WrCount = 7)then
						WrCount <= 0;
					else
						temp_Data <= (shift_right((temp_data(7 downto 0)),1));			
						WrCount <= WrCount +1;
					end if ;
			end if;
			
			end process Data_PISO;


end test;