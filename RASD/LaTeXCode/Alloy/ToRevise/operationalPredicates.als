-- =====================================================
-- Core Signatures
-- =====================================================

abstract sig User {}
sig AnonymousUser extends User {}
sig RegisteredUser extends User {
    username: one String,
    email: one String,
    password: one String
}

sig SessionToken {}

abstract sig Screen {}
one sig MainMap, Login, Register, RecordingHUD, SummaryAndSave, SavePath,
         ManualEditor, SearchResults, MyTripsList, TripDetails, PathDetails extends Screen {}

abstract sig Visibility {}
one sig Public, Private extends Visibility {}

sig Detection {}

abstract sig Report {}
sig StatusReport, ObstacleReport extends Report {}

sig Path {
    name: one String,
    visibility: one Visibility,
    creator: lone RegisteredUser,
    reports: set Report
}

sig Trip {
    owner: one RegisteredUser,
    detections: set Detection
}

-- =====================================================
-- System State
-- =====================================================

sig State {
    currentScreen: one Screen,
    loggedInUser: one User,
    paths: set Path,
    trips: set Trip,
    reports: set Report,
    appPathData: lone Path,
    appTripData: lone Trip,
    validTokens: set SessionToken,
    userSessions: User -> lone SessionToken,
    appLocalToken: lone SessionToken,
    pendingDetections: set Detection,
    confirmedDetections: set Detection
}

-- =====================================================
-- Helper predicates for unchanged parts of the system
-- =====================================================

pred unchanged_session[s, s2: State] {
    s2.validTokens = s.validTokens
    and s2.userSessions = s.userSessions
    and s2.appLocalToken = s.appLocalToken
}

pred unchanged_data[s, s2: State] {
    s2.paths = s.paths
    and s2.trips = s.trips
    and s2.reports = s.reports
}

pred unchanged_app_context[s, s2: State] {
    s2.pendingDetections = s.pendingDetections
    and s2.confirmedDetections = s.confirmedDetections
    and s2.appTripData = s.appTripData
    and s2.appPathData = s.appPathData
}

pred unchanged_app_path_creation[s, s2: State] {
    s2.appPathData = s.appPathData
}

pred unchanged_app_trip_recording[s, s2: State] {
    s2.appTripData = s.appTripData
}

-- =====================================================
-- Operations
-- =====================================================

pred op_goToRegisterScreen(s, s2: State) {
    s.currentScreen = MainMap
    and s.loggedInUser in AnonymousUser

    and s2.currentScreen = Register

    and unchanged_session[s, s2]
    and unchanged_data[s, s2]
    and unchanged_app_context[s, s2]
}

pred op_goToLoginScreen(s, s2: State) {
    s.currentScreen = MainMap

    and s2.currentScreen = Login

    and unchanged_session[s, s2]
    and unchanged_data[s, s2]
    and unchanged_app_context[s, s2]
}

pred op_Register_Valid(
    s, s2: State,
    u: AnonymousUser,
    newUser: RegisteredUser,
    newName, newEmail, newPass: String,
    tok: SessionToken
) {
    s.currentScreen = Register
    and s.loggedInUser = u
    and newEmail not in RegisteredUser.email
    and newName not in RegisteredUser.username
    and tok not in s.validTokens

    and s2.validTokens = s.validTokens + tok
    and s2.userSessions = s.userSessions + (newUser -> tok)
    and s2.appLocalToken = tok
    and s2.loggedInUser = newUser
    and s2.currentScreen = MainMap

    and unchanged_data[s, s2]
    and unchanged_app_context[s, s2]
}


pred op_Login_Valid(s, s2: State, userInDb: RegisteredUser, pass: String, tok: SessionToken) {
    s.currentScreen = Login
    and userInDb.password = pass
    and tok not in s.validTokens

    and s2.validTokens = s.validTokens + tok
    and s2.userSessions = s.userSessions + (userInDb -> tok)
    and s2.appLocalToken = tok
    and s2.loggedInUser = userInDb
    and s2.currentScreen = MainMap

    and unchanged_data[s, s2]
    and unchanged_app_context[s, s2]
}

pred op_Login_Invalid(s, s2: State, user: RegisteredUser, pass: String) {
    s.currentScreen = Login
    and user.password != pass

    and s2 = s
}

