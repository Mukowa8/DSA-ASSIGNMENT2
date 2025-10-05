import ballerina/http;
import ballerina/mongo;
import ballerina/uuid;
import ballerina/time;
import ballerinax/kafka;

configurable int port = 8080;

service / on new http:Listener(port) {
    private final mongo:Client dbClient;
    private final kafka:Producer kafkaProducer;

    function init() returns error? {
        self.dbClient = check new (mongodbUri);
        self.kafkaProducer = check new (kafka:DEFAULT_URL, 
            {"topic": "ticket.requests"});
    }

    resource function post register(@http:Payload Passenger passenger) returns http:Created|http:BadRequest {
        passenger.id = uuid:createType1AsString();
        passenger.createdAt = time:utcToString(time:utcNow());
        passenger.updatedAt = passenger.createdAt;
        passenger.balance = 0.0;

        _ = check self.dbClient->insert("passengers", passenger);
        
        return {body: {id: passenger.id, message: "Passenger registered successfully"}};
    }

    resource function get passengers/[string id]() returns http:Ok|http:NotFound {
        stream<record {}, error?> resultStream = self.dbClient->query(`SELECT * FROM passengers WHERE id = ${id}`);
        record {|Passenger value;|}? result = check resultStream.next();
        
        if result is () {
            return http:NOT_FOUND;
        }
        return {body: result.value};
    }

    resource function post passengers/[string id]/tickets(@http:Payload map<string> ticketRequest) returns http:Accepted|http:BadRequest {
        string tripId = ticketRequest.tripId.toString();
        string ticketType = ticketRequest.ticketType.toString();
        
        // Publish ticket request to Kafka
        map<string> ticketEvent = {
            passengerId: id,
            tripId: tripId,
            ticketType: ticketType,
            requestId: uuid:createType1AsString(),
            timestamp: time:utcToString(time:utcNow())
        };
        
        _ = check self.kafkaProducer->send({
            topic: "ticket.requests",
            value: ticketEvent.toString()
        });
        
        return {body: {message: "Ticket request submitted", requestId: ticketEvent.requestId}};
    }

    resource function get passengers/[string id]/tickets() returns http:Ok {
        stream<record {}, error?> resultStream = self.dbClient->query(`SELECT * FROM tickets WHERE passengerId = ${id}`);
        record {}[] tickets = from var ticket in resultStream
            select ticket;
        
        return {body: tickets};
    }

    resource function put passengers/[string id]/balance(@http:Payload map<string> topupRequest) returns http:Ok|http:BadRequest {
        decimal amount = 'decimal:fromString(topupRequest.amount.toString());
        
        _ = check self.dbClient->execute(`UPDATE passengers SET balance = balance + ${amount} WHERE id = ${id}`);
        
        return {body: {message: "Balance updated successfully"}};
    }
}