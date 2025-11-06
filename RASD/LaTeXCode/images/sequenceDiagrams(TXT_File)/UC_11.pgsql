actor "RCY" as User
participant "BBP Application" as App

User->>App: tapsCreateManualPath()
activate App
App-->>User: showManualEditorScreen()

loop User draws path
    User->>App: placesPointOnMap(location)
    App->>App: addSegmentToGeometry(location)
    activate App
    deactivate App
end

User->>App: tapsFinishCreation()
note over App: Triggers UC14: Add Status report
note over App: Triggers UC15: Add Obstacle report

note left of App: Passes created data to the Save Path workflow

note over App: Triggers UC11: Save path
deactivate App
