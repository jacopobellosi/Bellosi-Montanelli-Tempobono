sequenceDiagram
    actor "User" as User
    participant "BBP Application" as App
    actor "External navigation service" as NavService
    actor "Device Sensors (GPS)" as GPS

    User->App: taps "Follow Path" (R15)
    activate App

    /' App synchronously calls the external service and waits '/
    App->NavService: openWithRoute(pathGeometry)
    activate NavService
    NavService-->User: [Shows Turn-by-Turn Navigation]

    /' App asynchronously starts GPS updates (fire-and-forget) '/
    App->>GPS: startLocationUpdates()
    activate GPS

    loop Background Updates
        /' GPS asynchronously sends data back to the App '/
        GPS-->>App: onLocationChanged(newLocation)
        App->App: updateSessionStats(newLocation, time)
    end

    /' User returns to App and synchronously taps "Stop" '/
    User->App: [Returns to BBP] taps "Stop Navigation"
    deactivate NavService

    /' App asynchronously stops GPS updates '/
    App->>GPS: stopLocationUpdates()
    deactivate GPS

    note right of App: App finalizes session statistics using Elapsed Time (R31) (R16).

    /' App synchronously responds to the user's "Stop" tap '/
    App-->User: showNavigationSummary(sessionStats)

    /' The save logic is a synchronous UI flow '/
    alt User is Unauthenticated (R17)
        User->App: tapsRegisterToSave()
        note right of App: Triggers UC1: Register Account (R19)

        User->App: selectsVisibility(visibility) (R39.2)
        note right of App: System saves Trip to new account.
        App-->User: [Trip Saved Confirmation]

    else User is Registered (R33)
        User->App: tapsSaveActivity()

        User->App: selectsVisibility(visibility) (R39.2)
        note right of App: System saves Trip to user's archive.
        App-->User: [Trip Saved Confirmation]
    end

    deactivate App