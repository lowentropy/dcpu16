doctype 5
html lang: 'en', ->

  head ->
    meta charset: 'utf-8'
    meta name: 'viewport', content: 'width=device-width, initial-scale=1.0'
    title 'DCPU-16 Testbed'
    
    link rel: 'stylesheet', href: '/bootstrap/css/bootstrap.css'
    style 'body { padding-top: 60px; }'
    link rel: 'stylesheet', href: '/bootstrap/css/bootstrap-responsive.css'
    link rel: 'shortcut icon', href: '/images/favicon.ico'

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
            pre class: 'prettyprint linenums', -> '''
              foo
              bar
              baz
            '''
          div class: 'span6', ->
            h1 'Output stuff goes here'
        div class: 'row', ->
          div class: 'span12', ->
            h1 'Debugging goes here'

      script src: '/javascripts/vendor/jquery.min.js'
      script src: '/bootstrap/js/bootstrap.min.js'
