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

  /* Define the enclave-private memory as two Gigas of DRAM */ 
  li t0, 0x00000000 # Set mevbase
  csrw 0x07C0, t0
  li t0, 0xFFFFFFFE00000000
  csrw 0x07C1, t0 # Set mevmask
  
  /* Initialize meparbase and meparmask */
  li t0, 0xFFFFFFFFFFFFFFFF
  csrw 0x07C7, t0 # Set meparbase
  li t0, 0x0000000000000000
  csrw 0x07C8, t0 # Set meparmask
  
  /* Set MEMRBM */
  la t1, _illegal_address_giga # Compute illegal memory region corresponding to the address
  srli t1, t1, 25
  andi t1, t1, 0x3F
  li t0, 1
  sll t0, t0, t1
  not t0, t0 # Compute corresponding bitmap
  csrw 0x7C4, t0 # Set memrbm

  /* Activate Address Translation */
  /** Set satp mode to Sv39 **/  
  # SATP_MODE: 0xFF00000000000000
  li t0, 0x8000000000000000 # Mode Sv39 is value 8
  csrw satp, t0
  
  /** Set the root page table address for enclave page walk **/
  la t0, root_page_table
  srl t0, t0, 0xC # Physical Address divided by 4KiB
  csrw 0x07C2, t0 # Set meatp

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
  la t0, _illegal_address_giga // Read the last address before the illegal memory region
  lw zero, -4(t0)
  la t0, _illegal_address_giga // Read on next memory region
.illegal_load: // Read the first address of the illegal memory region
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
