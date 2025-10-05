import ballerina/http;
import ballerina/mongo;
import ballerina/uuid;
import ballerinax/kafka;

configurable int port = 8081;

service / on new http:Listener(port) {
    private final mongo:Client dbClient;
    private final kafka:Producer scheduleProducer;

    function init() returns error? {
        self.dbClient = check new (mongodbUri);
        self.scheduleProducer = check new (kafka:DEFAULT_URL,
            {"topic": "schedule.updates"});
    }

    resource function post routes(@http:Payload Route route) returns http:Created {
        route.id = uuid:createType1AsString();
        route.isActive = true;
        
        _ = check self.dbClient->insert("routes", route);
        
        return {body: {id: route.id, message: "Route created successfully"}};
    }

    resource function get routes() returns http:Ok {
        stream<record {}, error?> resultStream = self.dbClient->query(`SELECT * FROM routes WHERE isActive = true`);
        record {}[] routes = from var route in resultStream
            select route;
        
        return {body: routes};
    }

    resource function post trips(@http:Payload Trip trip) returns http:Created {
        trip.id = uuid:createType1AsString();
        trip.status = "SCHEDULED";
        
        _ = check self.dbClient->insert("trips", trip);
        
        // Notify about new trip schedule
        map<string> scheduleEvent = {
            type: "NEW_TRIP",
            tripId: trip.id,
            routeId: trip.routeId,
            scheduledDeparture: trip.scheduledDeparture
        };
        
        _ = check self.scheduleProducer->send({
            topic: "schedule.updates",
            value: scheduleEvent.toString()
        });
        
        return {body: {id: trip.id, message: "Trip scheduled successfully"}};
    }

    resource function put trips/[string id]/status(@http:Payload map<string> statusUpdate) returns http:Ok {
        string newStatus = statusUpdate.status.toString();
        
        _ = check self.dbClient->execute(`UPDATE trips SET status = ${newStatus} WHERE id = ${id}`);
        
        // Notify about status change
        map<string> statusEvent = {
            type: "STATUS_UPDATE",
            tripId: id,
            newStatus: newStatus
        };
        
        _ = check self.scheduleProducer->send({
            topic: "schedule.updates",
            value: statusEvent.toString()
        });
        
        return {body: {message: "Trip status updated"}};
    }
}