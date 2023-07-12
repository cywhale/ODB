library(data.table)
library(dplyr)
library(configr)
library(RODBC)
library(magrittr)
library(lubridate)
library(jsonlite)

setwd(here::here("ODB/R"))
## Function used

trim    = function (x) gsub("^\\s+|\\s+$", "", x)  ## Trim leading or trailing whitespace
trim.01n= function (x) gsub("\\r","",gsub("\\n","",gsub("^\\s+|^\\+|\\s+$|\\+$", "", x)))  ## Trim leading or trailing whitespace, "\"

## global variable
ilst= "aras_tbl/"
overwrite_ArasOut = TRUE #overwrite files under aras_tbl/
#IN_MSWIN = TRUE

conf = read.config(file="./env.config.json")

#if (IN_MSWIN) {
#require(RODBC)

## connect to MS SQL server database using ODBC
ms_drv = odbcDriverConnect(paste0('driver={SQL Server};server=', conf$server,
                                  ';database=', conf$database, ';uid=', conf$user,
                                  ';pwd=', conf$pass))

## Aras related tables #================================================
## Trim columns such that no whitespace 
## cruise table
cr_dt = sqlQuery(ms_drv, 'select * from innovator.CRUISE') %>% 
    arrange(DEPARTURE_DATE) %>% data.table() %>%          # Cruise information
    .[,c("REMARK","CRUISE_NAME","INVESTIGATORS","ODB_DESC"):=
        list(trim.01n(REMARK),trim.01n(CRUISE_NAME),trim.01n(INVESTIGATORS),trim.01n(ODB_DESC))]
  
prj_dt= sqlQuery(ms_drv, 'select * from innovator.PROJECTS_ONBOARD') %>% 
    arrange(SORT_ORDER,CREATED_ON) %>% data.table() %>%# project to execute
    .[,PROJECTS:=trim.01n(PROJECTS)]
  
nrow(cr_dt) #6082;
nrow(prj_dt) #7210;
length(which(cr_dt$id %in% prj_dt$SOURCE_ID)) #4936 #not all cr_dt in prj_dt
length(which(prj_dt$SOURCE_ID %in% cr_dt$id)) #7210 #all prj_dt in cr_dt
work_dt= sqlQuery(ms_drv, 'select * from innovator.WORKS_ONBOARD') %>% 
    arrange(SORT_ORDER,CREATED_ON) %>% data.table()   # work run
  
length(which(cr_dt$id %in% work_dt$SOURCE_ID)) #4560

value_dt =  sqlQuery(ms_drv, 'select * from innovator.VALUE') %>% 
  arrange(SORT_ORDER,CREATED_ON) %>% data.table()

length(which(work_dt$WORKS %in% value_dt$VALUE)) #21042 #need to extract LABEL_ZT in VALUE table
  
surv_dt= sqlQuery(ms_drv, 'select * from innovator.SURVEYLOG') %>% 
    arrange(SORT_ORDER,CR_DATE) %>% data.table() %>%   #cr_dt CR table information
    .[,REMARK:=trim.01n(REMARK)]
    
length(which(surv_dt$SOURCE_ID %in% cr_dt$id)) #88404 all in, cr_dt to surv_dt is 1 to multiple (stations)
#BUT not every cruise (cr_dt) has corresponding CR tables (surv_dt)

currdate = Sys.Date()
cr_dt[, uploaded:=currdate]
prj_dt[, uploaded:=currdate]
work_dt[, uploaded:=currdate]
value_dt[, uploaded:=currdate]
surv_dt[, uploaded:=currdate]

if (overwrite_ArasOut) {
 write.table(cr_dt,paste0(ilst, "aras_cruise.txt"),   sep="\t",quote=F,na="",row.names=F)
 write.table(prj_dt,paste0(ilst,"aras_project.txt"),  sep="\t",quote=F,na="",row.names=F)
 write.table(work_dt,paste0(ilst,"aras_work.txt"),  sep="\t",quote=F,na="",row.names=F)
 write.table(value_dt,paste0(ilst,"aras_value.txt"),sep="\t",quote=F,na="",row.names=F)
 write.table(surv_dt,paste0(ilst,"aras_survey.txt"),sep="\t",quote=F,na="",row.names=F)
}

