sequenceDiagram
    actor "Registered User" as User
    participant "BBP Application" as App

    note over User, App: User is viewing Path Details (UC5) or adding Path manually (UC11)

    User->App: tapsSubmitReport()
    activate App
    App-->User: showReportTypeOptions()
    deactivate App

    User->App: submitsStatusReport(pathID, status)
    activate App

    /'
       BBP Application is now active,
       handling the report submission.
    '/
    note right of App: System saves new Status_report (R37).
    note right of App: System recalculates path status (R9) and score (R10).

    App-->User: showMessage("Status report submitted!")
    deactivate App