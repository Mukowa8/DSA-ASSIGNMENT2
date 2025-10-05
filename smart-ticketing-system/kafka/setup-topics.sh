#!/bin/bash
echo "Waiting for Kafka to be ready..."
sleep 30

kafka-topics --bootstrap-server kafka:29092 --create --topic ticket.requests --partitions 3 --replication-factor 1
kafka-topics --bootstrap-server kafka:29092 --create --topic payments.processed --partitions 3 --replication-factor 1
kafka-topics --bootstrap-server kafka:29092 --create --topic schedule.updates --partitions 3 --replication-factor 1
kafka-topics --bootstrap-server kafka:29092 --create --topic ticket.validations --partitions 3 --replication-factor 1
kafka-topics --bootstrap-server kafka:29092 --create --topic notifications --partitions 3 --replication-factor 1
kafka-topics --bootstrap-server kafka:29092 --create --topic admin.updates --partitions 3 --replication-factor 1

echo "Kafka topics created successfully!"