sequenceDiagram
    actor "User" as User
    participant "BBP Application" as App

    User->App: taps Register Button
    activate App
    App-->User: showRegistrationScreen()
    deactivate App

    User->App: submitsData(username, email, password)
    activate App

    /'
       The BBP Application is now active,
       representing internal system processing.
    '/
    note right of App: System performs validation and checks uniqueness.

    alt Credentials Invalid (e.g., Email taken)
        App-->User: showError("Email or username already in use")

    else Credentials Valid
        note right of App: Creates new user account and generates session token.
        note right of App: App securely stores the session token.
        App-->User: showMainMapScreen()
    end
    deactivate App