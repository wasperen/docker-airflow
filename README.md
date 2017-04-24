# docker-airflow
A basic dockerized implementation of (clustered) Airflow.

This basic docker image can be used to spin up a clustered version of Airflow 1.9.0. It pulls the source from my GitHub fork of Airflow (https://github.com/wasperen/incubator-airflow), because it fixes a reference to a later version of the python docker binding (https://pypi.python.org/pypi/docker/).

The aim of this Docker image is to quickly spin up an Airflow environment that is equiped to talk to and run jobs on a Hadoop cluster. Separate configurations are required to configure these connections. This image forms a basis for such configuration.

Many thanks to Camil Blanaru, who created a version of Airflow for Docker a while ago (https://hub.docker.com/r/camil/airflow/) -- but that project does not seem to be active anymore.

## Background
This image is based on:
* Centos 7
* Python 2.7
* Airflow fork https://github.com/wasperen/incubator-airflow

## Airflow modules
The following Airflow modules are installed:
* celery
* rabbitmq
* mysql
* async
* password
* devel_hadoop
* crypto
* hdfs
* hive
* kerberos
* jdbc
* docker

## Running
A sample docker-compose file has been provided. This spins up the following services:
* MariaDB
* RabbitMQ
* Airflow -- Web Server
* Airflow -- Flower
* Airflow -- Scheduler
* Airflow -- Worker

A simple volume mapping is made to the directory `docker-airflow` in the users' home directory.

## Extending
The `entrypoint.sh` runs all entry point scripts in the directory `AIRFLOW_HOME/entrypoint.d/`, in order. This image provides some simple environment settings, but when extending from this image, one can include additional entrypoint scripts in the directory `AIRFLOW_HOME/entrypoint.d/`.

The scripts in the entry point directory are all run as `root`. Only at the last moment in `entrypoint.sh`, the user `airflow` is substituted. That is the user running the various Airflow services.
