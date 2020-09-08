
Summary
-----------------------------------------------

This MVP demonstates a MySQL server (storing and serving data) and a Webapp server (accepting user input and displaying database record), in seperate docker containers

Usage
-----------------------------------------------

**Prerequisite**: the host system should have Docker installed. 

In addition, on Mac, the `Docker Desktop` needs to be running. 

Similarly, on Linux, the docker daemon needs to be running. If `docker version` command complains that it can't connect to the daemon, you need to start it by 
```
sudo dockerd &
```
to get it running in the background.

## Download project files

```
# create project smartmvp from GitHub repository
git clone https://github.com/herbertyz/smartmvp.git smartmvp
```

## Run

#### Option 1 - using docker-compose

Using docker-compose and the YAML file (`docker-compose.yml`) located under project root, one can bring up and down the entire service (DNS, MySQL server and Webapp server) with one command.

To start, 

```
#  <project directory>
cd smartmvp

docker-compose up
```

Note: since Docker starts both containers (`smartdb_1` & `smartview_1`) in parallel, the Webapp server might attempt to connect to MySQL before the database is ready to accept connections. If this happen, the Webapp server will emit a panic and exit with code 2. Don't worry, Docker will try to restart the service after some short time. 

After the log info from `smartdb_1` shows `/usr/sbin/mysqld: ready for connections`, our web server `smartview_1` will come to life by reporting `server running on port :8080`.

This is the hint that you can now point your web browser to `localhost:8080` to issue requests to our webserver. Your landing page will provide more information and examples of usage.


To tearing down all these services, simply execute follow command from the project root directory
```
docker-compose down --remove-orphans
```
Note: if the previous docker-compose is running in the foreground, you can use `CTRL-C` to stop those process to get the terminal back, or you can use a different terminal. 

The `docker-compose down` command will stop and remove containers. In addition, it will remove the private network defined in the YAML file.

#### Option 2 - build and run docker individually

To build docker image, run following command from your project root directory
```
#  <project directory>
cd smartmvp

docker build -f sqldb/dockerfile.db -t smartdb sqldb/.
docker build -f goviewer/Dockerfile -t smartview goviewer/.
```

To bring up a private network so that our two servers can connect to it and communicate with each other
```
docker network create smartnet
```

To bring up MySQL server
```
docker container run -d --name smartdb_1 -p 3306:3306 --network smartnet smartdb

# check MySQL server log
docker container logs -f smartdb_1
```

After the log info from `smartdb_1` shows `/usr/sbin/mysqld: ready for connections`, you can use `CTRL-C` to stop showing log and move on to bring up our webapp server
```
docker container run -d --network smartnet --name smartview_1 -p 8080:8080 smartview

# check Webapp server log
docker container logs -f smartview_1
```

Now you can now point your web browser to `localhost:8080` and issue requests. Your landing page will provide more information and examples of usage.

After done, following are optional commands for cleaning up containers, images and system.
```
docker container rm -f smartview_1
docker container rm -f smartdb_1

docker image rm smartdb smartview

docker system prune -f
```

Architecture and Design
-----------------------------------------------

## Database server

Upon starting the MySQL server, tables are created, all 3 CSV files ingested, and view defined.

Basic configuration of the server is done via the environment variables in docker image definition (`dockerfile.db`), including root password, user account/password, and database name. Additional server configuration is achieved via `mysqld.cnf` to allow loading data from CSV files. 

All source file for bring up DB server is under `sqldb` directory

```
./dockerfile.db                 - docker file for building the image
./lead_users.csv                - data as supplied
./lead_user_sessions.csv        - data as supplied
./lead_user_responses_v2.csv    - data srubbed (5 rows fixed for the session_id field)
./schemas.sql                   - (MySQL statement) schemas as supplied
./loaddata.sql                  - (MySQL statement) Load data in CSV files into db
./createview.sql                - (MySQL statement) create a view joining data across 3 tables
./mysqld.cnf                    - MySQL server config file to enable loading data from CSV files
```

MySQL accepts connection on TCP port 3306 by default.

## Webapp server

The web host is implemented in Golang. It listens on port 8080, accept commands and paramenters via URL. Data is served via HTML/CSS.

All source file for bring up DB server is under `goviewer` directory

```
./src/main/main.go          - Simple web host in Golang
./templates/index.html      - Home page (index.html for this web site)
./templates/view.html       - Page to display lead view data
./assets/css/tachyons.css   - CSS style sheet from https://tachyons.io/
./assets/img/keyhole.jpg    - Background image (the Keyhole near Longs Peak, CO) to make home page more interesting
```
