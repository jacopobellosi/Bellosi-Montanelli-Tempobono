// ---------- BBP COMPLETE MODEL (STATIC + DYNAMIC) ----------
// Auto–pause logic has been removed according to the updated RASD.

// ----- 1. Enumerations -----

enum PathStatus { Optimal, Medium, RequiresMaintenance }
enum ObstacleType { Pothole, Roadwork, Other }
enum Visibility { Public, Private }
// sensor_event lifecycle from the RASD state diagram
enum DetectionState { Logged, AwaitingConfirmation, Confirmed, Ignored }

// ----- 2. Basic Data Types -----

sig GPS_point {}
sig Statistic {}
sig Weather_info {}
sig Timestamp {}

// ----- 3. Static Domain Model -----

abstract sig User {}

sig Registered_user extends User {
    trips: set Trip,             // Trips this user owns
    createdPaths: set Path,      // Paths this user created
    submittedReports: set Report // Reports this user authored
}

sig Path {
    geometry: set GPS_point,       // The GPS points defining the path
    pathVisibility: one Visibility,// Visibility for search (R39)
    creator: one Registered_user,  // The user who created it
    reports: set Report,           // All reports for this path
    performances: set Trip         // All trips recorded on this path
}

// A specific, recorded cycling session
sig Trip {
    trace: set GPS_point,            // GPS trace of the ride (R21)
    stats: one Statistic,            // Calculated stats (avg speed, etc)
    weather: lone Weather_info,      // Weather at the time of the trip (R32)
    owner: one Registered_user,      // The user who recorded it
    path: one Path,                  // The path this trip was on
    tripVisibility: one Visibility,  // Visibility for stats (R39)
    detections: set sensor_event     // Sensor events logged on this trip (R23)
}

// A raw sensor-detected event (e.g., from accelerometer)
// Its state evolves according to the sensor_event state diagram.
sig sensor_event {
    location: one GPS_point,        // Where the event happened
    trip: one Trip,                 // The trip it happened on
    var state: one DetectionState   // Logged -> AwaitingConfirmation -> {Confirmed, Ignored}
}

// Abstract signature for all user-submitted reports
abstract sig Report {
    timestamp: one Timestamp,       // When the report was made (freshness)
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
    // This association is mutable: it is created when an event is confirmed.
    var triggeredBy: lone sensor_event
}

// ----- 4. Static Invariants (Facts) -----

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
// (manual reports have no triggeredBy).
fact ObstacleSensorConsistency {
    all r: Obstacle_report | some r.triggeredBy implies (
        r.path = r.triggeredBy.trip.path and
        r.author = r.triggeredBy.trip.owner and
        r.triggeredBy in r.triggeredBy.trip.detections
    )
}

// Privacy rule: A 'Public' Trip must be on a 'Public' Path. (R39)
fact PublicTripOnPublicPath {
    all t: Trip |
        t.tripVisibility = Public implies t.path.pathVisibility = Public
}

// Privacy rule: A 'Private' Path can only have performances (Trips)
// recorded by the path's creator. (R39)
fact PrivatePathOwnedTrips {
    all p: Path |
        p.pathVisibility = Private implies
            all t: p.performances | t.owner = p.creator
}

// ----- 5. Dynamic Model for sensor_event & Obstacle_report -----
// Usa campi mutabili (var) + operatori temporali di Alloy 6.
// Modella lo state diagram di Figura 2.3 del RASD:
// Logged -> AwaitingConfirmation -> Confirmed / Ignored.

// --- 5.1 Transition predicates ---

// Il trip è finito e l’evento entra nella schermata di review.
pred startReview[e: sensor_event] {
    e.state = Logged
    e.state' = AwaitingConfirmation
    // Frame condition: tutti gli altri eventi mantengono lo stato.
    all e2: sensor_event - e | e2.state' = e2.state
    // Nessun report viene creato/modificato in questo passo.
    triggeredBy' = triggeredBy
}

