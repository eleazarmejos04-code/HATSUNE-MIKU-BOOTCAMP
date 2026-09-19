# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


@cocotb.test()
async def test_project(dut):
    dut._log.info("Start VGA simulation")

    # Set clock to ~25.175 MHz (period ~39.72 ns; 40 ns is standard for cocotb sim)
    clock = Clock(dut.clk, 40, unit="ns")
    cocotb.start_soon(clock.start())

    # Initialize pins & apply reset
    dut._log.info("Resetting design")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0

    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)

    dut._log.info("Testing initial output state after reset")

    # Decode standard TinyVGA PMOD bits:
    # uo_out[7] = hsync, uo_out[3] = vsync
    # uo_out[0, 4] = red, uo_out[1, 5] = green, uo_out[2, 6] = blue
    val = int(dut.uo_out.value)
    hsync = (val >> 7) & 1
    vsync = (val >> 3) & 1

    # In active visible display area (x=0, y=0), standard 640x480 sync lines are high (active low)
    assert hsync == 1, f"Expected HSync=1 during visible display, got {hsync}"
    assert vsync == 1, f"Expected VSync=1 during visible display, got {vsync}"

    # Step through one full 800-pixel line to verify HSync pulse appears
    dut._log.info("Stepping through one horizontal line (800 pixels)")
    hsync_low_detected = False

    for _ in range(800):
        await ClockCycles(dut.clk, 1)
        val = int(dut.uo_out.value)
        if ((val >> 7) & 1) == 0:
            hsync_low_detected = True

    assert hsync_low_detected, "HSync never pulsed low across 800 pixel clocks"

    dut._log.info("VGA timing test completed successfully")
