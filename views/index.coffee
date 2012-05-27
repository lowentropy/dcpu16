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
            div id: 'alerts', class: 'offset2 span6'

      div id: 'content', class: 'container', ->
      #   div class: 'row', ->
      #     div id: 'alerts', class: 'span6 offset3'

        div class: 'row', ->
          div class: 'span6', ->
            div class: 'btn-group', ->
              
              button(
                class: 'btn span3 dropdown-toggle file-chooser',
                data: {toggle: 'dropdown'}, ->
                  span class: 'chosen-file pull-left', "Choose a file..."
                  span class: 'caret pull-right')
                    
              ul id: 'file-choices', class: 'dropdown-menu', ->
                for name, content of @files
                  li -> a href: '#', name

            pre id: 'code', class: 'code prettyprint linenums lang-dasm'

          div class: 'span6', ->
            
            div class: 'btn-toolbar', ->            
              
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
            
              div class: 'btn-group', ->
                button id: 'on-fire', class: 'btn btn-danger', style: 'display: none', ->
                  i class: 'icon-fire icon-white'
                  text ' DCPU ON FIRE '
                  i class: 'icon-fire icon-white'

              div class: 'btn-group', ->
                button id: 'clock-tick', class: 'btn btn-info', style: 'display: none', ->
                  i class: 'icon-time icon-white'
            
            div class: 'monitor', ->
              canvas width: '384', height: '288', class: 'lem'

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
      
      script id: 'files', type: 'template/json', ->
        text JSON.stringify(@files)

      script src: '/javascripts/vendor/jquery.min.js'
      script src: '/javascripts/vendor/prettify.js'
      script src: '/javascripts/vendor/require.min.js'
      script src: '/bootstrap/js/bootstrap.min.js'
      script src: '/socket.io/socket.io.js'
      
      text js('client')
      text js('lang-dasm')
      
      script '$(function() { kick_off(); });'
      