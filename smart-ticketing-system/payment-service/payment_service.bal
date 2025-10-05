import ballerina/http;
import ballerina/mongo;
import ballerina/uuid;
import ballerina/time;
import ballerinax/kafka;

configurable int port = 8083;

service / on new http:Listener(port) {
    private final mongo:Client dbClient;
    private final kafka:Consumer paymentConsumer;
    private final kafka:Producer notificationProducer;

    function init() returns error? {
        self.dbClient = check new (mongodbUri);
        self.notificationProducer = check new (kafka:DEFAULT_URL,
            {"topic": "notifications"});
        
        // Consumer for payment requests
        self.paymentConsumer = check new ({
            topics: "payments.processed",
            groupId: "payment-service"
        });
        
        // Start listening for payment requests
        self.processPayments();
    }

    isolated function processPayments() returns error? {
        while true {
            kafka:ConsumerRecord[] records = check self.paymentConsumer->poll(1000);
            foreach var kafkaRecord in records {
                _ = start self.handlePayment(kafkaRecord);
            }
        }
    }

    isolated function handlePayment(kafka:ConsumerRecord record) returns error? {
        map<string> paymentRequest = check record.value.toString().fromJsonString();
        
        string ticketId = paymentRequest.ticketId.toString();
        string passengerId = paymentRequest.passengerId.toString();
        decimal amount = 'decimal:fromString(paymentRequest.amount.toString());
        
        // Check passenger balance
        stream<record {}, error?> passengerStream = self.dbClient->query `SELECT * FROM passengers WHERE id = ${passengerId}`;
        record {|Passenger value;|}? passengerResult = check passengerStream.next();
        
        if passengerResult is () {
            // Handle error
            return;
        }
        
        Passenger passenger = passengerResult.value;
        
        Payment payment = {
            id: uuid:createType1AsString(),
            ticketId: ticketId,
            passengerId: passengerId,
            amount: amount,
            paymentMethod: "WALLET",
            status: "PENDING",
            transactionId: uuid:createType1AsString(),
            timestamp: time:utcToString(time:utcNow())
        };
        
        if passenger.balance >= amount {
            // Process payment
            _ = check self.dbClient->execute(`UPDATE passengers SET balance = balance - ${amount} WHERE id = ${passengerId}`);
            payment.status = "COMPLETED";
            
            // Update ticket status
            _ = check self.dbClient->execute(`UPDATE tickets SET status = 'PAID' WHERE id = ${ticketId}`);
            
            // Send success notification
            map<string> notification = {
                passengerId: passengerId,
                type: "PAYMENT_SUCCESS",
                message: "Payment processed successfully for ticket " + ticketId,
                amount: amount.toString()
            };
            
            _ = check self.notificationProducer->send({
                topic: "notifications",
                value: notification.toString()
            });
        } else {
            payment.status = "FAILED";
            
            // Send failure notification
            map<string> notification = {
                passengerId: passengerId,
                type: "PAYMENT_FAILED",
                message: "Insufficient balance for ticket " + ticketId
            };
            
            _ = check self.notificationProducer->send({
                topic: "notifications",
                value: notification.toString()
            });
        }
        
        _ = check self.dbClient->insert("payments", payment);
    }
}