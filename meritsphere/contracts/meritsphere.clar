;; MeritSphere - Enhanced DAO Merit System
;; A comprehensive merit tracking system for DAOs on Stacks blockchain

(define-constant admin tx-sender)
(define-constant err-admin-only (err u100))
(define-constant err-member-not-found (err u101))
(define-constant err-access-denied (err u102))
(define-constant err-invalid-merit (err u103))
(define-constant err-invalid-parameter (err u104))
(define-constant err-invalid-initiative-id (err u111))
(define-constant err-invalid-activity (err u112))
(define-constant max-initiative-id u1000000)
(define-constant max-points u1000)

;; Enhanced Data Maps
(define-map member-metrics 
    principal 
    {
        merit-points: uint,
        initiatives-created: uint,
        decisions-made: uint,
        last-participation: uint,
        tasks-completed: uint,
        successful-initiatives: uint,
        decision-participation-rate: uint,
        peer-recognition: uint
    }
)

(define-map activity-points
    {activity-type: (string-ascii 24)}
    {
        base-points: uint,
        multiplier: uint,
        minimum-threshold: uint
    }
)

(define-map initiative-records
    uint
    {
        creator: principal,
        status: (string-ascii 12),
        decision-count: uint,
        created-at: uint
    }
)

;; Initialize activity points with enhanced parameters
(map-set activity-points 
    {activity-type: "initiative"} 
    {
        base-points: u10,
        multiplier: u2,
        minimum-threshold: u5
    }
)
(map-set activity-points 
    {activity-type: "decision"} 
    {
        base-points: u5,
        multiplier: u1,
        minimum-threshold: u10
    }
)
(map-set activity-points 
    {activity-type: "task"} 
    {
        base-points: u15,
        multiplier: u3,
        minimum-threshold: u3
    }
)

;; Input Validation Functions
(define-private (is-valid-initiative-id (initiative-id uint))
    (and 
        (> initiative-id u0)
        (<= initiative-id max-initiative-id)
    )
)

(define-private (is-valid-points (points uint))
    (<= points max-points)
)

(define-private (is-valid-activity (activity-type (string-ascii 24)))
    (or 
        (is-eq activity-type "initiative")
        (is-eq activity-type "decision")
        (is-eq activity-type "task")
    )
)

;; Enhanced Public Functions

(define-public (register-member)
    (begin
        (asserts! (is-none (get-member-metrics tx-sender)) (err u105))
        (ok (map-set member-metrics tx-sender {
            merit-points: u0,
            initiatives-created: u0,
            decisions-made: u0,
            last-participation: block-height,
            tasks-completed: u0,
            successful-initiatives: u0,
            decision-participation-rate: u0,
            peer-recognition: u0
        }))
    )
)

(define-public (log-initiative (initiative-id uint))
    (begin
        (asserts! (is-valid-initiative-id initiative-id) err-invalid-initiative-id)
        (let (
            (member-data (unwrap! (get-member-metrics tx-sender) (err u106)))
            (points-data (unwrap! (map-get? activity-points {activity-type: "initiative"}) (err u107)))
            (new-points (calculate-weighted-points 
                (get base-points points-data) 
                (get multiplier points-data) 
                (get initiatives-created member-data)
            ))
        )
        (begin
            (asserts! (is-none (map-get? initiative-records initiative-id)) err-invalid-parameter)
            (map-set initiative-records initiative-id {
                creator: tx-sender,
                status: "active",
                decision-count: u0,
                created-at: block-height
            })
            (ok (map-set member-metrics tx-sender (merge member-data {
                merit-points: (+ (get merit-points member-data) new-points),
                initiatives-created: (+ (get initiatives-created member-data) u1),
                last-participation: block-height
            })))
        ))
    )
)

(define-public (log-decision (initiative-id uint))
    (begin
        (asserts! (is-valid-initiative-id initiative-id) err-invalid-initiative-id)
        (let (
            (member-data (unwrap! (get-member-metrics tx-sender) (err u106)))
            (points-data (unwrap! (map-get? activity-points {activity-type: "decision"}) (err u107)))
            (initiative-data (unwrap! (map-get? initiative-records initiative-id) (err u108)))
            (new-points (calculate-weighted-points 
                (get base-points points-data) 
                (get multiplier points-data) 
                (get decisions-made member-data)
            ))
            (new-decision-count (+ (get decision-count initiative-data) u1))
        )
        (begin
            (asserts! (is-eq (get status initiative-data) "active") err-invalid-parameter)
            (map-set initiative-records initiative-id 
                (merge initiative-data {decision-count: new-decision-count}))
            (ok (map-set member-metrics tx-sender (merge member-data {
                merit-points: (+ (get merit-points member-data) new-points),
                decisions-made: (+ (get decisions-made member-data) u1),
                decision-participation-rate: (calculate-participation-rate 
                    (+ (get decisions-made member-data) u1) 
                    (get initiatives-created member-data)
                ),
                last-participation: block-height
            })))
        ))
    )
)

