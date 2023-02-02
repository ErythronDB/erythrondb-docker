
# ErythronDB Website Docker Build
Docker build for the ErythronDB Website and Database

## How to request the data

**More information COMING SOON**

## Requirements

* Docker or Docker Desktop

> **NOTE**: Recommend using [docker compose](https://docs.docker.com/compose/install/) to build the containers
> **NOTE**: Depending on how `docker compose` is installed on your system, the command may be `docker-compose` instead of `docker compose`

* Memory / Disk Space
  * a minimum of `4.5GB` RAM is required to build the website (so if using `WSL2` layer on Windows, you may need to create a `.wslconfig` file to allocate more memory to the WSL2 layer if your system has 8GB RAM as, by default, the Windows limits the `WSL2` to 50% of the system memory resources).  Once the docker build is complete, the website will run with `2GB` or less of RAM, so you can stop the `erythrondb-website` container, adjust your memory allocations accordingly, and restart the `erythronb-website` container.
  * The database container will require `380MB` of hard-drive space in the directories where docker images/containers are stored (usually `/var/lib/docker`).  
  * The website container is larger and will require 2-3GB of hard-drive space in the directories where docker images/containers are stored (usually `/var/lib/docker`).
  * The instantiated database (location of the target `pgdata` on the host) will utiliize `13-15GB` of disk space.

##  Terms

* **`base directory`**: directory containg `docker-compose.yaml` file for the project (`erythrondb-docker` or an alias specified when cloning from GitHub)

> **NOTE**: with the exception of the `git clone` step, example commands provided below should **all** be run from the `base directory`

## How to build


### Clone the parent repository ([ErythronDB/erythrondb-docker](https://github.com/ErythronDB/erythrondb-docker))
 
   ```git clone https://github.com/ErythronDB/erythrondb-docker.git```

### Set build-time environmental variables required by `docker compose`

Edit [sample.env](sample.env) and save as `.env` in the `base directory`.
   * this defines environmental variables for the build environment that are required by `docker-compose.yaml`
   * values to set are as follows:
      * **DB_INIT**: full path to the ErythronDB database dump; if using Docker Desktop, the host path containing the `DB_INIT`  file must be a directory or subdirectory for which `file sharing` is enabled **See Note 1, below**
      * **DB_DATA**: target path on host for mounting the PostGreSQL database (store the data); if using Docker Desktop, the host `DB_DATA` target must be a directory or subdirectory for which `file sharing` is enabled. **See Notes 1 & 2, below.**  
      * **POSTGRES_INIT_USER** and **POSTGRES_INIT_DATABASE**: placeholders for DB admin credentials; needed to initialize the database.  **NOTE:** `POSTGRES_INIT_USER` **should not be changed; must be `postgres`**.
      * **TOMCAT_PORT**: mapped host port for tomcat (default=8080)
      * **TOMCAT_LOG**: target path on host for mounting tomcat log directory; enables logs to be viewed outside of the container; if using Docker Desktop, the host `LOG` target must be a directory or subdirectory for which `file sharing` is enabled 

> **NOTE 1 - BEST PRACTICES**: Pick a location outside of the code pulled from the repository for data storage; i.e., the target directories for the database init file and the PostGreSQL `pgdata` file should not be subdirectories of the `base directory`.

> **NOTE 2**: The database will **NOT** initialize if the `DB_DATA` directory already exists and has contents.  If you need to reinitialize the database, you will need to first remove the `DB_DATA` target directory.  For example, if you set `DB_PATH=/erythrondb/data/pgdata`, the path `/erythrondb/data/` should exist on the host, but the target directory `pgdata` should not.   The docker build will create it.  If you need to reinitialize the database, you will need to remove the `pgdata` directory.


### Set build-time ARGs required by the service `Dockerfile`

Edit [site-admin.properties.sample](site-admin.properties.sample) and save in place as `site-admin.properties`. 
  * this file defines values that are needed to generate the website configuration during build-time, some of which would be security risks if set as environmental variables in the container (e.g., passwords).  
  * the values to set are as follows
    * **WEB_DB_PASSWORD** will be provided as part of a data access request
    * **SITE_ADMIN_EMAIL** email address to which `Contact Us` messages should be sent
    * **TOMCAT_MANAGER_PASSWORD** should be changed from the default.  The user name is `tomcat-admin`
  * Leave all other property values in the file unchanged, unless adding an Apache layer on the host to enable SSL/HTTPS.  See [CORS section below](configuring-for-httpsssl)
    
> **WARNING**: _DO NOT COMMIT the modified `.env`, `site-admin.properties` FILES TO THE REPOSITORY_ as they may contained database passwords.  Currently both are included in `.gitignore`, but in the case that you accidentally do commit either file, _you should change the database passwords_ and _let us know_ so we can change the default database passwords in the distributed versions.


### Configuring for HTTPS/SSL

This can be accomplished by putting an apache proxy pass/reverse proxy pass on the on the host machine.  Instructions for doing this are outside the scope of this project, but can be easily found on the web. 

The `CORS_ALLOWED_ORIGINS` setting in the `site-admin.properties` file will need to be updated to allow https from the hostname (or host IP).  See the `site-admin.properties.sample` file for details.

### Build the Site

#### Set up and initialize the database

* Create the `DB_INIT` target directory on the host.  If using `Docker Desktop`, make sure `file sharing` is enabled either for the target directory or its parent
* Create the parent directory for the `DB_DATA` target (e.g., if `DB_DATA=/erythrondb/data/pgdata`, then `mkdir -p /erythrondb/data`).  If using `Docker Desktop`, make sure `file sharing` is enabled for the parent directory.
* Fetch the database dump (`erythrondb.sql.gz`) and save in the `DB_INIT` directory (dump available upon request).
* Build the database container and initialize the database by executing:

```
docker compose up -d db
``` 

or from outside of the `base directory`:

```
docker compose  -f "<path to base_directory>/docker-compose.yaml" up -d --build db 
```

> **NOTE**: you are going to want to wait for the database to finish initializing before starting the web container for the first time.  This may take 10-30 minutes depending on the available resources on the host machine.

You can track the database initialization progress using the docker logs as follows:

```
docker compose logs --follow --timestamps | grep erythrondb-db
```

The log should report `database system is ready to accept connections` when the database is fully built.  Again, this should be after about 15-20 minutes of executing commands from the `erythrondb.sql.gz` database dump. If the database build completes sooner (matter of seconds), it is likely that either:
* The `DB_DATA` directory already existed or was not empty.  Remove the `DB_DATA` directory and try again.
* The `POSTGRES_INIT_USER` was changed.  It must be set to `postgres`.  Correct the setting and try again.

#### Build the website

Build the website site and start the tomcat application by executing: 

```
docker compose up -d web
``` 

or from outside of the `base directory`:

```
docker compose  -f "<path to base directory>/docker-compose.yaml" up -d --build web 
```

#### Run the website

If the `erythrondb-website` container has started successfully, you should be able to access the website from http://localhost:8080/ErythronDB.  If you specified a custom `TOMCAT_PORT` in the `.env` file, substitute that value for `8080` in the URL.


## Troubleshooting
1. Build is taking a long time and appears to have hung. 
> Maven builds within docker builds are known to be very slow due to some limitations on retrieving dependencies from the maven repository (see https://stackoverflow.com/questions/46713288/maven-inside-docker-container-horribly-slow).  The docker build may take 30 minutes or more the first time on a system with limited resources.

  * you can try allocating more memory to `docker` (or to `WSL2` if using Windows).  It may speed things up.

2. tomcat has started succesfully, but `localhost:${TOMCAT_PORT}/ErythronDB` gives a `404` error
> This is most likely due to a problem with the site configuration.

   * Review `$TOMCAT_LOG/erythrondb/wdk.log4j` to determine the errors in the configuration file 
   * Update `site-admin.properties` 
   * Stop the `erythrondb-web` container and remove the associated image (see docker documentation for commands)
   * Run the `docker system prune -a` to remove the build caches (see docker documentation for more specific commands)
   * Rebuild the container

