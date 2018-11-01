Some technical issues about **R** **Shiny** application: http://bio.odb.ntu.edu.tw/query

[![A small demo](https://github.com/cywhale/ODB/blob/master/docs/Intro_web001_201806_remark01ezgif.gif)](https://github.com/cywhale/ODB/blob/master/docs/Intro_web001_201806_remark01ezgif.gif)

*Link to database*...
* Construct shiny-server and PostgresSQL on different server. Write a private, internal package to connect database and return data. 
Through *Opencpu* API, then we can can fetch data after users input some criteria in shiny UI, and terminate the link to database after receiving the queried data.
Reference link: https://www.opencpu.org/posts/scoring-engine/

* Opencpu API can be hidden by Apache and Nginx setting. By doing so, we don't need to keep connection to database in the shiny session.

*Async*...
* Another advantage is that, this handling can be scheduled into *future*::future() if some pre-fetched data is needed. Then,
the shiny-server can continue to accomplish other UI's loading. As you need to render these pre-fetched data, just use future::value().
Other external data can be also scheduled into future().
    - Happy to see the Promise in shiny will integrated with future. Here is the discussion https://github.com/HenrikBengtsson/future/pull/163#issuecomment-357098873 
*  **201804 update**    
*  All long-run R functions work well in fx <- reactive({ future( foo() ) }), move away other shiny reactive controls within future(), use observeEvent(event, { fx() %...>% ({do something}) }) #Rshiny async #promises + #future both plan(multiprocess), plan(callr) ok #rstats https://twitter.com/bramasolo/status/983942002440941568 
*  An simplified example (app.R): https://github.com/cywhale/ODB/blob/master/shiny_async_test/app.R 
*  promise_all idea: https://rstudio.github.io/promises/articles/combining.html
```
  f1 <- reactive({ future( fetchDB1() ) })
  f2 <- reactive({ future( fetchDB2() ) })
  observeEvent(event, { 
    df1 <- f1() %...>% ({filtering...}) })
    df2 <- f2() %...>% ({filtering...}) })
    promise_all(df1, df2) %...>% {
      rbindlist(l=., fill=TRUE, use.names=TRUE)
      do some controls or side effects here...
    }
```

*Loding*...
* Encounter that js|css cannot be cached in Nginx, otherwise the web site got Errors. So I serve them in CDN.
Reference link: https://goo.gl/fum9Ji
    - Use Dev tool of browsers, you can find the loading of these resources on CDN can be cached, and the loading speed got improved.

Free free to contact me if any comments.


Some references:
*  A similar idea by using Plumber, presentation from Jeff Allen. Comments: https://twitter.com/bramasolo/status/987006787919360001


Chinese version, also on ptt https://goo.gl/s9BZT8
* 分享自己寫的 **shiny** app 主題是海洋浮游動物的生態資料庫查詢。在這就不介紹生態上的議題，主要分享技術上心得可供參考
http://bio.odb.ntu.edu.tw/query/

*Database*...
* shiny-server 和 PostgresSQL資料庫可架在不同server，在UI 完成篩選條件後，抓資料的function寫成內部使用的package，經由 **Opencpu** API 去抓使用者要的資料，抓完即斷掉和資料庫連結。 Opencpu API作法參考
https://www.opencpu.org/posts/scoring-engine/

* Opencpu server可在Apache 和 Nginx屏蔽成內網使用。用此做法在shiny-server session中，不需要持續和資料庫保持連結。
    - 順提，前日在Hadley twitter讀到他介紹 RPostgres 相對於RPostgresql這個目前使用的package的優勢，包括會自動清除佚失的連結，與query速度較快。之後應該會
改用看看~~ https://github.com/r-dbi/RPostgres

*Async*...
* 另一個好處是預先要抓的資料，可以丟進 **future**::future() (以及其他讀外部檔等工作) 讓shiny-server繼續完成其他UI要做的事，等到需要render資料時才用future::value()叫用出來。這樣減少一些lag..

*Loading*...
* 網頁一開始會慢的一部分原因都在掛載的javascript and css，這在nginx中若設 js | css 的cache, 網站都會出錯。但可以把這些倚賴的資源放在 CDN 上，
參考做法：https://goo.gl/fum9Ji  可以看到重複連結網站時，掛載在CDN上的resource都是取用被cache的，速度就會提升。

> 其實遇到很多問題，都靠孤狗大神一個個解決。我列了我使用到的package在這，其他有機會再續談。
http://bio.odb.ntu.edu.tw/index_tech_citations.html

> 以上做法可能都有其他更好、更快的方式，目前這樣做僅供參考，也歡迎討論。(如果您有使用此網站，使用經驗上好或不好的地方，或有其他細節要聯絡，敬請告知或透過網頁上email聯絡。)

*[關鍵字]* Shiny-server, API, Database
