FROM ballerina/ballerina:2201.8.0

WORKDIR /home/ballerina

COPY . .

RUN bal build --cloud=docker

CMD ["bal", "run", "target/bin/*.jar"]