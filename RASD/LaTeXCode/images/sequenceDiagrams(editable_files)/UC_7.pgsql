sequenceDiagram
    actor "Registered User" as User
    participant "BBP Application" as App
    actor "Device Sensors (GPS, IMU)" as Sensors

    /' User synchronously starts the recording and waits for the HUD '/
    User->App: tapsStartRecording() (R20)
    activate App
    App-->User: showRecordingHUD()

    /' App asynchronously starts the sensors (fire-and-forget) '/
    App->>Sensors: startLocationUpdates()
    activate Sensors
    App->>Sensors: startSensorMonitoring()

    note right of App: App displays real-time stats (R22). Timer (Elapsed Time) is always running.

    loop Continuous Asynchronous Updates
        /' Sensors independently send data back via callbacks '/
        Sensors-->>App: onLocationChanged(newLocation)

        /' Always record GPS (No auto-pause) '/
        App->App: recordGpsPoint(newLocation) (R21)

        Sensors-->>App: onSensorEvent(sensorData) (R23)

        opt sensorData > threshold
             note right of App: Checks if sensorData > threshold (R24)
             App->App: logSensorEvent(sensorData)
        end
    end

    /' User synchronously stops the recording '/
    User->App: tapsStopRecording() (R27)

    /' App asynchronously stops the sensors '/
    App->>Sensors: stopLocationUpdates()
    App->>Sensors: stopSensorMonitoring()
    deactivate Sensors

    note right of App: Check if sensor activity were logged
    note over App: Triggers UC9: Save trip and path

    deactivate App