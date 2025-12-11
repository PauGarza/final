# app.R

library(shiny)
library(ggplot2)
library(dplyr)
library(arrow)

# --------------------------------------------------------------------
# Cargar datos (ajusta la ruta si es necesario)
# --------------------------------------------------------------------
auto_mpg <- read_feather("data/clean/auto_mpg_clean_feather.feather")

auto_mpg$origin    <- as.factor(auto_mpg$origin)
auto_mpg$cylinders <- as.factor(auto_mpg$cylinders)

# --------------------------------------------------------------------
# UI
# --------------------------------------------------------------------
ui <- fluidPage(
  titlePanel("Auto MPG Explorer"),
  
  sidebarLayout(
    sidebarPanel(
      # Filtro por año de modelo
      sliderInput(
        inputId = "year_range",
        label   = "Año del modelo",
        min     = min(auto_mpg$model_year),
        max     = max(auto_mpg$model_year),
        value   = c(min(auto_mpg$model_year), max(auto_mpg$model_year)),
        step    = 1,
        sep     = ""
      ),
      
      # Filtro por cilindros
      checkboxGroupInput(
        inputId = "cyl_filter",
        label   = "Cilindros",
        choices = sort(unique(auto_mpg$cylinders)),
        selected = sort(unique(auto_mpg$cylinders))
      ),
      
      # Variable en eje X
      selectInput(
        inputId = "xaxis",
        label   = "Variable en eje X",
        choices = c(
          "Peso"              = "weight",
          "Caballos de fuerza"= "horsepower",
          "Cilindrada"        = "displacement",
          "Año del modelo"    = "model_year"
        ),
        selected = "weight"
      ),
      
      # Variable para color
      selectInput(
        inputId = "color",
        label   = "Color por",
        choices = c(
          "Origen"    = "origin",
          "Cilindros" = "cylinders"
        ),
        selected = "origin"
      )
    ),
    
    mainPanel(
      tabsetPanel(
        tabPanel("Dispersión", plotOutput("mainPlot")),
        tabPanel("Resumen", tableOutput("summaryTable"))
      )
    )
  )
)

# --------------------------------------------------------------------
# SERVER
# --------------------------------------------------------------------
server <- function(input, output, session) {
  
  # Datos filtrados según año y cilindros
  filtered_data <- reactive({
    df <- auto_mpg %>% 
      filter(
        model_year >= input$year_range[1],
        model_year <= input$year_range[2]
      )
    
    if (length(input$cyl_filter) > 0) {
      df <- df %>% filter(cylinders %in% input$cyl_filter)
    }
    
    df
  })
  
  # Gráfica principal
  output$mainPlot <- renderPlot({
    df <- filtered_data()
    
    validate(
      need(nrow(df) > 0, "No hay datos para los filtros seleccionados.")
    )
    
    ggplot(df, aes_string(x = input$xaxis, y = "mpg", color = input$color)) +
      geom_point(alpha = 0.7, size = 3) +
      theme_minimal() +
      labs(
        x = input$xaxis,
        y = "Millas por galón (mpg)",
        color = NULL
      )
  })
  
  # Tabla resumen por origen y cilindros
  output$summaryTable <- renderTable({
    filtered_data() %>%
      group_by(origin, cylinders) %>%
      summarise(
        n            = n(),
        mpg_promedio = round(mean(mpg), 2),
        .groups      = "drop"
      ) %>%
      arrange(origin, cylinders)
  })
}

# --------------------------------------------------------------------
# Lanzar app
# --------------------------------------------------------------------
shinyApp(ui, server)