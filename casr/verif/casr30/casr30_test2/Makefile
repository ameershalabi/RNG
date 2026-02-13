# Makefile for cocotb

TOPLEVEL_LANG = vhdl

# Get the directory where this Makefile is located
MAKEFILE_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
# Navigate to the casr source directory (3 levels up from test dir)
CASR_SRC_DIR := $(abspath $(MAKEFILE_DIR)/../../..)

VHDL_SOURCES = $(CASR_SRC_DIR)/casr_30.vhd

TOPLEVEL = casr_30
COCOTB_TEST_MODULES = test2

# Use GHDL or ModelSim/Questa
SIM = ghdl

# Generics (compile-time parameters)
SIM_ARGS += -gw_casr_g=64 -go_mode_g=\'1\'
SIM_ARGS += --vcd=sim.vcd
include $(shell cocotb-config --makefiles)/Makefile.sim
