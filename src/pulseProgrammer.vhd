
------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ram is
 generic(
       bitLength: natural;
       ppgAddressBits: natural;
       ppgAddressLines: natural
     );
  port( CLK: in std_logic;
        d: in std_logic_vector(bitLength-1 downto 0);
        address: in std_logic_vector(ppgAddressBits-1 downto 0);
        cs: in std_logic;
        we: in std_logic;
        q: out std_logic_vector(bitLength-1 downto 0)
      );
end ram;

architecture RTL of ram is
  type ram is array(0 to ppgAddressLines-1) of std_logic_vector(bitLength-1 downto 0);
  signal ram_block : ram;
begin
  process(CLK,we)
  begin
	if (CLK'event and CLK = '1') then
	  if (we = '1' and cs = '1') then
		ram_block(to_integer(unsigned(address))) <= d;
	  end if; -- we
        q <= ram_block(to_integer(unsigned(address)));
	end if; -- CLK
  end process;
end rtl;

------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity timer is
  port(CLK,RST,LOAD: in std_logic;
       DATA: in std_logic_vector(39 downto 0);
       ENDQ: out std_logic
      );
end timer;

architecture RTL of timer is
signal COUNT_TMP: std_logic_vector(39 downto 0);
signal zero: std_logic_vector(39 downto 0);
begin
  process (CLK,RST,LOAD) begin
    if (CLK'event and CLK='1') then
      if (RST='1') then
        COUNT_TMP <= (others => '0');
      else
        if (LOAD='1') then
          COUNT_TMP <= DATA;
        else
          COUNT_TMP <= COUNT_TMP - '1';
        end if;
      end if;
    end if;
  end process;
  
  process(CLK) begin
    if (CLK'event and CLK='1') then
      if COUNT_TMP = zero then ENDQ <= '1'; else ENDQ <= '0'; end if;
    end if; -- CLK
  end process;

  zero <= (others => '0');

end RTL;

------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

entity lineLatch is
 generic(
       lineLength: natural
     );
  port (CLK: in std_logic;
        RST: in std_logic;
        G: in std_logic;
        D: in std_logic_vector(lineLength-1 downto 0);
        Q: out std_logic_vector(lineLength-1 downto 0)
       );
end lineLatch;

architecture RTL of lineLatch is
begin
process(CLK,G) begin
  if(CLK'event and CLK='1') then
    if(RST='1') then
      Q <= (others => '0');
    elsif(G='1') then
      Q <= D;
    end if;
  end if; -- CLK
end process;
end RTL;

------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity pulseProgrammer is
 generic(
       bitLength: natural;
       lineLength: natural;
       ppgAddressBits: natural;
       ppgAddressLines: natural
     );
 port(CLK,RST,RUN: in std_logic;
      ADDRESS: in std_logic_vector(ppgAddressBits-1 downto 0);
		CURRENTADDRESS: out std_logic_vector(ppgAddressBits-1 downto 0);
      D112: in std_logic_vector(bitLength-1 downto 0);
      CS,WE: in std_logic;
      TRIG_E,TRIG_R,TRIG0,TRIG1,TRIG2,TRIG3: in std_logic;
      SYNC: in std_logic;
      LINE_OUT: out std_logic_vector(lineLength-1 downto 0);
      FINISH: out std_logic;
		RS: in std_logic;
		ND: in std_logic_vector(31 downto 0);
		INIT_PHASECYCLEPOINTER: out std_logic;
      Q112: out std_logic_vector(bitLength-1 downto 0);
      READY: out std_logic;
      ALL_SYNC: in std_logic;
      LATCH: out std_logic
      );
end pulseProgrammer;

architecture RTL of pulseProgrammer is
  
  component ram
    generic (
      bitLength:natural;
      ppgAddressBits:natural;
      ppgAddressLines:natural
      );
    port( CLK: in std_logic;
          d: in std_logic_vector(bitLength-1 downto 0);
          address: in std_logic_vector(ppgAddressBits-1 downto 0);
          cs:in std_logic;
          we: in std_logic;
          q: out std_logic_vector(bitLength-1 downto 0)
        );
  end component;

  component timer
    port(CLK,RST,LOAD: in std_logic;
         DATA: in std_logic_vector(39 downto 0);
         ENDQ: out std_logic
        );
  end component;

  
  component lineLatch
    generic(
       lineLength: natural
     );
    port (CLK: in std_logic;
          RST: in std_logic;
          G: in std_logic;
          D: in std_logic_vector(lineLength-1 downto 0);
          Q: out std_logic_vector(lineLength-1 downto 0)
         );
  end component;


  constant R0: std_logic_vector(3 downto 0) := "0000";
  constant R1: std_logic_vector(3 downto 0) := "0001";
  constant R2: std_logic_vector(3 downto 0) := "0010";
  constant R3: std_logic_vector(3 downto 0) := "0011";
  constant BU: std_logic_vector (3 downto 0):= "0111"; -- new (build1102 and higher)
  constant BU2: std_logic_vector (3 downto 0):= "0101"; -- new (build1102 and higher)
  constant E1: std_logic_vector(3 downto 0) := "0100";
  constant T1: std_logic_vector(3 downto 0) := "1000";
  constant T2: std_logic_vector(3 downto 0) := "1001";
  constant WH1: std_logic_vector(3 downto 0) := "1010";
  constant WH2: std_logic_vector(3 downto 0) := "1011";
  constant WL1: std_logic_vector(3 downto 0) := "1100";
  constant WL2: std_logic_vector(3 downto 0) := "1101";
  constant J1: std_logic_vector(3 downto 0) := "1111";
  constant SY: std_logic_vector(3 downto 0) := "0110";


  signal stateReg: std_logic_vector(3 downto 0) := R0;
  signal ASStateReg: std_logic;
  signal DSStateReg: std_logic_vector(1 downto 0) := "00";

--  signal runReg: std_logic;

  signal latchRSTReg: std_logic;
  signal latchGReg: std_logic;

  signal timerLoadReg: std_logic;
  signal timerCountEndReg: std_logic;

  signal finishReg: std_logic;  -- for sending a "FINISH" signal to pulser_interface

--  signal lp0AddressReg: std_logic_vector(10 downto 0);
--  signal lp1AddressReg: std_logic_vector(10 downto 0);
--  signal lp2AddressReg: std_logic_vector(10 downto 0);
  signal lp0AddressReg: std_logic_vector(ppgAddressBits-1 downto 0);
  signal lp1AddressReg: std_logic_vector(ppgAddressBits-1 downto 0);
  signal lp2AddressReg: std_logic_vector(ppgAddressBits-1 downto 0);
  signal lp0CountReg: std_logic_vector(39 downto 0);
  signal lp1CountReg: std_logic_vector(39 downto 0); -- extended from 16 to 40 bits in build2008 
  signal lp2CountReg: std_logic_vector(39 downto 0); -- extended from 16 to 40 bits in build2008
  signal lp0EndReg: std_logic;
  signal lp1EndReg: std_logic;
  signal lp2EndReg: std_logic;
  signal dummyCountReg: std_logic_vector(31 downto 0);
  signal dummyEndReg: std_logic;

--  signal runAddressReg: std_logic_vector(10 downto 0);
--  signal currentAddressReg: std_logic_vector(10 downto 0);
  signal runAddressReg: std_logic_vector(ppgAddressBits-1 downto 0);
  signal currentAddressReg: std_logic_vector(ppgAddressBits-1 downto 0);

  signal lineReg: std_logic_vector(lineLength-1 downto 0);
  signal argReg: std_logic_vector(39 downto 0);
  signal comReg: std_logic_vector(7 downto 0);
  signal Q112Reg: std_logic_vector(bitLength-1 downto 0);

  signal trigWReg,trigCReg,inTrigStateReg,inTrigStateNotReg: std_logic_vector(5 downto 0);

  signal asyncReg,syncTrigReg: std_logic;
--  signal asbAddressReg: std_logic_vector(10 downto 0);
  signal asbAddressReg: std_logic_vector(ppgAddressBits-1 downto 0);

  signal readyReg, syReg: std_logic;
  
  signal initPhaseCyclePointerReg: std_logic;
  signal countReg: integer range 0 to 15;


begin
  U1: ram generic map(bitLength=>bitLength,
                      ppgAddressBits=>ppgAddressBits,
                      ppgAddressLines=>ppgAddressLines) 
          port map(CLK=>CLK,
                   D=>D112,
                   ADDRESS=>currentAddressReg,
                   CS=>CS,
                   WE=>WE,
                   Q=>Q112Reg);

  U2: timer port map(CLK=>CLK,
                     RST=>RST,
                     LOAD=>timerLoadReg,
                     DATA=>argReg,
                     ENDQ=>timerCountEndReg);


  process(CLK) begin
    if (CLK'event and CLK='1') then
      if RUN='1' then currentAddressReg <= runAddressReg; 
      else currentAddressReg <= ADDRESS;
      end if;
    end if; -- CLK
  end process;

  CURRENTADDRESS <= currentAddressReg;
  
  U4: lineLatch generic map(lineLength=>lineLength)
                port map(CLK=>CLK,
                         RST=>latchRSTReg,
                         G=>latchGReg,
                         D=>lineReg,
                         Q=>LINE_OUT);

  LATCH <= latchGReg;

  latchRSTReg <= (not RUN) or syReg;
       -- disable line output when ppg is not running 
       -- or when ppg in in standby until all other channels have been ready.

  lineReg <= Q112Reg(lineLength-1 downto 0);
  argReg <= Q112Reg(lineLength+39 downto lineLength);
  comReg <= Q112Reg(lineLength+47 downto lineLength+40);

  FINISH <= finishReg;
  Q112 <= Q112Reg;
  INIT_PHASECYCLEPOINTER <= initPhaseCyclePointerReg;
  
  process(CLK) begin
    if (CLK'event and CLK='1') then 
      inTrigStateReg <= TRIG3 & TRIG2 & TRIG1 & TRIG0 & TRIG_R & TRIG_E;
      inTrigStateNotReg <= (not TRIG3) & (not TRIG2) & (not TRIG1) 
                        & (not TRIG0) & (not TRIG_R) & (not TRIG_E);
   --  inTrigStateNotReg <= not inTrigStateReg;
    end if;
  end process;

  READY <= readyReg; 

  process(CLK) begin
    if (CLK'event and CLK='1') then 
      if LP0CountReg=X"0000000001" then LP0EndReg<='1';
      else LP0EndReg<='0';end if;
    end if;
  end process;

  process(CLK) begin
    if (CLK'event and CLK='1') then 
      if LP1CountReg=X"0001" then LP1EndReg<='1';
      else LP1EndReg<='0';end if;
    end if;
  end process;

  process(CLK) begin
    if (CLK'event and CLK='1') then 
      if LP2CountReg=X"0001" then LP2EndReg<='1'; 
      else LP2EndReg<='0';end if;
    end if;
  end process;


  process(CLK) begin
    if (CLK'event and CLK='1') then 
      if RST='1' then 
        syncTrigReg <= '0';
        ASStateReg <= '0';
      else
        case ASStateReg is
          when '0' =>
            syncTrigReg <= '0';
            if asyncReg='1' then ASStateReg <='1';
            else ASStateReg <='0'; end if;
          when '1' =>
            if (asyncReg='1' and SYNC='1') then
              syncTrigReg <= '1';
              ASStateReg <= '0';
            else
              ASStateReg <= '1';
            end if;
        end case;
      end if; -- RST
    end if; -- CLK
  end process;

  process(CLK) begin
    if (CLK'event and CLK='1') then 
      if (RST='1' or RUN='0') then 
		  initPhaseCyclePointerReg<='0';
		  countReg <= 0;
        DSStateReg <= "00";
      else
        case DSStateReg is
          when "00" =>			   
				initPhaseCyclePointerReg<='0';
				if (stateReg=R3 and comReg=X"10") then -- loop0
				  initPhaseCyclePointerReg<='1';
				  countReg<=0;
              DSStateReg <= "10";				 
            elsif (dummyCountReg>0) then DSStateReg <="01";
            else DSStateReg <="00"; end if;
          when "01" =>
            if (dummyCountReg=0) then
				  initPhaseCyclePointerReg<='1';
				  countReg<=0;
              DSStateReg <= "10";				  
            else
              DSStateReg <= "01";
            end if;
			when "10" =>
			   if(countReg=7) then
			     countReg <= 0;
				  DSStateReg <= "00"; 
				else
				  countReg <= countReg+1;
				  DSStateReg <= "10";
				end if;
			when "11" => DSStateReg <= "00";
        end case;
      end if; -- RST
    end if; -- CLK
  end process;


  process(CLK,RST) begin
    if (CLK'event and CLK='1') then
      if (RST='1' or RUN='0') then
		  runAddressReg <= (others=>'0');
        LP0CountReg <= (others=>'0');
        LP1CountReg <= (others=>'0');
        LP2CountReg <= (others=>'0');
        finishReg <= '0';
        latchGReg <= '0';
        timerLoadReg <= '0';
        readyReg<='0';
		  syReg<='0';
		  dummyCountReg <= (others=>'0');
        stateReg<=R0;
      elsif syncTrigReg='1' then
        asyncReg <= '0';
        runAddressReg <= asbAddressReg;
        stateReg<=R1;
      else
      case stateReg is

        when E1 => -- END
          finishReg <= '1'; -- send a signal to pulser_interface
          stateReg <= E1;   -- infinite loop until RUN='0';

        when R0 => 
		    runAddressReg <= (others=>'0');
          LP0CountReg <= (others=>'0');
          LP1CountReg <= (others=>'0');
          LP2CountReg <= (others=>'0');
          finishReg <= '0';
          latchGReg <= '0';
          timerLoadReg <= '0';
          readyReg <= '0';
			 syReg<='0';
			 dummyCountReg <= (others=>'0');
          if RUN='0' then 
            stateReg<=R0;
          else 
--            runAddressReg <= ADDRESS;
            stateReg<=R1;
          end if;

        when R1 => stateReg <= R2;     -- 2 clock delay seems important!(2005.11.17)
        when R2 => stateReg <= R3;     --  (comment by Takeda)

        when R3 => 
          case comReg is
            when X"00" => -- END_PPG
              stateReg <= E1;

            when X"10" => -- LOOP0
              lp0AddressReg <= currentAddressReg + '1';
                     -- the "come-back" address for loop counter #0
              lp0CountReg <= argReg;
				  dummyCountReg <= ND;
              runAddressReg <= runAddressReg + '1'; 
              stateReg <= R1;

            when X"11" => -- LOOP1
              lp1AddressReg <= currentAddressReg + '1';
                     -- the "come-back" address for loop counter #1
              lp1CountReg <= argReg;
              runAddressReg <= runAddressReg + '1'; 
              stateReg <= R1;

            when X"12" => -- LOOP2
              lp2AddressReg <= currentAddressReg + '1';
                     -- the "come-back" address for loop counter #2
              lp2CountReg <= argReg;
              runAddressReg <= runAddressReg + '1'; 
              stateReg <= R1;

            when X"18" => -- END_LOOP0
				  if (RS='1') then -- repeat scan
				    runAddressReg <= lp0AddressReg;
                stateReg <= R1;
				  elsif (dummyCountReg>0) then
				    dummyCountReg <= dummyCountReg-'1';
                runAddressReg <= lp0AddressReg;
                stateReg <= R1;					 
              elsif (lp0EndReg='0') then
                lp0CountReg <= lp0CountReg-1;
                runAddressReg <= lp0AddressReg;
                stateReg <= R1;
              else  -- loop end
                runAddressReg <= runAddressReg + '1';
                stateReg <= R1;
              end if;

            when X"19" => -- END_LOOP1
              if lp1EndReg='0' then
                lp1CountReg <= lp1CountReg-1;
                runAddressReg <= lp1AddressReg;
                stateReg <= R1;
              else  -- loop end
                runAddressReg <= runAddressReg + '1';
                stateReg <= R1;
              end if;

            when X"1A" => -- END_LOOP2
              if lp2EndReg='0' then
                lp2CountReg <= lp2CountReg-1;
                runAddressReg <= lp2AddressReg;
                stateReg <= R1;
              else  -- loop end
                runAddressReg <= runAddressReg + '1';
                stateReg <= R1;
              end if;

            when X"B0" => -- JUMP
              runAddressReg <= argReg(ppgAddressBits-1 downto 0);
              stateReg <= R1;

            when X"B1" => -- JUMP_IF
              trigWReg <= argReg(5 downto 0);
              stateReg <= J1;

            when X"A0" => -- OUT_PD (new in build2006 2015Oct09 )
              runAddressReg <= runAddressReg + '1';
              if(lp0EndReg='1' and RS='0') then -- if this is the last accumulation, we skip the operation
                                   -- In addition, we detect RS (repeat scan)
                                   -- this is necessary when NA happens to be 1 and RS='1'!
                                   -- (18 Nov 2015 Takeda)
                stateReg <= R1;                 
              else -- else, we do the same as "OUT"
                latchGReg <='1';
                timerLoadReg <= '1';
                stateReg <= T1;
              end if;

            when X"A1" => --OUT
              latchGReg <= '1';
              runAddressReg <= runAddressReg + '1';
              timerLoadReg <= '1';
              stateReg <= T1;

				when X"BA" => -- BURST
				  -- new (build1102 and higher)
		        latchGReg <= '1';
				  runAddressReg <= runAddressReg + '1';
				  stateReg <= BU;  
				  
            when X"A2" => -- WAIT_HIGH
              latchGReg <= '1';
              runAddressReg <= runAddressReg + '1';
              trigWReg <= argReg(5 downto 0);
              stateReg <= WH1;

            when X"A3" => -- WAIT_LOW
              latchGReg <= '1';
              runAddressReg <= runAddressReg + '1';
              trigWReg <= argReg(5 downto 0);
              stateReg <= WL1;

            when X"AA" => -- ASYNC
              asyncReg <= '1';
              asbAddressReg <= currentAddressReg + '1';
              runAddressReg <= argReg(ppgAddressBits-1 downto 0);
              stateReg <= R1;

            when X"FF" => -- ALL_SYNC
              readyReg <= '1';
              runAddressReg <= runAddressReg + '1';
              stateReg <= SY;

            when others =>
          end case; -- comReg

        when T1 =>
          latchGReg <= '0';
          timerLoadReg <= '0';
          stateReg <= T2;

        when T2 =>
          if timerCountEndReg='0' then stateReg <= T2;
          else
            stateReg <= R3;
          end if;
			 
		  when BU => -- BURST
		  -- new (build1102 and higher)
		    runAddressReg <= runAddressReg + '1';
			 if(Q112Reg(lineLength+47 downto lineLength+40)=X"BA") then
			   stateReg <= BU;
			 else
			   latchGReg <= '0';
--				stateReg <= R1;
				stateReg <= BU2;
			 end if;
			 
		  when BU2 =>
--		    runAddressReg <= runAddressReg - '1';
		    runAddressReg <= runAddressReg - "11";
		    stateReg <= R1;
       
        when WH1 =>
          latchGReg <= '0';
			 trigCReg <= (inTrigStateReg and trigWReg);
          stateReg <= WH2;

        when WH2 =>
          if (trigCReg = trigWReg) then
            stateReg <= R3;
          else 
   			trigCReg <= (inTrigStateReg and trigWReg);
            stateReg <= WH2;
          end if;

        when WL1 =>
          latchGReg <= '0';
			 trigCReg <= (inTrigStateNotReg and trigWReg);
          stateReg <= WL2;

        when WL2 =>
          if (trigCReg = trigWReg) then
            stateReg <= R3;
          else 
   			trigCReg <= (inTrigStateNotReg and trigWReg);
            stateReg <= WL2;
          end if;

        when J1 =>
          if ((inTrigStateReg and trigWReg) = trigWReg) then
            runAddressReg <= argReg(ppgAddressBits+28 downto 29);
            stateReg <= R1;
          else
            runAddressReg <= argReg(ppgAddressBits+17 downto 18);
            stateReg <= R1;
          end if;

        when SY =>
          if (ALL_SYNC='1') then 
            readyReg <= '0';
				syReg<='0';
            stateReg <= R3; 
          else 
			   syReg<='1';
            stateReg <= SY; 
          end if;

        when others => stateReg <= E1; -- END

      end case;
      end if; -- RST
    end if; -- CLK  
  end process;
end RTL;