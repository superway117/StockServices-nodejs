
#http = require('http')
http = require('follow-redirects').http;
sys = require('sys')
csv = require('csv')
$ = require('jquery')
StockDict = require('./StockDict').StockDict

RequestHandler = require('./RequestHandler').RequestHandler

class StockServices

    @init: ->
        RequestHandler.appendHandle({category:"/stock",route:@route})

    @route: (req, res, params) =>
        if not params.api
            @outputError(res,params,"wrong api")
            return 
        subroute = @handles[params.api]
        
        if subroute
            if @[subroute[1]](params)
                @[subroute[0]](req, res, params)
            else
                @outputError(res,params,"wrong parameters")

    @handles: 
        {
            gethistory: ["getHistory","checkHistoryParam"]
            getlast: ["getLast","checkLastParam"]
            getquotes: ["getQuotes","checkQuotesParam"]
            getfunds: ["getFunds","checkFundsParam"]
        }

    @outputError: (res,params,message)->
        result={}
        result["status"]="error"
        result["reason"]=message
        res.sendJSONP(params.callback, result)

    @get: (res, params,url,callback)=>
        
        http.get url,(response) =>
            pageData=""
            response.on 'data', (chunk) ->
                pageData += chunk

            response.on 'end',=>
                callback(res,params,pageData)
            
        .on 'error', (e) =>
            @outputError(res,params,e.message)

    @canonicalYahoo: (stock)->
        if stock.lastIndexOf('.') is  -1
            if( stock.charAt(0) is '6')
                return stock += ".SS"
            else
                return stock += ".SZ"
        else
            stock            

    @checkHistoryParam: (params) ->
        return false if not params.s
        return false if not (params.a and params.b and params.c)
        if(params.d)
            return false if not (params.e and params.f)
        params["yahoo"] = @canonicalYahoo(params.s)
        true

    @getHistory: (req, res, params)=>
        
        console?.log("------------getHistory---------------")
        if params.d
            url = "http://ichart.finance.yahoo.com/table.csv?s=#{params.yahoo}
                    &d=#{params.d}&e=#{params.e}&f=#{params.f}&g=d
                    &a=#{params.a}&b=#{params.b}&c=#{params.c}&ignore=.csv"      
        else   
            url = "http://ichart.finance.yahoo.com/table.csv?s=#{params.yahoo}
                    &a=#{params.a}&b=#{params.b}&c=#{params.c}&ignore=.csv"
        @get(res,params,url,@parseHistoryData)

    @parseHistoryData: (res,params,pageData)->
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
            res.sendJSONP(params.callback,result)
        
        .on "error", (error)=>
            @outputError(res,params,e.message)
        
    @canonicalSina: (stock)->
        return if stock.length < 6
        id = stock[0..5]
        if stock.length is 9
            site=(stock[7..8]).toLowerCase()
            if(id  is '000001' and site is 'ss')
                return "s_sh000001"
            if(id  is '399001')
                return "s_sz399001"
        if( stock.charAt(0) is '6')
            return "sh#{id}"
        else
            return "sz#{id}"

    @canonicalGoog: (stock)->
        return if stock.length < 6
        id = stock[0..5]
        if stock.length is 9
            site=(stock[7..8]).toLowerCase()
            if(id  is '000001' and site is 'ss')
                return "SHA:#{id}"
        if( stock.charAt(0) is '6')
                return "SHA:#{id}"
        else
            return "SHE:#{id}"
        


    @checkLastParam: (params) ->
        #format "002142+601003"
        return false if not params.s
        list = params.s.split(" ")
        params["sina"] = (@canonicalSina(item) for item in list)
        true

    @getLast: (req, res, params)=>
        
        console?.log("------------getLast---------------")
        sinaurl = "http://hq.sinajs.cn/list=#{params.sina}" 

        @get(res,params,sinaurl,@parseSinaLastData)

    @parseSinaLastData: (res,params,pageData)->
        result={}
        result["status"]="succ"
        result["list"]=[]

        re = /\"(.*)\"/ig
        list = pageData.match(re)
        stockRe=/(\d{6})$/ig
        
        for item,index in list
            record={}
            
            item = item.split(",")
            origin_id = params.sina[index]
            record["id"] = origin_id.match(stockRe)[0]
            if origin_id is "s_sh000001" or origin_id is "s_sz399001"
                compose_list ={"s_sh000001":"上证指数","s_sz399001":"深成指"}
                record["name"] = compose_list[origin_id]
                record["price"] = item[1]
                record["chg"] = item[2]
                record["chgPre"] = item[3]
                record["volume"] = item[4]
                console?.log (item[5])
                record["volMoney"] = item[5]
            else
                record["name"]=StockDict[record["id"] ]
                record["open"] = item[1]
                record["preclose"] = item[2]
                record["price"] = item[3]
                record["high"] = item[4]
                record["low"] = item[5]
                record["buy1"] = item[6]
                record["sell1"] = item[7]
                record["volume"] = item[8]
                record["volMoney"] = item[9]
                record["buy1Num"] = item[10]
                #11 is buy1
                record["buy2Num"] = item[12]
                record["buy2"] = item[13]
                record["buy3Num"] = item[14]
                record["buy3"] = item[15]
                record["buy4Num"] = item[16]
                record["buy4"] = item[17]
                record["buy5Num"] = item[18]
                record["buy5"] = item[19]

                record["sell1Num"] = item[20]
                #21 is sell1
                record["sell2Num"] = item[22]
                record["sell2"] = item[23]
                record["sell3Num"] = item[24]
                record["sell3"] = item[25]
                record["sell4Num"] = item[26]
                record["sell4"] = item[27]
                record["sell5Num"] = item[28]
                record["sell5"] = item[29]

                record["date"] = item[30]
                record["time"] = item[31]
            result["list"].push(record)
        console?.log("------------parseSinaLastData---------------")
        res.sendJSONP(params.callback,result)
        
    @checkQuotesParam: (params) ->
        return false if not params.s
        list = params.s.split(" ")
        params["yahoo"] = (@canonicalYahoo(item) for item in list)
        true

    @getQuotes: (req, res, params)=>
        
        console?.log("------------getQuotes---------------")
        stocks = params.yahoo.join("+")
        url = "http://finance.yahoo.com/d/quotes.csv?s=#{stocks}&f=sd1ejkj5j6k4k5m3m4m5m6m7m8rr2" 
        
        @get(res,params,url,@parseYahooQuotesData)

    @parseYahooQuotesData: (res,params,pageData)->
        result={}
        result["status"]="succ"
        result["list"]=[]
        
        csv().from( pageData )
        .transform (line)->
            return line;
        .on "record", (line,index)->
            
            output={}
            output["id"]=line[0][0..5] #s
            output["name"]=StockDict[output["id"] ]
            output["date"]=line[1]  #d1
            output["shares"]=line[2] #e

            output["low52"]=line[3]  #j
            output["high52"]=line[4]   #k

            output["chgLow52"]=line[5]  #j5
            output["chgPreLow52"]=line[6]   #j6
            output["chgHigh52"]=line[7] #k4
            output["chgPreHigh52"]=line[8] #k5
            output["movAvg50"]=line[9] #m3
            output["movAvg200"]=line[10] #m4
            output["chgMovAvg200"]=line[11] #m5
            output["chgPreMovAvg200"]=line[12] #m6
            output["chgMovAvg50"]=line[13] #m7
            output["chgPreMovAvg50"]=line[14] #m8
            output["pe"]=line[15] #r
            output["dpe"]=line[16] #r2
            result.list.push(output)
        .on "end", (count)->
            res.sendJSONP(params.callback,result)
        
        .on "error", (error)=>
            @outputError(res,params,e.message)

    @canonicalIfeng: (stock)->
        return if stock.length < 6
        id = stock[0..5]
        if( stock.charAt(0) is '6')
            return "sh#{id}"
        else
            return "sz#{id}"

    @checkFundsParam: (params) ->
        #format "002142" or "002142.sz"
        return false if not params.s
        if(params.a)
            return false if not (params.b and params.c)
        if(params.d)
            return false if not (params.e and params.f)
        params["ifeng"] = @canonicalIfeng(params.s)
        true

    @getFunds: (req, res, params)=>
        
        console?.log("------------getFunds---------------")
        ifengurl = "http://app.finance.ifeng.com/data/stock/tab_zjlx.php?code=#{params.ifeng}" 
        if params.a
            ifengurl+="&begin_day=#{params.c}-#{params.a}-#{params.b}"
        if params.d
            ifengurl+="&end_day=#{params.f}-#{params.d}-#{params.e}"
            
        console?.log(ifengurl)
        @get(res,params,ifengurl,@parseIfengFundsData)

    @parseIfengFundsData: (res,params,pageData)=>
        result={}
        result["status"]="succ"
        result["list"]=[]
        $domData = $(pageData)
        $records=$domData.find("table.lable_tab01 tbody tr")
        
        length = $records.size()
        if length <= 2
            console.log("catch error")
            @outputError(res,params,"query length cant exceed 120 days")
            return
        for index in [1..length-2]
            $record = $($records.get(index)).find("td")
            i=0
            item={}
            item["date"]=$($record.get(i++)).text()
            item["total"]=parseFloat($($record.get(i++)).text())
            item["stotal"]=parseFloat($($record.get(i++)).text())
            item["mtotal"]=parseFloat($($record.get(i++)).text())
            item["ltotal"]=parseFloat($($record.get(i++)).text())
            item["sltotal"]=parseFloat($($record.get(i++)).text())
            item["volume"]=parseFloat($($record.get(i++)).text())
            item["growth"]=$($record.get(i++)).text()
            result.list.push(item)
        $last = $($records.get(length-1)).find("td")
        i=1 #the first one is chinese character
        result["summary"]={}
        result.summary["total"]=parseFloat($($last.get(i++)).text())
        result.summary["stotal"]=parseFloat($($last.get(i++)).text())
        result.summary["mtotal"]=parseFloat($($last.get(i++)).text())
        result.summary["ltotal"]=parseFloat($($last.get(i++)).text())
        result.summary["sltotal"]=parseFloat($($last.get(i++)).text())
        
        res.sendJSONP(params.callback,result)

exports.StockServices = StockServices