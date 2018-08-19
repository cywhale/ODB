# Problem for leaflet, and use sf feature, drawn polygons, to get data 
# modified codes from https://github.com/r-spatial/mapedit/issues/69
# Updates: 20180819: Handles for removing-polygon operation #mapedit

#### Testing parameters
#options(shiny.trace=TRUE) ## for debug

library(data.table)
library(magrittr)
library(shiny)
library(sf)
library(leaflet)
library(mapview)
library(mapedit)
library(DT)

ui <- fluidPage(
  fluidRow(
    column(5, 
           fluidRow(
             uiOutput("subset_ui")
           ),
           hr(),
           fluidRow(
             uiOutput("dt_result_ui")
           ),
           hr(),
           fluidRow(
             htmlOutput("outText")
           )
    ),
    column(7,
           fluidRow(
             uiOutput("emod_ui")
           )
    )
  )
)

server <- function(input, output, session) {
  
  #tempRD <- paste0(tempfile(), ".rds") ## only for debugging
  #print(tempRD)  
  ## Using reactiveValues to store intersected data got from polygons ##
  qryx <- reactiveValues(data=data.table(), msg=c(), msgflag=FALSE, ## message only for debug
                         rmflag=0L) # when doing remove poly op, trigger re-plot leaflet
  
  ns <- shiny::NS("eview") 
  
  initSet <- FALSE
  
  #### Initialize Dataset
  datax <- reactive ({
    dt <- st_as_sf(breweries91) 
    coords <- st_coordinates(dt)
    setDT(dt) %>%
      .[,`:=`(longitude = coords[,1], latitude = coords[,2], id=.I)]
  })
  
  #### Subset dataset from polygons drawn, set a flag "inpoly", indicating polygon id  
  # datapolyx <- reactive ({
  ## Move this functions into observe(), and store data in qryx$data
  ##}) 
  
  #### Initialize leaflet map  
  lf0 <- reactive({
    datax() %>%
      leaflet() %>%
      addProviderTiles("Esri.WorldTopoMap",options = providerTileOptions(maxZoom=13, minZoom=0, continuousWorld=FALSE, noWrap=TRUE)) %>%
      setView(10.5, 49.5, zoom=8) %>%
      addCircleMarkers(weight = 1, layerId = ~id, popup = ~as.character(id)) 
  })
  
  #### When user's polygons are all ready, submit it, and get data
  output$subset_ui <- renderUI({
    actionButton("subset_but", "Subset")
  })
  
  observeEvent({input$subset_but; qryx$rmflag}, { ## Renew subsetting data and redraw leaflet map
    req(!(is.null(input$subset_but) | !initSet)) 
    lf <- leafletProxy(ns("map")) %>% clearMarkers() %>% clearPopups()
    dt <- qryx$data #datapolyx()
    pal<- colorFactor('Set1', unique(dt$inpoly), na.color="grey")
    
    dt %>%
      addCircleMarkers(data = ., map = lf, 
                       weight = 1, layerId = ~id, fillOpacity = 0.5,
                       color = ~pal(inpoly),
                       popup = ~paste0(id, ifelse(is.na(inpoly),"", paste0(" within ", inpoly)))) 
  })
  
  output$emod_ui <- renderUI({
    editModUI("eview", width="100%", height="480px")
  })
  
  #### mapedit module
  observe({ 
    if (!initSet) {
      initSet <<- TRUE
      qryx$data<- datax() %>% .[,`:=`(inpoly = NA_character_)]
    }
    callModule(editMod, "eview", isolate({lf0()}))
  })
  
  #### Render Output Table  
  output$dt_result_ui <- renderUI({
    DT::dataTableOutput("result_tbl")
  })
  
  output$result_tbl <- DT::renderDataTable({
    dt <- qryx$data #datapolyx() 
    pal<- colorFactor('Set1', unique(dt$inpoly), na.color="grey")
    
    dt %>% .[,.(id,longitude,latitude,inpoly)] %>%
      DT::datatable(colnames=c("ID","lng","lat","polyIDs"),
                    options = list(pageLength = 5, serverSide=TRUE, processing = TRUE, retrieve=TRUE),
                    escape=FALSE)
  })
  
  #### Detect event from leaflet under editMod: Marker click  
  em_idx <- reactive({
    req(input[[ns("map_marker_click")]])
    cevent <- input[[ns("map_marker_click")]] 
    qryx$msgflag <- FALSE
    
    paste0("click_by_emod: ",as.character(cevent$id))
  })
  
  #### Map bounds  
  em_boundx <- reactive({
    req(input[[ns("map_bounds")]])
    paste0("bounds_by_emod: ",paste(round(unlist(input[[ns("map_bounds")]]),2), collapse = "<br/>"))
  }) 
  
  #### Get Polygon drawn
  # https://github.com/r-spatial/mapedit/issues/56  
  #  EVT_DRAW <- "map_draw_new_feature"
  #  EVT_EDIT <- "map_draw_edited_features"
  #  EVT_DELETE <- "map_draw_deleted_features"
  # https://github.com/bhaskarvk/leaflet.extras/issues/96
  #
  observeEvent(input[[ns("map_draw_deleted_features")]], {
    req(!(is.null(input$subset_but) | !initSet)) 
    qryx$rmflag <- qryx$rmflag + 1L
  })
  
  # get_sfpolyx <- eventReactive(
  observe({ #Event(input[[ns("map_draw_all_features")]], {
    req(!(is.null(input$subset_but) | !initSet)) 
    req(input[[ns("map_draw_all_features")]]) 
    
    nf <- input[[ns("map_draw_all_features")]]

    #only for debug
    # print(str(nf$features))

    qryx$msgflag <- TRUE
    
    if (is.null(nf) | is.null(nf$features) | length(nf$features)==0) {
      qryx$msg <- "No polygon drawn. Check it!"
      qryx$data<- datax() %>% .[,`:=`(inpoly = NA_character_)]
    } else {
      nfr <- do.call(rbind,sapply(seq_along(nf$features), function(x) {
        st_sf(id=nf$features[x][[1]]$properties$`_leaflet_id`,
              type=nf$features[x][[1]]$geometry$type,
              geom=sf::st_geometry(mapedit:::st_as_sfc.geo_list(nf$features[x][[1]])),
              crs=st_crs(4326))
      }, simplify=FALSE))
      
      #only for debug
      #saveRDS(nfr, file=tempRD)
      #return(nfr)
      
      sj <- as.data.frame(st_join(st_as_sf(breweries91), nfr, join = st_intersects)) 
      qryx$msg <- paste0("Fetch data within polygons (",length(nf$features),")") ## Output message
      ## Need handle intersection of multiple polygons  
      qryx$data<- datax() %>% merge(setDT(sj) %>% .[,.(brewery, id)] %>% setnames(2,"polyID"), by="brewery", all=TRUE) %>%
        .[,{.(inpoly=ifelse(all(is.na(polyID)), NA_character_, paste(na.omit(polyID), collapse=",")))}, by=.(brewery, id, longitude, latitude)]
    } 
  })
  
  
  #### Debugging Text Output
  output$outText <- renderUI({
    msg <- ifelse(qryx$msgflag, paste(qryx$msg,sep="<br/>"),
                    paste("From emMod: ", em_idx(), em_boundx(),sep="<br/>"))
    HTML(msg)
  })
  
  cancel.onSessionEnded <- session$onSessionEnded(function() {
    
    print("App End.. Goodbye!")
  })
}

shinyApp(ui = ui, server = server)
