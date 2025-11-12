// ---------- PART 2: DYNAMIC (TEMPORAL) MODEL ----------
// Models the "Automatic Recording" state machine (UC7, UC8)
// and the lifecycle of sensor_event detections.

// Import the static model definitions
// (Assumes Part 1 is in the same file or opened)

// ----- 2.1 Mutable Signatures -----

// A RecordingSession holds the state for an active trip recording.
sig RecordingSession {
    tripRef: one Trip,                // The Trip being built
    var state: RecState,              // The current state of the session
    var pendingDetections: set sensor_event // Detections awaiting review (R28) [cite: 3399]
}

// Add mutable state to sensor_event
sig sensor_event {
    var state: DetectionState // State: Pending -> Confirmed/Rejected [cite: 3194, 3203]
}

// Add a mutable field to the user to track their session
sig Registered_user {
    var currentSession: lone RecordingSession
}

// ----- 2.2 Recording State Machine (Enum) -----

// Defines the states for the recording session (UC7) [cite: 3404-3419]
enum RecState { Idle, Recording, Paused, Reviewing, Stopped }

// ----- 2.3 State Transition Predicates -----

// Starts a new recording session (R20)
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

// Auto-pauses GPS recording (R25)
pred autoPause[s: RecordingSession] {
    s.state = Recording
    s.state' = Paused
    // All other fields are unchanged
    u.currentSession' = u.currentSession
    s.pendingDetections' = s.pendingDetections
}

// Auto-resumes GPS recording (R26)
pred autoResume[s: RecordingSession] {
    s.state = Paused
    s.state' = Recording
    // All other fields are unchanged
    u.currentSession' = u.currentSession
    s.pendingDetections' = s.pendingDetections
}

// Logs a new sensor event (R24)
pred logDetection[s: RecordingSession, e: sensor_event] {
    s.state = Recording     // Can only log while actively recording
    s.state' = Recording
    e.trip = s.tripRef      // Link event to the session's trip
    e.state = Pending       // Set event state to Pending
    e.state' = Pending
    e in s.pendingDetections'       // Add event to pending set
    e not in s.pendingDetections    // Ensure it's a new event
    // All other fields are unchanged
    u.currentSession' = u.currentSession
}

// Moves to the review state (R28)
pred enterReview[s: RecordingSession] {
    s.state in Recording + Paused // Can stop from Recording or Paused
    some s.pendingDetections      // Only enter review if there are detections
    s.state' = Reviewing
    // All other fields are unchanged
    u.currentSession' = u.currentSession
    s.pendingDetections' = s.pendingDetections
}

// User confirms a detection (R29), creating an Obstacle_report (R30)
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
    u.currentSession' = u.currentSession
}

// User rejects a detection (R29)
pred rejectDetection[s: RecordingSession, e: sensor_event] {
    s.state = Reviewing
    s.state' = Reviewing
    e in s.pendingDetections          // Event was pending
    e not in s.pendingDetections'     // Remove from pending set
    e.state' = Rejected               // Set event state to Rejected
    // All other fields are unchanged
    u.currentSession' = u.currentSession
}

// Stops the session (R27)
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
