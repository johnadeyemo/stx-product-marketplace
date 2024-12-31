# Marketplace Smart Contract - Clarity 2.0

This Clarity smart contract implements a decentralized marketplace where users can trade products using STX tokens. The contract allows users to list products for sale, manage balances, and perform secure transactions, all while enforcing marketplace rules.

---

## Features

### 1. **Product Management**
   - **Add products for sale**: Users can list their products with a specified quantity and price.
   - **Remove products**: Users can withdraw products from sale.
   - **Set and update product prices**: The contract owner can define the product price globally.

### 2. **Secure Transactions**
   - Buyers can purchase products from sellers with automatic commission deduction.
   - Ensures adequate buyer balance and product availability before completing a transaction.

### 3. **User Balance Management**
   - Tracks product and STX balances for users.
   - Automatically updates balances after each transaction.

### 4. **Marketplace Administration**
   - The contract owner can set global configurations:
     - Product price.
     - Commission rate.
     - Maximum product reserve limit.
     - Maximum products per user.

### 5. **Error Handling**
   - Comprehensive error codes to manage contract operations:
     - `u200` - Only the contract owner can perform certain operations.
     - `u201` - Insufficient funds.
     - `u202` - Invalid price.
     - `u203` - Invalid quantity.
     - `u204` - Insufficient quantity.
     - `u205` - Transaction failed.
     - `u206` - Product not found.
     - `u207` - Transaction aborted.

---

## Smart Contract Overview

### Data Variables
- **`product-price`**: Price per product unit (default: `u100` microstacks).
- **`max-products-per-user`**: Max products a user can list (default: `u10000`).
- **`commission-rate`**: Commission rate in percentage (default: `u5`).
- **`product-reserve-limit`**: Maximum total products in the system (default: `u1000000`).
- **`current-product-reserve`**: Total products currently in the marketplace.

### Data Maps
- **`user-product-balance`**: Tracks product balances for users.
- **`user-stx-balance`**: Tracks STX balances for users.
- **`products-for-sale`**: Tracks products listed for sale by users.

### Functions

#### Public Functions
1. **Set Global Configurations**:
   - `set-product-price`
   - `set-commission-rate`
   - `set-product-reserve-limit`
   - `set-max-products-per-user`

2. **Product Listing and Transactions**:
   - `add-product-for-sale`
   - `remove-product-from-sale`
   - `buy-product-from-farmer`

3. **Optimizations**:
   - `optimize-price-check`
   - `refactor-add-product-for-sale`
   - `fix-remove-product-bug`

#### Read-Only Functions
- Retrieve marketplace data:
  - `get-product-price`
  - `get-commission-rate`
  - `get-product-balance`
  - `get-stx-balance`
  - `get-products-for-sale`
  - `get-max-products-per-user`
  - `get-current-product-reserve`
  - `get-product-reserve-limit`

#### Private Functions
- **`calculate-commission`**: Computes commission for a sale.
- **`update-product-reserve`**: Adjusts the marketplace's product reserve.

---

## How It Works

### 1. **Adding Products**
Users can add products to the marketplace by specifying a quantity and price. The system ensures:
- The user's product balance is sufficient.
- The product reserve limit is not exceeded.

### 2. **Buying Products**
Buyers can purchase products listed by other users. The transaction:
- Deducts the product quantity from the seller.
- Transfers the product to the buyer.
- Deducts the cost (including commission) from the buyer's STX balance.
- Adds the earnings to the seller's STX balance.
- Updates the contract owner's commission balance.

### 3. **Admin Privileges**
Only the contract owner can modify global configurations, such as product price and commission rate, ensuring a controlled and secure marketplace.

---

## Error Codes

| Code | Description                              |
|------|------------------------------------------|
| `u200` | Operation restricted to contract owner. |
| `u201` | Insufficient STX balance.              |
| `u202` | Invalid product price.                 |
| `u203` | Invalid product quantity.              |
| `u204` | Insufficient product quantity.         |
| `u205` | Transaction failed.                    |
| `u206` | Product not found.                     |
| `u207` | Transaction aborted.                   |

---

## Setup and Deployment

### Prerequisites
- [Clarity](https://docs.stacks.co/docs/clarity/overview) development environment.
- A compatible Clarity IDE or CLI.

### Steps
1. Clone the repository.
2. Deploy the contract to a Stacks blockchain testnet or mainnet.
3. Use Clarity CLI or tools like [Clarinet](https://docs.hiro.so/clarinet) to interact with the contract.

---

## Usage Examples

### Add Product for Sale
```clarity
(add-product-for-sale u10 u200)
```

### Buy Product
```clarity
(buy-product-from-farmer 'SP1234ABCD u5)
```

### Set Product Price (Admin)
```clarity
(set-product-price u150)
```

---

## Contributing
Contributions are welcome! Please submit issues or pull requests to improve the contract's functionality or documentation.

---

## License
This project is licensed under the MIT License. See the `LICENSE` file for details.

---

## Contact
For inquiries, please contact the repository owner or open an issue.

