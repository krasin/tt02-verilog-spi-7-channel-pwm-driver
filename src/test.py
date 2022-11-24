import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer, ClockCycles


@cocotb.test()
async def test_zeros_by_default(dut):
  dut._log.info("start")
  clock = Clock(dut.clk, 10, units="us")
  cocotb.start_soon(clock.start())

  dut._log.info("first cycle")
  dut.reset.value = 1
  dut.cs.value = 1
  await ClockCycles(dut.clk, 1)
  dut.mosi.value = 0
  dut.reset.value = 0
  dut._log.info("check that all pins are zeros and stay like that")
  for i in range(10):
    await ClockCycles(dut.clk, 1)
    print("dut.out_pwm: {}, miso: {}".format(dut.pwm_out.value, dut.miso.value))
    assert int(dut.pwm_out.value) == 0
    assert int(dut.miso.value) == 0

@cocotb.test()
async def test_zeros_by_default_sclk(dut):
  dut._log.info("start")
  clock = Clock(dut.clk, 10, units="us")
  cocotb.start_soon(clock.start())

  dut._log.info("first cycle")
  dut.reset.value = 1
  dut.cs.value = 0
  await ClockCycles(dut.clk, 1)
  dut.reset.value = 0
  dut.mosi.value = 0
  dut._log.info("check that all pins are zeros and stay like that, even when SPI clock is ticking")
  for i in range(200):
    # SPI clock ticks once per two regular clock cycles in this test.
    if (i / 2) % 2 == 0:
      dut.sclk.value = 0
    else:
      dut.sclk.value = 1
    await ClockCycles(dut.clk, 1)

    #print("i={}, dut.out_pwm: {}, miso: {}".format(i, dut.pwm_out.value, dut.miso.value))
    assert int(dut.pwm_out.value) == 0
    assert int(dut.miso.value) == 0


async def reset(dut, clock):
  dut.reset.value = 1
  dut.cs.value = 1
  await ClockCycles(dut.clk, 1)
  dut.reset.value = 0
  dut.mosi.value = 0


async def get_level(dut, clock, idx):
  dut.cs.value = 0
  # Sending a read command.
  for i in range(8):
    dut.mosi.value = idx >> 7
    idx = (idx << 1) & 0xFF
    dut.sclk.value = 1
    await ClockCycles(dut.clk, 2)
    dut.sclk.value = 0
    await ClockCycles(dut.clk, 2)

  # Reading the result
  dut.mosi.value = 0
  res = 0
  for i in range(8):
    dut.sclk.value = 1
    await ClockCycles(dut.clk, 2)
    dut.sclk.value = 0
    await ClockCycles(dut.clk, 2)
    res = (res << 1) + dut.miso.value

  dut.cs.value = 1
  await ClockCycles(dut.clk, 2)
  return res


async def set_level(dut, clock, idx, level):
  print("set_level(idx={}, level={})".format(idx, level))
  if level > 255:
    raise ValueError("level must fit 8 bits, but it's {}".format(level))

  idx = 0x80 | (idx & 0x7F)
  dut.cs.value = 0
  # Sending a write command (highest bit is set).
  for i in range(8):
    dut.mosi.value = idx >> 7
    idx = (idx << 1) & 0xFF
    dut.sclk.value = 1
    await ClockCycles(dut.clk, 2)
    dut.sclk.value = 0
    await ClockCycles(dut.clk, 2)

  # Processing the write value.
  res = 0
  tmp_val = level
  for i in range(8):
    dut.mosi.value = tmp_val >> 7
    tmp_val = (tmp_val << 1) & 0xFF
    dut.sclk.value = 1
    await ClockCycles(dut.clk, 2)
    dut.sclk.value = 0
    await ClockCycles(dut.clk, 2)
    res = (res << 1) + dut.miso.value

  # The returned byte is zero, because it was waiting for the value to set.
  assert res == 0

  # And now we read what we have set back.
  dut.mosi.value = 0
  res = 0
  for i in range(8):
    dut.sclk.value = 1
    await ClockCycles(dut.clk, 2)
    dut.sclk.value = 0
    await ClockCycles(dut.clk, 2)
    res = (res << 1) + dut.miso.value

  # Check that it returned the new level value.
  #print("got_level: {}, want_level: {}".format(res, level))
  assert res == level

  dut.cs.value = 1
  await ClockCycles(dut.clk, 2)



@cocotb.test()
async def test_read_write_regs(dut):
  dut._log.info("start")
  clock = Clock(dut.clk, 10, units="us")
  cocotb.start_soon(clock.start())

  await reset(dut, clock)
  dut._log.info("check that all levels are zeros after reset")
  for i in range(7):
    level = await get_level(dut, clock, i)
    assert level == 0

  dut._log.info("set pwm levels to non-zero values and check them")
  level = [0, 20, 63, 100, 127, 254, 255]
  for i in range(7):
    await set_level(dut, clock, i, level[i])
    cur_level = await get_level(dut, clock, i)
    #print("i={}, cur_level: {}, want_level: {}".format(i, cur_level, level[i]))
    assert cur_level == level[i]

  dut._log.info("check actual PWM outputs")
  cnt = [0, 0, 0, 0, 0, 0, 0]
  for i in range(255):
    await ClockCycles(dut.clk, 1)
    for j in range(7):
      val = dut.pwm_out[j].value
      cnt[j] += val
      #print("i={}, j={}, val={}".format(i, j, val))

  #print("cnt: {}".format(cnt))
  for i in range(7):
    assert cnt[i] == level[i]

@cocotb.test()
async def test_read_write_regs_all_values(dut):
  dut._log.info("start")
  clock = Clock(dut.clk, 10, units="us")
  cocotb.start_soon(clock.start())

  await reset(dut, clock)
  dut._log.info("check that all levels are zeros after reset")
  for i in range(7):
    level = await get_level(dut, clock, i)
    assert level == 0

  dut._log.info("set pwm levels to non-zero values and check them")
  for i in range(7):
    for j in range(256):
      await set_level(dut, clock, i, j)
      cur_level = await get_level(dut, clock, i)
      #print("i={}, cur_level: {}, want_level: {}".format(i, cur_level, level[i]))
      assert cur_level == j

  dut._log.info("check actual PWM outputs")
  cnt = [0, 0, 0, 0, 0, 0, 0]
  for i in range(255):
    await ClockCycles(dut.clk, 1)
    for j in range(7):
      val = dut.pwm_out[j].value
      cnt[j] += val
      #print("i={}, j={}, val={}".format(i, j, val))

  #print("cnt: {}".format(cnt))
  for i in range(7):
    assert cnt[i] == 255
