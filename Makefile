
# Read the path to this makefile
remove_trailing_slash = $(if $(filter %/,$(1)),$(call remove_trailing_slash,$(patsubst %/,%,$(1))),$(1))
SANCTUM_DIR := $(call remove_trailing_slash, $(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
BUILD_DIR := $(SANCTUM_DIR)/build
SCRIPTS_DIR := $(SANCTUM_DIR)/scripts
TESTS_DIR := $(SANCTUM_DIR)/tests
IDPT_DIR := $(SANCTUM_DIR)/tools/idpt
SECURE_BOOTLOADER_DIR := $(SANCTUM_DIR)/secure_bootloader

TEST_NAMES :=  $(notdir $(basename $(wildcard $(SANCTUM_DIR)/tests/test_*)))
TEST_ELFS := $(addprefix $(BUILD_DIR)/tests/, $(addsuffix .test.elf, $(TEST_NAMES)))
TEST_TASKS := $(addsuffix .test.task, $(TEST_NAMES))
OBJECTS := $(addprefix $(BUILDDIR)/,$(SOURCES:%.c=%.o))

QEMU := $(BUILD_DIR)/qemu/riscv64-softmmu/qemu-system-riscv64
IDPT := $(TESTS_DIR)/idpt.bin
SECURE_BOOTLOADER_ELF := $(BUILD_DIR)/secure_bootloader/secure_bootloader.elf
SECURE_BOOTLOADER_BIN := $(BUILD_DIR)/secure_bootloader/secure_bootloader.bin

CC := riscv64-unknown-elf-gcc
OBJCOPY= riscv64-unknown-elf-objcopy
READELF= riscv64-unknown-elf-readelf
STRIP= riscv64-unknown-elf-strip

.PHONY: all clean test qemu tools linux

all: $(QEMU) test

# High-level targets
clean:
	rm -rf build
	rm $(IDPT)

SECURE_BOOTLOADER_SRCS := \
	$(SECURE_BOOTLOADER_DIR)/bootloader.S \
	$(SECURE_BOOTLOADER_DIR)/bootloader.c \
	$(SECURE_BOOTLOADER_DIR)/stack.S \
	$(SECURE_BOOTLOADER_DIR)/boot_api.c \
	$(SECURE_BOOTLOADER_DIR)/boot_api.c \
	$(SECURE_BOOTLOADER_DIR)/sha3/sha3.c \
	$(SECURE_BOOTLOADER_DIR)/randomart/randomart.c \
	$(SECURE_BOOTLOADER_DIR)/platform/sanctum.c \
	$(SECURE_BOOTLOADER_DIR)/htif/htif.c \
	$(SECURE_BOOTLOADER_DIR)/ed25519/fe.c \
	$(SECURE_BOOTLOADER_DIR)/ed25519/ge.c \
	$(SECURE_BOOTLOADER_DIR)/ed25519/keypair.c \
	$(SECURE_BOOTLOADER_DIR)/ed25519/sc.c \
	$(SECURE_BOOTLOADER_DIR)/ed25519/sign.c \
	$(SECURE_BOOTLOADER_DIR)/clib/snprintf.c \
	$(SECURE_BOOTLOADER_DIR)/clib/memset.c \
	$(SECURE_BOOTLOADER_DIR)/aes/aes.c \

$(SECURE_BOOTLOADER_ELF): $(SECURE_BOOTLOADER_SRCS) $(SECURE_BOOTLOADER_DIR)/secure_bootloader.lds
	# create a build directory if one does not exist
	mkdir -p $(BUILD_DIR)/secure_bootloader
	# compile the secure bootloader ELF
	cd $(SECURE_BOOTLOADER_DIR) && $(CC) -T secure_bootloader.lds -march=rv64g -mabi=lp64 -nostdlib -nostartfiles -fno-common -std=gnu11 -static -fPIC -g -O0 -Wall $(SECURE_BOOTLOADER_SRCS) -o $(SECURE_BOOTLOADER_ELF)
	# extract a binary image from the ELF

$(SECURE_BOOTLOADER_BIN): $(SECURE_BOOTLOADER_ELF)
		$(OBJCOPY) -O binary --only-section=rom $< $@

.PHONY: secure_bootloader
secure_bootloader: $(SECURE_BOOTLOADER_BIN)

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
