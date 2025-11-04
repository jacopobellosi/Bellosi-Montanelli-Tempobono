actor "Registered User" as User
participant "BBP Application" as App
participant "BBP Server" as Server
participant "External Weather Service" as Weather

note over App: Triggered by UC7. App has all recorded data.
App->>Weather: getWeatherForTrip(tripData)
activate Weather
Weather-->>App: 200_OK(weatherInfo)
deactivate Weather
App->>User: showSummaryAndSaveScreen(summary, stats, weather, events)



alt Extension Point: Review Detections (UC8) [R25]
    User->>App: providesDetectionsReview(confirmedEvents)
end

User->>App: entersName(name)

note over User, App: <<includes>> UC10: Set Visibility
User->>App: selectsVisibility(tripVisibility, pathVisibility)

alt User Saves [Event Flow Step 6]
    User->>App: tapsSave()
    activate App
    App->>Server: saveTripAndPath(tripData, confirmedEvents, name, tripVisibility, pathVisibility)
    activate Server

        note right of Server: Saves the private Trip (R31)
        note right of Server: Saves the Path (R39)
        
        alt visibility is "Public"
            note right of Server: Updates Path average stats (R8, R9)
        end
        
        Server-->>App: 201_Created(savedIDs)
    deactivate Server

    App->>User: showMessage("Save successful!")
    App->>User: showMyTripsScreen()
    
else User Discards [Event Flow Step 7]
    User->>App: tapsDiscard()
    App-->>User: showMainMapScreen()
    deactivate App
end
