# syntax=docker/dockerfile:1
FROM tomcat:jdk11-adoptopenjdk-hotspot

ARG GUS_HOME
ARG PROJECT_HOME

ENV SITE_HOME=/www/erythrondb

# install git
RUN apt-get update && apt-get install -y git && apt-get install -y maven && apt-get install -y nodejs && apt-get install -y npm  && apt-get install -y ant

RUN mkdir -p $SITE_HOME/conf $SITE_HOME/gus_home/config $SITE_HOME/project_home $SITE_HOME/webapp $SITE_HOME/cgi-bin $SITE_HOME/cgi-lib $SITE_HOME/htdocs

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

RUN cp $PROJECT_HOME/install/gus.config.sample $GUS_HOME/config/gus.config

ADD web/config $SITE_HOME/conf

RUN cp $SITE_HOME/conf/tomcat-context.xml /usr/local/tomcat/conf/Catalina/localhost/ErythronDB.xml

RUN bldw ErythronDBWebsite $SITE_HOME/conf/webapp.prop
