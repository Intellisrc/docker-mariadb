#!/bin/sh

MYSQL_ROOT_PASSWORD=""
MYSQL_DATABASE=""
MYSQL_USER=""
MYSQL_PASSWORD=""

if [ -e /home/config.properties ]; then
  configText=$(cat /home/config.properties);

  MYSQL_ROOT_PASSWORD=$(echo "$configText" | grep "db.root" | awk -F'=' '{ print $2 }')
  MYSQL_DATABASE=$(echo "$configText" | grep "db.name" | awk -F'=' '{ print $2 }')
  MYSQL_USER=$(echo "$configText" | grep "db.user" | awk -F'=' '{ print $2 }')
  MYSQL_PASSWORD=$(echo "$configText" | grep "db.pass" | awk -F'=' '{ print $2 }')
fi

if [ -d "/run/mysqld" ]; then
    echo "[i] mysqld already present, skipping creation"
    chown -R mysql:mysql /run/mysqld
else
    echo "[i] mysqld not found, creating...."
    mkdir -p /run/mysqld
    chown -R mysql:mysql /run/mysqld
fi

if [ -d /var/lib/mysql/mysql ]; then
    echo "[i] MySQL directory already present, skipping creation"
    chown -R mysql:mysql /var/lib/mysql
else
    echo "[i] MySQL data directory not found, creating initial DBs"

    chown -R mysql:mysql /var/lib/mysql

    mysql_install_db --user=mysql --ldata=/var/lib/mysql > /dev/null

    if [ "$MYSQL_ROOT_PASSWORD" = "" ]; then
        $MYSQL_ROOT_PASSWORD=`pwgen 16 1`
        echo "[i] MySQL root Password: $MYSQL_ROOT_PASSWORD"
    fi

    tfile=`mktemp`
    if [ ! -f "$tfile" ]; then
        return 1
    fi

    if [ "$MYSQL_DATABASE" != "" ]; then
        echo "[i] Creating database: $MYSQL_DATABASE"
            echo "CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\` CHARACTER SET ${MYSQL_CHARSET:-utf8} COLLATE ${MYSQL_COLLATION:-utf8_general_ci};" >> $tfile
      if [ "$MYSQL_USER" != "" ]; then
        echo "[i] Creating user: $MYSQL_USER with password $MYSQL_PASSWORD"
        echo "FLUSH PRIVILEGES;" >> $tfile
        echo "GRANT ALL ON \`$MYSQL_DATABASE\`.* to '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';" >> $tfile
      fi
      echo "GRANT ALL ON *.* TO 'root'@'localhost' identified by '$MYSQL_ROOT_PASSWORD' WITH GRANT OPTION;" >> $tfile
      echo "SET PASSWORD FOR 'root'@'localhost'=PASSWORD('${MYSQL_ROOT_PASSWORD}');" >> $tfile
      echo "DROP DATABASE IF EXISTS test;" >> $tfile
      echo "DROP USER ''@'localhost';" >> $tfile
      echo "DROP USER ''@'$(hostname)';" >> $tfile
      echo "FLUSH PRIVILEGES;" >> $tfile
    fi
    
    /usr/bin/mysqld --user=mysql --bootstrap --verbose=0 --skip-name-resolve --skip-networking=0 < $tfile
    rm -f $tfile

    echo
    echo 'MySQL init process done. Ready for start up.'
    echo
fi
rm -f /home/config.properties
exec /usr/bin/mysqld --user=mysql --console --skip-name-resolve --skip-networking=0 $@  
