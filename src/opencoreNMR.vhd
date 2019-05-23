------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity opencoreNMR is
 generic(
--       bitLength: natural := 144;
--      lineLength: natural := 96
       bitLength: natural := 112;
       lineLength: natural := 64;
       ppgAddressBits: natural :=11;
       ppgAddressLines: natural :=2048
     );
    port(
         CLK1: in std_logic;
         RST: in std_logic;
         TRIG_E: in std_logic;
         RxD: in std_logic;
         TxD: out std_logic;
         F1AMP: out std_logic_vector(9 downto 0);
         F1GATE: out std_logic;
         F1UNBLANK_POS: out std_logic;
         F1UNBLANK_NEG: out std_logic;
         F1TTL: out std_logic_vector(1 downto 0);
         F2AMP: out std_logic_vector(9 downto 0);
         F2GATE: out std_logic;
         F2UNBLANK_POS: out std_logic;
         F2UNBLANK_NEG: out std_logic;
         F2TTL: out std_logic_vector(1 downto 0);
         F3AMP: out std_logic_vector(9 downto 0);
         F3GATE: out std_logic;
         F3UNBLANK_POS: out std_logic;
         F3UNBLANK_NEG: out std_logic;
         F3TTL: out std_logic_vector(1 downto 0);

         INVRUN: out std_logic;
         INVTRANSBUSY: out std_logic;  -- for putting an LED during FID-data transfer via USB
      --   INVPLLLOCKED: out std_logic;
			
         F1FREQ_ADD: out std_logic_vector(5 downto 0);
         F1FREQ_D: out std_logic_vector(7 downto 0);
         F2FREQ_ADD: out std_logic_vector(5 downto 0);
         F2FREQ_D: out std_logic_vector(7 downto 0);
         F3FREQ_ADD: out std_logic_vector(5 downto 0);
         F3FREQ_D: out std_logic_vector(7 downto 0);
         F1FREQ_WR: out std_logic;
         F1FREQ_RD: out std_logic;
         F2FREQ_WR: out std_logic;
         F2FREQ_RD: out std_logic;
         F3FREQ_WR: out std_logic;
         F3FREQ_RD: out std_logic;
         F1FREQ_PS0: out std_logic;
         F2FREQ_PS0: out std_logic;
         F3FREQ_PS0: out std_logic;
         F1FREQ_PS1: out std_logic;
         F2FREQ_PS1: out std_logic;
         F3FREQ_PS1: out std_logic;
         F1FREQ_FUD: out std_logic;
         F2FREQ_FUD: out std_logic;
         F3FREQ_FUD: out std_logic;
         F1FREQ_RST: out std_logic;
         F2FREQ_RST: out std_logic;
         F3FREQ_RST: out std_logic;
         
         F1SYNCLK: in std_logic;
         F2SYNCLK: in std_logic;
         F3SYNCLK: in std_logic;
         
         COS1: out std_logic_vector(9 downto 0);
         COS2: out std_logic_vector(9 downto 0);
         COS3: out std_logic_vector(9 downto 0);
         OCLK1a: out std_logic;
         OCLK2a: out std_logic;
         OCLK3a: out std_logic;
         ADOCLK: out std_logic;  --  ADC CLK (out)
         AMCLK1: out std_logic;  --  CLK for AM
         AMCLK2: out std_logic; 
         AMCLK3: out std_logic;  
         GZCLK: out std_logic;  -- new in build #1039
         RCVR_PWDN: out std_logic;  -- H: standby, L: normal operation
--         RCVR_OTR: in std_logic;  -- out-of-range indicator. not used currently
         SIG: in signed(13 downto 0);   -- ADC DATA
         RXF: in std_logic;
         TXE: in std_logic;
         RD: out std_logic;
         WR: out std_logic;
         USBDATA: inout std_logic_vector(7 downto 0);
         TTL_GND: out std_logic_vector(11 downto 0);
         GZ: out std_logic_vector(9 downto 0)  -- new in build #1039
         );
end opencoreNMR;


