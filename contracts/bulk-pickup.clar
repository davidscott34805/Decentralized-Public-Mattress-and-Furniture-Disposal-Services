;; Bulk Item Pickup Scheduling Contract
;; Manages curbside collection of large furniture and appliance items

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u300))
(define-constant ERR-INVALID-INPUT (err u301))
(define-constant ERR-PICKUP-NOT-FOUND (err u302))
(define-constant ERR-ALREADY-SCHEDULED (err u303))
(define-constant ERR-INVALID-DATE (err u304))
(define-constant ERR-CAPACITY-EXCEEDED (err u305))

;; Data Variables
(define-data-var next-pickup-id uint u1)
(define-data-var total-pickups uint u0)
(define-data-var daily-capacity uint u50)
(define-data-var pickup-fee uint u25) ;; STX per item

;; Data Maps
(define-map pickup-requests
  { pickup-id: uint }
  {
    requester: principal,
    items: (string-ascii 500),
    item-count: uint,
    pickup-address: (string-ascii 200),
    preferred-date: uint,
    scheduled-date: (optional uint),
    status: (string-ascii 20),
    collector: (optional principal),
    created-at: uint,
    completed-at: (optional uint)
  }
)

(define-map collectors
  { collector: principal }
  {
    name: (string-ascii 100),
    vehicle-capacity: uint,
    service-area: (string-ascii 100),
    pickups-completed: uint,
    active: bool
  }
)

(define-map daily-schedules
  { date: uint }
  {
    scheduled-pickups: uint,
    completed-pickups: uint,
    assigned-collectors: (list 10 principal)
  }
)

(define-map route-assignments
  { collector: principal, date: uint }
  {
    pickup-ids: (list 20 uint),
    estimated-items: uint,
    status: (string-ascii 20)
  }
)

;; Public Functions

;; Request bulk item pickup
(define-public (request-pickup (items (string-ascii 500)) (item-count uint) (pickup-address (string-ascii 200)) (preferred-date uint))
  (let
    (
      (pickup-id (var-get next-pickup-id))
      (current-block block-height)
    )
    (asserts! (> (len items) u0) ERR-INVALID-INPUT)
    (asserts! (> item-count u0) ERR-INVALID-INPUT)
    (asserts! (> (len pickup-address) u0) ERR-INVALID-INPUT)
    (asserts! (> preferred-date current-block) ERR-INVALID-DATE)

    (map-set pickup-requests
      { pickup-id: pickup-id }
      {
        requester: tx-sender,
        items: items,
        item-count: item-count,
        pickup-address: pickup-address,
        preferred-date: preferred-date,
        scheduled-date: none,
        status: "requested",
        collector: none,
        created-at: current-block,
        completed-at: none
      }
    )

    (var-set next-pickup-id (+ pickup-id u1))
    (var-set total-pickups (+ (var-get total-pickups) u1))
    (ok pickup-id)
  )
)

;; Register as a collector
(define-public (register-collector (name (string-ascii 100)) (vehicle-capacity uint) (service-area (string-ascii 100)))
  (begin
    (asserts! (> (len name) u0) ERR-INVALID-INPUT)
    (asserts! (> vehicle-capacity u0) ERR-INVALID-INPUT)
    (asserts! (> (len service-area) u0) ERR-INVALID-INPUT)

    (map-set collectors
      { collector: tx-sender }
      {
        name: name,
        vehicle-capacity: vehicle-capacity,
        service-area: service-area,
        pickups-completed: u0,
        active: true
      }
    )
    (ok true)
  )
)

;; Schedule pickup for specific date
(define-public (schedule-pickup (pickup-id uint) (scheduled-date uint) (collector principal))
  (let
    (
      (pickup (unwrap! (map-get? pickup-requests { pickup-id: pickup-id }) ERR-PICKUP-NOT-FOUND))
      (collector-info (unwrap! (map-get? collectors { collector: collector }) ERR-INVALID-INPUT))
      (daily-schedule (default-to { scheduled-pickups: u0, completed-pickups: u0, assigned-collectors: (list) }
                                  (map-get? daily-schedules { date: scheduled-date })))
    )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status pickup) "requested") ERR-ALREADY-SCHEDULED)
    (asserts! (get active collector-info) ERR-INVALID-INPUT)
    (asserts! (< (get scheduled-pickups daily-schedule) (var-get daily-capacity)) ERR-CAPACITY-EXCEEDED)

    ;; Update pickup request
    (map-set pickup-requests
      { pickup-id: pickup-id }
      (merge pickup {
        status: "scheduled",
        scheduled-date: (some scheduled-date),
        collector: (some collector)
      })
    )

    ;; Update daily schedule
    (map-set daily-schedules
      { date: scheduled-date }
      (merge daily-schedule {
        scheduled-pickups: (+ (get scheduled-pickups daily-schedule) u1)
      })
    )

    (ok true)
  )
)

