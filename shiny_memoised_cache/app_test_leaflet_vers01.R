# Test memoised functions by R.cache for leaflet 2.0.3 and leaflet.providers
# Change file name to app.R, or test it online: https://bio.odb.ntu.edu.tw/sample-apps/leaflet1/
# Error message (for 2.0.3) shown in the end of this file
###############
library(shiny)
library(R.cache)
library(sf)

Sel_Old_Leaflet <- FALSE #TRUE #'2_0_3' #FALSE # '2_0_2'
old_ver_lib <- "~/R/user_lib" #/usr/lib/R/site-library # user-define R lib path
new_ver_lib <- .libPaths()[1]

old_ver_cache <- "./.Rcache" ## user-defined R.cache dir
new_ver_cache <- "/tmp/ocpu-temp/ocpu-rcache/.Rcache" ## another user-defined R.cache dir

#remotes::install_version("leaflet", version = "2.0.2", lib=old_ver_lib)
if (Sel_Old_Leaflet) {
  library('leaflet', lib.loc=old_ver_lib)
  setCacheRootPath(path=old_ver_cache) 
} else {
  library(leaflet, lib.loc=new_ver_lib)
  setCacheRootPath(path=new_ver_cache)  
}

text1 <- paste0("leaflet: ", packageVersion("leaflet"))
text2 <- paste0("Rcache: ", getCacheRootPath())
print(text1)
print(text2)

library(mapview)
library(mapedit)
library(magrittr)

# Define UI for application 
ui <- fluidPage(
  fluidRow(
    column(3, uiOutput("test_ui")),
    column(4, textOutput("text1_ui")),
    column(5, textOutput("text2_ui"))
  ),  
  fluidRow(
    uiOutput("emod_ui")
  )
)

gDelay <- 5000L
geopoly <- c(
  123.5, 132.25, 132.25, 123.5, 123.5,
  26.5, 26.5, 32.75,  32.75,  26.5
) 
tstpoly <- c(
  124, 127, 127, 124, 124,
  25, 25, 29,  29,  25
) 

memFx <- function (FUN, akey=NULL, ...) {
  if (is.null(akey)) {
    key <- list(...)
  } else {
    key <- list(akey)
  }
  fn <- as.character(substitute(FUN))
  data <- loadCache(key)
  if (!is.null(data)) {
    print(paste0("Loaded ", fn, " cached data"))
    return(data)
  }
  print(paste0("Generating ", fn, " data from scratch..."))
  ## modified 20200131, for those unused arguments may produce error (leaflet.providers prefix)
  ll <- list(...)  ##match.call()
  args <- formals(FUN)             ## formals with default arguments
  argx <- ll[names(ll) %in% names(args)]
  data <- do.call(FUN, argx)
  saveCache(data, key=key, comment=paste0(fn,"()"))
  return(data)
}    

sf_polyx <- function(poly, delayMS=NA_integer_) {
  
  if (!is.na(delayMS)) Sys.sleep(as.integer(delayMS/1000)) #only for test 
  p <- poly %>% matrix(ncol=2,byrow=FALSE) %>% list() %>%
    st_polygon() %>%
    st_sfc(crs = 4326) 
}

init_lf <- function(lf_map) {
  lf_map %<>% #addTiles() 
    addProviderTiles("Esri.WorldImagery", group="Ersi_World",
                     options = providerTileOptions(maxZoom=17, minZoom=2, crs = leafletCRS(crsClass = "L.CRS.EPSG3857"))) %>% 
    setView(130, 30, zoom=5) 
}

server <- function(input, output) {
  
  ns <- shiny::NS("eview") 
  
  #### Initialize leaflet map  
  
  output$emod_ui <- renderUI({
    editModUI("eview", width="100%", height="480px")
  })
  
  output$test_ui <- renderUI({
    actionButton("test_but", "Test it!")
  })
  
  output$text1_ui <- renderText({
    text1
  })
  output$text2_ui <- renderText({
    text2
  })
  
  observe({
    p <- sf_polyx(poly=geopoly) #memFx(FUN=sf_polyx, akey=NULL, poly=geopoly, delayMS = gDelay)
    
    callModule(editMod, "eview", isolate({
      memFx(FUN=init_lf, akey="init_lf", 
            lf_map = leaflet()
      ) %>%
        addPolygons(data=p, popup=paste(st_bbox(p), collapse=","))
    }))
  })
  
  observeEvent(input$test_but,{
    req(input$test_but)
    plx <- memFx(FUN=sf_polyx, akey="stamp1", poly=tstpoly, delayMS = gDelay)
    
    leafletProxy(ns("map")) %>% clearShapes() %>% 
      addPolygons(data=plx, color = "red", popup=paste(st_bbox(plx), collapse=",")) 
  })
}

# Run the application 
shinyApp(ui = ui, server = server)
########
## Error message when using leaflet 2.0.3
#Warning: Error in value[[3L]]: Couldn't normalize path in `addResourcePath`, with arguments: `prefix` = 'leaflet-provi$
#  106: stop
#  105: value[[3L]]
#  104: tryCatchOne
#  103: tryCatchList
#  102: tryCatch
#  101: addResourcePath
#  100: FUN
#   99: lapply
#   98: renderWidget
#   97: transform
#   96: func
#   94: f
#   93: Reduce
#   84: do
#   83: hybrid_chain
#   82: origRenderFunc
#   81: output$eview-map
#    1: runApp
