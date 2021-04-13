#!/usr/bin/env bash

function wait_for_port() {
     PORT=$1

     while ! nc -z localhost $PORT; do
          sleep 0.1
     done
}

docker-compose up -d --build

wait_for_port 29092

docker-compose exec broker kafka-topics --create --topic topic1 --partitions 3 --bootstrap-server localhost:29092

wait_for_port 9042

docker-compose exec cassandra cqlsh -e "CREATE KEYSPACE \"test\" WITH replication = { 'class': 'SimpleStrategy', 'replication_factor': 1 };"
docker-compose exec cassandra cqlsh -e 'USE test; CREATE TABLE tableA (id int PRIMARY KEY, f1 text);'

wait_for_port 8083

curl -X PUT \
     -H "Content-Type: application/json" \
     --data '{
            "connect.cassandra.consistency.level": "ONE",
            "connect.cassandra.contact.points": "cassandra",
            "connect.cassandra.default.value": "UNSET",
            "connect.cassandra.error.policy": "RETRY",
            "connect.cassandra.kcql": "INSERT INTO tableA SELECT * FROM topic1;",
            "connect.cassandra.key.space": "test",
            "connect.cassandra.max.retries": "3",
            "connect.cassandra.port": "9042",
            "connect.cassandra.retry.interval": "5000",
            "connector.class": "com.datamountaineer.streamreactor.connect.cassandra.sink.CassandraSinkConnector",
            "key.converter": "org.apache.kafka.connect.storage.StringConverter",
            "key.converter.schemas.enable": "false",
            "name": "cassandra-sink",
            "plugin.path": "/app/connector/2.0.0-2.4.0",
            "tasks.max": "1",
            "topics": "topic1",
            "value.converter": "org.apache.kafka.connect.json.JsonConverter",
            "value.converter.schemas.enable": "false"
        }' \
     http://localhost:8083/connectors/cassandra-sink/config | jq .

seq 10 | jq -Rc '{id: ., f1: "value\(.)"}' | docker-compose exec -T broker kafka-console-producer --broker-list broker:9092 --topic topic1

sleep 5

docker-compose exec cassandra cqlsh -e 'USE test; SELECT * FROM tableA;'