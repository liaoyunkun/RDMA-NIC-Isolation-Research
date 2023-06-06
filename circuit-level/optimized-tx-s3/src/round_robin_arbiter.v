//Using Two Simple Priority Arbiters with a Mask - scalable
//author: dongjun_luo@hotmail.com
// https://github.com/freecores/round_robin_arbiter/blob/master/round_robin_arbiter3.v\
`default_nettype none
`timescale 1ns/1ps
module round_robin_arbiter #(
	parameter N = 4
)(
	input  wire         rst_an,
	input  wire         clk,
	input  wire         rr_ena,
	input  wire [N-1:0] req,
	output reg  [N-1:0] grant
);

reg	[N-1:0]	rotate_ptr;
wire	[N-1:0]	mask_req;
wire	[N-1:0]	mask_grant;
wire	[N-1:0]	grant_comb;
wire		no_mask_req;
wire	[N-1:0] nomask_grant;
wire		update_ptr;
genvar i;

// rotate pointer update logic
assign update_ptr = |grant[N-1:0];
always @ (posedge clk or negedge rst_an)
	begin
		if (!rst_an)
			begin
				rotate_ptr[N-1:0] <= {N{1'b1}};
			end
		else if (update_ptr & rr_ena)
			begin
				// note: N must be at least 2
				rotate_ptr[0] <= grant[N-1];
				rotate_ptr[1] <= grant[N-1] | grant[0];
			end
	end

generate
for (i=2;i<N;i=i+1)
always @ (posedge clk or negedge rst_an)
	begin
		if (!rst_an)
			begin
				rotate_ptr[i] <= 1'b1;
			end
		else if (update_ptr & rr_ena)
			begin
				rotate_ptr[i] <= grant[N-1] | (|grant[i-1:0]);
			end
	end
endgenerate

// mask grant generation logic
assign mask_req[N-1:0] = req[N-1:0] & rotate_ptr[N-1:0];

assign mask_grant[0] = mask_req[0];
generate
for (i=1;i<N;i=i+1)
	assign mask_grant[i] = (~|mask_req[i-1:0]) & mask_req[i];
endgenerate

// non-mask grant generation logic
assign nomask_grant[0] = req[0];
generate
for (i=1;i<N;i=i+1)
	assign nomask_grant[i] = (~|req[i-1:0]) & req[i];
endgenerate

// grant generation logic
assign no_mask_req = ~|mask_req[N-1:0];
assign grant_comb[N-1:0] = mask_grant[N-1:0] | (nomask_grant[N-1:0] & {N{no_mask_req}});

always @ (posedge clk or negedge rst_an)
	begin
		if (!rst_an)	
			begin
				grant[N-1:0] <= {N{1'b0}};
			end
		else if(rr_ena)
			begin	
				grant[N-1:0] <= grant_comb[N-1:0] & ~grant[N-1:0];
			end
	end
endmodule