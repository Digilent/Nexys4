----------------------------------------------------------------------------------
----------------------------------------------------------------------------
-- Author:  Albert Fazakas adapted from Sam Bobrowicz, Alec Wyen and Mihaita Nagy
--          Copyright 2014 Digilent, Inc.
----------------------------------------------------------------------------

-- Design Name:    Nexys4 User Demo
-- Module Name:    Nexys4UserDemo - Behavioral 
-- Project Name: 
-- Target Devices: Nexys4 Development Board, containing a XC7a100t-1 csg324 device
-- Tool versions: 
-- Description: 
-- This module represents the top - level design of the Nexys4 User Demo.
-- The project connects to the VGA display in a 1280*1024 resolution and displays various
-- items on the screen:
--    - a Digilent / Analog Devices logo
--
--    - a mouse cursor, if an Usb mouse is connected to the board when the project is started
--
--    - the audio signal from the onboard ADMP421 Omnidirectional Microphone

--    - a small square representing the X and Y acceleration data from the ADXL362 onboard Accelerometer.
--      The square moves according the Nexys4 board position. Note that the X and Y axes 
--      on the board are exchanged due to the accelerometer layout on the Nexys4 board.
--      The accelerometer display also displays the acceleration magnitude, calculated as
--      SQRT( X^2 + Y^2 +Z^2), where X, Y and Z represent the acceleration value on the respective axes
--
--    - The FPGA temperature, the onboard ADT7420 temperature sensor temperature value and the accelerometer
--      temperature value
--
--    - The value of the R, G and B components sent to the RGB Leds LD16 and LD17
--
-- Other features:
--    - The 16 Switches (SW0..SW15) are connected to LD0..LD15 except when audio recording is done
--
--    - Pressing BTNL, BTNC and BTNR will toggle between Red, Green and Blue colors on LD16 and LD17
--      Color sweeping returns when BTND is pressed. BTND also togles between LD16, LD17, none or both
--
--    - Pressing BTNU will start audio recording for about 5S, then the audio data will be played back
--      on the Audio output. While recording, LD15..LD0 will show a progressbar moving to left, while
--      playing back, LD15..LD0 will show a progressbar moving to right
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Nexys4UserDemo is
   port(
      clk_i          : in  std_logic;
      rstn_i         : in  std_logic;
      -- push-buttons
      btnl_i         : in  std_logic;
      btnc_i         : in  std_logic;
      btnr_i         : in  std_logic;
      btnd_i         : in  std_logic;
      btnu_i         : in  std_logic;
      -- switches
      sw_i           : in  std_logic_vector(15 downto 0);
      -- 7-segment display
      disp_seg_o     : out std_logic_vector(7 downto 0);
      disp_an_o      : out std_logic_vector(7 downto 0);
      -- leds
      led_o          : out std_logic_vector(15 downto 0);
      -- RGB leds
      rgb1_red_o     : out std_logic;
      rgb1_green_o   : out std_logic;
      rgb1_blue_o    : out std_logic;
      rgb2_red_o     : out std_logic;
      rgb2_green_o   : out std_logic;
      rgb2_blue_o    : out std_logic;
      -- VGA display
      vga_hs_o       : out std_logic;
      vga_vs_o       : out std_logic;
      vga_red_o      : out std_logic_vector(3 downto 0);
      vga_blue_o     : out std_logic_vector(3 downto 0);
      vga_green_o    : out std_logic_vector(3 downto 0);
      -- PDM microphone
      pdm_clk_o      : out std_logic;
      pdm_data_i     : in  std_logic;
      pdm_lrsel_o    : out std_logic;
      -- PWM audio
      pwm_audio_o    : out std_logic;
      pwm_sdaudio_o  : out std_logic;
		-- Temperature sensor
		tmp_scl        : inout std_logic;
		tmp_sda        : inout std_logic;
--		tmp_int        : in std_logic; -- Not used in this project
--		tmp_ct         : in std_logic; -- Not used in this project
      -- SPI Interface signals for the ADXL362 accelerometer
      sclk           : out STD_LOGIC;
      mosi           : out STD_LOGIC;
      miso           : in STD_LOGIC;
      ss             : out STD_LOGIC;
      -- PS2 interface
      ps2_clk        : inout std_logic;
      ps2_data       : inout std_logic;
      
      -- Cellular RAM
      Mem_A          : out std_logic_vector(22 downto 0);
      Mem_DQ         : inout std_logic_vector(15 downto 0);
      Mem_CEN        : out std_logic;
      Mem_OEN        : out std_logic;
      Mem_WEN        : out std_logic;
      Mem_UB         : out std_logic;
      Mem_LB         : out std_logic;
      Mem_ADV        : out std_logic;
      Mem_CLK        : out std_logic;
      Mem_CRE        : out std_logic     
   );
