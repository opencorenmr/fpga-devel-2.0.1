
------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity TxBaudGen is
  port(CLK, RST, EN: in std_logic;
       BAUD: out std_logic
      );
end TxBaudGen;

architecture RTL of TxBaudGen is
signal stateReg: std_logic:='0';
constant L0: std_logic:='0';
constant L1: std_logic:='1';
signal baudCnt: integer range 0 to 520; -- 20M/38400bps = 521, 20M/460800 = 43

begin
  process(CLK)
  begin
    if (CLK'event and CLK='1') then
      if RST='1' then BAUD <= '0'; stateReg <= L0;
      else
        case stateReg is
          when L0 =>
            BAUD <= '0';
            if EN='0' then stateReg <= L0; 
            else baudCnt <= 0; stateReg <= L1;
            end if;
          when L1 =>
            baudCnt <= baudCnt + 1;
            if baudCnt = 520 then BAUD <= '1'; stateReg <= L0;
--            if baudCnt = 172 then BAUD <= '1'; stateReg <= L0;
            else stateReg <= L1;
            end if;
        end case;
      end if;
    end if; -- CLk
  end process;
end RTL;

--------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity Tx is
  port(CLK,RST,TRIG: in std_logic;
       D8: in std_logic_vector(7 downto 0);
       BUSY, TxD: out std_logic
     );
end Tx;

architecture RTL of Tx is

  component TxBaudGen
    port(CLK, RST, EN: in std_logic;
         BAUD: out std_logic
        );
  end component;

  signal stateReg: std_logic_vector(5 downto 0):="000000";
  constant L0:std_logic_vector(5 downto 0) :=    "000000";
  constant L1:std_logic_vector(5 downto 0) :=    "000001";
  constant b0:std_logic_vector(5 downto 0) :=    "000011";
  constant b1:std_logic_vector(5 downto 0) :=    "000111";
  constant b2:std_logic_vector(5 downto 0) :=    "001111";
  constant b3:std_logic_vector(5 downto 0) :=    "011111";
  constant b4:std_logic_vector(5 downto 0) :=    "111111";
  constant b5:std_logic_vector(5 downto 0) :=    "111110";
  constant b6:std_logic_vector(5 downto 0) :=    "111100";
  constant b7:std_logic_vector(5 downto 0) :=    "111000";
  constant STOP:std_logic_vector(5 downto 0) :=  "110000";
  constant DELAY:std_logic_vector(5 downto 0) := "100000";

  signal ENReg: std_logic;
  signal BusyReg: std_logic;
  signal TxReg: std_logic;
  signal D8Reg: std_logic_vector(7 downto 0);
  signal baudReg: std_logic;
  signal delayCNT: integer range 0 to 199;

begin
  U1: TxBaudGen port map(CLK=>CLK,RST=>RST,EN=>EnReg,BAUD=>BaudReg);
  TxD <= TxReg;
  BUSY <= BusyReg;

  process(CLK)
  begin
    if (CLK'event and CLK='1') then
      if (RST='1') then
         TxReg <= '1'; 
         ENReg <= '0';
         delayCNT <= 0;
         BusyReg <='0';  
         stateReg <= L0;
      else
        case stateReg is
          when L0 =>
            TxReg <= '1';
            ENReg <= '0'; 
            delayCNT <= 0; 
            BusyReg <='0';
            if trig='0' then stateReg <= L0; 
            else -- trig='1' 
              ENReg <= '1';
              TxReg <= '0';
              D8Reg <= D8;
              BusyReg <= '1';
              stateReg <= L1;               
            end if;
          when L1 =>
            if baudReg='1' then TxReg <= D8Reg(0); stateReg <= b0;
            else stateReg <= L1;
            end if;
          when b0 =>
            if baudReg='1' then TxReg <= D8Reg(1); stateReg <= b1;
            else stateReg <= b0;
            end if;
          when b1 =>
            if baudReg='1' then TxReg <= D8Reg(2); stateReg <= b2;
            else stateReg <= b1;
            end if;
          when b2 =>
            if baudReg='1' then TxReg <= D8Reg(3); stateReg <= b3;
            else stateReg <= b2;
            end if;
          when b3 =>
            if baudReg='1' then TxReg <= D8Reg(4); stateReg <= b4;
            else stateReg <= b3;
            end if;
          when b4 =>
            if baudReg='1' then TxReg <= D8Reg(5); stateReg <= b5;
            else stateReg <= b4;
            end if;
          when b5 =>
            if baudReg='1' then TxReg <= D8Reg(6); stateReg <= b6;
            else stateReg <= b5;
            end if;
          when b6 =>
            if baudReg='1' then TxReg <= D8Reg(7); stateReg <= b7;
            else stateReg <= b6;
            end if;
          when b7 =>
            if baudReg='1' then TxReg <= '1'; stateReg <= STOP; -- stop bit
            else stateReg <= b7;
            end if;
          when STOP =>
            if baudReg='1' then ENReg <='0'; stateReg <= DELAY;
            else stateReg <= STOP;
            end if;
          when DELAY =>
            delayCNT <= delayCNT + 1;
--            if delayCNT = 199 then BusyReg <= '0'; stateReg <= L0;
              if delayCNT = 19 then BusyReg <= '0'; stateReg <= L0;
            else stateReg <= DELAY;
            end if;
          when others =>  -- do nothing
        end case;
      end if;
    end if; -- CLK
  end process;

end RTL;



------------------------------------------------------------
--                        FIFO                            --
------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity FIFO is
  port(CLK: in std_logic;
       RST: in std_logic;
       DIN: in std_logic_vector(7 downto 0);
       DOUT: out std_logic_vector(7 downto 0);
       WEN: in std_logic;
       REN: in std_logic;
    --   OE: in std_logic;
       EF: out std_logic;
       FF: out std_logic);
end FIFO;

architecture RTL of FIFO is

type FIFOARRAY is array(0 to 63) of std_logic_vector(7 downto 0);

signal ramReg: FIFOARRAY;
signal wptrReg: integer range 0 to 63;
signal rptrReg: integer range 0 to 63 := 63;
signal eftmpReg: std_logic;
signal FFReg, EFReg: std_logic;

begin

--  DOUT<=ramReg(rptrReg) when OE='1' else (others=>'Z');
  DOUT<=ramReg(rptrReg); -- 2009.6.13
  FF<=FFReg;
  EF<=EFReg;

  process(CLK) begin
    if (CLK'event and CLK='1') then
      if (WEN='1' and FFReg='0') then
        ramReg(wptrReg)<=DIN;
      end if;
    end if;  -- CLK
  end process;

  process(CLK,RST) begin
    if (RST='1') then
      wptrReg <= 0;
    elsif(CLK'event and CLK='1') then
      if(WEN='1' and FFReg='0') then
        if (wptrReg=63) then wptrReg<=0; else wptrReg<=wptrReg+1; end if;
      end if;
    end if;
  end process;

  process(CLK,RST) begin
    if (RST='1') then
      rptrReg<=63;
    elsif(CLK'event and CLK='1') then
      if(REN='1' and EFReg='0') then
        if (rptrReg=63) then rptrReg<=0; else rptrReg<=rptrReg+1; end if;
      end if;
    end if;
  end process;

  process(CLK,RST) begin
    if(RST='1') then FFReg<='0';
    elsif(CLK'event and CLK='1') then
      if(wptrReg=rptrReg and WEN='1' and REN='0') then FFReg<='1';
      elsif(FFReg='1' and REN='1') then FFReg<='0';
      end if;
    end if; --RST
  end process;

  
  eftmpReg<='1' when (rptrReg=wptrReg-2 or (rptrReg=63 and wptrReg=1) or (rptrReg=62 and wptrReg=0))
                else '0';

  process(CLK,RST) begin
    if(RST='1') then EFReg<='1';
    elsif(CLK'event and CLK='1') then
      if(eftmpReg='1' and REN='1' and WEN='0') then EFReg<='1';
      elsif(EFReg='1' and WEN='1') then EFReg<='0';
      end if;
    end if; --RST
  end process;

end RTL;

------------------------------------------------------------

--------------------------------------------------
--          RS232C Rx Baud Generator            --
--------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity RxBaudGen is
  port(CLK,RST,EN: in std_logic;
       TRGOUT: out std_logic
      );
end RxBaudGen;

architecture RTL of RxBaudGen is

constant L0: std_logic_vector(1 downto 0):="00";
constant L1: std_logic_vector(1 downto 0):="01";
constant L2: std_logic_vector(1 downto 0):="10";
constant L3: std_logic_vector(1 downto 0):="11";

signal stateReg: std_logic_vector(1 downto 0):=L0;

signal cntReg: integer range 0 to 2083;
signal toReg: std_logic;
signal kReg: integer range 0 to 16;

begin
  process(CLK) begin
    if(CLK'event and CLK='1') then
      if (RST='1') then toReg <= '0'; stateReg <= L0;
      else case stateReg is
          when L0 => if (EN='0') then stateReg <= L0; 
                     else stateReg <= L1; cntReg <= 0; end if;
          when L1 => 
            cntReg <= cntReg + 1;
            if (cntReg=4) then  -- just for a moment 
              toReg <= '1'; 
              kReg <= 0;
              stateReg <= L2;
            else stateReg <= L1;
            end if;
                   
          when L2 =>
              toReg <= '0';
              cntReg <= 0;
            if (kReg = 9) then 
              stateReg <= L0;
            else
              stateReg <= L3;
            end if; 

          when L3 => 
            cntReg <= cntReg + 1;
            if (cntReg = 518) then -- 20M/(38400)
--            if (cntReg = 173) then 
              toReg <= '1';
              kReg <= kReg + 1;
              stateReg <= L2;
            else stateReg <= L3;
            end if;
          when others =>
        end case; 
      end if; -- RST,EN
    end if; -- CLK
  end process;
  TRGOUT <= toReg;
end RTL;

-------------------------------------
--        RS232C Rx main           --
-------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity Rx is
  port(CLK,RST,RxD: in std_logic;
       READY: out std_logic;
       Q8: out std_logic_vector(7 downto 0)
      );
end Rx;

architecture RTL of Rx is

  component RxBaudGen
    port(CLK,RST,EN: in std_logic;
         TRGOUT: out std_logic
        );
  end component;

  constant L0:std_logic_vector(5 downto 0) := "000000";
  constant L1:std_logic_vector(5 downto 0) := "000001";
  constant L2:std_logic_vector(5 downto 0) := "000011";
  constant b0:std_logic_vector(5 downto 0) := "000111";
  constant b1:std_logic_vector(5 downto 0) := "001111";
  constant b2:std_logic_vector(5 downto 0) := "011111";
  constant b3:std_logic_vector(5 downto 0) := "111111";
  constant b4:std_logic_vector(5 downto 0) := "111110";
  constant b5:std_logic_vector(5 downto 0) := "111100";
  constant b6:std_logic_vector(5 downto 0) := "111000";
  constant b7:std_logic_vector(5 downto 0) := "110000";
  constant L3:std_logic_vector(5 downto 0) := "100000";

  signal stateReg: std_logic_vector(5 downto 0) := L0;
  signal enReg, stReg, readyReg: std_logic;
  signal QReg: std_logic_vector(7 downto 0);

begin

  U1: RxBaudGen port map(CLK=>CLK, RST=>RST, EN => ENReg, TRGOUT => stReg);
  READY <= readyReg;
  Q8 <= QReg;

  process(CLK) begin
  if (CLK'event and CLK='1') then
    if (RST='1') then
      readyReg <= '0';
      enReg <= '0';
      QReg <= (others => '0');
      stateReg <= L0;
    else case stateReg is
        when L0 =>
          enReg <= '0';
          readyReg <= '0';
          if (RxD='0') then 
            enReg <='1'; 
            stateReg <= L1;
          else 
            stateReg <= L0;
          end if;
        when L1 => 
          enReg <= '0';
          if (stReg ='1') then stateReg <= L2; else stateReg <= L1; end if;
        when L2 => if (RxD = '1') then stateReg <= L0;
                   else stateReg <= b0; end if; 
        when b0 => if (stReg ='1') then QReg(0) <= RxD; stateReg <= b1;
                   else stateReg <= b0; end if;
        when b1 => if (stReg ='1') then QReg(1) <= RxD; stateReg <= b2;
                   else stateReg <= b1; end if;
        when b2 => if (stReg ='1') then QReg(2) <= RxD; stateReg <= b3;
                   else stateReg <= b2; end if;
        when b3 => if (stReg ='1') then QReg(3) <= RxD; stateReg <= b4;
                   else stateReg <= b3; end if;
        when b4 => if (stReg ='1') then QReg(4) <= RxD; stateReg <= b5;
                   else stateReg <= b4; end if;
        when b5 => if (stReg ='1') then QReg(5) <= RxD; stateReg <= b6;
                   else stateReg <= b5; end if;
        when b6 => if (stReg ='1') then QReg(6) <= RxD; stateReg <= b7;
                   else stateReg <= b6; end if;
        when b7 => if (stReg ='1') then 
                     QReg(7) <= RxD;
                     readyReg <= '1';
                     stateReg <= L3;
                   else stateReg <= b7; end if;

        when L3 =>
          readyReg <= '0';
          if (stReg='1') then stateReg <= L0; else stateReg <= L3; end if;  --  STOP BIT          

        when others => stateReg <= L0;
      end case;
    end if; -- RST
  end if; -- CLK
  end process;
end RTL;



------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity hexToA is
  port( CLK, RST, G: in std_logic;
        D: in std_logic_vector(3 downto 0);
        Q: out std_logic_vector(7 downto 0)
       );
end hexToA;

architecture RTL of hexToA is
signal DReg: std_logic_vector(3 downto 0);
signal QReg: std_logic_vector(6 downto 0);
begin
  process(CLK,RST) begin
    if (CLK'event and CLK='1') then
      if (RST='1') then QReg <= (others => '0');
      elsif (G='1') then
        case DReg is
          when "0000" => QReg <= "0110000"; -- "0" 0x30(48) 0011 0000
          when "0001" => QReg <= "0110001"; -- "1" 0x31(49) 0011 0001
          when "0010" => QReg <= "0110010"; -- "2" 0x32(50) 0011 0010
          when "0011" => QReg <= "0110011"; -- "3" 0x33(51) 0011 0011
          when "0100" => QReg <= "0110100"; -- "4" 0x34(52) 0011 0100
          when "0101" => QReg <= "0110101"; -- "5" 0x35(53) 0011 0101
          when "0110" => QReg <= "0110110"; -- "6" 0x36(54) 0011 0110
          when "0111" => QReg <= "0110111"; -- "7" 0x37(55) 0011 0111
          when "1000" => QReg <= "0111000"; -- "8" 0x38(56) 0011 1000
          when "1001" => QReg <= "0111001"; -- "9" 0x39(57) 0011 1001
          when "1010" => QReg <= "1000001"; -- "A" 0x41(65) 0100 0001
          when "1011" => QReg <= "1000010"; -- "B" 0x42(66) 0100 0010         
          when "1100" => QReg <= "1000011"; -- "C" 0x43(67) 0100 0011
          when "1101" => QReg <= "1000100"; -- "D" 0x44(68) 0100 0100
          when "1110" => QReg <= "1000101"; -- "E" 0x45(69) 0100 0101
          when "1111" => QReg <= "1000110"; -- "F" 0x46(70) 0100 0110              
          when others => QReg <= "ZZZZZZZ";
        end case;
      else QReg <= QReg; -- no change from the previous setting
      end if; -- RST
    end if;-- CLK
  end process;
  
  DReg <= D;
  Q(7) <= '0'; Q(6 downto 0) <= QReg;  

end RTL;

------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity aToHex is
  port( CLK, RST, G: in std_logic;
        D: in std_logic_vector(7 downto 0);
        Q: out std_logic_vector(3 downto 0)
       );
end aToHex;

architecture RTL of aToHex is
signal DReg: std_logic_vector(7 downto 0);
signal QReg: std_logic_vector(3 downto 0);
begin
  process(CLK,RST) begin
    if (CLK'event and CLK='1') then
      if (RST='1') then QReg <= (others => '0');
      elsif (G='1') then
        case DReg is
          when "00110000" => QReg <= "0000"; -- "0" 0x30(48) 0011 0000
          when "00110001" => QReg <= "0001"; -- "1" 0x31(49) 0011 0001
          when "00110010" => QReg <= "0010"; -- "2" 0x32(50) 0011 0010
          when "00110011" => QReg <= "0011"; -- "3" 0x33(51) 0011 0011
          when "00110100" => QReg <= "0100"; -- "4" 0x34(52) 0011 0100
          when "00110101" => QReg <= "0101"; -- "5" 0x35(53) 0011 0101
          when "00110110" => QReg <= "0110"; -- "6" 0x36(54) 0011 0110
          when "00110111" => QReg <= "0111"; -- "7" 0x37(55) 0011 0111
          when "00111000" => QReg <= "1000"; -- "8" 0x38(56) 0011 1000
          when "00111001" => QReg <= "1001"; -- "9" 0x39(57) 0011 1001
          when "01000001" => QReg <= "1010";
          when "01100001" => QReg <= "1010"; 
            -- "A" 0x41(65) 0100 0001  OR  "a" 0x61(97) 0110 0001  
          when "01000010" => QReg <= "1011"; 
          when "01100010" => QReg <= "1011";          
            -- "B" 0x42(66) 0100 0010  OR  "b" 0x62(98) 0110 0010 
          when "01000011" => QReg <= "1100";
          when "01100011" => QReg <= "1100";          
            -- "C" 0x43(67) 0100 0011  OR  "c" 0x63(99) 0110 0011  
          when "01000100" => QReg <= "1101"; 
          when "01100100" => QReg <= "1101";
            -- "D" 0x44(68) 0100 0100  OR  "d" 0x64(100) 0110 0100   
          when "01000101" => QReg <= "1110";
          when "01100101" => QReg <= "1110";         
            -- "E" 0x45(69)  0100 0101  OR  "e" 0x65(101) 0110 0101  
          when "01000110" => QReg <= "1111";
          when "01100110" => QReg <= "1111"; 
            -- "F" 0x46(70)  0100 0110  OR  "f" 0x66(102) 0110 0110
          when others => QReg <= "1111";
        end case;
      else QReg <= QReg; -- no change from the previous setting
      end if; -- RST
    end if;-- CLK
  end process;
  
  DReg <= D;
  Q <= QReg;  

end RTL;

------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity interface is
 generic(
       bitLength: natural;
       ppgAddressBits: natural;
		 maxComLength: natural:=1023
     );
  port(CLK, RST: in std_logic;
       RUN, WE: out std_logic;
       ADDRESS: out std_logic_vector(ppgAddressBits-1 downto 0);
	    CURRENTADDRESS: in std_logic_vector(ppgAddressBits-1 downto 0);
       Q112: out std_logic_vector(bitLength-1 downto 0);
       D112: in std_logic_vector(bitLength-1 downto 0);
       TxD: out std_logic;
       RxD: in std_logic;
       FINISH: in std_logic;
       CH1,CH2,CH3: out std_logic;
       PHRST: out std_logic;
       --
		 RS: out std_logic; -- repeat scan (bool)
		 AL: out std_logic_vector(31 downto 0);
		 NA: out std_logic_vector(31 downto 0);
		 ND: out std_logic_vector(31 downto 0); -- number of dummy scans (2015Jan28)
		 DW: out std_logic_vector(31 downto 0);
		 ST: out std_logic_vector(31 downto 0);
		 AF: out std_logic_vector(31 downto 0);
		 DO: out std_logic_vector(31 downto 0);
		 SR: out std_logic_vector(31 downto 0);
		 CO_ADDRESS: out std_logic_vector(9 downto 0);
		 CO_DATA: out std_logic_vector(11 downto 0);
		 CO_WR: out std_logic;
		 CO_LENGTH: out std_logic_vector(9 downto 0);
		 Tx_Busy: out std_logic
		 );
end interface;

architecture RTL of interface is

  component Tx
    port(CLK,RST,TRIG: in std_logic;
         D8: in std_logic_vector(7 downto 0);
         BUSY, TxD: out std_logic
        );
  end component;

  component Rx
    port(CLK,RST,RxD: in std_logic;
         READY: out std_logic;
         Q8: out std_logic_vector(7 downto 0)
        );
  end component;

  component FIFO
    port(CLK: in std_logic;
         RST: in std_logic;
         DIN: in std_logic_vector(7 downto 0);
         DOUT: out std_logic_vector(7 downto 0);
         WEN: in std_logic;
         REN: in std_logic;
      --   OE: in std_logic;
         EF: out std_logic;
         FF: out std_logic);
  end component;

  component hexToA
    port( CLK, RST, G: in std_logic;
          D: in std_logic_vector(3 downto 0);
          Q: out std_logic_vector(7 downto 0)
         );
  end component;

  component aToHex
    port( CLK, RST, G: in std_logic;
          D: in std_logic_vector(7 downto 0);
          Q: out std_logic_vector(3 downto 0)
         );
  end component;

  
-- state register
-- Reset
  constant L0: std_logic_vector(7 downto 0) := X"00";

-- command prompt
  constant A0: std_logic_vector(7 downto 0) := X"10";

  constant A0_1: std_logic_vector(7 downto 0) := X"11";
  constant A0_2: std_logic_vector(7 downto 0) := X"12";
  constant A0_3: std_logic_vector(7 downto 0) := X"13";
  constant A0_4: std_logic_vector(7 downto 0) := X"14";
  constant A0_5: std_logic_vector(7 downto 0) := X"15";
  constant A0_6: std_logic_vector(7 downto 0) := X"16";


  constant A1: std_logic_vector(7 downto 0) := X"17";
  constant A1_5: std_logic_vector(7 downto 0) := X"18";
  constant A2: std_logic_vector(7 downto 0) := X"19";
  constant A3: std_logic_vector(7 downto 0) := X"1A";

-- command reception
  constant B1: std_logic_vector(7 downto 0)   := X"20";
  constant B1_5: std_logic_vector(7 downto 0) := X"21";
  constant B1_6: std_logic_vector(7 downto 0) := X"22";
  constant B1_8: std_logic_vector(7 downto 0) := X"23";
  constant B2: std_logic_vector(7 downto 0)   := X"24";
  constant B2_5: std_logic_vector(7 downto 0) := X"25";
  constant B2_6: std_logic_vector(7 downto 0) := X"26";
  constant B3: std_logic_vector(7 downto 0)   := X"27";
  constant B4: std_logic_vector(7 downto 0)   := X"28";

-- START/STOP
  constant C1: std_logic_vector(7 downto 0) := X"30";

-- channel select
  constant S1: std_logic_vector(7 downto 0) := X"31";
  constant S2: std_logic_vector(7 downto 0) := X"32";

-- current running address
  constant AD1: std_logic_vector(7 downto 0) := X"39";
  constant AD2: std_logic_vector(7 downto 0) := X"3A";
  constant AD3: std_logic_vector(7 downto 0) := X"3B";
  constant AD4: std_logic_vector(7 downto 0) := X"3C";
  constant AD5: std_logic_vector(7 downto 0) := X"3D";
  constant AD6: std_logic_vector(7 downto 0) := X"3E";
  constant AD7: std_logic_vector(7 downto 0) := X"3F";

-- LIST
  constant D1: std_logic_vector(7 downto 0) := X"40";

  constant D1_5: std_logic_vector(7 downto 0) := X"41";

  constant D2: std_logic_vector(7 downto 0) := X"42";
  constant D3: std_logic_vector(7 downto 0) := X"43";
  constant D4: std_logic_vector(7 downto 0) := X"44";

  constant D4_5: std_logic_vector(7 downto 0) := X"45";

  constant D5: std_logic_vector(7 downto 0) := X"46";
  constant D6: std_logic_vector(7 downto 0) := X"47";

  constant D6_5: std_logic_vector(7 downto 0) := X"48";

  constant D7: std_logic_vector(7 downto 0) := X"49";
  constant D8: std_logic_vector(7 downto 0) := X"4A";
  constant D9: std_logic_vector(7 downto 0) := X"4B";
  constant D10:std_logic_vector(7 downto 0) := X"4C";

-- error
  constant E1: std_logic_vector(7 downto 0) := X"E0";
  constant E2: std_logic_vector(7 downto 0) := X"E1";
  constant E3: std_logic_vector(7 downto 0) := X"E2";
  constant E4: std_logic_vector(7 downto 0) := X"E3";
  constant E5: std_logic_vector(7 downto 0) := X"E4";
  constant E6: std_logic_vector(7 downto 0) := X"E5";

-- write memory
  constant W1: std_logic_vector(7 downto 0) := X"50";

  constant W1_5: std_logic_vector(7 downto 0) := X"51";

  constant W2: std_logic_vector(7 downto 0) := X"52";
  constant W3: std_logic_vector(7 downto 0) := X"53";

  constant W3_5: std_logic_vector(7 downto 0) := X"54";
  constant W3_6: std_logic_vector(7 downto 0) := X"55";

  constant W4: std_logic_vector(7 downto 0) := X"56";

  constant W4_5: std_logic_vector(7 downto 0) := X"57";

  constant W5: std_logic_vector(7 downto 0) := X"58";
  constant W6: std_logic_vector(7 downto 0) := X"59";
  constant W7: std_logic_vector(7 downto 0) := X"5A";

-- Messages
  constant M0: std_logic_vector(7 downto 0) := X"60";
  constant M1: std_logic_vector(7 downto 0) := X"61";
  constant M2: std_logic_vector(7 downto 0) := X"62";
  constant M3: std_logic_vector(7 downto 0) := X"63";
  constant M4: std_logic_vector(7 downto 0) := X"64";
  constant M5: std_logic_vector(7 downto 0) := X"65";
  
  signal stateReg: std_logic_vector(7 downto 0):=L0;

  type TSentence is array(0 to maxComLength) of std_logic_vector(7 downto 0);
  signal A: TSentence;
  
  type TMessage is array(0 to 63) of std_logic_vector(7 downto 0);
  type TMediumMessage is array(0 to 31) of std_logic_vector(7 downto 0);		
  type TShortMessage is array(0 to 15) of std_logic_vector(7 downto 0);
  type TVeryShortMessage is array(0 to 7) of std_logic_vector(7 downto 0);
  
  
  
  
  constant verInfo: TMessage := (
     X"0D", X"4F", X"50", X"45", X"4E", X"43", X"4F", X"52",
  --   <CR>   O      P      E      N      C      O      R
     X"45", X"20", X"4E", X"4D", X"52", X"20", X"20",
  --   E   <SPACE>   N      M      R    <SPACE> <SPACE>    
     X"62", X"75", X"69", X"6C", X"64", X"20", X"32", X"30", X"30", X"39",
  --   b      u      i      l      d   <SPACE>   2      0       0     9
     X"63", X"20", X"20", X"20",
  --   c <SPACE> <SPACE> <SPACE> 
  --   X"4D", X"52", X"49", X"20",
  --   M      R      I   <SPACE>
     X"32", X"30", X"31", X"36", X"20", X"41", X"70", X"72", X"20", X"20",
  --   2      0      1      6   <SPACE>   A      p      r  <SPACE>  <SPACE>
     X"62", X"79", X"20", X"4B", X"2E", X"20", X"54", X"61", X"6B", X"65", X"64", X"61",
  --   b      y    <SPACE>  K      .    <SPACE>  T      a      k      e      d      a
	  X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00"
  -- <NULL>
      );

	constant syntaxError: TMediumMessage := 
	(
	  X"0D",X"53",X"79",X"6E",X"74",X"61",X"78",X"20", -- <CR>Syntax<SPACE>
	  X"65",X"72",X"72",X"6F",X"72",X"3A",X"20",X"75", -- error:<SPACE>u
	  X"6E",X"6B",X"6E",X"6F",X"77",X"6E",X"20",X"63", -- nknown c
	  X"6F",X"6D",X"6D",X"61",X"6E",X"64",X"00",X"00"  -- ommand <NULL><NULL>
	);		
	
   constant buildNumber: TVeryShortMessage := (x"0D", x"32",x"30",x"30",x"39",x"00",x"00",x"00");	
	                                   -- <CR>  2     0     0     9    <NULL> <NULL> <NULL>

   constant clkFreq: TVeryShortMessage := (x"0D", x"31",x"36",x"30",x"00",x"00",x"00",x"00");	
	                               --  <CR>  1     6     0  <NULL> <NULL>
											 
   constant abortedMsg: TShortMessage := (
	  x"0D",x"41",x"62",x"6F",x"72",x"74",x"65",x"64", -- <CR>Aborted
	  x"2E",x"00",x"00",x"00",x"00",x"00",x"00",x"00"  -- .<NULL>
	);
   constant finishedMsg: TShortMessage := (
	  x"0D",x"46",x"69",x"6E",x"69",x"73",x"68",x"65", -- <CR>Finishe
	  x"64",x"2E",x"00",x"00",x"00",x"00",x"00",x"00"  -- d.<NULL>
	);
   constant startedMsg: TShortMessage := (
	  x"0D",x"53",x"74",x"61",x"72",x"74",x"65",x"64", -- <CR>Started
	  x"2E",x"00",x"00",x"00",x"00",x"00",x"00",x"00"  -- .<NULL>
	);
   constant arrayMsg: TShortMessage := (
	  x"0D",x"55",x"70",x"64",x"61",x"74",x"69",x"6E", -- <CR>Updatin
	  x"67",x"2E",x"2E",x"2E",x"00",x"00",x"00",x"00"  -- g...<NULL>
	);

	constant repeatScanStartedMsg: TMediumMessage := (
	  x"0D",x"52",x"65",x"70",x"65",x"61",x"74",x"20", -- <CR>Repeat<SPACE>
	  x"73",x"63",x"61",x"6E",x"20",x"73",x"74",x"61",  -- scan<SPACE>sta	
	  x"72",x"74",x"65",x"64",x"2E",x"00",x"00",x"00", -- rted.<NULL>
	  x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00"  -- 	
	);
	
	constant runningMsg: TMediumMessage := (
	  x"0D",x"41",x"6C",x"72",x"65",x"61",x"64",x"79", -- <CR>Already
	  x"20",x"72",x"75",x"6E",x"6E",x"69",x"6E",x"67",  -- <NULL>running	
	  x"2E",x"00",x"00",x"00",x"00",x"00",x"00",x"00", -- .<NULL>
	  x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00"  -- 	
	);
	
	constant notRunningMsg: TShortMessage := (
	  x"0D",x"4E",x"6F",x"74",x"20",x"72",x"75",x"6E", -- <CR>Not<SPACE>run
	  x"6E",x"69",x"6E",x"67",x"2E",x"00",x"00",x"00"  -- ning.<NULL>	
	);
	
	constant invalidChannelNumberMsg: TMediumMessage := (
	  x"0D",x"49",x"6E",x"76",x"61",x"6C",x"69",x"64", -- <CR>Invalid
	  x"20",x"63",x"68",x"61",x"6E",x"6E",x"65",x"6C", -- <SPACE>channel	
	  x"20",x"6E",x"75",x"6D",x"62",x"65",x"72",x"2E", -- <SPACE>number.
	  x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00" -- channel	
	);
													  
	constant invalidReadArgumentMsg: TMediumMessage := (
	  x"0D",x"49",x"6E",x"76",x"61",x"6C",x"69",x"64", -- <CR>Invalid
	  x"20",x"22",x"52",x"45",x"41",x"44",x"22",x"20", -- <SPACE>"READ"<SPACE>	
	  x"61",x"72",x"67",x"75",x"6D",x"65",x"6E",x"74", -- argument
	  x"2E",x"00",x"00",x"00",x"00",x"00",x"00",x"00"  -- .<NULL>	
	);
													  
	constant invalidSetArgumentMsg: TMediumMessage := (
	  x"0D",x"49",x"6E",x"76",x"61",x"6C",x"69",x"64", -- <CR>Invalid
	  x"20",x"22",x"53",x"45",x"54",x"22",x"20",x"61", -- <SPACE>"SET"<SPACE>a	
	  x"72",x"67",x"75",x"6D",x"65",x"6E",x"74",x"2E", -- rgument.
	  x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00"  -- <NULL>	
	);

	constant commanTooLongMsg: TMediumMessage := (
	  x"0D",x"43",x"6F",x"6D",x"6D",x"61",x"6E",x"64", -- <CR>Command
	  x"20",x"69",x"73",x"20",x"74",x"6F",x"6F",x"20", -- <SPACE>is<SPACE>too<SPACE>	
	  x"6C",x"6F",x"6E",x"67",x"2E",x"00",x"00",x"00", -- long.
	  x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00"  -- <NULL>	
	);
	

  type TByte is array(0 to (bitLength/4)-1) of std_logic_vector(3 downto 0);
  signal BD, BQ: TByte;

  signal bufLength: integer range 0 to maxComLength; -- keeps the length of A
  signal k1Reg, k2Reg, k3Reg, k4Reg, k5Reg, mReg: integer range 0 to maxComLength;  -- counter
  signal c1Reg: integer range 0 to maxComLength; -- counter used for "SET CO" (build2004, 20150728)
  signal wReg,wPlus4Reg: integer range 0 to 127;  -- counter (W) 20150728 new in build 2004
  constant wNReg: integer range 0 to 127 := (bitLength/4)-1;  -- 20150728
  signal dfLengthReg: integer range 0 to 1023;
  signal msg: integer range 0 to 15;  -- message ID (0: ver info, 1: build no, 2: clk freq)
  signal messageReg: std_logic_vector(7 downto 0);
  signal TxTrigReg: std_logic;
  signal TxD8Reg: std_logic_vector(7 downto 0);
  signal TxBusyReg: std_logic;
  signal RxReadyReg: std_logic;
  signal FIFORenReg, FIFOEmptyReg: std_logic;
--  signal FIFOFullReg: std_logic;
  signal RxD8Reg,FIFOD8Reg: std_logic_vector(7 downto 0);
  signal hexToAGReg: std_logic;
  signal HADReg: std_logic_vector(3 downto 0);
  signal HAQReg: std_logic_vector(7 downto 0);
  signal AHGReg: std_logic;
  signal AHxGReg: std_logic;
  signal AH1DReg: std_logic_vector(7 downto 0);
  signal AH2DReg: std_logic_vector(7 downto 0);
  signal AH3DReg: std_logic_vector(7 downto 0);
  signal AHxDReg: std_logic_vector(7 downto 0);
  signal AH1QReg: std_logic_vector(3 downto 0);
  signal AH2QReg: std_logic_vector(3 downto 0);
  signal AH3QReg: std_logic_vector(3 downto 0);
  signal AHxQReg: std_logic_vector(3 downto 0);
  signal runQReg: std_logic;
  signal weReg: std_logic;
  signal addressReg: std_logic_vector(ppgAddressBits-1 downto 0);
  signal Q112Reg: std_logic_vector(bitLength-1 downto 0);
  signal ch1Reg, ch2Reg, ch3Reg: std_logic;
  signal finishReg: std_logic;
  signal phRSTReg: std_logic;
  signal datBuf32Reg: std_logic_vector(31 downto 0);
  signal rsReg: std_logic;
  signal alReg,dwReg,naReg,ndReg,stReg,afReg,doReg,arReg,srReg: std_logic_vector(31 downto 0);
  signal arrayCountReg: std_logic_vector(31 downto 0);
  signal coAddressReg: std_logic_vector(9 downto 0);
  signal coDataReg: std_logic_vector(11 downto 0);
  signal coWRReg: std_logic;
  signal coLengthReg: std_logic_vector(9 downto 0);
  signal argReg: std_logic_vector(15 downto 0);
  signal arrayQReg: std_logic;
  
begin

  U1: Tx port map(CLK=>CLK,
                  RST=>RST,
                  TRIG=>TxTrigReg,
                  D8=>TxD8Reg,
                  BUSY=>TxBusyReg,
                  TxD=>TxD
                 );

  U2: Rx port map(CLK=>CLK,
                  RST=>RST,
                  RxD=>RxD,
                  READY=>RxReadyReg,
                  Q8=>RxD8Reg
                  );
  
  U3: hexToA port map(CLK=>CLK,
                      RST=>RST,
                      G=>hexToAGReg,
                      D=>HADReg,
                      Q=>HAQReg
                      );
  
  U4: aToHex port map(CLK=>CLK,
                      RST=>RST,
                      G=>AHGReg,
                      D=>AH1DReg,
                      Q=>AH1QReg);
  
  U5: aToHex port map(CLK=>CLK,
                      RST=>RST,
                      G=>AHGReg,
                      D=>AH2DReg,
                      Q=>AH2QReg);
  
  U6: aToHex port map(CLK=>CLK,
                      RST=>RST,
                      G=>AHGReg,
                      D=>AH3DReg,
                      Q=>AH3QReg);
  
  U7: aToHex port map(CLK=>CLK,
                      RST=>RST,
                      G=>AHxGReg,
                      D=>AHxDReg,
                      Q=>AHxQReg);

  U8: FIFO port map(CLK=>CLK,
                    RST=>RST,
                    DIN=>RxD8Reg,
                    DOUT=>FIFOD8Reg,
                    WEN=>RxReadyReg,
                    REN=>FIFORenReg,
         --           OE=>'1',
                    EF=>FIFOEmptyReg
--                    FF=>FIFOFullReg
                    );
						  
						  
  Tx_Busy <= TxBusyReg;						  

  RUN <= runQReg;
  WE <= weReg;
  ADDRESS <= addressReg;
  Q112 <= Q112Reg;
  CH1 <= ch1Reg;
  CH2 <= ch2Reg;
  CH3 <= ch3Reg;
  PHRST <= phRSTReg;

  finishReg <= FINISH;

  RS <= rsReg;
  
  AL <= alReg;
  DW <= dwReg;
  NA <= naReg;  
  ND <= ndReg;
  ST <= stReg;
  AF <= afReg;
  DO <= doReg;
  SR <= srReg;
  
  CO_ADDRESS <= coAddressReg;
  CO_DATA <= coDataReg;
  CO_WR <= coWRReg;
  CO_LENGTH <= coLengthReg;


  process(CLK) begin
  if (CLK'event and CLK='1') then
    for I in 0 to (bitLength/4)-1 loop
      BD(I) <= D112(bitLength-1-(I*4) downto bitLength-4-(I*4));
      Q112Reg(bitLength-1-(I*4) downto bitLength-4-(I*4)) <= BQ(I);
    end loop;
  end if;
  end process;



  process(CLK, rst) begin
  if (CLK'event and CLK='1') then
    if RST='1' then 
      runQReg <='0'; arrayQReg<='0'; arReg <= x"00000001";
		rsReg<='0';
      FIFORenReg<='0';
      ch1Reg <= '1'; ch2Reg <= '0'; ch3Reg <= '0';
		arrayQReg<='0';
	   arrayCountReg<=x"00000001";
		msg<=0; stateReg <= M0;  -- to version information
    elsif finishReg='1' then	 
      runQReg <='0';
		rsReg <= '0';
      FIFORenReg<='0';
		stateReg <= x"04";
    else
      case stateReg is
		  when x"04" =>
	       if(arrayCountReg=arReg) then
		      arrayQReg<='0';
	         arrayCountReg<=x"00000001";
		      msg<=4; -- finished message
            stateReg <= M0;		
		    else
		      arrayQReg<='1';
		      arrayCountReg <= arrayCountReg+'1';
		      msg<=14; -- array
		      stateReg <= M0;
		    end if;
		  
		  
        when L0 => 
          runQReg <='0';
			 rsReg <= '0';
          FIFORenReg<='0';
          stateReg <= A0;
        
    -- STAGE A: command prompt --
        when A0 =>
          AHGReg <= '0'; AHxGReg <= '0'; 
          weReg <= '0'; 
          hexToAGReg <= '0';
          phRSTReg <='0';  -- restore PHRST  (see C1)
          stateReg <= A0_1;

        when A0_1 =>
          TxD8Reg <= X"0D";  -- 0x0D (<CR>)
          TxTrigReg <= '1';
			 stateReg <= A0_2;

        when A0_2 =>
          TxTrigReg <= '0';
          stateReg <= A0_3;

       when A0_3 =>
          if TxBusyReg = '1' then stateReg <= A0_3;
          else stateReg <= A1;
          end if;

        when A1 => 
          if (runQReg='0') then  -- not running
            stateReg <= A1_5;
   			--TxD8Reg <= X"2A";  -- 0x2A (*)
            --TxTrigReg <= '1'; stateReg <= A2;
	       else  -- running
            TxD8Reg <= X"23";  -- 0x23 (#)
            TxTrigReg <= '1'; stateReg <= A2;
          end if;
			 
		  when A1_5 =>
		    if(arrayQReg='0') then
			   TxD8Reg <= X"2A";  -- 0x2A (*)
            TxTrigReg <= '1'; stateReg <= A2;
			 else
			   TxD8Reg <= X"25";  -- 0x25 (%)
            TxTrigReg <= '1'; stateReg <= A2;
			 end if;


		  when A2 =>
          TxTrigReg <= '0';
          stateReg <= A3;
        when A3 =>  -- wait for character transfer to be finished
          if TxBusyReg = '1' then stateReg <= A3;
          else bufLength <= 0; stateReg <= B1;
          end if;
    -- end of STAGE A --

    -- STAGE B: command reception --
        when B1 =>
          if FIFOEmptyReg='1' then 
            stateReg <= B1;
          else -- received a character from RS232C!
            FIFORenReg<='1';
            stateReg <= B1_5;
          end if;

        when B1_5 => 
          FIFORenReg<='0';          
          stateReg <= B1_6;

        when B1_6 => 
          stateReg <= B1_8;

        when B1_8 => 
          stateReg <= B2;

        when B2 =>
		    if(FIFOD8Reg >= X"61" and FIFOD8Reg <= X"7A") then
			   A(bufLength) <= FIFOD8Reg - X"20";  -- to upper case (20150119)
			 else
            A(bufLength) <= FIFOD8Reg; 
			 end if;	
				-- store the character in A
          bufLength <= bufLength + 1; -- increment the length of A
          stateReg <= B2_5;

        when B2_5 => 
          stateReg <= B2_6;

        when B2_6 => 
          stateReg <= B3;

        when B3 =>    
          if A(bufLength-1)=X"0D" then -- 0x0D <CR> code?
			   bufLength <= bufLength - 1; -- discard <CR>
            stateReg <= B4;
          elsif A(bufLength-1)=X"20" then -- 0x20 <SPACE> code?
            bufLength <= bufLength - 1; -- discard <SPACE>
            stateReg <= B1;
          else -- still supposed to receive another code from RS232C
            if bufLength = maxComLength then -- overflow?
              bufLength <= 0; msg<=12; stateReg <= M0; -- error
            else
              stateReg <= B1;
            end if;
          end if;

        when B4 => -- command recognition
          if bufLength=1 then stateReg <= C1; -- "G"(START) or "I"(STOP) or "V"(Version info)
			 elsif (bufLength=2 and A(0)&A(1)=X"5253") then stateReg<=X"33"; -- "RS" (Repeat Scan)
			 elsif (A(0)&A(1)&A(2)=X"534554") then -- "SET"
			   argReg <= A(3)&A(4); 
				stateReg<=X"70"; 
			 elsif (A(0)&A(1)&A(2)&A(3)=X"52454144") then --"READ"
				stateReg<=X"80";
			 
          elsif (bufLength=3 and A(0)&A(1)=X"4348") then  -- "CH1", "CH2", or "CH3"
            stateReg <= S1;
          elsif bufLength=4 then  -- "XXX>" LIST
            stateReg <= D1;
          elsif bufLength=4+(bitLength/4) then -- "XXX=CCAAAAAAAAAALLLLLLLLLLLLLLLL"
            stateReg <= W1;  
          elsif bufLength=0 then --  <CR> only
            stateReg <= A0;
			 
			 else
			   msg <= 8;
            stateReg <= M0;  -- error
--            stateReg <= E1;  -- error
          end if;
    -- end of STAGE B --
	 
	 -- Repeat Scan --
	     when X"33" =>
          if (runQReg='1') then
				msg<=6;   -- already running message
			   stateReg<=M0; 
			 else
            runQReg <= '1';
				rsReg <= '1'; -- activate Repeat Scan
            addressReg <= (others=>'0');
            phRSTReg <='1';   -- RST signal forward quadDDS20M
            msg<=13;  -- started message
        		stateReg <= M0;
			 end if;

    -- SET (new 2015 Jan)
	     when X"70" =>
		    case argReg is
			   when X"414C" => stateReg <= X"71"; -- AL
			   when X"4E41" => stateReg <= X"71"; -- NA
			   when X"4E44" => stateReg <= X"71"; -- ND
			   when X"4457" => stateReg <= X"71"; -- DW
			   when X"5354" => stateReg <= X"71"; -- ST
			   when X"4146" => stateReg <= X"71"; -- AF
				when X"444F" => stateReg <= X"71"; -- DO  Dc Offset
				when X"4152" => stateReg <= X"71"; -- AR
			   when X"434F" => stateReg <= X"77"; -- CO
				when X"5352" => stateReg <= X"71"; -- SR  Shift Right
			   when others => msg<=11; stateReg <= M0;  -- error			 
			 end case;
		 
	     when X"71" =>
		    if (bufLength=13) then k1Reg<=5; stateReg<=X"72"; 
			 else msg<=11; stateReg <= M0; end if;

		  when X"72" =>	 
          AH1DReg <= A(k1Reg);
          AHGReg <= '1';
          stateReg <= X"73";
        
        when X"73" => stateReg <= X"74"; -- 1 clock delay

        when X"74" =>
		    case k1Reg is
			   when 5 => datBuf32Reg(31 downto 28) <= AH1QReg; stateReg <= X"75";
			   when 6 => datBuf32Reg(27 downto 24) <= AH1QReg; stateReg <= X"75";
			   when 7 => datBuf32Reg(23 downto 20) <= AH1QReg; stateReg <= X"75";
			   when 8 => datBuf32Reg(19 downto 16) <= AH1QReg; stateReg <= X"75";
			   when 9 => datBuf32Reg(15 downto 12) <= AH1QReg; stateReg <= X"75";
			   when 10 => datBuf32Reg(11 downto 8) <= AH1QReg; stateReg <= X"75";
			   when 11 => datBuf32Reg(7 downto 4) <= AH1QReg; stateReg <= X"75";
			   when 12 => datBuf32Reg(3 downto 0) <= AH1QReg; stateReg <= X"75";
			   when 13 => stateReg <= X"76";
			   when others => stateReg <= A0; -- do nothing
			 
			 end case; -- k1Reg

        when X"75" => k1Reg <= k1Reg + 1; stateReg <= X"72";
        
        when X"76" => 
		    case argReg is
			   when X"414C" => alReg<=datBuf32Reg; stateReg <= A0; -- AL
			   when X"4E41" => naReg<=datBuf32Reg; stateReg <= A0; -- NA
				when X"4E44" => ndReg<=datBuf32Reg; stateReg <= A0; -- ND
			   when X"4457" => dwReg<=datBuf32Reg; stateReg <= A0; -- DW
			   when X"5354" => stReg<=datBuf32Reg; stateReg <= A0; -- ST
			   when X"4146" => afReg<=datBuf32Reg; stateReg <= A0; -- AF
				when X"444F" => doReg<=datBuf32Reg; stateReg <= A0; -- DO
				when X"5352" => srReg<=datBuf32Reg; stateReg <= A0; -- SR
				when X"4152" => arReg<=datBuf32Reg;
				                arrayCountReg<=x"00000001";
                            stateReg <= A0; -- AR
				
			   when others => msg<=11; stateReg <= M0;  -- error			 					
	       end case;
			 
		  when X"77" => 
		    c1Reg <= 5; 
			 coAddressReg <= "0000000000";
			 stateReg <= X"78";

		  when X"78" =>
		    if((c1Reg+2)>bufLength-1) then
			   coLengthReg <= coAddressReg;
			   stateReg<=A0;
			 else
			   stateReg <= X"79";
			 end if;
		  
		  when X"79"=>
          AH1DReg <= A(c1Reg);
          AH2DReg <= A(c1Reg+1);
          AH3DReg <= A(c1Reg+2);
          AHGReg <= '1';		  
		    stateReg <= X"7A";
			 
		  when X"7A" => stateReg <= X"7B";
		  
		  when X"7B" =>
		    coDataReg <= AH1QReg & AH2QReg & AH3QReg;
		    coWRReg <= '1';
			 stateReg <= X"7C";
			 
		  when X"7C" => coWRReg <= '0'; stateReg <= X"7D";		  
			
		  when X"7D" =>
		    c1Reg <= c1Reg+3;
			 coAddressReg <= coAddressReg+'1';
			 stateReg <= X"78"; 
			 
	 -- READ --
	     when X"80" =>
		    if(bufLength=6) then 
			   argReg <= A(4)&A(5);
				stateReg<=X"81"; 
			 else 
			   msg<=10; stateReg <= M0; 
			 end if;

			 when X"81" =>
		    case argReg is
			   when X"414C" => datBuf32Reg<=alReg; stateReg <= X"82"; -- AL
    		   when X"4E41" => datBuf32Reg<=naReg; stateReg <= X"82"; -- NA
				when X"4E44" => datBuf32Reg<=ndReg; stateReg <= X"82"; -- ND
			   when X"4457" => datBuf32Reg<=dwReg; stateReg <= X"82"; -- DW
			   when X"5354" => datBuf32Reg<=stReg; stateReg <= X"82"; -- ST
			   when X"4146" => datBuf32Reg<=afReg; stateReg <= X"82"; -- AF
			   when X"444F" => datBuf32Reg<=doReg; stateReg <= X"82"; -- DO
			   when X"4152" => datBuf32Reg<=arReg; stateReg <= X"82"; -- AR
				when X"5352" => datBuf32Reg<=srReg; stateReg <= X"82"; -- SR
			   when X"434F" => stateReg <= A0; -- CO
			   when others => msg<=10; stateReg <= M0;  -- error			 
			 end case;
		    
		  when X"82" => k2Reg <= 0; hexToAGReg<='1'; stateReg <= X"83";
		  
		  when X"83" =>
		    case k2Reg is 
			   when 0 => stateReg <= X"84";
			   when 1 => HADReg <= datBuf32Reg(31 downto 28); stateReg <= X"84";
			   when 2 => HADReg <= datBuf32Reg(27 downto 24); stateReg <= X"84";
			   when 3 => HADReg <= datBuf32Reg(23 downto 20); stateReg <= X"84";
			   when 4 => HADReg <= datBuf32Reg(19 downto 16); stateReg <= X"84";
			   when 5 => HADReg <= datBuf32Reg(15 downto 12); stateReg <= X"84";
			   when 6 => HADReg <= datBuf32Reg(11 downto 8); stateReg <= X"84";
			   when 7 => HADReg <= datBuf32Reg(7 downto 4); stateReg <= X"84";
			   when 8 => HADReg <= datBuf32Reg(3 downto 0); stateReg <= X"84";
				--when 9 => stateReg <= X"84";
		      when others => hexToAGReg<='0'; stateReg <= A0;
			 end case;
		  
	     when X"84" => stateReg <= X"85";
		  
		  when X"85" => -- send a character through RS232C
		     if (k2Reg=0) then TxD8Reg<=X"0D";
           else TxD8Reg <= HAQReg; end if;
           TxTrigReg <= '1';
           stateReg <= X"86";

        when X"86" => TxTrigReg <= '0'; stateReg <= X"87";

        when X"87" =>
           if TxBusyReg='1' then stateReg <= X"87";
           else stateReg <= X"88"; end if;

        when X"88" => k2Reg <= k2Reg + 1; stateReg <= X"83";
   

	
		 
		  
    -- STAGE C: START/STOP --
        when C1 =>
          case A(0) is      
            when X"47" =>  -- "G"
				  if (runQReg='1') then
				    msg<=6;   -- already running message
					 stateReg<=M0; 
				  else
                runQReg <= '1';
                addressReg <= (others=>'0');
                phRSTReg <='1';   -- RST signal forward quadDDS20M
                msg<=3;  -- started message
        			 stateReg <= M0;
				  end if;

            when X"49" =>  -- "I"
				  arrayQReg<='0';
        	     arrayCountReg<=x"00000001";
              if(runQReg='1') then
				    runQReg <= '0';
					 rsReg <= '0';
					 msg<=5;
					 stateReg <= M0;
				  else 
				    stateReg <= A0;
					 --msg<=7;  -- not running message
				    --stateReg <= M0;
				  end if;

	  		   when X"56" => msg<=0; stateReg <= M0; -- "V"
            when X"42" => msg<=1; stateReg <= M0; -- "B"
            when X"43" => msg<=2; stateReg <= M0; -- "C"
				when X"41" => 
              if (runQReg='0') then				
					 msg<=7;  -- not running message
				    stateReg <= M0;
				  else
                stateReg <= AD1; -- "A"
              end if;
				  
            when others => 
				  msg <= 8;
              stateReg <= M0;  -- error
              -- stateReg <= E1;
          end case;
     -- end of STAGE C --

     -- STAGE S: channel select --

         when S1 =>
           case A(2) is
             when X"31" => -- "CH1"
               ch1Reg<='1'; ch2Reg<='0'; ch3Reg<='0';
               stateReg <= A0;
             when X"32" => -- "CH2"
               ch1Reg<='0'; ch2Reg<='1'; ch3Reg<='0';
               stateReg <= A0;
             when X"33" => -- "CH3"
               ch1Reg<='0'; ch2Reg<='0'; ch3Reg<='1';
               stateReg <= A0;
             when others =>
				   msg<=9;
               stateReg <= M0;
           end case; 

     -- end of STAGE S --
	  
	  
         when AD1 =>
			  k3Reg <= 0;
			  hexToAGReg <= '1';
			  stateReg <= AD2;
			
			when AD2 =>
			  if k3Reg = 0 then
			    stateReg <= AD3;
           elsif k3Reg = 1 then 
             HADReg <= '0' & currentAddress(10 downto 8); stateReg <= AD3;
			  elsif k3Reg=2 then 
            HADReg <= currentAddress(7 downto 4); stateReg <= AD3;
			  elsif k3Reg=3 then 
            HADReg <= currentAddress(3 downto 0); stateReg <= AD3;
           else 
             stateReg <= A0;
           end if;

         when AD3 => stateReg <= AD4;

         when AD4 => -- Send a character through RS232C
			  if (k3Reg=0) then TxD8Reg<=X"0D"; else TxD8Reg <= HAQReg; end if;
           TxTrigReg <= '1';
           stateReg <= AD5;

         when AD5 => TxTrigReg <= '0'; stateReg <= AD6;

         when AD6 =>
           if TxBusyReg='1' then stateReg <= AD6;
           else stateReg <= AD7; end if;

         when AD7 => k3Reg <= k3Reg + 1; stateReg <= AD2;

     -- STAGE D: LIST --
         when D1 =>
           if (runQReg='1' or A(3)/=X"3E") then
             -- Forbid this operation while sequence is running.
             -- Also A(3) must be 0x3E(>), 
             --        otherwise this must be a syntax error.
             stateReg <= E1; 
           else -- Asci to hexadecimal conversion
             AH1DReg <= A(0);
             AH2DReg <= A(1);
             AH3DReg <= A(2);
             AHGReg <= '1';
             stateReg <= D1_5;
           end if;

         when D1_5 => stateReg <= D2;
         
         when D2 =>
           addressReg <= AH1QReg(2 downto 0) & AH2QReg & AH3QReg;
--           addressReg <= AH1QReg(1 downto 0) & AH2QReg & AH3QReg;
           stateReg <= D3;
         
         when D3 => stateReg <= D4; -- just for 1-clock delay

         when D4 => -- Hex to Asci conversion (DATA)
           k4Reg <= 0;
           hexToAGReg <= '1';
           stateReg <= D4_5;
         
         when D4_5 => stateReg <= D5; -- just for 1-clock delay

      
         when D5 =>
           if k4Reg < bitLength/4 then 
             HADReg <= BD(k4Reg); stateReg <= D6;
           else 
             stateReg <= D10;
           end if;

         when D6 => stateReg <= D6_5;

         when D6_5 => -- Send a character through RS232C
           TxD8Reg <= HAQReg;
           TxTrigReg <= '1';
           stateReg <= D7;

         when D7 => TxTrigReg <= '0'; stateReg <= D8;

         when D8 =>
           if TxBusyReg='1' then stateReg <= D8;
           else stateReg <= D9; end if;

         when D9 => k4Reg <= k4Reg + 1; stateReg <= D5;

         when D10 => stateReg <= A0;

     -- end of STAGE D --

     -- STAGE E: error --
         when E1 =>
             TxD8Reg <= X"0D"; -- 0x0D(<CR>)
             TxTrigReg <= '1';
             stateReg <= E2;

         when E2 => TxTrigReg <= '0'; stateReg <= E3;

         when E3 => 
           if TxBusyReg='1' then stateReg <= E3;
           else stateReg <= E4; end if;

         when E4 =>
           TxD8Reg <= X"3F"; -- 0x3F(?)
           TxTrigReg <= '1';
           stateReg <= E5;

         when E5 => TxTrigReg <= '0'; stateReg <= E6;

         when E6 => 
           if TxBusyReg='1' then stateReg <= E6;
           else stateReg <= A0; end if;

     -- end of STAGE E --

     -- STAGE W: write memory --
         when W1 =>
           if (runQReg='1' or A(3)/="00111101") then
             -- Forbid this operation while sequence is running.
             -- Also A(3) must be 0x3D(=), 
             --        otherwise this must be a syntax error.
             stateReg <= E1; 
           else -- Asci to hexadecimal conversion (10-bit ADDRESS)
             AH1DReg <= A(0);
             AH2DReg <= A(1);
             AH3DReg <= A(2);
             AHGReg <= '1';
             stateReg <= W1_5;
           end if;

         when W1_5 => stateReg <= W2;

         when W2 =>
           addressReg <= AH1QReg(2 downto 0) & AH2QReg & AH3QReg;
--           addressReg <= AH1QReg(1 downto 0) & AH2QReg & AH3QReg;
           wReg <= 0; wPlus4Reg <= 4;
           stateReg <= W3;
       
         when W3 =>
           AHxGReg <= '0';
           stateReg <= W3_5;

         when W3_5 => stateReg <= W3_6;
         when W3_6 => stateReg <= W4;

         when W4 => 
           AHxDReg <= A(wPlus4Reg);  -- from 4 to 31 (39) 
           stateReg <= W4_5;
           AHxGReg <= '1';
          
         when W4_5 => stateReg <= W5;   -- This delay is important. Should not be removed.

         when W5 => BQ(wReg) <= AHxQReg; stateReg <= W6;
     
         when W6 => 
--           if wReg=(bitLength/4)-1 then 
           if wReg=wNReg then 
             weReg <= '1';
             stateReg <= W7;
           else
             wReg <= wReg + 1; 
			    wPlus4Reg <= wPlus4Reg + 1;
             stateReg <= W3;
           end if;

         when W7 =>
           weReg <= '0';
			  AHxGReg <= '0';
           stateReg <= A0;        
     -- end of STAGE W --

     -- STAGE M: Message --
         when M0 =>
           mReg <= 0;
           stateReg <= M1;

         when M1 =>
			  case msg is
  			    when 0 => messageReg <= verInfo(mReg);
  			    when 1 => messageReg <= buildNumber(mReg);
  			    when 2 => messageReg <= clkFreq(mReg);
				 when 3 => messageReg <= startedMsg(mReg);
				 when 4 => messageReg <= finishedMsg(mReg);
				 when 5 => messageReg <= abortedMsg(mReg);
				 when 6 => messageReg <= runningMsg(mReg);
				 when 7 => messageReg <= notRunningMsg(mReg);
				 when 8 => messageReg <= syntaxError(mReg);
				 when 9 => messageReg <= invalidChannelNumberMsg(mReg);
				 when 10 => messageReg <= invalidReadArgumentMsg(mReg);
				 when 11 => messageReg <= invalidSetArgumentMsg(mReg);
				 when 12 => messageReg <= commanTooLongMsg(mReg);
				 when 13 => messageReg <= repeatScanStartedMsg(mReg);
				 when 14 => messageReg <= arrayMsg(mReg);
 				 when others => messageReg <= X"00";
           end case;             
			  stateReg <= M2;

			when M2 =>			
			  if (messageReg=x"00") then -- NULL character?
			      stateReg<=A0;
			  else
			    TxD8Reg <= messageReg;
             TxTrigReg <= '1';
             stateReg <= M3;
			  end if;

         when M3 =>
           TxTrigReg <= '0';
           stateReg <= M4;

         when M4 =>
           if TxBusyReg='1' then stateReg <= M4;
           else stateReg <= M5; end if;

         when M5 =>
           mReg <= mReg + 1;
           stateReg <= M1;

      -- end of STATE M --
    
         when others => stateReg <= L0;
      end case;
    end if; -- RST/FINISH
  end if; -- CLK
  end process;
end RTL;