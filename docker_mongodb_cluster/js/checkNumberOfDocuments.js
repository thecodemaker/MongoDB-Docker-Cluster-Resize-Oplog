use test_database;

rs.slaveOk();

var NO_OF_DOCUMENTS = 50000;

var count = db.test_collections.count();
if (count != NO_OF_DOCUMENTS) {
    print("ERROR: ups something is wrong.");
}
print ("Number of documents: " + count);
