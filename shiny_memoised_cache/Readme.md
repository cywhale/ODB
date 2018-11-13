Please see [app.R](ODB/shiny_memoised_cache/app.R) and the movie clip to see how memoised functions by R.cache package can work in shiny app.
tweet: https://twitter.com/bramasolo/status/1060532122040000512

[![A small demo](https://github.com/cywhale/ODB/blob/master/shiny_memoised_cache/intro_cache_func02s.gif)](https://github.com/cywhale/ODB/blob/master/shiny_memoised_cache/intro_cache_func02s.gif)

Some explanations on Taiwan R-club: https://goo.gl/JEUcJS

分享一下，最近找適合在shiny app做cache，將某些計算過後的值記起來的package，並讓其他session的使用者也用得到（加速），找到memoise、R.cache這兩個package。
相較之下，R.cache 因為它的cache (存在file system)是persistent，其他shiny session會用一樣的cache (只要你給它的 key相同)，但memoise每次在restart shiny app都會重新建一個cache，也就是這個cache只能在同一session內重複被使用。所以在shiny 環境下使用，R.cache成了不錯的選擇，但memoise其實提供不少功能，也許適用在別的場合。

有興趣玩玩看的，我提供一個小範例(app.R)，放在 [app.R](ODB/shiny_memoised_cache/app.R)

實際應用在自己的 [shiny app](https://bio.odb.ntu.edu.tw/query)，的確加速不少，適合應用在initial load，通常都是重複的函數呼叫和計算。

值得一提的 R.cache的作者和 future package是同一位，做了相當多實用的package，但似乎有點低調。R.cache的資訊很少。 R.cache 和 future 剛好在shiny上一個用在減少 intra-session delay，一個用在 inter-session (async)上

另外 shiny在更新到 1.2版時，提供了繪圖上的cache (renderCachePlot) 初步看介紹，有點類似memoise 提供的一些功能，也許memoise也會有改版？

Reference:
https://github.com/HenrikBengtsson/R.cache
