library(shiny)
library(ggplot2)
library(dplyr)
library(arrow)

# ============================
# Cargar datos una sola vez
# ============================
data_all <- arrow::read_feather("data/auto_mpg_clean_feather.feather")

# Rangos para los controles
year_min <- min(data_all$model_year, na.rm = TRUE)
year_max <- max(data_all$model_year, na.rm = TRUE)

mpg_min  <- floor(min(data_all$mpg, na.rm = TRUE))
mpg_max  <- ceiling(max(data_all$mpg, na.rm = TRUE))

cyl_vals    <- sort(unique(data_all$cylinders))
origin_vals <- sort(unique(data_all$origin))

# ============================
# UI
# ============================
ui <- fluidPage(
  titlePanel("Auto MPG Explorer"),

  sidebarLayout(
    sidebarPanel(
      h4("Controles de visualización"),

      selectInput(
        "xaxis", "Eje X:",
        choices = c(
          "Peso"        = "weight",
          "Caballos"    = "horsepower",
          "Cilindrada"  = "displacement"
        ),
        selected = "weight"
      ),

      selectInput(
        "color", "Color por:",
        choices = c(
          "Origen"    = "origin",
          "Cilindros" = "cylinders"
        ),
        selected = "origin"
      ),

      hr(),
      h4("Filtros"),

      sliderInput(
        "year_range", "Año del modelo:",
        min = year_min, max = year_max,
        value = c(year_min, year_max),
        step = 1, sep = ""
      ),

      sliderInput(
        "mpg_range", "Rango de mpg:",
        min = mpg_min, max = mpg_max,
        value = c(mpg_min, mpg_max)
      ),

      checkboxGroupInput(
        "cyl_filter", "Cilindros:",
        choices = cyl_vals,
        selected = cyl_vals,
        inline = TRUE
      ),

      checkboxGroupInput(
        "origin_filter", "Origen:",
        choices = origin_vals,
        selected = origin_vals
      )
    ),

    mainPanel(
      tabsetPanel(
        tabPanel(
          "Gráfica",
          br(),
          plotOutput("mainPlot", height = "450px")
        ),
        tabPanel(
          "Resumen",
          br(),
          strong(textOutput("n_obs_text")),
          br(),
          tableOutput("summaryTable")
        ),
        tabPanel(
          "Datos (primeras filas)",
          br(),
          tableOutput("headTable")
        )
      )
    )
  )
)

# ============================
# SERVER
# ============================
server <- function(input, output, session) {

  # --------------------------
  # Datos filtrados
  # --------------------------
  filtered_data <- reactive({
    df <- data_all

    # año
    df <- df %>%
      filter(
        model_year >= input$year_range[1],
        model_year <= input$year_range[2]
      )

    # mpg
    df <- df %>%
      filter(
        mpg >= input$mpg_range[1],
        mpg <= input$mpg_range[2]
      )

    # cilindros
    if (!is.null(input$cyl_filter) && length(input$cyl_filter) > 0) {
      df <- df %>% filter(cylinders %in% input$cyl_filter)
    }

    # origen
    if (!is.null(input$origin_filter) && length(input$origin_filter) > 0) {
      df <- df %>% filter(origin %in% input$origin_filter)
    }

    df
  })

  # --------------------------
  # Gráfica principal
  # --------------------------
  output$mainPlot <- renderPlot({
    df <- filtered_data()

    ggplot(df, aes_string(x = input$xaxis, y = "mpg", color = input$color)) +
      geom_point(alpha = 0.7, size = 3) +
      theme_minimal(base_size = 14) +
      labs(
        x = input$xaxis,
        y = "mpg (millas por galón)",
        color = "Grupo"
      )
  })

  # --------------------------
  # Resumen numérico
  # --------------------------
  output$n_obs_text <- renderText({
    n <- nrow(filtered_data())
    paste("Observaciones después de filtros:", n)
  })

  output$summaryTable <- renderTable({
    df <- filtered_data()

    df %>%
      summarise(
        `mpg promedio`        = mean(mpg, na.rm = TRUE),
        `peso promedio`       = mean(weight, na.rm = TRUE),
        `hp promedio`         = mean(horsepower, na.rm = TRUE),
        `cilindrada promedio` = mean(displacement, na.rm = TRUE)
      ) %>%
      round(2)
  })

  # --------------------------
  # Vista rápida de los datos
  # --------------------------
  output$headTable <- renderTable({
    head(filtered_data(), 10)
  })
}

shinyApp(ui = ui, server = server)
