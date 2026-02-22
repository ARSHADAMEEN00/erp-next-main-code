1. move the ameen_app to server via SFTP
2. docker compose down
3. docker compose build backend worker scheduler
4. docker compose up -d
5. docker compose exec backend bench --site osperb.localhost migrate
6. docker compose exec backend bench --site osperb.localhost clear-cache
7. docker compose exec backend bench restart
8. docker exec erpnext_backend bench build