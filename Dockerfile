FROM intellisrc/alpine:3.14
# ------ EXPORTS ---------
EXPOSE 3306/TCP
VOLUME ["/var/lib/mysql"]

RUN apk add --no-cache mariadb mariadb-client mariadb-server-utils pwgen

RUN rm -f /var/cache/apk/*

ARG PROPS="/home/config.properties"
ARG DBROOT
ARG DBNAME
ARG DBUSER
ARG DBPASS

RUN echo "db.root=${DBROOT}" >> ${PROPS} && \
    echo "db.name=${DBNAME}" >> ${PROPS} && \
    echo "db.user=${DBUSER}" >> ${PROPS} && \
    echo "db.pass=${DBPASS}" >> ${PROPS} 

COPY setup/run.sh /home/run.sh

CMD ["/home/run.sh"]
