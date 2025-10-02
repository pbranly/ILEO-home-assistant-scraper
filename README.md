# ILEO Home Assistant Scraper

[![GitHub](https://img.shields.io/github/license/pbranly/ILEO-home-assistant-scraper)](LICENSE)
[![Docker](https://img.shields.io/badge/docker-required-blue.svg)](https://www.docker.com/)
[![Home Assistant](https://img.shields.io/badge/home%20assistant-compatible-green.svg)](https://www.home-assistant.io/)

Un scraper Docker pour intégrer automatiquement les données ILEO dans Home Assistant.

## Description

Ce projet permet de récupérer automatiquement les informations de votre compte ILEO (collecte des déchets, calendrier de ramassage, etc.) et de les rendre disponibles dans Home Assistant pour créer des automatisations et notifications.

## Table des matières

- [Installation](#installation)
- [Configuration](#configuration)
- [Planification automatique](#planification-automatique)
- [Utilisation](#utilisation)
- [Dépannage](#dépannage)
- [Contribution](#contribution)
- [Licence](#licence)

## Installation

### Prérequis

- Docker et Docker Compose
- Home Assistant installé et accessible
- Un compte ILEO actif

### Étapes d'installation

1. **Cloner le dépôt**

```bash
git clone https://github.com/pbranly/ILEO-home-assistant-scraper.git
cd ILEO-home-assistant-scraper
```

2. **Configurer les variables d'environnement**

Modifiez le fichier `.env` à la racine du projet :

```env
# --- Identifiants site web mel-ileo ---
LOGIN=ton_email@example.com
PASSWORD="ton_mot_de_passe"

# --- Configuration MQTT ---
MQTT_HOST=192.168.x.yy
MQTT_PORT=1883
MQTT_TOPIC_BASE=eau/consommation
MQTT_RETAIN=true

# ➕ Identifiants MQTT
MQTT_USERNAME=mon_user
MQTT_PASSWORD=mon_pass

# --- Optionnel : forcer une date de départ
# FORCE_START_DATE=2025-05-01

FORCE_RESET_CACHE=false
```

3. **Lancer le conteneur**
premiere installation:
```bash
docker compose up —build
```
puis:
```bash
docker compose up -d
```

## Configuration

### Docker Compose

fichier `docker-compose.yml` :

```yaml

services:
  ileo-scraper:
    container_name: ileo-scraper
    build: .
    volumes:
      - ./app:/app
    env_file:
      - .env

    environment:
        - TZ=Europe/Paris
```

### Planification automatique

> **Important** : Il est nécessaire de lancer le scraper toutes les 4 heures pour maintenir les données à jour.

Éditez votre crontab :

```bash
crontab -e
```

Ajoutez cette ligne pour exécuter le scraper 6 fois par jour (00h, 04h, 08h, 12h, 16h, 20h) :

```bash
0 0,4,8,12,16,20 * * * docker compose -f /home/docker/docker_ileo/docker-compose.yml run --rm ileo-scraper python /app/main.py >> /var/log/ileo.log 2>&1
```

> **Note** : Adaptez le chemin `/home/docker/docker_ileo/` selon l'emplacement de votre installation.

## Utilisation


### Exemple d'automatisation

```
alias: Importer donnée eau (index fixe)
description: >
  Met à jour l’index de consommation d’eau à la date reçue et à la date actuelle
  (pour éviter valeurs négatives), et met à jour les helpers associés.
triggers:
  - topic: eau/consommation
    trigger: mqtt
actions:
  - alias: Enregistrer l’index à la date reçue + aujourd’hui
    data:
      statistic_id: sensor.index_eau
      unit_of_measurement: L
      has_mean: false
      has_sum: true
      source: recorder
      stats:
        - start: |
            {{ as_datetime(trigger.payload_json.date)
               .replace(hour=0, minute=0, second=0, microsecond=0)
               .astimezone().isoformat() }}
          sum: "{{ trigger.payload_json.index | int }}"
    action: recorder.import_statistics
  - alias: Mettre à jour le helper dernier_index_eau
    target:
      entity_id: input_number.dernier_index_eau
    data:
      value: "{{ trigger.payload_json.index | float }}"
    action: input_number.set_value
mode: single
```

### Exemple de carte Lovelace

```
type: vertical-stack
cards:
  - type: picture-elements
    image: /local/image/compteur_eau.jpg
    title: Compteur Eau
    elements:
      - type: state-label
        entity: input_number.dernier_index_eau
        style:
          left: 52%
          top: 35%
          color: black
          font-size: 190%
  - type: vertical-stack
    cards:
      - type: markdown
        content: >
          ### Consommation d' eau du  {{
          states('sensor.date_consommation_eau_jour') }}
      - type: horizontal-stack
        cards:
          - type: gauge
            entity: sensor.consommation_eau_jour
            name: Consommation  jour
            needle: true
            min: 0
            max: 1000
            unit: L
            severity:
              green: 0
              yellow: 200
              red: 500
      - type: entities
        entities:
          - type: custom:template-entity-row
            name: Coût estimé
            icon: mdi:cash
            state: >
              {% set litres = states('sensor.consommation_eau_jour') | float(0)
              %} {% set euros = (litres / 1000 * 4.4152) %} {{ euros | round(2)
              }} €
  - type: statistics-graph
    title: Consommation Eau - 14 jours glissants
    chart_type: bar
    period: day
    entities:
      - sensor.index_eau
    stat_types:
      - change
    days_to_show: 14
    hide_legend: false

```

## Dépannage

### Le conteneur ne démarre pas

```bash
# Vérifier les logs
docker compose logs ileo-scraper

# Vérifier que Docker est en cours d'exécution
systemctl status docker
```

### Les données ne s'affichent pas dans Home Assistant

1. Vérifiez l'URL de Home Assistant dans le fichier `.env`
2. Consultez les logs de Home Assistant

### La tâche cron ne s'exécute pas

```bash
# Vérifier les logs cron
grep CRON /var/log/syslog

# Lister les tâches cron actives
crontab -l

# Tester l'exécution manuelle
docker compose -f /chemin/vers/docker-compose.yml run --rm ileo-scraper
```

## Contribution

Les contributions sont les bienvenues ! 

1. Fork le projet
2. Créez votre branche (`git checkout -b feature/amelioration`)
3. Committez vos changements (`git commit -m 'Ajout d'une fonctionnalité'`)
4. Pushez vers la branche (`git push origin feature/amelioration`)
5. Ouvrez une Pull Request

## Licence

Ce projet est distribué sous licence libre. Voir le fichier [LICENSE](LICENSE) pour plus de détails.

## Support

Pour toute question ou problème, ouvrez une [issue](https://github.com/pbranly/ILEO-home-assistant-scraper/issues).

---

**Développé pour la communauté Home Assistant**