end Nexys4UserDemo;

architecture Behavioral of Nexys4UserDemo is

----------------------------------------------------------------------------------
-- Component Declarations
----------------------------------------------------------------------------------  
component RgbLed is
port(
   clk_i          : in  std_logic;
   rstn_i         : in  std_logic;
   btnl_i         : in  std_logic;
   btnc_i         : in  std_logic;
   btnr_i         : in  std_logic;
   btnd_i         : in  std_logic;
   pwm1_red_o     : out std_logic;
   pwm1_green_o   : out std_logic;
   pwm1_blue_o    : out std_logic;
   pwm2_red_o     : out std_logic;
   pwm2_green_o   : out std_logic;
   pwm2_blue_o    : out std_logic;
   red_out        : out std_logic_vector (7 downto 0);
   green_out      : out std_logic_vector (7 downto 0);
   blue_out       : out std_logic_vector (7 downto 0)
   );
end component;

component sSegDemo is
port(
   clk_i          : in std_logic;
   rstn_i         : in std_logic;
   seg_o          : out std_logic_vector(7 downto 0);
   an_o           : out std_logic_vector(7 downto 0));
end component;

component AudioDemo is
port(
   clk_i          : in    std_logic;
   rstn_i         : in    std_logic;
   btn_u          : in    std_logic;
   leds_o         : out   std_logic_vector(15 downto 0);
   pdm_m_clk_o    : out   std_logic;
   pdm_m_data_i   : in    std_logic;
   pdm_lrsel_o    : out   std_logic;
   pwm_audio_o    : out   std_logic;
   pwm_sdaudio_o  : out   std_logic;
   Mem_A          : out   std_logic_vector(22 downto 0);
   Mem_DQ         : inout std_logic_vector(15 downto 0);
   Mem_CEN        : out   std_logic;
   Mem_OEN        : out   std_logic;
   Mem_WEN        : out   std_logic;
   Mem_UB         : out   std_logic;
   Mem_LB         : out   std_logic;
   Mem_ADV        : out   std_logic;
   Mem_CLK        : out   std_logic;
   Mem_CRE        : out   std_logic;
   pdm_clk_rising_o : out std_logic
   );
end component;

component TempSensorCtl is
	Generic (CLOCKFREQ : natural := 100); -- input CLK frequency in MHz
	Port (
		TMP_SCL : inout STD_LOGIC;
		TMP_SDA : inout STD_LOGIC;
      -- The Interrupt and Critical Temperature Signals
      -- from the ADT7420 Temperature Sensor are not used in this design
--		TMP_INT : in STD_LOGIC;
--		TMP_CT : in STD_LOGIC;		
		TEMP_O : out STD_LOGIC_VECTOR(12 downto 0); --12-bit two's complement temperature with sign bit
		RDY_O : out STD_LOGIC;	--'1' when there is a valid temperature reading on TEMP_O
		ERR_O : out STD_LOGIC; --'1' if communication error
		CLK_I : in STD_LOGIC;
		SRST_I : in STD_LOGIC
	);
end component;

