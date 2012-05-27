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
    text css('dcpu')

    body ->
      div class: 'navbar navbar-fixed-top', ->
        div class: 'navbar-inner', ->
          div class: 'container', ->
            span class: 'brand', href: '#', 'DCPU-16'
            ul class: 'nav', ->
              li class: 'active', -> a href: '#', -> span 'Home'

      div id: 'content', class: 'container', ->
        div class: 'row', ->
          div class: 'span6', ->
            pre id: 'code', class: 'prettyprint linenums lang-dasm', -> '''
              :main
                jsr init_screen
                jsr setup_tick
                jsr print_all
                set pc, halt
            
              :print_all
                set a, msg
                set b, 0
                jsr print
                set a, msg
                set b, 1
                jsr print
                set pc, pop
            
              :setup_tick
                ias change_border
                set a, 2
                set b, 1
                hwi 0
                set a, 0
                set b, 60
                hwi 0
                set pc, pop

              :halt set pc, halt
              
              :init_screen
                set a, 0
                set b, screen
                hwi 1
                set pc, pop
              
              :change_border
                set a, 3
                set b, [border]
                add [border], 1
                hwi 1
                rfi 0

              ; A is addr, B is blink
              :print
                set i, a
                set c, b
                set j, [print_buf]
                :loop
                  set b, [i]
                  bor b, 0xf000
                  ifn c, 0
                    bor b, 0x0080
                  sti [j], b
                  ifn [i], 0
                    set pc, loop
                sub j, screen
                add j, 31
                and j, 0xffc0
                ;div j, 32
                ;mul j, 32
                add j, screen
                set [print_buf], j
                set pc, pop
              
              :border dat 0

              :print_hex
                set pc, pop

              :msg dat "w00t here's a test message! and stuuuuf", 0
              :print_buf dat screen
              :screen
            '''

          div class: 'span6', ->
            div class: 'btn-group', ->
              button id: 'run_pause', class: 'btn btn-primary run', ->
                i id: 'run-icon', class: 'icon-play icon-white'
                i id: 'pause-icon', class: 'icon-pause icon-white hidden'
                text ' Run'
              button id: 'step', class: 'btn', ->
                i class: 'icon-arrow-right'
                text ' Step'
              button id: 'over', class: 'btn', ->
                i class: 'icon-share-alt'
                text ' Over'
              button id: 'reset', class: 'btn btn-warning', ->
                i class: 'icon-refresh icon-white'
                text ' Reset'
            
            div class: 'monitor', ->
              canvas width: '384', height: '288', class: 'lem'

            div class: 'btn-group', ->
              button id: 'on-fire', class: 'btn btn-danger', style: 'display: none', ->
                i class: 'icon-fire icon-white'
                text ' DCPU ON FIRE '
                i class: 'icon-fire icon-white'

            # div class: 'btn-group', ->
            #   button id: 'clock-tick', class: 'btn btn-info', style: 'display: none', ->
            #     i class: 'icon-time icon-white'
            
            register_bank = (registers...) ->
              div class: 'row-fluid', ->
                for register in registers
                  div class: 'span1 reg-name', register
                  div class: "span1 reg-val", data: {register}, '0000'
              
            div class: 'registers', ->
              register_bank 'PC', 'A', 'X', 'I'
              register_bank 'SP', 'B', 'Y', 'J'
              register_bank 'EX', 'C', 'Z', 'IA'
            
            div class: 'row', ->
              span class: 'span1', 'Cycles'
              span class: 'span1 total-cycles', '0'


      script src: '/javascripts/vendor/jquery.min.js'
      script src: '/javascripts/vendor/prettify.js'
      script src: '/javascripts/vendor/require.min.js'
      script src: '/bootstrap/js/bootstrap.min.js'
      
      text js('client')
      text js('lang-dasm')
      
      script '$(function() { prettyPrint(); kick_off(); });'
