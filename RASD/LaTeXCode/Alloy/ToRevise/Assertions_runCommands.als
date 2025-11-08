assert LogoutInvalidatesToken {
    all s, s': State, u: RegisteredUser |
        op_Logout(s, s', u) implies {
            s.appLocalToken not in s'.validTokens
            no s'.appLocalToken
            s'.loggedInUser in AnonymousUser
        }
}
check LogoutInvalidatesToken for 5

assert DiscardingTripDoesNotSaveData {
    all s, s': State, u: RegisteredUser |
        op_DiscardTrip(s, s', u) implies {
            s'.paths = s.paths
            s'.trips = s.trips
            no s'.appTripData
        }
}
check DiscardingTripDoesNotSaveData for 5

assert AnonymousUserCannotReport {
    all s, s': State, u: AnonymousUser, p: Path, r: StatusReport |
        not op_AddStatusReport(s, s', u, p, r)
}
check AnonymousUserCannotReport for 5

pred RegisterLoginFlow(s_init, s_reg, s_logout, s_login: State,
                       anon: AnonymousUser, newUser: RegisteredUser,
                       name, email, pass: String,
                       tok1, tok2: SessionToken) {

    init(s_init)

    op_Register_Valid(s_init, s_reg, anon, newUser, name, email, pass, tok1)

    op_Logout(s_reg, s_logout, newUser)

    op_Login_Valid(s_logout, s_login, newUser, pass, tok2)

    s_login.loggedInUser = newUser
}
run RegisterLoginFlow for 4 State, 2 SystemUser, 3 String, 2 SessionToken

pred FullRecordAndSaveFlow(s_init, s_start, s_stop, s_review, s_save: State,
                           u: RegisteredUser,
                           trip: Trip, path: Path,
                           d_conf, d_ign: Detection,
                           tName, pName: String) {

    init(s_init)
    s_init.loggedInUser = u
    s_init.appLocalToken in s_init.validTokens

    op_StartRecording(s_init, s_start, u, trip)

    trip.detections = d_conf + d_ign
    op_StopRecording(s_start, s_stop, u)

    op_ReviewDetections(s_stop, s_review, u, d_conf, d_ign)

    op_SaveTripAndPath(s_review, s_save, u, path, tName, pName, Public, Public)

    path in s_save.paths
    trip in s_save.trips
    s_save.trips.detections = d_conf
}
run FullRecordAndSaveFlow for 5 State, 1 RegisteredUser, 1 Trip, 1 Path, 2 Detection, 2 String