component AccelerometerCtl is
generic 
(
   SYSCLK_FREQUENCY_HZ : integer := 100000000;
   SCLK_FREQUENCY_HZ   : integer := 1000000;
   NUM_READS_AVG       : integer := 16;
   UPDATE_FREQUENCY_HZ : integer := 1000
);
port
(
 SYSCLK     : in STD_LOGIC; -- System Clock
 RESET      : in STD_LOGIC; -- Reset button on the Nexys4 board is active low

 -- SPI interface Signals
 SCLK       : out STD_LOGIC;
 MOSI       : out STD_LOGIC;
 MISO       : in STD_LOGIC;
 SS         : out STD_LOGIC;

-- Accelerometer data signals
 ACCEL_X_OUT    : out STD_LOGIC_VECTOR (8 downto 0);
 ACCEL_Y_OUT    : out STD_LOGIC_VECTOR (8 downto 0);
 ACCEL_MAG_OUT  : out STD_LOGIC_VECTOR (11 downto 0);
 ACCEL_TMP_OUT  : out STD_LOGIC_VECTOR (11 downto 0)
);
end component;


COMPONENT MouseCtl is
GENERIC
(
   SYSCLK_FREQUENCY_HZ : integer := 100000000;
   CHECK_PERIOD_MS     : integer := 500;
   TIMEOUT_PERIOD_MS   : integer := 100
);
PORT(
   clk            : in std_logic;
   rst            : in std_logic;
   xpos           : out std_logic_vector(11 downto 0);
   ypos           : out std_logic_vector(11 downto 0);
   zpos           : out std_logic_vector(3 downto 0);
   left           : out std_logic;
   middle         : out std_logic;
   right          : out std_logic;
   new_event      : out std_logic;
   value          : in std_logic_vector(11 downto 0);
   setx           : in std_logic;
   sety           : in std_logic;
   setmax_x       : in std_logic;
   setmax_y       : in std_logic;
   ps2_clk        : inout std_logic;
   ps2_data       : inout std_logic
);
END COMPONENT;

COMPONENT Vga is
PORT( 
   clk_i          : in  std_logic;
   vga_hs_o       : out std_logic;
   vga_vs_o       : out std_logic;
   vga_red_o      : out std_logic_vector(3 downto 0);
   vga_blue_o     : out std_logic_vector(3 downto 0);
   vga_green_o    : out std_logic_vector(3 downto 0);
   RGB_LED_RED    : in STD_LOGIC_VECTOR (7 downto 0);
   RGB_LED_GREEN  : in STD_LOGIC_VECTOR (7 downto 0);
   RGB_LED_BLUE   : in STD_LOGIC_VECTOR (7 downto 0);
   ACCEL_RADIUS   : in  STD_LOGIC_VECTOR (11 downto 0);
   LEVEL_THRESH   : in  STD_LOGIC_VECTOR (11 downto 0);
	ACL_X_IN       : in  STD_LOGIC_VECTOR (8 downto 0);
   ACL_Y_IN       : in  STD_LOGIC_VECTOR (8 downto 0);
   ACL_MAG_IN     : in  STD_LOGIC_VECTOR (11 downto 0);
   MIC_M_DATA_I   : IN STD_LOGIC;
   MIC_M_CLK_RISING  : IN STD_LOGIC;
   MOUSE_X_POS    :  in std_logic_vector (11 downto 0);
   MOUSE_Y_POS    :  in std_logic_vector (11 downto 0);
   XADC_TEMP_VALUE_I : in std_logic_vector (11 downto 0);
   ADT7420_TEMP_VALUE_I : in std_logic_vector (12 downto 0);
   ADXL362_TEMP_VALUE_I : in std_logic_vector (11 downto 0)
   );
END COMPONENT;

----------------------------------------------------------------------------------
-- Signal Declarations
----------------------------------------------------------------------------------  
-- Inverted reset signal
signal rst        : std_logic;

-- Progressbar signal when recording
signal led_audio  : std_logic_vector(15 downto 0);

