.option norvc
.section .text.entry

.global entry
entry:

/* Clear a0 */
li a0, 0

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

stack_base:
  .skip 128
stack_ptr:

/* Copy the page table in the dedicated region */ 

.section .text.page_table
.global root_page_table
root_page_table:
  .incbin "idpt.bin"
