sequenceDiagram
    actor "Registered User" as User
    participant "BBP Application" as App

    User->App: taps Logout Button
    activate App

    /'
       BBP Application is now active,
       handling session invalidation.
    '/
    note right of App: System invalidates session token.
    note right of App: App clears local session data.

    App-->User: showMainMapScreen()
    deactivate App