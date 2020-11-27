library ieee;
    use ieee.std_logic_1164.all;

entity SlaveJoystick is
  generic(
    settings : natural := 0
  );
  port(
    sclk : in  std_logic;
    mosi : in  std_logic;
    miso : out std_logic;
    ss   : in  std_logic
  );
end SlaveJoystick;

--------------------------------------------------------------------------------

architecture behavioral of SlaveJoystick is

  -- donnees recues depuis le SPI:
  signal led2, led1 : std_logic;

  -- donnees a envoyer a travers le SPI:
  signal X, Y                 : std_logic_vector(9 downto 0);
  signal btn2, btn1, joystick : std_logic;

  signal bit_index_mosi : natural;  -- bit index dans l'octet a recevoir
  signal num_octet_mosi : natural;  -- index de l'octet a recevoir

  signal bit_index_miso : natural;  -- bit index dans l'octet a envoyer
  signal num_octet_miso : natural;  -- index de l'octet a envoyer

  ------------------------------------------------------------------------------
  -- synthesis TRANSLATE_OFF
  -- pour verifier les timings en simulation:
  signal verif_clk          : std_logic;
  constant verif_clk_period : time := 10 ns;  -- 100 MHz
  -- synthesis TRANSLATE_ON
  ------------------------------------------------------------------------------

