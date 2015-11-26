use test_database;

rs.slaveOk();

print ("Number of documents: " + db.test_collections.count());
