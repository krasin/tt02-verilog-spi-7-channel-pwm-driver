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
  // SPI counter that tracks 8 bit.
  reg [2:0] spi_counter;
  // is_writing is set if we received a write command.
  reg is_writing;
  reg [2:0] write_addr;

  // Buffer from mosi.
  reg [7:0] in_buf;
  // Buffer for miso.
  reg [7:0] out_buf;

  // out_buf is advanced on each falling sclk.
  assign miso = out_buf[0];

  // 8-bit PWM counter that goes from 0 to 254.
  reg [7:0] counter;

  // PWM levels for each channel.
  // 0 means always off.
  // 1 means that PWM will be on for just 1 clock cycle and then off for the other 254, giving 1/255 on average.
  // 254 means 254/255 on.
  // 255 means always on.
  reg [7:0] pwm_level[6:0];

  function is_on(input [7:0] level, input[7:0] counter);
     begin
       is_on = (counter < level);
     end
  endfunction // is_on

  assign pwm_out[0] = is_on(pwm_level[0], counter);
  assign pwm_out[1] = is_on(pwm_level[1], counter);
  assign pwm_out[2] = is_on(pwm_level[2], counter);
  assign pwm_out[3] = is_on(pwm_level[3], counter);
  assign pwm_out[4] = is_on(pwm_level[4], counter);
  assign pwm_out[5] = is_on(pwm_level[5], counter);
  assign pwm_out[6] = is_on(pwm_level[6], counter);

  // external clock is 1000Hz.
  always @(posedge clk) begin
    // if reset, set counter and pwm levels to 0
    if (reset) begin
      counter <= 0;
      pwm_level[0] <= 0;
      pwm_level[1] <= 0;
      pwm_level[2] <= 0;
      pwm_level[3] <= 0;
      pwm_level[4] <= 0;
      pwm_level[5] <= 0;
      pwm_level[6] <= 0;
      in_buf <= 0;
      out_buf <= 0;
      prev_sclk <= 0;
      spi_counter <= 0;
      is_writing <= 0;
      write_addr <= 0;
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
        spi_counter <= 0;
        is_writing <= 0;
        write_addr <= 0;
      end else begin // if(cs)
        // The chip is selected.
        if (prev_sclk != sclk) begin
          // SPI clock changed. On rising edge we read from mosi, on falling edge, we write to miso.
          if (sclk) begin
            // Rising SCLK edge: reading from mosi.
            in_buf <= (in_buf << 1) | mosi;
            spi_counter <= spi_counter + 1'b1;
          end else begin // if (sclk)
            // Falling SCLK edge
            if (spi_counter == 0) begin
              if (is_writing) begin
                // Writing. We saved the write_addr after reading the first byte.
                pwm_level[write_addr] <= in_buf;
                // We output the saved value and reset.
                out_buf <= in_buf;
                is_writing <= 0;
                write_addr <= 0;
              end else begin // if (is_writing)
                if (in_buf[7]) begin
                  // We're writing, but the value will come as the next byte.
                  is_writing <= 1;
                  write_addr <= in_buf[2:0];
                end else begin // if (in_buf[7])
                  // Reading.
                  // We need to output a new byte.
                  // Address is in the 3 xlowest bits of in_buf.
                  out_buf <= pwm_level[in_buf[2:0]];
                end
              end // if (is_writing)
            end else begin // if (spi_counter == 0)
              // Advancing out_buf, so that miso sees a new value.
             out_buf <= out_buf >> 1;
            end
          end
          prev_sclk <= sclk;
        end
      end // else: !if(cs)
    end
  end // always @ (posedge clk)
endmodule
