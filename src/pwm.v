/*******************************************************************************
* @file    : pmw.v                                                             *
* @author  : @s-grundner                                                       *
* @license : Apache-2.0                                                        *
* @brief   : PWM generator.                                                    *
*******************************************************************************/

module pwm (
	input wire clk_i,
	input wire nrst_i,
	input wire [7:0] onCnt_i,
	input wire [7:0] periodCnt_i,
	output wire pwm_o
);

    wire cntSyncRst;
    wire [7:0] pwmCountVal;
    
    counter #(
        .BW(8)
    ) pwmCounter_inst (
        .clk_i(clk_i),
        .nrst_i(nrst_i),
        .nrstSync_i(cntSyncRst),
        .count_o(pwmCountVal)
    );
    
    assign cntSyncRst = (pwmCountVal >= periodCnt_i);
    assign pwm_o = (pwmCountVal < onCnt_i);

endmodule    // pwm