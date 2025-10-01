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

Créez un fichier `.env` à la racine du projet :

```env
ILEO_USERNAME=votre_email@exemple.com
ILEO_PASSWORD=votre_mot_de_passe
HA_URL=http://homeassistant.local:8123
HA_TOKEN=votre_token_home_assistant
```

3. **Lancer le conteneur**

```bash
docker compose up -d
```

## Configuration

### Docker Compose

Exemple de fichier `docker-compose.yml` :

```yaml
version: '3.8'

services:
  ileo-scraper:
    build: .
    container_name: ileo-scraper
    env_file:
      - .env
    restart: no
```

### Planification automatique

> **Important** : Il est nécessaire de lancer le scraper toutes les 4 heures pour maintenir les données à jour.

Éditez votre crontab :

```bash
crontab -e
```

Ajoutez cette ligne pour exécuter le scraper 6 fois par jour (00h, 04h, 08h, 12h, 16h, 20h) :

```bash
0 0,4,8,12,16,20 * * * docker compose -f /home/docker/docker_ileo/docker-compose.yml run --rm ileo-scraper
```

> **Note** : Adaptez le chemin `/home/docker/docker_ileo/` selon l'emplacement de votre installation.

## Utilisation

### Entités créées dans Home Assistant

Le scraper crée les entités suivantes :

- `sensor.ileo_prochaine_collecte` : Date de la prochaine collecte
- `sensor.ileo_type_collecte` : Type de déchets à sortir
- `sensor.ileo_dernier_update` : Horodatage de la dernière mise à jour

### Exemple d'automatisation

```yaml
automation:
  - alias: "Notification collecte déchets"
    trigger:
      - platform: state
        entity_id: sensor.ileo_prochaine_collecte
    condition:
      - condition: template
        value_template: "{{ (as_timestamp(states('sensor.ileo_prochaine_collecte')) - as_timestamp(now())) < 86400 }}"
    action:
      - service: notify.mobile_app
        data:
          title: "Rappel collecte des déchets"
          message: "La collecte est prévue demain : {{ states('sensor.ileo_type_collecte') }}"
```

### Exemple de carte Lovelace

```yaml
type: entities
title: Collecte des déchets
entities:
  - entity: sensor.ileo_prochaine_collecte
  - entity: sensor.ileo_type_collecte
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

1. Vérifiez que le token Home Assistant est valide
2. Vérifiez l'URL de Home Assistant dans le fichier `.env`
3. Consultez les logs de Home Assistant

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
