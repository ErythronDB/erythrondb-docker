# syntax=docker/dockerfile:1

# FROM tomcat:jdk11-adoptopenjdk-hotspot
FROM tomcat:9.0.65-jdk11-temurin-jammy as base

# ARGs that can be overload from command line or in the docker-compose.yaml
ARG DB_HOSTNAME=db
ARG DB_PORT

# legacy placeholder
ARG SECRET_KEY=placeholder-key

ENV SITE_HOME=/www/erythrondb
ENV COMMON_DIR=/www/common
ENV GUS_HOME=/www/erythrondb/gus_home
ENV PROJECT_HOME=/www/erythrondb/project_home
ENV DB_HOST=${DB_HOSTNAME}:${DB_PORT}
ENV PROJECT_ID=ErythronDB
ENV WEBAPP=$PROJECT_ID

# install build dependencies
RUN apt-get update && apt-get install -y git maven nodejs npm ant python3-pip \
    # clean up temp directories
	&& apt-get clean && apt-get purge && \
	rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
# Python Modules 
# -------------------------------------------------
    && pip3 install --no-cache-dir  \
    pandas scipy statsmodels wordcloud numpy seaborn

FROM base AS checkout-code

RUN mkdir -p $SITE_HOME/conf $SITE_HOME/gus_home/config $SITE_HOME/webapp \ 
    $SITE_HOME/cgi-bin $SITE_HOME/cgi-lib $SITE_HOME/htdocs $SITE_HOME/etc \
    $COMMON_DIR/temp $COMMON_DIR/secret

ADD site-admin.properties $SITE_HOME/etc/.

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

FROM checkout-code AS set-env

WORKDIR $SITE_HOME

ENV PATH $PATH:$GUS_HOME/bin:$PROJECT_HOME/install/bin
ENV NODE_OPTIONS=--max_old_space_size=4096
ENV SITE_ADMIN_PROPERTIES_FILE=$SITE_HOME/etc/site-admin.properties
ENV TOMCAT_HOME=$CATALINA_HOME

RUN cp $PROJECT_HOME/install/gus.config.sample $GUS_HOME/config/gus.config && \
    # . == source
    . $PROJECT_HOME/install/bin/gusEnv.bash && \
    # generate webapp.prop
    . $PROJECT_HOME/ErythronDBWebsite/Model/bin/generateWebappProps
  
FROM set-env AS build-web

# Build Website
# -------------------------------------------------
# fix tomcat directory structure; see https://www.topzenith.com/2020/07/http-status-404-not-found-docker-tomcat-image.html
# modify config and settings files based on ARGS
# link postgres jdbc driver

RUN echo "placeholder-key" > $COMMON_DIR/secret/.wdk_key && \
    bldw ErythronDBWebsite $GUS_HOME/config/webapp.prop && \
    rm -r $CATALINA_HOME/webapps && mv $CATALINA_HOME/webapps.dist/ $CATALINA_HOME/webapps && \
    cp $GUS_HOME/lib/java/db_driver/postgresql-*.jar $CATALINA_HOME/lib/. 

FROM build-web as config-site

# generate site config & clean up
RUN . $PROJECT_HOME/ErythronDBWebsite/Model/bin/generateSiteConfig && \
    # clean up
    rm -rf $PROJECT_HOME && \
    rm $SITE_ADMIN_PROPERTIES_FILE && unset SITE_ADMIN_PROPERTIES_FILE 
