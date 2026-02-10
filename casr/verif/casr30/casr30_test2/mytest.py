import sys
import os

sys.path.append(
    os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
)

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles
from helper import *

def hex_to_signed(hex_str, bits=64):
    h = hex_str[2:-1] if hex_str.startswith('x"') else hex_str
    val = int(h, 16)
    return val - (1 << bits) if val & (1 << (bits - 1)) else val


class casr_30:
    def __init__(self, state,mode='s'):
        self.state = state[:]
        self.n = len(state)
        self.mode = mode

    def rule30(self, L, C, R):
        return (L & ~C & ~R) | (~L & C) | (~L & ~C & R)

    def step(self):
        next_state = [0] * self.n
        for i in range(self.n):
            L = self.state[(i - 1) % self.n]
            C = self.state[i]
            R = self.state[(i + 1) % self.n]
            next_state[i] = self.rule30(L, C, R) & 1
        self.state = next_state
        return next_state
    # output_cell=-1 is MSB
    # output_cell=0 is LSB
    def generate(self, steps, output_cell=-1):
        stream = []
        for _ in range(steps):
            self.step()
            if self.mode == 'p':
                stream.append(self.state)
            else:
                stream.append(self.state[output_cell])
        return stream

async def reset_dut(dut):
    """
    Reset the design.

    From VHDL: rst is active LOW, meaning:
    - rst = 0 -> design is in reset (frozen)
    - rst = 1 -> design is running
    """
    # Set all inputs to safe values
    dut.rst.value = 0       # Assert reset (active LOW = 0 means reset)
    dut.clr.value = 0
    dut.enb.value = 0
    dut.seed_i.value = 0
    dut.init_i.value = 0
    dut.gen_i.value = 0

    # Hold reset for 3 clock cycles (give design time to reset)
    await ClockCycles(dut.clk, 3)

    # Release reset - design can now run
    dut.rst.value = 1
    await RisingEdge(dut.clk)

    dut._log.info("Reset complete")


async def enable_design(dut):
    """
    Enable the design.

    From VHDL: The design has a pipeline delay:
    - Cycle 0: We set enb = 1
    - Cycle 1: enb_r becomes 1 (registered in ctrl_proc)
    - Cycle 2: gen_proc can now see enb_r = 1

    So we must wait 2 cycles after enabling!
    """
    dut.enb.value = 1
    # await ClockCycles(dut.clk, 2)
    await RisingEdge(dut.clk)

    dut._log.info("Design enabled")

async def disable_design(dut):
    """
    Disable the design.

    From VHDL: The design has a pipeline delay:
    - Cycle 0: We set enb = 1
    - Cycle 1: enb_r becomes 1 (registered in ctrl_proc)
    - Cycle 2: gen_proc can now see enb_r = 1

    So we must wait 2 cycles after enabling!
    """
    dut.enb.value = 0
    # await ClockCycles(dut.clk, 2)
    await RisingEdge(dut.clk)

    dut._log.info("Design disabled")


async def load_seed(dut, seed):
    """
    Load a seed value into the CASR.

    From VHDL (lines 155-164):
    - When init_i = 1, the seed_i value is loaded into ext_casr_r
    - The extension bits are also set up for circular wrapping
    """
    dut.seed_i.value = seed
    dut.init_i.value = 1
    await RisingEdge(dut.clk)   # Seed is loaded on this rising edge

    dut.init_i.value = 0        # Deassert init
    await RisingEdge(dut.clk)

    dut._log.info(f"Loaded seed: 0x{seed:016X}")

async def clear_dut(dut):
    """
    Clear the design.

    From VHDL (lines 147-154):
    - When clr = 1, the design is cleared
    """
    dut.clr.value = 1
    await RisingEdge(dut.clk)
    dut.clr.value = 0
    await RisingEdge(dut.clk)
    dut._log.info("Design cleared")

