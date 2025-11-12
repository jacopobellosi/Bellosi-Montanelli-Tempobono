// ---------- PART 3: VERIFICATION AND ANALYSIS ----------

// ----- 3.1 Static Model Verification -----

// PREDICATE to find a valid instance of the static model
// This predicate describes a "happy path" scenario from the RASD.
pred FindPublicPathWithActivity {
    some p: Path {
        // Find a Public Path (R39) [cite: 4273-4275]
        p.pathVisibility = Public
        
        // That has at least two trips (performances) [cite: 4276-4278]
        some disj t1, t2: Trip {
            t1.path = p and t2.path = p
            
            // One trip is public, one is private [cite: 4279-4282]
            t1.tripVisibility = Public
            t2.tripVisibility = Private
            
            // From different owners [cite: 4281]
            t1.owner != t2.owner
        }
        // And has at least one obstacle report [cite: 4283-4287]
        some r: Obstacle_report {
            r.path = p
        }
    }
}

// COMMAND to run the predicate
run FindPublicPathWithActivity for 3 Path, 3 Trip, 3 Registered_user, 5 GPS_point, 3 Statistic, 3 Weather_info, 3 Report, 3 sensor_event [cite: 4291]

// ASSERTION to check the Public Trip/Path privacy rule (R39)
assert PublicTripsOnPublicPaths {
    all t: Trip {
        t.tripVisibility = Public implies t.path.pathVisibility = Public
    }
} [cite: 4292-4296]

// ASSERTION to check the Private Path privacy rule (R39)
assert PrivatePathPrivacy {
    all p: Path {
        p.pathVisibility = Private implies {
            all t: p.performances {
                t.owner = p.creator
            }
        }
    }
} [cite: 4297-4307]

// COMMANDS to check the assertions
check PublicTripsOnPublicPaths for 5 [cite: 4308]
check PrivatePathPrivacy for 5 [cite: 4309]

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
run showRecordingFlow for 2 Registered_user, 1 RecordingSession, 1 Trip, 1 sensor_event, 1 Obstacle_report, 5 steps
