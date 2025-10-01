/*
 * Copyright (c) 2024 Simon Grundner
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_s_grundner (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    synth synth_inst (
        .clk_i(clk),
        .nrst_i(rst_n),
        .rxData_i(ui_in[0]),
        .oscOut_o(uo_out[6:0]),
        .activeOscPwm_o(uo_out[7])
    );

    // All output pins must be assigned. If not used, assign to 0.
    assign uio_out = 0;
    assign uio_oe  = 0;

    // List all unused inputs to prevent warnings
    wire _unused = &{ena, 1'b0};

endmodule
