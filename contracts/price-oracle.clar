;; Price Oracle Contract
;; Records market values for assets

(define-data-var contract-owner principal tx-sender)
(define-data-var trusted-oracle principal tx-sender)

;; Error codes
(define-constant ERR-NOT-AUTHORIZED u100)
(define-constant ERR-PRICE-NOT-FOUND u101)

;; Price data structure
(define-map asset-prices
  { asset-id: (string-ascii 32) }
  {
    price: uint,
    decimals: uint,
    last-updated: uint,
    updated-by: principal
  }
)

;; Check if caller is contract owner
(define-private (is-contract-owner)
  (is-eq tx-sender (var-get contract-owner))
)

;; Check if caller is trusted oracle
(define-private (is-trusted-oracle)
  (is-eq tx-sender (var-get trusted-oracle))
)

;; Update price for an asset
(define-public (update-price (asset-id (string-ascii 32)) (price uint) (decimals uint))
  (begin
    (asserts! (is-trusted-oracle) (err ERR-NOT-AUTHORIZED))

    (map-set asset-prices
      { asset-id: asset-id }
      {
        price: price,
        decimals: decimals,
        last-updated: block-height,
        updated-by: tx-sender
      }
    )

    (ok true)
  )
)

;; Get current price for an asset
(define-read-only (get-price (asset-id (string-ascii 32)))
  (match (map-get? asset-prices { asset-id: asset-id })
    price-data (ok price-data)
    (err ERR-PRICE-NOT-FOUND)
  )
)

;; Set trusted oracle
(define-public (set-trusted-oracle (new-oracle principal))
  (begin
    (asserts! (is-contract-owner) (err ERR-NOT-AUTHORIZED))
    (var-set trusted-oracle new-oracle)
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
