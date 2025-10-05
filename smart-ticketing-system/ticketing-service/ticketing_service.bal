import ballerina/http;
import ballerina/mongo;
import ballerina/uuid;
import ballerina/time;
import ballerinax/kafka;

configurable int port = 8082;

service / on new http:Listener(port) {
    private final mongo:Client dbClient;
    private final kafka:Producer paymentProducer;
    private final kafka:Producer notificationProducer;
    private final kafka:Consumer ticketConsumer;

    function init() returns error? {
        self.dbClient = check new (mongodbUri);
        self.paymentProducer = check new (kafka:DEFAULT_URL,
            {"topic": "payments.processed"});
        self.notificationProducer = check new (kafka:DEFAULT_URL,
            {"topic": "notifications"});
        
        // Consumer for ticket requests
        self.ticketConsumer = check new ({
            topics: ["ticket.requests"],
            groupId: "ticketing-service"
        });
        
        // Start listening for ticket requests
        self.processTicketRequests();
    }

    isolated function processTicketRequests() returns error? {
        while true {
            kafka:ConsumerRecord[] records = check self.ticketConsumer->poll(1000);
            foreach var kafkaRecord in records {
                _ = start self.handleTicketRequest(kafkaRecord);
            }
        }
    }

    isolated function handleTicketRequest(kafka:ConsumerRecord record) returns error? {
        map<string> ticketRequest = check record.value.toString().fromJsonString();
        
        string passengerId = ticketRequest.passengerId.toString();
        string tripId = ticketRequest.tripId.toString();
        string ticketType = ticketRequest.ticketType.toString();
        
        // Get trip details
        stream<record {}, error?> tripStream = self.dbClient->query(`SELECT * FROM trips WHERE id = ${tripId}`);
        record {|Trip value;|}? tripResult = check tripStream.next();
        
        if tripResult is () {
            // Handle error
            return;
        }
        
        Trip trip = tripResult.value;
        
        // Get route price
        stream<record {}, error?> routeStream = self.dbClient->query(`SELECT * FROM routes WHERE id = ${trip.routeId}`);
        record {|Route value;|}? routeResult = check routeStream.next();
        
        if routeResult is () {
            // Handle error
            return;
        }
        
        Route route = routeResult.value;
        
        // Create ticket
        Ticket ticket = {
            id: uuid:createType1AsString(),
            passengerId: passengerId,
            tripId: tripId,
            routeId: route.id,
            ticketType: ticketType,
            status: "CREATED",
            price: route.price,
            purchaseTime: time:utcToString(time:utcNow()),
            qrCode: uuid:createType1AsString()
        };
        
        _ = check self.dbClient->insert("tickets", ticket);
        
        // Initiate payment
        map<string> paymentEvent = {
            ticketId: ticket.id,
            passengerId: passengerId,
            amount: route.price.toString(),
            paymentMethod: "WALLET"
        };
        
        _ = check self.paymentProducer->send({
            topic: "payments.processed",
            value: paymentEvent.toString()
        });
    }

    resource function post tickets/[string id]/validate() returns http:Ok|http:BadRequest {
        // Update ticket status to VALIDATED
        _ = check self.dbClient->execute(`UPDATE tickets SET status = 'VALIDATED', validationTime = ${time:utcToString(time:utcNow())} WHERE id = ${id}`);
        
        // Send validation notification
        map<string> validationEvent = {
            ticketId: id,
            validationTime: time:utcToString(time:utcNow()),
            status: "VALIDATED"
        };
        
        _ = check self.notificationProducer->send({
            topic: "ticket.validations",
            value: validationEvent.toString()
        });
        
        return {body: {message: "Ticket validated successfully"}};
    }

    resource function get tickets/[string id]() returns http:Ok|http:NotFound {
        stream<record {}, error?> resultStream = self.dbClient->query(`SELECT * FROM tickets WHERE id = ${id}`);
        record {|Ticket value;|}? result = check resultStream.next();
        
        if result is () {
            return http:NOT_FOUND;
        }
        return {body: result.value};
    }
}