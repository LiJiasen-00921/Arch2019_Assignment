/* ACM Class System (I) 2018 Fall Assignment 1 
 *
 * Part I: Adder in Verilog
 *
 * This file is used to test your adder. 
 * Please DO NOT modify this file.
 * 
 * GUIDE:
 *   1. Create a RTL project in Vivado
 *   2. Put `adder.v' OR `adder2.v' into `Sources', DO NOT add both of them at the same time.
 *   3. Put this file into `Simulation Sources'
 *   4. Run Behavioral Simulation
 *   5. Make sure to run at least 100 steps during the simulation (usually 100ns)
 *   6. You can see the results in `Tcl console'
 *
 */

//`include "../src/adder.v"

module test_adder;
	wire [15:0] answer;
	wire 		carry;
	reg  [15:0] a, b;
	reg	 [16:0] res;

	adder adder (a, b, answer, carry);
	
	integer i;
	initial begin
		for(i=1; i<=100; i=i+1) begin
			a[15:0] = $random;
			b[15:0] = $random;
			res		= a + b;
			
			#1;
			$display("TESTCASE %d: %d + %d = %d carry: %d", i, a, b, answer, carry);

			if (answer !== res[15:0] || carry != res[16]) begin
				$display("Wrong Answer!");
			end
		end
		$display("Congratulations! You have passed all of the tests.");
		$finish;
	end
endmodule
