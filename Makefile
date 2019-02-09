
# Read the path to this makefile
remove_trailing_slash = $(if $(filter %/,$(1)),$(call remove_trailing_slash,$(patsubst %/,%,$(1))),$(1))
SANCTUM_DIR := $(call remove_trailing_slash, $(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
BUILD_DIR := $(SANCTUM_DIR)/build
SCRIPTS_DIR := $(SANCTUM_DIR)/scripts
TESTS_DIR := $(SANCTUM_DIR)/tests
IDPT_DIR := $(SANCTUM_DIR)/tools/idpt

TEST_NAMES :=  $(notdir $(basename $(wildcard $(SANCTUM_DIR)/tests/test_*)))
TEST_ELFS := $(addprefix $(BUILD_DIR)/tests/, $(addsuffix .test.elf, $(TEST_NAMES)))
TEST_TASKS := $(addsuffix .test.task, $(TEST_NAMES))
OBJECTS := $(addprefix $(BUILDDIR)/,$(SOURCES:%.c=%.o))

QEMU := $(BUILD_DIR)/qemu/riscv64-softmmu/qemu-system-riscv64
IDPT := $(TESTS_DIR)/idpt.bin

CC := riscv64-unknown-elf-gcc

.PHONY: all clean test qemu tools linux

all: $(QEMU) test

# High-level targets
clean:
	rm -rf build
	rm $(IDPT)

.PHONY: idpt
idpt: $(IDPT)

$(IDPT): $(IDPT_DIR)/idpt.py
	cd $(TESTS_DIR) && python $(IDPT_DIR)/idpt.py

.PHONY: test
test: $(QEMU) $(IDPT) $(TEST_TASKS)
	@echo "All the test cases in $(SANCTUM_DIR)/test have been run."
	@echo "The tests were: $(TEST_NAMES)"

.PHONY: %.test.task
%.test.task: $(QEMU)
	mkdir -p $(BUILD_DIR)/tests
	cd $(TESTS_DIR) && $(CC) -T infrastructure.lds -march=rv64g -mabi=lp64 -nostdlib -nostartfiles -fno-common -std=gnu11 -static -fPIC -g -O0 -Wall infrastructure.c $*.S -o $(BUILD_DIR)/tests/$*.elf
	- cd $(BUILD_DIR)/tests && $(QEMU) -machine sanctum -m 2G -nographic -kernel $*.elf

.PHONY: qemu
qemu: $(QEMU)

$(QEMU):
	cd $(SANCTUM_DIR) && git submodule update --init --recursive tools/qemu
	cd $(SANCTUM_DIR)/tools/qemu && git apply $(SCRIPTS_DIR)/qemu.patch
	mkdir -p $(BUILD_DIR)/qemu
	cd $(BUILD_DIR)/qemu && $(SANCTUM_DIR)/tools/qemu/configure --target-list=riscv64-softmmu
	cd $(BUILD_DIR)/qemu && make