#### merge and select wanted cruise ##
#require(data.table)
#require(magrittr)

#cr_dt ISPUBLIC 0: not open (may has errors or not public data)

cruise = cr_dt %>% setnames(1:dim(cr_dt)[2],tolower(colnames(cr_dt))) %>%
  .[,c(1,2,4,5,9,24:35,37:54,57),with=F] %>% setnames(c(1,3),c("cr_rid","cr_aras_id"))

survey = surv_dt %>% setnames(1:dim(surv_dt)[2],tolower(colnames(surv_dt))) %>%
  .[,c(1:18,20,24,39,43:45,46),with=F] %>% setnames(c(1,21),c("surv_rid","cr_rid")) %>%
  .[,surv_id:=seq_len(nrow(.))] %>% .[,c("surv_id",colnames(.)[1:(dim(.)[2]-1)]),with=F] %>%
  merge(cruise[,c(1,3),with=F],by="cr_rid",all.x=T) %>% .[,cr_rid:=NULL] %>%
  .[,surv_rid:=NULL] %>% arrange(surv_id) %>% data.table()
  
numcols <- c("bottom_depth","lower_depth","air_temperature","wind_speed")
for (j in numcols) set(survey,j=j,value=as.numeric(trim(survey[[j]])))

work = work_dt %>% setnames(1:dim(work_dt)[2],tolower(colnames(work_dt))) %>%
  .[,c(1:6,9,13,28,32),with=F] %>% setnames(c(1,9),c("work_rid","cr_rid"))  %>%
  .[,work_id:=seq_len(nrow(.))] %>% .[,c("work_id",colnames(.)[1:(dim(.)[2]-1)]),with=F] %>%
    merge(value_dt[,c("VALUE", "LABEL_ZT")] %>% setnames(c(1:2), c("works","work_details")),
          by="works", all.x=T) %>% arrange(work_id)
#%>%
#  merge(cruise[,c(1,3),with=F],by="cr_rid",all.x=T) %>% .[,cr_rid:=NULL] %>% 
#  arrange(work_id) %>% data.table()

project = prj_dt %>% setnames(1:dim(prj_dt)[2],tolounwer(colnames(prj_dt))) %>%
  .[,c(1:6,9,13,28,32),with=F] %>% setnames(c(1,9),c("prj_rid","cr_rid"))  %>%
  .[,prj_id:=seq_len(nrow(.))] %>% .[,c("prj_id",colnames(.)[1:(dim(.)[2]-1)]),with=F]
#%>%
#  merge(cruise[,c(1,3),with=F],by="cr_rid",all.x=T) %>% .[,cr_rid:=NULL] %>% 
#  arrange(prj_id) %>% data.table()

#======= create the link betwwen cr_aras_id and cid
######## to utilize cruise_id....first, combine date and long-lat information

cr_info = merge(cruise[,.(cr_aras_id,departure_date,return_date,ispublic,uploaded)],
                survey[,.(cr_aras_id,lat_deg,lon_deg,uploaded)] %>% 
                  .[,c("lat_min","lat_max","lon_min","lon_max", "uploaded"):=list(
                     fifelse(all(is.na(lat_deg)),NA_real_,range(na.omit(lat_deg))[1]),
                     fifelse(all(is.na(lat_deg)),NA_real_,range(na.omit(lat_deg))[2]),
                     fifelse(all(is.na(lon_deg)),NA_real_,range(na.omit(lon_deg))[1]),
                     fifelse(all(is.na(lon_deg)),NA_real_,range(na.omit(lon_deg))[2]), uploaded),by="cr_aras_id"] %>%
                  .[,.(cr_aras_id,lat_min,lat_max,lon_min,lon_max,uploaded)] %>% unique(),
                  by=c("cr_aras_id", "uploaded"),all.x=T)
