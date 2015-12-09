FROM dev0/mongobase:latest

# Add mongod.conf
ADD mongod.conf /etc/mongod.conf

EXPOSE 27017
ENTRYPOINT ["usr/bin/mongod", "--config", "/etc/mongod.conf"]