;; Assign route to collector
(define-public (assign-route (collector principal) (date uint) (pickup-ids (list 20 uint)))
  (let
    (
      (collector-info (unwrap! (map-get? collectors { collector: collector }) ERR-INVALID-INPUT))
      (total-items (fold calculate-route-items pickup-ids u0))
    )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (get active collector-info) ERR-INVALID-INPUT)
    (asserts! (<= total-items (get vehicle-capacity collector-info)) ERR-CAPACITY-EXCEEDED)

    (map-set route-assignments
      { collector: collector, date: date }
      {
        pickup-ids: pickup-ids,
        estimated-items: total-items,
        status: "assigned"
      }
    )
    (ok true)
  )
)

;; Mark pickup as completed
(define-public (complete-pickup (pickup-id uint))
  (let
    (
      (pickup (unwrap! (map-get? pickup-requests { pickup-id: pickup-id }) ERR-PICKUP-NOT-FOUND))
      (collector-info (unwrap! (map-get? collectors { collector: tx-sender }) ERR-NOT-AUTHORIZED))
      (current-block block-height)
      (scheduled-date (unwrap! (get scheduled-date pickup) ERR-INVALID-INPUT))
      (daily-schedule (unwrap! (map-get? daily-schedules { date: scheduled-date }) ERR-INVALID-INPUT))
    )
    (asserts! (is-some (get collector pickup)) ERR-INVALID-INPUT)
    (asserts! (is-eq (unwrap-panic (get collector pickup)) tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status pickup) "scheduled") ERR-INVALID-INPUT)

    ;; Update pickup request
    (map-set pickup-requests
      { pickup-id: pickup-id }
      (merge pickup {
        status: "completed",
        completed-at: (some current-block)
      })
    )

    ;; Update collector stats
    (map-set collectors
      { collector: tx-sender }
      (merge collector-info {
        pickups-completed: (+ (get pickups-completed collector-info) u1)
      })
    )

    ;; Update daily schedule
    (map-set daily-schedules
      { date: scheduled-date }
      (merge daily-schedule {
        completed-pickups: (+ (get completed-pickups daily-schedule) u1)
      })
    )

    (ok true)
  )
)

;; Set daily capacity (owner only)
(define-public (set-daily-capacity (new-capacity uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (> new-capacity u0) ERR-INVALID-INPUT)
    (var-set daily-capacity new-capacity)
    (ok true)
  )
)

;; Set pickup fee (owner only)
(define-public (set-pickup-fee (new-fee uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (var-set pickup-fee new-fee)
    (ok true)
  )
)

;; Private Functions

;; Calculate total items for route assignment
(define-private (calculate-route-items (pickup-id uint) (total uint))
  (match (map-get? pickup-requests { pickup-id: pickup-id })
    pickup (+ total (get item-count pickup))
    total
  )
)

;; Read-only Functions

;; Get pickup request details
(define-read-only (get-pickup-request (pickup-id uint))
  (map-get? pickup-requests { pickup-id: pickup-id })
)

;; Get collector information
(define-read-only (get-collector (collector principal))
  (map-get? collectors { collector: collector })
)

;; Get daily schedule
(define-read-only (get-daily-schedule (date uint))
  (map-get? daily-schedules { date: date })
)

;; Get route assignment
(define-read-only (get-route-assignment (collector principal) (date uint))
  (map-get? route-assignments { collector: collector, date: date })
)

;; Get total pickups
(define-read-only (get-total-pickups)
  (var-get total-pickups)
)

;; Get daily capacity
(define-read-only (get-daily-capacity)
  (var-get daily-capacity)
)

;; Get pickup fee
(define-read-only (get-pickup-fee)
  (var-get pickup-fee)
)

;; Get next pickup ID
(define-read-only (get-next-pickup-id)
  (var-get next-pickup-id)
)
