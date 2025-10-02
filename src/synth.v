/*******************************************************************************
* @file    : synth.v                                                           *
* @author  : @s-grundner                                                       *
* @license : Apache-2.0                                                        *
* @brief   : Synthesis top module. This connects midi decoder and oscillator   *
*            stack.                                                            *
*******************************************************************************/

`include "global.v"

module synth (
    input wire clk_i,
    input wire nrst_i,
    input wire rxData_i,
    output wire [`OSC_VOICES-1:0] oscOut_o,
    output wire activeOscPwm_o
);

    wire noteOnStrb;
    wire noteOffStrb;
    wire [`MIDI_PAYLOAD_BITS-1:0] note;
    
    wire midiByteValid;
    wire [`MIDI_PAYLOAD_BITS-1:0] midiByte;
    
    assign activeOscPwm_o = noteOnStrb;

    // ---------------------------- Modules --------------------------------- //

    rx rx_inst (
        .clk_i(clk_i),
        .nrst_i(nrst_i),
        .rxData_i(rxData_i),
        .dataReady_o(midiByteValid),
        .midiData_o(midiByte)
    );

    midi #(
        .MIDI_CHANNEL(0)
    ) midi_inst (
        .clk_i(clk_i),
        .nrst_i(nrst_i),
        .midiByte_i(midiByte),
        .midiByteValid_i(midiByteValid),
        .note_o(note),
        .noteOnStrb_o(noteOnStrb),
        .noteOffStrb_o(noteOffStrb)
    );

    reg [3:0] oscCount;
    
    always @(posedge clk_i or negedge nrst_i) begin
        if (!nrst_i) begin
            oscCount <= 4'b0;
        end else if (noteOnStrb) begin
            oscCount <= oscCount + 4'b1;
        end else if (noteOffStrb) begin
            oscCount <= oscCount - 4'b1;
        end
    end

    // Generate Oscillator stack

    wire [`OSC_VOICES-1:0] wave;

    genvar i;
    generate
        for (i = 0; i < `OSC_VOICES; i = i + 1) begin : oscStack_gen
            osc osc_inst (
                .clk_i(clk_i),
                .nrst_i(nrst_i),
                .nrstPhase_i(1'b1),
                .note_i(8'b0),
                .enable_i(i < oscCount),
                .wave_o(oscOut_o[i])
            );
        end
    endgenerate
    

endmodule