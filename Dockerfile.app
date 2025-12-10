# Imagen base con R + Shiny + shiny-server
FROM rocker/shiny:latest

# Instalamos los paquetes que usa la app
# (shiny ya viene en la imagen)
RUN R -e "install.packages(c('ggplot2', 'dplyr', 'readr', 'arrow'), repos = 'https://cloud.r-project.org')"

# Carpeta donde shiny-server busca las apps por defecto
WORKDIR /srv/shiny-server

# Copiamos la app y los datos al contenedor
COPY app.R /srv/shiny-server/app.R
COPY data /srv/shiny-server/data

# Exponemos el puerto 3838 (Shiny por defecto)
EXPOSE 3838

# No hace falta CMD: la imagen rocker/shiny ya arranca shiny-server sola
