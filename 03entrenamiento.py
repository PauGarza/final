import pandas as pd
import pyarrow.feather as feather
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_squared_error, r2_score
import joblib

# ==============================
# 1. Cargar datos desde Feather
# ==============================

print("=== Carga de datos ===")
data = feather.read_feather("data/auto_mpg_clean_feather.feather")
print(f"Filas: {data.shape[0]}, Columnas: {data.shape[1]}")
print("Primeras filas del dataset:")
print(data.head(), "\n")

# Si existe origin, mostramos su distribución
if "origin" in data.columns:
    print("Distribución de 'origin' antes del One-Hot Encoding:")
    print(data["origin"].value_counts(), "\n")

# ==============================
# 2. One-Hot Encoding de 'origin'
# ==============================

print("=== One-Hot Encoding de 'origin' ===")
if "origin" in data.columns:
    data_encoded = pd.get_dummies(data, columns=["origin"], drop_first=True)
else:
    print("⚠️ Columna 'origin' no encontrada, se continúa sin codificar categóricas.")
    data_encoded = data.copy()

print("Columnas después del encoding:")
print(data_encoded.columns.tolist(), "\n")

# ==============================
# 3. Definir X (features) e y (target)
# ==============================

print("=== Definición de variables X (features) e y (target) ===")
y = data_encoded["mpg"]

X = data_encoded.drop(columns=["mpg"])
X = X.select_dtypes(include=["number"])  # solo numéricas

feature_cols = X.columns.tolist()
print("Columnas usadas como features:")
for col in feature_cols:
    print(f"  - {col}")
print()

# ==============================
# 4. Train / Test Split
# ==============================

print("=== Train / Test Split (80% / 20%) ===")
X_train, X_test, y_train, y_test = train_test_split(
    X,
    y,
    test_size=0.2,
    random_state=42
)

print(f"Tamaño X_train: {X_train.shape}")
print(f"Tamaño X_test : {X_test.shape}")
print(f"Tamaño y_train: {y_train.shape}")
print(f"Tamaño y_test : {y_test.shape}\n")

# ==============================
# 5. Entrenar RandomForestRegressor
# ==============================

print("=== Entrenando RandomForestRegressor ===")
model = RandomForestRegressor(
    n_estimators=100,
    random_state=42
)
model.fit(X_train, y_train)
print("Entrenamiento completado.\n")

# ==============================
# 6. Evaluación: MSE y R² en test
# ==============================

print("=== Evaluación en el set de prueba ===")
y_pred = model.predict(X_test)

mse = mean_squared_error(y_test, y_pred)
r2 = r2_score(y_test, y_pred)

print(f"MSE: {mse:.3f}")
print(f"R² : {r2:.3f}\n")

# Importancia de variables (ayuda a interpretar el modelo)
importances = pd.Series(model.feature_importances_, index=feature_cols).sort_values(ascending=False)
print("Importancia de las variables (feature importances):")
print(importances, "\n")

# ==============================
# 7. Guardar modelo y columnas
# ==============================

print("=== Guardando artefactos del modelo ===")
joblib.dump(model, "data/model.pkl")
joblib.dump(feature_cols, "data/model_columns.pkl")
print("Modelo guardado en: data/model.pkl")
print("Columnas de entrenamiento guardadas en: data/model_columns.pkl")
print("\n✅ Proceso completado correctamente.")
