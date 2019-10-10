	library ieee;
		use ieee.std_logic_1164.all;
		use ieee.Numeric_std.all;

entity slave is 
	port(	sclk : in std_logic;
			rst :in std_logic;
			Data_Txn : in std_logic_vector(7 downto 0);
			SDA : inout std_logic
		);
end entity;

architecture test of slave is
	--signal temp : std_logic_vector(7 downto 0);
	signal temp_Data:  unsigned(7 downto 0);
	signal WrCount  : integer range 0 to 8;
	signal piso_reg_Data: std_logic_vector(7 downto 0);
	signal a : std_logic;
	type state is (idle, addr_get, ACK_Slave, Sub_Reg, Ack_Reg, Wr, Rd, Ack_Slave2, Ack_Master );
	signal curr_state : state;
	signal sda_trig:std_logic := '0';
	signal SDA_slave:std_logic := '0';
begin
--	SDA <= temp_data(7);
	--temp <="10101010";
--a <= and temp;
SLAVE_FSM:	process(sclk,rst)
			begin
			if(rst = '1')then
				piso_reg_Data <= Data_Txn;
				temp_Data <= unsigned(piso_reg_Data);				
				WrCount <= 0;
			elsif(falling_edge(sclk))then
				case(curr_state)is
				when idle => if(SDA = '1')then
								curr_state <= addr_get;
							else 
								curr_state <= idle;	
							end if;	
							sda_trig <= '0';
				when addr_get =>						 
					if(WrCount = 7)then
						WrCount <= 0;
						curr_state <= ACK_Slave;
					else
						temp_Data <= (SDA & (temp_Data(7 downto 1)));
						WrCount <= WrCount +1;
					end if ;
				when ACK_Slave =>
						SDA_slave <= '0';
						sda_trig <= '1';
						curr_state <= idle;
				when others =>
						curr_state <= idle;
				end case;
			end if;
			end process SLAVE_FSM;
	SDA <= SDA_slave when sda_trig = '1' else 'Z';

end test;