(define-public (update-initiative-status (initiative-id uint) (new-status (string-ascii 12)))
    (begin
        (asserts! (is-valid-initiative-id initiative-id) err-invalid-initiative-id)
        (let (
            (initiative-data (unwrap! (map-get? initiative-records initiative-id) (err u108)))
            (creator-data (unwrap! (get-member-metrics (get creator initiative-data)) (err u109)))
        )
        (begin
            (asserts! (is-eq tx-sender admin) err-admin-only)
            (asserts! (or (is-eq new-status "successful") (is-eq new-status "failed")) err-invalid-parameter)
            (if (is-eq new-status "successful")
                (map-set member-metrics (get creator initiative-data) 
                    (merge creator-data {
                        successful-initiatives: (+ (get successful-initiatives creator-data) u1),
                        merit-points: (+ (get merit-points creator-data) u50)
                    })
                )
                true
            )
            (ok (map-set initiative-records initiative-id 
                (merge initiative-data {status: new-status})))
        ))
    )
)

(define-public (give-peer-recognition (member principal))
    (let (
        (recipient-data (unwrap! (get-member-metrics member) (err u110)))
    )
    (begin
        (asserts! (not (is-eq tx-sender member)) err-access-denied)
        (ok (map-set member-metrics member (merge recipient-data {
            peer-recognition: (+ (get peer-recognition recipient-data) u1),
            merit-points: (+ (get merit-points recipient-data) u5)
        })))
    ))
)

;; Enhanced Private Functions

(define-private (calculate-weighted-points (base uint) (multiplier uint) (count uint))
    (let (
        (activity-bonus (if (> count u10) u2 u1))
    )
    (* base (* multiplier activity-bonus))
    )
)

(define-private (calculate-participation-rate (decisions uint) (total-initiatives uint))
    (if (> total-initiatives u0)
        (* (/ decisions total-initiatives) u100)
        u0
    )
)

(define-private (calculate-decay (initial-points uint) (blocks-elapsed uint))
    (let (
        (decay-rate (/ blocks-elapsed u1000))
        (minimum-points (/ initial-points u10))
        (decayed-points (if (> decay-rate u0)
            (/ initial-points decay-rate)
            initial-points))
    )
    (if (< decayed-points minimum-points)
        minimum-points
        decayed-points)
    )
)

;; Enhanced Read-only Functions

(define-read-only (get-member-metrics (member principal))
    (map-get? member-metrics member)
)

(define-read-only (get-initiative-data (initiative-id uint))
    (map-get? initiative-records initiative-id)
)

(define-read-only (get-activity-points (activity-type (string-ascii 24)))
    (map-get? activity-points {activity-type: activity-type})
)

(define-read-only (get-current-merit (member principal))
    (let (
        (member-data (unwrap! (get-member-metrics member) err-member-not-found))
        (blocks-inactive (- block-height (get last-participation member-data)))
        (base-points (get merit-points member-data))
        (participation-bonus (if (> (get decision-participation-rate member-data) u75) u50 u0))
        (success-bonus (* (get successful-initiatives member-data) u25))
    )
    (ok (+ 
        (+ (calculate-decay base-points blocks-inactive) participation-bonus)
        success-bonus
    )))
)

;; Administrative Functions

(define-public (adjust-points-parameters 
    (activity-type (string-ascii 24)) 
    (base-points uint) 
    (multiplier uint) 
    (minimum-threshold uint)
)
    (begin
        (asserts! (is-eq tx-sender admin) err-admin-only)
        (asserts! (is-valid-activity activity-type) err-invalid-activity)
        (asserts! (is-valid-points base-points) err-invalid-parameter)
        (asserts! (is-valid-points multiplier) err-invalid-parameter)
        (asserts! (is-valid-points minimum-threshold) err-invalid-parameter)
        (ok (map-set activity-points 
            {activity-type: activity-type} 
            {
                base-points: base-points,
                multiplier: multiplier,
                minimum-threshold: minimum-threshold
            }
        ))
    )
)