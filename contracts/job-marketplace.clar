;; Job Marketplace Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-unauthorized (err u103))
(define-constant err-wrong-status (err u104))
(define-constant err-insufficient-funds (err u105))

;; Job status enum: 1=Open, 2=In Progress, 3=Completed, 4=Disputed
(define-data-var next-job-id uint u1)

;; Data structures
(define-map Jobs
    uint
    {
        employer: principal,
        worker: (optional principal),
        description: (string-utf8 500),
        amount: uint,
        status: uint,
        escrow-amount: uint
    }
)

;; Read only functions
(define-read-only (get-job (job-id uint))
    (map-get? Jobs job-id)
)

;; Public functions
(define-public (create-job (description (string-utf8 500)) (amount uint))
    (let
        (
            (job-id (var-get next-job-id))
        )
        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
        (map-set Jobs job-id {
            employer: tx-sender,
            worker: none,
            description: description,
            amount: amount,
            status: u1,
            escrow-amount: amount
        })
        (var-set next-job-id (+ job-id u1))
        (ok job-id)
    )
)

(define-public (accept-job (job-id uint))
    (let
        (
            (job (unwrap! (map-get? Jobs job-id) err-not-found))
        )
        (asserts! (is-eq (get status job) u1) err-wrong-status)
        (map-set Jobs job-id
            (merge job {
                worker: (some tx-sender),
                status: u2
            })
        )
        (ok true)
    )
)

(define-public (complete-job (job-id uint))
    (let
        (
            (job (unwrap! (map-get? Jobs job-id) err-not-found))
        )
        (asserts! (is-eq (unwrap! (get worker job) err-not-found) tx-sender) err-unauthorized)
        (asserts! (is-eq (get status job) u2) err-wrong-status)
        (map-set Jobs job-id
            (merge job { status: u3 })
        )
        (ok true)
    )
)

(define-public (release-payment (job-id uint))
    (let
        (
            (job (unwrap! (map-get? Jobs job-id) err-not-found))
        )
        (asserts! (is-eq (get employer job) tx-sender) err-unauthorized)
        (asserts! (is-eq (get status job) u3) err-wrong-status)
        (try! (as-contract (stx-transfer? (get escrow-amount job) tx-sender (unwrap! (get worker job) err-not-found))))
        (map-set Jobs job-id
            (merge job {
                escrow-amount: u0,
                status: u4
            })
        )
        (ok true)
    )
)

(define-public (dispute-job (job-id uint))
    (let
        (
            (job (unwrap! (map-get? Jobs job-id) err-not-found))
        )
        (asserts! (or (is-eq (get employer job) tx-sender) (is-eq (unwrap! (get worker job) err-not-found) tx-sender)) err-unauthorized)
        (asserts! (is-eq (get status job) u2) err-wrong-status)
        (map-set Jobs job-id
            (merge job { status: u4 })
        )
        (ok true)
    )
)
