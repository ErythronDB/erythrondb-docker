
# ErythronDB Website Docker Build
Docker build for the ErythronDB Website and Database

> **NOTE**: Recommend using [docker compose](https://docs.docker.com/compose/install/) to build the containers

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
      * **DB_INIT**: full path to the ErythronDB database dump; if using Docker Desktop, the host path containing the `DB_INIT`  file must be a directory or subdirectory for which `file shareing` is enabled
      * **DB_DATA**: target path on host for mounting the PostGreSQL database (store the data); if using Docker Desktop, the host `DB_DATA` target must be a directory or subdirectory for which `file shareing` is enbable
      * **POSTGRES_INIT_USER** and **POSTGRES_INIT_DATABASE**: placeholders for DB admin credentials; needed to initialize the database.  **POSTGRES_INIT_USER** CANNOT be `postgres`
      * **TOMCAT_PORT**: mapped host port for tomcat (default=8080)
      * **TOMCAT_LOG**: target path on host for mounting tomcat log directory; enables logs to be viewed outside of the container; if using Docker Desktop, the host `LOG` target must be a directory or subdirectory for which `file sharing` is enabled 


> **NOTE**: You may save the modified `.env` file with a different name or in a different location, but will need to provide the full path to the file to any`docker compose` command using the **`--env-file`** option. e.g.,  `docker compose --env-file ./config/.env.dev up`

### Set build-time ARGs required by the service `Dockerfile`

#### Edit [erythrondb-website/site-admin.properties.sample](erythrondb-website/site-admin.properties.sample) and save in place as `site-admin.properties`. 
  * this file defines values that are needed to generate the website configuration during build-time, some of which would be security risks if set as environmental variables in the container (e.g., passwords).  
  * the values to set are as follows
    * **WEB_DB_PASSWORD** will be provided as part of a data access request
    * **SITE_ADMIN_EMAIL** email address to which `Contact Us` messages should be sent
    * **TOMCAT_MANAGER_PASSWORD** should be changed from the default.  The user name is `tomcat-admin`
  
#### Run the [insertArgs](scripts/insertArgs.py) script

   ``` python3 scripts/insertArgs.py -p erythrondb-website/site-admin.properties -d erythrondb-website/Dockerfile ```

to generate a new file `web/Dockerfile-with-ARGs` which is an updated version of the `Dockerfile`, with the site admin variables added as 'ARG' instructions.  

> **NOTE**: You may save the modified `.properties` file with a different name or in a different location; just update the file path following the `-p` flag in the `insertArgs.py` command accordingly.

> **WARNING**: _DO NOT COMMIT the modified `.env`, `site-admin.properties` or `Dockerfile-with-ARGs` FILES TO THE REPOSITORY_ as they will contained database passwords.  Currently both are included in `.gitignore`, but in the case that you accidentally do commit either file, _you should change the database passwords_.


### Build the Site

#### Set up and initialize the database



#### Build the website

Build the website site and start the tomcat application by executing: 

```docker compose up -d web ``` 
   
## Troubleshooting
1. Build is taking a long time and appears to have hung. 
> Maven builds within docker builds are known to be very slow due to some limitations on retrieving dependencies from the maven repository (see https://stackoverflow.com/questions/46713288/maven-inside-docker-container-horribly-slow).  The docker build may take 30 minutes or more the first time.  

2. tomcat has started succesfully, but `localhost:${TOMCAT_PORT}/erythrondb` gives a `404` error
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
docker compose up -d web
```
