actor "Registered User" as User
participant "BBP Application" as App
participant "Device Sensors (GPS, IMU)" as Sensors


User->>App: tapsStartRecording()
App-->>User: showRecordingHUD()
activate App

App->>Sensors: startLocationUpdates()

activate Sensors
App->>Sensors: startSensorMonitoring()

note left of App: App displays real-time stats

loop Continuous Updates
    Sensors-->>App: onLocationChanged(newLocation)
    App->>App: recordGpsPoint(newLocation)
    activate App
    deactivate App
    
    Sensors-->>App: onSensorEvent(sensorData)
    note left of App: (R23: Checks if sensorData > threshold)
    App->>App: logSensorEvent(sensorData)
    activate App
    deactivate App
end

User->>App: tapsStopRecording()
App->>Sensors: stopLocationUpdates()
App->>Sensors: stopSensorMonitoring()
deactivate Sensors



note left of App: App calculates final statistics  
note left of App: Checks if sensor events were logged

note over App: Triggers:UC9 Save Path and Trip
deactivate App
