library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity FIR_50TAP_LPF is
port(
		clk              : in  std_logic;
		data_i           : in  std_logic_vector(31 downto 0);
		datavalid_i      : in  std_logic;
		data_o 	         : out std_logic_vector(31 downto 0);
		dataready_o      : out std_logic
	
);

end FIR_50TAP_LPF;

architecture Behavioral of FIR_50TAP_LPF is

component fpu is
    port (
        clk_i 			: in std_logic;
        -- Input Operands A & B
        opa_i        	: in std_logic_vector(31 downto 0);  -- Default: FP_WIDTH=32 
        opb_i           : in std_logic_vector(31 downto 0);

        -- fpu operations (fpu_op_i):
		-- ========================
		-- 000 = add, 
		-- 001 = substract, 
		-- 010 = multiply, 
		-- 011 = divide,
		-- 100 = square root
		-- 101 = unused
		-- 110 = unused
		-- 111 = unused
        fpu_op_i		: in std_logic_vector(2 downto 0);
        
        -- Rounding Mode: 
        -- ==============
        -- 00 = round to nearest even(default), 
        -- 01 = round to zero, 
        -- 10 = round up, 
        -- 11 = round down
        rmode_i 		: in std_logic_vector(1 downto 0);
        
        -- Output port   
        output_o        : out std_logic_vector(31 downto 0);
        
        -- Control signals
        start_i			: in std_logic; -- is also restart signal
        ready_o 		: out std_logic;
        
        -- Exceptions
        ine_o 			: out std_logic; -- inexact
        overflow_o  	: out std_logic; -- overflow
        underflow_o 	: out std_logic; -- underflow
        div_zero_o  	: out std_logic; -- divide by zero
        inf_o			: out std_logic; -- infinity
        zero_o			: out std_logic; -- zero
        qnan_o			: out std_logic; -- queit Not-a-Number
        snan_o			: out std_logic -- signaling Not-a-Number
	);   
end component;

signal 	opa_i           : std_logic_vector(31 downto 0) := (others => '0');
signal 	opb_i           : std_logic_vector(31 downto 0) := (others => '0');
signal 	fpu_op_i 	    : std_logic_vector(2 downto 0):= (others => '0');
signal 	rmode_i 		: std_logic_vector(1 downto 0):= (others => '0');
signal 	start_i 		: std_logic := '0';

signal  output_o	 : std_logic_vector(31 downto 0); 
signal  ready_o 	 : std_logic ;
signal  ine_o 		 : std_logic ;
signal  overflow_o   : std_logic ;
signal  underflow_o  : std_logic ;
signal  div_zero_o   : std_logic ;
signal  inf_o		 : std_logic ;
signal  zero_o		 : std_logic ;
signal  qnan_o		 : std_logic ;
signal  snan_o		 : std_logic ;


type table is array (0 to 50) of std_logic_vector(31 downto 0);

constant coeff : table := (x"36de8dd2",x"37a0cc8e",x"3631b4b4",x"b8ac6801",x"b921313f",
						   x"37977b75",x"39f9ce06",x"3a2b2931",x"b982cced",x"baf223af",
						   x"bafb6a3a",x"3aae254f",x"3bb3b41f",x"3b8d674e",x"bb9cd694",
						   x"bc5d4012",x"bc003f04",x"3c62bdc9",x"3cf31e25",x"3c41161c",
						   x"bd16bfc5",x"bd876725",x"bc75611d",x"3dffa152",x"3e8fe83a",
						   x"3eb2f701",x"3e8fe83a",x"3dffa152",x"bc75611d",x"bd876725",
						   x"bd16bfc5",x"3c41161c",x"3cf31e25",x"3c62bdc9",x"bc003f04",
						   x"bc5d4012",x"bb9cd694",x"3b8d674e",x"3bb3b41f",x"3aae254f",
						   x"bafb6a3a",x"baf223af",x"b982cced",x"3a2b2931",x"39f9ce06",
						   x"37977b75",x"b921313f",x"b8ac6801",x"3631b4b4",x"37a0cc8e",
						   x"36de8dd2");
signal dataarray : table := ((others => (others => '0')));

type states is (S_IDLE,S_PROCESS,S_DONE);
signal state : states := S_IDLE;

signal cntr          : integer range 0 to 63 := 0;
signal internalcntr	 : integer range 0 to 15 := 0;
signal i_sum 		 : std_logic_vector(31 downto 0) := (others => '0');

begin


P_MAIN : process(clk) begin 
if(rising_edge(clk)) then 

	case state is 
	
		when S_IDLE    =>
			
			if(datavalid_i = '1') then 
				dataarray(1 to 50) <= dataarray(0 to 49);
				dataarray(0) <= data_i;
				state <= S_PROCESS;
			else 
				state <= S_IDLE;
			end if;

		when S_PROCESS => 
			dataready_o <= '0';
			start_i  <= '0';
			
		if(cntr<=50) then 
			
			if(internalcntr = 0) then 
			
			opa_i <= dataarray(cntr); 
			opb_i <= coeff(cntr);
			start_i <= '1';
			fpu_op_i <= "010";
			rmode_i <= "00";
			internalcntr <= 1;
			
			elsif(internalcntr = 1) then
			
				if(ready_o = '1') then 
				  internalcntr <= 2;
				  start_i 	   <= '0';		
				  end if;
				
			elsif (internalcntr = 2) then 
				opa_i <= output_o; 
				opb_i <= i_sum; 
				start_i <= '1';
				fpu_op_i <= "000";
				rmode_i <= "00";
				internalcntr <= 3;
			
			elsif(internalcntr = 3) then
			
				if(ready_o = '1') then 
					cntr <= cntr + 1;
					internalcntr <= 0;
					start_i <= '0';
					i_sum <= output_o;
			     end if;
			
			end if; 
							
			elsif(cntr = 51) then
					cntr <= 52;
			elsif(cntr = 52) then
					cntr <= 53;
					data_o <= i_sum;
			elsif(cntr = 53) then
				cntr <= 0; 
				dataready_o <= '1';
				dataarray(1 to 50) <= dataarray(0 to 49);
				dataarray(0) <= data_i;
				i_sum <= (others => '0');
			else 
				state <= S_DONE;
			end if;
		when S_DONE    => 
			state <= S_IDLE;
	
	end case;
    
end if;
end process P_MAIN;

i_fpu : fpu 
port map (
        clk_i 		=> clk          ,
        opa_i        	=> opa_i        , 
        opb_i           => opb_i        , 
        fpu_op_i	=> fpu_op_i     ,
        rmode_i 	=> rmode_i      ,                
        output_o        => output_o     ,       
        start_i		=> start_i      ,
        ready_o 	=> ready_o      ,
        ine_o 		=> ine_o 	,	
        overflow_o  	=> overflow_o  	,
        underflow_o 	=> underflow_o 	,
        div_zero_o  	=> div_zero_o  	,
        inf_o		=> inf_o	,	
        zero_o		=> zero_o	,	
        qnan_o		=> qnan_o	,	
        snan_o		=> snan_o			
	);   

end Behavioral;
