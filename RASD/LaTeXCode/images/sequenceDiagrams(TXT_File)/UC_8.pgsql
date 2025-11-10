actor "Registered User" as User
participant "BBP Application" as App

note over App: UC9 (`Save trip and path`) triggered this review (R28).
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

note over App: Continues on UC9: Save Path and Trip
deactivate App
