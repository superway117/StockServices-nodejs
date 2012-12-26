journey = require('journey')
RequestHandler = require('./RequestHandler').RequestHandler

class Router
    @init: ->
        @jRouter or= new(journey.Router)

        @jRouter.map =>
            for handle in RequestHandler.getHandlers()
                method = handle.method or "get"
                console?.log(handle)
                @jRouter[method](handle.category).bind(handle.route)

    @handle: (request, body, callback) ->
        @jRouter.handle(request, body, callback)


exports.Router = Router