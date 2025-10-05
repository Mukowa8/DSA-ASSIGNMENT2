public type TicketType "SINGLE"|"DAY_PASS"|"WEEKLY"|"MONTHLY";

public type TicketStatus "CREATED"|"PAID"|"VALIDATED"|"EXPIRED"|"CANCELLED";

public type TransportType "BUS"|"TRAIN";

public type Passenger record {
    string id;
    string firstName;
    string lastName;
    string email;
    string phone;
    decimal balance;
    string createdAt;
    string updatedAt;
};

public type Route record {
    string id;
    string routeNumber;
    string name;
    TransportType transportType;
    string startLocation;
    string endLocation;
    decimal price;
    string[] stops;
    boolean isActive;
};

public type Trip record {
    string id;
    string routeId;
    string vehicleId;
    string driverId;
    string scheduledDeparture;
    string scheduledArrival;
    string actualDeparture?;
    string actualArrival?;
    string status; // "SCHEDULED", "IN_PROGRESS", "COMPLETED", "CANCELLED"
    int availableSeats;
};

public type Ticket record {
    string id;
    string passengerId;
    string tripId;
    string routeId;
    TicketType ticketType;
    TicketStatus status;
    decimal price;
    string purchaseTime;
    string validationTime?;
    string expiryTime?;
    string qrCode;
};

public type Payment record {
    string id;
    string ticketId;
    string passengerId;
    decimal amount;
    string paymentMethod;
    string status; // "PENDING", "COMPLETED", "FAILED"
    string transactionId;
    string timestamp;
};

public type Notification record {
    string id;
    string passengerId;
    string type;
    string message;
    boolean isRead;
    string createdAt;
};