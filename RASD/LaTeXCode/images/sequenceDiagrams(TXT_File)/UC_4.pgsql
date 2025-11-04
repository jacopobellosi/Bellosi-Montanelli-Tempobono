actor "User" as User
participant "BBP Application" as App
participant "BBP Server" as Server
participant "External Weather Service" as Weather

User->>App: entersSearchQuery(origin, destination)
activate App
App->>Server: searchPaths(origin, destination)
activate Server

    note right of Server: Server finds paths, retrieves all reports, applies merging (R8) & scoring (R9) logic.
    
    Server->>Weather: getForecast(location)
    activate Weather
    Weather-->>Server: 200_OK([Forecast Data])
    deactivate Weather
    
    alt No paths found
        Server-->>App: 404_NotFound("No paths found")
        App-->>User: showMessage("No results found")
    else Paths found
        note right of Server: Returns ordered list of paths with scores, merged status, and weather.
        Server-->>App: 200_OK([Path List])
        App-->>User: displaySearchResults(pathList)
        deactivate App
    end
deactivate Server
