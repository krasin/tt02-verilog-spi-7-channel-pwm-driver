import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer, ClockCycles


@cocotb.test()
async def test_zeros_by_default(dut):
  dut._log.info("start")
  clock = Clock(dut.clk, 10, units="us")
  cocotb.start_soon(clock.start())

  dut._log.info("first cycle")
  dut.pset.value = 0

  dut._log.info("check that all pins are zeros and stay like that")
  for i in range(10):
    await ClockCycles(dut.clk, 1)
    print("dut.out_pwm: {}".format(dut.pwm_out.value))
    assert int(dut.pwm_out.value) == 0
