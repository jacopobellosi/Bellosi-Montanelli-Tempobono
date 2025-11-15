sequenceDiagram
    actor "User" as User
    participant "BBP Application" as App
    actor "External navigation service" as NavService
    actor "Device Sensors (GPS)" as GPS

    User->App: taps "Follow Path" (R15)
    activate App

    /'
       Step 1: BBP sends the route to the external app
       (as per SP22 and Figure 2.6).
    '/
    App->NavService: openWithRoute(pathGeometry)
    activate NavService
    NavService-->User: [Shows Turn-by-Turn Navigation]

    /'
       Step 2: BBP *also* starts recording stats
       in the background (as per UC6 Event Flow).
    '/
    App->GPS: startLocationUpdates()
    activate GPS

    loop Background Updates
        /'
           The app doesn't show a map, but it collects
           GPS data to calculate stats (Step 4, 5).
        '/
        GPS-->App: onLocationChanged(newLocation)

        /' --- BUG FIX --- '/
        /' Removed redundant activate/deactivate. '/
        /' The App is already active, so this is just a self-message. '/
        App->App: updateSessionStats(newLocation, time)
    end

    /'
       Step 6: User finishes navigating and
       manually returns to BBP (as per SP23).
    '/
    User->App: [Returns to BBP] taps "Stop Navigation"
    deactivate NavService

    /' Step 7: BBP stops recording. '/
    App->GPS: stopLocationUpdates()
    deactivate GPS

    note right of App: App finalizes session statistics (R16).

    /' Step 8: Show Summary '/
    App-->User: showNavigationSummary(sessionStats)

    /' Step 9-13: Save logic '/
    alt User is Anonymous (R17)
        User->App: tapsRegisterToSave()
        note right of App: Triggers UC1: Register Account (R19)

        User->App: selectsVisibility(visibility) (R39)
        note right of App: System saves Trip to new account.
        App-->User: [Trip Saved Confirmation]

    else User is Registered (R33)
        User->App: tapsSaveActivity()

        User->App: selectsVisibility(visibility) (R39)
        note right of App: System saves Trip to user's archive.
        App-->User: [Trip Saved Confirmation]
    end

    deactivate App