OUTPUT_ARCH( "riscv" )
ENTRY( entry )

SECTIONS
{
  . = 0x80000000;
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
    *(.got)
    *(.got.plt)
  }

  
  . = 0x80004000;
  .page_table ALIGN(0x1000) : {
    *(.page_table)
  }
}
