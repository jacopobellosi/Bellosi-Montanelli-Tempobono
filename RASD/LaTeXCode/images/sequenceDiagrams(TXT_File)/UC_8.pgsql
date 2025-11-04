actor "Registered User" as User
participant "BBP Application" as App

note over App: UC7 (`Record Trip`) finished and triggered this review (R25).
App->>User: showSummaryAndReviewScreen(pendingEvents)
activate App

loop for each event
    User->>App: selectsDetection(eventID)
    App-->>User: showDetectionDetails(eventID)
    
    alt User confirms (R26)
        User->>App: tapsConfirm(eventID)
        App->>App: markEventAsConfirmed(eventID)
        activate App
        deactivate App
    else User ignores (R26)
        User->>App: tapsIgnore(eventID)
        App->>App: markEventAsIgnored(eventID)
        activate App
        deactivate App
    end
end

note over App: Proceeds to UC9: Save Path and Trip
deactivate App
