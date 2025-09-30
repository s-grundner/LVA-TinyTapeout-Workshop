module strb (
	input wire clk_i,
	input wire nrst_i,
	input wire nrstSync_i,
	output wire strb_o
);

	localparam BW = 16;

	reg strb = 1'b0;
	wire nrstSyncCnt = nrst_i & nrstSync_i;
	wire [BW-1:0] count;

	assign strb_o = strb;

	always @(posedge clk_i or negedge nrst_i) begin
		if (!nrst_i) begin
			strb <= 1'b0;
		end else begin
			strb <= (count == {BW{BW-1}}) ? 1'b1 : 1'b0;
		end
	end

	counter #(
		.BW(BW)
	) strbCounter_inst (
		.clk_i(clk_i),
		.nrst_i(nrst_i),
		.nrstSync_i(nrstSyncCnt),
		.count_o(count)
	);
	
endmodule  // strb
