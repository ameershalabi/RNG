# Makefile for cocotb

TOPLEVEL_LANG = vhdl
VHDL_SOURCES = $(PWD)/casr_150.vhd

TOPLEVEL = casr_150
COCOTB_TEST_MODULES = mytest150

# Use GHDL or ModelSim/Questa
SIM = ghdl

# Generics (compile-time parameters)
# Note: o_bit_g and o_mode_g use defaults from VHDL ('0' and '0')
# GHDL has issues with std_logic generics on command line
SIM_ARGS += -gw_casr_g=256
SIM_ARGS += --vcd=sim.vcd
include $(shell cocotb-config --makefiles)/Makefile.sim
