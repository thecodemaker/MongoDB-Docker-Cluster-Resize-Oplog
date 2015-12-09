use test_database;

var NO_OF_DOCUMENTS = 50000;

for(var i=0; i< NO_OF_DOCUMENTS; i++) {
    db.test_collections.save({
        nr: i,
        createdDtm: new Date().getTime(),
        randomValue: Math.random()
    });
};

db.test_collections.ensureIndex({randomValue: 1}, {background: true});
