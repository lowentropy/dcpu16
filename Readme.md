= Features To Do

* Multi-file support
  * Show *current* file, now that _require_ works
  * Make breakpoints work with multiple files
  * Post changed files to server, save to disk
* Precompiler
  * const: a label that just refers to a constant
  * os_call: trigger a named interrupt
* Meta commands
  * break: set a breakpoint on the following op on load
* Watch variables: support registers and mem, both hex and ascii
* Show changes when stepping

= OS Structures
  Constants
    num_pages = 0x100
    num_user_pages = 0xE0
    num_kernel_pages = 0x20
    page_size = 0x100
    user_mem_base_addr = 0x2000
    page_table_addr = ?
    lg_page_size = 8
  User memory (256) x 224   = 56  kw
  Kernel pages (256) x 16   = 4   kw
  Kernel code               = 2   kw
  Hardware (6 -> 8) x 64    = 1/2 kw
    hardware_id (2)
    index (1)
    message (1)
    set_message (1)
    owner (1)
  Process (13 -> 16) x 64   = 1   kw
    XYZABCIJ (8)
    PC,SP,EX (3)
    process_id (1)
    interrupt_addr (1)
  Page (1) x512             = 1/2 kw
    owner (1b)
    len (1b)
    root,0,00,01,..,1,10,11,..

= Features

* Breakpoints
* Live file sync
* LEM1802
* Working emulator
* DCPU 1.7
* Keyboard
* Clock
* Run / Step in browser
* Register bank

= Bugs

* Things that don't work in strings: , ; \"

= Fixed

* Can't step after pausing emulator in browser
* First step after pause seems to skip a line