architecture RTL of opencoreNMR is

  component receiver is
    port(CLK160: in std_logic;
         CLK80: in std_logic;
         CLK20: in std_logic;
         RST: in std_logic;
         RUNQ: in std_logic;
         --ADCLK: in std_logic;
         --AQC: in std_logic;
         --AQS: in std_logic;
         SIG: in signed(13 downto 0);
         ACQ_PHASE: in std_logic_vector(1 downto 0);
         ACQ_START: in std_logic;
         RXF_N : in std_logic;
         TXE_N : in std_logic;
         RD_N  : out std_logic;
         WR    : out std_logic;
         USBDATA: inout std_logic_vector(7 downto 0);
         ACQ_BUSY: out std_logic;
         TRANS_BUSY: out std_logic;
         RG: in std_logic;
			--
			AL: in std_logic_vector(31 downto 0);
		   NA: in std_logic_vector(31 downto 0);
		   DW: in std_logic_vector(31 downto 0);
		   ST: in std_logic_vector(31 downto 0);
		   AF: in std_logic_vector(31 downto 0);
		   CO_ADDRESS: in std_logic_vector(9 downto 0);
		   CO_DATA: in std_logic_vector(11 downto 0);
		   CO_WR: in std_logic;
		   CO_LENGTH: in std_logic_vector(9 downto 0)
         );
  end component;


  component interface is
    generic(
       bitLength: natural;
       ppgAddressBits: natural
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
			RS: out std_logic;
		   AL: out std_logic_vector(31 downto 0);
		   NA: out std_logic_vector(31 downto 0);
			ND: out std_logic_vector(31 downto 0);
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
  end component;

  component pulseProgrammer is
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
  end component;


  component PLL is  -- in 10M, out 20, 80, 160 MHz
	PORT(
		refclk		: IN STD_LOGIC  := '0';
	--	rst: IN STD_LOGIC:='0';
		outclk_0		: OUT STD_LOGIC ;   -- 20 MHz
		outclk_1:     OUT std_logic;  -- 80 MHz
		outclk_2      : OUT STD_LOGIC    -- 160 MHz
	);
  end component;


  component phaseController is
    port( CLK1,CLK2: in std_logic;
          RST: in std_logic;
          ALL_INIT: in std_logic;
          ACQ_CS: in std_logic;
          SEL: in std_logic_vector(3 downto 0);
          TOGGLE: in std_logic;
          INIT: in std_logic;
          COMMAND: in std_logic;
          MODE: in std_logic_vector(1 downto 0);
          PHASE_WORD: in std_logic_vector(9 downto 0);
          PHACC: in std_logic;
          PHACCRST: in std_logic;
          PPGLINELATCH: in std_logic;
          DA_COS: out std_logic_vector(9 downto 0);
          ACQ_PHASE: out std_logic_vector(1 downto 0)
         );
  end component;


  signal cos1Reg: std_logic_vector(9 downto 0);
  
  signal CLK20Reg,CLK80Reg,CLK160Reg: std_logic;
  signal RSTReg: std_logic;
  signal phRSTReg: std_logic;
  signal runReg: std_logic;
  signal weReg: std_logic;
  signal addressReg: std_logic_vector(ppgAddressBits-1 downto 0);
  signal currentAddressReg,currentAddress1Reg,currentAddress2Reg,currentAddress3Reg: std_logic_vector(ppgAddressBits-1 downto 0);
  signal WDReg: std_logic_vector(bitLength-1 downto 0);
  signal RD1Reg,RD2Reg,RD3Reg,RDQReg: std_logic_vector(bitLength-1 downto 0);
  signal finishReg,finish1Reg,finish2Reg,finish3Reg: std_logic;
  signal trig0Reg,trig1Reg,trig2Reg,trig3Reg: std_logic;
  signal ch1Reg,ch2Reg,ch3Reg: std_logic;
  signal line1Reg, line2Reg, line3Reg: std_logic_vector(lineLength-1 downto 0);
  signal transBusyReg, acqBusyReg, RCVRBusyReg: std_logic;
  signal acqPhaseReg: std_logic_vector(1 downto 0);
  signal ready1Reg,ready2Reg,ready3Reg,allSyncReg: std_logic;
  signal acqStartReg: std_logic;
  signal chSelReg: std_logic_vector(2 downto 0);
    
  signal F1PS0Reg, F2PS0Reg, F3PS0Reg: std_logic; 
  signal F1PS1Reg, F2PS1Reg, F3PS1Reg: std_logic; 
  signal F1FUDReg, F2FUDReg, F3FUDReg: std_logic; 
  
  signal lineLatch1Reg, lineLatch2Reg, lineLatch3Reg: std_logic;

  signal phRSTFromInterface: std_logic;
  signal allSyncStateReg: std_logic_vector(2 downto 0) := "000";
  signal WR1StateReg: std_logic_vector(2 downto 0) := "000";
  signal WR2StateReg: std_logic_vector(2 downto 0) := "000";
  signal WR3StateReg: std_logic_vector(2 downto 0) := "000";
  signal sampligTriggerStateReg: std_logic_vector(1 downto 0) := "00";
  
  signal rsReg: std_logic;
  signal alReg,dwReg,naReg,ndReg,stReg,afReg: std_logic_vector(31 downto 0);
  signal doReg: std_logic_vector(31 downto 0); -- DC offset (2015 Mar 10)
  signal dcOffsetReg: signed(13 downto 0);  -- 2015 Mar 10
  
  signal srReg: std_logic_vector(31 downto 0); -- number of Shift Right (2016 Apr 10)
  
  signal coAddressReg: std_logic_vector(9 downto 0);
  signal coDataReg: std_logic_vector(11 downto 0);
  signal coWRReg: std_logic;
  signal coLengthReg: std_logic_vector(9 downto 0);  
  
  signal initPhaseCyclePointer1Reg,
         initPhaseCyclePointer2Reg,
			initPhaseCyclePointer3Reg: std_logic;
  signal iniP1Reg,iniP2Reg,iniP3Reg: std_logic;
  
  signal sigReg, sigReg0, sigReg1, sigReg2: signed(13 downto 0);
	
  signal TxBusyReg: std_logic;	
  
  signal GxReg,GyReg,GzReg: std_logic_vector(9 downto 0);
begin
	
  U1: PLL port map(
    refclk => CLK1,
	-- rst=>RSTReg,
    outclk_0=>CLK20Reg,
    outclk_1=>CLK80Reg,
    outclk_2=>CLK160Reg
  );
  
  U3: interface 
      generic map(
         bitLength => bitLength,
         ppgAddressBits=>ppgAddressBits)
      port map(
        CLK => CLK20Reg,
        RST => RSTReg,
        RUN => runReg,
        WE => weReg,
        ADDRESS => addressReg,
		  CURRENTADDRESS => currentAddressReg,
        Q112 => WDReg,
        D112 => RDQReg,
        TxD => TxD,
        RxD => RxD,
        FINISH => finishReg,
        CH1 => ch1Reg,
        CH2 => ch2Reg,
        CH3 => ch3Reg,
        PHRST => phRSTFromInterface,
		  --
		  RS => rsReg,
		 AL => alReg,
		 NA => naReg,
		 ND => ndReg,
 		 DW => dwReg,
		 ST => stReg,
		 AF => afReg,
		 DO => doReg,
		 SR => srReg,
		 CO_ADDRESS => coAddressReg,
		 CO_DATA => coDataReg,
		 CO_WR => coWRReg,
		 CO_LENGTH => coLengthReg,	  
		  Tx_Busy => TxBusyReg
        );
		  
		phRSTReg <= line1Reg(56) or phRSTFromInterface;

		
		
		
  process(CLK20Reg) begin 
    if (CLK20Reg'event and CLK20Reg='1') then
      finishReg <= finish1Reg and finish2Reg and finish3Reg;
    end if;
  end process;


  chSelReg <= ch3Reg & ch2Reg & ch1Reg;
  with chSelReg select RDQReg <= RD1Reg when "001",
                                 RD2Reg when "010",
                                 RD3Reg when "100",
                                 RD1Reg when others;
  with chSelReg select currentAddressReg <= currentAddress1Reg when "001",
                                            currentAddress2Reg when "010",
														  currentAddress3Reg when "100",
														  currentAddress1Reg when others;

  
  process(CLK160Reg,RSTReg) begin
    if (CLK160Reg'event and CLK160Reg='1') then
	   if (RSTReg='1') then allSyncStateReg <= "000"; allSyncReg <='0'; else
	     case allSyncStateReg is
		     when "000" => 
             if (ready1Reg='1' and ready2Reg='1' and ready3Reg='1') then 
				   allSyncStateReg <= "001";
				 else
				   allSyncReg <='0';
					allSyncStateReg <= "000";
				 end if;
		     when "001" => allSyncReg <='1'; allSyncStateReg <= "010";
		     when "010" => allSyncStateReg <= "011";
		     when "011" => allSyncStateReg <= "100";
		     when "100" => allSyncStateReg <= "101";
		     when "101" => allSyncStateReg <= "110";
		     when "110" => allSyncStateReg <= "111";
		     when "111" => allSyncReg <='0'; allSyncStateReg <= "000";
				 
        end case;				 
		end if;		 
    end if;
  end process;
  -- NOTE:
  -- "allSyncReg <= (ready1Reg) and (ready2Reg) and (ready3Reg)" leads to malfunctioning.



  U5: pulseProgrammer    -- CHANNEL 1
     generic map(
       bitLength => bitLength,
       lineLength => lineLength,
       ppgAddressBits=>ppgAddressBits,
       ppgAddressLines=>ppgAddressLines )
     port map(
         CLK => CLK160Reg,
         RST => RSTReg,
         RUN => runReg,
         ADDRESS => addressReg,
			CURRENTADDRESS => currentAddress1Reg,
         D112 => WDReg,
         CS => ch1Reg,
         WE => weReg,
         TRIG_E => TRIG_E,
         TRIG_R => RCVRBusyReg,
         TRIG0 => '0',
         TRIG1 => '0',
         TRIG2 => line2Reg(57),  -- trigger from CH2
         TRIG3 => line3Reg(57),  -- trigger from CH3
         SYNC => '1',   -- CH1 is the master channel
         LINE_OUT => line1Reg,
         FINISH => finish1Reg,
			RS => rsReg,
			ND => ndReg,
			INIT_PHASECYCLEPOINTER => iniP1Reg,
         Q112 => RD1Reg,
         READY => ready1Reg, 
         ALL_SYNC => allSyncReg,
         LATCH => lineLatch1Reg
        );




  U6: pulseProgrammer    -- CHANNEL 2
     generic map(
       bitLength => bitLength,
       lineLength => lineLength,
       ppgAddressBits=>ppgAddressBits,
       ppgAddressLines=>ppgAddressLines )
     port map(
         CLK => CLK160Reg,
         RST => RSTReg,
         RUN => runReg,
         ADDRESS => addressReg,
			CURRENTADDRESS => currentAddress2Reg,
         D112 => WDReg,
         CS => ch2Reg,
         WE => weReg,
         TRIG_E => TRIG_E,
         TRIG_R => RCVRBusyReg,
         TRIG0 => '0',
         TRIG1 => line1Reg(57),  -- trigger from CH1
         TRIG2 => '0',
         TRIG3 => line3Reg(58),  -- trigger from CH3
         SYNC => line1Reg(62),
         LINE_OUT => line2Reg,
         FINISH => finish2Reg,
			RS => rsReg,
			ND => ndReg,
			INIT_PHASECYCLEPOINTER => iniP2Reg,
         Q112 => RD2Reg,
         READY => ready2Reg, 
         ALL_SYNC => allSyncReg,
         LATCH => lineLatch2Reg
        );

  U7: pulseProgrammer    -- CHANNEL 3
     generic map(
       bitLength => bitLength,
       lineLength => lineLength,
       ppgAddressBits=>ppgAddressBits,
       ppgAddressLines=>ppgAddressLines)
     port map(
         CLK => CLK160Reg,
         RST => RSTReg,
         RUN => runReg,
         ADDRESS => addressReg,
		   CURRENTADDRESS => currentAddress3Reg,
         D112 => WDReg,
         CS => ch3Reg,
         WE => weReg,
         TRIG_E => TRIG_E,
         TRIG_R => RCVRBusyReg,
         TRIG0 => '0',
         TRIG1 => line1Reg(58),  -- trigger from CH1
         TRIG2 => line2Reg(58),  -- trigger from CH2
         TRIG3 => '0',
         SYNC => line1Reg(63),
         LINE_OUT => line3Reg,
         FINISH => finish3Reg,
			RS => rsReg,
			ND => ndReg,
			INIT_PHASECYCLEPOINTER => iniP3Reg,
         Q112 => RD3Reg,
         READY => ready3Reg, 
         ALL_SYNC => allSyncReg,
         LATCH => lineLatch3Reg
        );

  initPhaseCyclePointer1Reg <= line1Reg(17) or iniP1Reg;
  initPhaseCyclePointer2Reg <= line2Reg(17) or iniP2Reg;
  initPhaseCyclePointer3Reg <= line3Reg(17) or iniP3Reg;
		  
  U8: phaseController
    port map( CLK1 => CLK160Reg,
              CLK2 => CLK20Reg,
     --         CLK3 => CLK100Reg,
              RST => phRSTReg,
              ALL_INIT => line1Reg(18),
              ACQ_CS => line1Reg(60),
              SEL => line1Reg(51) & line1Reg(12 downto 10),
              TOGGLE => line1Reg(13),
              -- INIT => line1Reg(17),
				  INIT => initPhaseCyclePointer1Reg,
              COMMAND => line1Reg(16),
              MODE => line1Reg(15 downto 14),
              PHASE_WORD => line1Reg(9 downto 0),
              PHACC => line1Reg(49),
              PHACCRST => line1Reg(50),
              PPGLINELATCH => lineLatch1Reg,
              DA_COS => COS1, 
              ACQ_PHASE => acqPhaseReg
              );

  U9: phaseController
    port map( CLK1 => CLK160Reg,
              CLK2 => CLK20Reg,
       --       CLK3 => CLK100Reg,
              RST => phRSTReg,
              ALL_INIT => line2Reg(18),
              ACQ_CS => '0',
              SEL => line2Reg(51) & line2Reg(12 downto 10),
              TOGGLE => line2Reg(13),
            --  INIT => line2Reg(17),
				  INIT => initPhaseCyclePointer2Reg,
              COMMAND => line2Reg(16),
              MODE => line2Reg(15 downto 14),
              PHASE_WORD => line2Reg(9 downto 0),
              PHACC => line2Reg(49),
              PHACCRST => line2Reg(50),
              PPGLINELATCH => lineLatch2Reg,
              DA_COS => COS2 
--              ACQ_PHASE => 
              );

  U10: phaseController
    port map( CLK1 => CLK160Reg,
              CLK2 => CLK20Reg,
       --       CLK3 => CLK100Reg,
              RST => phRSTReg,
              ALL_INIT => line3Reg(18),
              ACQ_CS => '0',
              SEL => line3Reg(51) & line3Reg(12 downto 10),
              TOGGLE => line3Reg(13),
             -- INIT => line3Reg(17),
				  INIT => initPhaseCyclePointer3Reg,
              COMMAND => line3Reg(16),
              MODE => line3Reg(15 downto 14),
              PHASE_WORD => line3Reg(9 downto 0),
              PHACC => line3Reg(49),
              PHACCRST => line3Reg(50),
              PPGLINELATCH => lineLatch3Reg,
              DA_COS => COS3
--              ACQ_PHASE => 
              );

				  
				  
  process(CLK80Reg) begin
    if (CLK80Reg'event and CLK80Reg='1') then
      sigReg0 <= SIG;
    end if;
  end process; 
  
  dcOffsetReg <= signed(doReg(13 downto 0));
  process(CLK80Reg) begin
    if (CLK80Reg'event and CLK80Reg='1') then
      sigReg1 <= sigReg0-dcOffsetReg;
    end if;
  end process; 
				  
				  
  process(CLK80Reg) begin
    if (CLK80Reg'event and CLK80Reg='1') then
      sigReg2 <= shift_right(sigReg1,to_integer(unsigned(srReg(3 downto 0))));
    end if;
  end process; 

  process(CLK80Reg) begin
    if (CLK80Reg'event and CLK80Reg='1') then
	   if(sigReg2="00000000000001" or sigReg2="11111111111111") then
		  sigReg <= (others => '0');
		else
        sigReg <= sigReg2;
		end if;
    end if;
  end process; 
				  
				  
				  
  U11: receiver port map(
         CLK160=>CLK160Reg, 
         CLK80=>CLK80Reg,
         CLK20=>CLK20Reg,
         RST=>RSTReg,
         RUNQ=>runReg,
         SIG => sigReg,
         ACQ_PHASE=>acqPhaseReg,
         ACQ_START=>acqStartReg,
         RXF_N=>RXF,
         TXE_N=>TXE,
         RD_N=>RD,
         WR =>WR,
         USBDATA=>USBDATA,
         ACQ_BUSY=>acqBusyReg,
         TRANS_BUSY=>transBusyReg,
         RG=>line1Reg(52),
			AL => alReg,
		   NA => naReg,
		   DW => dwReg,
		   ST => stReg,
		   AF => afReg,
		   CO_ADDRESS => coAddressReg,
		   CO_DATA => coDataReg,
		   CO_WR => coWRReg,
		   CO_LENGTH => coLengthReg	
         );


  --acqStartReg <= line1Reg(59);

  process(CLK160Reg,RSTReg) begin
    if (CLK160Reg'event and CLK160Reg='1') then
	   if (RSTReg='1') then sampligTriggerStateReg <= "00"; else
		  case sampligTriggerStateReg is
		    when "00"=> acqStartReg <= '0';
		      if(lineLatch1Reg='1' or lineLatch2Reg='1' or lineLatch3Reg='1') then 
				  sampligTriggerStateReg<="01"; 
				else 
				  sampligTriggerStateReg<="00"; 
				end if;
			 when "01" =>
		      if(line1Reg(59)='1') then acqStartReg<='1'; sampligTriggerStateReg<="10"; else sampligTriggerStateReg<="00"; end if;

		    when "10" => sampligTriggerStateReg <= "11";
		    when "11" => sampligTriggerStateReg <= "00";
        end case;		
		end if;
	 end if;
  end process;


--  RCVRBusyReg <= acqBusyReg or transBusyReg;
  process(CLK160Reg) begin
    if (CLK160Reg'event and CLK160Reg='1') then
      RCVRBusyReg <= transBusyReg;
    end if;
  end process; 
  
  process(CLK160Reg,RSTReg) begin
    if (CLK160Reg'event and CLK160Reg='1') then
	   if (RSTReg='1') then F1FREQ_WR<='1'; WR1StateReg <= "000"; else
		  case WR1StateReg is
		    when "000"=>
			   F1FREQ_WR<='1';
		      if(lineLatch1Reg='1') then WR1StateReg<="001"; else WR1StateReg<="000"; end if;
			 when "001" => WR1StateReg<="010";
			 when "010" =>
		      if(line1Reg(43)='1') then WR1StateReg<="011"; else WR1StateReg<="000"; end if;
			 when "011" => WR1StateReg <= "100";
		    when "100" => F1FREQ_WR<='0'; WR1StateReg <= "101";
		    when "101" =>	WR1StateReg <= "110";		 
		    when "110" =>	WR1StateReg <= "111";		 
		    when "111" =>	WR1StateReg <= "000";		 
        end case;		
		end if;
	 end if;
  end process;

  process(CLK160Reg,RSTReg) begin
    if (CLK160Reg'event and CLK160Reg='1') then
	   if (RSTReg='1') then F2FREQ_WR<='1'; WR2StateReg <= "000"; else
		  case WR2StateReg is
		    when "000"=>
			   F2FREQ_WR<='1';
		      if(lineLatch2Reg='1') then WR2StateReg<="001"; else WR2StateReg<="000"; end if;
			 when "001" => WR2StateReg<="010";
			 when "010" =>
		      if(line2Reg(43)='1') then WR2StateReg<="011"; else WR2StateReg<="000"; end if;
			 when "011" => WR2StateReg <= "100";
		    when "100" => F2FREQ_WR<='0'; WR2StateReg <= "101";
		    when "101" =>	WR2StateReg <= "110";		 
		    when "110" =>	WR2StateReg <= "111";		 
		    when "111" =>	WR2StateReg <= "000";		 
        end case;		
		end if;
	 end if;
  end process;

  process(CLK160Reg,RSTReg) begin
    if (CLK160Reg'event and CLK160Reg='1') then
	   if (RSTReg='1') then F3FREQ_WR<='1'; WR3StateReg <= "000"; else
		  case WR3StateReg is
		    when "000"=>
			   F3FREQ_WR<='1';
		      if(lineLatch3Reg='1') then WR3StateReg<="001"; else WR3StateReg<="000"; end if;
			 when "001" => WR3StateReg<="010";
			 when "010" =>
		      if(line3Reg(43)='1') then WR3StateReg<="011"; else WR3StateReg<="000"; end if;
			 when "011" => WR3StateReg <= "100";
		    when "100" => F3FREQ_WR<='0'; WR3StateReg <= "101";
		    when "101" =>	WR3StateReg <= "110";		 
		    when "110" =>	WR3StateReg <= "111";		 
		    when "111" =>	WR3StateReg <= "000";		 
        end case;		
		end if;
	 end if;
  end process;

  
  

  process(F1SYNCLK) begin
    if (F1SYNCLK'event and F1SYNCLK='1') then
      F1PS0Reg <= line1Reg(47);
      F1PS1Reg <= line1Reg(46);
      F1FUDReg <= line1Reg(45);
    end if;
  end process;

  F1FREQ_PS0 <= F1PS0Reg;
  F1FREQ_PS1 <= F1PS1Reg;
  F1FREQ_FUD <= F1FUDReg;
  


  F1FREQ_RST <= line1Reg(48);
--  F1FREQ_WR <= not line1Reg(43);  -- ACTIVE LOW
  F1FREQ_RD <= '1';

  F1FREQ_ADD <= line1Reg(42 downto 37);
  F1FREQ_D <= line1Reg(36 downto 29);


  process(F2SYNCLK) begin
    if (F2SYNCLK'event and F2SYNCLK='1') then
      F2PS0Reg <= line2Reg(47);
      F2PS1Reg <= line2Reg(46);
      F2FUDReg <= line2Reg(45);
   end if;
  end process;

  F2FREQ_PS0 <= F2PS0Reg;
  F2FREQ_PS1 <= F2PS1Reg;
  F2FREQ_FUD <= F2FUDReg;

  F2FREQ_RST <= line2Reg(48);
--  F2FREQ_WR <= not line2Reg(43);  -- ACTIVE LOW
  F2FREQ_RD <= '1';

  F2FREQ_ADD <= line2Reg(42 downto 37);
  F2FREQ_D <= line2Reg(36 downto 29);

  process(F3SYNCLK) begin
    if (F3SYNCLK'event and F3SYNCLK='1') then
      F3PS0Reg <= line3Reg(47);
      F3PS1Reg <= line3Reg(46);
      F3FUDReg <= line3Reg(45);
    end if;
  end process;

  F3FREQ_PS0 <= F3PS0Reg;
  F3FREQ_PS1 <= F3PS1Reg;
  F3FREQ_FUD <= F3FUDReg;
  
  F3FREQ_RST <= line3Reg(48);
--  F3FREQ_WR <= not line3Reg(43);  -- ACTIVE LOW
  F3FREQ_RD <= '1';

  F3FREQ_ADD <= line3Reg(42 downto 37);
  F3FREQ_D <= line3Reg(36 downto 29);
  
  F1AMP <= line1Reg(28 downto 19);
  
  GxReg <= line2Reg(28 downto 19); -- + "1000000000";  -- differential output (specific to MRI build)
  F2Amp <= GxReg;
  GyReg <= line3Reg(28 downto 19); -- + "1000000000"; -- differential output (specific to MRI build) 
  F3Amp <= GyReg;
  --F2AMP <= line2Reg(28 downto 19); 
  --F3AMP <= line3Reg(28 downto 19); 

  F1TTL <= line1Reg(53 downto 52);
  F2TTL <= line2Reg(53 downto 52);
  F3TTL <= line3Reg(53 downto 52);

  F1GATE <= line1Reg(54);
  F2GATE <= line2Reg(54);
  F3GATE <= line3Reg(54);
  
  F1UNBLANK_POS <= line1Reg(55);
  F1UNBLANK_NEG <= not line1Reg(55);
  F2UNBLANK_POS <= line2Reg(55);
  F2UNBLANK_NEG <= not line2Reg(55);
  F3UNBLANK_POS <= line3Reg(55);
  F3UNBLANK_NEG <= not line3Reg(55);

  ADOCLK <= CLK80Reg;

  --RCVR_PWDN <= not runReg;
  RCVR_PWDN <= '0';  -- ADC is always activated (2015 Jan 22)

  OCLK1a <= CLK160Reg;  -- CLK for DDS AD
  OCLK2a <= CLK160Reg;
  OCLK3a <= CLK160Reg;

  AMCLK1 <= CLK160Reg;
  AMCLK2 <= CLK160Reg;
  AMCLK3 <= CLK160Reg;
  
  GZCLK <= CLK160Reg;
  GzReg <= line3Reg(41 downto 32); --+"1000000000";  -- differential output (specific to MRI build)
  GZ <= GzReg;
 -- INVPLLLOCKED <= not pllLockedReg;
  INVTRANSBUSY <= not (transBusyReg or txBusyReg);  -- LED during signal acquisition & transfer
  RSTReg <= not RST;  --  RST button
  INVRUN <= not runReg;  -- LED during implementation of PPGs

  TTL_GND <= (others=>'0');

end RTL;
