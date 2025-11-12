// ---------- PART 1: STATIC DOMAIN MODEL ----------
// Defines the entities, relations, and static invariants
// based on the BBP RASD (Bellosi, Montanelli, Tempobono).

// ----- 1.1 Enumerations (from RASD) -----

// Defines the possible conditions of a path
enum PathStatus { Optimal, Medium, RequiresMaintenance }

// Defines the types of obstacles
enum ObstacleType { Pothole, Roadwork, Other }

// Defines the visibility for paths and trips
enum Visibility { Public, Private }

// Defines the user-verified state of a sensor event
enum DetectionState { Pending, Confirmed, Rejected }

// ----- 1.2 Abstract Signatures for Data -----
// (Used because 'Int' is not on the allowed list)

// Abstract type for GPS coordinates
sig GPS_point {}

// Abstract type for computed trip statistics
sig Statistic {}

// Abstract type for weather data
sig Weather_info {}

// Abstract type for time, used in reports
abstract sig Timestamp {}

// ----- 1.3 Core Entities (Signatures) -----

// Abstract User, extended by Registered_user
abstract sig User {}

// A registered cyclist (RCY)
sig Registered_user extends User {
    trips: set Trip,             // Trips this user owns
    createdPaths: set Path,      // Paths this user created
    submittedReports: set Report // Reports this user authored
}

// A navigable path, which can be public or private
sig Path {
    geometry: set GPS_point,       // The GPS points defining the path
    pathVisibility: one Visibility,// Visibility for search
    creator: one Registered_user,  // The user who created it
    reports: set Report,           // All reports for this path
    performances: set Trip         // All trips recorded on this path
}

// A specific, recorded cycling session
sig Trip {
    trace: set GPS_point,            // GPS trace of the ride
    stats: one Statistic,            // Calculated stats (avg speed, etc)
    weather: lone Weather_info,      // Weather at the time of the trip
    owner: one Registered_user,      // The user who recorded it
    path: lone Path,                 // The path this trip was on (if any)
    tripVisibility: one Visibility,  // Visibility for stats
    detections: set sensor_event     // Sensor events logged on this trip
}

// A raw sensor-detected event (e.g., from accelerometer)
sig sensor_event {
    location: one GPS_point, // Where the event happened
    trip: one Trip           // The trip it happened on
}

// Abstract signature for all user-submitted reports
abstract sig Report {
    timestamp: one Timestamp,       // When the report was made
    author: one Registered_user,    // Who made the report
    path: one Path                  // The path this report is about
}

// A report about the path's general condition
sig Status_report extends Report {
    status: one PathStatus
}

// A report about a specific obstacle
sig Obstacle_report extends Report {
    type: one ObstacleType,         // Type of obstacle
    location: one GPS_point,        // Location of obstacle
    triggeredBy: lone sensor_event  // Optional link to a sensor event
}

// ----- 1.4 Static Invariants (Facts) -----

// Facts ensuring bidirectional relationships are consistent.
fact BidirectionalConsistency {
    trips = ~owner              // Trip.owner
    createdPaths = ~creator     // Path.creator
    submittedReports = ~author  // Report.author
    reports = ~path             // Report.path
    performances = ~path        // Trip.path
    detections = ~trip          // sensor_event.trip
}

// A sensor_event can trigger at most one Obstacle_report.
fact OneReportPerEvent {
    all e: sensor_event | lone e.~triggeredBy
}

// Logic for sensor-confirmed obstacle reports
fact ObstacleSensorConsistency {
    all r: Obstacle_report | some r.triggeredBy implies (
        r.path = r.triggeredBy.trip.path and
        r.author = r.triggeredBy.trip.owner and
        r.triggeredBy in r.triggeredBy.trip.detections
    )
}

// Privacy rule: A 'Public' Trip must be on a 'Public' Path.
fact PublicTripOnPublicPath {
    all t: Trip | t.tripVisibility = Public implies t.path.pathVisibility = Public
}

// Privacy rule: A 'Private' Path can only have performances (Trips)
// recorded by the path's creator.
fact PrivatePathOwnedTrips {
    all p: Path | p.pathVisibility = Private implies (
        all t: p.performances | t.owner = p.creator
    )
}
