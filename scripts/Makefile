
# TODO: include a makefile constants file

# Read the path to this makefile
remove_trailing_slash = $(if $(filter %/,$(1)),$(call remove_trailing_slash,$(patsubst %/,%,$(1))),$(1))
SANCTUM_DIR := $(call remove_trailing_slash, $(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
BUILD_DIR := $(SANCTUM_DIR)/build
SCRIPTS_DIR := $(SANCTUM_DIR)/scripts
COMMON_DIR := $(SANCTUM_DIR)/common

# TODO: create targets to make patch operations indempotent

# Top-level targets
# -----------------
.PHONY: all clean-all clean test

all: test

test: hw_test

clean:
	-rm -rf $(BUILD_DIR)/secure_bootloader
	-rm -rf $(BUILD_DIR)/security_monitor
	-rm -rf $(BUILD_DIR)/tests

clean-all: clean
	-rm -rf $(BUILD_DIR)

# Generic helper targets
# ----------------------

# TODO: create *.in target - copy from SSITH

# Secure Bootloader targets
# -------------------------
# TODO: move this to respecive makefile fragments
SECURE_BOOTLOADER := $(BUILD_DIR)/secure_bootloader/secure_bootloader.bin

SECURE_BOOTLOADER_DIR := $(SANCTUM_DIR)/secure_bootloader
IDPT_DIR := $(SANCTUM_DIR)/tools/idpt
IDPT := $(TESTS_DIR)/idpt.bin

SECURE_BOOTLOADER_SRCS := \
	$(SECURE_BOOTLOADER_DIR)/src/bootloader.S \
	$(SECURE_BOOTLOADER_DIR)/src/bootloader.c \
	$(SECURE_BOOTLOADER_DIR)/src/stack.S \
	$(SECURE_BOOTLOADER_DIR)/src/boot_api.c \
	$(SECURE_BOOTLOADER_DIR)/src/boot_api.c \
	$(COMMON_DIR)/sha3/sha3.c \
	$(COMMON_DIR)/randomart/randomart.c \
	$(COMMON_DIR)/platform/sanctum.c \
	$(COMMON_DIR)/htif/htif.c \
	$(COMMON_DIR)/ed25519/fe.c \
	$(COMMON_DIR)/ed25519/ge.c \
	$(COMMON_DIR)/ed25519/keypair.c \
	$(COMMON_DIR)/ed25519/sc.c \
	$(COMMON_DIR)/ed25519/sign.c \
	$(COMMON_DIR)/clib/snprintf.c \
	$(COMMON_DIR)/clib/memset.c \
	$(COMMON_DIR)/aes/aes.c \

$(SECURE_BOOTLOADER): $(SECURE_BOOTLOADER_DIR)/src/bootloader.lds $(SECURE_BOOTLOADER_SRCS)
	# create a build directory if one does not exist
	mkdir -p $(BUILD_DIR)/secure_bootloader
	# compile the secure bootloader ELF
	cd $(BUILD_DIR)/secure_bootloader && $(CC) -T secure_bootloader.lds -march=rv64g -mabi=lp64 -nostdlib -nostartfiles -fno-common -std=gnu11 -static -fPIC -g -O0 -Wall $(SECURE_BOOTLOADER_SRCS) -o $(BUILD_DIR)/secure_bootloader/secure_bootloader.elf
	# extract a binary image from the ELF
	cd $(BUILD_DIR)/secure_bootloader && $(OBJCOPY) -O binary --only-section=rom  $(BUILD_DIR)/secure_bootloader/secure_bootloader.elf $(BUILD_DIR)/secure_bootloader/secure_bootloader.bin

.PHONY: secure_bootloader
secure_bootloader: $(SECURE_BOOTLOADER)

# Security Monitor targets
# ------------------------


# ------------------------
# ## QEMU
# TODO: move this to a makefile fragments in scripts

QEMU := $(BUILD_DIR)/qemu/riscv64-softmmu/qemu-system-riscv64

.PHONY: qemu
qemu: $(QEMU)

$(QEMU):
	cd $(SANCTUM_DIR) && git submodule update --init --recursive tools/qemu
	cd $(SANCTUM_DIR)/tools/qemu && git apply $(SCRIPTS_DIR)/qemu.patch
	mkdir -p $(BUILD_DIR)/qemu
	cd $(BUILD_DIR)/qemu && $(SANCTUM_DIR)/tools/qemu/configure --target-list=riscv64-softmmu
	cd $(BUILD_DIR)/qemu && make

# ## Build Tools: compilers, debuggers, etc.
# TODO: move this to a makefile fragments in scripts

CC := $(BUILD_DIR)/riscv-gnu-toolchain/bin/riscv64-unknown-elf-gcc
OBJCOPY= $(BUILD_DIR)/riscv-gnu-toolchain/bin/riscv64-unknown-elf-objcopy
READELF= $(BUILD_DIR)/riscv-gnu-toolchain/bin/riscv64-unknown-elf-readelf/buil
STRIP= $(BUILD_DIR)/riscv-gnu-toolchain/bin/riscv64-unknown-elf-strip

$(CC): buid-tools
$(READELF): buid-tools
$(OBJCOPY): buid-tools
$(STRIP): buid-tools

.PHONY: build-tools
build-tools:
	cd $(SANCTUM_DIR) && git submodule update --init --recursive tools/riscv-gnu-toolchain
	cd $(SANCTUM_DIR)/tools/riscv-gnu-toolchain && git apply $(SCRIPTS_DIR)/riscv-gnu-toolchain.patch
	mkdir -p $(BUILD_DIR)/riscv-gnu-toolchain
	cd $(BUILD_DIR)/riscv-gnu-toolchain && $(SANCTUM_DIR)/tools/riscv-gnu-toolchain/configure --prefix $(BUILD_DIR)/riscv-gnu-toolchain/
	cd $(BUILD_DIR)/riscv-gnu-toolchain && make

# ## Linux

# TODO: move this to a makefile fragments in scripts
# TODO: create a target for building a Linux vmimage

# Debug target to help debug errors in the Makefile
# -------------------------------------------------
debug-% :
	@echo $* = $($*)
