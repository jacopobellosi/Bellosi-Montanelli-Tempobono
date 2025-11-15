actor "User" as User
participant "BBP Application" as App
participant "Device Sensors (GPS)" as GPS

User->>App: tapsFollowRoute(pathGeometry)
App-->>User: showNavigationScreen(pathGeometry)

App->>GPS: startLocationUpdates()
activate App
activate GPS

loop Continuous Updates
    GPS-->>App: onLocationChanged(newLocation)
    App->>App: updateLocationOnMap(newLocation)
    activate App
    App->>App: updateSessionStats(newLocation, time)
    deactivate App
end

User->>App: tapsStopNavigation()
App->>GPS: stopLocationUpdates()
deactivate GPS

note left of App: App finalizes session statistics (avg speed, time).
App->>User: showNavigationSummary(sessionStats)

alt User is Anonymous (R16)
    User->>App: tapsRegisterToSave()
    note right of App: Triggers UC1: Register Account

    App->>User: showVisibilityOptions()
    User->>App: selectsVisibility(visibility)
    App->>Server: saveLightTrip(sessionStats, visibility)
    activate Server
    Server-->>App: 200_OK
    deactivate Server
    
else User is Registered
    User->>App: tapsSaveActivity()
    App->>User: showVisibilityOptions()
    User->>App: selectsVisibility(visibility)
    App->>Server: saveLightTrip(sessionStats, visibility)
    activate Server
    Server-->>App: 200_OK
    deactivate App
    deactivate Server
end
