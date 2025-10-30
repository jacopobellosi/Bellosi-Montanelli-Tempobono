title UC: Log In - Sequence Diagram

actor "Anonymous User" as User
participant "BBP Application" as App
participant "BBP Server" as Server

User->>App: tapsLoginOption()
App-->>User: showLoginForm()

User->>App: entersCredentials(identifierOrEmail, password)
User-->>App: tapsLogIn()
App->>Server: authenticate(identifierOrEmail, password)
activate Server

    Server->>Server: validateInput(identifierOrEmail, password)
    Server-->>Server: inputOK

    Server->>Server: user = findUserByIdentifier(identifierOrEmail)
    Server-->>Server: [userFound: true|false]

    alt Invalid credentials (user not found or password mismatch)
        Server-->>App: 401_Unauthorized("Invalid username or password")
        App-->>User: showError("Invalid username or password")
    else Valid credentials
        Server->>Server: passwordsMatch = verifyPassword(password, user.hash)
        alt Password invalid
            Server-->>App: 401_Unauthorized("Invalid username or password")
            App-->>User: showError("Invalid username or password")
        else Password valid
            Server->>Server: sessionToken = createSession(user.id)
            Server-->>App: 200_OK(sessionToken)
            App->>App: storeSession(sessionToken)
            App-->>User: showMainMapScreen()
            note over User,App: Role becomes Registered User
        end
    end
deactivate Server
