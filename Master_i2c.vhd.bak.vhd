	library ieee;
		use ieee.std_logic_1164.all;
		use ieee.Numeric_std.all;

entity Master_i2c is 
	port(	clk : in std_logic;
			rst :in std_logic;
			enable : in std_logic;
			ReqRd_ReqWr : in std_logic;
			Data_Txn : in std_logic_vector(7 downto 0);
			Addr : in std_logic_vector(7 downto 0);
		--	RegAddrReq : in std_logic; --Request for Register Address 
			Data_Rxn: out std_logic_vector(7 downto 0);
			SDA : inout std_logic;
			SCK : out std_logic;
			RegSnd : out std_logic	-- Interupt to Send the Register Address
		);
end entity;

architecture behave of Master_i2c is 
	type state is (idle, start_bit, addr_get, ACK_Slave, Sub_Reg, cmd, Wr, Rd, Ack_Slave2, Ack_Master );
	signal curr_state : state;
	signal piso_out : std_logic;
	signal load : std_logic;
	signal loadData: std_logic;
	signal RdFlag : std_logic;
	signal AddrCount : integer range 0 to 8;
	signal WrCount : integer range 0 to 8;
	signal RdCount : integer range 0 to 8;
	signal piso_reg_Addr : unsigned(7 downto 0);
	signal piso_reg_Data : unsigned(7 downto 0);
	signal piso_reg : unsigned(7 downto 0);
	signal temp_Addr : unsigned(7 downto 0);
	signal temp_Data : unsigned(7 downto 0);
	signal temp : unsigned(7 downto 0);
	signal sckcount : integer range 0 to 124;
	
	begin
			piso_reg <= piso_reg_Addr or  piso_reg_Data;
			
Master_FSM: process(rst, SCK)
			begin

		if(rst = '1')then
			curr_state <= idle;
			load <= '0';
			--WrCount <= 0;
			SDA <= '1';
			RegSnd <= '0';	
			RdFlag <= '0';	
		elsif(falling_edge(sck))then
				case(curr_state)is
					when idle => 
								SDA <= '1';
								if(enable = '1')then
									curr_state <= start_bit;
									load <= '1';--
								else
									curr_state <= idle;
								end if;
					when start_bit =>
									temp_Addr <=piso_reg_Addr;
									SDA <= '0';
									curr_state <= addr_get;
									load <= '0';--
					when addr_get => 									
									
								if(AddrCount = 7)then
									SDA <= ReqRd_ReqWr;
									Curr_state <= ACK_Slave;
									RegSnd <= '1';	---- Interupt to Send the Register Address
									load <= '1';
								elsif(AddrCount < 7)then
									SDA <= piso_reg_Addr(0);
								end if;
								
					when ACK_Slave => 
								SDA <= '0';
								
--								if(SDA = '0')then
									curr_state <= Sub_Reg;
									load <= '0';
--								else
--									curr_state <= idle;
--								end if;
					when Sub_Reg => 
								
								if(AddrCount = 7)then
									--temp(7) <= Addr(0);
									SDA <= '0';
									Curr_state <= cmd;
								else
									SDA <= piso_reg_Addr(0);
								end if;
					when cmd =>	
								if(ReqRd_ReqWr = '0')then
									curr_state <= Wr;
									loadData <= '1';
								else 
									curr_state <= Rd;
								end if;									
					when WR => 
								loadData <= '0';
								if(WrCount = 7)then
								 	--WrCount <= 0;
									SDA <= piso_reg_Data(7);
									curr_state <= Ack_Slave2;
								else
									SDA <= piso_reg_Data(7);
									curr_state <= WR;
								end if;
					when RD => 	
								if(RdCount = 7)then
									RdCount <= 0;
									curr_state <= Ack_Master;	
						   		else
									RdCount <= RdCount +1;
									Data_Rxn <= (SDA & std_logic_vector(piso_reg_data(7 downto 1)));
									curr_state <= RD;
						   		end if; 
					when ACK_Slave2 =>
								if(SDA = '1' and ((enable ='1') and piso_reg(7)= '0'))then
										curr_state <= WR;											
 								
								else
									curr_state <= idle;
								end if;	
					when Ack_Master =>
								if((enable ='1') and (piso_reg(7)= '1'))then 
								SDA <= '0';
								curr_state <= RD;
								else 
								SDA <= '1';
								curr_state <= idle;
								end if;
					when Others => 
									curr_state <= Idle;

					end case;	
			 end if;
				end process Master_FSM;

Addr_PISO:	process(SCK,rst)
			begin
			if(rst = '1')then
				piso_reg_Addr <= "00000000";
				temp_Addr <= "00000000";
				AddrCount <= 0;
			elsif(falling_edge(SCK))then
				if(load ='1')then
			
					piso_reg_Addr <= unsigned(Addr);
					AddrCount <= 0;--Last added
				else
						if(AddrCount = 7)then
							AddrCount <= 0;
							--piso_reg_Data(7) <= ReqRd_ReqWr;
						else
							--piso_out <= piso_reg_Addr(7);
							piso_reg_Addr <= (shift_right((piso_reg_Addr(7 downto 0)),1));
							AddrCount <= AddrCount +1;
						end if;
				end if;
			end if;
			end process Addr_PISO;

Data_PISO:	process(SCK,rst)
			begin
			if(rst = '1')then
				piso_reg_Data <= "00000000";
				temp_Data <= "00000000";
				WrCount <= 0;				
			elsif(falling_edge(SCK))then
				if(loadData ='1')then
					piso_reg_Data <= unsigned(Data_Txn);
					WrCount <= 0;
				else
					if(WrCount = 7)then
						WrCount <= 0;
					else
						piso_reg_Data <= (shift_right(piso_reg_Data(7 downto 0),1));			
						WrCount <= WrCount +1;
					end if ;
				end if;
			end if;
			end process Data_PISO;
--
SCK_Defined:process(clk)
			begin
			if(rising_edge(clk))then
				if(enable = '0')then
					SCK <= '1';
					sckcount <= 0;
				elsif(enable = '1')then
					if(sckcount = 62)then
						sckcount <= 0;
						SCK <= not SCK;
					else
						sckcount <= sckcount + 1;
					end if;
				end if;
			end if;
			end process SCK_Defined;
end behave;