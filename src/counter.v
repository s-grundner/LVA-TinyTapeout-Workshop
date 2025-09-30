/*******************************************************************************
* @file    : counter.v                                                         *
* @author  : @s-grundner                                                       *
* @license : Apache-2.0                                                        *
* @brief   : Counter module. Counts up on each clock cycle                     *
*******************************************************************************/

`default_nettype none
`ifndef __COUNTER__
`define __COUNTER__ 

module counter #(
    parameter BW = 8
) (
    input clk_i,
    input nrst_i,
    input nrstSync_i,
    output wire [BW-1:0] count_o
);

    reg [BW-1:0] count_r;
    assign count_o = count_r;

    always @(posedge clk_i or negedge nrst_i) begin
        if (!nrst_i) begin
            count_r <= {BW{1'b0}};
        end else if (!nrstSync_i) begin
            count_r <= {BW{1'b0}};
		end else begin
            count_r <= count_r + {{(BW - 1) {1'b0}}, 1'b1};
        end
    end
endmodule  // counter

`endif
`default_nettype wire
