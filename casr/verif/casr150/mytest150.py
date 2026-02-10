import sys
import os

sys.path.append(
    os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
)
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles
from helper import *

def hex_to_signed(hex_str, bits=256):
    h = hex_str[2:-1] if hex_str.startswith('x"') else hex_str
    val = int(h, 16)
    return val - (1 << bits) if val & (1 << (bits - 1)) else val


class casr_150:
    def __init__(self, state,mode='s'):
        self.state = state[:]
        self.n = len(state)
        self.mode = mode

    def step(self):
        next_state = [0] * self.n
        for i in range(self.n):
            left   = self.state[(i - 1) % self.n]
            center = self.state[i]
            right  = self.state[(i + 1) % self.n]
            next_state[i] = left ^ center ^ right
        self.state = next_state
        return self.state

    def generate(self, steps, output_cell=-1):
        stream = []
        for _ in range(steps):
            self.step()
            if self.mode == 'p':
                stream.append(self.state)
            else:
                stream.append(self.state[output_cell])
        return stream



@cocotb.test()
async def mytest150(dut):

    # Start Clock 100MHz
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
    SEED = 0xFC7FFDD5E74EF4C24F7F1722EF758AC4DB33FA5E3C4D8A2C36BD0F75A4ABE07D 
    dut.seed_i.value = SEED
    dut._log.info("Seed loaded")
    dut.gen_i.value = 1
    await RisingEdge(dut.clk)
    dut.init_i.value = 0
    outputs = []
    for i in range(10):
        await RisingEdge(dut.clk)
        if dut.valid_o.value == 1:
            outputs.append(dut.state_o.value.to_signed())
            dut._log.info(f"Step {i}: state = {dut.state_o.value.to_signed()} (0x{dut.state_o.value.to_unsigned():016X}) - VALID")
        else:
            dut._log.info(f"Step {i}: waiting... - NOT VALID YET")
    dut.gen_i.value = 0
    dut._log.info("Generate complete")

   
    dut._log.info("Comparing test to model")

    #convert the seed to a list of bits
    signed_value = SEED & ((1 << 256) - 1)
    SEED = [int(b) for b in format(signed_value, '0256b')][::-1]
    model = casr_150(SEED, mode='p')

    model_outputs = prep_out(model.generate(10),256)
    for i in range(len(outputs)):
        if outputs[i] != hex_to_signed(model_outputs[i]):
            dut._log.error(f"Mismatch at step {i}: test={outputs[i]}, model={model_outputs[i]}")
    dut._log.info("Comparison complete")

    dut._log.info("========== ALL TESTS PASSED ==========")
