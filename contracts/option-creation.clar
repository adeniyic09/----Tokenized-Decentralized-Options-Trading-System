;; Option Creation Contract
;; Defines derivative parameters

(define-data-var contract-owner principal tx-sender)
(define-data-var option-counter uint u0)

;; Option types
(define-constant OPTION-TYPE-CALL "CALL")
(define-constant OPTION-TYPE-PUT "PUT")

;; Error codes
(define-constant ERR-NOT-AUTHORIZED u100)
(define-constant ERR-INVALID-ASSET u101)
(define-constant ERR-INVALID-EXPIRY u102)
(define-constant ERR-INVALID-STRIKE u103)
(define-constant ERR-INVALID-OPTION-TYPE u104)
(define-constant ERR-OPTION-NOT-FOUND u105)

;; Option data structure
(define-map options
  { option-id: uint }
  {
    creator: principal,
    asset-id: (string-ascii 32),
    option-type: (string-ascii 4),
    strike-price: uint,
    expiry-height: uint,
    premium: uint,
    active: bool
  }
)

;; Check if caller is contract owner
(define-private (is-contract-owner)
  (is-eq tx-sender (var-get contract-owner))
)

;; Validate option type
(define-private (is-valid-option-type (option-type (string-ascii 4)))
  (or
    (is-eq option-type OPTION-TYPE-CALL)
    (is-eq option-type OPTION-TYPE-PUT)
  )
)

;; Create a new option
(define-public (create-option
    (asset-id (string-ascii 32))
    (option-type (string-ascii 4))
    (strike-price uint)
    (expiry-blocks uint)
    (premium uint))
  (let
    (
      (current-height block-height)
      (expiry-height (+ current-height expiry-blocks))
      (option-id (+ (var-get option-counter) u1))
    )

    ;; Validate inputs
    (asserts! (is-valid-option-type option-type) (err ERR-INVALID-OPTION-TYPE))
    (asserts! (> strike-price u0) (err ERR-INVALID-STRIKE))
    (asserts! (> expiry-blocks u0) (err ERR-INVALID-EXPIRY))

    ;; Create the option
    (map-set options
      { option-id: option-id }
      {
        creator: tx-sender,
        asset-id: asset-id,
        option-type: option-type,
        strike-price: strike-price,
        expiry-height: expiry-height,
        premium: premium,
        active: true
      }
    )

    ;; Increment counter
    (var-set option-counter option-id)

    (ok option-id)
  )
)

;; Get option details
(define-read-only (get-option (option-id uint))
  (map-get? options { option-id: option-id })
)

;; Deactivate an option (can only be done by creator)
(define-public (deactivate-option (option-id uint))
  (let ((option-data (unwrap! (map-get? options { option-id: option-id }) (err ERR-OPTION-NOT-FOUND))))
    (asserts! (is-eq tx-sender (get creator option-data)) (err ERR-NOT-AUTHORIZED))

    (map-set options
      { option-id: option-id }
      (merge option-data { active: false })
    )

    (ok true)
  )
)

;; Check if option is expired
(define-read-only (is-option-expired (option-id uint))
  (match (map-get? options { option-id: option-id })
    option-data (ok (> block-height (get expiry-height option-data)))
    (err ERR-OPTION-NOT-FOUND)
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
