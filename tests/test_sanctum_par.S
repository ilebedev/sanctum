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
  // TODO

  /* Set up protected address range */
  // TODO

  /* Switch to S-mode, jump to the protected range */
  // TODO
  
  /* The following should never execute */
  li a0, 0 // Fail this test!
  jr ra /* return to caller */
