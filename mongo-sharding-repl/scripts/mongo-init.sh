#!/bin/bash

# Инициализация сервера конфигурации
docker compose exec -T configSrv mongosh --port 27017 <<EOF

rs.initiate(
  {
    _id : "config_server",
       configsvr: true,
    members: [
      { _id : 0, host : "configSrv:27017" }
    ]
  }
);

EOF

# Инициализация шарда 1
docker compose exec -T shard1repl1 mongosh --port 27018 <<EOF

rs.initiate(
    {
      _id : "shard1",
      members: [
        { _id : 0, host : "shard1repl1:27018" },
        { _id : 1, host : "shard1repl2:27021" },
        { _id : 2, host : "shard1repl3:27022" }
      ]
    }
);

EOF

# Инициализация шарда 2
docker compose exec -T shard2repl1 mongosh --port 27019 <<EOF

rs.initiate(
    {
      _id : "shard2",
      members: [
        { _id : 3, host : "shard2repl1:27019" },
        { _id : 4, host : "shard2repl2:27023" },
        { _id : 5, host : "shard2repl3:27024" }
      ]
    }
  );

EOF

# Инициализация роутера и наполнения его данными
docker compose exec -T mongos_router mongosh --port 27020 <<EOF

sh.addShard( "shard1/shard1repl1:27018");
sh.addShard( "shard2/shard2repl1:27019");

sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { "name" : "hashed" } )

use somedb

for(var i = 0; i < 1000; i++) db.helloDoc.insert({age:i, name:"ly"+i})

EOF