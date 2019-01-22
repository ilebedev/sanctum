
# Read the path to this makefile
SANCTUM_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
BUILD_DIR := $(SANCTUM_DIR)/build
SCRIPTS_DIR := $(SANCTUM_DIR)/scripts

# High-level targets
.PHONY: clean
clean:
	rm -rf build

.PHONY: test
test:
	@echo $(mkfile_path)

.PHONY: qemu
qemu:
	cd $(SANCTUM_DIR)/tools/qemu && git submodule update --init --recursive
	cd $(SANCTUM_DIR)/tools/qemu && git apply $(SCRIPTS_DIR)/qemu.patch
	mkdir -p $(BUILD_DIR)/qemu
	cd $(BUILD_DIR)/qemu && $(SANCTUM_DIR)/tools/qemu/configure --target-list=riscv64-softmmu
	cd $(BUILD_DIR)/qemu && make
