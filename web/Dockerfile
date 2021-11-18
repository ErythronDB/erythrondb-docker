# syntax=docker/dockerfile:1
FROM tomcat:jdk11-adoptopenjdk-hotspot

ENV SITE_HOME=/www/erythrondb
ENV COMMON_DIR=/www/common
ENV GUS_HOME=/www/erythrondb/gus_home
ENV PROJECT_HOME=/www/erythrondb/project_home

# install git
RUN apt-get update && apt-get install -y git && apt-get install -y maven && apt-get install -y nodejs && apt-get install -y npm  && apt-get install -y ant

#$SITE_HOME/project_home

RUN mkdir -p $SITE_HOME/conf $SITE_HOME/gus_home/config $SITE_HOME/webapp $SITE_HOME/cgi-bin $SITE_HOME/cgi-lib $SITE_HOME/htdocs $COMMON_DIR/temp $COMMON_DIR/secret

WORKDIR $PROJECT_HOME

RUN git clone --depth 1 -b api-build-50 https://github.com/VEupathDB/WDK.git && \
    git clone --depth 1 -b api-build-50 https://github.com/VEupathDB/WDKClient.git && \
    git clone --depth 1 -b api-build-50 https://github.com/VEupathDB/install.git && \
    git clone --depth 1 -b api-build-50 https://github.com/VEuPathDB/CBIL.git && \
    git clone --depth 1 -b api-build-50 https://github.com/VEupathDB/WSF.git && \
    git clone --depth 1 -b api-build-50 https://github.com/VEupathDB/FgpUtil.git && \
    git clone --depth 1 -b api-build-50 https://github.com/VEuPathDB/ReFlow.git && \
    git clone --depth 1 -b api-build-50 https://github.com/VEupathDB/EbrcModelCommon.git && \
    git clone --depth 1 -b api-build-50 https://github.com/VEupathDB/EbrcWebsiteCommon.git && \
    git clone --depth 1 -b api-build-50 https://github.com/VEupathDB/EbrcWebSvcCommon.git && \
    git clone --depth 1 https://github.com/ErythronDB/ErythronDBWebsite.git

WORKDIR $SITE_HOME

ENV PATH $PATH:$GUS_HOME/bin:$PROJECT_HOME/install/bin

ADD web/config/webapp.prop $SITE_HOME/conf/webapp.prop

# https://www.topzenith.com/2020/07/http-status-404-not-found-docker-tomcat-image.html
RUN rm -r $CATALINA_HOME/webapps && mv $CATALINA_HOME/webapps.dist/ $CATALINA_HOME/webapps && \
    cp $PROJECT_HOME/install/gus.config.sample $GUS_HOME/config/gus.config && \
    ln -s $GUS_HOME/lib/java/db_driver/postgresql-42.2.14.jar $CATALINA_HOME/lib/postgresql-42.2.14.jar && \
    bldw ErythronDBWebsite $SITE_HOME/conf/webapp.prop

ADD web/config/tomcat-context.xml $CATALINA_HOME/conf/Catalina/localhost/ErythronDB.xml
ADD web/config/model.prop $GUS_HOME/config/ErythronDB/model.prop
ADD web/config/model-config.xml $GUS_HOME/config/ErythronDB/model-config.xml
ADD web/config/wdk_key $COMMON_DIR/secret/.erythrondb_wdk_key


# TODO: python?
