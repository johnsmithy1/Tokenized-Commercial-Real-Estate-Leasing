;; Property Verification Contract
;; Validates ownership and condition of commercial real estate properties

(define-data-var contract-owner principal tx-sender)

;; Property data structure
(define-map properties
  { property-id: uint }
  {
    owner: principal,
    verified: bool,
    address: (string-utf8 256),
    condition-score: uint,
    last-inspection-time: uint,
    property-details: (string-utf8 1024)
  }
)

;; Verifier data structure
(define-map verifiers
  { verifier: principal }
  {
    authorized: bool,
    reputation-score: uint
  }
)

;; Initialize contract
(define-public (initialize)
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u1))
    (ok true)
  )
)

;; Add a new property
(define-public (register-property
    (property-id uint)
    (address (string-utf8 256))
    (property-details (string-utf8 1024)))
  (begin
    (asserts! (is-none (map-get? properties { property-id: property-id })) (err u2))
    (map-set properties
      { property-id: property-id }
      {
        owner: tx-sender,
        verified: false,
        address: address,
        condition-score: u0,
        last-inspection-time: u0,
        property-details: property-details
      }
    )
    (ok true)
  )
)

;; Transfer property ownership
(define-public (transfer-property (property-id uint) (new-owner principal))
  (let ((property (unwrap! (map-get? properties { property-id: property-id }) (err u3))))
    (asserts! (is-eq tx-sender (get owner property)) (err u4))
    (map-set properties
      { property-id: property-id }
      (merge property { owner: new-owner })
    )
    (ok true)
  )
)

;; Add a verifier
(define-public (add-verifier (verifier principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u5))
    (map-set verifiers
      { verifier: verifier }
      {
        authorized: true,
        reputation-score: u100
      }
    )
    (ok true)
  )
)

;; Verify a property
(define-public (verify-property
    (property-id uint)
    (condition-score uint))
  (let (
    (property (unwrap! (map-get? properties { property-id: property-id }) (err u6)))
    (verifier (unwrap! (map-get? verifiers { verifier: tx-sender }) (err u7)))
  )
    (asserts! (get authorized verifier) (err u8))
    (map-set properties
      { property-id: property-id }
      (merge property {
        verified: true,
        condition-score: condition-score,
        last-inspection-time: block-height
      })
    )
    (ok true)
  )
)

;; Read property details
(define-read-only (get-property (property-id uint))
  (map-get? properties { property-id: property-id })
)

;; Check if property is verified
(define-read-only (is-property-verified (property-id uint))
  (match (map-get? properties { property-id: property-id })
    property (get verified property)
    false
  )
)
