import ballerina/http;
import ballerina/mongo;
import ballerina/uuid;
import ballerina/time;
import ballerinax/kafka;

configurable int port = 8084;

service / on new http:Listener(port) {
    private final mongo:Client dbClient;
    private final kafka:Consumer notificationConsumer;
    private final kafka:Consumer scheduleConsumer;

    function init() returns error? {
        self.dbClient = check new (mongodbUri);
        
        // Consumer for notifications
        self.notificationConsumer = check new ({
            topics: ["notifications", "ticket.validations"],
            groupId: "notification-service"
        });
        
        // Consumer for schedule updates
        self.scheduleConsumer = check new ({
            topics: ["schedule.updates"],
            groupId: "notification-service"
        });
        
        // Start listening for notifications
        self.processNotifications();
        self.processScheduleUpdates();
    }

    isolated function processNotifications() returns error? {
        while true {
            kafka:ConsumerRecord[] records = check self.notificationConsumer->poll(1000);
            foreach var kafkaRecord in records {
                _ = start self.handleNotification(kafkaRecord);
            }
        }
    }

    isolated function processScheduleUpdates() returns error? {
        while true {
            kafka:ConsumerRecord[] records = check self.scheduleConsumer->poll(1000);
            foreach var kafkaRecord in records {
                _ = start self.handleScheduleUpdate(kafkaRecord);
            }
        }
    }

    isolated function handleNotification(kafka:ConsumerRecord record) returns error? {
        map<string> notificationData = check record.value.toString().fromJsonString();
        
        Notification notification = {
            id: uuid:createType1AsString(),
            passengerId: notificationData.passengerId.toString(),
            type: notificationData.type.toString(),
            message: notificationData.message.toString(),
            isRead: false,
            createdAt: time:utcToString(time:utcNow())
        };
        
        _ = check self.dbClient->insert("notifications", notification);
        
        // In a real system, you would send email/SMS/push notifications here
        log:printInfo("Notification sent: " + notification.message);
    }

    isolated function handleScheduleUpdate(kafka:ConsumerRecord record) returns error? {
        map<string> scheduleUpdate = check record.value.toString().fromJsonString();
        
        string type = scheduleUpdate.type.toString();
        string tripId = scheduleUpdate.tripId.toString();
        
        // Get passengers with tickets for this trip
        stream<record {}, error?> ticketStream = self.dbClient->query(`SELECT passengerId FROM tickets WHERE tripId = ${tripId} AND status = 'PAID'`);
        
        foreach var ticket in ticketStream {
            string passengerId = ticket.passengerId.toString();
            
            Notification notification = {
                id: uuid:createType1AsString(),
                passengerId: passengerId,
                type: "SCHEDULE_UPDATE",
                message: "Schedule update for your trip: " + type,
                isRead: false,
                createdAt: time:utcToString(time:utcNow())
            };
            
            _ = check self.dbClient->insert("notifications", notification);
        }
    }

    resource function get passengers/[string id]/notifications() returns http:Ok {
        stream<record {}, error?> resultStream = self.dbClient->query(`SELECT * FROM notifications WHERE passengerId = ${id} ORDER BY createdAt DESC`);
        record {}[] notifications = from var notification in resultStream
            select notification;
        
        return {body: notifications};
    }
}
