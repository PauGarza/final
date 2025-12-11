FROM rocker/shiny:latest

# Carpeta por defecto de shiny-server
WORKDIR /srv/shiny-server

# Instalar paquetes necesarios, incluyendo arrow
RUN install2.r --error --skipinstalled \
    ggplot2 \
    dplyr \
    arrow

# Copiar app y datos
COPY app.R /srv/shiny-server/app.R
COPY data /srv/shiny-server/data

EXPOSE 3838