#### manual fix
# cr_dt["?大杰" %in% investigators,]
cr_dt[grepl("?大杰",investigators), investigators:=gsub("\\?大杰", "溫大杰", investigators)]
cr_dt[grepl("葉?田",investigators), investigators:=gsub("葉\\?田", "葉啟田", investigators)]
cr_dt[grepl("江秉?",investigators), investigators:=gsub("江秉\\?","江秉峵", investigators)]
cr_dt[grepl("邱瑞?",primary_investigator), primary_investigator:=gsub("邱瑞\\?","邱瑞焜", primary_investigator)]
cr_dt[grepl("許瑞?",primary_investigator), primary_investigator:=gsub("許瑞\\?","許瑞峯", primary_investigator)]
cr_dt[grepl("沒有資料",primary_investigator), primary_investigator:=NA_character_]
cr_dt[grepl("台灣西南海域中鋼爐石海?區", cruise_name), cruise_name:="台灣西南海域中鋼爐石海抛區"]

#### Extract information from value_dt
ships = unique(value_dt[grepl("號",LABEL_ZT), c("VALUE", "LABEL_ZT")])
ships[,shipname:=
  paste0(fifelse(grepl("水試", LABEL_ZT), "FR", 
         fifelse(grepl("新海研", LABEL_ZT), "NOR", "OR")),
         fifelse(grepl("一|1", LABEL_ZT), "1",
         fifelse(grepl("二|2", LABEL_ZT), "2", "3"))),by=.(VALUE)]
#VALUE  LABEL_ZT
#1:     1  海研一號
#2:     2  海研二號
#3:     3  海研三號
#4:     4  水試一號
#5:    11 新海研1號
#6:    12 新海研2號
#7:    13 新海研3號

ports = unique(value_dt[grepl("港",LABEL_ZT), c("VALUE", "LABEL_ZT")])
#VALUE LABEL_ZT
#1:     1   基隆港
#2:     2   高雄港
#3:     3   碧砂港
#4:     4   安平港
#5:     5   花蓮港
#6:     6   蘇澳港
#7:     7   富岡港
#8:     8   台北港
#9:     9   台中港
#10:    11   興達港
#11:    12   馬公港

region = unique(value_dt[grepl("海域",LABEL_ZT), c("VALUE", "LABEL_ZT")])
#   VALUE       LABEL_ZT
#1:   001       東部海域
#2:   002       北部海域
#3:     5   台灣周圍海域
#4:     3 龜山島周圍海域
#5:   004       西南海域
#6:   005       南海海域
#7:   006     太平洋海域
region[VALUE=="3", VALUE:="003"]
region = region[VALUE!="5"] %>% .[,LABEL_ZT:=trim(LABEL_ZT)]

#function to find corresponding ExploreOcean vs investigate_refion
findRegion = function(investigate_region) {
  unlist(tstrsplit(investigate_region,split=","), use.names = FALSE) %>%
    sapply(function(x){region[VALUE==as.character(x),]$LABEL_ZT[1]}, simplify = T) %>%
    unlist(use.names = F) %>% paste(collapse=",")
}

utc2localtime = function(utctime) {
  as.POSIXct(format(force_tz(utctime,tzone= 'GMT'),tz = 'Asia/Taipei',origin ='GMT', usetz=TRUE))
}

subSpacing = function(text) {
  gsub("(\\()(\\s+)(.*\\))", "\\1\\3", 
  gsub("([\U4E00-\U9FFF\U3000-\U303F\\(])(\\s+)(?=[\U4E00-\U9FFF\U3000-\U303F\\s]*\\(*[^)]*\\)*|[\U00C0-\U024F])", "\\1", text, perl=TRUE))
## example ##
  ##gsub("(\\()(\\s+)(.*\\))", "\\1\\3", gsub("([\U4E00-\U9FFF\U3000-\U303F\\(])(\\s+)(?=[\U4E00-\U9FFF\U3000-\U303F\\s]*\\(*[^)]*\\)*|[\U00C0-\U024F])", "\\1", "台    大 ( 單位) (National Taiwan University)", perl=TRUE))
  ##[1] "台大(單位) (National Taiwan University)"
}

prefixCat = function(items) { 
  sapply(seq_along(items), function(x) paste0(x, ".", items[x]), simplify = TRUE)
}

