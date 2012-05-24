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
            ul class: 'nav', ->
              li class: 'active', -> a href: '#', -> span 'Home'

      div id: 'content', class: 'container', ->
        div class: 'row', ->
          div class: 'span6', ->
            # h1 'Code goes here'
            # p "Here's an inline <code>code</code> snippet."
            pre id: 'code', class: 'prettyprint linenums lang-dasm', -> '''
              sti a, 1
              :loop
                add j, i
                set i, a
                set a, j
                set pc, loop
            '''

          div class: 'span6', ->
            # h1 'Output goes here'
            
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

            # h1 'Debugging goes here'
            
            div class: 'btn-group', ->
              button id: 'on-fire', class: 'btn btn-danger', style: 'display: none', ->
                i class: 'icon-fire icon-white'
                text ' DCPU ON FIRE '
                i class: 'icon-fire icon-white'

            div class: 'btn-group', ->
              button id: 'clock-tick', class: 'btn btn-info', style: 'display: none', ->
                i class: 'icon-time icon-white'
                

      script src: '/javascripts/vendor/jquery.min.js'
      script src: '/javascripts/vendor/prettify.js'
      script src: '/javascripts/vendor/require.min.js'
      script src: '/bootstrap/js/bootstrap.min.js'
      
      text js('client')
      text js('lang-dasm')
      
      script '$(function() { prettyPrint(); kick_off(); });'
