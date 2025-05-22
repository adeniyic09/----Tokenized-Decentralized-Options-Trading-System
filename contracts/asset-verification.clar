;; Asset Verification Contract
;; Validates underlying instruments for options trading

(define-data-var contract-owner principal tx-sender)

;; Map of verified assets
(define-map verified-assets
  { asset-id: (string-ascii 32) }
  {
    verified: bool,
    asset-type: (string-ascii 10),
    decimals: uint,
    verified-by: principal
  }
)

;; Error codes
(define-constant ERR-NOT-AUTHORIZED u100)
(define-constant ERR-ALREADY-VERIFIED u101)
(define-constant ERR-INVALID-ASSET u102)

;; Check if caller is contract owner
(define-private (is-contract-owner)
  (is-eq tx-sender (var-get contract-owner))
)

;; Verify a new asset
(define-public (verify-asset (asset-id (string-ascii 32)) (asset-type (string-ascii 10)) (decimals uint))
  (begin
    (asserts! (is-contract-owner) (err ERR-NOT-AUTHORIZED))
    (asserts! (is-none (map-get? verified-assets { asset-id: asset-id })) (err ERR-ALREADY-VERIFIED))

    (map-set verified-assets
      { asset-id: asset-id }
      {
        verified: true,
        asset-type: asset-type,
        decimals: decimals,
        verified-by: tx-sender
      }
    )
    (ok true)
  )
)

;; Check if an asset is verified
(define-read-only (is-asset-verified (asset-id (string-ascii 32)))
  (match (map-get? verified-assets { asset-id: asset-id })
    asset-data (ok (get verified asset-data))
    (err ERR-INVALID-ASSET)
  )
)

;; Get asset details
(define-read-only (get-asset-details (asset-id (string-ascii 32)))
  (map-get? verified-assets { asset-id: asset-id })
)

;; Transfer ownership
(define-public (transfer-ownership (new-owner principal))
  (begin
    (asserts! (is-contract-owner) (err ERR-NOT-AUTHORIZED))
    (var-set contract-owner new-owner)
    (ok true)
  )
)
