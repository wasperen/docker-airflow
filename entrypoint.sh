#!/bin/bash
/bin/run-parts entrypoint.d

TRY_LOOP="10"
MYSQL_HOST="mysql"
MYSQL_PORT="3306"
RABBITMQ_HOST="rabbitmq"
RABBITMQ_CREDS="airflow:airflow"

# wait for rabbitmq
if [ "$@" = "webserver" ] || [ "$@" = "worker" ] || [ "$@" = "scheduler" ] || [ "$@" = "flower" ] ; then
  j=0
  while ! curl -sI -u $RABBITMQ_CREDS http://$RABBITMQ_HOST:15672/api/whoami |grep '200 OK'; do
    j=`expr $j + 1`
    if [ $j -ge $TRY_LOOP ]; then
      echo "$(date) - $RABBITMQ_HOST still not reachable, giving up"
      exit 1
    fi
    echo "$(date) - waiting for RabbitMQ... $j/$TRY_LOOP"
    sleep 5
  done
fi

# wait for DB
if [ "$@" = "webserver" ] || [ "$@" = "worker" ] || [ "$@" = "scheduler" ] ; then
  i=0
  while ! nc $MYSQL_HOST $MYSQL_PORT >/dev/null 2>&1 < /dev/null; do
    i=`expr $i + 1`
    if [ $i -ge $TRY_LOOP ]; then
      echo "$(date) - ${MYSQL_HOST}:${MYSQL_PORT} still not reachable, giving up"
      exit 1
    fi
    echo "$(date) - waiting for ${MYSQL_HOST}:${MYSQL_PORT}... $i/$TRY_LOOP"
    sleep 5
  done
  if [ "$@" = "webserver" ]; then
    echo "Initialize database..."
    sudo -u airflow -E airflow initdb
  fi
  sleep 5
fi

exec sudo -u airflow -E airflow "$@"
