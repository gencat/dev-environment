IMAGE=nodejs_centos
CONTENIDOR=nodejs
PORT=8000
CUR_PATH=$(pwd)
URL="http://canigo.ctti.gencat.cat/devenv/nodejs/centos"


echo $CUR_PATH/Dockerfile

curl -o $CUR_PATH/Dockerfile $URL/Dockerfile
curl -o $CUR_PATH/app.js $URL/app.js

sudo docker build -t $IMAGE .
sudo docker rm -f $CONTENIDOR
sudo docker run -p $PORT:$PORT -d --name $CONTENIDOR -v $CUR_PATH:/config $IMAGE pm2 start /config/app.js --no-daemon -- $PORT