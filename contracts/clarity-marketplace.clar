;; stx-product-marketplace Smart Contract
;; 
;; This smart contract facilitates a decentralized marketplace where users can list, buy, and sell products 
;; using STX tokens. It includes functionalities for managing product prices, commission rates, product reserves, 
;; and user balances. The contract ensures secure transactions through ownership checks, error handling, and 
;; reserve validation. Key features include:
;; - Setting and updating product prices and commission rates.
;; - Adding and removing products for sale.
;; - Managing user balances for both STX and product inventory.
;; - Calculating commissions on sales and distributing earnings to the seller and contract owner.
;; - Read-only functions for fetching marketplace data such as product prices, user balances, and product listings.

;; Define constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u200))
(define-constant err-insufficient-funds (err u201))
(define-constant err-invalid-price (err u202))
(define-constant err-invalid-quantity (err u203))
(define-constant err-insufficient-quantity (err u204))
(define-constant err-transaction-failed (err u205))
(define-constant err-product-not-found (err u206))
(define-constant err-transaction-aborted (err u207))

;; Define data variables
(define-data-var product-price uint u100) ;; Price per product unit in microstacks (1 STX = 1,000,000 microstacks)
(define-data-var max-products-per-user uint u10000) ;; Max products a user can list
(define-data-var commission-rate uint u5) ;; Commission rate for each sale in percentage
(define-data-var product-reserve-limit uint u1000000) ;; Maximum total products in the system
(define-data-var current-product-reserve uint u0) ;; Total products in the marketplace

;; Define data maps
(define-map user-product-balance principal uint)
(define-map user-stx-balance principal uint)
(define-map products-for-sale {user: principal} {quantity: uint, price: uint})

;; Private functions

;; Calculate commission on sale
(define-private (calculate-commission (sale-price uint))
  (/ (* sale-price (var-get commission-rate)) u100))

;; Update product reserve
(define-private (update-product-reserve (change int))
  (let (
    (current-reserve (var-get current-product-reserve))
    (new-reserve (if (< change 0)
                     (if (>= current-reserve (to-uint (- 0 change)))
                         (- current-reserve (to-uint (- 0 change)))
                         u0)
                     (+ current-reserve (to-uint change))))
  )
    (asserts! (<= new-reserve (var-get product-reserve-limit)) err-product-not-found)
    (var-set current-product-reserve new-reserve)
    (ok true)))

;; Refactor: Consolidate logic for removing products from sale
(define-private (remove-product (quantity uint))
  (begin
    (asserts! (> quantity u0) err-invalid-quantity)
    (let ((current-for-sale (default-to u0 (map-get? user-product-balance tx-sender))))
      (asserts! (>= current-for-sale quantity) err-insufficient-quantity)
      (map-set user-product-balance tx-sender (- current-for-sale quantity)))
    (ok true)))

;; Optimize contract function: Cache commission rate for faster access
(define-private (calculate-commission-optimized (sale-price uint))
  (let ((rate (var-get commission-rate))) ;; Cache commission rate
    (/ (* sale-price rate) u100)))


;; Public functions

;; Set product price (only by the contract owner)
(define-public (set-product-price (new-price uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (> new-price u0) err-invalid-price) ;; Ensure price is greater than 0
    (var-set product-price new-price)
    (ok true)))

;; Set commission rate (only by the contract owner)
(define-public (set-commission-rate (new-rate uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (<= new-rate u100) err-invalid-price) ;; Ensure rate is valid
    (var-set commission-rate new-rate)
    (ok true)))

;; Function to refactor add-product-for-sale to handle price validation
(define-public (refactor-add-product-for-sale (quantity uint) (price uint))
  (let (
    (current-balance (default-to u0 (map-get? user-product-balance tx-sender)))
    (current-for-sale (get quantity (default-to {quantity: u0, price: u0} (map-get? products-for-sale {user: tx-sender}))))
    (new-for-sale (+ quantity current-for-sale))
  )
    ;; Ensure price is valid before adding product
    (asserts! (> price u0) err-invalid-price)
    (asserts! (>= current-balance new-for-sale) err-insufficient-quantity)
    (try! (update-product-reserve (to-int quantity)))
    (map-set products-for-sale {user: tx-sender} {quantity: new-for-sale, price: price})
    (ok true)))

;; Function to fix bug with insufficient quantity in remove-product-from-sale
(define-public (fix-remove-product-bug (quantity uint))
  (let (
    (current-for-sale (get quantity (default-to {quantity: u0, price: u0} (map-get? products-for-sale {user: tx-sender}))))
  )
    ;; Fix bug where quantity to be removed is more than what is available for sale
    (asserts! (>= current-for-sale quantity) err-insufficient-quantity)
    (try! (update-product-reserve (to-int (- quantity))))
    (map-set products-for-sale {user: tx-sender} 
             {quantity: (- current-for-sale quantity), 
              price: (get price (default-to {quantity: u0, price: u0} (map-get? products-for-sale {user: tx-sender})))})
    (ok true)))

;; Set product reserve limit (only by the contract owner)
(define-public (set-product-reserve-limit (new-limit uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (>= new-limit (var-get current-product-reserve)) err-product-not-found)
    (var-set product-reserve-limit new-limit)
    (ok true)))

