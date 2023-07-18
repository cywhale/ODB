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

project = prj_dt %>% setnames(1:dim(prj_dt)[2],tolower(colnames(prj_dt))) %>%
  .[,c(1:6,9,13,28,32),with=F] %>% setnames(c(1,9),c("prj_rid","cr_rid"))  %>%
  .[,prj_id:=seq_len(nrow(.))] %>% .[,c("prj_id",colnames(.)[1:(dim(.)[2]-1)]),with=F]
#%>%
#  merge(cruise[,c(1,3),with=F],by="cr_rid",all.x=T) %>% .[,cr_rid:=NULL] %>% 
#  arrange(prj_id) %>% data.table()

#=== create the link betwwen cr_aras_id and cid
#### to utilize cruise_id....first, combine date and long-lat information
#### survey (CR not CSR) is not used in XML upload method (CSR), so no use here
cr_info = merge(cruise[,.(cr_aras_id,departure_date,return_date,ispublic,uploaded)],
                survey[,.(cr_aras_id,lat_deg,lon_deg,uploaded)] %>% 
                  .[,c("lat_min","lat_max","lon_min","lon_max", "uploaded"):=list(
                     fifelse(all(is.na(lat_deg)),NA_real_,range(na.omit(lat_deg))[1]),
                     fifelse(all(is.na(lat_deg)),NA_real_,range(na.omit(lat_deg))[2]),
                     fifelse(all(is.na(lon_deg)),NA_real_,range(na.omit(lon_deg))[1]),
                     fifelse(all(is.na(lon_deg)),NA_real_,range(na.omit(lon_deg))[2]), uploaded),by="cr_aras_id"] %>%
                  .[,.(cr_aras_id,lat_min,lat_max,lon_min,lon_max,uploaded)] %>% unique(),
                  by=c("cr_aras_id", "uploaded"),all.x=T)

#### manual fix typo
# cr_dt["?大杰" %in% investigators,]
cr_dt[grepl("?大杰",investigators), investigators:=gsub("\\?大杰", "溫大杰", investigators)]
cr_dt[grepl("葉?田",investigators), investigators:=gsub("葉\\?田", "葉啟田", investigators)]
cr_dt[grepl("江秉?",investigators), investigators:=gsub("江秉\\?","江秉峵", investigators)]
cr_dt[grepl("邱瑞?",primary_investigator), primary_investigator:=gsub("邱瑞\\?","邱瑞焜", primary_investigator)]
cr_dt[grepl("許瑞?",primary_investigator), primary_investigator:=gsub("許瑞\\?","許瑞峯", primary_investigator)]
cr_dt[grepl("沒有資料",primary_investigator), primary_investigator:=NA_character_]
cr_dt[grepl("台灣西南海域中鋼爐石海?區", cruise_name), cruise_name:="台灣西南海域中鋼爐石海抛區"]

#### fix typo in project
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

#function to find corresponding ExploreOcean vs investigate_region
findRegion = function(investigate_region) {
  unlist(tstrsplit(investigate_region,split=","), use.names = FALSE) %>%
    sapply(function(x){region[VALUE==as.character(x),]$LABEL_ZT[1]}, simplify = T) %>%
    unlist(use.names = F) %>% paste(collapse=",")
}

#function: convert GMT+8 to ISO8601 string
utc2ISOstr = function(utctime) {
  as.POSIXct(format(force_tz(utctime,tzone= 'GMT'),tz = 'Asia/Taipei',origin ='GMT', usetz=TRUE)) %>%
  #as.POSIXct(format(utctime, tz = 'Asia/Taipei',origin ='GMT+8', usetz=TRUE)) %>%
    strftime("%Y-%m-%dT%H:%M:%SZ")  
}

