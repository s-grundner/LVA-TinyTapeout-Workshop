/*******************************************************************************
* @file    : rx.v                                                              *
* @author  : @s-grundner                                                       *
* @license : Apache-2.0                                                        *
* @brief   : RX frontend of midi input. 31250 baud, 8 data bits, no parity     *
*******************************************************************************/

`include "global.v"

module rx (
    input wire clk_i,
    input wire nrst_i,
    input wire rxData_i,
    output wire dataReady_o,
    output reg [`MIDI_PAYLOAD_BITS-1:0] midiData_o
);

    // ----------------------- Internal Parameters ---------------------------- //

    localparam CYCLES_PER_BIT = `F_CLK_HZ / `F_BAUD;
    localparam COUNT_REG_LEN = 1 + $clog2(CYCLES_PER_BIT);

    // FSM States
    localparam FSM_IDLE = 0;
    localparam FSM_START = 1;
    localparam FSM_RECV = 2;
    localparam FSM_STOP = 3;

    // ------------------------ Internal Register ----------------------------- //

    reg [2:0] fsmState;
    reg [2:0] nextFsmState;

    // Break up long timing paths from the input to the logic by internally
    // latching rx buffer
    reg rxDataReg0;
    reg rxDataReg1;

    // Storage of rx data
    reg [`MIDI_PAYLOAD_BITS-1:0] midiData;
    // Count Clock Cycles
    reg [COUNT_REG_LEN-1:0] cycleCounter;
    // Count Recieved Bits
    reg [3:0] bitCounter;

    // Sampling of the midi input line
    reg sampledBit;

    // --------------------- Combinatorial Processes -------------------------- //

    // Next State Conditions
    wire nextBitReady = (cycleCounter == CYCLES_PER_BIT) ||
                        (fsmState == FSM_STOP) &&
                        (cycleCounter == CYCLES_PER_BIT/2);
    wire payloadDone = (bitCounter == `MIDI_PAYLOAD_BITS);
    assign dataReady_o = payloadDone;

    // Select Next State
    always @(*) begin : nextFsmState_p
        case (fsmState)
            FSM_IDLE:  nextFsmState = rxDataReg0 ? FSM_IDLE : FSM_START;
            FSM_START: nextFsmState = nextBitReady ? FSM_RECV : FSM_START;
            FSM_RECV:  nextFsmState = payloadDone ? FSM_STOP : FSM_RECV;
            FSM_STOP:  nextFsmState = nextBitReady ? FSM_IDLE : FSM_STOP;
            default:   nextFsmState = FSM_IDLE;
        endcase
    end

    // ------------------------ Register Processes ---------------------------- //

    // Register Output
    always @(posedge clk_i or negedge nrst_i) begin : output_p
        if (!nrst_i) begin
            midiData_o <= 8'b0;
        end else if (fsmState == FSM_STOP) begin
            midiData_o <= midiData;
        end
    end

    // Sample input.
    always @(posedge clk_i or negedge nrst_i) begin : sampleBit_p
        if (!nrst_i) begin
            sampledBit <= 1'b0;
        end else if (cycleCounter == CYCLES_PER_BIT / 2) begin
            // Take sample in the middle of a bit
            sampledBit <= rxDataReg0;
        end
    end

    // Register FSM State
    always @(posedge clk_i or negedge nrst_i) begin : fsmState_p
        if (!nrst_i) begin
            fsmState <= FSM_IDLE;
        end else begin
            fsmState <= nextFsmState;
        end
    end

    // Register Rx Buffers
    always @(posedge clk_i or negedge nrst_i) begin : rxBuffer_p
        if (!nrst_i) begin
            rxDataReg0 <= 1'b1;
            rxDataReg1 <= 1'b1;
        end else begin
            rxDataReg0 <= rxDataReg1;
            rxDataReg1 <= rxData_i;
        end
    end

    // Update the Sampled Bit to the rx-buffer
    integer i = 0;
    always @(posedge clk_i or negedge nrst_i) begin : updRxBuffer_p
        if (!nrst_i) begin
            midiData <= `MIDI_PAYLOAD_BITS'b0;
        end else if (fsmState == FSM_IDLE) begin
            midiData <= `MIDI_PAYLOAD_BITS'b0;
        end else if (fsmState == FSM_RECV && nextBitReady) begin
            midiData[`MIDI_PAYLOAD_BITS-1] <= sampledBit;
            for (i = `MIDI_PAYLOAD_BITS - 2; i >= 0; i = i - 1) begin
                midiData[i] <= midiData[i+1];
            end
        end
    end

    // Increment Cycle Counter
    always @(posedge clk_i or negedge nrst_i) begin : countCycles_p
        if (!nrst_i) begin
            cycleCounter <= 12'b0;
        end else if (nextBitReady) begin
            cycleCounter <= 12'b0;
        end else if (fsmState == FSM_START || fsmState == FSM_RECV || fsmState == FSM_STOP) begin
            cycleCounter <= cycleCounter + 12'b1;
        end
    end

    // Increments the bit counter when recieving.
    always @(posedge clk_i or negedge nrst_i) begin : countBit_p
        if (!nrst_i) begin
            bitCounter <= 4'b0;
        end else if (fsmState != FSM_RECV) begin
            bitCounter <= 4'b0;
        end else if (fsmState == FSM_RECV && nextBitReady) begin
            bitCounter <= bitCounter + 4'b1;
        end
    end

endmodule  // rx
