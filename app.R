library(shiny)
library(ggplot2)
library(readr)
library(dplyr)

ui <- fluidPage(
    titlePanel("Auto MPG Explorer"),
    sidebarLayout(
        sidebarPanel(
            selectInput("xaxis", "Eje X", 
                        choices = c("weight", "horsepower", "displacement")),
            selectInput("color", "Color por", 
                        choices = c("origin", "cylinders"))
        ),
        mainPanel(plotOutput("mainPlot"))
    )
)

server <- function(input, output) {
    # Ahora leemos el CSV, no feather
    data <- readr::read_csv("data/auto_mpg.csv")

    output$mainPlot <- renderPlot({
        ggplot(data, aes_string(x = input$xaxis, y = "mpg", color = input$color)) +
            geom_point(size = 3) +
            theme_minimal()
    })
}

shinyApp(ui, server)
