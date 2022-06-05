#!/bin/bash
testdir="$(dirname $(realpath $0))"
mockdir="${testdir}/mock"
inotifyscan="${testdir}/../nextcloud-inotifyscan"
nextcloud="${mockdir}/nextcloud"
datadir="${mockdir}/data"
tmp=$(mktemp)
python2=/usr/bin/python
python3=/usr/bin/python
dockeruser=userfoo
dockercontainer=containerbar
tmpconfig=$(mktemp)
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
  sleep .5
  echo foo > "${nextcloud}/data/bob/files/bar"
  sleep .5
  echo foo > "${nextcloud}/data/bob/files/한국어"
  sleep .5
  rm "${nextcloud}/data/bob/files/한국어"
  sleep .5
  rm "${nextcloud}/data/bob/files/bar"
  sleep .5
}

function run-for-alice() {
  sleep .5
  echo foo > "${datadir}/alice/files/bar"
  sleep .5
  rm "${datadir}/alice/files/bar"
  sleep .5
  echo foo > "${datadir}/alice/files/조선말"
  sleep .5
  rm "${datadir}/alice/files/조선말"
  sleep .5
}

function run-for-both() {
  sleep .5
  echo foo > "${datadir}/bob/files/bar"
  sleep .5
  echo foo > "${datadir}/alice/files/bar"
  sleep .5
  rm "${datadir}/alice/files/bar"
  sleep .5
  rm "${datadir}/bob/files/bar"
  sleep .5
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
php ${nextcloud}/occ files:scan --no-interaction --path=/bob/files/bar --shallow --quiet
php ${nextcloud}/occ files:scan --no-interaction --path=/bob/files/한국어 --shallow --quiet
php ${nextcloud}/occ files:scan --no-interaction --path=/bob/files/ --shallow --quiet
php ${nextcloud}/occ files:scan --no-interaction --path=/bob/files/ --shallow --quiet
EOF
) ${tmp} || exit 1

# Use case 2:
#   set NEXTCLOUD_HOME, USER_NAME
#   php must be available in $PATH
#   $NEXTCLOUD_HOME/occ will be used
#   data directory is customized
LOCAL_DATA=1 NEXTCLOUD_HOME="${nextcloud}" USER_NAME=alice DATA_DIR="${datadir}" ${python2} "${inotifyscan}" >${tmp} &
child=$!
run-for-alice
kill-all ${child}
diff <(cat <<EOF
php ${nextcloud}/occ files:scan --no-interaction --path=/alice/files/bar --shallow --quiet
php ${nextcloud}/occ files:scan --no-interaction --path=/alice/files/ --shallow --quiet
php ${nextcloud}/occ files:scan --no-interaction --path=/alice/files/조선말 --shallow --quiet
php ${nextcloud}/occ files:scan --no-interaction --path=/alice/files/ --shallow --quiet
EOF
) ${tmp} || exit 2

# Use case 3:
#   set USE_DOCKER=True, DOCKER_USER, DOCKER_CONTAINER, NEXTCLOUD_HOME, and USER_NAME
#   docker must be available in $PATH
#   php must be available in the docker's $PATH
#   occ in the docker's $PATH will be used
#   data directory is under $NEXTCLOUD_HOME/data
USE_DOCKER=True DOCKER_USER=${dockeruser} DOCKER_CONTAINER=${dockercontainer} NEXTCLOUD_HOME="${nextcloud}" USER_NAME=bob "${inotifyscan}" >${tmp} &
child=$!
run-for-bob
kill-all ${child}
diff <(cat <<EOF
docker exec -u${dockeruser} ${dockercontainer} php occ files:scan --no-interaction --path=/bob/files/bar --shallow --quiet
docker exec -u${dockeruser} ${dockercontainer} php occ files:scan --no-interaction --path=/bob/files/한국어 --shallow --quiet
docker exec -u${dockeruser} ${dockercontainer} php occ files:scan --no-interaction --path=/bob/files/ --shallow --quiet
docker exec -u${dockeruser} ${dockercontainer} php occ files:scan --no-interaction --path=/bob/files/ --shallow --quiet
EOF
) ${tmp} || exit 3

# Use case 4:
#   set USE_DOCKER=True, DOCKER_USER, DOCKER_CONTAINER, and USER_NAME
#   docker must be available in $PATH
#   php must be available in the docker's $PATH
#   occ in the docker's $PATH will be used
#   data directory is customized
LOCAL_DATA=1 USE_DOCKER=True DOCKER_USER=${dockeruser} DOCKER_CONTAINER=${dockercontainer} DATA_DIR="${datadir}" USER_NAME=alice "${inotifyscan}" >${tmp} &
child=$!
run-for-alice
kill-all ${child}
diff <(cat <<EOF
docker exec -u${dockeruser} ${dockercontainer} php occ files:scan --no-interaction --path=/alice/files/bar --shallow --quiet
docker exec -u${dockeruser} ${dockercontainer} php occ files:scan --no-interaction --path=/alice/files/ --shallow --quiet
docker exec -u${dockeruser} ${dockercontainer} php occ files:scan --no-interaction --path=/alice/files/조선말 --shallow --quiet
docker exec -u${dockeruser} ${dockercontainer} php occ files:scan --no-interaction --path=/alice/files/ --shallow --quiet
EOF
) ${tmp} || exit 4

