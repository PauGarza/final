#!/usr/bin/env bash
set -euo pipefail

RAW_FILE="data/auto-mpg.data"
CSV_FILE="data/auto-mpg_clean.csv"

URL1="https://archive.ics.uci.edu/ml/machine-learning-databases/auto-mpg/auto-mpg.data"
URL2="https://raw.githubusercontent.com/mwaskom/seaborn-data/master/mpg.csv"  # respaldo, pero OJO: ya viene en CSV

echo "Intentando descargar dataset original de UCI..."
if curl -fSL --retry 5 --retry-delay 2 "$URL1" -o "$RAW_FILE"; then
  echo "Descarga desde UCI exitosa: $RAW_FILE"

  ########################################
  # Limpieza con tr / sed / grep
  ########################################
  {
    echo "mpg,cylinders,displacement,horsepower,weight,acceleration,model_year,origin,car_name"

    grep -v '\?' "$RAW_FILE" | \
    tr -s ' ' ' '            | \
    sed 's/^ *//'            | \
    sed 's/ /,/g'            | \
    sed 's/^,//g'
  } > "$CSV_FILE"

  echo "Listo: $CSV_FILE generado a partir del archivo de UCI."

else
  echo "No se pudo descargar desde UCI (502/otro error)."
  echo "Usando dataset de respaldo (ya en CSV) desde GitHub..."

  curl -fSL --retry 5 --retry-delay 2 "$URL2" -o "$CSV_FILE"

  echo "OJO: $CSV_FILE ya viene limpio y con encabezados (formato seaborn)."
fi
