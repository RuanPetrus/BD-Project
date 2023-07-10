# Database
Creating tables and schemas
``` sh
psql -h hostname -d database_name -U user_name -p 5432 -a -q -f filepath
```
In my case running on docker
``` sh
psql -h 172.17.0.2 -d emigue -U postgres -p 5432 -a -q -f ./sql/create_tables.sql
```

``` sh
psql -h ep-floral-mode-881681-pooler.us-east-1.postgres.vercel-storage.com -d verceldb -U default -p 5432 -a -q -f ./sql/create_tables.sql
```


# Development
Postgres
```sh
sudo docker run --name local-postgres -e POSTGRES_PASSWORD=1234 -d postgres
```
If you want to go inside postgres.
```sh
docker exec -it local-posgres bash
```

If you want to see network information
```sh
docker inspect local-postgres
```

PGADMIN
```sh
sudo docker pull dpage/pgadmin4:latest
sudo docker run --name local-pgadmin -p 5051:80 -e "PGADMIN_DEFAULT_EMAIL=xastroboyx11@gmail.com" -e "PGADMIN_DEFAULT_PASSWORD=1234" -d dpage/pgadmin4
```