;; Add products for sale
(define-public (add-product-for-sale (quantity uint) (price uint))
  (let (
    (current-balance (default-to u0 (map-get? user-product-balance tx-sender)))
    (current-for-sale (get quantity (default-to {quantity: u0, price: u0} (map-get? products-for-sale {user: tx-sender}))))
    (new-for-sale (+ quantity current-for-sale))
  )
    (asserts! (> quantity u0) err-invalid-quantity) ;; Ensure quantity is greater than 0
    (asserts! (> price u0) err-invalid-price) ;; Ensure price is greater than 0
    (asserts! (>= current-balance new-for-sale) err-insufficient-quantity)
    (try! (update-product-reserve (to-int quantity)))
    (map-set products-for-sale {user: tx-sender} {quantity: new-for-sale, price: price})
    (ok true)))

;; Remove products from sale
(define-public (remove-product-from-sale (quantity uint))
  (let (
    (current-for-sale (get quantity (default-to {quantity: u0, price: u0} (map-get? products-for-sale {user: tx-sender}))))
  )
    (asserts! (>= current-for-sale quantity) err-insufficient-quantity)
    (try! (update-product-reserve (to-int (- quantity))))
    (map-set products-for-sale {user: tx-sender} 
             {quantity: (- current-for-sale quantity), 
              price: (get price (default-to {quantity: u0, price: u0} (map-get? products-for-sale {user: tx-sender})))})
    (ok true)))

;; Buy products from farmer
(define-public (buy-product-from-farmer (farmer principal) (quantity uint))
  (let (
    (product-data (default-to {quantity: u0, price: u0} (map-get? products-for-sale {user: farmer})))
    (product-cost (* quantity (get price product-data)))
    (commission (calculate-commission product-cost))
    (total-cost (+ product-cost commission))
    (farmer-product (default-to u0 (map-get? user-product-balance farmer)))
    (buyer-balance (default-to u0 (map-get? user-stx-balance tx-sender)))
    (farmer-balance (default-to u0 (map-get? user-stx-balance farmer)))
    (owner-balance (default-to u0 (map-get? user-stx-balance contract-owner)))
  )
    (asserts! (not (is-eq tx-sender farmer)) err-transaction-aborted)
    (asserts! (> quantity u0) err-invalid-quantity) ;; Ensure quantity is greater than 0
    (asserts! (>= (get quantity product-data) quantity) err-insufficient-quantity)
    (asserts! (>= farmer-product quantity) err-insufficient-quantity)
    (asserts! (>= buyer-balance total-cost) err-insufficient-funds)

    ;; Update farmer's product balance and for-sale quantity
    (map-set user-product-balance farmer (- farmer-product quantity))
    (map-set products-for-sale {user: farmer} 
             {quantity: (- (get quantity product-data) quantity), price: (get price product-data)})

    ;; Update buyer's STX and product balance
    (map-set user-stx-balance tx-sender (- buyer-balance total-cost))
    (map-set user-product-balance tx-sender (+ (default-to u0 (map-get? user-product-balance tx-sender)) quantity))

    ;; Update farmer's and contract owner's STX balance
    (map-set user-stx-balance farmer (+ farmer-balance product-cost))
    (map-set user-stx-balance contract-owner (+ owner-balance commission))

    (ok true)))

;; Function to optimize price setting logic by checking for the minimum price
(define-public (optimize-price-check (new-price uint))
  (begin
    ;; Optimize by ensuring price is above a defined minimum threshold
    (asserts! (> new-price u1000) err-invalid-price)  ;; Minimum price in microstacks
    (var-set product-price new-price)
    (ok true)))

;; Function to refactor get-stx-balance for optimized lookup
(define-public (refactor-get-stx-balance (user principal))
  (let (
    (balance (default-to u0 (map-get? user-stx-balance user)))
  )
    ;; Refactor for better performance when fetching STX balance
    (ok balance)))

;; New functionality: Remove products from the reserve
(define-public (remove-product-from-reserve (quantity uint))
  (begin
    (asserts! (> quantity u0) err-invalid-quantity)
    (try! (update-product-reserve (to-int (- quantity))))
    (ok true)))

;; Read-only functions

;; Get current product price
(define-read-only (get-product-price)
  (ok (var-get product-price)))

;; Get current commission rate
(define-read-only (get-commission-rate)
  (ok (var-get commission-rate)))

;; Get user's product balance
(define-read-only (get-product-balance (user principal))
  (ok (default-to u0 (map-get? user-product-balance user))))

;; Get user's STX balance
(define-read-only (get-stx-balance (user principal))
  (ok (default-to u0 (map-get? user-stx-balance user))))

;; Get products for sale by user
(define-read-only (get-products-for-sale (user principal))
  (ok (default-to {quantity: u0, price: u0} (map-get? products-for-sale {user: user}))))

;; Get maximum products per user
(define-read-only (get-max-products-per-user)
  (ok (var-get max-products-per-user)))

;; Get current product reserve
(define-read-only (get-current-product-reserve)
  (ok (var-get current-product-reserve)))

;; Get product reserve limit
(define-read-only (get-product-reserve-limit)
  (ok (var-get product-reserve-limit)))

;; Set maximum products per user (only contract owner)
(define-public (set-max-products-per-user (new-limit uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (> new-limit u0) err-invalid-quantity)
    (var-set max-products-per-user new-limit)
    (ok true)))
