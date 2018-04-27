------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity phaseController is
  port( CLK1,CLK2: in std_logic;
    --  160, 20 MHz
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
end phaseController;

architecture RTL of phaseController is

signal QReg, phaseWordReg: std_logic_vector(9 downto 0);
signal qRSTReg: std_logic;
signal phMemReg, phMem2Reg, phaseWord1Reg: std_logic_vector(9 downto 0);
signal phAccStateReg: std_logic_vector(1 downto 0):="00";

signal aReg, bReg: std_logic;

  component phaseCycleMemoryArray
    port(CLK,RST: in std_logic;
         ACQ_CS: in std_logic;
         SEL: in std_logic_vector(3 downto 0);
         TOGGLE: in std_logic;
         INIT: in std_logic;
         COMMAND: in std_logic;
         MODE: in std_logic_vector(1 downto 0);
         D: in std_logic_vector(9 downto 0); 
         Q: out std_logic_vector(9 downto 0);
         ACQ_Q: out std_logic_vector(1 downto 0)
        );
  end component;

  component QuadDDS20MHz
    port( CLK, RST: in std_logic;
          PHASE_WORD: in std_logic_vector(9 downto 0);
          DA_COS: out std_logic_vector(9 downto 0)
         );
  end component;

begin



process(CLK1) begin
  if (CLK1'event and CLK1='1') then    
    phaseWord1Reg <= PHASE_WORD + phMemReg;
    phaseWordReg <= QReg + phaseWord1Reg;
--      phaseWordReg <= PHASE_WORD+QReg;
  end if;-- CLK1
end process;


process(CLK1) begin
  if (CLK1'event and CLK1='1') then
    if (phAccRST='1') then    
      phMemReg <= (others =>'0');
      phMem2Reg <= (others =>'0');    
      phAccStateReg<="00";
    else
      case phAccStateReg is
      when "00" =>
        phMemReg <= (others =>'0');
        phMem2Reg <= (others =>'0');
        if PHACC='1' then phAccstateReg <= "01"; else phAccstateReg <="00"; end if;
      when "01" =>
        if PPGLINELATCH='1' then
          phMemReg <= phMem2Reg; 
          phAccstateReg <= "10"; 
        else 
          phAccstateReg <="01"; 
        end if;

      when "10" => phAccStateReg <="11";
          
      when "11" =>  
        phMem2Reg <= phaseWord1Reg; 
        phAccStateReg <="01";  
      end case; -- case
    end if; --  phAccRST
  end if;-- CLK3
end process;


  U1: phaseCycleMemoryArray port map(
         CLK=>CLK2,
         RST=>ALL_INIT,
         ACQ_CS=>ACQ_CS,
         SEL=>SEL,
         TOGGLE=>TOGGLE,
         INIT=>INIT,
         COMMAND=>COMMAND,
         MODE=>MODE,
         D=>PHASE_WORD, 
         Q=>QReg,
         ACQ_Q=>ACQ_PHASE
        );

---- detection of rising edge of RST  ----

  process(CLK1) begin
    if(CLK1'event and CLK1='1') then
      aReg <= RST;
      bReg <= not aReg;
    end if;
  end process;

  qRSTReg <= aReg and bReg; 
------------------------------------------
		  

  U2: QuadDDS20MHz port map(
          CLK=>CLK1,
          RST=>qRSTReg,
          PHASE_WORD=>phaseWordReg,
          DA_COS=>DA_COS
         );
  
end RTL;

------------------------------------------------------------