-- RGB LED signals
signal rgb_led_red: std_logic_vector (7 downto 0);
signal rgb_led_green: std_logic_vector (7 downto 0);
signal rgb_led_blue: std_logic_vector (7 downto 0);

-- ADXL362 Accelerometer data signals
signal ACCEL_X    : STD_LOGIC_VECTOR (8 downto 0);
signal ACCEL_Y    : STD_LOGIC_VECTOR (8 downto 0);
signal ACCEL_MAG  : STD_LOGIC_VECTOR (11 downto 0);
signal ACCEL_TMP  : STD_LOGIC_VECTOR (11 downto 0);

-- Mouse data signals
signal MOUSE_X_POS: std_logic_vector (11 downto 0);
signal MOUSE_Y_POS: std_logic_vector (11 downto 0);

-- ADT7420 Temperature Sensor raw Data Signal
signal tempValue : std_logic_vector(12 downto 0);
signal tempRdy, tempErr : std_logic;

-- XADC Temperature Sensor raw Data signal
signal fpgaTempValue : std_logic_vector(11 downto 0);

-- pdm_clk and pdm_clk_rising are needed by the VGA controller
-- to display incoming microphone data
signal pdm_clk : std_logic;
signal pdm_clk_rising : std_logic;


begin
   
   -- Assign LEDs
   led_o <= sw_i when (led_audio = X"0000") else led_audio;

   -- The Reset Button on the Nexys4 board is active-low,
   -- however many components need an active-high reset
   rst <= not rstn_i;

   -- Assign pdm_clk output
   pdm_clk_o <= pdm_clk;

----------------------------------------------------------------------------------
-- Rgb Led Controller
----------------------------------------------------------------------------------    
   Inst_RGB: RgbLed
   port map(
      clk_i          => clk_i,
      rstn_i         => rstn_i,
      btnl_i         => btnl_i,
      btnc_i         => btnc_i,
      btnr_i         => btnr_i,
      btnd_i         => btnd_i,
      pwm1_red_o     => rgb1_red_o,
      pwm1_green_o   => rgb1_green_o,
      pwm1_blue_o    => rgb1_blue_o,
      pwm2_red_o     => rgb2_red_o,
      pwm2_green_o   => rgb2_green_o,
      pwm2_blue_o    => rgb2_blue_o,
      RED_OUT        => rgb_led_red,
      GREEN_OUT      => rgb_led_green,
      BLUE_OUT       => rgb_led_blue
      );

----------------------------------------------------------------------------------
-- Seven-Segment Display
----------------------------------------------------------------------------------     
   Inst_SevenSeg: sSegDemo
   port map(
      clk_i          => clk_i,
      rstn_i         => rstn_i,
      seg_o          => disp_seg_o,
      an_o           => disp_an_o
	  );

----------------------------------------------------------------------------------
-- Audio Demo
----------------------------------------------------------------------------------   
   Inst_AudioDemo: AudioDemo
   port map(
      clk_i          => clk_i,
      rstn_i         => rstn_i,
      btn_u          => btnu_i,
      leds_o         => led_audio,
      pdm_m_clk_o    => pdm_clk,
      pdm_m_data_i   => pdm_data_i,
      pdm_lrsel_o    => pdm_lrsel_o,
      pwm_audio_o    => pwm_audio_o,
      pwm_sdaudio_o  => pwm_sdaudio_o,
      Mem_A          => Mem_A,
      Mem_DQ         => Mem_DQ,
      Mem_CEN        => Mem_CEN,
      Mem_OEN        => Mem_OEN,
      Mem_WEN        => Mem_WEN,
      Mem_UB         => Mem_UB,
      Mem_LB         => Mem_LB,
      Mem_ADV        => Mem_ADV,
      Mem_CLK        => Mem_CLK,
      Mem_CRE        => Mem_CRE,
      pdm_clk_rising_o => pdm_clk_rising
      );

   
