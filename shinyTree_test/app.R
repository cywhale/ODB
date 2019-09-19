# shinyTree cannot render twice after re-open wellpanel
# solved by https://github.com/shinyTree/shinyTree/issues/87
library(shiny)
library(shinyTree)

ui <- fluidPage(
   titlePanel("Test Shiny Tree"),
   
   sidebarLayout(
      sidebarPanel(
        actionButton("get_tree", "Tree list")
      ),
      
      mainPanel(
        uiOutput("test_ui"),
        verbatimTextOutput("outText")
      )
   )
)

# Define server logic required to draw a histogram
server <- function(input, output) {

  treex <- structure(list(a=list(a1=1,a2=2) , b="b"), stopened = T)
  treex <- lapply(treex, function(x) structure(x, stopened = T))

  tree_selx <- eventReactive(input$tree_List,{
    req(input$tree_List) 

    return(unlist(get_selected(input$tree_List)))
  })
  
  actionx <- reactiveValues(sel=character(), toggle=FALSE)
  
  observeEvent(input$get_tree,{
    req(input$get_tree)
    
    isolate({
      actionx$toggle <- as.logical(input$get_tree>0)
    })
  })
  
  observeEvent(input$tree_apply, {
    actionx$sel <- as.character(tree_selx())
    actionx$toggle <- FALSE
  })
  
  output$outText <- renderText({
    actionx$sel
  })
  
  output$test_ui <- renderUI({
    if (actionx$toggle) {
      wellPanel(
        id = "treePanel", 
        shinyTree("tree_List", search=TRUE), 
        actionButton("tree_apply", "Apply"),
        tagList(tags$script(HTML(paste('document.getElementById(\"tree_apply\").onclick = function(){$(\"#treePanel\").hide();};',sep=""))),
                tags$script(HTML(paste('document.getElementById(\"get_tree\").onclick= function(){$(\"#treePanel\").show();}',sep=""))))
      )
    }
  })
  
  output$tree_List <- renderTree({
    input$tree_apply ## include this, that can render tree after close/open 
    treex
  })
}


# Run the application 
shinyApp(ui = ui, server = server)

