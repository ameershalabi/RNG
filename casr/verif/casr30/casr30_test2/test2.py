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

# Test 2 :-
    # produce 100 valid outputs
    # clear atleast 3 times
    # pull gen_i down 2 times
    # use 6 seeds


def hex_to_signed(hex_str, bits=64):
    h = hex_str[2:-1] if hex_str.startswith('x"') else hex_str
    val = int(h, 16)
    return val - (1 << bits) if val & (1 << (bits - 1)) else val


async def reset_dut(dut):

    dut.rst.value = 0 
    dut.clr.value = 0
    dut.enb.value = 0
    dut.seed_i.value = 0
    dut.init_i.value = 0
    dut.gen_i.value = 0

    await RisingEdge(dut.clk)

    dut.rst.value = 1
    await RisingEdge(dut.clk)

    dut._log.info("Reset complete")

async def load_seed(dut, seed):
   
    dut.seed_i.value = seed
    dut.init_i.value = 1
    await RisingEdge(dut.clk) 

    dut.init_i.value = 0
    await RisingEdge(dut.clk)

    dut._log.info(f"Loaded seed: 0x{seed:016X}")

async def clear_dut(dut):
   
    dut.clr.value = 1
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.clr.value = 0
    await RisingEdge(dut.clk)
    dut._log.info("Design cleared")

async def wait_valid_and_store(dut, counter, outputs):
    if dut.valid_o.value == 1:
        outputs.append(dut.state_o.value.to_signed())
        dut._log.info(f"Step {counter}: state = {dut.state_o.value.to_signed()} (0x{dut.state_o.value.to_unsigned():016X}) - VALID")
        counter = counter + 1
        return True
    else:
        dut._log.info(f"Step {counter}: waiting... - NOT VALID YET")
        return False

async def clear_and_load_seed(dut, seed):
    await clear_dut(dut)
    await load_seed(dut, seed)

def seed_to_model(seed):
    signed = seed & ((1 << 64) - 1)
    bits = [int(b) for b in format(signed, "064b")][::-1]
    return casr_30(bits, mode="p")

@cocotb.test()
async def mytest(dut):
    test_sample=101
    segments = [15, 15, 15, 15, 15, 25]
    seeds = [0x36BD0F75A4ABE07D,
             0x123456789ABCDEF0,
             0xFEDCBA9876543210,
             0xA5A5A5A5A5A5A5A5,
             0x5A5A5A5A5A5A5A5A,
             0x0F0F0F0F0F0F0F0F]

    # Start Clock at 100MHz
    clock = Clock(dut.clk, 10, unit="ns")
    cocotb.start_soon(clock.start())

    await RisingEdge(dut.clk)

    # Reset , Enable and Clear for one Cycle
    dut.rst.value = 0
    dut.clr.value = 0
    dut.enb.value = 0

    dut.gen_i.value = 0
    dut.seed_i.value = 0
    dut.init_i.value = 0

    await RisingEdge(dut.clk)

    dut.rst.value = 1
    dut.clr.value = 1
    dut.enb.value = 1

    await RisingEdge(dut.clk)
    dut._log.info("Reset complete")
    dut._log.info("Enabled")
    dut._log.info("Clear complete")

    dut.clr.value = 0
    await RisingEdge(dut.clk)
    dut.gen_i.value = 1
    dut.init_i.value = 1
    
    dut.seed_i.value = seeds[0]
    dut._log.info("Seed loaded")
    await RisingEdge(dut.clk)
    dut.init_i.value = 0
    outputs = []
    counter= 0
    invalid = 0
    segment = 0
    segment_limit = segments[segment]

    while(1):
        if invalid == 10:
            break
        if counter == test_sample-1:
           break
        if counter == test_sample-2:
            dut.gen_i.value = 0
        
        await RisingEdge(dut.clk)

        if await wait_valid_and_store(dut, counter, outputs):
            counter += 1
            if counter == segment_limit and dut.valid_o.value == 1:
                segment += 1
                if segment == len(segments):
                    break
                segment_limit += segments[segment]

                if segment == 2 or segment == 4:
                    dut.gen_i.value = 0
                    await RisingEdge(dut.clk)
                await clear_and_load_seed(dut, seeds[segment])
                if segment == 2 or segment == 4:
                    dut.gen_i.value = 1
                    await RisingEdge(dut.clk)
                    await RisingEdge(dut.clk)

        else:
            invalid += 1
        
    await ClockCycles(dut.clk,4)
    dut._log.info("Generate complete")
    dut._log.info(f"Valid outputs count: {len(outputs)}")

    dut._log.info("Comparing test to model")
    matching = 0

    #convert the seeds to a lists of bits
    models = [seed_to_model(s) for s in seeds]
    model_outputs = prep_out(sum([m.generate(n) for m, n in zip(models, segments)],[]),64)

    for i in range(len(outputs)):
        if outputs[i] != hex_to_signed(model_outputs[i]):
            dut._log.error(f"Mismatch at step {i}: test={outputs[i]}, model={hex_to_signed(model_outputs[i])}")
        else:
            dut._log.info(f"Match at step {i}: test={outputs[i]}, model={hex_to_signed(model_outputs[i])}")
            matching = matching + 1
    dut._log.info("Comparison complete")
    dut._log.info(f"Matching outputs: {matching}")
    if matching == len(outputs):
        dut._log.info("========== ALL TESTS PASSED ==========")
    else:
        dut._log.error("========== TESTS FAILED ==========")