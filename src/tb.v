`default_nettype none
`timescale 1ns/1ps

/*
this testbench just instantiates the module and makes some convenient wires
that can be driven / tested by the cocotb test.py
*/

module tb (
    // testbench is controlled by test.py
    input 	 clk,
    input 	 reset,
    input 	 sclk,
    input        cs,
    input 	 mosi,
    output 	 miso,
    output [3:0] pwm_out
   );

    // this part dumps the trace to a vcd file that can be viewed with GTKWave
    initial begin
        $dumpfile ("tb.vcd");
        $dumpvars (0, tb);
        #1;
    end

    // wire up the inputs and outputs
    wire [7:0] inputs = {3'b0, mosi, cs, sclk, reset, clk};
    wire [7:0] outputs;
    assign miso = outputs[7];
    assign pwm_out = outputs[3:0];

    // instantiate the DUT
    krasin_tt02_verilog_spi_7_channel_pwm_driver krasin_tt02_verilog_spi_7_channel_pwm_driver(
        .io_in  (inputs),
        .io_out (outputs)
        );

endmodule
