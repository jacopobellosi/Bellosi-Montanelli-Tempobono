actor "Registred User" as User
participant "BBP Application" as App
participant "BBP Server" as Server

User->>App: user taps Login
activate App
App-->>User: showLoginForm()
deactivate App

User->>App: entersCredentials(identifierOrEmail, password)
activate App
App->>Server: authenticate(identifierOrEmail, password)
activate Server

    note right of Server: Server validates format, finds user, and verifies password.
    
    alt Invalid credentials
        Server-->>App: 401_Unauthorized("Invalid username or password")
        App-->>User: showError("Invalid username or password")
    else Valid credentials
        note right of Server: Generates new session token.
        Server-->>App: 200_OK(sessionToken)
        
        note left of App: App securely stores the session token.
        App-->>User: showMainMapScreen()
        deactivate App
 
    end
deactivate Server
