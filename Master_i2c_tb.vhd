	library ieee;
		use ieee.std_logic_1164.all;
		use ieee.Numeric_std.all;

entity Master_tb is
end entity;

architecture test of Master_tb is 
--	component Master_i2c is 
--		port(	clk : in std_logic;
--				rst :in std_logic;
--				enable : in std_logic;
--				
--				Data_Txn : in std_logic_vector(7 downto 0);
--				Addr : in std_logic_vector(7 downto 0);
--			--	RegAddrReq : in std_logic; --Request for Register Address 
--				Data_Rxn: out std_logic_vector(7 downto 0);
--				SDA : inout std_logic;
--				SCK : inout std_logic;
--				RegSnd : out std_logic
--			);
--	end component;
--
	signal clk_in : std_logic:='0';
	signal rst_in : std_logic;
	signal enable_in : std_logic;
	signal Data_Txn_in :  std_logic_vector(7 downto 0);
	signal Addr_in :  std_logic_vector(7 downto 0);
	signal Data_Rxn_in: std_logic_vector(7 downto 0);
	signal SDA_in : std_logic;
	signal SDA_Trig : std_logic;
	signal SDA_slave :std_logic;
	signal SCK_out : std_logic;
	signal RegSnd_out : std_logic;
	signal tb_count : integer := 0;
	signal Slave_Driver : std_logic;
	signal wr_count	: integer := 0;
	signal finished : std_logic:= '0';
	signal start : std_logic := '0';
	--signal  ClockPeriod : time := 0 ns;
	signal counter :  integer; 
	signal address :  std_logic_vector(7 downto 0):="10101011";
	signal reg :  std_logic_vector(7 downto 0):= "00000000";
	alias FsmClk is << signal .master_tb.Master_DUT.FSM_Clk :std_logic>>;
	alias LoadFlag is << signal .master_tb.Master_DUT.load :std_logic>>;
	begin 
	Master_DUT: entity work.Master_i2c port map(
								 clk => clk_in,
								 rst => rst_in,
								 enable => enable_in,
								 
								 Data_Txn => Data_Txn_in,
								 Addr => Addr_in ,
								 Data_Rxn => Data_Rxn_in,
								 SDA =>SDA_in,
								 SCK => SCK_out,
								 RegSnd => RegSnd_out
								);	
	
	
	clk_Process: process(clk_in,finished)
					begin
					clk_in <= not clk_in after 10 ns when finished /= '1' else '0';
				end process clk_process;

	Clock_Counter: process(Clk_in,tb_count)
					begin
					if rising_edge(Clk_in)then
						tb_count <= tb_count + 1;
					end if;
					if(tb_count < 200)then
						rst_in <= '1'; 
						enable_in <= '0';
					else
						rst_in <= '0';
						enable_in <= '1';
					end if;
					end process Clock_Counter;
 	
test_vector_generation: process(SCK_out) 
	 procedure definitions (constant Data_in  :in  std_logic_vector(7 downto 0);
							constant Addre_in : in std_logic_vector(7 downto 0))is
					begin
						start <= '1';
						Data_Txn_in <= Data_in;
						Addr_in <= Addre_in;

	 end procedure;
		    -- read from I2C bus
--			    procedure i2c_read (
--			      constant address : in  std_logic_vector(6 downto 0);
--			      signal data      : out std_logic_vector(7 downto 0)) is
--			    begin

--			      i2c_set_read;


--			      i2c_read_ack(ack);
--			      if ack = '0' then
--			        state_dbg <= 6;
--			        i2c_stop;
--			        return;
--			      end if;
--			      ack       <= '0';
--			      state_dbg <= 4;
--			      i2c_receive_byte(data);
--			      state_dbg <= 5;
--			      i2c_write_nack;
--			      state_dbg <= 6;
--			      i2c_stop;
--			    end procedure i2c_read;

	--Write
--    procedure i2c_write (
--		signal address : in std_logic_vector(7 downto 0);
--		signal reg :  std_logic_vector(7 downto 0):="00000000";
--		signal counter : out integer ) is
--		begin 
--			definitions (address,address);--( "10101011","11001101");
--			
--	end procedure;
		 begin 
					definitions ( address,"11001101");
				if(rst_in  = '1')then
					SDA_Trig <= '0';
					counter <= 0;
				elsif(rising_edge(SCK_out))then
					if(counter = 8)then 
						SDA_Trig <= '1';
						SDA_slave <= '0';
						counter <= 0;
					else
						SDA_Trig <= '1';
						counter <= counter + 1;
						reg <=  (SDA_slave & reg(7 downto 1));
						assert(address = reg) report "Write Failed" severity warning;
					end if;
			 end if;
	
		end process  test_vector_generation;
		SDA_in <= SDA_slave when counter = 8 else 'Z';
	end test;