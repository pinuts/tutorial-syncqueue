FROM amazoncorretto:17-alpine

RUN adduser --system --disabled-password --home /UM --shell /bin/bash --uid 102 um

COPY --chown=um:nogroup build/UM-current.sh .um.varfile /
COPY --chown=um:nogroup .docker-entrypoint.sh /UM/docker-entrypoint.sh
RUN chmod +x /UM/docker-entrypoint.sh

WORKDIR /UM
USER um

# Persist certain config files:
RUN mkdir /UM/.install4j
RUN sh /UM-current.sh -q -dir ~ -varfile /.um.varfile
RUN chmod +x /UM/docker-entrypoint.sh
RUN echo -e "cmsbs.gui.login = internal\ncmsbs.database.url=jdbc:h2:/UM/cmsbs-work/db.h2\ncmsbs.log.allFilesToStdout = true\ncmsbs.directory.listen.syncWithVfs = true\ninclude.1 = cmsbs-conf/docker.properties" >> /UM/cmsbs-conf/cmsbs.properties
RUN sed -i /UM/scripts/.umrc -e 's/LC_CTYPE=.*/# Removed by Dockerfile/'

# ----------------------------------------------------

FROM amazoncorretto:17-alpine

RUN apk add --no-cache bash

EXPOSE 8080

RUN adduser --system --disabled-password --home /UM --shell /bin/bash --uid 102 um
ENV TZ=Europe/Berlin
ENV LC_LOCALE=C.UTF-8

COPY --chown=um:nogroup --from=0 /UM /UM/
COPY --chown=um:nogroup build/current.zip /UM/um-project.zip

VOLUME [ "/UM/cmsbs-work" ]

ENTRYPOINT ["/UM/docker-entrypoint.sh"]
