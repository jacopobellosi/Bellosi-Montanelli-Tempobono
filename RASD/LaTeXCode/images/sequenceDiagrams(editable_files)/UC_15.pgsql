sequenceDiagram
    actor "Registered User" as User
    participant "BBP Application" as App

    note over User, App: User is viewing Path Details (UC5) or adding Path manually (UC11)

    User->App: selectsReportType("Obstacle")
    activate App
    App-->User: showObstacleForm()
    deactivate App

    User->App: submitsObstacleReport(pathID, type, location)
    activate App

    /'
       BBP Application is now active,
       handling the report submission.
    '/
    note right of App: System saves new Obstacle_report (R38).
    note right of App: System recalculates path score (R10).

    App-->User: showMessage("Obstacle report submitted!")
    deactivate App