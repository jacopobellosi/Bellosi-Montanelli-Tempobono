/*
 * -----------------------------------------------------------------
 * Alloy Formal Analysis for BBP Use Cases (UC 1-15)
 * -----------------------------------------------------------------
 */

sig GpsPoint {}
sig Detection {}

abstract sig SystemUser {}

sig RegisteredUser extends SystemUser {
    username: one String,
    email: one String,
    password: one String
}
sig AnonymousUser extends SystemUser {}

one sig App {}
one sig Server {}
one sig WeatherService {}
one sig Sensors {}

enum Visibility { Public, Private }
sig SessionToken {}

abstract sig Report {
    submittedBy: one RegisteredUser,
    onPath: one Path
}
sig StatusReport extends Report {}
sig ObstacleReport extends Report {}

sig Path {
    name: one String,
    visibility: one Visibility,
    geometry: set GpsPoint,
    reports: set Report,
    creator: one SystemUser
}

sig Trip {
    name: lone String,
    visibility: one Visibility,
    rawPoints: set GpsPoint,
    detections: set Detection,
    associatedPath: lone Path,
    owner: one RegisteredUser
}

enum Screen {
    MainMap,
    Login,
    Register,
    RecordingHUD,
    SummaryAndSave,
    SummaryAndReview,
    MyTripsList,
    TripDetails,
    PathDetails,
    SearchResults,
    ManualEditor,
    SavePath,
    ReportForm,
    NavigationSummary
}

sig State {
    validTokens: set SessionToken,
    userSessions: SystemUser -> lone SessionToken,
    appLocalToken: lone SessionToken,
    loggedInUser: one SystemUser,

    paths: set Path,
    trips: set Trip,
    reports: set Report,

    currentScreen: one Screen,
    appTripData: lone Trip,
    appPathData: lone Path,
    pendingDetections: set Detection,
    confirmedDetections: set Detection
}


pred unchanged_data(s, s2: State) {
    s2.paths = s.paths
    s2.trips = s.trips
    s2.reports = s.reports
}

pred unchanged_session(s, s2: State) {
    s2.validTokens = s.validTokens
    s2.userSessions = s.userSessions
    s2.appLocalToken = s.appLocalToken
    s2.loggedInUser = s.loggedInUser
}

pred unchanged_app_context(s, s2: State) {
    s2.appTripData = s.appTripData
    s2.appPathData = s.appPathData
    s2.pendingDetections = s.pendingDetections
    s2.confirmedDetections = s.confirmedDetections
}

pred unchanged_app_trip_recording(s, s2: State) {
    s2.appTripData = s.appTripData
    s2.pendingDetections = s.pendingDetections
    s2.confirmedDetections = s.confirmedDetections
}

pred unchanged_app_path_creation(s, s2: State) {
    s2.appPathData = s.appPathData
}

pred init(s: State) {
    no s.validTokens
    no s.userSessions
    no s.appLocalToken
    s.loggedInUser in AnonymousUser

    no s.paths
    no s.trips
    no s.reports

    s.currentScreen = MainMap
    no s.appTripData
    no s.appPathData
    no s.pendingDetections
    no s.confirmedDetections
}
