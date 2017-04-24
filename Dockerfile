# VERSION 0.1.0
# AUTHOR: Willem van Asperen

FROM centos:7

## Core OS and dependencies install & configure
RUN yum -y update && \
    yum -y install epel-release && \
    yum -y install \
        nmap-ncat \
        python-pip \
        python-devel \
        mariadb-libs \
        mariadb-devel \
        krb5-devel \
        cyrus-sasl \
        cyrus-sasl-devel \
        cyrus-sasl-gs2 \
        cyrus-sasl-gssapi \
        cyrus-sasl-lib \
        cyrus-sasl-md5 \
        cyrus-sasl-plain \
        openssl-devel \
        libffi-devel \
        krb5-workstation \
        java-1.8.0-openjdk \
        which \
        cronie-noanacron \
        sudo &&\
    yum -y groupinstall "Development Tools" && \
    pip install --upgrade pip

RUN rm /etc/localtime && \
    ln -s /usr/share/zoneinfo/Europe/Amsterdam /etc/localtime && \
    localedef --quiet -c -i en_US -f UTF-8 en_US.UTF-8

## Airflow install
ENV AIRFLOW_VERSION 1.9.0.dev0+apache.incubating
ENV AIRFLOW_HOME /opt/airflow

RUN useradd --shell /bin/bash --create-home --home $AIRFLOW_HOME airflow \
    && mkdir $AIRFLOW_HOME/logs \
    && mkdir $AIRFLOW_HOME/dags \
    && chown -R airflow: $AIRFLOW_HOME \
    && pip install pytz==2015.7 cryptography pyOpenSSL ndg-httpsclient pyasn1 celery==3.1.17 \
    && pip install --upgrade backports.ssl-match-hostname \
    && pip install configparser

RUN mkdir /tmp/incubator-airflow \
    && cd /tmp/incubator-airflow \
    && git clone https://github.com/wasperen/incubator-airflow.git /tmp/incubator-airflow \
    && pip install . .[celery] .[rabbitmq] .[mysql] .[async] .[password] .[devel_hadoop] .[crypto] .[hdfs] .[hive] .[kerberos] .[jdbc] .[docker] \
    && rm -rf /tmp/incubator-airflow

# Entrypoint
RUN mkdir $AIRFLOW_HOME/entrypoint.d
ADD entrypoint.d/* ${AIRFLOW_HOME}/entrypoint.d/
ADD entrypoint.sh ${AIRFLOW_HOME}/entrypoint.sh
RUN chmod +x $AIRFLOW_HOME/entrypoint.sh \
    && chmod +x $AIRFLOW_HOME/entrypoint.d/*

# Configuration
ADD airflow.cfg ${AIRFLOW_HOME}/airflow.cfg

RUN sed -i "s:#AIRFLOW_HOME#:$AIRFLOW_HOME:" $AIRFLOW_HOME/airflow.cfg \
    && sed -i "s:#AIRFLOW_HOME#:$AIRFLOW_HOME:" $AIRFLOW_HOME/entrypoint.d/*

RUN FERNET_KEY=$(python -c "from cryptography.fernet import Fernet; FERNET_KEY = Fernet.generate_key().decode(); print FERNET_KEY") \
    && sed -i "s/#FERNET_KEY#/$FERNET_KEY/" $AIRFLOW_HOME/airflow.cfg \
    && sed -i "s/#FERNET_KEY#/$FERNET_KEY/" $AIRFLOW_HOME/entrypoint.d/*

EXPOSE 8080 5555 8793

USER root
WORKDIR ${AIRFLOW_HOME}
ENTRYPOINT ["./entrypoint.sh"]