#test ExploreOcean in cruise_name
crt = cr_dt[ispublic==1, .(id, keyed_name, cruise_name, investigate_region)]
crt[, region:=gsub("NA", NA_character_, 
                fifelse(is.na(investigate_region) & grepl("群島|海域|溪口|附近|南海|東海|外海|海峽|沿岸|近岸|沿海|近海|淺堆|灘|水域|峽谷|河口|小琉球|中國海|(台|臺)東|永安|南灣|東港|高雄|高屏溪|台南|澎湖|蘭嶼|綠島|左營|台灣(東|西|南|北)", cruise_name),
                fifelse(grepl("地物|化學|元素|(洋|環|湧升)流|水團|地層|特性|懸浮|鋒面|演化|資源|現象|結構|(地|物)質|(震|遙|觀|量)測|紀錄|分(佈|布)|差異|模式|實習|測量|關係|實驗|機制|資料|分析|影響|調查|研究|評估|計(畫|劃)|生物|描述|過程|作用|變化|環境|蟲|浮游|沈積|生態|重金屬", 
                              cruise_name), #, perl=TRUE)
                  NA_character_,
                  gsub("\\((.*)\\)|KEEP-II|KEEP|WOCE|探測|黑潮(分支|蛇行)|之態|水文", "", gsub("臺灣","台灣", trim(cruise_name)))),
                  findRegion(investigate_region))), by=.(id)]

prj = project[!is.na(cr_rid),.(cr_rid, projects, pi, participants, project_number, institute)] %>%
  .[,pid:= rowid(cr_rid)] %>% setkey(cr_rid)

prj[project_number=="陳韋仁、魏志潾、李欣、董木華、許凌藍、梁卓景、湯淨、黃健豪、吳凱盈",
    `:=`(project_number=NA_character_, participants="陳韋仁、魏志潾、李欣、董木華、許凌藍、梁卓景、湯淨、黃健豪、吳凱盈")]

prj[project_number=="陳天任、徐佳瑜、徐彥承",
    `:=`(project_number=NA_character_, participants="陳天任、徐佳瑜、徐彥承")]

prj[project_number=="中山直英",
    `:=`(project_number=NA_character_, participants="中山直英")]

prj[project_number=="Philippe BOUCHET,Michel LE GALL",
    `:=`(project_number=NA_character_, participants="Philippe BOUCHET,Michel LE GALL英")]

#which(is.na(prj$participants) | prj$participants=="" | prj$participants=="NA")

prjx = prj[,#`:=`(proj=paste0(paste0(pid,"."),gsub("1\\.", "", projects), fifelse(is.na(project_number) | project_number=="" | project_number=="NA",
            #                               "", paste0("(", project_number, ")"))) %>%
            #       subSpacing(),
            `:=`(proj=fifelse(is.na(projects) | projects=="" | projects=="NA",
                   NA_character_,
                   paste0(gsub("1\\.", "", projects), fifelse(is.na(project_number) | project_number=="" | project_number=="NA",
                               "", paste0("(", project_number, ")"))) %>%
                   subSpacing()),
                 people=paste0(fifelse(is.na(institute) | institute=="" | institute=="NA",
                   as.character(pid),institute),":",participants) %>%
                   subSpacing()
                 ), by=.(cr_rid, pid, projects)] %>%
  .[, .(planname=fifelse(all(is.na(proj)), NA_character_, paste(prefixCat(unique(proj)), collapse="。")),
        participants=paste(people, collapse="。")), by=.(cr_rid)]

#CruiseBasicData

