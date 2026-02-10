# Makefile for cocotb

TOPLEVEL_LANG = vhdl

# Get the directory where this Makefile is located
MAKEFILE_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
# Navigate to the casr source directory (3 levels up from test dir)
CASR_SRC_DIR := $(abspath $(MAKEFILE_DIR)/../../..)

VHDL_SOURCES = $(CASR_SRC_DIR)/casr_30.vhd

TOPLEVEL = casr_30
COCOTB_TEST_MODULES = test1

# Use GHDL or ModelSim/Questa
SIM = ghdl

# Generics (compile-time parameters)
# Note: o_bit_g and o_mode_g use defaults from VHDL ('0' and '0')
# GHDL has issues with std_logic generics on command line
SIM_ARGS += -gw_casr_g=64
SIM_ARGS += --vcd=sim.vcd
include $(shell cocotb-config --makefiles)/Makefile.sim
