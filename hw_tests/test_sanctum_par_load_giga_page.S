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

  /* Set up a trap vector */
  la t0, .default_trap_vector
  csrw mtvec, t0

  la t0, _illegal_address_giga
  csrw 0x07C5, t0 # Set mparbase
  li t0, 0xF0000000
  csrw 0x07C6, t0 # Set mparmask

  /* Activate Address Translation */
  /** Set satp mode to Sv39 and set the root page table address **/ 
  # SATP_MODE: 0xFF00000000000000
  li t0, 0x8000000000000000 # Mode Sv39 is value 8
  la t2, root_page_table
  srl t2, t2, 0xC # Physical Address divided by 4KiB
  or t0, t0, t2 
  csrw satp, t0

  /* Switch to S-mode, jump to the protected range */
  /** Set mPP to 1 (S-mode), sIE to 1, mPIE to 0 and TVM to 1 **/
  csrr t0, mstatus
  # MSTATUS_TVM:  0x00100000
  # MSTATUS_MPP:  0x00001800
  # MSTATUS_mPIE: 0x00000080
  # MSTATUS_SIE:  0x00000002
  li t1, 0xFFFFFFFFFFEFE77D
  li t2, 0x00100802
  and t0, t0, t1
  or t0, t0, t2
  csrw mstatus, t0

  /* Set return address to malicious program mret to S-mode */
  la t0, .malicious_program
  csrw mepc, t0
  mret
 
.malicious_program: /* Tries to read at the limit of the protected range and then inside */
  la t0, _illegal_address_giga
  li t1, 0x40000000
  add t0, t0, t1
  lw zero, 0(t0)
  la t0, _illegal_address_giga
  lw zero, -4(t0)
.illegal_load: // Read the first address of the illegal Giga page
  lw zero, 0(t0)

  j .test_failure

.default_trap_vector:
  csrr t0, mcause // Check this is a Load Page Fault
  li t1, 0xD
  bne t0, t1, .test_failure

  csrr t0, mepc   // That happend during the illegal load
  la t1, .illegal_load
  bne t0, t1, .test_failure

  csrr t0, mtval  // On the illegal address
  la t1, _illegal_address_giga
  bne t0, t1, .test_failure

  li a0, 1 // The test is successful
  jr ra

.test_failure:
  li a0, 0 // Fail this test!
  jr ra /* return to  caller */
