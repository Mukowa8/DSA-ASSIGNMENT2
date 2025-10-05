FROM ballerina/ballerina:2201.8.0

WORKDIR /home/ballerina

COPY passenger-service.src ./src
COPY Ballerina.toml .

RUN bal build --cloud=docker

CMD ["bal", "run", "target/bin/passenger_service.jar"]