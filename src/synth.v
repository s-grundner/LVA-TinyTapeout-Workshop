/*******************************************************************************
* @file    : synth.v                                                           *
* @author  : @s-grundner                                                       *
* @license : Apache-2.0                                                        *
* @brief   : Synthesis top module. This connects midi decoder and oscillator   *
*            stack.                                                            *
*******************************************************************************/

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
    
    assign activeOscPwm_o = 1'b0;
    assign oscOut_o = `OSC_VOICES'b0;

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

endmodule