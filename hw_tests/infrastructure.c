#include <stdint.h>

volatile uint64_t tohost    __attribute__((section(".htif.tohost")));
volatile uint64_t fromhost  __attribute__((section(".htif.fromhost")));

# define TOHOST_CMD(dev, cmd, payload) \
  (((uint64_t)(dev) << 56) | ((uint64_t)(cmd) << 48) | (uint64_t)(payload))

void print_char(char c) {
  // No synchronization needed, as the bootloader runs solely on core 0

  while (tohost) {
    // spin
    fromhost = 0;
  }

  tohost = TOHOST_CMD(1, 1, c); // send char
}

void print_str(char* s) {
  while (*s != 0) {
    print_char(*s++);
  }
}

void pass_test() {
  print_str("[TEST] OK\n");
  tohost = TOHOST_CMD(0, 0, 0b01); // report test done; 0 exit code
}

void fail_test() {
  print_str("[TEST] FAILED\n");
  tohost = TOHOST_CMD(0, 0, 0b11); // report test done; 1 exit code
}
