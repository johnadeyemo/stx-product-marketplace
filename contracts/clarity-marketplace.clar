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