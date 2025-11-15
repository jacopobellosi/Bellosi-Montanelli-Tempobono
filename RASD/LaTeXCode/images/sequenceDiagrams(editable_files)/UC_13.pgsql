sequenceDiagram
    actor "Registered User" as User
    participant "BBP Application" as App

    User->App: tapsViewMyTrips()
    activate App

    note right of App: System retrieves summary for all user's private trips.

    App-->User: showMyTripsList(tripsList)
    deactivate App

    loop User views details
        User->App: selectsTrip(tripID)
        activate App

        note right of App: System retrieves full trip (GPS, stats, weather, reports).

        App-->User: showTripDetails(fullTripData)
        deactivate App
    end