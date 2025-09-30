/*******************************************************************************
* @file    : osc.v                                                             *
* @author  : @s-grundner                                                       *
* @license : Apache-2.0                                                        *
* @brief   : Oscillator module. Generates a square wave for a given midi note  *
*******************************************************************************/

`include "counter.v"

module osc (
    input wire clk_i,
    input wire nrst_i,
    input wire nrstPhase_i,
    input wire [7:0] note_i,
    output wire wave_o
);

    // -------------------------- Parameters -------------------------------- //

    localparam MAX_NOTE = 8'd127;
    localparam MIN_NOTE = 8'd21; // A0
    
    localparam CNT_BW = 16;

    // ------------------------ Assign Outputs ------------------------------ //
    assign wave_o = wave;
    // ---------------------------- Signals --------------------------------- //

    reg [CNT_BW-1:0] oscCmp = {CNT_BW{1'b0}};
    wire [CNT_BW-1:0] oscCounter;

    reg wave = 1'b0;
    reg nrstCnt;

    // -------------------- Logic Implementations --------------------------- //

    wire toggleOsc = (oscCounter == oscCmp);
    
    // Toggle wave 
    always @(posedge clk_i or negedge nrst_i) begin
        if (!nrst_i) begin
            wave <= 1'b0;
        end else if (toggleOsc) begin
            wave <= ~wave;
        end
    end

    // Clamp note input and convert to counter period
    always @(*) begin 
        if (note_i < MIN_NOTE) begin
            oscCmp = noteToHalfCntPeriod(MIN_NOTE);
        end else if (note_i > MAX_NOTE) begin
            oscCmp = noteToHalfCntPeriod(MAX_NOTE);
        end else begin
            oscCmp = noteToHalfCntPeriod(note_i);
        end
    end

    // Determine counter reset condition
    always @(*) begin
        if (nrstPhase_i | toggleOsc) begin
            nrstCnt <= 1'b0;
        end else begin
            nrstCnt <= 1'b1;
        end
    end
    
    // -------------------------- Functions --------------------------------- //

    // MIDI note to counter Period conversion
    function [CNT_BW-1:0] noteToHalfCntPeriod;
        input [7:0] note;
        begin
            // n_cntPeriod = (f_clk / f_note) / 2
            // f_note = 440 * 2^((note - 69)/12)
            noteToHalfCntPeriod = (`F_CLK_HZ / (440 * (2**((note - 69) / 12)))) >> 1;
        end
    endfunction

    // ----------------------- Module Instances ----------------------------- //

    counter #(
        .BW(CNT_BW)
    ) oscCounter_inst (
        .clk_i(clk_i),
        .nrst_i(nrst_i),
        .nrstSync_i(nrstCnt),
        .count_o(oscCounter)
    );

endmodule  // osc
