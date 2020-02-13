#!/bin/bash
# exit on failure
set -eE # allow for trap
set -o pipefail

# pushd "${BASH_SOURCE%/*}" || exit  # cd into this dir and use relative paths
# trap "popd" ERR # go back to original dir the user was in if an error occurs

# Set these environmental variables to override them,
# but they have safe defaults.
export PGHOST=${PGHOST-localhost}
export PGPORT=${PGPORT-5432}
export PGDATABASE=${PGDATABASE-pgdbapi}
export PGUSER=${PGUSER-postgres}
export PGPASSWORD=${PGPASSWORD-password}


usage() {
  echo "Usage: ${0} react https://unpkg.com/react/umd/react.production.min.js"
}

MODULE_NAME="${1}"
MODULE_URL="${2}"
MODULES_DIR=${MODULES_DIR-./lib/v8/modules}

if [[ ${MODULE_URL} == http* ]]; then
  if [ -f ${MODULES_DIR}/${MODULE_NAME}.js ]; then
    echo "${MODULE_NAME}.js exists. Skipping download."
  else
    echo "Downloading ${1}"
    wget -N -O ${MODULES_DIR}/${MODULE_NAME}.js ${MODULE_URL}
  fi
fi

RUN_PSQL="psql -X --set AUTOCOMMIT=off --set ON_ERROR_STOP=on "

${RUN_PSQL} <<SQL
  \set tmp_filename '${MODULE_NAME}'

  \lo_import ${MODULES_DIR}/:tmp_filename.js
  \set tmp_lo_id :LASTOID
  DELETE FROM v8.modules WHERE module = :'tmp_filename';
  INSERT INTO v8.modules (module, autoload, source)
  VALUES (
    :'tmp_filename',
    false,
    convert_from(lo_get(:tmp_lo_id), 'UTF8')
  );
  \lo_unlink :tmp_lo_id
  COMMIT;
SQL
