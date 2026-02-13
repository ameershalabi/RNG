import sys
import os

# Add models/ for casr_30.py
sys.path.append(
    os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../models'))
)

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles
from helper import *
from casr_30 import *


# Test 1 :-
# Produce 100 valid outputs

def hex_to_signed(hex_str, bits=64):
    h = hex_str[2:-1] if hex_str.startswith('x"') else hex_str
    val = int(h, 16)
    return val - (1 << bits) if val & (1 << (bits - 1)) else val

@cocotb.test()
async def test1(dut):
    test_sample = 100

    # Start Clock at 100MHz
    clock = Clock(dut.clk, 10, unit="ns")
    cocotb.start_soon(clock.start())

    # Reset , Enable and Clear for one Cycle
    dut.rst.value = 0
    dut.clr.value = 0
    dut.enb.value = 0

    dut.seed_i.value = 0
    dut.init_i.value = 0
    dut.gen_i.value = 0

    await RisingEdge(dut.clk)

    dut.rst.value = 1
    dut.clr.value = 1
    dut.enb.value = 1

    await RisingEdge(dut.clk)
    dut._log.info("Reset complete")
    dut._log.info("Enabled")
    dut._log.info("Clear complete")
    
    # load the seed and initilize the generator
    dut.clr.value = 0
    await RisingEdge(dut.clk)
    dut.gen_i.value = 1
    dut.init_i.value = 1
    
    SEED = 0x36BD0F75A4ABE07D
    dut.seed_i.value = SEED
    await RisingEdge(dut.clk)
    dut.init_i.value = 0
    dut._log.info("Seed loaded")
    outputs = []
    counter = 0
    invalid = 0
    
    # start generating
    while True:
        if invalid == 10:
            break
        await RisingEdge(dut.clk)
        if counter == test_sample:
           break
        if counter == test_sample-3:
            dut.gen_i.value = 0
        
        if dut.valid_o.value == 1:
            outputs.append(dut.state_o.value.to_signed())
            dut._log.info(f"Step {counter}: state = {dut.state_o.value.to_signed()} (0x{dut.state_o.value.to_unsigned():016X}) - VALID")
            counter += 1
        else:
            dut._log.info(f"Step {counter}: waiting... - NOT VALID YET")
            invalid += 1
    await ClockCycles(dut.clk, 4)
    dut._log.info("Generate complete")
    dut._log.info(f"Valid outputs count: {len(outputs)}")

    dut._log.info("Comparing test to model")

    # convert the seed to a list of bits to feed into the model
    signed_value = SEED & ((1 << 64) - 1)
    SEED = [int(b) for b in format(signed_value, '064b')][::-1]
    model = casr_30(SEED, mode='p')

    # generate the outputs from the model
    model_outputs = prep_out(model.generate(test_sample),64)
    matching = 0
    for i in range(len(outputs)):
        if outputs[i] != hex_to_signed(model_outputs[i]):
            dut._log.error(f"Mismatch at step {i}: test={outputs[i]}, model={hex_to_signed(model_outputs[i])}")
            invalid += 1
        else:
            dut._log.info(f"Match at step {i}: test={outputs[i]}, model={hex_to_signed(model_outputs[i])}")
            matching += 1
    dut._log.info("Comparison complete")
    dut._log.info(f"Matching outputs: {matching}")
    if matching == len(outputs):
        dut._log.info("========== ALL TESTS PASSED ==========")
    else:
        dut._log.error("========== TEST FAILED ==========")