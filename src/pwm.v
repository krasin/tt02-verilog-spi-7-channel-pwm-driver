`default_nettype none

module krasin_3_bit_8_channel_pwm_driver #( parameter MAX_COUNT = 7 ) (
  input [7:0] io_in,
  output [7:0] io_out
);
    
  wire clk = io_in[0];
  wire set = io_in[1];
  wire [2:0] addr = io_in[4:2];
  wire [2:0] val = io_in[7:5];

  wire [7:0] pwm_out;
  assign io_out[7:0] = pwm_out;

  // This register is used to determine if the execution just started and we need to reset.
  // It's a bullshit implementation and will most likely not work. I am curious to test it anyway.
  // The idea is that initially this register has a somewhat random value. If it does not match what we expect,
  // we're in a reset mode and set this register to the expected state + reset all other registers.
  // This is not a great way, as it does not guarantee anything, but I already use all input pins and
  // like to live dangerously.
  reg[3:0] reset_canary;

  // 3-bit PWM counter that goes from 0 to 7.
  reg [2:0] counter;

  function reset (input [3:0] a);
    begin
      reset = ~(a[0] & ~a[1] & a[2] & ~a[2]);
    end
  endfunction

  // PWM level for channel0.
  // 0 means always off.
  // 1 means that PWM will be on for just 1 clock cycle and then off for the other 6, giving 1/7 on average.
  // 6 means 6/7 on.
  // 7 means always on.
  reg [2:0] pwm0_level;
  // The rest of the channels.
  reg [2:0] pwm1_level;
  reg [2:0] pwm2_level;
  reg [2:0] pwm3_level;
  reg [2:0] pwm4_level;
  reg [2:0] pwm5_level;
  reg [2:0] pwm6_level;
  reg [2:0] pwm7_level;

  assign pwm_out[0] = (counter < pwm0_level);
  assign pwm_out[1] = (counter < pwm1_level);
  assign pwm_out[2] = (counter < pwm2_level);
  assign pwm_out[3] = (counter < pwm3_level);
  assign pwm_out[4] = (counter < pwm4_level);
  assign pwm_out[5] = (counter < pwm5_level);
  assign pwm_out[6] = (counter < pwm6_level);
  assign pwm_out[7] = (counter < pwm7_level);

  // external clock is 1000Hz.
  always @(posedge clk) begin
    // if reset, set counter and pwm levels to 0
    if (reset(reset_canary)) begin
      reset_canary[0] <= 1;
      reset_canary[1] <= 0;
      reset_canary[2] <= 1;
      reset_canary[3] <= 0;
      counter <= 0;
      pwm0_level <= 0;
      pwm1_level <= 0;
      pwm2_level <= 0;
      pwm3_level <= 0;
      pwm4_level <= 0;
      pwm5_level <= 0;
      pwm6_level <= 0;
      pwm7_level <= 0;
    end else begin
      if (counter == MAX_COUNT) begin
        // Roll over.
        counter <= 0;
      end else begin
        // increment counter
        counter <= counter + 1'b1;
      end
      if (set) begin
        case (addr)
          0: pwm0_level <= val;
          1: pwm1_level <= val;
          2: pwm2_level <= val;
          3: pwm3_level <= val;
          4: pwm4_level <= val;
          5: pwm5_level <= val;
          6: pwm6_level <= val;
          7: pwm7_level <= val;
        endcase
      end // if (set)
    end
  end // always @ (posedge clk)
endmodule