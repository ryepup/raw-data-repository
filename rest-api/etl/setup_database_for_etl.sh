#!/bin/bash -ae

# Prepares databases in Cloud SQL for running the RDR -> OMOP ETL.
# Imports "cdm" and "voc" databases located in GCS, which were produced by running
# setup_local_database_for_etl.
# If the databases already exist, drop them prior to running this.
# Note: this takes a while. Go get some coffee while it's running!

USAGE="tools/setup_database_for_etl.sh --project <PROJECT> --account <ACCOUNT>"
while true; do
  case "$1" in
    --account) ACCOUNT=$2; shift 2;;
    --project) PROJECT=$2; shift 2;;
    -- ) shift; break ;;
    * ) break ;;
  esac
done

if [ -z "${ACCOUNT}" ]
then
  echo "Usage: $USAGE"
  exit 1
fi

if [ -z "${PROJECT}" ]
then
  echo "Usage: $USAGE"
  exit 1
fi
CREDS_ACCOUNT=${ACCOUNT}

echo "Activating service account..."
source tools/auth_setup.sh
gcloud auth activate-service-account $SERVICE_ACCOUNT --key-file=$CREDS_FILE

SQL_SERVICE_ACCOUNT=`gcloud sql instances describe --project ${PROJECT} --account ${ACCOUNT} \
rdrmaindb | grep serviceAccountEmailAddress | cut -d: -f2`

echo "Granting GCS access to ${SQL_SERVICE_ACCOUNT}..."
gsutil acl ch -u ${SQL_SERVICE_ACCOUNT}:W gs://all-of-us-rdr-vocabulary
gsutil acl ch -u ${SQL_SERVICE_ACCOUNT}:R gs://all-of-us-rdr-vocabulary/vocabularies-2017-09-18/*.sql

echo "Importing CDM database..."
gcloud sql instances import --quiet --project ${PROJECT} --account ${ACCOUNT} rdrmaindb gs://all-of-us-rdr-vocabulary/vocabularies-2017-09-18/cdm.sql

echo "Importing VOC database..."
gcloud sql instances import --quiet --project ${PROJECT} --account ${ACCOUNT} rdrmaindb gs://all-of-us-rdr-vocabulary/vocabularies-2017-09-18/voc.sql

echo "Done."