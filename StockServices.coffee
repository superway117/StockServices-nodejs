
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
                result = @parseHistoryData(res,pageData)
            
        .on 'error', (e) =>
            @outputError(res,e.message)

    @parseHistoryData: (res,data)->
        result={}
        result["status"]="succ"
        result["list"]=[]
        result["count"]=0
        csv().from( data )
        .transform (data)->
            data.unshift(data.pop());
            return data;
        .on "record", (data,index)->
            if index>0
                output={}
                output["adjclose"]=data[0]
                output["date"]=data[1]
                output["open"]=data[2]
                output["high"]=data[3]
                output["low"]=data[4]
                output["close"]=data[5]
                output["volume"]=data[6]
                result.list.push(output)
        .on "end", (count)->
            result.count=count
            res.send(200, {},result)
        .on "error", (error)=>
            @outputError(res,e.message)
        


exports.StockServices = StockServices