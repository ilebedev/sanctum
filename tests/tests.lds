OUTPUT_ARCH( "riscv" )
ENTRY( entry )

SECTIONS
{
  . = 0x80000000;
  .infra : {
    *(.infra.entry)
    *(.infra)
    *(.infra.*)
  }



  /* Reserve some space for M-mode stacks (handled by ROT) */
  .htif ALIGN(0x1000) (NOLOAD) : {
    *(.htif.fromhost)
    *(.htif.tohost)
  }
