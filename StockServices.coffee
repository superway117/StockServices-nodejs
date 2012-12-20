
http = require('http')
sys = require('sys')
csv = require('csv');
fs = require('fs');

RequestHandler = require('./RequestHandler').RequestHandler

class StockServices

    @init: ->
        RequestHandler.appendHandle({category:"/stock",route:@route})

    @route: (req, res, data) =>
        if not data.api
            @outputError(res,"wrong api")
            return 
        subroute = @handles[data.api]
        if subroute
            if @[subroute[1]](data)
                @[subroute[0]](req, res, data)
            else
                @outputError(res,"wrong parameters")
        #@[@handles[data.api]](req, res, data)

    @handles: 
        {
            gethistory: ["getHistory","checkHistoryParam"]
        }

    @outputError: (res,message)->
        result={}
        result["status"]="error"
        result["reason"]=message
        res.send(200, {}, result)

    @checkHistoryParam: (data) ->
        return false if not data.s
        return false if not (data.a and data.b and data.c)
        if(data.d)
            return false if not (data.e and data.f)
        true

    @getHistory: (req, res, data)=>
        
        console.log("------------getHistory---------------")
        console.log(data)

        if data.d
            url = "http://ichart.finance.yahoo.com/table.csv?s=#{data.s}
                    &d=#{data.d}&e=#{data.e}&f=#{data.f}&g=d
                    &a=#{data.a}&b=#{data.b}&c=#{data.c}&ignore=.csv"      
        else   
            url = "http://ichart.finance.yahoo.com/table.csv?s=#{data.s}&a=#{data.a}&b=#{data.b}&c=#{data.c}&ignore=.csv"

        http.get url,(response) =>
            pageData=""
            response.on 'data', (chunk) ->
                pageData += chunk

            response.on 'end', =>
                result = @parseHistoryData(res,data,pageData)
            
        .on 'error', (e) =>
            @outputError(res,e.message)

    @parseHistoryData: (res,data,pageData)->
        result={}
        result["status"]="succ"
        result["list"]=[]
        #result["count"]=0
        csv().from( pageData )
        .transform (line)->
            line.unshift(line.pop());
            return line;
        .on "record", (line,index)->
            if index>0
                output={}
                output["adjclose"]=line[0]
                output["date"]=line[1]
                output["open"]=line[2]
                output["high"]=line[3]
                output["low"]=line[4]
                output["close"]=line[5]
                output["volume"]=line[6]
                result.list.push(output)
        .on "end", (count)->
            res.sendJSONP(data.callback,result)
        
        .on "error", (error)=>
            @outputError(res,e.message)
        


exports.StockServices = StockServices