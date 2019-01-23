#include <stdint.h>

volatile uint64_t tohost    __attribute__((section(".htif.tohost")));
volatile uint64_t fromhost  __attribute__((section(".htif.fromhost")));
