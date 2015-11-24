-- Copyright 1986-2015 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2015.1 (win64) Build 1215546 Mon Apr 27 19:22:08 MDT 2015
-- Date        : Sat Oct 17 14:25:09 2015
-- Host        : Sparky running 64-bit Service Pack 1  (build 7601)
-- Command     : write_vhdl -force -mode synth_stub
--               C:/Users/Nate/Desktop/work/GitProject/Demos/DemoTest/Nexys4/Projects/Nexys4_User_Demo/src/ip/PxlClkGen/PxlClkGen_stub.vhdl
-- Design      : PxlClkGen
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7a100tcsg324-1
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity PxlClkGen is
  Port ( 
    CLK_IN1 : in STD_LOGIC;
    CLK_OUT1 : out STD_LOGIC;
    LOCKED : out STD_LOGIC
  );

end PxlClkGen;

architecture stub of PxlClkGen is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "CLK_IN1,CLK_OUT1,LOCKED";
begin
end;
