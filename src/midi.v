/*******************************************************************************
* @file    : midi.v                                                            *
* @author  : @s-grundner                                                       *
* @license : Apache-2.0                                                        *
* @brief   : MIDI command parser. Extracts note on/off commands for selected
             channel. Only feed Channel Voice Messages (0x8n, 0x9n)
*******************************************************************************/

`include "global.v"

module midi #(
    parameter MIDI_CHANNEL = 0
) (
    input wire clk_i,
    input wire nrst_i,
    input wire midiByteValid_i,
    input wire [7:0] midiByte_i,
    output wire [`MIDI_PAYLOAD_BITS-1:0] note_o,
    output wire noteOnStrb_o,
    output wire noteOffStrb_o
);
    // ----------------------- Internal Parameters -------------------------- //

    localparam CMD_BITS = 4;
    localparam CMD_NOTE_ON  = 4'b1001;
    localparam CMD_NOTE_OFF = 4'b1000;

    localparam FSM_IDLE = 0;
    localparam FSM_CMD = 1;
    localparam FSM_VAL = 2;
    localparam FSM_VEL = 3;

    // ------------------------ Internal Register --------------------------- //

    reg [3:0] cmd;
    reg [`MIDI_PAYLOAD_BITS-1:0] note;

    reg [2:0] fsmState;
    reg [2:0] nextFsmState;

    assign note_o = note;
    assign noteOnStrb_o = (fsmState == FSM_VEL) && (cmd == CMD_NOTE_ON) && midiByteValid_i;
    assign noteOffStrb_o = (fsmState == FSM_VEL) && (cmd == CMD_NOTE_OFF) && midiByteValid_i;

    // --------------------- Combinatorial Processes ------------------------ //

    always @(*) begin : nextFsmState_p
        case (fsmState)
            FSM_IDLE: nextFsmState = midiByteValid_i ? FSM_CMD : FSM_IDLE;
            FSM_CMD:  nextFsmState = midiByteValid_i ? FSM_VAL : FSM_CMD;
            FSM_VAL:  nextFsmState = midiByteValid_i ? FSM_VEL : FSM_VAL;
            FSM_VEL:  nextFsmState = midiByteValid_i ? FSM_IDLE : FSM_VEL;
            default:  nextFsmState = FSM_IDLE;
        endcase
    end

    // ---------------------- Register Processes --------------------------- //

    always @(posedge clk_i or negedge nrst_i) begin : fsmState_p
        if (!nrst_i) begin
            fsmState <= FSM_IDLE;
        end else begin
            fsmState <= nextFsmState;
        end
    end	

    wire chValid = (midiByte_i[3:0] == 4'(MIDI_CHANNEL));
    always @(posedge clk_i or negedge nrst_i) begin : midiCmd_p
        if (!nrst_i) begin
            cmd <= CMD_BITS'(0);
        end else if (fsmState == FSM_CMD && chValid) begin
            cmd <= midiByte_i[7:4];
        end
    end
    
    always @(posedge clk_i or negedge nrst_i) begin : midiNote_p
        if (!nrst_i) begin
            note <= `MIDI_PAYLOAD_BITS'b0;
        end else if (fsmState == FSM_VAL && chValid) begin
            note <= midiByte_i;
        end
    end

endmodule