--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   18:13:31 11/26/2020
-- Design Name:   
-- Module Name:   /home/tpillot/2SN/Archi/mini_projet/src/JOYSTICK/TestJoystick.vhd
-- Project Name:  MasterJoystick
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: MasterJoystick
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY TestJoystick IS
END TestJoystick;
 
ARCHITECTURE behavior OF TestJoystick IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT MasterJoystick
    PORT(
         rst : IN  std_logic;
         clk : IN  std_logic;
         en : IN  std_logic;
         led1 : IN  std_logic;
         led2 : IN  std_logic;
         miso : IN  std_logic;
         ss : OUT  std_logic;
         sclk : OUT  std_logic;
         mosi : OUT  std_logic;
         x : OUT  std_logic_vector(15 downto 0);
         y : OUT  std_logic_vector(15 downto 0);
         btn1 : OUT  std_logic;
         btn2 : OUT  std_logic;
         btnj : OUT  std_logic;
         busy : OUT  std_logic
        );
    END COMPONENT;
    
		COMPONENT SlaveJoystick
		generic(settings : natural);
		PORT(
			sclk : IN std_logic;
			mosi : IN std_logic;
			ss : IN std_logic;          
			miso : OUT std_logic
			);
		END COMPONENT;

   --Inputs
   signal rst : std_logic := '0';
   signal clk : std_logic := '0';
   signal en : std_logic := '0';
   signal led1 : std_logic := '0';
   signal led2 : std_logic := '0';
   signal miso : std_logic := '0';

 	--Outputs
   signal ss : std_logic;
   signal sclk : std_logic;
   signal mosi : std_logic;
   signal x : std_logic_vector(15 downto 0);
   signal y : std_logic_vector(15 downto 0);
   signal btn1 : std_logic;
   signal btn2 : std_logic;
   signal btnj : std_logic;
   signal busy : std_logic;

   -- Clock period definitions
   constant clk_period : time := 1 us; -- Pour avoir une clock à 1 Mhz
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: MasterJoystick PORT MAP (
          rst => rst,
          clk => clk,
          en => en,
          led1 => led1,
          led2 => led2,
          miso => miso,
          ss => ss,
          sclk => sclk,
          mosi => mosi,
          x => x,
          y => y,
          btn1 => btn1,
          btn2 => btn2,
          btnj => btnj,
          busy => busy
        );
				
		Inst_SlaveJoystick: SlaveJoystick 
		generic map(1)
		PORT MAP(
				sclk => sclk,
				mosi => mosi,
				miso => miso,
				ss => ss
			);

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
			rst <= '0';
      wait for 100 ns;	

			rst <= '1';
			en <= '1';
			
      wait for clk_period*10;
			en <= '0';

      -- insert stimulus here
			led1 <= '1';
			led2 <= '1';

      wait;
   end process;

END;
