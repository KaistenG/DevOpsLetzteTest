# Basisimage
FROM python:3.11-slim

# Arbeitsverzeichnis
WORKDIR /app

# Abhängigkeiten installieren
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# App kopieren
COPY . .

# Flask starten
CMD ["python", "app.py"]