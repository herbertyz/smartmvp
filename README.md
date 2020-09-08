
# Summary
-----------------------------------------------

This MVP demonstates a MySQL server (storing and serving data) and a Webapp server (accepting user inputs and displaying database records), in seperate docker containers.

Once all up and running, the Webapp server can be accessed via `localhost:8080`. It connects to the database via MySQL server's default port `3306`.  



# Usage
-----------------------------------------------

**Prerequisite**: the host system should have `Docker Engine` and, if you want to use docker-compose as described below, `Docker Compose` installed. 

On Mac, `Docker Desktop` installation include both. It needs to be running and ready. 

On Linux, those two items are usually installed via separate commands. Furthermore, you might need to start docker daemon manually. If `docker version` command complains that it can't connect to the daemon, you need to start it by 
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

Using docker-compose and the YAML file (`docker-compose.yml`) located under project root, one can bring up and down all necessary services (DNS, MySQL server and Webapp server) with one simple commandline.

To start, 

```
#  Get into our project directory
cd ./smartmvp

docker-compose up
```

Note: since Docker starts both containers (`smartdb_1` & `smartview_1`) in parallel, the Webapp server might attempt to connect to MySQL before the database is ready to accept connections. If this happen, the Webapp server will emit a panic and exit with code 2. Don't worry if you witness this in system logs. Docker will attempt to restart our Webapp service after some short wait. 

After the log info from `smartdb_1` shows `/usr/sbin/mysqld: ready for connections`, our web server `smartview_1` will return to good health by reporting `server running on port :8080`.

This is the hint that you can now point your web browser to `localhost:8080`, and start issuing requests to our webserver. The landing page will provide information about the request format along with examples.

To tearing down all these services, simply execute follow command from the project root directory
```
docker-compose down --remove-orphans
```
Note: if the previous docker-compose is running in the foreground, you can use `CTRL-C` to stop it and get your terminal back. Alternatively, you can use a different terminal to invoke `docker-compose down`. 

The `docker-compose down` command will stop and remove containers. In addition, it will remove the private network defined in the YAML file.

#### Option 2 - build and run docker individually

To build docker image, run following command from your project root directory
```
#  after we just clone the github repo
cd ./smartmvp

# from our MVP project root directory
docker build -f sqldb/dockerfile.db -t smartdb sqldb/.
docker build -f goviewer/Dockerfile -t smartview goviewer/.
```

To bring up a private network (called `smartnet`) so that our two servers can connect to its DNS and communicate with each other by hostname (i.e. the container names used by Docker)
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

Now you can now point your web browser to `localhost:8080` and issue requests. Your landing page will provide more information and examples of URL format.

After done, following commands can be used to clean up containers, images and system.
```
docker container rm -f smartview_1
docker container rm -f smartdb_1

docker image rm smartdb smartview

docker system prune -f
```

# Architecture and Design
-----------------------------------------------

## Database server

Upon starting the MySQL server, tables are created, all 3 CSV files ingested, and a view defined.

Basic configuration of the server is done via the environment variables in docker image definition (`dockerfile.db`), including root password, user account/password, and database name. Additional server configuration is achieved via `mysqld.cnf` to allow loading data from CSV files. 

All source file for bring up DB server is under `sqldb` directory

```
./dockerfile.db                 - docker file for building the image
./lead_users.csv                - data as supplied
./lead_user_sessions.csv        - data as supplied
./lead_user_responses_v2.csv    - data srubbed (5 rows fixed for the session_id field)
./schemas.sql                   - (MySQL statement) schemas as supplied
./loaddata.sql                  - (MySQL statement) load data in CSV files into db
./createview.sql                - (MySQL statement) create a view joining data across 3 tables
./mysqld.cnf                    - MySQL server config file to permit loading data from CSV files in a specific directory
```

MySQL server accepts connection on TCP port 3306 by default.

## Webapp server

The web host is implemented in Golang. It listens on port 8080, accept commands and parameters via URL. Data is served via HTML templates and a CSS style sheet.

All source file for bring up Webapp server is under `goviewer` directory

```
./src/main/main.go          - Simple web host written in Golang
./templates/index.html      - Home page (index.html for this web site)
./templates/view.html       - Web page to display data return by a query built from URL parameters
./assets/css/tachyons.css   - CSS style sheet downloaded from https://tachyons.io/
./assets/img/keyhole.jpg    - Background image (the Keyhole near Longs Peak, CO) to make the home page more interesting
```
