`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Digilent Inc.
// Engineer: Varun Kondagunturi
// 
// Create Date:    17:08:26 06/12/2014 
// Design Name: 
// Module Name:    Nexys4_Abacus_Top
// Project Name: 
// Target Devices: 
// Tool versions: 
//
//
// Description: 
//This is the Top-Level Source file for the Abacus Project. 
//Slide switches provide two 8-bit binary inputs A and B. 
//Slide Switches [15 down to 8] is input A.
//Slide Switches [7 down to 0] is input B.
//Inputs from the Push Buttons ( btnU, btnD, btnR, btnL) will allow the user to select different arithmetic operations that will be computed on the inputs A and B.
//btnU: Subtraction/Difference.
//btnC: Addition.
//When A>B, difference is positive. 
//When A<B, difference is negative. If the button is not held down but just pressed once, the result will scroll. To find out if the result is negative, press and hold onto the push button btnU. This will show the negative sign. 
//btnD: Multiplication/Product. Result will Scroll
//btnR: Quotient(Division Operation). Press and Hold the button to display result
//btnL: Remainder ( Division Operation). Press and Hold the button to display result
//No btns pressed: inputs are displeyed on individual 7seg
//Output is displayed on the two 7 segment LED displays. 
//
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Revision 0.02 - Edited to work with Nexys4 (Tommy Kappenman)
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
 module Nexys4_Abacus_Top(

//CLK Input
	 input clk,
	 
//Push Button Inputs	 
	 input btnC,
	 input btnU, 
	 input btnD,
	 input btnR,
	 input btnL,
	 
// Slide Switch Inputs
// Input A = sw[15:8]
//Input B = sw[7:0]	 
	 input [15:0] sw, 
   
// LED Outputs
     output [15:0] led,
     
// Seven Segment Display Outputs
     output [6:0] seg,
     output [7:0] an, 
     output dp
    
 );
	
//Seven Segment Display Signal
reg [31:0] x;//input to seg7 to define segment pattern

//adder signals
wire [7:0] sum;
wire [7:0] diff;
wire cout;


// 16 bit BCD Converter Signals
reg [15:0] B; // Inputs to B will be Adder/Subtractor and Multiplication Results 
wire[19:0] bcdout;// bcdout is sent to Scroll_Display Module


// 16 bit BCD Converter Signals for Divider Sub-Module
reg [15:0] B1; // input will be 8 bit quotient signal
wire[19:0] bcdout1;// sent to Scroll_Display Module

reg [15:0] B2; // input will be 8 bit remainder signal
wire[19:0] bcdout2;// sent to Scroll_Display Module

 // Divider or Mod signals
 wire [7:0] QU;// Quotient
 wire [7:0] REM; // Remainder

// Product or Multiplication Signals
wire [15:0] Product;
wire [7:0] PP0;// partial product outputs from multi modules.  
wire [7:0] PP1;
wire [7:0] PP2;
wire [7:0] PP3;
wire [21:0] p_temp;

// Difference Signals
wire [7:0] zero_diff;
wire [7:0] twoC_diff;

// Clear Signal for Adder/Sub/Product
wire clr_seg;
assign clr_seg = btnU | btnD | btnC;// | btnR | btnL ;

// Clear Signal for Divider
wire clr_seg_DIV;//
assign clr_seg_DIV = btnR | btnL;

 
assign zero_diff[7:0] = diff[7:0]; //{1'b0, diff[7:0]};
assign twoC_diff[7:0] = ((~(zero_diff[7:0])) +8'b00000001);	



assign p_temp[3:0] = PP0[3:0];
assign Product[3:0] = p_temp[3:0];

assign p_temp[9:4] = PP0[7:4]+PP1[3:0]+PP2[3:0]; //sum2_2[3:0]; 6 bits
assign Product[7:4] = p_temp[7:4];

assign p_temp[15:10] = PP1[7:4] + PP2[7:4] + PP3[3:0]+ {2'b00, p_temp[9:8]} ;  //sumC_C[3:0]; // 6 bits
assign Product[11:8] = p_temp[13:10];

assign p_temp[21:16] = PP3[7:4] + {2'b00,p_temp[15:14]}; //P3[7:4]+ {3'b000, tempC_C[4]};
assign Product[15:12] = p_temp[19:16];


assign led[15:0] = sw[15:0];



always @(*) begin

if ( (btnU == 1) && (sw[15:8] <= sw[7:0]))  
begin
	
B = twoC_diff[7:0];
            x[31:28] <= 0;//'hC;
			 x[27:24] <= 0; //hundreds;
             x[23:20] <= 0;// tens;
             x[19:16] <= 0;//ones;
             x[15:12] = 'hA;
			 x[11:8] = bcdout[11:8]; //hundreds;
			 x[7:4] = bcdout[7:4];// tens;
			 x[3:0] = bcdout[3:0];//ones;

	end

else if ( (btnU == 1) && (sw[15:8] >= sw[7:0] ))
	begin
B = diff[7:0];
                x[31:28] <= 0;//'hC;
			 x[27:24] <= 0; //hundreds;
             x[23:20] <= 0;// tens;
             x[19:16] <= 0;//ones;
             x[15:12] = bcdout[15:12];//'hC;
			 x[11:8] = bcdout[11:8]; //hundreds;
             x[7:4] = bcdout[7:4];// tens;
             x[3:0] = bcdout[3:0];//ones;
	 
	end
	
else if (btnC == 1) begin 
B = sum[7:0];     
    
                 x[31:28] <= 0;//'hC;
                 x[27:24] <= 0; //hundreds;
                 x[23:20] <= 0;// tens;
                 x[19:16] <= 0;//ones;
                 x[15:12] = bcdout[15:12];//'hC;
                 x[11:8] = bcdout[11:8]; //hundreds;
                 x[7:4] = bcdout[7:4];// tens;
                 x[3:0] = bcdout[3:0];//ones;
                 
end


else if (btnD == 1) begin

B = Product[15:0];

            x[31:28] <= 0;//'hC;
			 x[27:24] <= 0; //hundreds;
             x[23:20] <= 0;// tens;
             x[19:16] <= bcdout[19:16];//ones;
             x[15:12] = bcdout[15:12];//'hC;
			 x[11:8] = bcdout[11:8]; //hundreds;
             x[7:4] = bcdout[7:4];// tens;
             x[3:0] = bcdout[3:0];//ones;
         
end

else if (btnR == 1) begin
 
B1 = QU[7:0]; // bcdout1

            x[31:28] <= 0;//'hC;
			 x[27:24] <= 0; //hundreds;
             x[23:20] <= 0;// tens;
             x[19:16] <= 0;//ones;
             x[15:12] = bcdout1[15:12];//'hC;
			 x[11:8] = bcdout1[11:8]; //hundreds;
             x[7:4] = bcdout1[7:4];// tens;
             x[3:0] = bcdout1[3:0];//ones;

end

else if (btnL == 1) begin


B2 <= REM[7:0]; // bcdout2

             x[31:28] <= 0;//'hC;
			 x[27:24] <= 0; //hundreds;
             x[23:20] <= 0;// tens;
             x[19:16] <= 0;//ones;
             x[15:12] = bcdout2[15:12];//'hC;
			 x[11:8] = bcdout2[11:8]; //hundreds;
             x[7:4] = bcdout2[7:4];// tens;
             x[3:0] = bcdout2[3:0];//ones;

end


else//No buttons pressed, show inputs 
	begin
	
B = sw[7:0]; 	
B2 <= sw[15:8];

             x[31:28] = bcdout2[15:12];//'hC;
			 x[27:24] = bcdout2[11:8]; //hundreds;
             x[23:20] = bcdout2[7:4];// tens;
             x[19:16] = bcdout2[3:0];//ones;
             x[15:12] = bcdout[15:12];//'hC;
			 x[11:8] = bcdout[11:8]; //hundreds;
             x[7:4] = bcdout[7:4];// tens;
             x[3:0] = bcdout[3:0];//ones;
                 

	end
end



// Binary to BCD conversion module1 for Adder/Sub/Multi Result
bin_to_decimal u1 (

.B(B), 
.bcdout(bcdout)
);

// Binary to BCD conversion module2 for Quotient Result
BIN_DEC1 u2 (

.B1(B1), // QU in binary
.bcdout1(bcdout1)// QU in BCD
);

// Binary to BCD conversion module3 for Remainder Result
BIN_DEC2 u3 (

.B2(B2), // REM in binary
.bcdout2(bcdout2)// REM in BCD
);


// 7segment display module

seg7decimal u7 (

.x(x),
.clk(clk),
.a_to_g(seg),
.an(an),
.dp(dp)
);


// Arithmetic Operations

// Adder/Subtractor Module
adder u8 (

.clk(clk),
.a(sw[15:8]),
.b(sw[7:0]),
.sum(sum),
.diff(diff),
.cout(cout),
.cin(btnU)
);

// Product/Multiplication

// Partial Product 0 Module
multi_4_4_pp0 u9 (

.clk(clk),
//.clr(btn[1]),
.A0_3(sw[11:8]),
.B0_3(sw[3:0]),
.pp0(PP0)

);

// Partial Product 1 Module
multi_4_4_pp1 u10 (

.clk(clk),
//.clr(btn[1]),
.A4_7(sw[15:12]),
.B0_3(sw[3:0]),
.pp1(PP1)

);

// Partial Product 2 Module
multi_4_4_pp2 u11 (

.clk(clk),
//.clr(btn[1]),
.A0_3(sw[11:8]),
.B4_7(sw[7:4]),
.pp2(PP2)

);

// Partial Product 3 Module
multi_4_4_pp3 u12 (

.clk(clk),
//.clr(btn[1]),
.A4_7(sw[15:12]),
.B4_7(sw[7:4]),
.pp3(PP3)

);


// Divider Module
divider u13(

.clk(clk),
.div(sw[15:8]),
.dvr(sw[7:0]),
.quotient(QU),
.remainder(REM)
);

endmodule