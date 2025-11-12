// ---------- PART 1: STATIC DOMAIN MODEL ----------
// Defines the entities, relations, and static invariants
// based on the BBP RASD (Bellosi, Montanelli, Tempobono).

// ----- 1.1 Enumerations (from RASD) -----

// Defines the possible conditions of a path [cite: 4189, 3261]
enum PathStatus { Optimal, Medium, RequiresMaintenance }

// Defines the types of obstacles [cite: 4190, 3262]
enum ObstacleType { Pothole, Roadwork, Other }

// Defines the visibility for paths and trips [cite: 4191, 3441, 3442]
enum Visibility { Public, Private }

// Defines the user-verified state of a sensor event [cite: 3194, 3203]
enum DetectionState { Pending, Confirmed, Rejected }

// ----- 1.2 Abstract Signatures for Data -----
// (Used because 'Int' is not on the allowed list)

// Abstract type for GPS coordinates [cite: 4192]
sig GPS_point {}

// Abstract type for computed trip statistics [cite: 4193, 3221]
sig Statistic {}

// Abstract type for weather data [cite: 4194, 3226]
sig Weather_info {}

// Abstract type for time, used in reports [cite: 3232, 3259]
abstract sig Timestamp {}

// ----- 1.3 Core Entities (Signatures) -----

// Abstract User, extended by Registered_user [cite: 3216, 3217]
abstract sig User {}

// A registered cyclist (RCY) [cite: 4195, 3134, 3217]
sig Registered_user extends User {
    trips: set Trip,             // Trips this user owns [cite: 4196]
    createdPaths: set Path,      // Paths this user created [cite: 4197]
    submittedReports: set Report // Reports this user authored [cite: 4198]
}

// A navigable path, which can be public or private [cite: 4200, 3253]
sig Path {
    geometry: set GPS_point,       // The GPS points defining the path [cite: 4201]
    pathVisibility: one Visibility,// Visibility for search (R39) [cite: 4202, 3511]
    creator: one Registered_user,  // The user who created it [cite: 4203]
    reports: set Report,           // All reports for this path [cite: 4204]
    performances: set Trip         // All trips recorded on this path [cite: 4205]
}

// A specific, recorded cycling session [cite: 4213, 3249]
sig Trip {
    trace: set GPS_point,            // GPS trace of the ride [cite: 4215]
    stats: one Statistic,            // Calculated stats (avg speed, etc) [cite: 4216]
    weather: lone Weather_info,      // Weather at the time of the trip [cite: 4217, 3252]
    owner: one Registered_user,      // The user who recorded it [cite: 4218]
    path: lone Path,                 // The path this trip was on (if any) [cite: 4219, 3249]
    tripVisibility: one Visibility,  // Visibility for stats (R39) [cite: 4220, 3511]
    detections: set sensor_event     // Sensor events logged on this trip [cite: 4220]
}

// A raw sensor-detected event (e.g., from accelerometer) [cite: 4207, 3264]
sig sensor_event {
    location: one GPS_point, // Where the event happened [cite: 4208]
    trip: one Trip           // The trip it happened on [cite: 4209]
}

// Abstract signature for all user-submitted reports [cite: 4221, 3259]
abstract sig Report {
    timestamp: one Timestamp,       // When the report was made [cite: 4222]
    author: one Registered_user,    // Who made the report [cite: 4223]
    path: one Path                  // The path this report is about [cite: 4224]
}

// A report about the path's general condition [cite: 4226, 3261]
sig Status_report extends Report {
    status: one PathStatus [cite: 4227]
}

// A report about a specific obstacle [cite: 4229, 3262]
sig Obstacle_report extends Report {
    type: one ObstacleType,         // Type of obstacle [cite: 4231]
    location: one GPS_point,        // Location of obstacle [cite: 4232]
    triggeredBy: lone sensor_event  // Optional link to a sensor event (R30) [cite: 4233, 3509]
}

// ----- 1.4 Static Invariants (Facts) -----

// Facts ensuring bidirectional relationships are consistent.
// e.g., if 'u' is a trip's owner, the trip must be in 'u.trips'.
fact BidirectionalConsistency {
    trips = ~owner              // Trip.owner [cite: 4235]
    createdPaths = ~creator     // Path.creator [cite: 4236]
    submittedReports = ~author  // Report.author [cite: 4237]
    reports = ~path             // Report.path [cite: 4238]
    performances = ~path        // Trip.path [cite: 4239]
    detections = ~trip          // sensor_event.trip [cite: 4240]
}

// A sensor_event can trigger at most one Obstacle_report.
fact OneReportPerEvent {
    all e: sensor_event | lone e.~triggeredBy
}

// Logic for sensor-confirmed obstacle reports (R28, R29, R30).
// If an Obstacle_report was triggered by a sensor_event, then:
// 1. The report's path must be the same as the event's trip's path.
// 2. The report's author must be the owner of the trip.
// 3. The event must be listed in the trip's detections.
fact ObstacleSensorConsistency {
    all r: Obstacle_report | some r.triggeredBy implies (
        r.path = r.triggeredBy.trip.path and
        r.author = r.triggeredBy.trip.owner and
        r.triggeredBy in r.triggeredBy.trip.detections
    ) [cite: 4241-4243, 4250-4258]
}

// Privacy rule: A 'Public' Trip must be on a 'Public' Path (R39).
fact PublicTripOnPublicPath {
    all t: Trip | t.tripVisibility = Public implies t.path.pathVisibility = Public
    [cite: 4259-4261]
}

// Privacy rule: A 'Private' Path can only have performances (Trips)
// recorded by the path's creator (R39).
fact PrivatePathOwnedTrips {
    all p: Path | p.pathVisibility = Private implies (
        all t: p.performances | t.owner = p.creator
    ) [cite: 4262-4270]
}
