sequenceDiagram
    actor "User" as User
    participant "BBP Application" as App
    actor "External Weather Service" as Weather

    User->App: selectPath(pathID)
    activate App

    /'
       BBP Application is now active,
       representing all internal system processing.
    '/
    note right of App: System retrieves Path and all associated Reports (R8).
    note right of App: Applies merging logic (R9) to calculate definitive status.

    App->Weather: getForecast(pathLocations)
    activate Weather
    Weather-->App: [Forecast Data]
    deactivate Weather

    note right of App: Compiles full path details.

    App-->User: displayPathDetails(pathDetails)
    deactivate App