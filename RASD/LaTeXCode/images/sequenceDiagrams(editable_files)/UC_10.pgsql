sequenceDiagram
    actor "Registered User" as User
    participant "BBP Application" as App

    note over User, App: (Called from UC9 or UC12)
    App-->User: showVisibilityOptions()
    activate App

    opt Context: Called from UC9 (Save trip and path)
        User->App: selectsVisibility(tripVisibility, pathVisibility)
    end

    opt Context: Called from UC12 (Save path)
        User->App: selectsVisibility(pathVisibility)
    end

    note over App: (Returns preferences to calling use case)
    deactivate App