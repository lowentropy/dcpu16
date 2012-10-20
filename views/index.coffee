doctype 5
html lang: 'en', ->

  head ->

    # meta stuff
    meta charset: 'utf-8'
    meta name: 'viewport', content: 'width=device-width, initial-scale=1.0'
    title 'DCPU-16 Testbed'
    link rel: 'shortcut icon', href: '/images/favicon.ico'

    # bootstrap styles
    link rel: 'stylesheet', href: '/bootstrap/css/bootstrap.css'
    style 'body { padding-top: 60px; }'
    link rel: 'stylesheet', href: '/bootstrap/css/bootstrap-responsive.css'

    # codemirror
    link rel: 'stylesheet', href: '/stylesheets/vendor/codemirror.css'
    link rel: 'stylesheet', href: '/stylesheets/vendor/theme/ambiance.css'
    link rel: 'stylesheet', href: '/stylesheets/vendor/theme/lesser-dark.css'

    # my styles
    text css('prettify')
    text css('lem')
    text css('dcpu')

    body ->

      # title bar
      div class: 'navbar navbar-fixed-top', ->
        div class: 'navbar-inner', ->
          div class: 'container', ->
            span class: 'brand', href: '#', 'DCPU-16'
            div id: 'alerts', class: 'offset2 span6'

      div id: 'content', class: 'container', ->

        # the main row
        div class: 'row', ->

          # the editor part
          div class: 'span6', ->
            div class: 'btn-group', ->

              button class: 'btn file-chooser', ->
                span class: 'chosen-file', "Choose a file..."
              button class: 'btn dropdown-toggle', data: {toggle: 'dropdown'}, ->
                span class: 'caret'
              ul id: 'file-choices', class: 'dropdown-menu', ->
                for name, content of @files
                  li -> a href: '#', name

            form ->
              textarea id: 'code'

          # the output part
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

            # the LEM1802 output
            div id: 'lem', class: 'monitor', ->
              canvas width: '384', height: '288', class: 'lem'

            # the SPED3 output
            div id: 'sped', class: 'monitor'

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

      # store .dasm files
      script id: 'files', type: 'template/json', ->
        text JSON.stringify(@files)

      # vendor scripts
      script src: '/javascripts/vendor/underscore.min.js'
      script src: '/javascripts/vendor/jquery.min.js'
      script src: '/javascripts/vendor/require.min.js'
      script src: '/javascripts/vendor/codemirror.js'
      script src: '/javascripts/vendor/three.min.js'
      script src: '/bootstrap/js/bootstrap.min.js'
      script src: '/socket.io/socket.io.js'

      # custom scripts
      text js('client')
      text js('mode/dasm')

      # let's get this party started
      script '$(function() { kick_off(); });'

