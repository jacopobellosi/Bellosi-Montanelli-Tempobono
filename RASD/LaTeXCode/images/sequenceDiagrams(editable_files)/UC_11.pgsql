sequenceDiagram
    actor "Registered User" as RCY
    participant "BBP Application" as App

    RCY->App: tapsCreateManualPath()
    activate App
    App-->RCY: showManualEditorScreen()

    loop User draws path
        RCY->App: placesPointOnMap(location)
        /' App is already active, so this is a self-message '/
        App->App: addSegmentToGeometry(location)
    end

    RCY->App: tapsFinishCreation()
    note over App: Triggers UC14: Add Status report
    note over App: Triggers UC15: Add Obstacle report

    note right of App: Passes created data to the Save Path workflow

    /' UC11 (Create) triggers UC12 (Save) '/
    note over App: Triggers UC12: Save path
    deactivate App