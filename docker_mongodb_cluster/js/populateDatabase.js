use test_database;

for(var i=0; i< 10000; i++) {
    db.test_collections.save({
        nr: i,
        createdDtm: new Date().getTime(),
        randomValue: Math.random()
    });
};

db.test_collections.ensureIndex({randomValue: 1}, {background: true});
