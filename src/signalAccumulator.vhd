------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity signalAccumulator is
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
      ASIG_C: in std_logic_vector(31 downto 0); --
      ASIG_S: in std_logic_vector(31 downto 0); --
      DWN: in std_logic_vector(15 downto 0);
      AL: in std_logic_vector(maxALBits-1 downto 0);
      NA: in std_logic_vector(31 downto 0);
      STEP: in std_logic_vector(15 downto 0);
      TRANS_ACTIVE: in std_logic;
      ACQ_ACTIVE: out std_logic;
      QSIG_C: out std_logic_vector(31 downto 0); --
      QSIG_S: out std_logic_vector(31 downto 0); -- 
      ADDRESS: out std_logic_vector(maxALBits-1 downto 0);
      WE: out std_logic;
      ACCUM_OK: out std_logic
      );
end signalAccumulator;

architecture RTL of signalAccumulator is

  signal QReg: std_logic := '0';

  constant L0: std_logic_vector(4 downto 0) := "00000";
  constant L1: std_logic_vector(4 downto 0) := "00001";
  constant L2: std_logic_vector(4 downto 0) := "00011";

  constant A0: std_logic_vector(4 downto 0) := "01000";
  constant A1: std_logic_vector(4 downto 0) := "01001";
  constant A2: std_logic_vector(4 downto 0) := "01011";
  constant A3: std_logic_vector(4 downto 0) := "01111";
  constant A4: std_logic_vector(4 downto 0) := "01110";
  constant A5: std_logic_vector(4 downto 0) := "01100";

  constant B0: std_logic_vector(4 downto 0) := "10000";
  constant B1: std_logic_vector(4 downto 0) := "10001";
  constant B2: std_logic_vector(4 downto 0) := "10011";
  constant B0_5: std_logic_vector(4 downto 0) := "10111";



  signal stateReg: std_logic_vector(4 downto 0) := L0;
--  signal accumStateReg: std_logic_vector(4 downto 0):=L0;
  signal countStateReg: std_logic_vector(15 downto 0):=x"0000";
  signal QStateReg: std_logic_vector(1 downto 0):="00";
  signal alReg: std_logic_vector(maxALBits-1 downto 0);
  signal naReg: std_logic_vector(31 downto 0);
  signal stepReg: std_logic_vector(15 downto 0);

  signal readyCReg, readySReg, acqActiveReg: std_logic;

  signal addressReg: std_logic_vector(maxALBits-1 downto 0);
  signal weReg: std_logic;
  
  signal caReg: std_logic_vector(31 downto 0);
  signal cbReg: std_logic_vector(15 downto 0);

  signal cReg: std_logic_vector(15 downto 0);
  signal samplingTriggerReg: std_logic;

  signal sigCReg, sigSReg: signed(31 downto 0);
  signal accumCReg, accumSReg: signed(31 downto 0);
  signal AsigCReg, AsigSReg: signed(31 downto 0);
  signal QsigCReg, QsigSReg: signed(31 downto 0);
  
  signal addTrigReg:std_logic;
  signal accumOKReg: std_logic;

