library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;


entity receiver is
 generic(
       firLength: natural := 51;
--       firLength: natural := 135;
      -- maxComLength: natural :=1023;
       maxALBits: natural:=14;
       maxAL: natural:=16384
     );
    port(CLK160: in std_logic;
         CLK80: in std_logic;
         CLK20: in std_logic;
         RST: in std_logic;
         RUNQ: in std_logic;
        -- ADCLK: in std_logic;
        -- AQC: in std_logic;
        -- AQS: in std_logic;
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
end receiver;


architecture RTL of receiver is

  component quadDemodulator is
    port(CLK: in std_logic;
         RST: in std_logic; 
         SIG: in signed(13 downto 0);
         TRIG: out std_logic;
         SIG_C, SIG_S: out signed(13 downto 0)
         );
  end component;



  component signalAccumulator is
   generic(
       maxALBits: natural
     );
    port(CLK: in std_logic;
         RST: in std_logic;
         RUNQ: in std_logic;
         ACQ_PHASE: in std_logic_vector(1 downto 0);
         ACQ_START: in std_logic;
         SIG_C: in signed(31 downto 0);
         SIG_S: in signed(31 downto 0);
--         ASIG_C: in std_logic_vector(27 downto 0); --
--         ASIG_S: in std_logic_vector(27 downto 0); --
         ASIG_C: in std_logic_vector(31 downto 0); --
         ASIG_S: in std_logic_vector(31 downto 0); --
         DWN: in std_logic_vector(15 downto 0); 
         
         AL: in std_logic_vector(maxALBits-1 downto 0);
         NA: in std_logic_vector(31 downto 0);
         STEP: in std_logic_vector(15 downto 0);
         TRANS_ACTIVE: in std_logic;
         ACQ_ACTIVE: out std_logic;
  --       CA: out std_logic_vector(31 downto 0);
--         QSIG_C: out std_logic_vector(27 downto 0); --
--         QSIG_S: out std_logic_vector(27 downto 0); --
         QSIG_C: out std_logic_vector(31 downto 0); --
         QSIG_S: out std_logic_vector(31 downto 0); --

         ADDRESS: out std_logic_vector(maxALBits-1 downto 0);
         WE: out std_logic;
         ACCUM_OK: out std_logic
         );
  end component;



  component usbArbiter is
    port ( CLK : in  std_logic;
            RST : in  std_logic;
            RXF_N : in std_logic; 
            TXE_N : in std_logic;
            RD_N  : out std_logic;
            WR    : out std_logic;
            BUS_BUSY : out std_logic;
            TG_READY : in  std_logic;
            USB_DATA : inout  std_logic_vector( 7 downto 0 );
            TG_DO    : out std_logic_vector( 7 downto 0 );
            TG_DI    : in  std_logic_vector( 7 downto 0 );
            TG_RD    : out std_logic;
            TG_WR    : in  std_logic );
  end component;


--------- variables for quadrature demodulator ---------

  signal QDStateReg: std_logic_vector(2 downto 0):="000";
  signal sigReg: signed(13 downto 0);
  signal sigCReg, sigSReg: signed(13 downto 0);
  signal sigCLatchReg,sigSLatchReg: std_logic;

--------- variables for averager ---------

  signal avCStateReg, avSStateReg: std_logic_vector(4 downto 0):="00000";
  signal DFTrigCReg, DFTrigSReg: std_logic;
 
  type avSig is array (0 to 9) of signed(17 downto 0);
  signal avSigSReg,avSigCReg: avSig;
    
  
--------- variables for digital filter ---------
  type coeff is array(0 to firLength-1) of signed(9 downto 0);
  signal DFcoeff: coeff;

  type DFQ is array(0 to firLength-1) of signed(23 downto 0);
  signal CQRealReg, CQImagReg: DFQ;

  type DFS is array(0 to firLength-1) of signed(31 downto 0);
  signal CSRealReg, CSImagReg: DFS;

  type FID is array(0 to maxAL-1) of std_logic_vector(31 downto 0);
  signal FID_real, FID_imag: fid;

  signal qdTrigReg: std_logic;
--  signal C50nsLatchReg, S50nsLatchReg: std_logic;
  
  signal sigCReg2a,sigCReg2b,sigSReg2a,sigSReg2b: signed(31 downto 0);
  
  signal sigCReg3, sigSReg3: signed(31 downto 0);
 
  signal datBuf32Reg: std_logic_vector(31 downto 0);
  signal add1Reg, add2Reg, addQReg: std_logic_vector(maxALBits-1 downto 0);
  signal acqActiveReg: std_logic;
  signal AsigCReg, AsigSReg: std_logic_vector(31 downto 0);
  signal QsigCReg, QsigSReg: std_logic_vector(31 downto 0);
  signal accumOKReg, transActiveReg, weReg: std_logic;
  signal readyCReg, readySReg: std_logic;
  signal diReg, doReg: std_logic_vector(7 downto 0);
  signal tgrdReg, tgwrReg, busBusyReg, readyReg: std_logic;

  signal QDRSTReg, QDRSTReg_SYNC, aReg, bReg: std_logic;
  signal samplingTriggerReg, sTrigReg, nsTrigReg: std_logic;
  
  signal alReg,dwReg,naReg,stReg,afReg: std_logic_vector(31 downto 0);

  signal INTF_stateReg: std_logic_vector(7 downto 0):=x"00";
  signal kReg: integer range 0 to 63;  -- counter

begin
  alReg <= AL;
  dwReg <= DW;
  naReg <= NA;
  stReg <= ST;
  afReg <= AF;

  process(CLK20) begin
    if(CLK20'event and CLK20='1') then
      if (CO_WR='1') then
        dfCoeff(to_integer(unsigned(CO_ADDRESS))) <= signed(CO_DATA(9 downto 0));
      end if;
    end if;
  end process;
  
  -----------------------   		
  --   Receiver gate   --
  -----------------------
  process(CLK80) begin
    if(CLK80'event and CLK80='1') then
      if (RG='0') then
        sigReg<=(others=>'0');
      else 
        sigReg<=SIG;
      end if;
    end if;
  end process;

---- detection of rising edge in the QDRST signal ----
  process(CLK80) begin
    if(CLK80'event and CLK80='1') then
      aReg <= QDRSTReg;
      bReg <= not aReg;
    end if;
  end process;

  QDRSTReg_SYNC <= aReg and bReg; 
-------------------------------------------------------


---- Main of quadrature demodulation ---------
  process(CLK80) begin
    if(CLK80'event and CLK80='1') then
      if QDRSTReg_SYNC='1' then 
		  if(afReg(0)='0') then QDstateReg <= "000"; else QDStateReg <= "100"; end if;       
      else
        case QDStateReg is
          when "000" => 
			   sigCReg <= sigReg;
				sigCLatchReg <= '1';
				sigSLatchReg <= '0';
--				C50nsLatchReg <= '1';
--				S50nsLatchReg <= '0';
            QDStateReg <= "001";
          when "001" => 
			   sigSReg <= sigReg;
				sigCLatchReg <= '0';
				sigSLatchReg <= '1';
--				C50nsLatchReg <= '0';
--				S50nsLatchReg <= '1';
				QDStateReg <= "010"; 
			 when "010" => 
			   sigCReg <= -sigReg;
				sigCLatchReg <= '1';
				sigSLatchReg <= '0';
--				C50nsLatchReg <= '0';
--				S50nsLatchReg <= '0';
				QDStateReg <= "011";
          when "011" => 
			   sigSReg <= -sigReg; 
				sigCLatchReg <= '0';
				sigSLatchReg <= '1';
--				C50nsLatchReg <= '0';
--				S50nsLatchReg <= '0';
				QDStateReg <= "000";

          when "100" => 
			   sigCReg <= sigReg;
				sigCLatchReg <= '1';
				sigSLatchReg <= '0';
--				C50nsLatchReg <= '1';
--				S50nsLatchReg <= '0';
            QDStateReg <= "101";
          when "101" => 
			   sigSReg <= sigReg;
				sigCLatchReg <= '0';
				sigSLatchReg <= '1';
--				C50nsLatchReg <= '0';
--				S50nsLatchReg <= '1';
				QDStateReg <= "100"; 
				
			when others => QDStateReg <= "000";
        end case;
      end if; -- RST;
    end if; -- CLK
  end process;

  
---- detection of the leading edge of sampling trigger ----
  process(CLK80) begin
    if(CLK80'event and CLK80='1') then
      sTrigReg <= ACQ_START;
      nsTrigReg <= not sTrigReg;
    end if;
  end process;

  samplingTriggerReg <= sTrigReg and nsTrigReg;
-----------------------------------------------------------

  
  --
  --  [Signal averager]
  --
  --  This module receives the demodulated in-phase and quadrature signals,
  --  which is updated at a rate of 40 MHz. Here the signals are averaged 
  --  over 10 times, and sent to the digital filter. That is, the input signal 
  --  of the digital filter will be updated at a rate of 40/10=4 MHz.
  --
  process(CLK80) begin
    if(CLK80'event and CLK80='1') then
      if(samplingTriggerReg='1') then  -- synchronization with the sampling trigger
--      if(QDRSTReg_SYNC='1') then
	     avCStateReg <= "00000"; 
      else
      case avCStateReg is  	  
	     when "00000"=> if(sigCLatchReg='1') then avCStateReg<="00001"; end if;
	     when "00001"=> if(sigCLatchReg='1') then avCStateReg<="00011"; end if;
	     when "00011"=> if(sigCLatchReg='1') then avCStateReg<="00111"; end if;
	     when "00111"=> if(sigCLatchReg='1') then avCStateReg<="01111"; end if;
	     when "01111"=> if(sigCLatchReg='1') then avCStateReg<="11111"; end if;
	     when "11111"=> if(sigCLatchReg='1') then avCStateReg<="11110"; end if;
	     when "11110"=> if(sigCLatchReg='1') then avCStateReg<="11100"; end if;
	     when "11100"=> if(sigCLatchReg='1') then avCStateReg<="11000"; end if;
	     when "11000"=> if(sigCLatchReg='1') then avCStateReg<="10000"; end if;
	     when "10000"=> if(sigCLatchReg='1') then avCStateReg<="00000"; end if;
	     when others => avCStateReg<="00000"; 
      end case;
		end if;
    end if;
  end process;
	       
  dfTrigCReg <= '1' when avCStateReg="10000" else '0';
    

  process(CLK80) begin
    if(CLK80'event and CLK80='1') then
      if(samplingTriggerReg='1') then  -- synchronization with the sampling trigger
--      if(QDRSTReg_SYNC='1') then
	     avSStateReg <= "00000"; 
      else
      case avSStateReg is  	  
	     when "00000"=> if(sigSLatchReg='1') then avSStateReg<="00001"; end if;
	     when "00001"=> if(sigSLatchReg='1') then avSStateReg<="00011"; end if;
	     when "00011"=> if(sigSLatchReg='1') then avSStateReg<="00111"; end if;
	     when "00111"=> if(sigSLatchReg='1') then avSStateReg<="01111"; end if;
	     when "01111"=> if(sigSLatchReg='1') then avSStateReg<="11111"; end if;
	     when "11111"=> if(sigSLatchReg='1') then avSStateReg<="11110"; end if;
	     when "11110"=> if(sigSLatchReg='1') then avSStateReg<="11100"; end if;
	     when "11100"=> if(sigSLatchReg='1') then avSStateReg<="11000"; end if;
	     when "11000"=> if(sigSLatchReg='1') then avSStateReg<="10000"; end if;
	     when "10000"=> if(sigSLatchReg='1') then avSStateReg<="00000"; end if;
	     when others => avSStateReg<="00000"; 
      end case;
		end if;
    end if;
  end process;
	       
  dfTrigSReg <= '1' when avSStateReg="10000" else '0';
  
  process(CLK80)
  begin
    if (CLK80'event and CLK80='1') then
      if (sigCLatchReg='1') then
        avSigCReg(0) 
	       <= sigCReg(13) & sigCReg(13) & sigCReg(13) & sigCReg(13) & sigCReg;
        for I in 1 to 9 loop
	       avSigCReg(I) <= avSigCReg(I-1) 
		      + (sigCReg(13) & sigCReg(13) & sigCReg(13) & sigCReg(13) & sigCReg);
	     end loop;
      end if;
    end if;
  end process;	 

  process(CLK80)
  begin
    if (CLK80'event and CLK80='1') then
      if (sigSLatchReg='1') then
        avSigSReg(0) 
	       <= sigSReg(13) & sigSReg(13) & sigSReg(13) & sigSReg(13) & sigSReg;
        for I in 1 to 9 loop
	       avSigSReg(I) <= avSigSReg(I-1) 
		      + (sigSReg(13) & sigSReg(13) & sigSReg(13) & sigSReg(13) & sigSReg);
	     end loop;
      end if;
    end if;
  end process;	 

------------   END OF SIGNAL AVERAGER   ------------
	
-------------------  FIR FILTER  ------------------

process(CLK80)
begin
if (CLK80'event and CLK80='1') then
  if (DFTrigCReg='1') then
    for I in 0 to firLength-1 loop
      CQRealReg(I) <= avSigCReg(9)(17 downto 4) * DFcoeff(I);
    end loop;

      CSRealReg(0) <= 
		    CQRealReg(0)(23) & CQRealReg(0)(23) & CQRealReg(0)(23) & 
			 CQRealReg(0)(23) & CQRealReg(0)(23) & CQRealReg(0)(23) & 
			 CQRealReg(0)(23) & CQRealReg(0)(23) & CQRealReg(0)(23) & 
			 CQRealReg(0)(23) & CQRealReg(0)(21 downto 0);

    for I in 1 to firLength-1 loop
      CSRealReg(I) <= CSRealReg(I-1) 
		               + (
							CQRealReg(I)(23) & CQRealReg(I)(23) & CQRealReg(I)(23) & 
							CQRealReg(I)(23) & CQRealReg(I)(23) & CQRealReg(I)(23) & 
							CQRealReg(I)(23) & CQRealReg(I)(23) & CQRealReg(I)(23) & 
							CQRealReg(I)(23) & CQRealReg(I)(21 downto 0));
    end loop;
  end if; -- 
end if; -- CLK
end process;


process(CLK80)
begin
if (CLK80'event and CLK80='1') then
  if (DFTrigSReg='1') then
    for I in 0 to firLength-1 loop
      CQImagReg(I) <= avSigSReg(9)(17 downto 4) * DFcoeff(I);
    end loop;

    CSImagReg(0) <= 
	       CQImagReg(0)(23) & CQImagReg(0)(23) & CQImagReg(0)(23) & 
			 CQImagReg(0)(23) & CQImagReg(0)(23) & CQImagReg(0)(23) & 
			 CQImagReg(0)(23) & CQImagReg(0)(23) & CQImagReg(0)(23) & 
	       CQImagReg(0)(23) & CQImagReg(0)(21 downto 0);

    for I in 1 to firLength-1 loop
      CSImagReg(I) <= CSImagReg(I-1)
	              	+ (
						CQImagReg(I)(23) & CQImagReg(I)(23) & CQImagReg(I)(23) & 
						CQImagReg(I)(23) & CQImagReg(I)(23) & CQImagReg(I)(23) & 
						CQImagReg(I)(23) & CQImagReg(I)(23) & CQImagReg(I)(23) & 
						CQImagReg(I)(23) & CQImagReg(I)(21 downto 0));
    end loop;
  end if; -- 
end if; -- CLK
end process;

---------------  END OF FIR FILTER -----------------


------------------------------------------------
--  signal multiplexer according to           --
--  whether digital filtration is used        --
------------------------------------------------

process(CLK80)
begin
  if (CLK80'event and CLK80='1') then
--    if (DFTrigCReg='1') then sigCReg2a <= CSRealReg(to_integer(unsigned(CO_LENGTH))); end if;
--    if (DFTrigSReg='1') then sigSReg2a <= CSImagReg(to_integer(unsigned(CO_LENGTH))); end if;
    if (DFTrigCReg='1') then sigCReg2a <= CSRealReg(firLength-1); end if;
    if (DFTrigSReg='1') then sigSReg2a <= CSImagReg(firLength-1); end if;
  end if;
end process;

process(CLK80)
begin
  if (CLK80'event and CLK80='1') then
	   if (sigCLatchReg='1') then
--	   if (C50nsLatchReg='1') then
        sigCReg2b <= sigCReg(13) & sigCReg(13) & sigCReg(13) &
		 sigCReg(13) & sigCReg(13) & sigCReg(13) &
		sigCReg(13) & sigCReg(13) & sigCReg(13) &
	sigCReg(13) & sigCReg(13) & sigCReg(13) &	
                    sigCReg(13) & sigCReg(13) & sigCReg(13) &
                    sigCReg(13) & sigCReg(13) & sigCReg(13) & sigCReg;
		end if;
  	   if (sigSLatchReg='1') then
--  	   if (S50nsLatchReg='1') then
        sigSReg2b <= sigSReg(13) & sigSReg(13) & sigSReg(13) &
		  sigSReg(13) & sigSReg(13) & sigSReg(13) &
		  sigSReg(13) & sigSReg(13) & sigSReg(13) &
		  sigSReg(13) & sigSReg(13) & sigSReg(13) &
                  sigSReg(13) & sigSReg(13) & sigSReg(13) &
                  sigSReg(13) & sigSReg(13) & sigSReg(13) & sigSReg;
      end if;
  end if;
end process;

with AFReg(1) select   -- second bit
  sigCReg3 <= sigCReg2b when '0',  -- no FIR
				  sigCReg2a when '1';  -- FIR
              
with AFReg(1) select
  sigSReg3 <= sigSReg2b when '0',  -- no FIR
				  sigSReg2a when '1';  -- FIR

--------------   RCVR RAM   -------------------
----   REAL component   ----
  process(CLK160,weReg)
  begin
    if (CLK160'event and CLK160 = '1') then
      if (weReg = '1') then
	     FID_real(to_integer(unsigned(addQReg))) <= QsigCReg;
      end if; -- accumTriggerReg
      AsigCReg <= FID_real(to_integer(unsigned(addQReg)));
    end if; -- CLK160
  end process;

---- IMAGINARY component ----
  process(CLK160,weReg)
  begin
    if (CLK160'event and CLK160 = '1') then
      if (weReg = '1') then
 	     FID_imag(to_integer(unsigned(addQReg))) <= QsigSReg;
      end if; -- accumTriggerReg
      AsigSReg <= FID_imag(to_integer(unsigned(addQReg)));
    end if; -- CLK80
  end process;
------------------------------


  U2: signalAccumulator 
       generic map(
         maxALBits=>maxALBits
        )         
       port map(
         CLK=>CLK160,
--         RST=>QDRSTReg_SYNC,
         RST=>samplingTriggerReg,
         RUNQ=>RUNQ,
         ACQ_PHASE=>ACQ_PHASE,
         ACQ_START=>ACQ_START,
         SIG_C=>sigCReg3,
         SIG_S=>sigSReg3,
         ASIG_C=>AsigCReg, 
         ASIG_S=>AsigSReg, 
         DWN=>dwReg(15 downto 0), 
         AL=>alReg(maxALBits-1 downto 0),
         NA=>naReg,
         STEP=>stReg(15 downto 0),
         TRANS_ACTIVE=>transActiveReg,
         ACQ_ACTIVE=>acqActiveReg,
    --     CA=>caReg,
         QSIG_C=>QsigCReg, 
         QSIG_S=>QsigSReg, 
         ADDRESS=>add1Reg,
         WE=>weReg,
         ACCUM_OK=>accumOKReg
         );

  ACQ_BUSY <= acqActiveReg;

-- RCVR RAM Address multiplexer

with transActiveReg select addQReg <= ADD1Reg when '0',
                                      ADD2Reg when '1';

  U7: usbArbiter port map(
            CLK=>CLK20,
            RST=>RST,
            RXF_N=>RXF_N,
            TXE_N=>TXE_N,
            RD_N=>RD_N,
            WR=>WR,
            BUS_BUSY=>busBusyReg,
            TG_READY=>readyReg,
            USB_DATA=>USBDATA,
            TG_DO=>diReg,
            TG_DI=>doReg,
            TG_RD=>tgrdReg,
            TG_WR=>tgwrReg
           );

-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++



  TRANS_BUSY <= transActiveReg;
  

  process(CLK20) begin
  if (CLK20'event and CLK20='1') then
    if RST='1' then 
--      bufLength <= 0;
      transActiveReg <= '0';
      INTF_stateReg <= x"00";
    else
      case INTF_stateReg is

    -- MAIN --
        when x"00" => 
          INTF_stateReg <= x"01";
          transActiveReg <= '0';

        when x"01" =>
          if (runQ='1') then
            QDRSTReg <= '1';
            INTF_stateReg <= x"F0";
          else
            QDRSTReg <= '0';
            INTF_stateReg <= x"01";
          end if;

    --  RUN --
        when x"F0" => 
          QDRSTReg <= '0';
          transActiveReg <= '0';
          readyReg <= '0';
--          bufLength <= 0;
          tgwrReg <= '0';
          if (RUNQ='0') then
            readyReg <= '1';
            INTF_stateReg <= x"00";
          else
            INTF_stateReg <= x"F1";
          end if;
          
        when x"F1" =>
          if (RUNQ='0') then
            INTF_stateReg <= x"00";
          elsif (accumOKReg='1') then
            transActiveReg <= '1';
            add2Reg <= (others => '0');
            INTF_stateReg <= x"F2";
          else
            INTF_stateReg <= x"F1";
          end if;

        when x"F2" =>
          kReg <= 1;
          INTF_stateReg <= x"F3";

        when x"F3" =>
          INTF_stateReg <= x"F4";

        when x"F4" =>
          case kReg is
            when 1 => doReg <= AsigCReg(31 downto 24); INTF_stateReg <= x"F5";
            when 2 => doReg <= AsigCReg(23 downto 16); INTF_stateReg <= x"F5";
            when 3 => doReg <= AsigCReg(15 downto 8); INTF_stateReg <= x"F5";
            when 4 => doReg <= AsigCReg(7 downto 0); INTF_stateReg <= x"F5";
            when 5 => doReg <= AsigSReg(31 downto 24); INTF_stateReg <= x"F5";
            when 6 => doReg <= AsigSReg(23 downto 16); INTF_stateReg <= x"F5";
            when 7 => doReg <= AsigSReg(15 downto 8); INTF_stateReg <= x"F5";
            when 8 => doReg <= AsigSReg(7 downto 0); INTF_stateReg <= x"F5";
            when others => INTF_stateReg <= x"F7";
          end case;
        
        when x"F5" =>
          if (busBusyReg='0') then 
            tgwrReg <= '1';
            kReg <= kReg + 1;
            INTF_stateReg <= x"F6";
          elsif (RUNQ='0') then
            INTF_stateReg <= x"00";
          else
            INTF_stateReg <= x"F5";
          end if;
        
        when x"F6" =>
          tgwrReg <= '0';
          INTF_stateReg <=x"F4";

        when x"F7" =>
          if (add2Reg=alReg) then
            readyReg <= '1';
            INTF_stateReg <= x"F8";
          else
            add2Reg <= add2Reg + '1';
            INTF_stateReg <= x"F2";
          end if;

       when x"F8" =>
         if (tgrdReg='1') then 
--         ackFromPCReg <= diReg;

           INTF_stateReg <= x"F0";
			  
         elsif (RUNQ='0') then -- in case PPG is aborted
                               -- Without this, the process may fall into
           INTF_stateReg <= x"00";     -- an infinite loop here at x"F8"!!
         else
           INTF_stateReg <= x"F8";
         end if;
        
    -- end of RUN --
    
         when others => INTF_stateReg <= x"00";
      end case;
    end if; -- RST
  end if; -- CLK20
  end process;

end RTL;
