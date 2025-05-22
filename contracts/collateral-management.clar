;; Collateral Management Contract
;; Tracks backing assets for options

(define-data-var contract-owner principal tx-sender)

;; Error codes
(define-constant ERR-NOT-AUTHORIZED u100)
(define-constant ERR-INSUFFICIENT-COLLATERAL u101)
(define-constant ERR-OPTION-NOT-FOUND u102)
(define-constant ERR-ALREADY-COLLATERALIZED u103)
(define-constant ERR-NOT-COLLATERALIZED u104)

;; Collateral data structure
(define-map collateral-vault
  { option-id: uint }
  {
    collateral-amount: uint,
    collateral-provider: principal,
    locked-until: uint
  }
)

;; Check if caller is contract owner
(define-private (is-contract-owner)
  (is-eq tx-sender (var-get contract-owner))
)

;; Add collateral for an option
(define-public (add-collateral (option-id uint) (amount uint) (lock-until uint))
  (begin
    (asserts! (> amount u0) (err ERR-INSUFFICIENT-COLLATERAL))
    (asserts! (> lock-until block-height) (err ERR-INSUFFICIENT-COLLATERAL))
    (asserts! (is-none (map-get? collateral-vault { option-id: option-id })) (err ERR-ALREADY-COLLATERALIZED))

    ;; Store collateral information
    (map-set collateral-vault
      { option-id: option-id }
      {
        collateral-amount: amount,
        collateral-provider: tx-sender,
        locked-until: lock-until
      }
    )

    ;; In a real implementation, we would transfer tokens here
    ;; For simplicity, we're just recording the collateral

    (ok true)
  )
)

;; Get collateral details
(define-read-only (get-collateral (option-id uint))
  (map-get? collateral-vault { option-id: option-id })
)

;; Check if option is collateralized
(define-read-only (is-collateralized (option-id uint))
  (is-some (map-get? collateral-vault { option-id: option-id }))
)

;; Release collateral (only after lock period)
(define-public (release-collateral (option-id uint))
  (let ((collateral-data (unwrap! (map-get? collateral-vault { option-id: option-id }) (err ERR-NOT-COLLATERALIZED))))
    (asserts! (is-eq tx-sender (get collateral-provider collateral-data)) (err ERR-NOT-AUTHORIZED))
    (asserts! (<= (get locked-until collateral-data) block-height) (err ERR-NOT-AUTHORIZED))

    ;; Delete collateral record
    (map-delete collateral-vault { option-id: option-id })

    ;; In a real implementation, we would transfer tokens back here

    (ok true)
  )
)

;; Transfer ownership
(define-public (transfer-ownership (new-owner principal))
  (begin
    (asserts! (is-contract-owner) (err ERR-NOT-AUTHORIZED))
    (var-set contract-owner new-owner)
    (ok true)
  )
)
