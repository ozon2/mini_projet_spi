library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity er_1octet is
 port ( rst : in std_logic ;                        -- Bouton C pour reset (actif à ’0’)
        clk : in std_logic ;                        -- Horloge intégrée 100Mhz
        en : in std_logic ;                         -- Indique qu’un ordre d’échange (émission/réception) d’1 octet est passé (actif à ’1’)
        din : in std_logic_vector (7 downto 0);     -- L'octet à émettre
        miso : in std_logic ;                       -- Master Input Slave Output (produit par l'esclave)
        sclk : out std_logic ;                      -- Serial clock (produit par le maître)
        mosi : out std_logic ;                      -- Master Output Slave Input (produit par le maître)
        dout : out std_logic_vector (7 downto 0) ;  -- L'octet reçu une fois l’émission/réception terminée
        busy : out std_logic);                      -- Indique que le composant est occupé à émettre/réceptionner (actif à ’1’)
end er_1octet;

architecture behavioral_3 of er_1octet is

    -- États possibles lors de l'échange d'un octet
    type t_etat is (attente, capturer_bit, emettre_bit);
    
    -- État actuel
    signal etat : t_etat;

begin

     -- Échanger 1 octet
    er : process (clk, rst)
        
        
        variable cpt : integer range 0 to 7 := 0;
        variable registre : std_logic_vector (7 downto 0) := "00000000";
        
    begin

        if (rst = '0') then

            -- Retour dans l'état d'attente
            etat <= attente;
            sclk <= '1'; 
                
            -- Mise à zéro de tous les signaux et variables
            mosi <= '0';
            dout <= "00000000";
            busy <= '0';
            cpt := 0;
            registre := "00000000";

        elsif (rising_edge(clk)) then

            case etat is
                
                when attente =>
                    if (en = '1') then
                        busy <= '1';
                        sclk <= '0';
                        registre := din;        -- On copie din dans un registre car on a pas de garantie que din sera constant lors de la capture
                        cpt := 7;
                        mosi <= registre(cpt);	-- Pour ne pas perdre un cycle d'horloge on envoie le premier bit ici
                        etat <= capturer_bit;
                    end if; --en

                when capturer_bit =>
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
