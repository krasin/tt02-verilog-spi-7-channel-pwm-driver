`default_nettype none

module krasin_tt02_verilog_spi_7_channel_pwm_driver (
  input [7:0] io_in,
  output [7:0] io_out
);
    
  wire clk = io_in[0];
  wire reset = io_in[1];
  wire sclk = io_in[2];
  wire mosi = io_in[3];

  wire [6:0] pwm_out;
  assign io_out[6:0] = pwm_out;

  wire miso = io_out[7];

  // 8-bit PWM counter that goes from 0 to 254.
  reg [7:0] counter;

  // PWM level for channel0.
  // 0 means always off.
  // 1 means that PWM will be on for just 1 clock cycle and then off for the other 254, giving 1/255 on average.
  // 254 means 254/255 on.
  // 255 means always on.
  reg [7:0] pwm0_level;
  // The rest of the channels.
  reg [7:0] pwm1_level;
  reg [7:0] pwm2_level;
  reg [7:0] pwm3_level;
  reg [7:0] pwm4_level;
  reg [7:0] pwm5_level;
  reg [7:0] pwm6_level;

  function is_on(input [7:0] level, input[7:0] counter);
     begin
       is_on = (counter < level);
     end
  endfunction // is_on

  assign pwm_out[0] = is_on(pwm0_level, counter);
  assign pwm_out[1] = is_on(pwm1_level, counter);
  assign pwm_out[2] = is_on(pwm2_level, counter);
  assign pwm_out[3] = is_on(pwm3_level, counter);
  assign pwm_out[4] = is_on(pwm4_level, counter);
  assign pwm_out[5] = is_on(pwm5_level, counter);
  assign pwm_out[6] = is_on(pwm6_level, counter);

  // external clock is 1000Hz.
  always @(posedge clk) begin
    // if reset, set counter and pwm levels to 0
    if (reset) begin
      counter <= 0;
      pwm0_level <= 0;
      pwm1_level <= 0;
      pwm2_level <= 0;
      pwm3_level <= 0;
      pwm4_level <= 0;
      pwm5_level <= 0;
      pwm6_level <= 0;
    end else begin // if (reset)
      if (counter == 254) begin
        // Roll over.
        counter <= 0;
      end else begin
        // increment counter
        counter <= counter + 1'b1;
      end
      //if (pset) begin
      //  case (addr)
      //    0: pwm0_level <= level;
      //    1: pwm1_level <= level;
      //    2: pwm2_level <= level;
      //    3: pwm3_level <= level;
      //    4: pwm4_level <= level;
      //    5: pwm5_level <= level;
      //    6: pwm6_level <= level;
      //    7: pwm7_level <= level;
      //  endcase
      //end // if (set)
    end
  end // always @ (posedge clk)
endmodule
