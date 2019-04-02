
# TODO: include a makefile constants file

# Read the path to this makefile
remove_trailing_slash = $(if $(filter %/,$(1)),$(call remove_trailing_slash,$(patsubst %/,%,$(1))),$(1))
SANCTUM_DIR := $(call remove_trailing_slash, $(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
BUILD_DIR := $(SANCTUM_DIR)/build
SCRIPTS_DIR := $(SANCTUM_DIR)/scripts
COMMON_DIR := $(SANCTUM_DIR)/common

# Dependencies
# ------------
include $(SCRIPTS_DIR)/qemu.Makefrag
include $(SCRIPTS_DIR)/riscv-gnu-toolchain.Makefrag
#TODO: add linux here

# Project targets
# -----------------
include $(SANCTUM_DIR)/secure_bootloader/secure_bootloader.Makefrag
#include $(SANCTUM_DIR)/security_monitor/security_monitor.Makefrag
include $(SANCTUM_DIR)/hw_tests/hw_tests.Makefrag

# Top-level targets
# -----------------
.PHONY: all test clean clean-all

all: $(QEMU) test

test: hw_test

clean:
	-rm -rf $(BUILD_DIR)/secure_bootloader
	-rm -rf $(BUILD_DIR)/security_monitor
	-rm -rf $(BUILD_DIR)/hw_tests

clean-all:
	-rm -rf $(BUILD_DIR)

# Generic helper targets
# ----------------------

# TODO: create *.in target - copy from SSITH

#????
#??? Import .h file in a Makefile ??
#??? Or create *h.in ?
#?????

# Debug target to help debug errors in the Makefile
# -------------------------------------------------
debug-% :
	@echo $* = $($*)
