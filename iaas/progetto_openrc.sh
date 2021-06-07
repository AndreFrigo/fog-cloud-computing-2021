#!/bin/sh 
export OS_USERNAME="admin"
export OS_PROJECT_NAME="progetto"
export OS_AUTH_URL="http://10.235.1.209/identity"
export OS_CACERT=""
export NOVA_CERT="/home/stack/devstack/accrc/cacert.pem"
export OS_PASSWORD="password"
export OS_USER_DOMAIN_ID=default
unset OS_USER_DOMAIN_NAME
export OS_PROJECT_DOMAIN_ID=default
unset OS_PROJECT_DOMAIN_NAME