actor "User" as User
participant "BBP Application" as App
participant "BBP Server" as Server
participant "External Weather Service" as Weather

User->>App: selectPath(pathID)
activate App
App->>Server: getPathDetails(pathID)
activate Server

    note right of Server: Server retrieves Path, all GPS Points, and all associated Reports.
    note right of Server: Applies merging logic (R8) to calculate definitive status.

    Server->>Weather: getForecast(pathLocations)
    activate Weather
    Weather-->>Server: 200_OK([Forecast Data])
    deactivate Weather
    
    note right of Server: Compiles full path details 
    Server-->>App: 200_OK(pathDetails)
deactivate Server

App-->>User: displayPathDetails(pathDetails)
deactivate App
