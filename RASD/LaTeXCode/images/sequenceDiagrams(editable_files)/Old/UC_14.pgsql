actor "Registered User" as User
participant "BBP Application" as App
participant "BBP Server" as Server

note over User, App: User is viewing Path Details (UC5) or adding Path manually (UC11)

User->>App: tapsSubmitReport()
activate App
App-->>User: showReportTypeOptions()
deactivate App

User->>App: submitsStatusReport(pathID, status)
activate App
App->>Server: submitReport(pathID, statusReportData)
activate Server
    note right of Server: Saves new Status_report.
    note right of Server: Triggers Path score/status recalculation.
    Server-->>App: 200_OK(reportSaved)
deactivate Server

App-->>User: showMessage("Status report submitted!")
deactivate App