// L’utente conferma una detection; si crea/lega un Obstacle_report.
pred confirmDetection[e: sensor_event, r: Obstacle_report] {
    e.state = AwaitingConfirmation
    e.state' = Confirmed

    // Il report scelto non era già associato.
    no r.triggeredBy
    r.triggeredBy' = e

    // Frame conditions
    all e2: sensor_event - e | e2.state' = e2.state
    all r2: Obstacle_report - r | r2.triggeredBy' = r2.triggeredBy
}

// L’utente rifiuta una detection.
pred rejectDetection[e: sensor_event] {
    e.state = AwaitingConfirmation
    e.state' = Ignored

    // Frame conditions
    all e2: sensor_event - e | e2.state' = e2.state
    triggeredBy' = triggeredBy
}

// Nessun cambiamento nello stato mutabile.
pred doNothing {
    state' = state
    triggeredBy' = triggeredBy
}

// --- 5.2 Global behaviour & liveness ---

fact DetectionLifecycle {
    // Stato iniziale: tutti gli eventi sono appena Logged e nessun report è collegato.
    all e: sensor_event | e.state = Logged
    no triggeredBy

    // Ad ogni passo avviene una delle operazioni base.
    always (
        doNothing
        or some e: sensor_event | startReview[e]
        or some e: sensor_event, r: Obstacle_report | confirmDetection[e, r]
        or some e: sensor_event | rejectDetection[e]
    )
}

// Fairness: un evento che è in AwaitingConfirmation viene
// prima o poi confermato o ignorato (non resta "pending" per sempre).
fact Fairness {
    always (all e: sensor_event |
        e.state = AwaitingConfirmation implies
            eventually (e.state = Confirmed or e.state = Ignored)
    )
}

// ----- 6. Static Model Verification (as in the RASD) -----

// PREDICATE to find a rich static instance.
pred FindPublicPathWithActivity {
    some p: Path {
        // A Public Path (R39)
        p.pathVisibility = Public

        // With at least two Trips on it, from different owners
        some disj t1, t2: Trip {
            t1.path = p and t2.path = p
            t1.tripVisibility = Public
            t2.tripVisibility = Private
            t1.owner != t2.owner
        }

        // And at least one obstacle report
        some r: Obstacle_report | r.path = p
    }
}

// COMMAND to run the predicate (purely static analysis)
run FindPublicPathWithActivity
    for 3 Path, 3 Trip, 3 Registered_user,
        5 GPS_point, 3 Statistic, 3 Weather_info,
        3 Timestamp, 3 Report, 3 sensor_event

// ASSERTION to check the Public Trip/Path privacy rule (R39)
assert PublicTripsOnPublicPaths {
    all t: Trip |
        t.tripVisibility = Public implies t.path.pathVisibility = Public
}

// ASSERTION to check the Private Path privacy rule (R39)
assert PrivatePathPrivacy {
    all p: Path |
        p.pathVisibility = Private implies
            all t: p.performances | t.owner = p.creator
}

// COMMANDS to check the assertions (static checks)
check PublicTripsOnPublicPaths for 5
check PrivatePathPrivacy for 5

// ----- 7. Dynamic Model Verification -----

// Safety: ogni volta che un evento è Confirmed
// esiste qualche Obstacle_report collegato ad esso.
assert ConfirmedImpliesReport {
    always (all e: sensor_event |
        e.state = Confirmed implies
            some r: Obstacle_report | r.triggeredBy = e
    )
}

// Liveness: ogni evento che arriva in AwaitingConfirmation
// viene prima o poi deciso (Confirmed o Ignored).
assert AwaitingEventuallyDecided {
    always (all e: sensor_event |
        e.state = AwaitingConfirmation implies
            eventually (e.state = Confirmed or e.state = Ignored)
    )
}

// COMMANDS to check the dynamic assertions
check ConfirmedImpliesReport for 3 but 10 steps
check AwaitingEventuallyDecided for 3 but 10 steps

// Example predicate to visualise a full lifecycle:
// un evento che parte Logged ed è poi Confermato.
pred showEventLifecycle {
    some e: sensor_event |
        e.state = Logged and
        eventually e.state = Confirmed
}

// Run the dynamic scenario for a bounded trace.
run showEventLifecycle for 3 but 5 steps
