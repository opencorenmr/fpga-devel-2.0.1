------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity acqPhaseCycleMemory is
  port(CLK, RST: in std_logic;
       CS: in std_logic;  -- chip select
       TOGGLE: in std_logic;
       INIT: in std_logic;
       TRIG: in std_logic;
       MODE: in std_logic_vector(1 downto 0);
       D: in std_logic_vector(9 downto 0);
       Q: out std_logic_vector(1 downto 0)
      );
end acqPhaseCycleMemory;

architecture RTL of acqPhaseCycleMemory is

  constant A0: std_logic_vector(1 downto 0):="00";
  constant A1: std_logic_vector(1 downto 0):="01";
  constant A2: std_logic_vector(1 downto 0):="10";
  signal stateReg: std_logic_vector(1 downto 0):=A0;
  signal currentCountReg: integer range 0 to 127;
  signal maxCountReg: integer range 1 to 128;
  type phram is array(0 to 127) of std_logic_vector(1 downto 0);
  signal ph: phram;

begin

  Q <= ph(currentCountReg);

  process(CLK)
    begin
      if (CLK'event and CLK='1') then
        if RST='1' then      
          currentCountReg <= 0;
        else
          if INIT='1' then currentCountReg <= 0;
          elsif TOGGLE='1' then
            if currentCountReg=maxCountReg-1 then currentCountReg <= 0;
            else currentCountReg <= currentCountReg+1;
            end if;
          end if;
        end if; --RST
      end if; -- CLK
    end process;

  process(CLK)
    begin
      if (CLK'event and CLK='1') then
        if RST='1' then 
          stateReg <= A0;
          maxCountReg <= 1;
        else
          case stateReg is
            when A0 =>
              if (TRIG='1' and CS='1') then
                case MODE is
                  when "00" => stateReg <= A0;
                  when "01" => stateReg <= A1;
                  when "10" => stateReg <= A2;
                  when others => stateReg <= A0;
                end case;
              end if;
            when A1 =>
              ph(currentCountReg) <= D(1 downto 0);
              stateReg <= A0;
            when A2 =>
              if to_Integer(unsigned(D))>128 then 
                maxCountReg <= 128;
                stateReg <= A0;
              elsif to_Integer(unsigned(D))=0 then
                maxCountReg <= 1;
                stateReg <= A0;
              else
                maxCountReg <= to_integer(unsigned(D));
                stateReg <= A0;
              end if;        
            when others => stateReg <= A0;
          end case;
        end if;
      end if; -- CLk
    end process;
end RTL;

------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity phaseCycleMemory is
  port(CLK, RST: in std_logic;
       CS: in std_logic;  -- chip select
       TOGGLE: in std_logic;
       INIT: in std_logic;
       TRIG: in std_logic;
       MODE: in std_logic_vector(1 downto 0);
       D: in std_logic_vector(9 downto 0);
       Q: out std_logic_vector(9 downto 0)
      );
end phaseCycleMemory;

architecture RTL of phaseCycleMemory is

  constant A0: std_logic_vector(1 downto 0):="00";
  constant A1: std_logic_vector(1 downto 0):="01";
  constant A2: std_logic_vector(1 downto 0):="10";
  signal stateReg: std_logic_vector(1 downto 0):=A0;
  signal currentCountReg: integer range 0 to 127;
  signal maxCountReg: integer range 1 to 128;
  type phram is array(0 to 127) of std_logic_vector(9 downto 0);
  signal ph: phram;

begin

  Q <= ph(currentCountReg);

  process(CLK)
    begin
      if (CLK'event and CLK='1') then
        if RST='1' then      
          currentCountReg <= 0;
        else
          if INIT='1' then currentCountReg <= 0;
          elsif TOGGLE='1' then
            if currentCountReg=maxCountReg-1 then currentCountReg <= 0;
            else currentCountReg <= currentCountReg+1;
            end if;
          end if;
        end if; --RST
      end if; -- CLK
    end process;

  process(CLK)
    begin
      if (CLK'event and CLK='1') then
        if RST='1' then 
          stateReg <= A0;
          maxCountReg <= 1;
        else
          case stateReg is
            when A0 =>
              if (TRIG='1' and CS='1') then
                case MODE is
                  when "00" => stateReg <= A0;
                  when "01" => stateReg <= A1;
                  when "10" => stateReg <= A2;
                  when others => stateReg <= A0;
                end case;
              end if;
            when A1 =>
              ph(currentCountReg) <= D;
              stateReg <= A0;
            when A2 =>
              if to_Integer(unsigned(D))>128 then 
                maxCountReg <= 128;
                stateReg <= A0;
              elsif to_Integer(unsigned(D))=0 then
                maxCountReg <= 1;
                stateReg <= A0;
              else
                maxCountReg <= to_integer(unsigned(D));
                stateReg <= A0;
              end if;        
            when others => stateReg <= A0;
          end case;
        end if;
      end if; -- CLk
    end process;
end RTL;
------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity pMux is
  port( CLK, RST: in std_logic;
        SEL: in std_logic_vector(3 downto 0);
        D0,D1,D2,D3,D4,D5,D6,D7,D8,D9,D10,D11,D12,D13,D14,D15: in std_logic_vector(9 downto 0);
        Q: out std_logic_vector(9 downto 0)
       );
end pMux;

architecture RTL of pMux is
signal QReg: std_logic_vector(9 downto 0);
begin
  process(CLK,RST) begin
    if (CLK'event and CLK='1') then
      if (RST='1') then QReg <= (others => '0');
      else
        case SEL is
          when "0000" => QReg <= D0;
          when "0001" => QReg <= D1;
          when "0010" => QReg <= D2;
          when "0011" => QReg <= D3;
          when "0100" => QReg <= D4;
          when "0101" => QReg <= D5;
          when "0110" => QReg <= D6;
          when "0111" => QReg <= D7;
          when "1000" => QReg <= D8;
          when "1001" => QReg <= D9;
          when "1010" => QReg <= D10;
          when "1011" => QReg <= D11;
          when "1100" => QReg <= D12;
          when "1101" => QReg <= D13;
          when "1110" => QReg <= D14;
          when "1111" => QReg <= D15;
        end case;
      end if; -- RST
    end if;-- CLK
  end process;
  
  Q <= QReg;
  
end RTL;
------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity phaseCycleMemoryArray is
  port(CLK,RST: in std_logic;
       ACQ_CS: in std_logic;   --  acq phase memory chip select
       SEL: in std_logic_vector(3 downto 0);
       TOGGLE: in std_logic;
       INIT: in std_logic;
       COMMAND: in std_logic;
       MODE: in std_logic_vector(1 downto 0);
       D: in std_logic_vector(9 downto 0); 
       Q: out std_logic_vector(9 downto 0);
       ACQ_Q: out std_logic_vector(1 downto 0)
   );
end phaseCycleMemoryArray;

architecture RTL of phaseCycleMemoryArray is

  component phaseCycleMemory
    port(CLK, RST: in std_logic;
         CS: in std_logic;
         TOGGLE: in std_logic;
         INIT: in std_logic;
         TRIG: in std_logic;
         MODE: in std_logic_vector(1 downto 0);
         D: in std_logic_vector(9 downto 0);
         Q: out std_logic_vector(9 downto 0)
        );
  end component;

  component acqPhaseCycleMemory is
    port(CLK, RST: in std_logic;
         CS: in std_logic;  -- chip select
         TOGGLE: in std_logic;
         INIT: in std_logic;
         TRIG: in std_logic;
         MODE: in std_logic_vector(1 downto 0);
         D: in std_logic_vector(9 downto 0);
         Q: out std_logic_vector(1 downto 0)
        );
  end component;

  component pMux is
    port( CLK, RST: in std_logic;
          SEL: in std_logic_vector(3 downto 0);
          D0,D1,D2,D3,D4,D5,D6,D7,
			 D8,D9,D10,D11,D12,D13,D14,D15: in std_logic_vector(9 downto 0);
          Q: out std_logic_vector(9 downto 0)
         );
  end component;


  signal QReg: std_logic_vector(9 downto 0);
  constant Q0Reg: std_logic_vector(9 downto 0):="0000000000";
  signal Q1Reg,Q2Reg,Q3Reg,Q4Reg,Q5Reg,Q6Reg,Q7Reg: std_logic_vector(9 downto 0);
  signal Q8Reg,Q9Reg,Q10Reg,Q11Reg,Q12Reg,Q13Reg,Q14Reg,Q15Reg: std_logic_vector(9 downto 0);
  signal selReg: std_logic_vector(15 downto 0);
  signal toggleReg, initReg, trigReg: std_logic;
  signal toggleStateReg, initStateReg, trigStateReg: std_logic;
  signal acqQreg: std_logic_vector(1 downto 0);

begin

  selReg <= "0000000000000001" when SEL="0000" else
            "0000000000000010" when SEL="0001" else
            "0000000000000100" when SEL="0010" else
            "0000000000001000" when SEL="0011" else
            "0000000000010000" when SEL="0100" else
            "0000000000100000" when SEL="0101" else
            "0000000001000000" when SEL="0110" else
            "0000000010000000" when SEL="0111" else
				"0000000100000000" when SEL="1000" else
            "0000001000000000" when SEL="1001" else
            "0000010000000000" when SEL="1010" else
            "0000100000000000" when SEL="1011" else
            "0001000000000000" when SEL="1100" else
            "0010000000000000" when SEL="1101" else
            "0100000000000000" when SEL="1110" else
            "1000000000000000" when SEL="1111";


  U0: pMux port map(
         CLK=>CLK, RST=>RST,
         SEL=>SEL,
         D0=>Q0Reg,D1=>Q1Reg,D2=>Q2Reg,D3=>Q3Reg,
         D4=>Q4Reg,D5=>Q5Reg,D6=>Q6Reg,D7=>Q7Reg,
         D8=>Q8Reg,D9=>Q9Reg,D10=>Q10Reg,D11=>Q11Reg,
         D12=>Q12Reg,D13=>Q13Reg,D14=>Q14Reg,D15=>Q15Reg,
         Q=>QReg
         );
  
  Q <= QReg;

  U1: phaseCycleMemory port map(
         CLK=>CLK, RST=>RST,
         CS=>selReg(1),
         TOGGLE=>toggleReg,
         INIT=>initReg,
         TRIG=>trigReg,
         MODE=>MODE,
         D=>D,
         Q=>Q1Reg);

  U2: phaseCycleMemory port map(
         CLK=>CLK, RST=>RST,
         CS=>selReg(2),
         TOGGLE=>toggleReg,
         INIT=>initReg,
         TRIG=>trigReg,
         MODE=>MODE,
         D=>D,
         Q=>Q2Reg);
  
  U3: phaseCycleMemory port map(
         CLK=>CLK, RST=>RST,
         CS=>selReg(3),
         TOGGLE=>toggleReg,
         INIT=>initReg,
         TRIG=>trigReg,
         MODE=>MODE,
         D=>D,
         Q=>Q3Reg);
  
  U4: phaseCycleMemory port map(
         CLK=>CLK, RST=>RST,
         CS=>selReg(4),
         TOGGLE=>toggleReg,
         INIT=>initReg,
         TRIG=>trigReg,
         MODE=>MODE,
         D=>D,
         Q=>Q4Reg);
  
  U5: phaseCycleMemory port map(
         CLK=>CLK, RST=>RST,
         CS=>selReg(5),
         TOGGLE=>toggleReg,
         INIT=>initReg,
         TRIG=>trigReg,
         MODE=>MODE,
         D=>D,
         Q=>Q5Reg);
  
  U6: phaseCycleMemory port map(
         CLK=>CLK, RST=>RST,
         CS=>selReg(6),
         TOGGLE=>toggleReg,
         INIT=>initReg,
         TRIG=>trigReg,
         MODE=>MODE,
         D=>D,
         Q=>Q6Reg);
  
  U7: phaseCycleMemory port map(
         CLK=>CLK, RST=>RST,
         CS=>selReg(7),
         TOGGLE=>toggleReg,
         INIT=>initReg,
         TRIG=>trigReg,
         MODE=>MODE,
         D=>D,
         Q=>Q7Reg);
			
  U8: phaseCycleMemory port map(
         CLK=>CLK, RST=>RST,
         CS=>selReg(8),
         TOGGLE=>toggleReg,
         INIT=>initReg,
         TRIG=>trigReg,
         MODE=>MODE,
         D=>D,
         Q=>Q8Reg);
			
  U9: phaseCycleMemory port map(
         CLK=>CLK, RST=>RST,
         CS=>selReg(9),
         TOGGLE=>toggleReg,
         INIT=>initReg,
         TRIG=>trigReg,
         MODE=>MODE,
         D=>D,
         Q=>Q9Reg);
			
  U10: phaseCycleMemory port map(
         CLK=>CLK, RST=>RST,
         CS=>selReg(10),
         TOGGLE=>toggleReg,
         INIT=>initReg,
         TRIG=>trigReg,
         MODE=>MODE,
         D=>D,
         Q=>Q10Reg);
			
  U11: phaseCycleMemory port map(
         CLK=>CLK, RST=>RST,
         CS=>selReg(11),
         TOGGLE=>toggleReg,
         INIT=>initReg,
         TRIG=>trigReg,
         MODE=>MODE,
         D=>D,
         Q=>Q11Reg);
			
  U12: phaseCycleMemory port map(
         CLK=>CLK, RST=>RST,
         CS=>selReg(12),
         TOGGLE=>toggleReg,
         INIT=>initReg,
         TRIG=>trigReg,
         MODE=>MODE,
         D=>D,
         Q=>Q12Reg);
			
  U13: phaseCycleMemory port map(
         CLK=>CLK, RST=>RST,
         CS=>selReg(13),
         TOGGLE=>toggleReg,
         INIT=>initReg,
         TRIG=>trigReg,
         MODE=>MODE,
         D=>D,
         Q=>Q13Reg);
			
  U14: phaseCycleMemory port map(
         CLK=>CLK, RST=>RST,
         CS=>selReg(14),
         TOGGLE=>toggleReg,
         INIT=>initReg,
         TRIG=>trigReg,
         MODE=>MODE,
         D=>D,
         Q=>Q14Reg);
			
  U15: phaseCycleMemory port map(
         CLK=>CLK, RST=>RST,
         CS=>selReg(15),
         TOGGLE=>toggleReg,
         INIT=>initReg,
         TRIG=>trigReg,
         MODE=>MODE,
         D=>D,
         Q=>Q15Reg);

  U16: acqPhaseCycleMemory port map(
         CLK=>CLK, 
         RST=>RST,
         CS=>ACQ_CS,
         TOGGLE=>toggleReg,
         INIT=>initReg,
         TRIG=>trigReg,
         MODE=>MODE,
         D=>D,
         Q=>acqQreg
        );

  ACQ_Q <= acqQreg;

  process(CLK) begin
    if(CLK'event and CLK='1') then
      if RST='1' then initReg<='0'; initStateReg <= '0'; else
        case initStateReg is
          when '0' => 
            if INIT='1' then 
              initReg<='1'; 
              initStateReg<='1'; 
            else 
              initReg<='0';
              initStateReg<='0'; 
            end if;
          when '1' =>
            initReg<='0';
            if INIT='0' then
              initStateReg<='0';
            else
              initStateReg<='1';
            end if;
        end case;
      end if; -- RST
    end if; -- CLK
  end process;

  process(CLK) begin
    if(CLK'event and CLK='1') then
      if RST='1' then toggleReg<='0'; toggleStateReg <= '0'; else
        case toggleStateReg is
          when '0' => 
            if TOGGLE='1' then 
              toggleReg<='1'; 
              toggleStateReg<='1'; 
            else 
              toggleReg<='0';
              toggleStateReg<='0'; 
            end if;
          when '1' =>
            toggleReg<='0';
            if TOGGLE='0' then
              toggleStateReg<='0';
            else
              toggleStateReg<='1';
            end if;
        end case;
      end if; -- RST
    end if; -- CLK
  end process;

  process(CLK) begin
    if(CLK'event and CLK='1') then
      if RST='1' then trigReg<='0'; trigStateReg <= '0'; else
        case trigStateReg is
          when '0' => 
            if COMMAND='1' then 
              trigReg<='1'; 
              trigStateReg<='1'; 
            else 
              trigReg<='0';
              trigStateReg<='0'; 
            end if;
          when '1' =>
            trigReg<='0';
            if COMMAND='0' then
              trigStateReg<='0';
            else
              trigStateReg<='1';
            end if;
        end case;
      end if; -- RST
    end if; -- CLK
  end process;


end RTL;
