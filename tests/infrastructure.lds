OUTPUT_ARCH( "riscv" )
ENTRY( entry )

SECTIONS
{
  . = 0x80000000;
  /* Reserve some space for M-mode stacks (handled by ROT) */
  .htif ALIGN(0x1000) (NOLOAD) : {
    *(.htif.fromhost)
    *(.htif.tohost)
  }

  . = 0x80001000;
  .boot_keys ALIGN(0x1000) (NOLOAD) : {
    /* nothing here for this specific application */
  }

  . = 0x80002000;
  .text ALIGN(0x1000) : {
    *(.text.entry)
    *(.text)
  }
}
