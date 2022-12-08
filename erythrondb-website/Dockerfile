# syntax=docker/dockerfile:1

# FROM tomcat:jdk11-adoptopenjdk-hotspot
FROM tomcat:9.0.65-jdk11-temurin-jammy as base

# ARGs that can be overload from command line or in the docker-compose.yaml
ARG WEBAPP=ErythronDB
ARG PROJECT_ID=ErythronDB
ARG DB_HOST=db
ARG SECRET_KEY=placeholder-key

ENV SITE_HOME=/www/erythrondb
ENV COMMON_DIR=/www/common
ENV GUS_HOME=/www/erythrondb/gus_home
ENV PROJECT_HOME=/www/erythrondb/project_home

# install build dependencies
RUN apt-get update && apt-get install -y git maven nodejs npm ant python3-pip \
    # clean up temp directories
	&& apt-get clean && apt-get purge && \
	rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
# Python Modules 
# -------------------------------------------------
    && pip3 install --no-cache-dir  \
    pandas scipy statsmodels wordcloud numpy seaborn

FROM base AS initialize-env

RUN mkdir -p $SITE_HOME/conf $SITE_HOME/gus_home/config $SITE_HOME/webapp \ 
    $SITE_HOME/cgi-bin $SITE_HOME/cgi-lib $SITE_HOME/htdocs \
    $COMMON_DIR/temp $COMMON_DIR/secret

WORKDIR $PROJECT_HOME

RUN git clone --depth 1 -b api-build-50 https://github.com/ErythronDB/WDK.git && \
    git clone --depth 1 -b api-build-50 https://github.com/ErythronDB/WDKClient.git && \
    git clone --depth 1 -b api-build-50 https://github.com/ErythronDB/install.git && \
    git clone --depth 1 -b api-build-50 https://github.com/ErythronDB/WSF.git && \
    git clone --depth 1 -b api-build-50 https://github.com/ErythronDB/FgpUtil.git && \
    git clone --depth 1 -b api-build-50 https://github.com/ErythronDB/EbrcModelCommon.git && \
    git clone --depth 1 -b api-build-50 https://github.com/ErythronDB/EbrcWebsiteCommon.git && \
    git clone --depth 1 -b api-build-50 https://github.com/ErythronDB/EbrcWebSvcCommon.git && \
    git clone --depth 1 https://github.com/ErythronDB/ErythronDBWebsite.git

WORKDIR $SITE_HOME

ENV PATH $PATH:$GUS_HOME/bin:$PROJECT_HOME/install/bin
ENV NODE_OPTIONS=--max_old_space_size=4096

# Build Website
# -------------------------------------------------
# fix tomcat directory structure; see https://www.topzenith.com/2020/07/http-status-404-not-found-docker-tomcat-image.html
# modify config and settings files based on ARGS
# link postgres jdbc driver
RUN cp $PROJECT_HOME/install/gus.config.sample $GUS_HOME/config/gus.config && \
    # . == source
    . $PROJECT_HOME/install/bin/gusEnv.bash && \
    # set webapp properties
    cp $PROJECT_HOME/ErythronDBWebsite/Site/config/webapp.prop.sample $GUS_HOME/config/webapp.prop && \
    sed -i "s|@WEBAPP@|$WEBAPP|g" $GUS_HOME/config/webapp.prop && \
    sed -i "s|@PROJECT_ID@|$PROJECT_ID|g" $GUS_HOME/config/webapp.prop   \
    # build web
    && bldw ErythronDBWebsite $GUS_HOME/config/webapp.prop && \
    rm -r $CATALINA_HOME/webapps && mv $CATALINA_HOME/webapps.dist/ $CATALINA_HOME/webapps && \
    cp $GUS_HOME/lib/java/db_driver/postgresql-*.jar $CATALINA_HOME/lib/.  && \
    rm -r $PROJECT_HOME && \
    echo "Creating/modifying configuration files" && \
    # secret key file for cookie-based authentication
    cat $SECRET_KEY > $COMMON_DIR/secret/.wdk_key && \
    # model.props (specific for genome build b/c of third-party URLs)
    cp $GUS_HOME/config/$PROJECT_ID/model.prop.sample $GUS_HOME/config/$PROJECT_ID/model.prop && \
    sed -i "s|@WEBAPP@|${WEBAPP}|g" $GUS_HOME/config/$PROJECT_ID/model.prop && \
    sed -i "s|@SITE_ADMIN_EMAIL@|${SITE_ADMIN_EMAIL}|g" $GUS_HOME/config/$PROJECT_ID/model.prop && \
    sed -i "s|@PROJECT_ID@|${PROJECT_ID}|g" $GUS_HOME/config/$PROJECT_ID/model.prop && \
    # model-config
    cp $GUS_HOME/config/model-config.xml.sample $GUS_HOME/config/$PROJECT_ID/model-config.xml && \
    sed -i "s|@MODEL@|${PROJECT_ID}|g" $GUS_HOME/config/$PROJECT_ID/model-config.xml && \
    sed -i "s|@SITE_ADMIN_EMAIL@|${SITE_ADMIN_EMAIL}|g" $GUS_HOME/config/$PROJECT_ID/model-config.xml && \
    sed -i "s|@DB_USER@|${WEB_DB_USER}|g" $GUS_HOME/config/$PROJECT_ID/model-config.xml && \
    sed -i "s|@DB_PASSWORD@|${WEB_DB_PASSWORD}|g" $GUS_HOME/config/$PROJECT_ID/model-config.xml && \
    sed -i "s|@DB_HOST@|${DB_HOST}|g" $GUS_HOME/config/$PROJECT_ID/model-config.xml && \
    sed -i "s|@DB_PORT@|${WEB_DB_PORT}|g" $GUS_HOME/config/$PROJECT_ID/model-config.xml && \
    sed -i "s|@DB_NAME@|${WEB_DB_NAME}|g" $GUS_HOME/config/$PROJECT_ID/model-config.xml && \ 
    # tomcat-context.xml
    cp $GUS_HOME/config/tomcat-context.xml.sample $CATALINA_HOME/conf/Catalina/localhost/${WEBAPP}.xml && \
    sed -i "s|@MODEL@|${PROJECT_ID}|g" $CATALINA_HOME/conf/Catalina/localhost/${WEBAPP}.xml && \
    sed -i "s|@WEBAPP@|${WEBAPP}|g" $CATALINA_HOME/conf/Catalina/localhost/${WEBAPP}.xml && \
    # move an older version of log4j needed to generate ontology files/raml but causes version conflicts
    # and method not found issues in the FgpUtil
    mkdir $GUS_HOME/lib/java/deprecated && mv $GUS_HOME/lib/java/log4j-1.2.17.jar $GUS_HOME/lib/java/deprecated/. && \
    # tomcat-users.xml
    cp $GUS_HOME/config/tomcat-users.xml.sample $CATALINA_HOME/conf/tomcat-users.xml && \
    sed -i "s|@TOMCAT_MANAGER_PASSWORD@|$TOMCAT_MANAGER_PASSWORD|g" $CATALINA_HOME/conf/tomcat-users.xml && \
    cp $GUS_HOME/config/tomcat-manager-context.xml $CATALINA_HOME/webapps/manager/META-INF/context.xml
