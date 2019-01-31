#include "infrastructure.S"

.section .text

.global dut_entry
dut_entry:
  /* INPUT:
    $ra contains return address for this test; do not clobber it */

  /* OUTPUT:
    $a0 should contain:
    0 if the test FAILS
    1 if the test PASSES */

  /* Set up the stack so ra can be saved */ 
  la sp, stack_ptr
  sw ra, 1(sp)

  /* Set up a trap vector */
  la t0, .default_trap_vector
  csrw mtvec, t0

  /* Set up protected address range (boot_keys region)*/
  li t0, 0x80001000
  csrw 0X07C5, t0 # Set mparbase
  li t0, 0xFFFFF000
  csrw 0x07C8, t0 # Set mparmask

  /* Switch to S-mode, jump to the protected range */
  /** Set mPP to 1 (S-mode) **/
  csrr t0, mstatus
  # MSTATUS_MPP: 0x00001800
  li t1, 0xFFFFFFFFFFFFE7FF
  li t2, 0x0800
  and t0, t0, t1
  or t0, t0, t2
  csrw mstatus, t0

  /* Set return address to malicious program mret to S-mode */
  la ra, .malicious_program
  mret
  
.malicious_program: /* Tries to read in the protected range */
  li t0, 0x80001000
  lw t0, 0(t0)
 
  /* The following should never execute */
  li a0, 0 // Fail this test!
  j .return_caller /* return to caller */

.default_trap_vector:
  csrr t0, mcause
  li a0, 1 // The trap was triggered and the test is successful

.return_caller:
  lw ra, 1(sp)
  jr ra 
