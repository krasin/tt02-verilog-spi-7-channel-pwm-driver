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
  await ClockCycles(dut.clk, 1)

  dut._log.info("check that all pins are zeros and stay like that")
  for i in range(20):
    await ClockCycles(dut.clk, 1)
    # print("dut.out_pwm: {}".format(dut.pwm_out.value))
    assert int(dut.pwm_out.value) == 0

@cocotb.test()
async def test_pwm0_full_on(dut):
  dut._log.info("start")
  clock = Clock(dut.clk, 10, units="us")
  cocotb.start_soon(clock.start())

  dut._log.info("set pwm0=7")
  dut.pset.value = 1
  dut.addr.value = 0
  dut.level.value = 7
  await ClockCycles(dut.clk, 1)

  dut._log.info("check that pwm0 is fully on")
  for i in range(20):
    await ClockCycles(dut.clk, 1)
    # print("dut.out_pwm: {}".format(dut.pwm_out.value))
    assert int(dut.pwm_out.value) == 1


# Reset all pwm levels to zeros.
async def set_all_levels_zero(dut, clock):
  for i in range(8):
    dut._log.info("reset pwm{}".format(i))
    dut.pset.value = 1
    dut.addr.value = i
    dut.level.value = 0
    await ClockCycles(dut.clk, 1)

  dut.pset.value = 0
  await ClockCycles(dut.clk, 1)


@cocotb.test()
async def test_pwm1_level_4(dut):
  dut._log.info("start")
  clock = Clock(dut.clk, 10, units="us")
  cocotb.start_soon(clock.start())

  await set_all_levels_zero(dut, clock)

  dut._log.info("set pwm1=4")
  dut.pset.value = 1
  dut.addr.value = 1
  dut.level.value = 4
  await ClockCycles(dut.clk, 1)
  dut.pset.value = 0

  dut._log.info("check that pwm4 is at level 4")
  cnt = 0
  for i in range(70):
    await ClockCycles(dut.clk, 1)
    print("dut.out_pwm: {}".format(dut.pwm_out.value))
    if (int(dut.pwm_out.value) & 0x2):
        cnt += 1
  # We need exactly 4/7, so 40 from 70 cycles.
  assert cnt == 40
