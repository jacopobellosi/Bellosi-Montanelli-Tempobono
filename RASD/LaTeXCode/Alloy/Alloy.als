enum PathStatus { Optimal, Medium, RequiresMaintenance }
enum ObstacleType { Pothole, Roadwork, Other }
enum Visibility { Public, Private }

sig GPS_point {}
sig Statistic {}
sig Weather_info {}

sig Registered_user {
    trips: set Trip,
    createdPaths: set Path,
    submittedReports: set Report
}

sig Path {
    geometry: set GPS_point,
    pathVisibility: one Visibility,
    creator: one Registered_user,
    reports: set Report,
    performances: set Trip
}

sig sensor_event {
    location: one GPS_point,
    trip: one Trip
}

sig Trip {
    trace: set GPS_point,
    stats: one Statistic,
    weather: one Weather_info,
    owner: one Registered_user,
    path: one Path,
    tripVisibility: one Visibility,
    detections: set sensor_event
}

abstract sig Report {
    timestamp: one Int,
    author: one Registered_user,
    path: one Path
}

sig Status_report extends Report {
    status: one PathStatus
}

sig Obstacle_report extends Report {
    type: one ObstacleType,
    location: one GPS_point,
    triggeredBy: lone sensor_event
}

fact ModelInvariants {
    trips = ~owner
    createdPaths = ~creator
    submittedReports = ~author
    reports = ~path
    performances = ~path
    detections = ~trip

    all r: Obstacle_report {
        some r.triggeredBy
    }

    all e: sensor_event {
        lone e.~triggeredBy
    }

    all r: Obstacle_report {
        r.path = r.triggeredBy.trip.path
    }

    all r: Obstacle_report {
        r.author = r.triggeredBy.trip.owner
    }

    all r: Obstacle_report {
        r.triggeredBy in r.triggeredBy.trip.detections
    }

    all t: Trip {
        t.tripVisibility = Public implies t.path.pathVisibility = Public
    }
    
    all p: Path {
        p.pathVisibility = Private implies {
            all t: p.performances {
                t.owner = p.creator
            }
        }
    }
}

pred FindPublicPathWithActivity {
    some p: Path {
        p.pathVisibility = Public
        some disj t1, t2: Trip {
            t1.path = p and t2.path = p
            t1.tripVisibility = Public
            t2.tripVisibility = Private
            t1.owner != t2.owner
        }
        some r: Obstacle_report {
            r.path = p
        }
    }
}
run FindPublicPathWithActivity for 3 Path, 3 Trip, 3 Registered_user, 5 GPS_point, 3 Statistic, 3 Weather_info, 3 Report, 3 sensor_event
assert PublicTripsOnPublicPaths {
    all t: Trip {
        t.tripVisibility = Public implies t.path.pathVisibility = Public
    }
}

assert PrivatePathPrivacy {
    all p: Path {
        p.pathVisibility = Private implies {
            all t: p.performances {
                t.owner = p.creator
            }
        }
    }
}
check PublicTripsOnPublicPaths for 5
check PrivatePathPrivacy for 5
