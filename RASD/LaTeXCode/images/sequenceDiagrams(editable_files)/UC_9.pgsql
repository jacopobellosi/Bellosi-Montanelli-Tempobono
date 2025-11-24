sequenceDiagram
    actor "Registered User" as User
    participant "BBP Application" as App
    actor "External Weather Service" as Weather

    note over App: Triggered by UC7. App has all recorded data.
    App->Weather: getWeatherForTrip(tripData)
    activate Weather
    Weather-->App: [weatherInfo]
    deactivate Weather

    App-->User: showSummaryAndSaveScreen(summary, stats, weather, events)
    activate App

    alt Extension Point: Review Detections (UC8) [R28]
        User->App: providesDetectionsReview(confirmedEvents)
    end

    User->App: entersName(name)

    note over User, App: <<includes>> UC10: Set Visibility
    User->App: selectsVisibility(tripVisibility, pathVisibility)

    alt User Saves [Event Flow Step 6]
        User->App: tapsSave()

        note right of App: System saves the private Trip (R33).
        note right of App: System saves the Path with selected visibility (R25).

        alt visibility is "Public"
            note right of App: System updates Path average stats (R26).
        end

        App-->User: showMessage("Save successful!")
        App-->User: showMyTripsScreen()

    else User Discards [Event Flow Step 7]
        User->App: tapsDiscard()
        App-->User: showMainMapScreen()
    end

    deactivate App