#function: remove undesired spacing within Chinese characters
subSpacing = function(text) {
  gsub("(\\()(\\s+)(.*\\))", "\\1\\3", 
  gsub("([\U4E00-\U9FFF\U3000-\U303F\\(])(\\s+)(?=[\U4E00-\U9FFF\U3000-\U303F\\s]*\\(*[^)]*\\)*|[\U00C0-\U024F])", "\\1", text, perl=TRUE))
## example ##
  ##gsub("(\\()(\\s+)(.*\\))", "\\1\\3", gsub("([\U4E00-\U9FFF\U3000-\U303F\\(])(\\s+)(?=[\U4E00-\U9FFF\U3000-\U303F\\s]*\\(*[^)]*\\)*|[\U00C0-\U024F])", "\\1", "台    大 ( 單位) (National Taiwan University)", perl=TRUE))
  ##[1] "台大(單位) (National Taiwan University)"
}

#function: add prefix of numbering (1., 2.) in front of projects
prefixCat = function(items) { 
  sapply(seq_along(items), function(x) paste0(x, ".", items[x]), simplify = TRUE)
}

#Just a test ExploreOcean in cruise_name
#crt = cr_dt[ispublic==1, .(id, keyed_name, cruise_name, investigate_region)]
#crt[, region:=gsub("NA", NA_character_, 
#                fifelse(is.na(investigate_region) & grepl("群島|海域|溪口|附近|南海|東海|外海|海峽|沿岸|近岸|沿海|近海|淺堆|灘|水域|峽谷|河口|小琉球|中國海|(台|臺)東|永安|南灣|東港|高雄|高屏溪|台南|澎湖|蘭嶼|綠島|左營|台灣(東|西|南|北)", cruise_name),
#                fifelse(grepl("地物|化學|元素|(洋|環|湧升)流|水團|地層|特性|懸浮|鋒面|演化|資源|現象|結構|(地|物)質|(震|遙|觀|量)測|紀錄|分(佈|布)|差異|模式|實習|測量|關係|實驗|機制|資料|分析|影響|調查|研究|評估|計(畫|劃)|生物|描述|過程|作用|變化|環境|蟲|浮游|沈積|生態|重金屬", 
#                              cruise_name), #, perl=TRUE)
#                  NA_character_,
#                  gsub("\\((.*)\\)|KEEP-II|KEEP|WOCE|探測|黑潮(分支|蛇行)|之態|水文", "", gsub("臺灣","台灣", trim(cruise_name)))),
#                  findRegion(investigate_region))), by=.(id)]

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

####CSR: CruiseBasicData
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
        StartDate=utc2ISOstr(departure_date),
        EndDate=utc2ISOstr(return_date),
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

#### CSR: CruiseData
#<CruiseData>
#  <Item>都普勒流剖儀ADCP 75-kHz</Item>
#  <CollectionNum>1</CollectionNum>
#  <CollectionOwner>樣品持有人1</CollectionOwner>
#  <ReasonChecked>0</ReasonChecked>
#  <Reason> </Reason>
#  <Item>單音束測深儀EK-80</Item>
# ....
#<Physical>
#<Equipment>CTD</Equipment>
#  <Summary1>1</Summary1>
#  <Summary2>1</Summary2>
#  <DataOwner>物理1</DataOwner>
#  <Equipment>Drifter</Equipment>
# ....
#<Biogeochemical>, <Biology>, <Geology>, <Geophysics>, <Atmosphere>, <Other>

# first define the mapping dictionary
work_details_dict <- c("化" = "Biogeochemical",
                       "船" = "CruiseData",
                       "物" = "Physical",
                       "地" = "Geology",
                       "未分類" = "Other",
                       "生" = "Biology")

# SBP (sub-bottom profiler) = Chirp Sonar 
# OR1 < 951(不含) 寫 底質剖面儀 Bathy2000
# OR1 >=951(含) 寫 底質剖面儀 Bathy2010
# cr_basic[ShipName=="OR1" & CruiseID=="0951",]
# StartDate: 2010-12-14T10:00:00Z
crwork <- merge(work[,.(cr_rid, work_id, works, remark, work_details, quantity, owner_of_samples)] %>%
                  setnames(1,"id"),
                cr_basic[,.(id, ShipName, CruiseID, StartDate)], by="id", all.x=TRUE)

