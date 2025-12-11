library(shiny)
library(ggplot2)
library(dplyr)
library(arrow)

ui <- fluidPage(
  titlePanel("Auto MPG Explorer"),
  sidebarLayout(
    sidebarPanel(
      selectInput("xaxis", "Eje X",
                  choices = c("weight", "horsepower", "displacement")),
      selectInput("color", "Color por",
                  choices = c("origin", "cylinders"))
    ),
    mainPanel(
      plotOutput("mainPlot")
    )
  )
)

server <- function(input, output) {

  # Leemos el feather directamente
  data <- arrow::read_feather("data/auto_mpg.feather")

  output$mainPlot <- renderPlot({
    ggplot(data, aes_string(x = input$xaxis, y = "mpg", color = input$color)) +
      geom_point(size = 3) +
      theme_minimal()
  })
}

shinyApp(ui = ui, server = server)
