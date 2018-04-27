-- usbArbiter --
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity usbArbiter is
  port (CLK: in std_logic;
        RST: in std_logic;
        RXF_N: in std_logic;
        TXE_N: in std_logic;
        RD_N: out std_logic;
        WR: out std_logic;
        BUS_BUSY: out std_logic;
        TG_READY: in std_logic;
        USB_DATA: inout std_logic_vector( 7 downto 0 );
        TG_DO: out std_logic_vector( 7 downto 0 );
        TG_DI: in  std_logic_vector( 7 downto 0 );
        TG_RD: out std_logic;
        TG_WR: in  std_logic 
       );
end usbArbiter;

architecture RTL of usbArbiter is

signal RXF_REG: std_logic;
signal TXE_REG: std_logic;
signal USB_DATA_REG: std_logic_vector(7 downto 0);
signal DIR: std_logic;
signal RDStateReg: std_logic_vector(1 downto 0);
signal WRStateReg: std_logic_vector(1 downto 0);
constant S0: std_logic_vector := "00";
constant S1: std_logic_vector := "01";
constant S2: std_logic_vector := "10";
constant S3: std_logic_vector := "11";

begin

USB_DATA <= USB_DATA_REG when (DIR = '1') else "ZZZZZZZZ";
BUS_BUSY <= '0' when( WRStateReg="00" and RDStateReg="00" ) else '1';

process(CLK, RST) begin
  if ( RST ='1') then
    RXF_REG <= '0';
    TXE_REG <= '0';
  elsif( CLK'event and CLK='1') then
    RXF_REG <= not RXF_N;
    TXE_REG <= not TXE_N;
  else
    NULL;
  end if;
end process;

-- READ --
process(CLK, RST) begin
if (RST ='1') then
  TG_DO <= "00000000";
  TG_RD <= '0';
  RD_N  <= '1';
  RDStateReg <= S0;
elsif( CLK'event and CLK='1') then
  case RDStateReg is
    when S0 =>
      if( RXF_REG='1' and TG_READY='1' and WRStateReg="00") then
        RD_N     <= '0';
        RDStateReg <= S1;
      else
        RDStateReg <= S0;
      end if;

    when S1 =>
      TG_DO <= USB_DATA;
      RDStateReg <= S2;

    when S2 =>
      RD_N     <= '1'; 
      TG_RD    <= '1';
      RDStateReg <= S3;

    when S3 =>
      TG_RD    <= '0';
      RDStateReg <= S0;

    when others => RDStateReg <= S0;

  end case;
end if;
end process;

-- WRITE --
process(CLK, RST) begin
  if(RST ='1') then
    WR <= '1';
    DIR <= '0';
    WRStateReg <= S0;
  elsif( CLK'event and CLK='1') then
    case WRStateReg is
      when S0 =>
        if( TG_WR='1') then
          USB_DATA_REG <= TG_DI;
          WRStateReg <= S1;
        else
          WRStateReg <= S0;
        end if;

      when S1 =>
        if (TXE_REG='1' and RDStateReg="00") then
          WR <= '1';
          DIR <='1';
          WRStateReg <= S2;
        else
          WRStateReg <= S1;
        end if;

      when S2 =>
        WR <= '0';
        DIR <= '1';
        WRStateReg <= S3;

      when S3 =>
        WR <= '1';
        DIR <= '0';
        WRStateReg <= S0;

      when others => WRStateReg <= S0;

    end case;
  end if;
end process;

end RTL;