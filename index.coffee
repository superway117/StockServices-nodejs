Server = require('./Server').Server
StockServices = require('./StockServices').StockServices

StockServices.init()

Server.start()
