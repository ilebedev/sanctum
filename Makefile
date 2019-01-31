
# Read the path to this makefile
remove_trailing_slash = $(if $(filter %/,$(1)),$(call remove_trailing_slash,$(patsubst %/,%,$(1))),$(1))
SANCTUM_DIR := $(call remove_trailing_slash, $(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
BUILD_DIR := $(SANCTUM_DIR)/build
SCRIPTS_DIR := $(SANCTUM_DIR)/scripts

TEST_NAMES :=  $(notdir $(basename $(wildcard $(SANCTUM_DIR)/tests/test_*)))
TEST_ELFS := $(addprefix $(BUILD_DIR)/tests/, $(addsuffix .test.elf, $(TEST_NAMES)))
TEST_TASKS := $(addsuffix .test.task, $(TEST_NAMES))
OBJECTS := $(addprefix $(BUILDDIR)/,$(SOURCES:%.c=%.o))

QEMU := $(BUILD_DIR)/qemu/riscv64-softmmu/qemu-system-riscv64
CC := riscv64-unknown-elf-gcc

.PHONY: all clean test qemu tools linux

# High-level targets
clean:
	rm -rf build

test: $(QEMU) $(TEST_TASKS)
	@echo "All the test cases in $(SANCTUM_DIR)/test have been run."

.PHONY: %.test.task
%.test.task: $(QEMU)
	mkdir -p $(BUILD_DIR)/tests
	cd $(SANCTUM_DIR)/tests && $(CC) -T infrastructure.lds -march=rv64g -mabi=lp64 -nostdlib -nostartfiles -fno-common -std=gnu11 -static -fPIC -Wall infrastructure.c $*.S -o $(BUILD_DIR)/tests/$*.elf

.PHONY: qemu
qemu: $(QEMU)

$(BUILD_DIR)/qemu/riscv64-softmmu/qemu-system-riscv64:
	cd $(SANCTUM_DIR) && git submodule update --init --recursive tools/qemu
	cd $(SANCTUM_DIR)/tools/qemu && git apply $(SCRIPTS_DIR)/qemu.patch
	mkdir -p $(BUILD_DIR)/qemu
	cd $(BUILD_DIR)/qemu && $(SANCTUM_DIR)/tools/qemu/configure --target-list=riscv64-softmmu
	cd $(BUILD_DIR)/qemu && make
