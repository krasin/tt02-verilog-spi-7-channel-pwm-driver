`default_nettype none

module krasin_tt02_verilog_spi_7_channel_pwm_driver (
  input [7:0] io_in,
  output [7:0] io_out
);

  wire clk = io_in[0];
  wire reset = io_in[1];
  wire sclk = io_in[2];
  wire cs = io_in[3];
  wire mosi = io_in[4];

  wire [6:0] pwm_out;
  assign io_out[6:0] = pwm_out;
  wire miso;
  assign io_out[7] = miso;

  // Previous value of sclk.
  // This is to track SPI clock transitions within the main clock trigger.
  reg prev_sclk;

  // Buffer from mosi.
  reg [15:0] in_buf;
  // Buffer for miso.
  reg [7:0] out_buf;

  // out_buf is advanced on each falling sclk.
  assign miso = out_buf[0];

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
      in_buf <= 0;
      out_buf <= 0;
      prev_sclk <= 0;
    end else begin // if (reset)
      if (counter == 254) begin
        // Roll over.
        counter <= 0;
      end else begin
        // increment counter
        counter <= counter + 1'b1;
      end
      if (cs) begin
        // The chip is not selected. Reset all SPI registers.
        in_buf <= 0;
        out_buf <= 0;
        prev_sclk <= 0;
      end else begin // if(cs)
        // The chip is selected.
        if (prev_sclk != sclk) begin
          // SPI clock changed. On rising edge we read from mosi, on falling edge, we write to miso.
          if (sclk) begin
            // Rising SCLK edge: reading from mosi.
            in_buf <= (in_buf << 1) + mosi;
          end else begin // if (sclk)
            // Falling SCLK edge: advancing out_buf, so that miso sees a new value.
            out_buf <= out_buf >> 1;
          end
          prev_sclk <= sclk;
        end
      end // else: !if(cs)

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
