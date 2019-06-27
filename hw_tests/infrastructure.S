.option norvc
.section .text.entry

.global entry
entry:

/* Clear a0 */
li a0, 0

/* Initialize Sanctum CSRs */

li t0, 0
li t1, 0xFFFFFFFFFFFFFFFF

csrw 0x7c0, t1 // Write MEVBASE
csrw 0x7c1, t0 // Write MEVMASK

csrw 0x7c3, t1 // Write MMRBM

csrw 0x7c5, t1 // Write MPARBASE
csrw 0x7c6, t0 // Write MPARMASK

/* Call into design under test */
call dut_entry
la sp, stack_ptr
/* Read test result */
beq a0, zero, .test_failed
j .test_passed

/* Routine for printing characters to the console over HTIF */
.putchar:
  jr ra

/* If the test reports as failed, print "FAIL" in the console */
.test_failed:
/* Print "FAIL" */
call fail_test
j .halt

/* If the test reports as passed, print "PASS" in the console */
.test_passed:
/* Print "PASS" */
call pass_test
j .halt

/* Halt */
.halt:
  j .halt /* spin forever, for now */

  .align 4
stack_base:
  .skip 128
stack_ptr:

/* Copy the page table in the dedicated region */ 

.section .text.page_table
.global root_page_table
root_page_table:
  .incbin "idpt.bin"