pred op_Logout(s, s2: State, u: RegisteredUser) {
    s.loggedInUser = u
    and s.appLocalToken in s.validTokens

    and s2.validTokens = s.validTokens - s.appLocalToken
    and s2.userSessions = s.userSessions - (u -> s.appLocalToken)
    and no s2.appLocalToken
    and s2.loggedInUser in AnonymousUser
    and s2.currentScreen = MainMap

    and unchanged_data[s, s2]
    and unchanged_app_context[s, s2]
}

pred op_SearchPaths(s, s2: State) {
    s.currentScreen = MainMap

    and s2.currentScreen = SearchResults

    and unchanged_session[s, s2]
    and unchanged_data[s, s2]
    and unchanged_app_context[s, s2]
}

pred op_ViewPathDetails(s, s2: State, p: Path) {
    p in s.paths

    and s2.currentScreen = PathDetails

    and unchanged_session[s, s2]
    and unchanged_data[s, s2]
    and unchanged_app_context[s, s2]
}

pred op_StartRecording(s, s2: State, u: RegisteredUser, newTrip: Trip) {
    s.loggedInUser = u
    and s.currentScreen = MainMap
    and no s.appTripData

    and s2.currentScreen = RecordingHUD
    and s2.appTripData = newTrip
    and newTrip.owner = u

    and unchanged_session[s, s2]
    and unchanged_data[s, s2]
    and unchanged_app_path_creation[s, s2]
    and s2.pendingDetections = s.pendingDetections
    and s2.confirmedDetections = s.confirmedDetections
}


pred op_StopRecording(s, s2: State, u: RegisteredUser) {
    s.loggedInUser = u
    and s.currentScreen = RecordingHUD
    and some s.appTripData

    and s2.currentScreen = SummaryAndSave
    and s2.pendingDetections = s.appTripData.detections
    and s2.appTripData = s.appTripData

    and unchanged_session[s, s2]
    and unchanged_data[s, s2]
    and unchanged_app_path_creation[s, s2]
    and s2.confirmedDetections = s.confirmedDetections
}

pred op_ReviewDetections(s, s2: State, u: RegisteredUser, confirmed: set Detection, ignored: set Detection) {
    s.loggedInUser = u
    and s.currentScreen = SummaryAndSave
    and confirmed in s.pendingDetections
    and ignored in s.pendingDetections
    and no (confirmed & ignored)

    and s2.pendingDetections = s.pendingDetections - (confirmed + ignored)
    and s2.confirmedDetections = s.confirmedDetections + confirmed
    and s2.currentScreen = s.currentScreen
    and s2.appTripData = s.appTripData

    and unchanged_session[s, s2]
    and unchanged_data[s, s2]
    and unchanged_app_path_creation[s, s2]
}

pred op_FinishManualPath(s, s2: State, u: RegisteredUser) {
    s.loggedInUser = u
    and s.currentScreen = ManualEditor
    and some s.appPathData

    and s2.currentScreen = SavePath
    and s2.appPathData = s.appPathData

    and unchanged_session[s, s2]
    and unchanged_data[s, s2]
    and unchanged_app_trip_recording[s, s2]
}

pred op_SaveManualPath(s, s2: State, u: RegisteredUser, pathName: String, pathVis: Visibility) {
    s.loggedInUser = u
    and s.currentScreen = SavePath
    and some s.appPathData

    some finalPath: Path | (
        finalPath = s.appPathData
        and finalPath.name = pathName
        and finalPath.visibility = pathVis

        and s2.paths = s.paths + finalPath
        and s2.currentScreen = MainMap
        and no s2.appPathData

        and unchanged_session[s, s2]
        and s2.trips = s.trips
        and s2.reports = s.reports
        and unchanged_app_trip_recording[s, s2]
    )
}

pred op_DiscardManualPath(s, s2: State, u: RegisteredUser) {
    s.loggedInUser = u
    and s.currentScreen = SavePath

    and s2.currentScreen = MainMap
    and no s2.appPathData

    and unchanged_session[s, s2]
    and unchanged_data[s, s2]
    and unchanged_app_trip_recording[s, s2]
}