unset INTERVAL

# Use case 5:
#   use config bob.ini
cat >"${tmpconfig}" <<EOF
[Bob]
interval = 0.1
occ = ${nextcloud}/occ
user = bob
docker = no
EOF
${python3} "${inotifyscan}" --config "${tmpconfig}" >${tmp} &
child=$!
run-for-bob
kill-all ${child}
diff <(cat <<EOF
php ${nextcloud}/occ files:scan --no-interaction --path=/bob/files/bar --shallow --quiet
php ${nextcloud}/occ files:scan --no-interaction --path=/bob/files/한국어 --shallow --quiet
php ${nextcloud}/occ files:scan --no-interaction --path=/bob/files/ --shallow --quiet
php ${nextcloud}/occ files:scan --no-interaction --path=/bob/files/ --shallow --quiet
EOF
) ${tmp} || exit 5

# Use case 6:
#   use config alice.ini
cat >"${tmpconfig}" <<EOF
[Alice]
interval = 0.1
occ = occ
user = alice
docker = ${dockeruser}:${dockercontainer}
EOF
LOCAL_DATA=1 "${inotifyscan}" --config "${tmpconfig}" >${tmp} &
child=$!
run-for-alice
kill-all ${child}
diff <(cat <<EOF
docker exec -u${dockeruser} ${dockercontainer} php occ files:scan --no-interaction --path=/alice/files/bar --shallow --quiet
docker exec -u${dockeruser} ${dockercontainer} php occ files:scan --no-interaction --path=/alice/files/ --shallow --quiet
docker exec -u${dockeruser} ${dockercontainer} php occ files:scan --no-interaction --path=/alice/files/조선말 --shallow --quiet
docker exec -u${dockeruser} ${dockercontainer} php occ files:scan --no-interaction --path=/alice/files/ --shallow --quiet
EOF
) ${tmp} || exit 6

# Use case 7:
#   watch alice and bob at the same time
cat >"${tmpconfig}" <<EOF
[DEFAULT]
interval = 0.1

[Alice]
occ = ${nextcloud}/occ
user = alice,bob
docker = no

[Bob]
occ = occ
user = bob
docker = ${dockeruser}:${dockercontainer}
EOF
LOCAL_DATA=1 "${inotifyscan}" \
  --config "${tmpconfig}" >${tmp} &
child=$!
run-for-both
kill-all ${child}
diff <(cat <<EOF
php ${nextcloud}/occ files:scan --no-interaction --path=/bob/files/bar --shallow --quiet
docker exec -u${dockeruser} ${dockercontainer} php occ files:scan --no-interaction --path=/bob/files/bar --shallow --quiet
php ${nextcloud}/occ files:scan --no-interaction --path=/alice/files/bar --shallow --quiet
php ${nextcloud}/occ files:scan --no-interaction --path=/alice/files/ --shallow --quiet
php ${nextcloud}/occ files:scan --no-interaction --path=/bob/files/ --shallow --quiet
docker exec -u${dockeruser} ${dockercontainer} php occ files:scan --no-interaction --path=/bob/files/ --shallow --quiet
EOF
) ${tmp} || exit 7

# Test command error for python3
CMD_ERR=oops NEXTCLOUD_HOME="${nextcloud}" USER_NAME=bob ${python3} "${inotifyscan}" 2>${tmp} &
run-for-bob
diff <(cat <<EOF
error message oops from php
CRITICAL - ['php', '${mockdir}/nextcloud/occ', 'config:system:get', 'datadirectory'] returned non-zero exit status 42
CRITICAL - ${mockdir}/nextcloud/data

EOF
) ${tmp} || exit 8

# Test command error for python2
cat >"${tmpconfig}" <<EOF
[Alice]
interval = 0.1
occ = occ
user = alice
docker = ${dockeruser}:${dockercontainer}
EOF
CMD_ERR=foobar LOCAL_DATA=1 "${inotifyscan}" --config "${tmpconfig}" 2>${tmp} &
run-for-alice
diff <(cat <<EOF
error message foobar from docker
CRITICAL - ['docker', 'exec', '-uuserfoo', 'containerbar', 'php', 'occ', 'config:system:get', 'datadirectory'] returned non-zero exit status 42
CRITICAL - ${mockdir}/data

EOF
) ${tmp} || exit 9

rm ${tmp} ${tmpconfig}
