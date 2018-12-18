#!/bin/bash
# Setup Development Project
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
echo "Setting up Parks Development Environment in project ${GUID}-parks-dev"

# Code to set up the parks development project.

# To be Implemented by Student
oc policy add-role-to-user edit system:serviceaccount:tcy-jenkins:jenkins -n tcy-parks-dev
oc new-app -f ../templates/mongodb-persistent-template.json -n ${GUID}-parks-dev \
--param MONGODB_USER="mongodb" \
--param MONGODB_PASSWORD="mongodb" \
--param MONGODB_DATABASE="parks" \
--param MONGODB_ADMIN_PASSWORD="mongodb" \
--param VOLUME_CAPACITY="3Gi"

oc new-build --binary=true --name="mlbparks" jboss-eap70-openshift:1.7 -n ${GUID}-parks-dev
oc new-app ${GUID}-parks-dev/mlbparks:0.0-0 --name=mlbparks --allow-missing-imagestream-tags=true -n ${GUID}-parks-dev
oc create configmap mlbparks-config -n ${GUID}-parks-dev \
--from-literal="DB_HOST=mongodb" \
--from-literal="DB_PORT=27017" \
--from-literal="DB_USERNAME=mongodb" \
--from-literal="DB_PASSWORD=mongodb" \
--from-literal="DB_NAME=parks" \
--from-literal="APPNAME=National Parks (Dev)"
oc set env dc/mlbparks --from=configmap/mlbparks-config -n ${GUID}-parks-dev
oc set triggers dc/mlbparks --remove-all -n ${GUID}-parks-dev
oc expose dc mlbparks --port 8080 -n ${GUID}-parks-dev
oc expose svc mlbparks -n ${GUID}-parks-dev -l type=parksmap-backend
oc set probe dc/mlbparks --liveness --failure-threshold 5 --initial-delay-seconds 30 -- echo ok -n ${GUID}-parks-dev
oc set probe dc/mlbparks --readiness --failure-threshold 3 --initial-delay-seconds 60 --get-url=http://:8080/ws/healthz/ -n ${GUID}-parks-dev