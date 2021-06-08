#!/bin/bash

PW_LENGTH=12
ELASTICSEARCH_ADMIN_PASSWD=$(pwgen $PW_LENGTH 1)
ELASTICSEARCH_CONFIGURER_PASSWD=$(pwgen $PW_LENGTH 1)
ELASTICSEARCH_KIBANA_PASSWD=$(pwgen $PW_LENGTH 1)

cat <<EOF > secrets.yaml
objectStorage:
    s3:
        accessKey: $(pwgen 20 1)
        secretKey: $(pwgen 40 1)
grafana:
    password: $(pwgen $PW_LENGTH 1)
    clientSecret: $(pwgen $PW_LENGTH 1)
harbor:
    password: $(pwgen $PW_LENGTH 1)
    databasePassword: $(pwgen $PW_LENGTH 1)
    clientSecret: $(pwgen $PW_LENGTH 1)
    xsrf: $(pwgen $PW_LENGTH 1)
    coreSecret: $(pwgen $PW_LENGTH 1)
    jobserviceSecret: $(pwgen $PW_LENGTH 1)
    registrySecret: $(pwgen $PW_LENGTH 1)
influxDB:
    users:
        adminPassword: $(pwgen $PW_LENGTH 1)
        wcWriterPassword: $(pwgen $PW_LENGTH 1)
        scWriterPassword: $(pwgen $PW_LENGTH 1)
elasticsearch:
    adminPassword: ${ELASTICSEARCH_ADMIN_PASSWD}
    adminHash: $(htpasswd -bnBC 10 "" ${ELASTICSEARCH_ADMIN_PASSWD} | tr -d ':\n')
    clientSecret: $(pwgen $PW_LENGTH 1)
    configurerPassword: ${ELASTICSEARCH_CONFIGURER_PASSWD}
    configurerHash: $(htpasswd -bnBC 10 "" ${ELASTICSEARCH_CONFIGURER_PASSWD} | tr -d ':\n')
    kibanaPassword: ${ELASTICSEARCH_KIBANA_PASSWD}
    kibanaHash: $(htpasswd -bnBC 10 "" ${ELASTICSEARCH_KIBANA_PASSWD} | tr -d ':\n')
    fluentdPassword: $(pwgen $PW_LENGTH 1)
    curatorPassword: $(pwgen $PW_LENGTH 1)
    snapshotterPassword: $(pwgen $PW_LENGTH 1)
    metricsExporterPassword: $(pwgen $PW_LENGTH 1)
    kibanaCookieEncKey: $(pwgen 32 1)
kubeapiMetricsPassword: $(pwgen $PW_LENGTH 1)
alerts:
    slack:
        apiUrl: $(pwgen $PW_LENGTH 1)
    opsGenie:
        apiKey: $(pwgen $PW_LENGTH 1)
dex:
    staticPassword: $(htpasswd -bnBC 10 "" $(pwgen $PW_LENGTH 1) | tr -d ':\n')
    googleClientID: null
    googleClientSecret: null
    oktaClientID: null
    oktaClientSecret: null
    kubeloginClientSecret: $(pwgen $PW_LENGTH 1)
    issuer: null
user:
    grafanaPassword: $(pwgen $PW_LENGTH 1)
    alertmanagerPassword: $(pwgen $PW_LENGTH 1)
prometheus:
    remoteWrite:
        password: $(pwgen $PW_LENGTH 1)
EOF
