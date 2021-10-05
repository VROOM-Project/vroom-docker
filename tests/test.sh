set -u

CONF_DIR="${PWD}/conf"
PORT=3005

# save the query to eval later
status_request="curl -X POST -H 'Content-Type: application/json' -d @tests/test_req.json http://localhost:${PORT}"

# keep requesting status for 10 seconds before considering it failed
do_request() {
  NEXT_WAIT_TIME=0
  until [ $NEXT_WAIT_TIME -eq 10 ]; do
    eval $status_request 2> /dev/null
    if [[ 0 -eq $? ]]; then
      return 0
    fi
    sleep $(( NEXT_WAIT_TIME++ ))
  done
  docker rm -f vroom
  return 101
}

cleanup() {
  docker rm -f vroom > /dev/null
  sudo rm -r "${CONF_DIR}"
}

docker run -d --name vroom -p ${PORT}:3000 -v ${CONF_DIR}:/conf vroomvrp/vroom-docker:$1 > /dev/null

echo "#### Testing startup.. ####"
# tests that the service starts up alright
do_request > /dev/null
if [[ $? != 0 ]]; then
  echo $'Couldnt start service. docker logs:\n' && echo $'$(docker logs vroom)\n'
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

# vroom-express will respond with code 4 for too many locations
res=$(do_request | jq '.code')
if [[ ${res} != "4" ]]; then
  echo "Bad error code: ${res}."
  cleanup
  exit 1
fi

echo "\n#### Tests successful ####"

cleanup
exit 0
