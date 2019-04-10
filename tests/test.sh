#!/bin/bash
testdir="$(dirname $(realpath $0))"
mockdir="${testdir}/mock"
inotifyscan="${testdir}/../nextcloud-inotifyscan"
nextcloud="${mockdir}/nextcloud"
datadir="${mockdir}/data"
tmp=$(mktemp)
python2=/usr/bin/python
python3=/usr/bin/python
test -x /usr/bin/python2 && python2=/usr/bin/python2
test -x /usr/bin/python3 && python3=/usr/bin/python3

PATH="${mockdir}/bin:${PATH}"
export INTERVAL=0.1

function kill-all() {
  child=$1
  children=$(pgrep -P ${child})
  kill -SIGINT ${child}
  kill ${children}
}

function run-for-bob() {
  sleep .2
  echo foo > "${nextcloud}/data/bob/files/bar"
  sleep .2
  echo foo > "${nextcloud}/data/bob/files/한국어"
  sleep .2
  rm "${nextcloud}/data/bob/files/한국어"
  sleep .2
  rm "${nextcloud}/data/bob/files/bar"
  sleep .2
}

function run-for-alice() {
  sleep .2
  echo foo > "${datadir}/alice/files/bar"
  sleep .2
  rm "${datadir}/alice/files/bar"
  sleep .2
  echo foo > "${datadir}/alice/files/조선말"
  sleep .2
  rm "${datadir}/alice/files/조선말"
  sleep .2
}
# Use case 1:
#   set NEXTCLOUD_HOME and USER_NAME
#   php must be available in $PATH
#   $NEXTCLOUD_HOME/occ will be used
#   data directory is under $NEXTCLOUD_HOME/data
NEXTCLOUD_HOME="${nextcloud}" USER_NAME=bob ${python3} "${inotifyscan}" >${tmp} &
child=$!
run-for-bob
kill-all ${child}
diff <(cat <<EOF
php ${nextcloud}/occ files:scan --no-interaction --path=/bob/files/bar --shallow
php ${nextcloud}/occ files:scan --no-interaction --path=/bob/files/한국어 --shallow
php ${nextcloud}/occ files:scan --no-interaction --path=/bob/files/ --shallow
php ${nextcloud}/occ files:scan --no-interaction --path=/bob/files/ --shallow
EOF
) ${tmp} || exit 1

# Use case 2:
#   set NEXTCLOUD_HOME, USER_NAME
#   php must be available in $PATH
#   $NEXTCLOUD_HOME/occ will be used
#   data directory is customized
NEXTCLOUD_HOME="${nextcloud}" USER_NAME=alice DATA_DIR="${datadir}" ${python2} "${inotifyscan}" >${tmp} &
child=$!
run-for-alice
kill-all ${child}
diff <(cat <<EOF
php ${nextcloud}/occ files:scan --no-interaction --path=/alice/files/bar --shallow
php ${nextcloud}/occ files:scan --no-interaction --path=/alice/files/ --shallow
php ${nextcloud}/occ files:scan --no-interaction --path=/alice/files/조선말 --shallow
php ${nextcloud}/occ files:scan --no-interaction --path=/alice/files/ --shallow
EOF
) ${tmp} || exit 2

# Use case 3:
#   set USE_DOCKER=True, DOCKER_USER, DOCKER_CONTAINER, NEXTCLOUD_HOME, and USER_NAME
#   docker must be available in $PATH
#   php must be available in the docker's $PATH
#   occ in the docker's $PATH will be used
#   data directory is under $NEXTCLOUD_HOME/data
USE_DOCKER=True DOCKER_USER=userfoo DOCKER_CONTAINER=containerbar NEXTCLOUD_HOME="${nextcloud}" USER_NAME=bob "${inotifyscan}" >${tmp} &
child=$!
run-for-bob
kill-all ${child}
diff <(cat <<EOF
docker exec -uuserfoo containerbar php occ files:scan --no-interaction --path=/bob/files/bar --shallow
docker exec -uuserfoo containerbar php occ files:scan --no-interaction --path=/bob/files/한국어 --shallow
docker exec -uuserfoo containerbar php occ files:scan --no-interaction --path=/bob/files/ --shallow
docker exec -uuserfoo containerbar php occ files:scan --no-interaction --path=/bob/files/ --shallow
EOF
) ${tmp} || exit 3

# Use case 4:
#   set USE_DOCKER=True, DOCKER_USER, DOCKER_CONTAINER, and USER_NAME
#   docker must be available in $PATH
#   php must be available in the docker's $PATH
#   occ in the docker's $PATH will be used
#   data directory is customized
USE_DOCKER=True DOCKER_USER=userfoo DOCKER_CONTAINER=containerbar DATA_DIR="${datadir}" USER_NAME=alice "${inotifyscan}" >${tmp} &
child=$!
run-for-alice
kill-all ${child}
diff <(cat <<EOF
docker exec -uuserfoo containerbar php occ files:scan --no-interaction --path=/alice/files/bar --shallow
docker exec -uuserfoo containerbar php occ files:scan --no-interaction --path=/alice/files/ --shallow
docker exec -uuserfoo containerbar php occ files:scan --no-interaction --path=/alice/files/조선말 --shallow
docker exec -uuserfoo containerbar php occ files:scan --no-interaction --path=/alice/files/ --shallow
EOF
) ${tmp} || exit 4

rm ${tmp}
