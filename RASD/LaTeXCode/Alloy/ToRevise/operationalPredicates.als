pred op_goToRegisterScreen(s, s': State) {
    s.currentScreen = MainMap
    s.loggedInUser in AnonymousUser

    s'.currentScreen = Register

    unchanged_session(s, s')
    unchanged_data(s, s')
    unchanged_app_context(s, s')
}

pred op_goToLoginScreen(s, s': State) {
    s.currentScreen = MainMap

    s'.currentScreen = Login

    unchanged_session(s, s')
    unchanged_data(s, s')
    unchanged_app_context(s, s')
}

pred op_Register_Valid(s, s': State, u: AnonymousUser, newUser: RegisteredUser, name, email, pass: String, tok: SessionToken) {
    s.currentScreen = Register
    s.loggedInUser = u
    email not in RegisteredUser.email
    name not in RegisteredUser.username
    tok not in s.validTokens

    s'.validTokens = s.validTokens + tok
    s'.userSessions = s.userSessions + (newUser -> tok)
    s'.appLocalToken = tok
    s'.loggedInUser = newUser
    s'.currentScreen = MainMap

    unchanged_data(s, s')
    unchanged_app_context(s, s')
}

pred op_Login_Valid(s, s': State, userInDb: RegisteredUser, pass: String, tok: SessionToken) {
    s.currentScreen = Login
    userInDb.password = pass
    tok not in s.validTokens

    s'.validTokens = s.validTokens + tok
    s'.userSessions = s.userSessions + (userInDb -> tok)
    s'.appLocalToken = tok
    s'.loggedInUser = userInDb
    s'.currentScreen = MainMap

    unchanged_data(s, s')
    unchanged_app_context(s, s')
}

pred op_Login_Invalid(s, s': State, user: RegisteredUser, pass: String) {
    s.currentScreen = Login
    user.password != pass

    s' = s
}

pred op_Logout(s, s': State, u: RegisteredUser) {
    s.loggedInUser = u
    s.appLocalToken in s.validTokens

    s'.validTokens = s.validTokens - s.appLocalToken
    s'.userSessions = s.userSessions - (u -> s.appLocalToken)
    no s'.appLocalToken
    s'.loggedInUser in AnonymousUser
    s'.currentScreen = MainMap

    unchanged_data(s, s')
    unchanged_app_context(s, s')
}

pred op_SearchPaths(s, s': State) {
    s.currentScreen = MainMap

    s'.currentScreen = SearchResults

    unchanged_session(s, s')
    unchanged_data(s, s')
    unchanged_app_context(s, s')
}

pred op_ViewPathDetails(s, s': State, p: Path) {
    p in s.paths

    s'.currentScreen = PathDetails

    unchanged_session(s, s')
    unchanged_data(s, s')
    unchanged_app_context(s, s')
}

pred op_StartRecording(s, s': State, u: RegisteredUser, newTrip: Trip) {
    s.loggedInUser = u
    s.currentScreen = MainMap
    no s.appTripData

    s'.currentScreen = RecordingHUD
    s'.appTripData = newTrip { owner = u }

    unchanged_session(s, s')
    unchanged_data(s, s')
    unchanged_app_path_creation(s, s')
    s'.pendingDetections = s.pendingDetections
    s'.confirmedDetections = s.confirmedDetections
}

pred op_StopRecording(s, s': State, u: RegisteredUser) {
    s.loggedInUser = u
    s.currentScreen = RecordingHUD
    some s.appTripData

    s'.currentScreen = SummaryAndSave
    s'.pendingDetections = s.appTripData.detections
    s'.appTripData = s.appTripData

    unchanged_session(s, s')
    unchanged_data(s, s')
    unchanged_app_path_creation(s, s')
    s'.confirmedDetections = s.confirmedDetections
}

pred op_ReviewDetections(s, s': State, u: RegisteredUser, confirmed: set Detection, ignored: set Detection) {
    s.loggedInUser = u
    s.currentScreen = SummaryAndSave
    confirmed in s.pendingDetections
    ignored in s.pendingDetections
    no (confirmed & ignored)

    s'.pendingDetections = s.pendingDetections - (confirmed + ignored)
    s'.confirmedDetections = s.confirmedDetections + confirmed
    s'.currentScreen = s.currentScreen
    s'.appTripData = s.appTripData

    unchanged_session(s, s')
    unchanged_data(s, s')
    unchanged_app_path_creation(s, s')
}

pred op_SaveTripAndPath(s, s': State, u: RegisteredUser, newPath: Path, tripName, pathName: String, tripVis, pathVis: Visibility) {
    s.loggedInUser = u
    s.currentScreen = SummaryAndSave
    some s.appTripData
    newPath not in s.paths

    let finalPath = newPath {
        name = pathName,
        visibility = pathVis,
        geometry = s.appTripData.rawPoints,
        reports = none,
        creator = u
    }
    let finalTrip = s.appTripData {
        name = tripName,
        visibility = tripVis,
        detections = s.confirmedDetections,
        associatedPath = finalPath
    }

    s'.paths = s.paths + finalPath
    s'.trips = s.trips + finalTrip

    s'.currentScreen = MyTripsList
    no s'.appTripData
    no s'.pendingDetections
    no s'.confirmedDetections

    s'.reports = s.reports
    unchanged_session(s, s')
    unchanged_app_path_creation(s, s')
}

pred op_DiscardTrip(s, s': State, u: RegisteredUser) {
    s.loggedInUser = u
    s.currentScreen = SummaryAndSave

    s'.currentScreen = MainMap
    no s'.appTripData
    no s'.pendingDetections
    no s'.confirmedDetections

    unchanged_data(s, s')
    unchanged_session(s, s')
    unchanged_app_path_creation(s, s')
}

pred op_StartManualPath(s, s': State, u: RegisteredUser, newPath: Path) {
    s.loggedInUser = u
    s.currentScreen = MainMap
    newPath not in s.paths

    s'.currentScreen = ManualEditor
    s'.appPathData = newPath { creator = u }

    unchanged_session(s, s')
    unchanged_data(s, s')
    unchanged_app_trip_recording(s, s')
}

pred op_FinishManualPath(s, s': State, u: RegisteredUser) {
    s.loggedInUser = u
    s.currentScreen = ManualEditor
    some s.appPathData

    s'.currentScreen = SavePath
    s'.appPathData = s.appPathData

    unchanged_session(s, s')
    unchanged_data(s, s')
    unchanged_app_trip_recording(s, s')
}

pred op_SaveManualPath(s, s': State, u: RegisteredUser, pathName: String, pathVis: Visibility) {
    s.loggedInUser = u
    s.currentScreen = SavePath
    some s.appPathData

    let finalPath = s.appPathData {
        name = pathName,
        visibility = pathVis
    }

    s'.paths = s.paths + finalPath
    s'.currentScreen = MainMap
    no s'.appPathData

    unchanged_session(s, s')
    s'.trips = s.trips
    s'.reports = s.reports
    unchanged_app_trip_recording(s, s')
}

pred op_DiscardManualPath(s, s': State, u: RegisteredUser) {
    s.loggedInUser = u
    s.currentScreen = SavePath

    s'.currentScreen = MainMap
    no s'.appPathData

    unchanged_session(s, s')
    unchanged_data(s, s')
    unchanged_app_trip_recording(s, s')
}

pred op_ViewMyTrips(s, s': State, u: RegisteredUser) {
    s.loggedInUser = u

    s'.currentScreen = MyTripsList

    unchanged_session(s, s')
    unchanged_data(s, s')
    unchanged_app_context(s, s')
}

pred op_ViewTripDetails(s, s': State, u: RegisteredUser, t: Trip) {
    s.loggedInUser = u
    s.currentScreen = MyTripsList
    t in s.trips and t.owner = u

    s'.currentScreen = TripDetails

    unchanged_session(s, s')
    unchanged_data(s, s')
    unchanged_app_context(s, s')
}

pred op_AddStatusReport(s, s': State, u: RegisteredUser, p: Path, newReport: StatusReport) {
    s.loggedInUser = u
    s.currentScreen = PathDetails
    p in s.paths
    newReport not in s.reports

    s'.reports = s.reports + newReport
    s'.paths = s.paths - p + p { reports = p.reports + newReport }
    s'.currentScreen = PathDetails

    unchanged_session(s, s')
    s'.trips = s.trips
    unchanged_app_context(s, s')
}

pred op_AddObstacleReport(s, s': State, u: RegisteredUser, p: Path, newReport: ObstacleReport) {
    s.loggedInUser = u
    s.currentScreen = PathDetails
    p in s.paths
    newReport not in s.reports

    s'.reports = s.reports + newReport
    s'.paths = s.paths - p + p { reports = p.reports + newReport }
    s'.currentScreen = PathDetails

    unchanged_session(s, s')
    s'.trips = s.trips
    unchanged_app_context(s, s')
}
