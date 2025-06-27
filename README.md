# Ileo-home-assistant-scraper-
il est necessaire de lancer le docker toutes les 4 heures par exemple dans un cron
exemple :
0 0,4,8,12,16,20 * * * docker compose -f /home/docker/docker_ileo/docker-compose.yml run --rm >
