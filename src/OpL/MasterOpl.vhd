library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity MasterOpl is
  port ( rst : in std_logic;                            -- Bouton C pour reset (actif à ’0’)
         clk : in std_logic;                            -- Horloge intégrée 100Mhz
         en : in std_logic;                             -- Indique qu’un ordre d’échange (émission/réception) d’1 octet est passé (actif à ’1’)
         v1 : in std_logic_vector (7 downto 0);         -- 1er octet opérande
         v2 : in std_logic_vector(7 downto 0);          -- 2ème octet opérande
         miso : in std_logic;                           -- Master Input Slave Output (produit par l'esclave)
         ss   : out std_logic;                          -- Slave Select (actif à ’0’)
         sclk : out std_logic;                          -- Serial clock (produit par le maître)
         mosi : out std_logic;                          -- Master Output Slave Input (produit par le maître)
         val_and : out std_logic_vector (7 downto 0);   -- v1 and v2
         val_or : out std_logic_vector (7 downto 0);    -- v1 or v2
         val_xor : out std_logic_vector (7 downto 0);   -- v1 xor v2
         busy : out std_logic);                         -- Indique que le composant est occupé à émettre/réceptionner (actif à ’1’)
end MasterOpl;

architecture behavior of MasterOpl is

    -- Echange d'un octet
    component er_1octet port map( 
        rst : in std_logic ;
        clk : in std_logic ;
        en : in std_logic ;
        din : in std_logic_vector (7 downto 0);     -- L’octet à émettre, sa valeur est fournie au moment où le composant est au repos et enable passe à '1'
        miso : in std_logic ;
        sclk : out std_logic ;
        mosi : out std_logic ;
        dout : out std_logic_vector (7 downto 0);   -- L’octet reçu une fois l’émission/réception terminée
        busy : out std_logic
    );
    end component;
    
    -- L'octet à émettre (v1, v2, ou 0)
    signal din : std_logic_vector(7 downto 0) := (others => '0');
    
    -- L’octet reçu une fois l’émission/réception terminée
    signal dout : std_logic_vector(7 downto 0) := (others => '0');
    
    -- Indique que le composant est occupé à émettre/réceptionner (actif à ’1’)
    signal busy : out std_logic;
    
    -- Etats possibles du Master
    type t_etat is (attente, echange);

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
        busy=>busy_er,
    );
    

    -- Envoi des données à l'esclave et récupération des résultats
    echange: process (clk, rst)
    
        -- Compteur décrémenté pendant l'attente
        variable cpt : natural := 0;
        
        -- Numéro de l'octet envoyé
        variable num_octet : natural := 0;
        
        -- Nombre d'octets total à envoyer
        constant NB_OCTETS : int := 3;
        
        -- Nombre de cycles d'horloge nécessaire pour que l'esclave soit prêt
        constant ATTENTE_ESCLAVE : int := 10;
        
        -- Nombre de cycles d'horloge à attendre avant l'envoi de l'octet suivant
        constant ATTENTE_ENVOI : int := 3;
    
    begin

        if (rst = '0') then

            -- Réinitialiser les signaux
            etat <= repos;
            ss <= '1';
            val_and <= "00000000";
            val_or <= "00000000";
            val_xor <= "00000000";
            busy <= '0';

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
                            when 0 =>
                                din_er <= v1;           -- Envoi du 1er octet
                            when 1 =>
                                din_er <= v2;           -- Envoi du 2ème octet
                            when others => null;
                        end case;
                        
                        en_er <= '1';                   -- Activer er_1octet pour échanger l'octet
                        etat <= echange;
                        
                    else
                        cpt := cpt - 1;                 -- On reste en attente
                        
                    end if;
                        
                when echange =>

                    if (!busy_er) then                  -- On vérifie que er_1octet a bien terminé son échange
                        case num_octet is
                            when 0 =>
                                val_and <= dout_er;     -- Réception du 1er octet
                                etat <= attente;
                            when 1 =>
                                val_or <= dout_er;      -- Réception du 2ème octet
                                etat <= attente;
                            when 2 =>
                                val_xor <= dout_er;     -- Réception du 3ème octet
                                ss <= '1';              -- Terminer la transmission
                                busy <= '0';            -- Le maitre n'est plus occupé
                                etat <= repos;          -- Retour dans l'état repos jusqu'à la prochaine transmission
                            when others => null;
                        end case;
                    
                        num_octet := num_octet + 1;
                        cpt := ATTENTE_ENVOI;           -- Attendre avant l'échange du prochain octet
                    end if;
                    
            end case;
            
        end if;
    
    end process;

end behavior;
