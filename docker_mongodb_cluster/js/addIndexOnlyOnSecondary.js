use test_database;

print ("Number of documents: " + db.test_collections.count());

db.test_collections.ensureIndex({createdDtm: 1}, {background: true});
db.test_collections.getIndexes();