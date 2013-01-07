http = require('http')
Router = require('./Router').Router

Server = 
    start: ->
        Router.init()
        http.createServer (request, response) ->
            body = ""
            request.addListener 'data', (chunk) -> 
                body += chunk 

            request.addListener 'end', =>
                Router.handle request, body, (result) ->
                    response.writeHead(result.status, result.headers)
                    response.end(result.body)

        .listen(8080)


exports.Server = Server