doctype 5
html lang: 'en', ->

  head ->
    meta charset: 'utf-8'
    meta name: 'viewport', content: 'width=device-width, initial-scale=1.0'
    title 'DCPU-16 Testbed'
    
    link rel: 'shortcut icon', href: '/images/favicon.ico'

    link rel: 'stylesheet', href: '/bootstrap/css/bootstrap.css'
    style 'body { padding-top: 60px; }'
    link rel: 'stylesheet', href: '/bootstrap/css/bootstrap-responsive.css'
    
    text css('prettify')
    text css('lem')

    body ->
      div class: 'navbar navbar-fixed-top', ->
        div class: 'navbar-inner', ->
          div class: 'container', ->
            span class: 'brand', href: '#', 'DCPU-16'
            span class: 'pull-right', 'Ignore me...'
            ul class: 'nav', ->
              li class: 'active', -> a href: '#', -> span 'Home'

      div id: 'content', class: 'container', ->
        div class: 'row', ->
          div class: 'span6', ->
            h1 'Code goes here'
            p "Here's an inline <code>code</code> snippet."
            pre class: 'prettyprint linenums lang-dasm', -> '''
              set pc, main

              ; active memory
              :screen_ptr    dat screen_buffer
              :line_buf_ptr  dat line_buffer

              ; miscellaneous constants
              :num_devices   dat 2
              :timer_ms      dat 1000

              ; constants identifying the hardware ids, messages, and indices of known devices
              :hardware_start

              :keyboard_index    dat 0xFFFF
              :keyboard_message  dat 1
              :keybaord_msg_cmd  dat 3
              :keyboard_hwid     dat 0x30CF, 0x7406

              :clock_index       dat 0xFFFF
              :clock_message     dat 2
              :clock_msg_cmd     dat 2
              :clock_hwid        dat 0x12D0, 0xB402

              :screen_index      dat 0xFFFF
              :screen_message    dat 0
              :screen_msg_cmd    dat 0
              :screen_hwid       dat 0x7349, 0xF615

              :hardware_end



              ; start of main program
              :main
                jsr discover_hardware
                ;jsr report_hardware
                jsr program_hardware
                ias interrupt
                set a, [timer_ms]
                jsr set_timer
                jsr setup_screen
                set pc, stall
                ;set pc, halt

              ; assign messages to hardware for interrupts
              :program_hardware
                set j, hardware_start
                :ph_loop
                  ife [j], 0xFFFF      ; abort if hw not attached
                    set pc, ph_loop_end
                  ife [2+j], 0         ; abort if hw doesn't need programming
                    set pc, ph_loop_end
                  set a, [2+j]         ; set interrupt programming command
                  set b, [1+j]         ; set interrupt message to program
                  hwi [j]              ; program hardware with message
                  :ph_loop_end
                    add j, 5           ; move to next hardware
                    ifl j, hardware_end
                      set pc, ph_loop  ; stop at end of hardware list
                set pc, pop

              ; route an interrupt
              :interrupt
                ife a, [keyboard_message]
                  set pc, keyboard_interrupt
                ife a, [clock_message]
                  set pc, clock_interrupt
                set pc, unknown_interrupt

              ; handle keyboard input
              :keyboard_interrupt
                set A, 1                    ; get next key from keyboard
                hwi [keyboard_index]        
                ife C, 0                    ; abort if no key pressed
                  rfi 0                     
                jsr keypress                ; determine if we should append to buffer
                ifn B, 0                    
                  jsr append_line_buffer    ; and then do so.
                ife C, 0x11                 ; if enter was pressed
                  jsr handle_enter          ; call another handler
                set pc, keyboard_interrupt  ; keep checking for pressed keys

              ; handle keypress; C is character; return: B is whether to append it to buffer
              :keypress
                ; TODO: determine if its a key that makes sense to record
              ;   print C
                set B, 1
                set PC, pop

              ; append the pressed char to the line buffer
              :append_line_buffer
                set A, [line_buf_ptr]     ; find end of current line
                ife A, line_buffer_end    ; abort if out of buffer space
                  set PC, pop
                set [A], C                ; record the character
                set [1+A], 0              ; and a terminating zero
                add [line_buf_ptr], 1     ; increment the buffer pointer
                set PC, pop

              ; the <enter> key was pressed, so do a thing
              :handle_enter
                ; if the user enters 'quit', then quit...
                set a, line_buffer        ; start at head of buffer
                ife [0+a], 0x71           ; q
                ife [1+a], 0x75           ; u
                ife [2+a], 0x69           ; i
                ife [3+a], 0x74           ; t
                set pc, halt              ; if string matched, halt immediately
                jsr clear_line_buffer     ; otherwise just clear the line buffer
                set pc, pop

              ; clear the line buffer
              :clear_line_buffer
                set [line_buf_ptr], line_buffer  ; reset pointer to head of buffer
                set [line_buffer], 0             ; and put the terminating zero there
                set pc, pop

              ; handle a clock interrupt
              :clock_interrupt
                ; NOTE: you can do stuff here. on a timer!
                rfi 0

              ; we have no idea what this interrupt is
              :unknown_interrupt
                ; TODO
                rfi 0

              ; set the clock; A contains pause in milliseconds
              :set_timer
                set b, a           ; clock will interrupt 60/B times per second,
                mul b, 60          ; so we want to pass (ms * 60 / 1000) to get
                div b, 1000        ; a correct interval in ms. NOTE that if ms was
                set a, 0           ; less than 17, this will disable the clock.
                hwi [clock_index]
                set pc, pop

              ; map the screen buffer memory
              :setup_screen
                set a, 0
                set b, screen_buffer
                hwi [screen_index]
                set pc, pop

              ; report on hardware indices!
              :report_hardware
                print [keyboard_index]
                print [clock_index]
                set pc, pop

              ; fill out the hardware indices
              :discover_hardware
                hwn i                     ; how many devices are there?
                :dh_loop
                  sub i, 1                ; starting at device N-1
                  hwq i                   ; get the device info
                  jsr search_for_device   ; then match it to known hardware
                  ifn i, 0                ; loop until done
                    set pc, dh_loop
                set pc, pop

              ; find out what device we have
              :search_for_device
                set j, hardware_start     ; start at first known device
                :sfd_loop
                  ife b, [3+j]            ; if hardware id matches, then
                    ife a, [4+j]          ; assign this device
                      set pc, sfd_assign
                  add j, 5                ; otherwise continue to next hardware entry
                  ifl j, hardware_end
                    set pc, sfd_loop      ; abort at end of hardware list
                set pc, pop
                :sfd_assign
                  set [j], i              ; assign index to hardware list item
                  set pc, pop             ; then return from `search_for_device`

              ; jump here to hang indefinitely
              :stall set pc, stall        ; loop forever

              ; jump here to end the program
              :halt dat 0                 ; 0x0000 is 'reserved for future expansion' :P

              :line_buffer
                dat "                                "
                dat "                                "
                dat "                                "
                dat "                                "
              :line_buffer_end
                dat 0

              :screen_buffer
                dat "                                "
                dat "                                "
                dat "                                "
                dat "                                "
                dat "                                "
                dat "                                "
                dat "                                "
                dat "                                "
                dat "                                "
                dat "                                "
                dat "                                "
                dat "                                "
              :screen_buffer_end
            '''

          div class: 'span6', ->
            h1 'Output goes here'
            
            div class: 'btn-group', ->
              button class: 'btn btn-primary', ->
                i class: 'icon-play icon-white'
                text ' Run'
              button class: 'btn', ->
                i class: 'icon-arrow-right'
                text ' Step'
              button class: 'btn', ->
                i class: 'icon-share-alt'
                text ' Over'
              button class: 'btn btn-warning', ->
                i class: 'icon-refresh icon-white'
                text ' Reset'
                
            div class: 'monitor', ->
              canvas width: '384', height: '288', class: 'lem'

            h1 'Debugging goes here'

      script src: '/javascripts/vendor/jquery.min.js'
      script src: '/javascripts/vendor/prettify.js'
      script src: '/javascripts/vendor/require.min.js'
      script src: '/bootstrap/js/bootstrap.min.js'
      
      text js('client')
      text js('lang-dasm')
      
      script '$(function() { prettyPrint(); });'
