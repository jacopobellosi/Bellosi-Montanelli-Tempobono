// ---------- BBP DYNAMIC MODEL (PART 2) - CORRECTED ----------
// This file models the "Automatic Recording" state machine (UC7, UC8)
// and the lifecycle of sensor_event detections.

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

// Abstract type for GPS coordinates
sig GPS_point {}

// Abstract type for computed trip statistics
sig Statistic {}

// Abstract type for weather data
sig Weather_info {}

// Abstract type for time, used in reports
abstract sig Timestamp {}

// ----- 1.3 Core Entities (Signatures) -----
// (Static definitions needed by the dynamic model)

// Abstract User
abstract sig User {}

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

// ---------- PART 2: DYNAMIC (TEMPORAL) MODEL ----------
// Models the "Automatic Recording" state machine (UC7, UC8)
// and the lifecycle of sensor_event detections.

// ----- 2.1 Mutable Signatures -----

// A RecordingSession holds the state for an active trip recording.
sig RecordingSession {
    tripRef: one Trip,                // The Trip being built
    var state: RecState,              // The current state of the session
    var pendingDetections: set sensor_event // Detections awaiting review
}

// A registered cyclist (RCY) - MUTABLE DEFINITION
sig Registered_user extends User {
    trips: set Trip,             // Trips this user owns
    createdPaths: set Path,      // Paths this user created
    submittedReports: set Report,// Reports this user authored
    var currentSession: lone RecordingSession // User's active session
}

// A raw sensor-detected event - MUTABLE DEFINITION
sig sensor_event {
    location: one GPS_point, // Where the event happened
    trip: one Trip,          // The trip it happened on
    var state: DetectionState // State: Pending -> Confirmed/Rejected
}

// ----- 2.2 Recording State Machine (Enum) -----

// Defines the states for the recording session
enum RecState { Idle, Recording, Paused, Reviewing, Stopped }

// ----- 2.3 State Transition Predicates -----

// Starts a new recording session
pred startRecording[u: Registered_user, s: RecordingSession, t: Trip] {
    no u.currentSession     // User has no active session
    s.state = Idle
    s.state' = Recording    // Set state to Recording
    s.tripRef = t           // Link the session to a new trip
    t.owner = u             // Set the trip's owner
    u.currentSession' = s   // Set user's active session
    // All other fields are unchanged
    s.pendingDetections' = s.pendingDetections
}

// Auto-pauses GPS recording
pred autoPause[s: RecordingSession] {
    s.state = Recording
    s.state' = Paused
    // All other fields are unchanged
    // --- CORRECTION: Use s.tripRef.owner to find the user ---
    s.tripRef.owner.currentSession' = s.tripRef.owner.currentSession
    s.pendingDetections' = s.pendingDetections
}

// Auto-resumes GPS recording
pred autoResume[s: RecordingSession] {
    s.state = Paused
    s.state' = Recording
    // All other fields are unchanged
    // --- CORRECTION: Use s.tripRef.owner to find the user ---
    s.tripRef.owner.currentSession' = s.tripRef.owner.currentSession
    s.pendingDetections' = s.pendingDetections
}

// Logs a new sensor event
pred logDetection[s: RecordingSession, e: sensor_event] {
    s.state = Recording     // Can only log while actively recording
    s.state' = Recording
    e.trip = s.tripRef      // Link event to the session's trip
    e.state = Pending       // Set event state to Pending
    e.state' = Pending
    e in s.pendingDetections'       // Add event to pending set
    e not in s.pendingDetections    // Ensure it's a new event
    // All other fields are unchanged
    // --- CORRECTION: Use s.tripRef.owner to find the user ---
    s.tripRef.owner.currentSession' = s.tripRef.owner.currentSession
}

// Moves to the review state
pred enterReview[s: RecordingSession] {
    s.state in Recording + Paused // Can stop from Recording or Paused
    some s.pendingDetections      // Only enter review if there are detections
    s.state' = Reviewing
    // All other fields are unchanged
    // --- CORRECTION: Use s.tripRef.owner to find the user ---
    s.tripRef.owner.currentSession' = s.tripRef.owner.currentSession
    s.pendingDetections' = s.pendingDetections
}

// User confirms a detection, creating an Obstacle_report
pred confirmDetection[s: RecordingSession, e: sensor_event, r: Obstacle_report] {
    s.state = Reviewing
    s.state' = Reviewing
    e in s.pendingDetections          // Event was pending
    e not in s.pendingDetections'     // Remove from pending set
    e.state' = Confirmed              // Set event state to Confirmed
    // Create and link the new report
    r.triggeredBy = e
    r.author = s.tripRef.owner
    r.path = s.tripRef.path
    // All other fields are unchanged
    // --- CORRECTION: Use s.tripRef.owner to find the user ---
    s.tripRef.owner.currentSession' = s.tripRef.owner.currentSession
}

// User rejects a detection
pred rejectDetection[s: RecordingSession, e: sensor_event] {
    s.state = Reviewing
    s.state' = Reviewing
    e in s.pendingDetections          // Event was pending
    e not in s.pendingDetections'     // Remove from pending set
    e.state' = Rejected               // Set event state to Rejected
    // All other fields are unchanged
    // --- CORRECTION: Use s.tripRef.owner to find the user ---
    s.tripRef.owner.currentSession' = s.tripRef.owner.currentSession
}

// Stops the session
pred stopRecording[u: Registered_user, s: RecordingSession] {
    s in u.currentSession
    // Can stop if in Reviewing, or if Recording/Paused with NO pending detections
    (s.state = Reviewing) or (s.state in Recording + Paused and no s.pendingDetections)
    s.state' = Stopped
    u.currentSession' = none // Clear the user's active session
    // All other fields are unchanged
    s.pendingDetections' = s.pendingDetections
}

// ----- 2.4 Temporal Facts -----
// (Static facts from Part 1 are also needed for consistency)

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

// Defines the allowed state transitions
fact StateMachine {
    // All sessions start Idle
    historically all s: RecordingSession | s.state = Idle
    
    // A session, once started, must eventually stop
    always all s: RecordingSession | (s.state = Recording implies eventually s.state = Stopped)
    
    // A session, once stopped, stays stopped
    always all s: RecordingSession | (s.state = Stopped implies after (always s.state = Stopped))

    // A pending event must eventually be reviewed
    always all s: RecordingSession, e: sensor_event |
        (e in s.pendingDetections and s.state = Recording) implies
            (eventually (e.state = Confirmed or e.state = Rejected))
            
    // A confirmed event must correspond to an Obstacle_report
    always all e: sensor_event |
        (e.state = Confirmed) implies
            (once some r: Obstacle_report | r.triggeredBy = e and r.author = e.trip.owner)
}

// ----- 3.2 Dynamic Model Verification -----

// PREDICATE to show a valid temporal flow
pred showRecordingFlow {
    some u: Registered_user, s: RecordingSession, t: Trip, e: sensor_event, r: Obstacle_report {
        // Use ';' to sequence the operations
        startRecording[u, s, t] ;
        logDetection[s, e] ;
        enterReview[s] ;
        confirmDetection[s, e, r] ;
        stopRecording[u, s]
    }
}

// COMMAND to run the temporal flow
// We must specify a scope for steps (e.g., 5 steps)
run showRecordingFlow for 2 Registered_user, 1 RecordingSession, 1 Trip, 1 sensor_event, 1 Obstacle_report, 3 Path, 3 Status_report, 5 GPS_point, 3 Statistic, 3 Weather_info, 3 Timestamp, 5 steps
