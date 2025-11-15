sequenceDiagram
    actor "User" as User
    participant "BBP Application" as App

    User->App: user taps Login
    activate App
    App-->User: showLoginForm()
    deactivate App

    User->App: entersCredentials(identifierOrEmail, password)
    activate App

    /'
       BBP Application is now active,
       representing all internal system processing
       (validation, auth, token generation).
    '/
    note right of App: System validates format, finds user, and verifies password.

    alt Invalid credentials
        App-->User: showError("Invalid username or password")
    else Valid credentials
        note right of App: Generates new session token.
        note right of App: App securely stores the session token.
        App-->User: showMainMapScreen()
    end
    deactivate App