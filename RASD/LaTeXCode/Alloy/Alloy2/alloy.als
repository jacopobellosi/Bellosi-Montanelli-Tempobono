// ----- 1. Tipi Enumerati -----
enum PathStatus { Optimal, Medium, RequiresMaintenance }
enum ObstacleType { Pothole, Roadwork, Other }
enum Visibility { Public, Private }
enum DetectionState { Pending, Confirmed, Rejected }

// ----- 2. Tipi di dato -----
sig GPS_point {}
sig Statistic {}
sig Weather_info {}
sig Timestamp {}

// ----- 3. Struttura Statica e Dinamica -----

abstract sig User {}
sig Registered_user extends User {
    trips: set Trip,
    createdPaths: set Path,
    submittedReports: set Report
}

sig Path {
    geometry: set GPS_point,
    pathVisibility: one Visibility,
    creator: one Registered_user,
    reports: set Report,
    performances: set Trip
}

// MUTABILE: Lo stato dell'evento cambia nel tempo
sig sensor_event {
    location: one GPS_point,
    trip: one Trip,
    var state: DetectionState 
}

sig Trip {
    trace: set GPS_point,
    stats: one Statistic,
    weather: lone Weather_info,
    owner: one Registered_user,
    path: lone Path,
    tripVisibility: one Visibility,
    detections: set sensor_event
}

abstract sig Report {
    timestamp: one Timestamp,
    author: one Registered_user,
    path: one Path
}

sig Status_report extends Report {
    status: one PathStatus
}

// MUTABILE: Il collegamento avviene quando l'evento è confermato
sig Obstacle_report extends Report {
    type: one ObstacleType,
    location: one GPS_point,
    var triggeredBy: lone sensor_event // Aggiunto 'var'
}

// ----- 4. Invarianti Statiche (Sempre Vere) -----
fact ModelInvariants {
    trips = ~owner
    createdPaths = ~creator
    submittedReports = ~author
    reports = ~path
    performances = ~path
    detections = ~trip
    
    // Coerenza statica di base
    all e: sensor_event | lone e.~triggeredBy
}

// ----- 5. Operazioni Dinamiche (Transizioni) -----

// Operazione: Conferma Evento
// Prende un evento pendente 'e' e un report libero 'r' e li collega
pred confirmDetection[e: sensor_event, r: Obstacle_report] {
    // Pre-condizioni (Guardie)
    e.state = Pending        // L'evento deve essere pendente
    no r.triggeredBy        // Il report non deve essere già usato

    // Post-condizioni (Effetti)
    e.state' = Confirmed    // Diventa confermato
    r.triggeredBy' = e      // Si crea il collegamento

    // Frame Conditions (Cosa NON cambia)
    // Tutti gli altri eventi mantengono il loro stato
    all e2: sensor_event - e | e2.state' = e2.state
    // Tutti gli altri report mantengono il loro collegamento
    all r2: Obstacle_report - r | r2.triggeredBy' = r2.triggeredBy
}

// Operazione: Rifiuta Evento
pred rejectDetection[e: sensor_event] {
    e.state = Pending
    e.state' = Rejected
    
    // Frame Conditions
    all e2: sensor_event - e | e2.state' = e2.state
    // I report non cambiano
    triggeredBy' = triggeredBy
}

// Operazione: Stutter (Non succede nulla)
pred doNothing {
    state' = state
    triggeredBy' = triggeredBy
}

// ----- 6. Fatti di Traccia (Il Motore del Sistema) -----

fact SystemDynamics {
    // Stato Iniziale: Tutto Pendente, nessun collegamento
    (all e: sensor_event | e.state = Pending)
    (no triggeredBy)
    
    // Transizioni: Ad ogni passo succede una di queste cose
    always (
        doNothing or
        (some e: sensor_event, r: Obstacle_report | confirmDetection[e, r]) or
        (some e: sensor_event | rejectDetection[e])
    )
}

// ----- 7. Fairness (Liveness) -----
// Questo è il vincolo "complesso" che mancava:
// "Se un evento è pendente, il sistema non può ignorarlo all'infinito."
fact Fairness {
    all e: sensor_event | 
        (e.state = Pending) implies eventually (e.state != Pending)
}

// ----- 8. Verifiche (Check) -----

// Proprietà 1: Coerenza (Se confermato, esiste il report)
assert ConfirmedImpliesReport {
    always (all e: sensor_event | 
        e.state = Confirmed implies some r: Obstacle_report | r.triggeredBy = e)
}

// Proprietà 2: Progresso (Tutto viene deciso)
assert PendingEventuallyDecided {
    all e: sensor_event | eventually (e.state = Confirmed or e.state = Rejected)
}

// Eseguiamo i check
// Nota: Aumentiamo leggermente i passi per dare tempo al sistema di evolvere
check ConfirmedImpliesReport for 3 but 10 steps
check PendingEventuallyDecided for 3 but 10 steps

// Scenario di Esempio (Run)
pred showSuccessScenario {
    eventually (some e: sensor_event | e.state = Confirmed)
}
run showSuccessScenario for 3 but 5 steps