begin

  process(CLK) begin
    if (CLK'event and CLK='1') then
        sigCReg <= SIG_C;
        sigSReg <= SIG_S;
    end if; -- CLK
  end process;


  alReg <= AL;   
  naReg <= X"00000001" when NA=X"00000000" else NA;
  stepReg <= x"0001" when STEP=x"0000" else STEP;

  ACQ_ACTIVE <= acqActiveReg;

  QSIG_C <= std_logic_vector(QsigCReg);
  QSIG_S <= std_logic_vector(QsigSReg);
  ADDRESS <= addressReg;
  WE <= weReg;
  ACCUM_OK <= accumOKReg;


  process(CLK) begin
    if (CLK'event and CLK='1') then
      if (to_integer(unsigned(cbReg))=0) then
          AsigCReg <= (others => '0');
          AsigSReg <= (others => '0');
        else                   
          AsigCReg <= signed(ASIG_C);
          AsigSReg <= signed(ASIG_S);
      end if; -- 
    end if; -- CLK
  end process;


  with ACQ_PHASE select
    accumCReg <= sigCReg when "00", --   0
                -sigSReg when "01", --  90
                -sigCReg when "10", -- 180
                 sigSReg when "11"; -- 270

  with ACQ_PHASE select
    accumSReg <= sigSReg when "00", --   0
                 sigCReg when "01", --  90
                -sigSReg when "10", -- 180
                -sigCReg when "11"; -- 270



  process(CLK,RUNQ) begin
    if (CLK'event and CLK='1') then
      if (RUNQ='0') then
		  weReg <= '0';
        accumOKReg <= '0';
        acqActiveReg <= '0';
        addressReg <= (others =>'0');
        cbReg <= (others => '0');
		  caReg <= (others => '0');
        stateReg <= L0;
      else
      case stateReg is
        when L0 =>
		    weReg <= '0';
          accumOKReg <= '0';
          acqActiveReg <= '0';
          addressReg <= (others =>'0');
          caReg <= (others => '0');
          cbReg <= (others => '0');
          stateReg <= L1;

        when L1 =>
		    weReg <= '0';
          addressReg <= (others => '0');
          accumOKReg <= '0';
          acqActiveReg <= '0';
          if (ACQ_START='1' and TRANS_ACTIVE='0') then
                            -- TRANS_ACTIVE should also be monitored by the
                            -- pulse programmer, or the signal may not be 
                            -- acquired when the pulse delay (PD) is very short. 
           -- TRANS_ACTIVE also acts as an address selector for RCVR_RAM.
           -- i.e., TRANS_ACTIVE='1' means the control is on the RCVR_interface side,
           -- and only when TRANS_ACTIVE='0' can the signalAccumulator store data
           -- in RCVR_RAM.
            acqActiveReg <= '1';
            stateReg <= L2;
          else
            stateReg <= L1;
          end if;
			 
        when L2 =>
		    if (samplingTriggerReg = '1') then  
 			   QsigCReg <= AsigCReg + accumCReg;
            QsigSReg <= AsigSReg + accumSReg;
            weReg <= '1';
            stateReg <= A0;

			 else 
            stateReg <= L2;
          end if;

        when A0 => 
		    weReg <= '0';
          if (addressReg = alReg) then -- acquisition complete		  
 		      acqActiveReg <= '0';
            addressReg <= (others=>'0');
            caReg <= caReg + '1';
            cbReg <= cbReg + '1';
            stateReg <= B0;      
          else		  
            addressReg <= addressReg + '1';
  			   stateReg <= L2;
          end if;
		          
        when B0 =>
			 if (cbReg=stepReg) then
            cbReg<=(others=>'0');
            accumOKReg <= '1';
            stateReg <= B1;
          else
            stateReg <= B0_5;
          end if;

        when B0_5 =>
          if (caReg=naReg) then
            accumOKReg <= '1';
            stateReg <= B1;
          else 
            stateReg <= L1;
          end if;

        when B1 => 
          if (TRANS_ACTIVE='1') then
            accumOKReg <= '0';
            stateReg <= L1;
          else
            stateReg <= B1;
          end if;
        when others => stateReg <= L0;

      end case;
    end if; -- RUNQ
    end if; -- CLK
  end process;


  process(CLK) begin
    if (CLK'event and CLK='1') then
      if (acqActiveReg='0') then
        cReg <= X"0001";
        samplingTriggerReg <= '0';
      elsif (QReg='1') then
        if (cReg/=DWN) then
          cReg <= cReg + '1';
          samplingTriggerReg <= '0';
        else
          cReg<=X"0001";
          samplingTriggerReg <= '1';
        end if;
		else -- QReg = '0'
          samplingTriggerReg <= '0';		
      end if; -- acqActiveReg
    end if; -- CLK
  end process;


  process(CLK,RST) begin
    if(CLK'event and CLK='1') then
      if(RST='1') then  -- synchronization with the sampling trigger
	     QReg <= '0';
		  QStateReg <= "00"; 
      else
		  case QStateReg is
		  when "00" => 
		    QReg <= '0';
		    QStateReg <= "01";
		  when "01" => 
		    QReg <= '1';
		    QStateReg <= "10";
		  when "10" => 
		    QReg <= '0';
		    QStateReg <= "11";
		  when "11" => 
		    QReg <= '0';
		    QStateReg <= "00";
			 
        end case;
	   end if;
    end if;
  end process;
	         


end RTL;
