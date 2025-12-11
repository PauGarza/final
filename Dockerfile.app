FROM rocker/shiny:latest

WORKDIR /srv/shiny-server

# Solo los paquetes que usamos
RUN install2.r --error --skipinstalled \
    ggplot2 \
    dplyr \
    readr

# Copiamos app y datos
COPY app.R /srv/shiny-server/app.R
COPY data /srv/shiny-server/data

EXPOSE 3838
