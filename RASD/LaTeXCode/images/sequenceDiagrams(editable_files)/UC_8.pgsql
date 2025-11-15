sequenceDiagram
    actor "Registered User" as User
    participant "BBP Application" as App

    note over App: UC9 (`Save trip and path`) triggered this review (R28).
    App-->User: showSummaryAndReviewScreen(pendingEvents)
    activate App

    loop for each event
        User->App: selectsDetection(eventID)
        App-->User: showDetectionDetails(eventID)

        alt User confirms (R29)
            User->App: tapsConfirm(eventID)
            /' App is already active, so this is a self-message '/
            App->App: markEventAsConfirmed(eventID)
        else User ignores (R29)
            User->App: tapsIgnore(eventID)
            App->App: markEventAsIgnored(eventID)
        end
    end

    note over App: Continues on UC9: Save Path and Trip
    deactivate App