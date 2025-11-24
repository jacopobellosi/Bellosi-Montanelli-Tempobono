sequenceDiagram
    actor "Registered User" as User
    participant "BBP Application" as App

    User->App: tapsViewMyTrips()
    activate App

    note right of App: System retrieves summary for all user's private trips (R34).

    App-->User: showMyTripsList(tripsList)
    deactivate App

    loop User views details
        User->App: selectsTrip(tripID)
        activate App

        note right of App: System retrieves full trip (GPS, stats, weather, reports) (R35).

        App-->User: showTripDetails(fullTripData)
        deactivate App
    end