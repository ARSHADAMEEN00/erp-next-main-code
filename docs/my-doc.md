1. bench init frappe-bench version-15
2. bench new-site ameenSite --force
3. bench get-app --branch version-15 erpnext
4. bench --site ameenSite install-app erpnext
5. bench start

6. to enable dev mode :
   bench set-config developer_mode 1

7. to create new app :
   bench new-app ameen-app

8. to install app :
   bench install-app ameen-app

9. to open the db
   bench mariadb
   desc `tabClient Document`;
   select \* from `tabClient Document`;

// Terminal Deployment Steps

1.  tar -xvzf erpnext-ameen-production-final.tar.gz : extract the files
2.  docker compose --env-file .env.production -f docker-compose-production.yml up -d --build : build and run the containers
3.  docker compose up -d
4.  docker ps
5.  docker compose logs -f
    erpnext-ameen-production-fixed.tar.gz

In Server

Here is what happens automatically inside the Docker container when he runs docker-compose up -d:

Base Image: It downloads the official Frappe/ERPNext Docker image (which already contains the Frappe Framework and ERPNext code).
Your App Code: I have configured the
Dockerfile

in this package to clone your ameen_app from GitHub right during the build process.
Installation: The container then installs your ameen_app into the Frappe environment.
Database Connection: Finally, it connects to the ameen_site database on the server (which we just populated with your local data).
So relying on your ameen_app repo is perfectly fine. The Docker setup will combine:

Official Frappe/ERPNext Code (from Docker Hub)
Your Custom App Code (from your GitHub repo)
Your Data (from the server's MariaDB)

docker build --platform linux/amd64 -t ameenarshad99/erp-next-demo:v1.0 .
docker push ameenarshad99/erp-next-demo:v1.0

mysql -h 165.232.191.67 -P 3307 -u root -pameen123 --ssl-mode=DISABLED -e "SHOW DATABASES;"

//
bench setup requirements --node
ls -d apps/frappe/node_modules/socket.io

db
docker exec erpnext_db mysql -u root -padmin123 -e "CREATE DATABASE ameen_site CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

cat ameen_site_ready_dump.sql | docker exec -i erpnext_db mysql -u root -padmin123 ameen_site

docker exec erpnext_db mysql -u root -padmin123 -e "CREATE USER IF NOT EXISTS 'ameen_site'@'%' IDENTIFIED BY 'admin123'; GRANT ALL PRIVILEGES ON ameen_site.\* TO 'ameen_site'@'%'; FLUSH PRIVILEGES;"

docker restart erpnext_backend
