sequenceDiagram
    actor "User" as User
    participant "BBP Application" as App
    actor "External Weather Service" as Weather

    User->App: entersSearchQuery(origin, destination)
    activate App

    /'
       BBP Application is now active,
       representing all internal system processing.
    '/
    note right of App: Finds public paths (R25), retrieves reports (R8), applies merging (R9) & scoring (R10).

    App->Weather: getForecast(location)
    activate Weather
    Weather-->App: [Forecast Data]
    deactivate Weather

    alt No paths found
        App-->User: showMessage("No results found")
    else Paths found
        note right of App: Returns ordered list of paths with scores, merged status, and weather (R11).
        App-->User: displaySearchResults(pathList)
    end
    deactivate App