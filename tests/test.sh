#!/bin/bash
set -u

CONF_DIR="${PWD}/conf"
PORT=3005

# save the query to eval later
status_request="curl --fail --silent -X POST -H 'Content-Type: application/json' -d @tests/test_req.json http://localhost:${PORT}"

# keep requesting status for 10 seconds before considering it failed
do_request() {
  eval $status_request > /dev/null
  if ! [[ 0 -eq $? ]]; then
    docker logs vroom
    docker rm -f vroom
    return 1
  fi
}

cleanup() {
  docker rm -f vroom > /dev/null
  sudo rm -r "${CONF_DIR}"
}

docker run -d --name vroom -p ${PORT}:3000 -v ${CONF_DIR}:/conf $1 > /dev/null

# wait for the server to start, plenty of time
sleep 2

echo "#### Testing startup.. ####"
# tests that the service starts up alright
eval $status_request > /dev/null
if [[ $? != 0 ]]; then
  echo $'ERROR: Couldnt start service.'
  cleanup
  exit 1
fi

# make sure the generated files are there
for f in ${CONF_DIR}/access.log ${CONF_DIR}/config.yml; do
  if [[ ! -f $f ]]; then
    echo $'Couldnt find $(basename $f):\n'
    ll ${CONF_DIR}
    cleanup
    exit 1
  fi
done

# change the config to accept only 1 job which should fail the test request
echo $'#### Testing config change.. ####'
sudo sed -i.bak "s/\b1000\b/1/g" ${CONF_DIR}/config.yml
docker restart vroom > /dev/null

# wait for the server to start, plenty of time
sleep 2

# vroom-express will respond with code 4 for too many locations
http_code=$(eval "${status_request} -w '%{http_code}'")
if [[ ${http_code} != "413" ]]; then
  echo "Bad error code: ${http_code}."
  cleanup
  exit 1
fi

echo "\n#### Tests successful ####"

cleanup
exit 0
