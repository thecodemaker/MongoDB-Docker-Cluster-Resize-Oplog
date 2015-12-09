#!/bin/bash

#https://docs.mongodb.org/manual/tutorial/change-oplog-size/

echo "**********************************************Get oplog size before change"

for i in {1..3}
do
    mongo --port $(docker port rs1_srv${i} 27017|cut -d ":" -f2) <<EOF
    rs.slaveOk();
    use local;
    print("Oplog size:" + db['oplog.rs'].storageSize());
EOF

    sleep 5
done


echo "*******************************Create index on secondary replication"
echo "**********************************************Put down one secondary"

docker stop -t=10 rs1_srv2

sleep 5

mongo --port $(docker port rs1_srv1 27017|cut -d ":" -f2) <<EOF
    rs.status()
EOF

echo "**********************************************Start one secondary"

docker start rs1_srv2 --port 27027


#echo "***********************************Create new secondary on same data"
#
#docker run \
#     --dns ${DOCKERIP}  \
#     --name rs1_srv2_bis \
#     -v "`pwd`/mongo-persisted-data/rs1_srv2":/data/mongodb \
#     -P -i -d dev0/mongodb \
#     --dbpath /data/mongodb --noprealloc --smallfiles --profile=0 --slowms=-1
#
#sleep 5
#
#docker ps -a
#
#mongo --port $(docker port rs1_srv2_bis 27017|cut -d ":" -f2) < js/addIndexOnlyOnSecondary.js
#
#sleep 5
#
#echo "***********************************************Restart old secondary"
#
#docker stop -t=10 rs1_srv2_bis
#
#docker start rs1_srv2
#
#sleep 5
#
#mongo --port $(docker port rs1_srv1 27017|cut -d ":" -f2) <<EOF
#    rs.status()
#EOF
#
#echo "*******************************************************Execute query"
#
#mongo --port $(docker port rs1_srv2 27017|cut -d ":" -f2) <<EOF
#    rs.slaveOk();
#    use test_database;
#
#    printjson(db.test_collections.find({randomValue: {\$gt: 0}, createdDtm: {\$gt: 0}}).limit(1).explain(true));
#EOF
#
#echo "***********************************************Populate initial data"
#
#mongo --port $(docker port mongos1 27017|cut -d ":" -f2) < js/populateDatabase.js
#
#echo "**********************************************Check data replication"
#
#mongo --port $(docker port rs1_srv1 27017|cut -d ":" -f2) < js/checkNumberOfDocuments.js
#
#sleep 5
#
#mongo --port $(docker port rs1_srv2 27017|cut -d ":" -f2) < js/checkNumberOfDocuments.js
#
#sleep 5
#
#mongo --port $(docker port rs1_srv3 27017|cut -d ":" -f2) < js/checkNumberOfDocuments.js
