;; Settlement Contract
;; Handles contract execution at expiry

(define-data-var contract-owner principal tx-sender)

;; Contract references (would be set after deployment)
(define-data-var option-contract principal tx-sender)
(define-data-var collateral-contract principal tx-sender)
(define-data-var price-oracle principal tx-sender)

;; Option types
(define-constant OPTION-TYPE-CALL "CALL")
(define-constant OPTION-TYPE-PUT "PUT")

;; Error codes
(define-constant ERR-NOT-AUTHORIZED u100)
(define-constant ERR-OPTION-NOT-EXPIRED u101)
(define-constant ERR-SETTLEMENT-FAILED u102)
(define-constant ERR-ALREADY-SETTLED u103)

;; Settlement records
(define-map settlements
  { option-id: uint }
  {
    settled: bool,
    settlement-price: uint,
    settlement-amount: uint,
    settled-at: uint,
    settled-by: principal
  }
)

;; Check if caller is contract owner
(define-private (is-contract-owner)
  (is-eq tx-sender (var-get contract-owner))
)

;; Calculate settlement amount
(define-private (calculate-settlement (option-type (string-ascii 4)) (strike-price uint) (current-price uint) (size uint))
  (if (is-eq option-type OPTION-TYPE-CALL)
    ;; For CALL options: max(0, current_price - strike_price) * size
    (if (> current-price strike-price)
      (* (- current-price strike-price) size)
      u0
    )
    ;; For PUT options: max(0, strike_price - current_price) * size
    (if (> strike-price current-price)
      (* (- strike-price current-price) size)
      u0
    )
  )
)

;; Settle an option
(define-public (settle-option (option-id uint) (settlement-price uint) (size uint))
  (begin
    ;; In a real implementation, we would:
    ;; 1. Check if option is expired by calling the option contract
    ;; 2. Verify the settlement price from the oracle
    ;; 3. Calculate the settlement amount
    ;; 4. Transfer funds between parties

    ;; For simplicity, we're just recording the settlement
    (asserts! (is-none (map-get? settlements { option-id: option-id })) (err ERR-ALREADY-SETTLED))

    (let
      (
        ;; In a real implementation, we would get these from the option contract
        (option-type OPTION-TYPE-CALL)
        (strike-price u1000)
        (settlement-amount (calculate-settlement option-type strike-price settlement-price size))
      )

      (map-set settlements
        { option-id: option-id }
        {
          settled: true,
          settlement-price: settlement-price,
          settlement-amount: settlement-amount,
          settled-at: block-height,
          settled-by: tx-sender
        }
      )

      (ok settlement-amount)
    )
  )
)

;; Check if option is settled
(define-read-only (is-settled (option-id uint))
  (match (map-get? settlements { option-id: option-id })
    settlement-data (get settled settlement-data)
    false
  )
)

;; Get settlement details
(define-read-only (get-settlement (option-id uint))
  (map-get? settlements { option-id: option-id })
)

;; Set contract references
(define-public (set-contract-references
    (new-option-contract principal)
    (new-collateral-contract principal)
    (new-price-oracle principal))
  (begin
    (asserts! (is-contract-owner) (err ERR-NOT-AUTHORIZED))
    (var-set option-contract new-option-contract)
    (var-set collateral-contract new-collateral-contract)
    (var-set price-oracle new-price-oracle)
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
