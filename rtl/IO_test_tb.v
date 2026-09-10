`timescale 1us/1ns

module IO_test_tb;

	reg iCLK_us, iCLK, i_SDA, rst, start_button, stop_button;
	wire SCL, SDA_EN, isILDE, o_SDA;
	
	

	IO_test u1(
				.i_SDA(i_SDA), 
				.o_SDA(o_SDA), 
				.rst(rst), 
				.iCLK(iCLK), 
				.iCLK_us(iCLK_us), 
				.SCL(SCL), 
				.SDA_EN(SDA_EN), 
				.isILDE(isILDE), 
				.start_button(start_button), 
				.stop_button(stop_button)
				);

	
	initial begin
		iCLK_us = 0;
		forever #0.5 iCLK_us = ~iCLK_us;
	end
	
	initial begin
		rst = 0; //SCL = 1
		start_button = 0;
		stop_button  = 0;
		i_SDA = 1;
		
		#1 // 1us
		rst = 1;
		#1 // 1us
		rst = 0;
		
		#1
		start_button = 1;
		#1
		start_button = 0;
		#1
		i_SDA = 0;
		
		#7
		
		i_SDA = 0; 
		#100000
		
		$finish;
		
	end
		
endmodule