#include "test_infrastructure.S"

.section .infra.entry

.global entry
entry:

/* Clear a0 */
li a0, 0

/* Call into design under test */
call dut_entry

/* Read test result */
beq a0, zero, .test_failed
j .test_passed

/* Routine for printing characters to the console over HTIF
.putchar:
...TODO

/* If the test reports as failed, print "FAIL" in the console */
.test_failed:
/* Print "FAIL" */
TODO
j .halt

/* If the test reports as passed, print "PASS" in the console */
.test_passed:
/* Print "PASS" */
TODO
j .halt

/* Halt */
.halt:
  j .halt /* spin forever, for now */
