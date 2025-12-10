FROM rocker/shiny:latest

# Carpeta donde shiny-server busca apps
WORKDIR /srv/shiny-server

# Instalar solo los paquetes que necesitamos (sin arrow)
RUN install2.r --error --skipinstalled \
    ggplot2 \
    dplyr \
    readr

# Copiar app y datos
COPY app.R /srv/shiny-server/app.R
COPY data /srv/shiny-server/data

# Shiny escucha en 3838 por default
EXPOSE 3838
