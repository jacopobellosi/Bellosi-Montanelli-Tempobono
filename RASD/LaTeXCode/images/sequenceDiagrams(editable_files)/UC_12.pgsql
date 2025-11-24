sequenceDiagram
    actor "Registered User" as User
    participant "BBP Application" as App

    note over App: Triggered by UC11 (Create path manually).
    App-->User: showSavePathScreen(pathData)
    activate App

    User->App: entersName(pathName)

    note over User, App: <<includes>> UC10: Set Visibility
    User->App: selectsVisibility(pathVisibility)

    alt User Saves
        User->App: tapsSave()

        /'
           BBP Application is now active,
           handling the save logic internally.
        '/
        note right of App: System saves the new Path with selected visibility (R25).

        App-->User: showMessage("Path saved successfully!")
        App-->User: showMainMapScreen()

    else User Discards
        User->App: tapsDiscard()
        App-->User: showMainMapScreen()
    end

    deactivate App