# Create a function to parse `work_details`
parse_work_details <- function(work_details, works, work_id, remark, ShipName, StartDate, item_base_date) {
  # Split the work_details string
  if (is.na(work_details) || trimws(work_details)=="" || work_details=="NA") {
   #return(list(field = NA_character_, equipment = NA_character_, summary2 = NA_character_))
    return(list(field = "", equipment = "", summary2 = ""))
  }
  splits <- unlist(tstrsplit(work_details, split = "(\\(\\s*|\\)\\s*)"))
  splits=splits[splits!=""]
  if (length(splits) != 4) {
    if (length(splits) == 5) {
      equipment <- trimws(paste0(splits[3], splits[4]))
      summary2 <- trimws(splits[5])
    } else if (length(splits) == 3) {
      equipment <- trimws(splits[3]) #"S999(船)其他"
      summary2 <- ""
    } else {
      print(paste("Error split length:", work_details, work_id, sep=" - "))
    }
  } else {
    equipment <- trimws(splits[3])
    summary2 <- trimws(splits[4])
  }
  # Extract the components
  work_term <- trimws(splits[1])
  if (works != work_term) {
    print(paste("Error matching works: ", work_term, works, work_details, work_id, sep=" - "))
  }
  field_symbol <- trimws(splits[2])
  field <- work_details_dict[field_symbol]
  
  ### some special case, maually edit it ####
  #print(paste0("Test crwork: ", ShipName, StartDate, item_base_date, remark))
  equipment <- gsub("CTD\\s*採水", "CTD", equipment)
  if (grepl("ADCP", equipment) & as.character(works)=='S001') {
    equipment = "都普勒流剖儀ADCP"
  } else if (grepl("EK500", equipment) & as.character(works)=='S002') {
    equipment = "單音束測深儀EK-500"
  } else if (grepl("EK60", equipment) & as.character(works)=='S004') {
    if (grepl("EK\\-*80", remark)) {
      equipment = "單音束測深儀EK-80"
    } else {
      equipment = "單音束測深儀EK-60"
    }
  } else if (grepl("EA640", equipment) & as.character(works)=='S005') {
    equipment = "單音束測深儀EA-640"
  } else if (grepl("Chirp", equipment) & as.character(works)=='G007') {
    field = "CruiseData"
    if (!is.na(ShipName) & !is.na(StartDate) & as.character(ShipName) == 'OR1') {
      if (StartDate >= item_base_date) {
        equipment = "底質剖面儀Bathy2010"
      } else {
        equipment = "底質剖面儀Bathy2000"
      }
    } else {
      equipment = "底質剖面儀"
    }
  } else if (as.character(works)=='G016') {
    field = "CruiseData"
    if (grepl("多音束", equipment) & grepl("304", remark)) {
      equipment = "多音束測深儀EM304"
    } else if (grepl("多音束", equipment) & grepl("712", remark)) {
      equipment = "多音束測深儀EM712"
    } else if (grepl("多音束", equipment) & grepl("2040", remark)) {
      equipment = "多音束測深儀EM2040"
    } else {
      equipment = "多音束測深儀"
    }
  } else if (grepl("OBS", equipment) & as.character(works)=='G014') {
    equipment = "海底地震儀OBS"  
  }  
  
  return(list(field = field, equipment = equipment, summary2 = summary2))
}

# Apply the function to `work_dt` to create `fields_dt`
fields_dt <- copy(crwork) %>% 
  .[, c("Field", "Equipment", "Summary2") :=
      parse_work_details(work_details, works, work_id, remark, ShipName, StartDate,
                         item_base_date=crwork[ShipName=="OR1" & CruiseID=="0951",]$StartDate[1]),
                         by=.(id, work_id, works)]
fields_dt[, `:=`(Summary1 = quantity, DataOwner = gsub("、$","", trimws(owner_of_samples)))]
fields_dt <- fields_dt[,.(id, work_id, works, Field, Equipment, Summary1, Summary2, DataOwner, remark)]

chcols = names(fields_dt)[sapply(fields_dt, is.character)]
for (j in chcols)
  set(fields_dt,which(is.na(fields_dt[[j]])),j,"")


