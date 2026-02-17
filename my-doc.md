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

mysql -h 165.232.191.67 -P 3307 -u root -p
mysql -u root -e "SHOW DATABASES;"
mysql -u root -padmin123 -e "SHOW DATABASES;"
mysql -h 127.0.0.1 -P 3306 -u root -e "SHOW DATABASES;"
mysql -h 127.0.0.1 -P 3306 -u root -padmin123 -e "SHOW DATABASES;"
for p in admin 123 password frappe; do mysql -u root "-p$p" -e "status" && echo "Success with $p" && break; done

mysql -u root -p123 -e "SHOW DATABASES;"
mysql -u root -p123 -D \_91cdd60c3a4ccc62 -e "SHOW TABLES LIKE 'tabClient%';"
mysql -u root -p123 -D \_91cdd60c3a4ccc62 -e "SHOW TABLES LIKE 'tabClient%';"
mysql -u root -p123 -D \_bd6bd311f61aa29c -e "SHOW TABLES LIKE 'tabClient%';"
mysql -h 165.232.191.67 -P 3307 -u root -padmin123 -e "SHOW DATABASES LIKE 'ameen%';"
ping -c 3 165.232.191.67
nc -zv 165.232.191.67 3307
nc -zv 165.232.191.67 3306
lsof -i -P | grep LISTEN | grep 330
netstat -an | grep 3307
docker inspect erpnext_backend | grep DB_HOST -A 5
docker exec erpnext_backend bash -c "mysql -h 165.232.191.67 -P 3307 -u root -padmin123 -e 'status'"
mysqldump -u root -p123 \_91cdd60c3a4ccc62 > ameen_site_dump.sql
mv ameen_site_dump.sql ameenSite_local_dump.sql

head -n 20 ameenSite_local_dump.sql
