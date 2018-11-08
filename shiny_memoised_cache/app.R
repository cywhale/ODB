# Test memoised functions by R.cache

library(shiny)
library(sf)
library(leaflet)
library(mapview)
library(mapedit)
library(magrittr)
library(R.cache)

# Define UI for application 
ui <- fluidPage(
  fluidRow(
    uiOutput("test_ui")
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
    key <- list(akey,...)
  }
  fn <- as.character(substitute(FUN))
  data <- loadCache(key)
  if (!is.null(data)) {
    print(paste0("Loaded ", fn, " cached data"))
    return(data)
  }
  print(paste0("Generating ", fn, " data from scratch..."))
  data <- FUN(...)
  saveCache(data, key=key, comment=paste0(fn,"()"))
  return(data)
}    

sf_polyx <- function(poly, delayMS=NA_integer_) {
  
  if (!is.na(delayMS)) Sys.sleep(as.integer(delayMS/1000)) #only for test 
  p <- poly %>% matrix(ncol=2,byrow=FALSE) %>% list() %>%
    st_polygon() %>%
    st_sfc(crs = 4326) 
}

init_lf <- function(poly, delayMS) {
  p <- memFx(FUN=sf_polyx, akey=NULL, poly=poly, delayMS = delayMS)
  
  leaflet() %>% addTiles() %>% setView(130, 30, zoom=5) %>%
    addPolygons(data=p, popup=paste(st_bbox(p), collapse=","))
}

server <- function(input, output) {
  
  ns <- shiny::NS("eview") 
  
  #### Initialize leaflet map  
  
  output$emod_ui <- renderUI({
    editModUI("eview", width="100%", height="480px")
  })
  
  output$test_ui <- renderUI({
    actionButton("test_but", "Test!")
  })
  
  observe({
    callModule(editMod, "eview", isolate({init_lf(geopoly, gDelay)}))
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

