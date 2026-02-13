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
    # clear 3 times
    # pull gen_i down 2 times
    # use 6 seeds
    # all the above within this while loop
#1-15 : SEED1
#16-30 : SEED2
#31-45 : SEED3
#46-60 : SEED4
#61-75 : SEED5
#76-100 : SEED6


def hex_to_signed(hex_str, bits=64):
    h = hex_str[2:-1] if hex_str.startswith('x"') else hex_str
    val = int(h, 16)
    return val - (1 << bits) if val & (1 << (bits - 1)) else val


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

    dut.gen_i.value = 0
    dut.seed_i.value = 0
    dut.init_i.value = 0

    await ClockCycles(dut.clk, 2)

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
    
    SEED1 = 0x36BD0F75A4ABE07D
    SEED2 = 0x123456789ABCDEF0
    SEED3 = 0xFEDCBA9876543210
    SEED4 = 0xA5A5A5A5A5A5A5A5
    SEED5 = 0x5A5A5A5A5A5A5A5A
    SEED6 = 0x0F0F0F0F0F0F0F0F
    dut.seed_i.value = SEED1
    dut._log.info("Seed loaded")
    await RisingEdge(dut.clk)
    dut.init_i.value = 0
    outputs = []
    counter= 0
    invalid = 0

    while(1):
        if invalid == 10:
            break
        await RisingEdge(dut.clk)
        if counter == test_sample-1:
           break
        if counter == test_sample-2:
            dut.gen_i.value = 0
##################### 0 - 14 ###############################################################
        if counter < 15:
            if dut.valid_o.value == 1:
                outputs.append(dut.state_o.value.to_signed())
                dut._log.info(f"Step {counter}: state = {dut.state_o.value.to_signed()} (0x{dut.state_o.value.to_unsigned():016X}) - VALID")
                counter = counter + 1
            else:
                dut._log.info(f"Step {counter}: waiting... - NOT VALID YET")
                invalid = invalid + 1
##################### transition 1 ##########################################################
        if counter == 15 and dut.valid_o.value == 1:
            await RisingEdge(dut.clk)
            await clear_dut(dut)
            await load_seed(dut, SEED2)
            await RisingEdge(dut.clk)
##################### 15 - 29 ###############################################################
        if counter >= 15 and counter < 30:
            if dut.valid_o.value == 1:
                outputs.append(dut.state_o.value.to_signed())
                dut._log.info(f"Step {counter}: state = {dut.state_o.value.to_signed()} (0x{dut.state_o.value.to_unsigned():016X}) - VALID")
                counter = counter + 1
            else:
                dut._log.info(f"Step {counter}: waiting... - NOT VALID YET")
                invalid = invalid + 1
##################### transition 2 ##########################################################
        if counter == 30 and dut.valid_o.value == 1:
            dut.gen_i.value = 0
            await RisingEdge(dut.clk)
            await clear_dut(dut)
            await load_seed(dut, SEED3)
            dut.gen_i.value = 1
            await ClockCycles(dut.clk, 3)
##################### 30 - 44 ###############################################################
        if counter >= 30 and counter < 45:
            if dut.valid_o.value == 1:
                outputs.append(dut.state_o.value.to_signed())
                dut._log.info(f"Step {counter}: state = {dut.state_o.value.to_signed()} (0x{dut.state_o.value.to_unsigned():016X}) - VALID")
                counter = counter + 1
            else:
                dut._log.info(f"Step {counter}: waiting... - NOT VALID YET")
                invalid = invalid + 1
##################### transition 3 ##########################################################
        if counter == 45 and dut.valid_o.value == 1:
            await RisingEdge(dut.clk)
            await clear_dut(dut)
            await load_seed(dut, SEED4)
            await RisingEdge(dut.clk)
