FROM python:3.11-slim

# Installer les dépendances système nécessaires pour Chromium headless
# Retiré : wget, curl, unzip car non utilisés pour cette installation via apt
RUN apt-get update && apt-get install -y \
    chromium-driver \
    chromium \
    && rm -rf /var/lib/apt/lists/*

# Variables d'environnement pour Chromium (souvent utile pour Selenium)
ENV CHROME_BIN=/usr/bin/chromium
# Retiré : ENV PATH="$PATH:/usr/bin" car /usr/bin est déjà dans le PATH par défaut

# Installer les dépendances Python
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copier le code de l'application
COPY . /app
WORKDIR /app

# Commande par défaut pour exécuter le script
CMD ["python", "main.py"]
