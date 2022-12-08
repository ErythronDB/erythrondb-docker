
# ErythronDB Website Docker Build
Docker build for the ErythronDB Website and Database

> **NOTE**: Recommend using `docker compose` to build the containers

##  Terms

* **`base directory`**: directory containg `docker-compose.yaml` file for the project (should be `erythrondb-docker/erythrondb-website`)

> **NOTE**: with the exception of the `git clone` step, example commands provided below should all be run from the `base directory`

## How to build

### Clone the parent repository ([ErythronDB/erythrondb-docker](https://github.com/ErythronDB/erythrondb-docker))
 
   ```git clone https://github.com/ErythronDB/erythrondb-docker.git```

### Set build-time environmental variables required by `docker compose`

Edit [erythrondb-website/sample.env](../sample.env) and save as `.env` in the `base directory`.
   * this defines environmental variables for the build environment that are required by `docker-compose.yaml`
   * values to set are as follows:
      * **DB_INIT**: full path to the ErythronDB database dump; if using Docker Desktop, the host path containing the `DB_INIT`  file must be a directory or subdirectory for which `file shareing` is enabled
      * **DB_DATA**: target path on host for mounting the PostGreSQL database (store the data); if using Docker Desktop, the host `DB_DATA` target must be a directory or subdirectory for which `file shareing` is enbable
      * **POSTGRES_INIT_USER** and **POSTGRES_INIT_DATABASE**: placeholders for DB admin credentials
      * **TOMCAT_PORT**: mapped host port for tomcat (default=8080)
      * **LOG**: target path on host for mounting tomcat log directory; enables logs to be viewed outside of the container; if using Docker Desktop, the host `LOG` target must be a directory or subdirectory for which `file sharing` is enabled 


> **NOTE**: You may save the modified `.env` file with a different name or in a different location, but will need to provide the full path to the file to any`docker compose` command using the **`--env-file`** option. e.g.,  `docker compose --env-file ./config/.env.dev up`

### Set build-time ARGs required by the service `Dockerfile`
Edit [erythrondb-website/site-admin.properties.sample](/erythrondb-website/site-admin.properties.sample) and save in place as `site-admin.properties`. 
  * this file defines values that are needed to generate the website configuration during build-time, some of which would be security risks if set as environmental variables in the container (e.g., passwords).  
  * the **WEB_DB_PASSWORD** will be provided as part of a data access request

Run the [insertArgs](../../scripts/insertArgs.py) script

   ``` python3 scripts/insertArgs.py -p web/site-admin.properties -d web/Dockerfile ```

to generate a new file `web/Dockerfile-with-ARGs` which is an updated version of the `Dockerfile`, with the site admin variables added as 'ARG' instructions.  

> **NOTE**: You may save the modified `.properties` file with a different name or in a different location; just update the file path following the `-p` flag in the `insertArgs.py` command accordingly.

> **WARNING**: _DO NOT COMMIT the modified `site-admin.properties` or `Dockerfile-with-ARGs` FILES TO THE REPOSITORY_ as they will contained database passwords.  Currently both are included in `.gitignore`, but in the case that you accidentally do commit either file, please contact the DB Admin right away so that passwords can be changed.


Values set in the `site-admin.properties` file are as follows:
 * **SITE_ADMIN_EMAIL**: _internal_; site error checking mechanism will e-mail certain types of errors to this admin
 * **WEBAPP**: site web application name; e.g., `www.niagads.org/`**genomics** (default=genomics)
 * **GENOME_BUILD**: full genome build for display purposes (e.g., hg38/GRCh38.p8) (default=GRCh38.p8)
 * **GENCODE_VERSION**:  GENCODE version; for dynamically populating genome browser config; will vary depending on _GENOME_BUILD_ and release
 * **DBSNP_VERSION**: dbSNP version; for dynamically populating genome browser config; will vary depending on _GENOME_BUILD_ and release
 * **ALT_BUILD_LINK**: URL for alternative site (i.e., GRCh37 site if GRCh38 and vice versa; see file for recommendations) 
 * **WEB_DB_PORT**: host port through which web application database can be accessed (default=5432)
 * **WEB_DB_HOST**: database server; if tunneling should use `host.docker.internal` instead of `localhost`
 * **WEB_DB_NAME**: name of the web application database
 * **WEB_DB_USER**: website "user" account in the DB
 * **WEB_DB_PASSWORD**: password for website "user" account in the DB
 * **SECRET_KEY**: text key for encoding login cookies

### Build the Site

The `genomicsdb/web` container is generated using a multi-stage build
   * Single step/production build - from the `genomicsdb` directory run:
   ```docker compose up -d web```
   * Development, multi-stage build; set a target in `docker-compose.yaml` and then run ```docker compose up -d web```
      * useful for debugging or setting web-development environment that does not need to build the website
      * allowable targets split the build into the following stages:
         * **base**: build base image, run update and install build (e.g., git, ant, maven, nodejs, npm) and run-time (python) dependencies 
         * **initialize-env**: create site working directories and pull code from repositories, create build property files and set ENV for build
         * **build-web**: run ant build scripts to generate the website
         * **site-admin-config**: [final stage]: perform substitutions from site-admin.properties based ARGs and copy config files to locations generated during the `build-web` stage
         
To do a multi-stage build, follow instructions for setting the `target` in the `docker-compose.yaml` file, see excerpt below:
   ```yaml
services:     
  web:
    container_name: ${PROJECT_ID}
    build:
      context: .
      dockerfile: ./web/Dockerfile-with-ARGs
      args:
        ENABLE_TOMCAT_MANAGER: ${ENABLE_TOMCAT_MANAGER}
        BUILD: ${BUILD}
      #target: 
      # leave target commented out to build entire container; or set targets to build sequentially for dev or debugging as follows:
      # 1. base - create tomcat container, do update and install dependencies
      # 2. initialize-env - fetches source from github and creates webapp.prop and gus.config and sets gusEnv to enable build
      # 3. build-web - run ant build for the website
      # 4. site-admin-config - generates site admin configuration based on values set in site-admin.properties 
   ```    
   
## Troubleshooting
1. Build is taking a long time and appears to have hung during `build-web` stage. 
> Maven builds within docker builds are known to be very slow due to some limitations on retrieving dependencies from the maven repository (see https://stackoverflow.com/questions/46713288/maven-inside-docker-container-horribly-slow).  The docker build may take 30 minutes or more the first time it tries to do the `build-web` target.  We employ `bind mounts` to cache maven dependencies on the host, so re-builds should be faster.

2. tomcat has started succesfully, but `localhost:${TOMCAT_PORT}/genomics` gives a `404` error
> This is most likely due to a problem with the site configuration.

   * Review `$TOMCAT_LOGS/genomics/wdk.log4j` to determine the errors in the configuration file 
   * Update `site-admin.properties` and rerun `insertArgs.py` to regenerate the `Dockerfile-with-ARGs` file
   * Uncomment the following line from the `Dockerfile-with-ARGs` file and save updated version to allow the docker build to clear the `site-admin-config` stage build cache, but retain the build cache for the earlier, more time intensive build stages