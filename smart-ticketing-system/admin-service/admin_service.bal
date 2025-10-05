import ballerina/http;
import ballerina/mongo;
import ballerinax/kafka;

configurable int port = 8085;

service / on new http:Listener(port) {
    private final mongo:Client dbClient;
    private final kafka:Producer adminProducer;

    function init() returns error? {
        self.dbClient = check new (mongodbUri);
        self.adminProducer = check new (kafka:DEFAULT_URL,
            {"topic": "admin.updates"});
    }

    resource function get reports/sales() returns http:Ok {
        stream<record {}, error?> resultStream = self.dbClient->query(`SELECT COUNT(*) as totalTickets, SUM(price) as totalRevenue FROM tickets WHERE status = 'PAID'`);
        record {|record {} value;|}? result = check resultStream.next();
        
        return {body: result is () ? {} : result.value};
    }

    resource function get reports/passenger-traffic() returns http:Ok {
        stream<record {}, error?> resultStream = self.dbClient->query(`SELECT routeId, COUNT(*) as passengerCount FROM tickets WHERE status = 'VALIDATED' GROUP BY routeId`);
        record {}[] trafficData = from var data in resultStream
            select data;
        
        return {body: trafficData};
    }

    resource function post disruptions(@http:Payload map<string> disruption) returns http:Created {
        // Publish service disruption
        map<string> disruptionEvent = {
            type: "SERVICE_DISRUPTION",
            message: disruption.message.toString(),
            affectedRoutes: disruption.affectedRoutes,
            severity: disruption.severity.toString()
        };
        
        _ = check self.adminProducer->send({
            topic: "admin.updates",
            value: disruptionEvent.toString()
        });
        
        return {body: {message: "Disruption published successfully"}};
    }

    resource function get analytics/usage-patterns() returns http:Ok {
        // Get usage patterns by hour and route
        stream<record {}, error?> resultStream = self.dbClient->query(`SELECT HOUR(validationTime) as hour, routeId, COUNT(*) as count FROM tickets WHERE status = 'VALIDATED' GROUP BY HOUR(validationTime), routeId`);
        record {}[] patterns = from var pattern in resultStream
            select pattern;
        
        return {body: patterns};
    }
}