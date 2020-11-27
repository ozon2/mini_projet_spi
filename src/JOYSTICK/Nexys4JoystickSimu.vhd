library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

-- Nexys4Joystick avec le "faux" joystick simulé par SlaveJoystick
entity Nexys4JoystickSimu is
  port (
    -- les 16 switchs
    swt : in std_logic_vector (15 downto 0);
    -- les 5 boutons noirs
    btnC, btnU, btnL, btnR, btnD : in std_logic;
    -- horloge
    mclk : in std_logic;
    -- les 16 leds
    led : out std_logic_vector (15 downto 0);
    -- les anodes pour sélectionner les afficheurs 7 segments à utiliser
    an : out std_logic_vector (7 downto 0);
    -- valeur affichée sur les 7 segments (point décimal compris, segment 7)
    ssg : out std_logic_vector (7 downto 0)
  );
end Nexys4JoystickSimu;

architecture synthesis of Nexys4JoystickSimu is

  COMPONENT MasterJoystick
	PORT(
		rst : IN std_logic;
		clk : IN std_logic;
		en : IN std_logic;
		led1 : IN std_logic;
		led2 : IN std_logic;
		miso : IN std_logic;          
		ss : OUT std_logic;
		sclk : OUT std_logic;
		mosi : OUT std_logic;
		x : OUT std_logic_vector(15 downto 0);
		y : OUT std_logic_vector(15 downto 0);
		btn1 : OUT std_logic;
		btn2 : OUT std_logic;
		btnj : OUT std_logic;
		busy : OUT std_logic
		);
	END COMPONENT;

	COMPONENT diviseurClk
	generic(facteur : natural);
	PORT(
		clk : IN std_logic;
		reset : IN std_logic;          
		nclk : OUT std_logic
		);
	END COMPONENT;
	
	COMPONENT All7Segments
	PORT(
		clk : IN std_logic;
		reset : IN std_logic;
		e0 : IN std_logic_vector(3 downto 0);
		e1 : IN std_logic_vector(3 downto 0);
		e2 : IN std_logic_vector(3 downto 0);
		e3 : IN std_logic_vector(3 downto 0);
		e4 : IN std_logic_vector(3 downto 0);
		e5 : IN std_logic_vector(3 downto 0);
		e6 : IN std_logic_vector(3 downto 0);
		e7 : IN std_logic_vector(3 downto 0);          
		an : OUT std_logic_vector(7 downto 0);
		ssg : OUT std_logic_vector(7 downto 0)
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
	
	signal x : std_logic_vector(15 downto 0);
	signal y : std_logic_vector(15 downto 0);
	signal btn1 : std_logic;
	signal btn2 : std_logic;
	signal btnj : std_logic;
	signal clk1MHz : std_logic;
	signal jmiso : std_logic;          
	signal jss : std_logic;
	signal jsclk : std_logic;
	signal jmosi : std_logic;

begin

  -- valeurs des sorties
	
  -- leds éteintes
  led(15 downto 4) <= (others => '0');

  -- connexion du (des) composant(s) avec les ports de la carte
  
	Inst_MasterJoystick: MasterJoystick PORT MAP(
		rst => not btnC,
		clk => clk1MHz,
		en => swt(0),
		led1 => btnU,
		led2 => btnL,
		miso => jmiso,
		ss => jss,
		sclk => jsclk,
		mosi => jmosi,
		x => x,
		y => y,
		btn1 => led(0),
		btn2 => led(1),
		btnj => led(2),
		busy => led(3)
	);
	
	Inst_SlaveJoystick: SlaveJoystick 
	generic map(1)
	PORT MAP(
			sclk => jsclk,
			mosi => jmosi,
			miso => jmiso,
			ss => jss
		);
	
	Inst_diviseurClk: diviseurClk
	GENERIC MAP(100)
	PORT MAP(
		clk => mclk,
		reset => not btnC,
		nclk => clk1MHz
	);
	
	Inst_All7Segments: All7Segments PORT MAP(
		clk => mclk,
		reset => not btnC,
		e0 => x(3 downto 0),
		e1 => x(7 downto 4),
		e2 => x(11 downto 8),
		e3 => x(15 downto 12),
		e4 => y(3 downto 0),
		e5 => y(7 downto 4),
		e6 => y(11 downto 8),
		e7 => y(15 downto 12),
		an => an(7 downto 0),
		ssg => ssg(7 downto 0)
	);

end synthesis;
