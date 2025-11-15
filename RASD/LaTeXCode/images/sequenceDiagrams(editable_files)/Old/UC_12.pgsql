actor "Registered User" as User
participant "BBP Application" as App
participant "BBP Server" as Server

note over App: Triggered by UC11 (Create path manually).
App->>User: showSavePathScreen(pathData)
activate App
User->>App: entersName(pathName)

note over User, App: <<includes>> UC12: Set Visibility


alt User Saves
    User->>App: tapsSave()
    App->>Server: saveManualPath(pathData, pathName, pathVisibility)
    activate Server

        note right of Server: Saves the new Path with selected visibility.
        Server-->>App: 201_Created(savedPathID)
    deactivate Server

    App-->>User: showMessage("Path saved successfully!")
    App->>User: showMainMapScreen()
    
else User Discards
    User->>App: tapsDiscard()
    App->>User: showMainMapScreen()
    deactivate App
end