# Create a new column 'work_remark' that combines 'works' and 'remark'
work_remark = fields_dt[,.(id, works, remark)] %>%
  .[!is.na(remark) & remark!="" & remark!="NA",] %>%
  .[, .(work_remark=paste(paste0(works, ":", remark),collapse=";")), by=(id)]

####CSR: Participants
prjy = prj[,.(participants=subSpacing(participants)), by=.(cr_rid, pid, institute)] %>%
  setnames(1,"id")

#cr_basis correspond to project
setkey(cr_basic, id)
setkey(prjy, id)
setkey(work_remark, id)
crprj = merge(cr_basic, work_remark, by="id", all.x=TRUE) %>%
  .[,`:=`(Remark=paste0(fifelse(is.na(Remark) | Remark=="" | Remark=="NA", "", Remark),
                        fifelse(is.na(work_remark), "", paste0("(", work_remark,")")))), by=.(id)]
crprj[,`:=`(work_remark=NULL)]
fields_dt[,`:=`(remark=NULL)]

crprj = merge(crprj, prjy, by="id", all.x=TRUE)
setkey(crprj, id)

chcols = names(crprj)[sapply(crprj, is.character)]
for (j in chcols)
  set(crprj,which(is.na(crprj[[j]])),j,"")

crprj_list <- split(crprj, by = "id", keep.by = FALSE)
crprj_list <- lapply(crprj_list, function(dt) {
  list(
    CruiseBasicData = list(
      ShipName = dt$ShipName[1],
      CruiseID = dt$CruiseID[1],
      LeaderName = dt$LeaderName[1],
      ExploreOcean = dt$ExploreOcean[1],
      FarestDistance = dt$FarestDistance[1],
      TotalDistance = dt$TotalDistance[1],
      FuelConsumption = "",
      StartDate = dt$StartDate[1],
      EndDate = dt$EndDate[1],
      StartPort = dt$StartPort[1],
      EndPort = dt$EndPort[1],
      DurationDays = dt$DurationDays[1],
      DurationHours = dt$DurationHours[1],
      PlanName = dt$PlanName[1],
      Technician = dt$Technician[1],
      Remark = dt$Remark[1]
    ),
    Participants = list(
      Department = dt$institute,
      Name = dt$participants
    )
  )
})

# Each Fields 
# Get all unique fields
unique_fields <- unique(fields_dt$Field)

# Create a list to hold data.tables
field_dts <- list()

# Loop over each unique field
for (field in unique_fields) {
  # Filter rows with this field
  field_dt <- fields_dt[Field == field]
  
  # Aggregate rows by id
  #field_dt <- field_dt[, lapply(.SD, function(x) list(unique(na.omit(x)))), by = id]
  #field_dt <- field_dt[, lapply(.SD, function(x, y) {
  #  if (y == "Field") {
  #    list(unique(na.omit(x)))
  #  } else {
  #    list(x)
  #  }
  #}, y = names(.SD)), by = id]
  field_dt <- field_dt[, lapply(.SD, function(x) list(x)), by = .(id, Field)]
  
  # Store the result in the list
  #chcols = names(field_dt)[sapply(field_dt, is.character)]
  #for (j in chcols)
  #  set(field_dt,which(is.na(field_dt[[j]])),j,"")
  
  field_dts[[field]] <- field_dt
}

# Bind all the field data.tables vertically
nested_fields <- rbindlist(field_dts, idcol = 'Field')

# Remove duplicated 'Field' column
setnames(nested_fields, 1, "dup_field")
nested_fields[,c("dup_field"):=list(NULL)]

# Set key on 'id'
setkey(nested_fields, id)
result <- merge(crprj, prjx %>% setnames(1, "id"), by="id", all.x=TRUE) %>%
  merge(nested_fields, by="id", all.x=TRUE)

#### Output as JSON, prepare importing to MongoDB
# function: Recursively unbox all lists with only one item
#recursive_unbox <- function(x) {
#  if (is.list(x)) {
#    if (length(x) == 1) {
#      x <- unbox(x)
#    } else {
#      x <- lapply(x, recursive_unbox)
#    }
#  }
#  x
#}
#recursive_unbox <- function(x) { #cause double/nested array if it's a multi-element array
#  if (is.recursive(x)) {
#    lapply(x, recursive_unbox)
#  } else if (length(x) == 1) {
#    jsonlite::unbox(x)
#  } else {
#    x
#  }
#}

