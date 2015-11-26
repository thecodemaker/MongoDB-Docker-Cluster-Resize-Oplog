rs.slaveOk();

var oplogSize = db.getReplicationInfo().logSizeMB;

print("Oplog size:" + oplogSize);