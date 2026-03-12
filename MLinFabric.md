# 🤖 Microsoft Fabric – ML Endpoints : Bonnes Pratiques

> **Contexte** : Nous utilisons Microsoft Fabric pour déployer des modèles ML en temps réel via les ML Model Endpoints (Preview).

---

## 📌 Sommaire

1. [Logging des entrées/sorties des endpoints](#1--logging-des-entréessorties-des-endpoints)
2. [Personnalisation des endpoints (preprocessing, appels DB)](#2--personnalisation-des-endpoints-preprocessing-appels-db)
3. [Workflow complet de bout en bout](#3--workflow-complet-de-bout-en-bout)

---

## 1. 📋 Logging des entrées/sorties des endpoints

### Architecture recommandée

```mermaid
flowchart LR
    A["🖥️ Client\n(App / API)"] -->|"POST JSON"| B["🔮 Endpoint Fabric\n(REST API)"]
    B --> C["🐍 Wrapper PyFunc\n(predict)"]
    C --> D["🤖 Modèle ML\n(inference)"]
    C --> E["📝 Logging"]
    E --> F["🗄️ Lakehouse /\nBlob Storage"]
    E --> G["📊 Application\nInsights"]
    D -->|"Résultat"| B
    B -->|"Réponse JSON"| A

    style C fill:#4a90d9,color:#fff
    style E fill:#f5a623,color:#fff
    style F fill:#7ed321,color:#fff
    style G fill:#7ed321,color:#fff
```

### Les 3 options possibles

```mermaid
flowchart TD
    Q{"Comment logger\nles entrées/sorties ?"}
    Q --> O1["✅ Option A\nWrapper PyFunc\n(recommandée)"]
    Q --> O2["⚙️ Option B\nLogging côté client"]
    Q --> O3["📊 Option C\nApplication Insights /\nAzure Monitor"]

    O1 --> R1["Logging dans predict()\n→ écriture Lakehouse / Blob"]
    O2 --> R2["L'appelant intercepte\nrequêtes & réponses"]
    O3 --> R3["Télémétrie automatique\ndes appels REST"]

    style O1 fill:#7ed321,color:#fff
    style O2 fill:#f5a623,color:#fff
    style O3 fill:#4a90d9,color:#fff
```

### Exemple de code (Option A – recommandée)

```python
import mlflow.pyfunc
import pandas as pd
import json, datetime

class LoggedModel(mlflow.pyfunc.PythonModel):

    def load_context(self, context):
        import joblib
        self.model = joblib.load(context.artifacts["model"])

    def predict(self, context, model_input: pd.DataFrame):
        predictions = self.model.predict(model_input)

        log_entry = {
            "timestamp": str(datetime.datetime.utcnow()),
            "input": model_input.to_dict(orient="records"),
            "output": predictions.tolist()
        }
        self._persist_log(log_entry)
        return predictions

    def _persist_log(self, log_entry):
        from azure.storage.blob import BlobServiceClient
        client = BlobServiceClient.from_connection_string("CONN_STRING")
        blob = client.get_blob_client("logs", f"inference/{{log_entry['timestamp']}}.json")
        blob.upload_blob(json.dumps(log_entry))
```

---

## 2. 🔧 Personnalisation des endpoints (preprocessing, appels DB)

### Flux d'exécution dans le wrapper

```mermaid
sequenceDiagram
    participant Client as 🖥️ Client
    participant Endpoint as 🔮 Endpoint REST
    participant Wrapper as 🐍 PyFunc Wrapper
    participant DB as 🗄️ Base de données
    participant Model as 🤖 Modèle ML

    Client->>Endpoint: POST /score (données brutes)
    Endpoint->>Wrapper: predict(model_input)

    rect rgb(230, 245, 255)
        Note over Wrapper: Phase 1 – Enrichissement
        Wrapper->>DB: SELECT features FROM ...
        DB-->>Wrapper: features complémentaires
    end

    rect rgb(255, 243, 224)
        Note over Wrapper: Phase 2 – Preprocessing
        Wrapper->>Wrapper: fillna, encoding, scaling...
    end

    rect rgb(232, 245, 233)
        Note over Wrapper: Phase 3 – Inférence
        Wrapper->>Model: model.predict(data)
        Model-->>Wrapper: prédictions
    end

    Wrapper-->>Endpoint: résultats
    Endpoint-->>Client: JSON response
```

### Structure du wrapper

```mermaid
classDiagram
    class PythonModel {
        <<mlflow.pyfunc>>
        +load_context(context)
        +predict(context, model_input)
    }

    class CustomEndpointModel {
        -model
        -db_connection
        +load_context(context)
        +predict(context, model_input)
        -_enrich_from_db(df) → DataFrame
        -_preprocess(df) → DataFrame
        -_persist_log(log_entry)
    }

    PythonModel <|-- CustomEndpointModel

    style CustomEndpointModel fill:#4a90d9,color:#fff
```

### Exemple de code complet

```python
import mlflow.pyfunc
import pandas as pd

class CustomEndpointModel(mlflow.pyfunc.PythonModel):

    def load_context(self, context):
        import joblib, pyodbc
        self.model = joblib.load(context.artifacts["model"])
        self.conn = pyodbc.connect(
            "DRIVER={ODBC Driver 18 for SQL Server};"
            "SERVER=myserver.database.windows.net;"
            "DATABASE=mydb;UID=user;PWD=pass"
        )

    def _enrich_from_db(self, df: pd.DataFrame) -> pd.DataFrame:
        ids = tuple(df["customer_id"].tolist())
        query = f"SELECT customer_id, segment, credit_score FROM customers WHERE customer_id IN {{ids}}"
        return df.merge(pd.read_sql(query, self.conn), on="customer_id", how="left")

    def _preprocess(self, df: pd.DataFrame) -> pd.DataFrame:
        df = df.fillna(0)
        df["ratio"] = df["col_a"] / (df["col_b"] + 1)
        return df

    def predict(self, context, model_input: pd.DataFrame):
        enriched  = self._enrich_from_db(model_input)
        processed = self._preprocess(enriched)
        return self.model.predict(processed)
```

### Enregistrement et déploiement

```python
import mlflow

artifacts = {"model": "path/to/trained_model.joblib"}

mlflow.pyfunc.save_model(
    path="custom_endpoint_model",
    python_model=CustomEndpointModel(),
    artifacts=artifacts,
    pip_requirements=["pandas", "scikit-learn", "pyodbc", "joblib"]
)

mlflow.register_model("runs:/<run_id>/custom_endpoint_model", "MyCustomModel")
```

---

## 3. 🚀 Workflow complet de bout en bout

```mermaid
flowchart TD
    A["1️⃣ Entraînement\ndu modèle ML"] --> B["2️⃣ Création du\nwrapper PyFunc"]
    B --> C["3️⃣ Enregistrement\nMLflow + artifacts"]
    C --> D["4️⃣ Registration dans\nle Model Registry Fabric"]
    D --> E["5️⃣ Activation de\nl'endpoint (UI / API)"]
    E --> F["6️⃣ Appel REST\npar le client"]
    F --> G{"Le wrapper\nexécute :"}
    G --> H["📂 Enrichissement DB"]
    G --> I["⚙️ Preprocessing"]
    G --> J["🤖 Inférence"]
    G --> K["📝 Logging I/O"]
    H --> J
    I --> J
    J --> L["📤 Réponse\nau client"]
    K --> M["🗄️ Lakehouse /\nBlob / App Insights"]

    style A fill:#9b59b6,color:#fff
    style B fill:#4a90d9,color:#fff
    style D fill:#f5a623,color:#fff
    style E fill:#7ed321,color:#fff
    style J fill:#e74c3c,color:#fff
    style M fill:#1abc9c,color:#fff
```

---

## 📚 Ressources

| Ressource | Lien |
|---|---|
| ML Model Endpoints | [learn.microsoft.com](https://learn.microsoft.com/en-us/fabric/data-science/model-endpoints) |
| Blog – Real-time predictions | [blog.fabric.microsoft.com](https://blog.fabric.microsoft.com/en-us/blog/serve-real-time-predictions-seamlessly-with-ml-model-endpoints/) |
| PREDICT – Batch scoring | [learn.microsoft.com](https://learn.microsoft.com/en-us/fabric/data-science/model-scoring-predict) |
| Deploy MLflow models | [learn.microsoft.com](https://learn.microsoft.com/en-us/azure/machine-learning/how-to-deploy-mlflow-models) |

---

## ✅ Synthèse

| Besoin | Solution |
|---|---|
| **Logging I/O** | Wrapper `PythonModel` → Lakehouse / Blob / App Insights |
| **Preprocessing / appels DB** | Wrapper `PythonModel` → logique custom dans `predict()` |
| **Déploiement** | Model Registry Fabric → activation endpoint → REST API |

---

*Document généré le 12/03/2026*