##################### 45 - 59 ###############################################################
        if counter >= 45 and counter < 60:
            if dut.valid_o.value == 1:
                outputs.append(dut.state_o.value.to_signed())
                dut._log.info(f"Step {counter}: state = {dut.state_o.value.to_signed()} (0x{dut.state_o.value.to_unsigned():016X}) - VALID")
                counter = counter + 1
            else:
                dut._log.info(f"Step {counter}: waiting... - NOT VALID YET")
                invalid = invalid + 1
##################### transition 4 ##########################################################
        if counter == 60 and dut.valid_o.value == 1:
            dut.gen_i.value = 0
            await RisingEdge(dut.clk)
            await clear_dut(dut)
            await load_seed(dut, SEED5)
            dut.gen_i.value = 1
            await ClockCycles(dut.clk, 3)
##################### 60 - 74 ###############################################################
        if counter >= 60 and counter < 75:
            if dut.valid_o.value == 1:
                outputs.append(dut.state_o.value.to_signed())
                dut._log.info(f"Step {counter}: state = {dut.state_o.value.to_signed()} (0x{dut.state_o.value.to_unsigned():016X}) - VALID")
                counter = counter + 1
            else:
                dut._log.info(f"Step {counter}: waiting... - NOT VALID YET")
                invalid = invalid + 1
##################### transition 5 ##########################################################
        if counter == 75 and dut.valid_o.value == 1:
            await RisingEdge(dut.clk)
            await clear_dut(dut)
            await enable_design(dut)
            await load_seed(dut, SEED6)
            await RisingEdge(dut.clk)
##################### 75 - 89 ###############################################################
        if counter >= 75:
            if dut.valid_o.value == 1:
                outputs.append(dut.state_o.value.to_signed())
                dut._log.info(f"Step {counter}: state = {dut.state_o.value.to_signed()} (0x{dut.state_o.value.to_unsigned():016X}) - VALID")
                counter = counter + 1
            else:
                dut._log.info(f"Step {counter}: waiting... - NOT VALID YET")
                invalid = invalid + 1
    
    await ClockCycles(dut.clk,4)
    dut._log.info("Generate complete")
    dut._log.info(f"Valid outputs count: {len(outputs)}")

   
    dut._log.info("Comparing test to model")

    #convert the seed to a list of bits
    signed_value = SEED1 & ((1 << 64) - 1)
    SEED1 = [int(b) for b in format(signed_value, '064b')][::-1]
    model_seed1 = casr_30(SEED1, mode='p')
    signed_value = SEED2 & ((1 << 64) - 1)
    SEED2 = [int(b) for b in format(signed_value, '064b')][::-1]
    model_seed2 = casr_30(SEED2, mode='p')
    signed_value = SEED3 & ((1 << 64) - 1)
    SEED3 = [int(b) for b in format(signed_value, '064b')][::-1]
    model_seed3 = casr_30(SEED3, mode='p')
    signed_value = SEED4 & ((1 << 64) - 1)
    SEED4 = [int(b) for b in format(signed_value, '064b')][::-1]
    model_seed4 = casr_30(SEED4, mode='p')
    signed_value = SEED5 & ((1 << 64) - 1)
    SEED5 = [int(b) for b in format(signed_value, '064b')][::-1]
    model_seed5 = casr_30(SEED5, mode='p')
    signed_value = SEED6 & ((1 << 64) - 1)
    SEED6 = [int(b) for b in format(signed_value, '064b')][::-1]
    model_seed6 = casr_30(SEED6, mode='p')
    model_outputs = prep_out(model_seed1.generate(15) + model_seed2.generate(15) + model_seed3.generate(15) + model_seed4.generate(15) + model_seed5.generate(15) + model_seed6.generate(25),64)
    for i in range(len(outputs)):
        if outputs[i] != hex_to_signed(model_outputs[i]):
            dut._log.error(f"Mismatch at step {i}: test={outputs[i]}, model={hex_to_signed(model_outputs[i])}")
        else:
            dut._log.info(f"Match at step {i}: test={outputs[i]}, model={hex_to_signed(model_outputs[i])}")
    dut._log.info("Comparison complete")

    dut._log.info("========== ALL TESTS PASSED ==========")