begin

  -- donnees hardcodees en fonction d'un generic:
  --
  with settings select X <= "1000000000" when 0,      -- 512  = 0x200
                            "0001000010" when 1,      -- 66   = 0x42
                            "0000101010" when 2,      -- 42   = 0x2A
                            "0000000000" when 3,      -- 0    = 0x0
                            "1111111111" when 4,      -- 1024 = 0x400
                            "1010011010" when others; -- 666  = 0x29A
  --
  with settings select Y <= "0010010111" when 0,      -- 151  = 0x97
                            "1100110001" when 1,      -- 817  = 0x331
                            "0001111011" when 2,      -- 123  = 0x7B
                            "1101011000" when 3,      -- 856  = 0x358
                            "1010111000" when 4,      -- 696  = 0x2B8
                            "1100001001" when others; -- 777  = 0x309
  --
  with settings select btn2 <= '0' when 0,
                               '0' when 1,
                               '1' when 2,
                               '1' when 3,
                               '0' when 4,
                               '1' when others;
  --
  with settings select btn1 <= '0' when 0,
                               '1' when 1,
                               '0' when 2,
                               '1' when 3,
                               '0' when 4,
                               '1' when others;
  --
  with settings select joystick <= '1' when 0,
                                   '1' when 1,
                                   '1' when 2,
                                   '0' when 3,
                                   '0' when 4,
                                   '0' when others;

  -- process de capture sur front montant de sclk:
  capture : process(ss, sclk)
  begin
    if ( ss = '1' ) then  -- ss est un reset asynchrone
      bit_index_mosi <= 7;
      num_octet_mosi <= 0;

    elsif ( rising_edge(sclk) ) then
      -- comptage:
      if ( bit_index_mosi > 0 ) then
        bit_index_mosi <= bit_index_mosi - 1;
      else
        bit_index_mosi <= 7;
        --
        if ( num_octet_mosi < 5 ) then
          num_octet_mosi <= num_octet_mosi + 1;
        else
          num_octet_mosi <= 0;
        end if;
      end if;

      -- capture des entrees:
      case (num_octet_mosi) is
        when 0 =>
          -- capture des deux bits de poids faible:
          case (bit_index_mosi) is
            when 1      => led2 <= mosi;
            when 0      => led1 <= mosi;
            when others => null;
          end case;

          -- rien a capturer dans les 4 derniers octets:
        when others => null;
      end case;
    end if;
  end process;


  -- process de "presentation" sur front descendant de sclk:
  envoi : process(ss, sclk)
  begin
    if ( ss = '1' ) then  -- ss est un reset asynchrone
      bit_index_miso <= 7;
      num_octet_miso <= 0;

    elsif ( falling_edge(sclk) ) then
      -- comptage:
      if ( bit_index_miso > 0 ) then
        bit_index_miso <= bit_index_miso - 1;
      else
        bit_index_miso <= 7;
        --
        if ( num_octet_miso < 5 ) then
          num_octet_miso <= num_octet_miso + 1;
        else
          num_octet_miso <= 0;
        end if;
      end if;

      -- affectation des sorties:
      case (num_octet_miso) is
        when 0 =>
          case ( bit_index_miso ) is
            when 0      => miso <= X(0);
            when 1      => miso <= X(1);
            when 2      => miso <= X(2);
            when 3      => miso <= X(3);
            when 4      => miso <= X(4);
            when 5      => miso <= X(5);
            when 6      => miso <= X(6);
            when others => miso <= X(7);
          end case;

        when 1 =>
          case ( bit_index_miso ) is
            when 0      => miso <= X(8);
            when 1      => miso <= X(9);
            when others => miso <= '0';
          end case;

        when 2 =>
          case ( bit_index_miso ) is
            when 0      => miso <= Y(0);
            when 1      => miso <= Y(1);
            when 2      => miso <= Y(2);
            when 3      => miso <= Y(3);
            when 4      => miso <= Y(4);
            when 5      => miso <= Y(5);
            when 6      => miso <= Y(6);
            when others => miso <= Y(7);
          end case;

        when 3 =>
          case ( bit_index_miso ) is
            when 0      => miso <= Y(8);
            when 1      => miso <= Y(9);
            when others => miso <= '0';
          end case;

        when others =>
          case ( bit_index_miso ) is
            when 0      => miso <= joystick;
            when 1      => miso <= btn1;
            when 2      => miso <= btn2;
            when others => miso <= '0';
          end case;
      end case;
    end if;
  end process;

  ------------------------------------------------------------------------------
  -- synthesis TRANSLATE_OFF
  verif_clk_gen : process -- creation d'une horloge pour verifier les timings
  begin
    verif_clk <= '1';
    wait for verif_clk_period/2;
    verif_clk <= '0';
    wait for verif_clk_period/2;
  end process;

  -- verifie compter au moins jusqu'a 100/2 quand sclk est au niveau bas:
  verif_frequency : process(verif_clk)
    variable count : natural   :=  0;
  begin
    if ( rising_edge(verif_clk) ) then
      if ( sclk = '0' ) then
        count := count + 1;
      else
        if ( count > 0 and count < 100/2 ) then
          assert false
            report   "The maximum recommended SPI clock speed is 1 MHz."
            severity error;
        end if;
        count := 0;
      end if;
    end if;
  end process;

  -- verifie compter jusqu'a (15 * 100) apres le passage de ss a '0' avant que
  -- les bit index ou numero d'octet ne change:
  verif_start_time : process(verif_clk)
    variable count : natural := 0;
  begin
    if ( rising_edge(verif_clk) ) then
      if ( ss = '1' ) then
        count := 0;
      else
        if ( bit_index_miso /= 7 or num_octet_miso /= 0 ) then
          if ( count > 0 and count < 15*100 ) then
            assert false
              report "The minimum recommended amount of time between the SS pin going low and the start of data transmission on the bus is 15us."
              severity error;
          end if;
          count := 0;
        else
          count := count + 1;
        end if;
      end if;
    end if;
  end process;

  -- verifie compter jusqu'a (10 * 100) entre chaque envoi d'octet, c'est-a-dire
  -- pendant que bit_index_miso et bit_index_mosi sont egaux a 7.
  verif_between_time : process(verif_clk)
    variable count : natural := 0;
  begin
    if ( rising_edge(verif_clk) ) then
      if ( ss = '1' ) then
        count := 0;
      else
        if ( bit_index_miso /= 7 or bit_index_mosi /= 7 ) then
          if ( count > 0 and count < 10*100 ) then
            assert false
              report "The minimum recommended amount of time between the end of one byte being shifted and the beginning of the next is 10us."
              severity error;
          end if;
          count := 0;
        else
          count := count + 1;
        end if;
      end if;
    end if;
  end process;
  -- synthesis TRANSLATE_ON
  ------------------------------------------------------------------------------

end behavioral;

