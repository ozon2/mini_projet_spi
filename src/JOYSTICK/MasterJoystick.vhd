library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity MasterJoystick is
  port ( rst : in std_logic;                            -- Bouton C pour reset (actif à '0')
         clk : in std_logic;                            -- Horloge intégrée 100Mhz
         en : in std_logic;                             -- Indique qu'un ordre d'échange (émission/réception) d'1 octet est passé (actif à '1')
         led1 : in std_logic;         									-- Contrôle la LED1 du joystick (actif à '1')
         led2 : in std_logic;         									-- Contrôle la LED2 du joystick (actif à '1')
         miso : in std_logic;                           -- Master Input Slave Output (produit par l'esclave)
         ss   : out std_logic;                          -- Slave Select (actif à '0')
         sclk : out std_logic;                          -- Serial clock (produit par le maître)
         mosi : out std_logic;                          -- Master Output Slave Input (produit par le maître)
         x : out std_logic_vector (15 downto 0);   			-- Coordonnée x du joystick
         y : out std_logic_vector (15 downto 0);    		-- Coordonnée y du joystick
         btn1 : out std_logic;  												-- Le bouton 1 du joystick, appuyé à '1'
				 btn2 : out std_logic;  												-- Le bouton 2 du joystick, appuyé à '1'
				 btnj : out std_logic;  												-- Le bouton sur le joystick, appuyé à '1'
         busy : out std_logic);                         -- Indique que le composant est occupé à émettre/réceptionner (actif à '1')
end MasterJoystick;

architecture behavior of MasterJoystick is

    -- Echange d'un octet
    component er_1octet port(
        rst : in std_logic ;
        clk : in std_logic ;
        en : in std_logic ;
        din : in std_logic_vector (7 downto 0);     -- L'octet à émettre, sa valeur est fournie au moment où le composant est au repos et enable passe à '1'
        miso : in std_logic ;
        sclk : out std_logic ;
        mosi : out std_logic ;
        dout : out std_logic_vector (7 downto 0);   -- L'octet reçu une fois l'émission/réception terminée
        busy : out std_logic
    );
    end component;
    
    -- L'octet à émettre (v1, v2, ou 0)
    signal din_er : std_logic_vector(7 downto 0) := (others => 'U');
    
    -- L'octet reçu une fois l'émission/réception terminée
    signal dout_er : std_logic_vector(7 downto 0) := (others => 'U');
    
    -- Indique que le composant est occupé à émettre/réceptionner (actif à '1')
    signal busy_er : std_logic;

    -- Entrée de er_1octet
    signal en_er : std_logic := '0';
    
    -- Etats possibles du Master
    type t_etat is (repos, attente, echange);

    -- Etat actuel
    signal etat : t_etat;
    
begin

    -- Emission et réception de chaque octet
    er_1octet_Inst: er_1octet port map(
        rst=>rst,
        clk=>clk,
        en=>en_er,
        din=>din_er,
        miso=>miso,
        sclk=>sclk,
        mosi=>mosi,
        dout=>dout_er,
        busy=>busy_er
    );


    -- Envoi des données à l'esclave et récupération des résultats
    master: process (clk, rst)
    
        -- Compteur décrémenté pendant l'attente
        variable cpt : natural := 0;
        
        -- Numéro de l'octet envoyé
        variable num_octet : natural := 0;
        
        -- Nombre d'octets total à envoyer
        constant NB_OCTETS : natural := 3;
        
        -- Nombre de cycles d'horloge nécessaire pour que l'esclave soit prêt
				-- "The minimum recommended amount of time between the SS pin going low and the start of data transmission on the bus is 15μs."
        constant ATTENTE_ESCLAVE : natural := 13;
        
        -- Nombre de cycles d'horloge à attendre avant l'envoi de l'octet suivant
				-- "The minimum recommended amount of time between the end of one byte being shifted and the beginning of the next is 10μs."
        constant ATTENTE_ENVOI : natural := 8;
    
    begin

        if (rst = '0') then

            -- Réinitialiser les signaux
            etat <= repos;
            ss <= '1';
            busy <= '0';
						en_er <= '0';
						x <= (others => '0');
						y <= (others => '0');
						btn1 <= '0';
						btn2 <= '0';
						btnj <= '0';

        elsif (rising_edge(clk)) then
    
            case (etat) is
            
                when repos =>

                    if (en = '1') then
                    -- Un ordre a été passé au composant
                        ss <= '0';                      -- Initialiser la transmission
                        busy <= '1';                    -- Indiquer que le composant est occupé
                        cpt := ATTENTE_ESCLAVE;         -- Attendre que l'esclave soit prêt
                        num_octet := 0;
                        etat <= attente;
                        
                    end if;                             -- Le composant n'est pas actif, on reste en repos

                when attente =>
                
                    if (cpt = 0) then                   -- Fin de l'attente
                        case num_octet is
                            when 0 =>										-- Envoi du 1er octet qui permet d'allumer les LEDs du joystick
																din_er(0) <= led1;
																din_er(1) <= led2;
                                din_er(7 downto 2) <= "100000";
                            when others => null;				-- "The remaining four bytes that are shifted in are ignored by the PmodJSTK."
                        end case;
                        
                        en_er <= '1';                   -- Activer er_1octet pour échanger l'octet
                        etat <= echange;
                        
                    else
                        cpt := cpt - 1;                 -- On reste en attente
                        
                    end if;
                        
                when echange =>
                    if (busy_er = '0' and en_er = '0') then  -- On vérifie que er_1octet a bien terminé son échange
                        case num_octet is
                            when 0 =>
                                x(7 downto 0) <= dout_er;     -- Réception du 1er octet : l'octet de poids faible de la coordonnée x du joystick
                                etat <= attente;
                            when 1 =>
                                x(9 downto 8) <= dout_er(1 downto 0);    -- Réception du 2ème octet : l'octet de poids fort de la coordonnée x du joystick
                                etat <= attente;
                            when 2 =>
                                y(7 downto 0) <= dout_er;    	-- Réception du 3ème octet : l'octet de poids faible de la coordonnée y du joystick
                                etat <= attente;
														when 3 =>
																x(9 downto 8) <= dout_er(1 downto 0);    -- Réception du 4ème octet : l'octet de poids fort de la coordonnée y du joystick
																etat <= attente;
														when 4 =>
																-- Réception du 5ème octet : les boutons du joystick
																btnj <= dout_er(0);
																btn1 <= dout_er(1);
																btn2 <= dout_er(2);
																ss <= '1';              -- Terminer la transmission ("The SS pin should be returned high after communication has been completed.")
                                busy <= '0';            -- Le maitre n'est plus occupé
                                etat <= repos;          -- Retour dans l'état repos jusqu'à la prochaine transmission
                                en_er <= '0';           -- Fin de l'échange, on peut désactiver er_1octet
                            when others => null;
                        end case;
                    
                        num_octet := num_octet + 1;
                        cpt := ATTENTE_ENVOI;           -- Attendre avant l'échange du prochain octet
                            
                    else
                        en_er <= '0';                   -- Nécessaire pour différencier le début et la fin d'un échange
                    end if;
                    
            end case;
            
        end if;
    
    end process;

end behavior;
