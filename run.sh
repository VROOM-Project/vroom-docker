# Necessary workaround since the config.js most likely doesn't exist
# when creating a Docker container
if test -f /conf/config.js; then
  cp /conf/config.js /vroom-express/src/config.js
else
  cp /vroom-express/src/config.js /conf/config.js
fi

npm --prefix /vroom-express start
