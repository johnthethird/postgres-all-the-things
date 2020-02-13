#!/bin/bash
# exit on failure
set -e
set -o pipefail

cd database/api_schema
cat all.sql  | psql ${PGDATABASE-pgdbapi}
