
class RequestHandler

    @appendHandle: (handle)->
        @handlers ?= []
        @handlers.push(handle)

    @getHandlers: ->
        @handlers
 
exports.RequestHandler = RequestHandler