----------------------------------------------------------------------------------
-- FPGA Temperature Monitor
----------------------------------------------------------------------------------
	Inst_FPGAMonitor: entity work.FPGAMonitor PORT MAP(
		CLK_I          => clk_i,
		RST_I          => rst,
		TEMP_O         => fpgaTempValue
	);

----------------------------------------------------------------------------------
-- Temperature Sensor Controller
----------------------------------------------------------------------------------
	Inst_TempSensorCtl: TempSensorCtl
	GENERIC MAP (CLOCKFREQ => 100)
	PORT MAP(
		TMP_SCL        => TMP_SCL,
		TMP_SDA        => TMP_SDA,
--		TMP_INT        => TMP_INT,
--		TMP_CT         => TMP_CT,		
		TEMP_O         => tempValue,
		RDY_O          => tempRdy,
		ERR_O          => tempErr,
		
		CLK_I          => clk_i,
		SRST_I         => rst
	);

----------------------------------------------------------------------------------
-- Accelerometer Controller
----------------------------------------------------------------------------------
   Inst_AccelerometerCtl: AccelerometerCtl
   generic map
   (
        SYSCLK_FREQUENCY_HZ   => 100000000,
        SCLK_FREQUENCY_HZ     => 100000,
        NUM_READS_AVG         => 16,
        UPDATE_FREQUENCY_HZ   => 1000
   )
   port map
   (
       SYSCLK     => clk_i,
       RESET      => rst, 
       -- Spi interface Signals
       SCLK       => sclk,
       MOSI       => mosi,
       MISO       => miso,
       SS         => ss,
	   
      -- Accelerometer data signals
       ACCEL_X_OUT   => ACCEL_X,
       ACCEL_Y_OUT   => ACCEL_Y,
       ACCEL_MAG_OUT => ACCEL_MAG,
       ACCEL_TMP_OUT => ACCEL_TMP
   );

----------------------------------------------------------------------------------
-- Mouse Controller
----------------------------------------------------------------------------------
   Inst_MouseCtl: MouseCtl
   GENERIC MAP
(
   SYSCLK_FREQUENCY_HZ => 100000000,
   CHECK_PERIOD_MS     => 500,
   TIMEOUT_PERIOD_MS   => 100
)
   PORT MAP
   (
      clk            => clk_i,
      rst            => rst,
      xpos           => MOUSE_X_POS,
      ypos           => MOUSE_Y_POS,
      zpos           => open,
      left           => open,
      middle         => open,
      right          => open,
      new_event      => open,
      value          => x"000",
      setx           => '0',
      sety           => '0',
      setmax_x       => '0',
      setmax_y       => '0',
      ps2_clk        => ps2_clk,
      ps2_data       => ps2_data
   );

----------------------------------------------------------------------------------
-- VGA Controller
----------------------------------------------------------------------------------
   Inst_VGA: Vga
   port map(
      clk_i          => clk_i,
      vga_hs_o       => vga_hs_o,
      vga_vs_o       => vga_vs_o,
      vga_red_o      => vga_red_o,
      vga_blue_o     => vga_blue_o,
      vga_green_o    => vga_green_o,
      RGB_LED_RED    => rgb_led_red,
      RGB_LED_GREEN  => rgb_led_green,
      RGB_LED_BLUE   => rgb_led_blue,
      ACCEL_RADIUS   => X"007",
      LEVEL_THRESH   => X"020",
      ACL_X_IN       => ACCEL_X,
      ACL_Y_IN       => ACCEL_Y,
      ACL_MAG_IN     => ACCEL_MAG,
      MIC_M_DATA_I   => pdm_data_i,
      MIC_M_CLK_RISING => pdm_clk_rising,
      MOUSE_X_POS    => MOUSE_X_POS,
      MOUSE_Y_POS    => MOUSE_Y_POS,
      XADC_TEMP_VALUE_I => fpgaTempValue,
      ADT7420_TEMP_VALUE_I => tempValue,
      ADXL362_TEMP_VALUE_I => ACCEL_TMP
      );
	  
end Behavioral;

