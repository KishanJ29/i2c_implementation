	library ieee;
		use ieee.std_logic_1164.all;
		use ieee.Numeric_std.all;

entity Master_i2c is 
	port(	clk : in std_logic;
			rst :in std_logic;
			enable : in std_logic;
			
			Data_Txn : in std_logic_vector(7 downto 0);
			Addr : in std_logic_vector(7 downto 0);
		--	RegAddrReq : in std_logic; --Request for Register Address 
			Data_Rxn: out std_logic_vector(7 downto 0);
			SDA : inout std_logic;
			SCK : inout std_logic;
			RegSnd : out std_logic	-- Interupt to Send the Register Address
		);
end entity;

architecture behave of Master_i2c is 
	type state is (idle, start_bit, addr_get, ACK_Slave, Sub_Reg, Ack_Reg, Wr, Rd, Ack_Slave2, Ack_Master );
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
	signal sckcount : integer;
	signal FsmCount : integer;
	signal Temp_Rxn : std_logic_vector(7 downto 0);
	signal FSM_Clk :std_logic;
	signal SDA_int : std_logic;
	signal SDA_int_trig : std_logic;
	constant SCKCount_value : integer := 125; --The counter value for setting the baud rate
	begin
			piso_reg <= piso_reg_Addr or  piso_reg_Data;
Addr_PISO:	process(FSM_Clk,rst)
			begin
			if(rst = '1')then
				piso_reg_Addr <= "00000000";
				temp_Addr <= "00000000";
				AddrCount <= 0;
			elsif(falling_edge(FSM_Clk))then
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

WR_PISO:	process(SCK,rst)
			begin
			if(rst = '1')then
				piso_reg_Data <= "00000000";
				temp_Data <= "00000000";
				WrCount <= 0;
								
			elsif(falling_edge(SCK))then
				if(loadData ='1')then
					piso_reg_Data <= unsigned(Data_Txn);
					WrCount <= 0;

				elsif(loadData = '0')then
					if(WrCount = 7)then
						WrCount <= 0;
					else
						piso_reg_Data <= (shift_left(piso_reg_Data(7 downto 0),1));			
						WrCount <= WrCount +1;
					end if ;
				end if;
			end if;
			end process WR_PISO;
-------------------------------------------------------------------
--						SCK
-------------------------------------------------------------------
SCK_Defined:process(clk)
			begin
			if(rising_edge(clk))then
				if((curr_state = idle) or (curr_state = start_bit))then
					SCK <= '1';
					sckcount <= 0;
				else
					if(sckcount = SCKCount_value/2)then
						sckcount <= 0;
						SCK <= not SCK;
					else
--						SCK <= '1';
						sckcount <= sckcount + 1;
					end if;
				end if;
---------------------------------------------------------------
--				Clock for running the FSM	
---------------------------------------------------------------
				if(enable = '0')then
					FSM_Clk <= '1';
					FsmCount<= 0;
				elsif(enable = '1')then
					if(FsmCount = SCKCount_value/2 )then
						FsmCount <= 0;
						FSM_Clk <= not FSM_Clk;
					else
						FsmCount <= FsmCount + 1;
					end if;
				end if;
			end if;
			end process SCK_Defined;

-------------------------------------------------------------------
--					I2C Interface
-------------------------------------------------------------------
	SDA <= SDA_int when SDA_int_trig = '1' else 'Z';

-------------------------------------------------------------------
--				Master FSM
-------------------------------------------------------------------			
Master_FSM: process(rst, FSM_Clk)
			begin
		if(rst = '1')then
			curr_state <= idle;
			load <= '0';
			--WrCount <= 0;
			SDA_int <= '1';
			SDA_int_trig<= '1';
			RegSnd <= '0';	
			RdFlag <= '0';	
		elsif(falling_edge(FSM_Clk))then
				 
				case(curr_state)is
					when idle => 
								SDA_int <= '1';
								SDA_int_trig<= '1';
								if(enable = '1')then
									curr_state <= start_bit;
									load <= '1';
								else
									curr_state <= idle;
								end if;
					when start_bit =>
									temp_Addr <=piso_reg_Addr;
									RdFlag <= piso_reg_Addr(0);
									SDA_int <= '0';
									SDA_int_trig<= '1';
									curr_state <= addr_get;
									load <= '0';
					when addr_get => 									
								RdFlag <= piso_reg_Addr(7); --Read Flag
								if(AddrCount = 7)then
									SDA_int <= piso_reg_Addr(0);
									SDA_int_trig<= '0';
									
									Curr_state <= ACK_Slave;
									RegSnd <= '1';	---- Interupt to Send the Register Address
									load <= '1';
								elsif(AddrCount < 7)then
									SDA_int <= piso_reg_Addr(0);
									SDA_int_trig<= '1';
								end if;	
								
					when ACK_Slave => 
								
								assert( (SDA = 'Z')) report " Not Z" severity warning; 
								if((SDA = '0'))then
											
									curr_state <= Sub_Reg;
									load <= '0';
 								else
									curr_state <= idle;
								end if;
					when Sub_Reg => 				
								if(AddrCount = 7)then
									temp <= unsigned(Addr);
									SDA_int <= piso_reg_Addr(0);
									SDA_int_trig <= '0';
									Curr_state <= Ack_Reg;	
									else
									--temp <= Addr;
									SDA_int <= piso_reg_Addr(0);
									SDA_int_trig<= '1';
								end if;
					when Ack_Reg =>
								assert( (SDA = 'Z')) report " Not Z" severity warning; 
								if(SDA = '0')then
									if(RdFlag = '0')then
										curr_state <= Wr;
										loadData <= '1';
									else 
										curr_state <= Rd;
									end if;		
								else
									curr_state <= idle;											
								end if;
									--
					when WR => 
								loadData <= '0';
								if(WrCount = 7)then
								 	--WrCount <= 0;
									SDA_int <= piso_reg_Data(7);
									SDA_int_trig<= '0';
									curr_state <= Ack_Slave2;
								
								else
									SDA_int <= piso_reg_Data(7);
									SDA_int_trig<= '1';
									curr_state <= WR;
								end if;
					when RD => 
								if(RdFlag = '1')then 	
									if(RdCount = 7)then
										RdCount <= 0;
										Data_Rxn <= Temp_Rxn;
										curr_state <= Ack_Master;
										SDA_int_trig<= '0';
							   		else
										RdCount <= RdCount +1;
										Temp_Rxn <= (SDA_int & std_logic_vector(piso_reg_data(7 downto 1)));
										curr_state <= RD;
										SDA_int_trig<= '1';
							   		end if; 
								end if;
					when ACK_Slave2 =>
									
								if((temp = unsigned(Addr)) and (enable ='1') and (RdFlag = '0'))then
									loadData <= '1';
									curr_state <= WR;											
								elsif( RdFlag = '1')then
									curr_state <= Rd;
									loadData <= '1';

								else
									curr_state <= idle;
								end if;	
					when Ack_Master =>
								if((temp = unsigned(Addr)) and (enable ='1') and (RdFlag = '1'))then 
								SDA_int <= '0';
								curr_state <= RD;
								else 
								SDA_int <= '1';
								SDA_int_trig<= '1';
								curr_state <= idle;
								end if;
								
					when Others => 
								curr_state <= Idle;

					end case;	
			 end if;

			end process Master_FSM;



		
		
end behave;