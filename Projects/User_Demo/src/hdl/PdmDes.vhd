----------------------------------------------------------------------------------
----------------------------------------------------------------------------
-- Author:  Mihaita Nagy
--          Copyright 2014 Digilent, Inc.
----------------------------------------------------------------------------
-- 
-- Create Date:    14:24:36 04/02/2013 
-- Design Name: 
-- Module Name:    PdmDes - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description:
--       This module represents the deserializer of the microphone data. The module generates
--    the pdm_m_clk_o signal to the ADMP421 Microphone (M_CLK) and data is read on the positive
--    edge of this signal.
--
--       Then the module deserializes the signal on 16 bits when en_i = '1' (it means that recoding
--    is going on)
--
--       The module also generates the pdm_clk_rising_o signal, that is active when the positive edge of the
--    pdm_m_clk_o signal occures. This signal is used in the VGA controller, the MicDisplay component to
--    display audio data on the screen. The signal is two system clock period length, in order to make it
--    easier the synchronizing with the VGA clock domain (108MHz)
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity PdmDes is
   generic(
      C_NR_OF_BITS : integer := 16;
      C_SYS_CLK_FREQ_MHZ : integer := 100;
      C_PDM_FREQ_HZ : integer := 2000000
   );
   port(
      clk_i : in std_logic;
      rst_i : in std_logic;
      en_i : in std_logic; -- Enable deserializing (during record)
      
      done_o : out std_logic; -- Signaling that 16 bits are deserialized
      data_o : out std_logic_vector(C_NR_OF_BITS - 1 downto 0); -- output deserialized data
      
      -- PDM
      pdm_m_clk_o : out std_logic; -- Output M_CLK signal to the microphone
      pdm_m_data_i : in std_logic; -- Input PDM data from the microphone
      pdm_lrsel_o : out std_logic; -- Set to '0', therefore data is read on the positive edge
      pdm_clk_rising_o : out std_logic -- Signaling the rising edge of M_CLK, used by the MicDisplay
                                       -- component in the VGA controller
   );
end PdmDes;

architecture Behavioral of PdmDes is

------------------------------------------------------------------------
-- Signal Declarations
------------------------------------------------------------------------
-- Divider to create pdm_m_clk_0
signal cnt_clk : integer range 0 to 127 := 0;
-- Internal pdm_m_clk_o signal
signal clk_int : std_logic := '0';

-- Piped clk_int signal to create pdm_clk_rising
signal clk_intt : std_logic := '0';
signal pdm_clk_rising : std_logic;

-- Shift register to deserialize incoming microphone data
signal pdm_tmp : std_logic_vector((C_NR_OF_BITS - 1) downto 0);
-- Count the number of bits
signal cnt_bits : integer range 0 to C_NR_OF_BITS - 1 := 0;

-- To create a pdm_clk_rising impulse of two clock period length
-- This signal will be registered in the mic_display module on the 108MHz pxlclk
signal pdm_clk_rising_reg  : std_logic_vector (2 downto 0);

signal clk_cntr_reg : std_logic_vector (11 downto 0) := (others=>'0'); 

------------------------------------------------------------------------
-- Module Implementation
------------------------------------------------------------------------
begin

   -- with L/R Sel tied to GND => output = DATA1 (rising edge)
   pdm_lrsel_o <= '0';

------------------------------------------------------------------------
-- Deserializer
------------------------------------------------------------------------
-- Sample input serial data process
   SHFT_IN: process(clk_i) 
   begin 
      if rising_edge(clk_i) then
         if en_i = '1' and pdm_clk_rising = '1' then 
            pdm_tmp <= pdm_tmp(C_NR_OF_BITS-2 downto 0) & pdm_m_data_i;
         end if; 
      end if;
   end process SHFT_IN;
   

-- Count the number of sampled bits
   CNT: process(clk_i) begin
      if rising_edge(clk_i) then
         if en_i = '1' and pdm_clk_rising = '1' then
            if cnt_bits = (C_NR_OF_BITS-1) then
               cnt_bits <= 0;
            else
               cnt_bits <= cnt_bits + 1;
            end if;
         end if;
      end if;
   end process CNT;

-- Generate the done signal
   process(clk_i) 
   begin
      if rising_edge(clk_i) then
         if en_i = '1' and pdm_clk_rising = '1' then
            if cnt_bits = (C_NR_OF_BITS-1) then
               done_o <= '1';
               data_o <= pdm_tmp;
            end if;
         else
            done_o <= '0';
         end if;
      end if;
   end process;

-- Generate PDM Clock
   CLK_CNT: process(clk_i)
   begin
      if rising_edge(clk_i) then
         if rst_i = '1' or cnt_clk = ((C_SYS_CLK_FREQ_MHZ*1000000/(C_PDM_FREQ_HZ*2))-1) then
            cnt_clk <= 0;
            clk_int <= not clk_int;
         else
            cnt_clk <= cnt_clk + 1;
         end if;
         clk_intt <= clk_int;
      end if;
   end process CLK_CNT;

   
   pdm_m_clk_o <= clk_int;
   pdm_clk_rising <= '1' when clk_int = '1' and clk_intt = '0' else '0';

-- Register pdm_clk_rising 
-- to create a two clock period length impulse
   RISING_IMP: process(clk_i)
   begin
      if rising_edge(clk_i) then
         pdm_clk_rising_reg <= pdm_clk_rising_reg (1 downto 0) & pdm_clk_rising;
      end if;
   end process RISING_IMP;
   
-- Assign the output pdm_clk_rising impulse
   ASSIGN_PDM_CLK_RISING_IMP: process(clk_i)
   begin
      if rising_edge(clk_i) then
         pdm_clk_rising_o <= (pdm_clk_rising_reg(0) or pdm_clk_rising_reg(1)) and (not pdm_clk_rising_reg(2));
      end if;
   end process ASSIGN_PDM_CLK_RISING_IMP;

end Behavioral;
