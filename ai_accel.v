`timescale 1ns/1ps
 
module multiplier
(
	a, b, c
);

	input [31:0] a;
	input [31:0] b;
	output [31:0] c;
	
	wire[15:0] x,y,z;
	
	assign x = a[31:24] * b[31:24];
	assign y = a[23:16] * b[23:16];
	assign z = a[15:8]  *  b[15:8];
	
	assign c = {x > 8'hff ? 8'hff : x[7:0],
					y > 8'hff ? 8'hff : y[7:0],
					z > 8'hff ? 8'hff : z[7:0],
					8'b0};

endmodule

module adder
(
	a, b, c, d
);

	input [31:0] a;
	input [31:0] b;
	input [31:0] c;
	output [31:0] d;
	
	wire [15:0] e;
	
	assign e = a[31:24] + b[31:24] + c[31:24]
				+ a[23:16] + b[23:16] + c[23:16]
				+ a[15:8]  + b[15:8]  + c[15:8];
	
	assign d = e > 8'hff ? 8'hff : e[7:0]; 

endmodule

module mean
(
	a, b
);

	input [31:0] a;
	output [31:0] b;
	
	wire [31:0] c;
	
	assign c = (a[31:24] + a[23:16] + a[15:8] + a[7:0]);
	
	assign b = (c >> 2) + (c[1] ? 10'b1 : 10'b0);

endmodule

module zero_mean
(
	a, b, e
);

	input [31:0] a;
	input [31:0] e; // mean
	output [31:0] b;
	
	wire [9:0] c, d;
	wire [15:0] x, y, z, t;
	
	assign x = a[31:24] - e;
	assign y = a[23:16] - e;
	assign z = a[15:8]  - e;
	assign t = a[7:0]   - e;
	
	assign b = {x[15] ? 8'h0 : x[7:0],
					y[15] ? 8'h0 : y[7:0],
					z[15] ? 8'h0 : z[7:0],
					t[15] ? 8'h0 : t[7:0]};

endmodule

module variance
(
	a, b, c
);

	input  [31:0] a; // matrix
	input  [31:0] b; // mean 
	output [31:0] c;
	
	wire [31:0] d,e,f,g, d1,e1,f1,g1;
	wire [63:0] i, j;
	
	
	assign d = {24'b0, a[31:24]} - b;
	assign e = {24'b0, a[23:16]} - b;
	assign f = {24'b0, a[15:8] } - b;
	assign g = {24'b0, a[7:0]  } - b;
	
	assign d1 = d[31] ? ~d + 32'b1 : d;
	assign e1 = e[31] ? ~e + 32'b1 : e;
	assign f1 = f[31] ? ~f + 32'b1 : f;
	assign g1 = g[31] ? ~g + 32'b1 : g;
	
	
	assign i = d1*d1 + e1*e1 + f1*f1 + g1*g1;
	
	assign j = (i >> 2) + (i[1] ? 32'b1 : 32'b0); // handles round properly
	
	assign c = j[31:0];	
	
endmodule



// Module Declaration
module ai_accel
(
        rst_n		,  // Reset Neg
        clk,         // Clk
        addr		,  // Address
		  wr_en,		   //Write enable
		  accel_select,
		  data_in,
		  ctr,
        data_out	   // Output Data
    );
	 
	 input rst_n;
	 input clk;
	 input [31:0] addr;
	 input wr_en;
	 input accel_select;
	 input [31:0] data_in;
	 output [31:0] data_out;
	 output [15:0] ctr;
	 
	 reg [31:0] data_out;
 
	 reg go_bit;
	 wire go_bit_in;
	 reg done_bit;
	 wire done_bit_in;

	 reg [15:0] counter;
	 
	 //reg [31:0] data_A;
	 //reg [31:0] data_B;
	 wire [31:0] data_G;
	 reg [31:0] result;

	 
	 //reg [7:0] in1, in2;
	 //wire[7:0] out;

	 // Image matrix row registers declaration
	 reg [31:0] img_row_1, 
					img_row_2, 
					img_row_3, 
					img_row_4;
					
	 // Mask matrix row registers declaration			
	 reg [31:0] msk_row_1, 
					msk_row_2, 
					msk_row_3;
					
	 // Multipliers output result wires declaration
	 wire [31:0] m_out_1_1, m_out_1_2, m_out_1_3, m_out_1_4,
					 m_out_2_1, m_out_2_2, m_out_2_3, m_out_2_4,
					 m_out_3_1, m_out_3_2, m_out_3_3, m_out_3_4;
					 
	// Adders output result wires declaration
	 wire [31:0] a_out_1,
					 a_out_2,
					 a_out_3,
					 a_out_4;
					 
	// Mean output wire declaration
	 wire [31:0] mean_out;
					 
	// Normalizer output wire declaration
	 wire[31:0] z_mean_out;
	 
	// Variance output wire declaration
	 wire[31:0] var_out;
	 
	 //assign ctr = counter;
	 assign ctr = counter;
	 
	 //always @(addr[4:2], data_A, data_B, data_C, counter, done_bit, go_bit, counter) begin
	 always @(addr[6:2], img_row_1, img_row_2, img_row_3, img_row_4,
				 msk_row_1, msk_row_2, msk_row_3,
				 data_G, counter, done_bit, go_bit, counter) begin
		case(addr[6:2])
		5'b01000: data_out = {done_bit, 30'b0, go_bit};
		5'b01001: data_out = {16'b0, counter}; 
		//3'b010: data_out = data_A;
		//3'b011: data_out = data_B;
		5'b01010: data_out = img_row_1;
		5'b01011: data_out = img_row_2;
		5'b01100: data_out = img_row_3;
		5'b01101: data_out = img_row_4;
		5'b01110: data_out = msk_row_1;
		5'b01111: data_out = msk_row_2;
		5'b10000: data_out = msk_row_3;
		5'b10001: data_out = data_G;
		default: data_out = 32'b1;
		endcase
	 end
	 
	 assign go_bit_in = (wr_en & accel_select & (addr[6:2] == 5'b01000));
	
	 always @(posedge clk or negedge rst_n)
		if(~rst_n) go_bit <= 1'b0;
		else go_bit <=  go_bit_in ? 1'b1 : 1'b0;
		
	 always @(posedge clk or negedge rst_n)
		if(~rst_n) begin
			counter <= 16'b0;
			
			img_row_1 <= 32'b0;
			img_row_2 <= 32'b0;
			img_row_3 <= 32'b0;
			img_row_4 <= 32'b0;
			
			msk_row_1 <= 32'b0;
			msk_row_2 <= 32'b0;
			msk_row_3 <= 32'b0;
			
			//data_A <= 32'b0;
			//data_B <= 32'b0;
		end
		else begin
			if (wr_en & accel_select) begin	
				img_row_1 <= (addr[6:2] == 5'b01010) ? data_in : img_row_1;
				img_row_2 <= (addr[6:2] == 5'b01011) ? data_in : img_row_2;
				img_row_3 <= (addr[6:2] == 5'b01100) ? data_in : img_row_3;
				img_row_4 <= (addr[6:2] == 5'b01101) ? data_in : img_row_4;
				
				msk_row_1 <= (addr[6:2] == 5'b01110) ? data_in : msk_row_1;
				msk_row_2 <= (addr[6:2] == 5'b01111) ? data_in : msk_row_2;
				msk_row_3 <= (addr[6:2] == 5'b10000) ? data_in : msk_row_3;
				
				//data_A <= (addr[4:2] == 3'b010) ? data_in : data_A;
				//data_B <= (addr[4:2] == 3'b011) ? data_in : data_B;
			end
			else begin
				img_row_1 <= img_row_1;
				img_row_2 <= img_row_2;
				img_row_3 <= img_row_3;
				img_row_4 <= img_row_4;
				
				msk_row_1 <= msk_row_1; 
				msk_row_2 <= msk_row_2;
				msk_row_3 <= msk_row_3;
								
				//data_A <= data_A;
				//data_B <= data_B;
			end
			counter <= go_bit_in? 16'h00 : done_bit_in ? counter : counter +16'h01;
		end
		
	 /*		
	 always @(data_A, counter) begin
		case(counter)
		16'b0: 	in1 = data_A[7:0];
		16'b1:	in1 = data_A[15:8];
		16'b10:	in1 = data_A[23:16];
		default: in1 = data_A[7:0];
		endcase
	 end
	 */
	/*
	  always @(data_B, counter) begin
		case(counter)
		32'b0: 	in2 = data_B[7:0];
		32'b1:	in2 = data_B[15:8];
		32'b10:	in2 = data_B[23:16];
		default: in2 = data_B[7:0];
		endcase
	 end
	 */
	 
	 //multiplier mul(.a(in1), .b(in2), .c(out));
	 
	 // Multipliers declaration
	 multiplier mul_1_1(.a(msk_row_1), .b({img_row_1[31:8], 8'b0}), .c(m_out_1_1)); // left  first  row X mask first  row
	 multiplier mul_1_2(.a(msk_row_1), .b({img_row_1[23:0], 8'b0}), .c(m_out_1_2)); // right first  row X mask first  row
	 multiplier mul_1_3(.a(msk_row_1), .b({img_row_2[31:8], 8'b0}), .c(m_out_1_3)); // left  second row X mask first  row
	 multiplier mul_1_4(.a(msk_row_1), .b({img_row_2[23:0], 8'b0}), .c(m_out_1_4)); // right second row X mask first  row
	 
	 multiplier mul_2_1(.a(msk_row_2), .b({img_row_2[31:8], 8'b0}), .c(m_out_2_1)); // left  second row X mask second row
	 multiplier mul_2_2(.a(msk_row_2), .b({img_row_2[23:0], 8'b0}), .c(m_out_2_2)); // right second row X mask second row
	 multiplier mul_2_3(.a(msk_row_2), .b({img_row_3[31:8], 8'b0}), .c(m_out_2_3)); // left  third  row X mask second row
	 multiplier mul_2_4(.a(msk_row_2), .b({img_row_3[23:0], 8'b0}), .c(m_out_2_4)); // right third  row X mask second row
	 
	 multiplier mul_3_1(.a(msk_row_3), .b({img_row_3[31:8], 8'b0}), .c(m_out_3_1)); // left  third  row X mask third  row
	 multiplier mul_3_2(.a(msk_row_3), .b({img_row_3[23:0], 8'b0}), .c(m_out_3_2)); // right third  row X mask third  row
	 multiplier mul_3_3(.a(msk_row_3), .b({img_row_4[31:8], 8'b0}), .c(m_out_3_3)); // left  fourth row X mask third  row
	 multiplier mul_3_4(.a(msk_row_3), .b({img_row_4[23:0], 8'b0}), .c(m_out_3_4)); // right fourth row X mask third  row
	 
	 
	 // Adders declaration
	 adder add_1(.a(m_out_1_1), .b(m_out_2_1), .c(m_out_3_1), .d(a_out_1)); // left  top    corner square
	 adder add_2(.a(m_out_1_2), .b(m_out_2_2), .c(m_out_3_2), .d(a_out_2)); // right top    corner square
	 adder add_3(.a(m_out_1_3), .b(m_out_2_3), .c(m_out_3_3), .d(a_out_3)); // left  bottom corner square
	 adder add_4(.a(m_out_1_4), .b(m_out_2_4), .c(m_out_3_4), .d(a_out_4)); // right bottom corner square
	 
	 // Mean declaration
	 mean mn(.a({a_out_1[7:0], a_out_2[7:0], a_out_3[7:0], a_out_4[7:0]}), .b(mean_out));
	 
	 // Zero mean declaration
	 zero_mean z_mean(.a({a_out_1[7:0], a_out_2[7:0], a_out_3[7:0], a_out_4[7:0]}),
							.b(z_mean_out), .e(mean_out)); // shifts mean of matrix to zero
							
	 // Variance declaration
	 variance var(.a({a_out_1[7:0], a_out_2[7:0], a_out_3[7:0], a_out_4[7:0]}),
					  .b(mean_out), .c(var_out));
	 
	//wire [31:0] result_in;

	assign data_G = z_mean_out; // send normalized result to output of the accelerator
							 
	 always @(posedge clk or negedge rst_n)
		if(~rst_n) result <=32'h0;
		//else result <= result_in;
	 	 
	 //assign data_G = result;
	 
	 assign done_bit_in = !(z_mean_out != 32'd0) ;
	 
	 always @(posedge clk or negedge rst_n)
		if(~rst_n) done_bit <= 1'b0;
		else done_bit <= go_bit_in ? 1'b0 : done_bit_in;
	 
endmodule