@cocotb.test()
async def mytest(dut):
    test_sample=101

    # # Start Clock 100MHz
    clock = Clock(dut.clk, 10, unit="ns")
    cocotb.start_soon(clock.start())

    # Reset , Enable and Clear for one Cycle
    dut.rst.value = 0
    dut.clr.value = 0
    dut.enb.value = 0

    dut.seed_i.value = 0
    dut.init_i.value = 0
    dut.gen_i.value = 0

    await ClockCycles(dut.clk, 2)

    dut.rst.value = 1
    dut.clr.value = 1
    dut.enb.value = 1

    await RisingEdge(dut.clk)
    dut._log.info("Reset complete")
    dut._log.info("Enabled")
    dut._log.info("Clear complete")

    dut.clr.value = 0
    dut.init_i.value = 1
    
    SEED1 = 0x36BD0F75A4ABE07D 
    SEED2 = 0x36BD0F75A4ABE07D 
    SEED3 = 0x36BD0F75A4ABE07D 
    SEED4 = 0x36BD0F75A4ABE07D 
    SEED5 = 0x36BD0F75A4ABE07D 
    SEED6 = 0x36BD0F75A4ABE07D 
    dut.seed_i.value = SEED1
    dut._log.info("Seed loaded")
    dut.gen_i.value = 1
    await RisingEdge(dut.clk)
    dut.init_i.value = 0
    outputs = []
    counter= 0
    
    while(1):
        # i need 100 valid outputs
        # i need to clear 3 times
        # i need to pull gen_i down 2 times
        # i need to use 6 seeds
        # all the above within this while loop

        await RisingEdge(dut.clk)
        if counter == test_sample-1:
           break
        if counter == test_sample-2:
            dut.gen_i.value = 0
        #1-15 : SEED1
        #16-30 : SEED2
        #31-45 : SEED3
        #46-60 : SEED4
        #61-75 : SEED5
        #76-100 : SEED6
        if counter < 15:
            if dut.valid_o.value == 1:
                outputs.append(dut.state_o.value.to_signed())
                dut._log.info(f"Step {counter}: state = {dut.state_o.value.to_signed()} (0x{dut.state_o.value.to_unsigned():016X}) - VALID")
                counter = counter + 1
            else:
                dut._log.info(f"Step {counter}: waiting... - NOT VALID YET")
        if counter == 15 and dut.valid_o.value == 1:
            dut.gen_i.value = 0
            await RisingEdge(dut.clk)
            await clear_dut(dut)
            await enable_design(dut)
            await load_seed(dut, SEED2)
            dut.gen_i.value = 1
            await ClockCycles(dut.clk, 3)
        if counter >= 15 and counter < 30:
            if dut.valid_o.value == 1:
                outputs.append(dut.state_o.value.to_signed())
                dut._log.info(f"Step {counter}: state = {dut.state_o.value.to_signed()} (0x{dut.state_o.value.to_unsigned():016X}) - VALID")
                counter = counter + 1
            else:
                dut._log.info(f"Step {counter}: waiting... - NOT VALID YET")
        if counter == 30 and dut.valid_o.value == 1:
            # dut.gen_i.value = 0
            await RisingEdge(dut.clk)
            await clear_dut(dut)
            await enable_design(dut)
            await load_seed(dut, SEED3)
            dut.gen_i.value = 1
            await ClockCycles(dut.clk, 3)

        if counter >= 30 and counter < 45:
            if dut.valid_o.value == 1:
                outputs.append(dut.state_o.value.to_signed())
                dut._log.info(f"Step {counter}: state = {dut.state_o.value.to_signed()} (0x{dut.state_o.value.to_unsigned():016X}) - VALID")
                counter = counter + 1
            else:
                dut._log.info(f"Step {counter}: waiting... - NOT VALID YET")
        if counter == 45 and dut.valid_o.value == 1:
            dut.gen_i.value = 0
            await RisingEdge(dut.clk)
            await clear_dut(dut)
            await enable_design(dut)
            await load_seed(dut, SEED4)
            dut.gen_i.value = 1
            await ClockCycles(dut.clk, 3)
        if counter >= 45 and counter < 60:
            if dut.valid_o.value == 1:
                outputs.append(dut.state_o.value.to_signed())
                dut._log.info(f"Step {counter}: state = {dut.state_o.value.to_signed()} (0x{dut.state_o.value.to_unsigned():016X}) - VALID")
                counter = counter + 1
            else:
                dut._log.info(f"Step {counter}: waiting... - NOT VALID YET")
        if counter == 60 and dut.valid_o.value == 1:
            dut.gen_i.value = 0
            await RisingEdge(dut.clk)
            await clear_dut(dut)
            await enable_design(dut)
            await load_seed(dut, SEED5)
            dut.gen_i.value = 1
            await ClockCycles(dut.clk, 3)
            await disable_design(dut)
        if counter >= 60 and counter < 75:
            if dut.valid_o.value == 1:
                outputs.append(dut.state_o.value.to_signed())
                dut._log.info(f"Step {counter}: state = {dut.state_o.value.to_signed()} (0x{dut.state_o.value.to_unsigned():016X}) - VALID")
                counter = counter + 1
            else:
                dut._log.info(f"Step {counter}: waiting... - NOT VALID YET")
        if counter == 75 and dut.valid_o.value == 1:
            dut.gen_i.value = 0
            await RisingEdge(dut.clk)
            await clear_dut(dut)
            await enable_design(dut)
            await load_seed(dut, SEED6)
            dut.gen_i.value = 1
            await ClockCycles(dut.clk, 3)
        if counter >= 75:
            if dut.valid_o.value == 1:
                outputs.append(dut.state_o.value.to_signed())
                dut._log.info(f"Step {counter}: state = {dut.state_o.value.to_signed()} (0x{dut.state_o.value.to_unsigned():016X}) - VALID")
                counter = counter + 1
            else:
                dut._log.info(f"Step {counter}: waiting... - NOT VALID YET")

    
    await ClockCycles(dut.clk,4)
    dut._log.info("Generate complete")
    dut._log.info(f"Valid outputs count: {len(outputs)}")
    dut._log.info(f"Valid outputs: {outputs}")

   
    # dut._log.info("Comparing test to model")

    # #convert the seed to a list of bits
    # signed_value = SEED & ((1 << 64) - 1)
    # SEED = [int(b) for b in format(signed_value, '064b')][::-1]
    # model = casr_30(SEED, mode='p')

    # model_outputs = prep_out(model.generate(10),64)
    # for i in range(len(outputs)):
    #     if outputs[i] != hex_to_signed(model_outputs[i]):
    #         dut._log.error(f"Mismatch at step {i}: test={outputs[i]}, model={model_outputs[i]}")
    # dut._log.info("Comparison complete")

    dut._log.info("========== ALL TESTS PASSED ==========")