cr_basic= merge(cr_dt[ispublic==1,],
                prjx[,.(cr_rid, planname, participants)] %>% setnames(1,"id"),
                by="id",all.x=T)%>% 
  .[, ShipName:=ships[VALUE==platform,]$shipname[1], by=.(id)] %>%
  .[, .(CruiseID=toupper(gsub(ShipName, "", keyed_name)),
        LeaderName=gsub(",\\s*","、",trim(primary_investigator) %>% subSpacing()),
        ExploreOcean=gsub("NA", NA_character_, 
               fifelse(is.na(investigate_region) & grepl("群島|海域|溪口|附近|南海|東海|外海|海峽|沿岸|近岸|沿海|近海|淺堆|灘|水域|峽谷|河口|小琉球|中國海|(台|臺)東|永安|南灣|東港|高雄|高屏溪|台南|澎湖|蘭嶼|綠島|左營|台灣(東|西|南|北)", cruise_name),
                       fifelse(grepl("地物|化學|元素|(洋|環|湧升)流|水團|地層|特性|懸浮|鋒面|演化|資源|現象|結構|(地|物)質|(震|遙|觀|量)測|紀錄|分(佈|布)|差異|模式|實習|測量|關係|實驗|機制|資料|分析|影響|調查|研究|評估|計(畫|劃)|生物|描述|過程|作用|變化|環境|蟲|浮游|沈積|生態|重金屬", 
                                     cruise_name), #, perl=TRUE)
                               NA_character_,
                               gsub("\\((.*)\\)|KEEP-II|KEEP|WOCE|探測|黑潮(分支|蛇行)|之態|水文", "", gsub("臺灣","台灣", trim(cruise_name)))),
                       findRegion(investigate_region))),
        FarestDistance=as.integer(miles_from_shore_n_miles),
        TotalDistance=as.integer(cruise_distance_nautical_miles),
        FuelConsumption=NA_integer_,
        StartDate=utc2localtime(departure_date),
        EndDate=utc2localtime(return_date),
        StartPort=ports[VALUE==as.integer(departure_port),]$LABEL_ZT[1],
        EndPort=ports[VALUE==as.integer(arrival_port),]$LABEL_ZT[1],
        DurationDays=cruise_days,
        DurationHours=cruise_hours,
        PlanName=
          gsub("^(1\\.1\\.|\\(1\\))","1.",     
          gsub("^(\\s+)|\\s+$","",
          gsub("^(\\d+\\.)([^。]+。|[^。]+)$","\\2",
          gsub("(。)(\\()?(\\d+)(\\))",".\\3",
          fifelse((is.na(planname) || planname=="" || planname=='NA') &
                         grepl("黑潮|循環|傳輸|測試|水色|聲(納|學)|二氧化碳|LNG|WOCE|KEEP|動態|營養|地物|化學|元素|(洋|環|湧升)流|水團|地層|特性|懸浮|鋒面|演化|資源|現象|結構|(地|物)質|(震|遙|觀|量)測|紀錄|分(佈|布)|差異|模式|實習|測量|關係|實驗|機制|資料|分析|影響|調查|研究|評估|計(畫|劃)|生物|描述|過程|作用|變化|環境|蟲|浮游|沈積|生態|重金屬",
                         cruise_name), cruise_name, planname)
          )))),
        Technician=gsub("、+\\s*","、",investigators),
        Remark=remark
  ),by=.(id, ShipName)]


##
# Recursively unbox all lists with only one item
recursive_unbox <- function(x) {
  if (is.list(x)) {
    if (length(x) == 1) {
      x <- unbox(x)
    } else {
      x <- lapply(x, recursive_unbox)
    }
  }
  x
}

#cr_basis correspond to project
setkey(cr_basic, id)
prjy = prj[,.(participants=subSpacing(participants)), by=.(cr_rid, pid, institute)] %>%
  setnames(1,"id")
setkey(prjy, id)
crprj = merge(cr_basic, prjy, by="id", all.x=TRUE)

crprj_list <- split(crprj[1:15,], by = "id", keep.by = FALSE)

tt1 <- lapply(crprj_list, function(dt) {
  list(
    CruiseBasicData = list(
      ShipName = dt$ShipName[1],
      CruiseID = dt$CruiseID[1],
      LeaderName = dt$LeaderName[1],
      ExploreOcean = dt$ExploreOcean[1]
    ),
    Participants = list(
      Department = dt$institute,
      Name = dt$participants
    )
  )
})

tt1 <- unname(tt1)
combined_list <- lapply(tt1, recursive_unbox)

# Convert list to JSON
js1 <- toJSON(combined_list, pretty = TRUE, auto_unbox = TRUE)
#=====================================================================

## Freees driver of MS SQL server
close(ms_drv)
#odbcClose(channel)





