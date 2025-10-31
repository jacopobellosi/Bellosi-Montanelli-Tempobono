actor "Registered User" as User
participant "BBP Application" as App
participant "BBP Server" as Server

User->>App: taps Logout Button
activate App
App->>Server: logout()
activate Server

    note right of Server: Server invalidates the user's session token.
    Server-->>App: 200_OK(logout_success)
deactivate Server

note right of App: clearLocalSession()


App-->>User: showMainMapScreen()
deactivate App
