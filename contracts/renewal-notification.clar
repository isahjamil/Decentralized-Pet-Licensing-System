;; Renewal Notification Contract
;; Manages license renewal reminders and notifications

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u200))
(define-constant ERR-NOTIFICATION-NOT-FOUND (err u201))
(define-constant ERR-INVALID-INPUT (err u202))
(define-constant ERR-ALREADY-NOTIFIED (err u203))

;; Data Variables
(define-data-var notification-window uint u2592000) ;; 30 days in seconds
(define-data-var grace-period uint u1296000) ;; 15 days in seconds
(define-data-var late-fee uint u10)

;; Data Maps
(define-map renewal-notifications
  { pet-id: uint }
  {
    owner: principal,
    license-expires: uint,
    first-notice-sent: uint,
    second-notice-sent: uint,
    final-notice-sent: uint,
    is-renewed: bool,
    late-fee-applied: bool
  }
)

(define-map notification-history
  { pet-id: uint, notice-type: (string-ascii 20) }
  {
    sent-date: uint,
    recipient: principal,
    message: (string-ascii 200)
  }
)

(define-map owner-notification-preferences
  { owner: principal }
  {
    email-notifications: bool,
    sms-notifications: bool,
    advance-notice-days: uint
  }
)

;; Private Functions
(define-private (is-within-notification-window (expiry-date uint) (current-time uint))
  (let ((time-until-expiry (- expiry-date current-time)))
    (< time-until-expiry (var-get notification-window))
  )
)

(define-private (calculate-late-fee (days-overdue uint))
  (if (> days-overdue u0)
    (* (var-get late-fee) days-overdue)
    u0
  )
)

(define-private (get-days-overdue (expiry-date uint) (current-time uint))
  (if (> current-time expiry-date)
    (/ (- current-time expiry-date) u86400) ;; Convert seconds to days
    u0
  )
)

;; Public Functions
(define-public (create-renewal-notification (pet-id uint) (owner principal) (license-expires uint))
  (let ((current-time (unwrap-panic (get-block-info? time (- block-height u1)))))
    (asserts! (is-within-notification-window license-expires current-time) ERR-INVALID-INPUT)
    (asserts! (is-none (map-get? renewal-notifications { pet-id: pet-id })) ERR-ALREADY-NOTIFIED)

    (map-set renewal-notifications
      { pet-id: pet-id }
      {
        owner: owner,
        license-expires: license-expires,
        first-notice-sent: u0,
        second-notice-sent: u0,
        final-notice-sent: u0,
        is-renewed: false,
        late-fee-applied: false
      }
    )

    (ok true)
  )
)

(define-public (send-first-notice (pet-id uint))
  (let
    (
      (notification (unwrap! (map-get? renewal-notifications { pet-id: pet-id }) ERR-NOTIFICATION-NOT-FOUND))
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
    )
    (asserts! (is-eq (get first-notice-sent notification) u0) ERR-ALREADY-NOTIFIED)

    ;; Update notification record
    (map-set renewal-notifications
      { pet-id: pet-id }
      (merge notification { first-notice-sent: current-time })
    )

    ;; Record notification history
    (map-set notification-history
      { pet-id: pet-id, notice-type: "first-notice" }
      {
        sent-date: current-time,
        recipient: (get owner notification),
        message: "Your pet license expires soon. Please renew to avoid late fees."
      }
    )

    (ok true)
  )
)

(define-public (send-second-notice (pet-id uint))
  (let
    (
      (notification (unwrap! (map-get? renewal-notifications { pet-id: pet-id }) ERR-NOTIFICATION-NOT-FOUND))
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
    )
    (asserts! (> (get first-notice-sent notification) u0) ERR-INVALID-INPUT)
    (asserts! (is-eq (get second-notice-sent notification) u0) ERR-ALREADY-NOTIFIED)

    (map-set renewal-notifications
      { pet-id: pet-id }
      (merge notification { second-notice-sent: current-time })
    )

    (map-set notification-history
      { pet-id: pet-id, notice-type: "second-notice" }
      {
        sent-date: current-time,
        recipient: (get owner notification),
        message: "Final reminder: Your pet license expires in 7 days."
      }
    )

    (ok true)
  )
)

(define-public (send-final-notice (pet-id uint))
  (let
    (
      (notification (unwrap! (map-get? renewal-notifications { pet-id: pet-id }) ERR-NOTIFICATION-NOT-FOUND))
      (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
      (days-overdue (get-days-overdue (get license-expires notification) current-time))
    )
    (asserts! (> (get second-notice-sent notification) u0) ERR-INVALID-INPUT)
    (asserts! (is-eq (get final-notice-sent notification) u0) ERR-ALREADY-NOTIFIED)

    ;; Apply late fee if overdue
    (let ((late-fee-amount (calculate-late-fee days-overdue)))
      (map-set renewal-notifications
        { pet-id: pet-id }
        (merge notification {
          final-notice-sent: current-time,
          late-fee-applied: (> late-fee-amount u0)
        })
      )

      (map-set notification-history
        { pet-id: pet-id, notice-type: "final-notice" }
        {
          sent-date: current-time,
          recipient: (get owner notification),
          message: "Your pet license has expired. Late fees may apply."
        }
      )

      (ok true)
    )
  )
)

(define-public (mark-as-renewed (pet-id uint))
  (let ((notification (unwrap! (map-get? renewal-notifications { pet-id: pet-id }) ERR-NOTIFICATION-NOT-FOUND)))
    (map-set renewal-notifications
      { pet-id: pet-id }
      (merge notification { is-renewed: true })
    )

    (ok true)
  )
)

(define-public (set-notification-preferences
  (email-notifications bool)
  (sms-notifications bool)
  (advance-notice-days uint)
)
  (begin
    (asserts! (< advance-notice-days u90) ERR-INVALID-INPUT)

    (map-set owner-notification-preferences
      { owner: tx-sender }
      {
        email-notifications: email-notifications,
        sms-notifications: sms-notifications,
        advance-notice-days: advance-notice-days
      }
    )

    (ok true)
  )
)

;; Read-only Functions
(define-read-only (get-notification-status (pet-id uint))
  (map-get? renewal-notifications { pet-id: pet-id })
)

(define-read-only (get-notification-history (pet-id uint) (notice-type (string-ascii 20)))
  (map-get? notification-history { pet-id: pet-id, notice-type: notice-type })
)

(define-read-only (get-owner-preferences (owner principal))
  (map-get? owner-notification-preferences { owner: owner })
)

(define-read-only (calculate-current-late-fee (pet-id uint))
  (match (map-get? renewal-notifications { pet-id: pet-id })
    notification
    (let
      (
        (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
        (days-overdue (get-days-overdue (get license-expires notification) current-time))
      )
      (calculate-late-fee days-overdue)
    )
    u0
  )
)

(define-read-only (get-notification-window)
  (var-get notification-window)
)

;; Admin Functions
(define-public (set-notification-window (new-window uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (var-set notification-window new-window)
    (ok true)
  )
)

(define-public (set-late-fee (new-fee uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (var-set late-fee new-fee)
    (ok true)
  )
)
