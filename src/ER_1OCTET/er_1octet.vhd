library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity er_1octet is
  port ( rst : in std_logic ;
         clk : in std_logic ;
         en : in std_logic ;
         din : in std_logic_vector (7 downto 0);
         miso : in std_logic ;
         sclk : out std_logic ;
         mosi : out std_logic ;
         dout : out std_logic_vector (7 downto 0) ;
         busy : out std_logic);
end er_1octet;

architecture behavioral_3 of er_1octet is

	type t_etat is (attente, capturer_bit, emettre_bit);
  signal etat : t_etat;

begin

  er : process (clk, rst)
  -- échanger 1 octet
	
		variable cpt : integer range 0 to 7 := 0;
		variable registre : std_logic_vector (7 downto 0) := "00000000";
	
  begin

    if (rst = '0') then

      etat <= attente;
      sclk <= '1';
			mosi <= '0';
			dout <= "00000000";
			busy <= '0';
			cpt := 0;
			registre := "00000000";

    elsif (rising_edge(clk)) then

      case etat is
			
        when attente  =>
          if (en = '1') then
						busy <= '1';
						sclk <= '0';
						registre := din;
						cpt := 7;
						mosi <= registre(cpt);
						etat <= capturer_bit;
					end if; --en
					
        when capturer_bit  =>
					sclk <= '1';
					registre(cpt) := miso;
					if (cpt = 0) then
						busy <= '0';
						dout <= registre;
						etat <= attente;
					else -- cpt > 0
						etat <= emettre_bit;
					end if; --cpt
          
        when emettre_bit =>
					cpt := cpt - 1;
					mosi <= registre(cpt);
					sclk <= '0';
					etat <= capturer_bit;
          
      end case; --etat
    end if; --reset

  end process;

end behavioral_3;