recursive_unbox <- function(x, unbox_leaf_arr=FALSE) {
  if(is.list(x) && length(x) == 1 && !is.data.frame(x)) {
    return(recursive_unbox(x[[1]], unbox_leaf_arr=unbox_leaf_arr))
  } else if(is.list(x)) {
    #print(paste(names(x), collapse=","))
    if (names(x)[1] == "CruiseBasicData") {
      return(mapply(recursive_unbox, x, as.list(c(TRUE, rep(FALSE, length(x)-1)))))
    }
    return(lapply(x, recursive_unbox, unbox_leaf_arr=unbox_leaf_arr))
  } else if (length(x) == 1) {
    if (unbox_leaf_arr) {
      if (is.na(x[[1]])) {
        return(jsonlite::unbox(NA))
      } 
      return(jsonlite::unbox(x))
    }
    return(x)
  } else {
    x
  }
}

# Transform nested_fields data.table to list
fields_list <- split(nested_fields, by = "id", keep.by = FALSE)
fields_list <- lapply(fields_list, function(dt) {
  setNames(
    lapply(unique(dt$Field), function(field) {
      sub_dt <- dt[Field == field]
      if (field=='CruiseData') {
        list(
          Item = sub_dt$Equipment,
          CollectionNum = sub_dt$Summary1,
          CollectionOwner = sub_dt$DataOwner,
          ReasonChecked = rep(0, length(tstrsplit(sub_dt$DataOwner,","))),
          Reason = rep("", length(tstrsplit(sub_dt$DataOwner,",")))
        )
      } else {
        list(
          Equipment = sub_dt$Equipment,
          Summary1 = sub_dt$Summary1,
          Summary2 = sub_dt$Summary2,
          DataOwner = sub_dt$DataOwner
        )
      } 
    }),
    unique(dt$Field)
  )
})

# Combine crprj_list and fields_list
# combined_list <- mapply(c, crprj_list, fields_list, SIMPLIFY = FALSE)
# cause warning: In mapply(c, ..: longer argument not a multiple of length of shorter" 
# it caused from different id in crprj (from cr_basic) and fields_dt (from project)
# tt = which(!crprj$id %in% fields_dt$id); length(tt) #[1] 1570 
# tt1= which(!fields_dt$id %in% crprj$id); length(tt1)#[1] 94
# Create an empty template for fields as aboving empty_template
empty_template <- list()

# Extend fields_list to include all ids from crprj_list
extended_fields_list <- lapply(names(crprj_list), function(id) {
  if (id %in% names(fields_list)) {
    return(fields_list[[id]])
  } else {
    return(empty_template)
  }
})

names(extended_fields_list) <- names(crprj_list)  # Assign names

# Combine crprj_list and extended_fields_list
combined_list <- mapply(c, crprj_list, extended_fields_list, SIMPLIFY = FALSE)

# Unname the list to remove keys
combined_list <- unname(combined_list)

# Apply recursive unboxing
combined_list <- lapply(combined_list, recursive_unbox)

# Convert list to JSON
js1 <- toJSON(combined_list, pretty = TRUE)

# data check #combined_list[[3]]
# result[ShipName=="OR3" & CruiseID=="0919"] #original
# toJSON(combined_list[[3]], pretty = TRUE)  #stored JSONs
matching_indices <- which(unlist(lapply(combined_list, function(x) {
  x$CruiseBasicData$ShipName[[1]] == "OR1" & x$CruiseBasicData$CruiseID[[1]] == "0951"
})), useNames = F) #4627
# toJSON(combined_list[[4627]], pretty = TRUE)
# toJSON(combined_list[[6018]], pretty = TRUE)
# toJSON(combined_list[[2800]], pretty = TRUE) #OR3 1773
#=====================================================================

## Freees driver of MS SQL server
close(ms_drv)
#odbcClose(channel)





