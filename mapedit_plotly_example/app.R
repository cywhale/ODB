# Test plotly on absolutePanel in mapview/mapedit

library(shiny)
library(sf)
library(leaflet)
library(mapview)
library(mapedit)
library(magrittr)
library(plotly)

# Define UI for application 
ui <- fluidPage(
  
  fluidRow(
    uiOutput("emod_ui")
  ),
  div(id="paneldiv", uiOutput("plotProfile_ui"))
)

server <- function(input, output) {
  
  geopoly <- c(
    123.5, 132.25, 132.25, 123.5, 123.5,
    26.5, 26.5, 32.75,  32.75,  26.5
  ) %>% matrix(ncol=2,byrow=FALSE) %>% list() %>%
    st_polygon() %>%
    st_sfc(crs = 4326) 
  
  p <- plot_ly(data=data.frame(ID=letters[1:5], val=sample(100,5)), 
               labels = ~ID, values = ~val, type = 'pie') %>%
    layout(title = '',
           xaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE),
           yaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE))  
  
  userAction <- reactiveValues(pclick=FALSE)
  
  ns <- shiny::NS("eview") 
  
  #### Initialize leaflet map  
  lf0 <- reactive({
    leaflet() %>% addTiles() %>% setView(130, 30, zoom=5) %>%
      addProviderTiles(provider = providers$CartoDB.DarkMatter, group="CartoDB_Dark") %>%
      addPolygons(data=geopoly) 
  })
  
  output$emod_ui <- renderUI({
    editModUI("eview", width="100%", height="800px")
  })
  
  output$plotProfile_ui <- renderUI({
    if (userAction$pclick) {
      absolutePanel(id = "panel1", class = "panel panel-default", fixed = FALSE,
                    draggable = TRUE, top = 115, left = 55, right = "auto", bottom = "auto",
                    width = 480, height = "auto",
                    style = "overflow-y:scroll; max-height: 400px; padding: 0px; z-index:1000 !important; position: fixed; bottom: 5%;", 
                    
                    plotlyOutput("plotly_out", height="350px", width="100%"),
                    
                    hr(),
                    div(tags$div(style="display:inline-block", actionButton("but_ok", "Apply")),
                        tagList(tags$script(HTML(paste('document.getElementById(\"but_ok\").onclick = function(){$(\"#panel1\").hide();};',sep=""))))
                    )      
      )
    } 
  })    
  
  output$plotly_out <- renderPlotly({ 
    p
  }) 
  
  observe({
    callModule(editMod, "eview", isolate({lf0()}))
  })
  
  observeEvent({input[[ns("map_shape_click")]]}, { 
    req(input[[ns("map_shape_click")]])
    pievent <- input[[ns("map_shape_click")]]
    if (!userAction$pclick) userAction$pclick <- TRUE
  })  
  
  observeEvent(input$but_ok, {
    req(input$but_ok)
    if (userAction$pclick) userAction$pclick <- FALSE
  })
}

# Run the application 
shinyApp(ui = ui, server = server)
