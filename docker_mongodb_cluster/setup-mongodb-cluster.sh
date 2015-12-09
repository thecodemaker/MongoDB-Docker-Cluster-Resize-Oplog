#!/bin/bash

# Docker interface ip
DOCKERIP="172.17.42.1"

#sudo docker ps -a -q | sudo xargs docker stop | sudo xargs docker rm

echo "********************************************Cleaning the environment"
containers=(skydns skydock rs1_srv1 rs1_srv2 rs1_srv3 cfg1 mongos1 rs1_srv2_bis)
for c in ${containers[@]}; do
	docker stop ${c} 	> /dev/null 2>&1
	docker rm ${c} 		> /dev/null 2>&1
	rm -r mongo-persisted-data/${c}
done

echo "***********************Restart docker to avoid some skydns problems."
service docker.io restart
sleep 5

echo "***********************************************Setup skydns/skydock."
docker run -d -p ${DOCKERIP}:53:53/udp --name skydns crosbymichael/skydns -nameserver 8.8.8.8:53 -domain docker
docker run -d -v /var/run/docker.sock:/docker.sock --name skydock crosbymichael/skydock -ttl 30 -environment dev -s /docker.sock -domain docker -name skydns

sleep 2

echo "*******************************************Create mongodocker images"
echo "build dev0/mongobase"
docker build --no-cache=true -t dev0/mongobase mongobase

echo "build dev0/mongodb"
docker build --no-cache=true -t dev0/mongodb mongod

echo "build dev0/mongoconfig"
docker build --no-cache=true -t dev0/mongoconfig mongoconfig

echo "build dev0/mongos"
docker build --no-cache=true -t dev0/mongos mongos

echo "************************************************Create a replica set"
for i in {1..3}
do
    container_name="rs1_srv${i}"

    data_dir="`pwd`/mongo-persisted-data/${container_name}"
    mkdir -p ${data_dir}

    docker run \
        --dns ${DOCKERIP}  \
        --name ${container_name} \
        -v ${data_dir}:/data/mongodb \
        -P -i -d dev0/mongodb

    sleep 2
done

sleep 5

mongo --port $(docker port rs1_srv1 27017|cut -d ":" -f2) <<EOF
    config = { _id: "rs1", members:[
              { _id : 0, host : "rs1_srv1.mongodb.dev.docker:27017" },
              { _id : 1, host : "rs1_srv2.mongodb.dev.docker:27017" },
              { _id : 2, host : "rs1_srv3.mongodb.dev.docker:27017" }]
             };
    rs.initiate(config)
EOF

sleep 20

mongo --port $(docker port rs1_srv1 27017|cut -d ":" -f2) <<EOF
    rs.status()
EOF

sleep 2

#create some config servers
echo "********************************************create some config servers"

docker run \
    --dns ${DOCKERIP} \
    --name cfg1 \
    -v "`pwd`/mongo-persisted-data/cfg1":/data/mongodb \
    -P -i -d dev0/mongoconfig \
    --configsvr --dbpath /data/mongodb --noprealloc --smallfiles --profile=0  --slowms=-1 --port 27017

sleep 10

echo "************************************************create mongod router"

docker run \
    --dns ${DOCKERIP} \
    --name mongos1 \
    -P -i -d dev0/mongos \
    --configdb "cfg1.mongoconfig.dev.docker:27017" \
    --port 27017

sleep 10

mongo --port $(docker port mongos1 27017|cut -d ":" -f2) <<EOF
    sh.addShard("rs1/rs1_srv1.mongodb.dev.docker:27017")
    sh.status()
EOF

sleep 5

echo "***********************************************Populate initial data"

mongo --port $(docker port mongos1 27017|cut -d ":" -f2) < js/populateDatabase.js

echo "**********************************************Check data replication"

for i in {1..3}
do
    mongo --port $(docker port rs1_srv${i} 27017|cut -d ":" -f2) < js/checkNumberOfDocuments.js

    sleep 5
done

echo "**********************************************Get oplog size before change"

for i in {1..3}
do
    mongo --port $(docker port rs1_srv${i} 27017|cut -d ":" -f2) < js/getOplogSize.js

    sleep 5
done

####sudo docker logs rs1_srv1
####sudo docker logs rs1_srv2
####sudo docker logs rs1_srv3
###
####sudo docker logs cfg1
####sudo docker logs mongos1
###
