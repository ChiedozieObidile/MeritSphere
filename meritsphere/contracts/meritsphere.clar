;; MeritSphere - DAO Merit Tracking System
;; A comprehensive merit and influence tracking system for DAOs on Stacks blockchain

(define-constant admin tx-sender)
(define-constant err-admin-only (err u100))
(define-constant err-member-not-found (err u101))
(define-constant err-access-denied (err u102))

;; Data Maps
(define-map member-metrics 
    principal 
    {
        merit-points: uint,
        initiatives-created: uint,
        decisions-made: uint,
        last-participation: uint,
        tasks-completed: uint
    }
)

(define-map activity-points
    {activity-type: (string-ascii 24)}
    {points: uint}
)

;; Initialize activity point values
(map-set activity-points {activity-type: "initiative"} {points: u10})
(map-set activity-points {activity-type: "decision"} {points: u5})
(map-set activity-points {activity-type: "task"} {points: u15})

;; Public functions
(define-public (register-member)
    (begin
        (asserts! (is-none (get-member-metrics tx-sender)) (err u103))
        (ok (map-set member-metrics tx-sender {
            merit-points: u0,
            initiatives-created: u0,
            decisions-made: u0,
            last-participation: block-height,
            tasks-completed: u0
        }))
    )
)

(define-public (log-initiative)
    (let (
        (member-data (unwrap! (get-member-metrics tx-sender) (err u104)))
        (initiative-points (get points (unwrap! (map-get? activity-points {activity-type: "initiative"}) (err u105))))
    )
    (ok (map-set member-metrics tx-sender (merge member-data {
        merit-points: (+ (get merit-points member-data) initiative-points),
        initiatives-created: (+ (get initiatives-created member-data) u1),
        last-participation: block-height
    })))
    )
)

(define-public (log-decision)
    (let (
        (member-data (unwrap! (get-member-metrics tx-sender) (err u104)))
        (decision-points (get points (unwrap! (map-get? activity-points {activity-type: "decision"}) (err u105))))
    )
    (ok (map-set member-metrics tx-sender (merge member-data {
        merit-points: (+ (get merit-points member-data) decision-points),
        decisions-made: (+ (get decisions-made member-data) u1),
        last-participation: block-height
    })))
    )
)

(define-public (log-task)
    (let (
        (member-data (unwrap! (get-member-metrics tx-sender) (err u104)))
        (task-points (get points (unwrap! (map-get? activity-points {activity-type: "task"}) (err u105))))
    )
    (ok (map-set member-metrics tx-sender (merge member-data {
        merit-points: (+ (get merit-points member-data) task-points),
        tasks-completed: (+ (get tasks-completed member-data) u1),
        last-participation: block-height
    })))
    )
)

;; Admin functions
(define-public (adjust-points (activity-type (string-ascii 24)) (new-points uint))
    (begin
        (asserts! (is-eq tx-sender admin) err-admin-only)
        (ok (map-set activity-points {activity-type: activity-type} {points: new-points}))
    )
)

;; Read-only functions
(define-read-only (get-member-metrics (member principal))
    (map-get? member-metrics member)
)

(define-read-only (get-activity-points (activity-type (string-ascii 24)))
    (map-get? activity-points {activity-type: activity-type})
)

;; Helper functions
(define-private (calculate-decay (initial-points uint) (blocks-elapsed uint))
    (let (
        (decay-rate (/ blocks-elapsed u1000))
    )
    (if (> decay-rate u0)
        (/ initial-points decay-rate)
        initial-points
    ))
)

;; Current merit calculation with time decay
(define-read-only (get-current-merit (member principal))
    (let (
        (member-data (unwrap! (get-member-metrics member) err-member-not-found))
        (blocks-inactive (- block-height (get last-participation member-data)))
    )
    (ok (calculate-decay (get merit-points member-data) blocks-inactive))
    )
)