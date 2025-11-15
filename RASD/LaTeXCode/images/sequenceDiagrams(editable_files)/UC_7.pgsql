sequenceDiagram
    actor "Registered User" as User
    participant "BBP Application" as App
    actor "Device Sensors (GPS, IMU)" as Sensors

    User->App: tapsStartRecording() (R20)
    activate App
    App-->User: showRecordingHUD()

    App->Sensors: startLocationUpdates()
    activate Sensors
    App->Sensors: startSensorMonitoring()

    note right of App: App displays real-time stats (R22). Timer (Elapsed Time) is always running.

    loop Continuous Updates
        Sensors-->App: onLocationChanged(newLocation, currentSpeed)

        alt currentSpeed > threshold [Auto-Resume / Recording] (R26)
            App->App: recordGpsPoint(newLocation) (R21)

            Sensors-->App: onSensorEvent(sensorData) (R23)
            note right of App: (Checks if sensorData > threshold)
            App->App: logSensorEvent(sensorData) (R24)

        else currentSpeed < threshold [Auto-Pause] (R25)
            note right of App: GPS/Sensor recording paused (R25). Timer (R22) continues.
        end
    end

    User->App: tapsStopRecording() (R27)
    App->Sensors: stopLocationUpdates()
    App->Sensors: stopSensorMonitoring()
    deactivate Sensors

    note right of App: Check if sensor activity were logged
    note over App: Triggers UC9: Save trip and path

    deactivate App