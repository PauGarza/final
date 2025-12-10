from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import pandas as pd
import joblib
from typing import List

app = FastAPI(
    title="API de Predicción de mpg",
    description="API REST para predecir la eficiencia (mpg) de autos usando RandomForest",
    version="1.0.0"
)

# ==============================
# Cargar modelo y columnas
# ==============================

model = joblib.load("data/model.pkl")             # cambia a model_mpg.pkl si tu archivo se llama así
model_cols: List[str] = joblib.load("data/model_columns.pkl")

# Historial simple de predicciones (en memoria)
prediction_history: List[float] = []


# ==============================
# Esquema de entrada (Pydantic)
# ==============================

class CarFeatures(BaseModel):
    cylinders: int
    displacement: float
    horsepower: float
    weight: float
    acceleration: float
    model_year: int
    origin: str  # puede venir como "USA", "Europe", "Japan" o "1", "2", "3"


# ==============================
# Helper para normalizar origin
# ==============================

def normalize_origin(origin_value: str) -> str:
    """
    Acepta:
    - "USA", "usa", "UsA", etc.
    - "Europe", "EUROPE", etc.
    - "Japan", "japan", etc.
    - "1", "2", "3" (del dataset original: 1=USA, 2=Europe, 3=Japan)
    y regresa siempre "USA", "Europe" o "Japan".
    """
    s = str(origin_value).strip().lower()

    # numérica como string
    if s.isdigit():
        num = int(s)
        if num == 1:
            return "USA"
        elif num == 2:
            return "Europe"
        elif num == 3:
            return "Japan"

    # texto
    if s in ["usa", "us", "united states", "eeuu", "e.e.u.u."]:
        return "USA"
    if s in ["europe", "eu", "europa"]:
        return "Europe"
    if s in ["japan", "jp", "japón", "japon"]:
        return "Japan"

    raise HTTPException(
        status_code=400,
        detail=f"Valor de origin no reconocido: {origin_value}. Usa 'USA', 'Europe', 'Japan' o 1/2/3."
    )


# ==============================
# Endpoint raíz (opcional)
# ==============================

@app.get("/")
def read_root():
    return {
        "message": "API de predicción de mpg funcionando.",
        "endpoints": ["/predict", "/stats"]
    }


# ==============================
# /predict
# ==============================

@app.post("/predict")
def predict(car: CarFeatures):
    """
    Recibe las características de un auto y devuelve la predicción de mpg.
    origin puede venir como texto o número.
    """
    # Normalizar origin
    origin_norm = normalize_origin(car.origin)

    # Crear DataFrame con una sola fila
    data_dict = car.dict()
    data_dict["origin"] = origin_norm  # sobrescribimos con la versión normalizada

    df = pd.DataFrame([data_dict])

    # One-Hot Encoding de 'origin' igual que en entrenamiento
    # (si en tu entrenamiento no se usó origin, esto igual no rompe nada)
    df_encoded = pd.get_dummies(df, columns=["origin"], drop_first=True)

    # Reindexar para que las columnas coincidan EXACTAMENTE con las del modelo
    df_final = df_encoded.reindex(columns=model_cols, fill_value=0)

    # Predicción
    pred = float(model.predict(df_final)[0])

    # Guardamos en historial en memoria
    prediction_history.append(pred)

    return {
        "mpg_prediction": pred,
        "used_columns": model_cols
    }


# ==============================
# /stats
# ==============================

@app.get("/stats")
def stats():
    """
    Muestra estadísticas simples de las predicciones hechas hasta ahora:
    - count
    - mean
    - min
    - max
    """
    if len(prediction_history) == 0:
        return {
            "count": 0,
            "mean": None,
            "min": None,
            "max": None,
            "message": "Aún no se han hecho predicciones."
        }

    preds = prediction_history

    return {
        "count": len(preds),
        "mean": sum(preds) / len(preds),
        "min": min(preds),
        "max": max(preds)
    }
