# Problem for leaflet 
# https://github.com/r-spatial/mapedit/issues/69

#### Testing parameters
#options(shiny.trace=TRUE) ## for debug
sleepTime <- 20L #### test async
testAsync <- TRUE ## if true, test promises and future

library(shiny)
library(sf)
library(leaflet)
library(mapview)
library(mapedit)
library(magrittr)
######################## test in 20180409
library(DT)
library(dplyr)
library(promises)
library(future) 
library(future.callr) ## Only trial.. 
library(parallel)

ui <- fluidPage(
  fluidRow(
    column(4, 
           fluidRow(
             uiOutput("control_ui")
           ),
           fluidRow(
             uiOutput("subset_ui")
           ),
           fluidRow(
             uiOutput("dt_result_ui")
           ),
           fluidRow(
             htmlOutput("outText")
           )
    ),
    column(7,
           fluidRow(
             uiOutput("emod_ui")
           ),
           fluidRow(
             uiOutput("leaflet_ui")
           )
    )
  )
)

server <- function(input, output, session) {
  
  ns <- shiny::NS("eview") 
  
  initSet <- FALSE
  plan(multiprocess, gc=TRUE)
  #plan(callr)
  
  stat <- reactiveValues(toggleSubset=FALSE)
 
  observeEvent(input$subset_but, {
    if (initSet & !stat$toggleSubset) {
      stat$toggleSubset <- TRUE
    } else {
      stat$toggleSubset <- FALSE
    }
    print("Toggle")
    print(as.integer(stat$toggleSubset))
    
    if (!testAsync) {
      leafletProxy("lview") %>% clearMarkers() %>% clearPopups() %>% 
        addCircleMarkers(data=datax(), #breweries91, stat$toggleSubset, sleepTime),
                         weight = 1, layerId = ~id, 
                         popup = ~as.character(century)) 
      return(NULL)
    } 
    
    lmap<- leafletProxy("lview") %>% clearMarkers() %>% clearPopups()
    
    if (stat$toggleSubset) {
      datax() %...>%
        addCircleMarkers(data = ., map = lmap, 
                         weight = 1, layerId = ~id, 
                         popup = ~as.character(century)) 
    }
  })
   
  datax <- reactive ({
    future({

      Sys.sleep(sleepTime) ## test if sync block multi-session
      
      st_as_sf(breweries91) %>%
        mutate(century = floor(founded/100)*100) %>%
        filter(!is.na(century)) %>%
        mutate(id=1:n())
    })  
  })
  
  lf0 <- reactive({
      leaflet(breweries91) %>%
        addProviderTiles("Esri.WorldTopoMap",options = providerTileOptions(maxZoom=13,minZoom=0,continuousWorld=FALSE,noWrap=TRUE)) %>%
        setView(10.5, 49.5, zoom=8) %>%
        addCircleMarkers(weight = 1, layerId = 1:nrow(breweries91),
                         popup = breweries91@data$brewery)
  })
  
  output$dt_result_ui <- renderUI({
    DT::dataTableOutput("result_tbl")
  })
  
  output$subset_ui <- renderUI({
    actionButton("subset_but", "Subset")
  })
  
  output$control_ui <- renderUI({
    selectizeInput(inputId="basemapsel", label= "Basemap:",
                   choices=list("Esri Topo"= 1, "Esri Ocean"=2), multiple=FALSE, 
                   selected = 1, options = list(allowEmptyOption=FALSE)
    )
  })
  
  output$emod_ui <- renderUI({
    editModUI("eview", width="100%", height="400px")
  })

  output$leaflet_ui <- renderUI({
    leafletOutput("lview", width="100%", height="400px")
  })
  
  editmapx <- callModule(editMod, "eview", isolate({lf0()}))
  
  observe({ 
    editmapx() 
  })
  
  observeEvent(input$basemapsel, {

    lf <- leafletProxy(ns("map")) 
    
    if (input$basemapsel == 1) {
      lf %>% addProviderTiles("Esri.WorldTopoMap",options = providerTileOptions(maxZoom=13,minZoom=0,continuousWorld=FALSE,noWrap=TRUE)) 
      
    } else { 
      lf %>% addProviderTiles("Esri.OceanBasemap",options = providerTileOptions(maxZoom=13,minZoom=0,continuousWorld=FALSE,noWrap=TRUE)) 
    }
  })   
  
  output$lview <- renderLeaflet({
    if (!initSet) {
      initSet <<- TRUE
    }
    isolate({lf0()})
  })

  output$result_tbl <- DT::renderDataTable({
    if (stat$toggleSubset) {
      datax() %...>% 
        as.data.frame() %...>%
        select(brewery, zipcode, century, id) %...>%
        DT::datatable(options = list(pageLength = 5,
                                     #initComplete = I("function(settings, json) {alert('Done.');}"),
                                     serverSide=TRUE, processing = TRUE, retrieve=TRUE),
                      escape=FALSE)
    }
  })

######## Detect event from leaflet under editMod: Marker click  
  
  em_idx <- eventReactive(input[[ns("map_marker_click")]], {  
    cevent <- input[[ns("map_marker_click")]] 
    
    if (is.null(cevent)) {
      return("click_by_emod_NONE")
    }
    paste0("click_by_emod: ",as.character(cevent$id))
  })

#### Map bounds  
  em_boundx <- eventReactive(input[[ns("map_bounds")]], { 
    if (is.null(input[[ns("map_bounds")]])) {
      return("bounds_by_emod_NONE")
    }
    paste0("bounds_by_emod: ",paste(round(unlist(input[[ns("map_bounds")]]),2), collapse = "<br/>"))
  }) 

######## Detect event from only leaflet 
  
  lf_idx <- eventReactive (input$lview_marker_click, {  
    cevent <- input$lview_marker_click 
    
    if (is.null(cevent)) {
      return("click_by_lf_NONE")
    }
    paste0("click_by_lf: ",as.character(cevent$id))
  })
  
  lf_boundx <- eventReactive(input$lview_bounds, { 
    if (is.null(input$lview_bounds)) {
      return("bounds_by_lf_NONE")
    }
    paste0("bounds_by_lf: ",paste(round(unlist(input$lview_bounds,2)), collapse = "<br/>"))
  }) 

#### Output Result, click the markers on leaflet
  output$outText <- renderUI({

    HTML(paste("From emMod: ", em_idx(), em_boundx(), #### Comment the two text outputs because it cannot work and make renderText failed.
      "From LF: ", lf_idx(), lf_boundx(), sep="<br/>"))## Only the two text outputs from leaflet "lview" works!
  })

  cancel.onSessionEnded <- session$onSessionEnded(function() {

    print("App End.. Goodbye!")
    #stopApp() 
  })
  
}

shinyApp(ui = ui, server = server)

