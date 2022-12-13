
# ErythronDB Website Docker Build
Docker build for the ErythronDB Website and Database

> **NOTE**: Recommend using [docker compose](https://docs.docker.com/compose/install/) to build the containers

> **NOTE**: Depending on how `docker compose` is installed on your system, the command may be `docker-compose` instead of `docker compose`

##  Terms

* **`base directory`**: directory containg `docker-compose.yaml` file for the project (should be `erythrondb-docker/erythrondb-website`)

> **NOTE**: with the exception of the `git clone` step, example commands provided below should all be run from the `base directory`

## How to build

### Clone the parent repository ([ErythronDB/erythrondb-docker](https://github.com/ErythronDB/erythrondb-docker))
 
   ```git clone https://github.com/ErythronDB/erythrondb-docker.git```

### Set build-time environmental variables required by `docker compose`

Edit [erythrondb-website/sample.env](erythrondb-website/sample.env) and save as `.env` in the `base directory`.
   * this defines environmental variables for the build environment that are required by `docker-compose.yaml`
   * values to set are as follows:
      * **DB_INIT**: full path to the ErythronDB database dump; if using Docker Desktop, the host path containing the `DB_INIT`  file must be a directory or subdirectory for which `file sharing` is enabled
      * **DB_DATA**: target path on host for mounting the PostGreSQL database (store the data); if using Docker Desktop, the host `DB_DATA` target must be a directory or subdirectory for which `file sharing` is enbable
      * **POSTGRES_INIT_USER** and **POSTGRES_INIT_DATABASE**: placeholders for DB admin credentials; needed to initialize the database.  **POSTGRES_INIT_USER** CANNOT be `postgres`
      * **TOMCAT_PORT**: mapped host port for tomcat (default=8080)
      * **TOMCAT_LOG**: target path on host for mounting tomcat log directory; enables logs to be viewed outside of the container; if using Docker Desktop, the host `LOG` target must be a directory or subdirectory for which `file sharing` is enabled 

> **NOTE**: the database will **NOT** initialize if the `DB_DATA` directory already exists and has contents.  If you need to reinitialize the database, you will need to first remove the `DB_DATA` target directory

> **NOTE**: You may save the modified `.env` file with a different name or in a different location, but will need to provide the full path to the file to any`docker compose` command using the **`--env-file`** option. e.g.,  `docker compose --env-file ./config/.env.dev up`

### Set build-time ARGs required by the service `Dockerfile`

Edit [erythrondb-website/site-admin.properties.sample](erythrondb-website/site-admin.properties.sample) and save in place as `site-admin.properties`. 
  * this file defines values that are needed to generate the website configuration during build-time, some of which would be security risks if set as environmental variables in the container (e.g., passwords).  
  * the values to set are as follows
    * **WEB_DB_PASSWORD** will be provided as part of a data access request
    * **SITE_ADMIN_EMAIL** email address to which `Contact Us` messages should be sent
    * **TOMCAT_MANAGER_PASSWORD** should be changed from the default.  The user name is `tomcat-admin`
  
Run the [insertArgs](scripts/insertArgs.py) script

   ``` python3 scripts/insertArgs.py -p erythrondb-website/site-admin.properties -d erythrondb-website/Dockerfile ```

to generate a new file `web/Dockerfile-with-ARGs` which is an updated version of the `Dockerfile`, with the site admin variables added as 'ARG' instructions.  

> **NOTE**: You may save the modified `.properties` file with a different name or in a different location; just update the file path following the `-p` flag in the `insertArgs.py` command accordingly.

> **WARNING**: _DO NOT COMMIT the modified `.env`, `site-admin.properties` or `Dockerfile-with-ARGs` FILES TO THE REPOSITORY_ as they will contained database passwords.  Currently both are included in `.gitignore`, but in the case that you accidentally do commit either file, _you should change the database passwords_.


### Configuring for HTTPS/SSL

Details coming soon


### Build the Site

#### Set up and initialize the database

* Create the `DB_INIT` target directory on the host.  If using `Docker Desktop`, make sure `file sharing` is enabled either for the target directory or its parent
* Create the parent directory for the `DB_DATA` target (e.g., if `DB_DATA=/erythrondb/data/pgdata`, then `mkdir -p /erythrondb/data`).  If using `Docker Desktop`, make sure `file sharing` is enabled either for the parent directory.
* Fetch the database dump (`erythrondb.gz`) and save in the $DB_INIT directory
* Build the database container and initialize the database by executing:

```docker compose up -d db ``` 

or from outside of the `base directory`:

```
docker compose  -f "erythrondb-docker/erythrondb-website/docker-compose.yml" up -d --build db 
```

> **NOTE**: you are going to want to wait for the database to finish initializing before starting the web container for the first time.  This may take 30 minutes to a couple of hours depending on the available resources on the host machine.

You can track the database initialization progress using the docker logs as follows:

```
docker compose logs --follow --timestamps | grep database
```

The log should report `database system is ready to accept connections` when the database is fully built.

#### Build the website

Build the website site and start the tomcat application by executing: 

```docker compose up -d web ``` 

or from outside of the `base directory`:

```
docker compose  -f "erythrondb-docker/erythrondb-website/docker-compose.yml" up -d --build web 
```

## Troubleshooting
1. Build is taking a long time and appears to have hung. 
> Maven builds within docker builds are known to be very slow due to some limitations on retrieving dependencies from the maven repository (see https://stackoverflow.com/questions/46713288/maven-inside-docker-container-horribly-slow).  The docker build may take 30 minutes or more the first time.  

2. tomcat has started succesfully, but `localhost:${TOMCAT_PORT}/ErythronDB` gives a `404` error
> This is most likely due to a problem with the site configuration.

   * Review `$TOMCAT_LOG/erythrondb/wdk.log4j` to determine the errors in the configuration file 
   * Update `site-admin.properties` and rerun `insertArgs.py` to regenerate the `Dockerfile-with-ARGs` file
   * Uncomment the following line from the `Dockerfile-with-ARGs` file and save updated version to allow the docker build to clear the `site-admin-config` stage build cache, but retain the build cache for the earlier, more time intensive build stages
 
```
ADD "https://www.random.org/cgi-bin/randbyte?nbytes=10&format=h" skipcache
```
   * from the base directory run
```
docker compose down web
docker compose up -d --build web
```
