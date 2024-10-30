# NFTLend Protocol

NFTLend is a decentralized P2P lending protocol that facilitates NFT-collateralized loans on the blockchain. The protocol enables NFT holders to unlock liquidity from their assets while retaining eventual ownership.

## Core Features

### 🎨 Listing an NFT (Borrower)
- Create a LISTING by putting up your NFT as loan collateral
- Customize loan terms including principal amount, maximum repayment, and duration
- Maintain ownership until loan terms are accepted

### 💰 Making an Offer (Lender) 
- Browse active NFT listings and make competitive loan OFFERS
- Set custom terms including principal amount, interest rate, and duration
- Multiple lenders can compete to provide the best terms

### 🤝 Begin Loan (Borrower)
- Accept your preferred loan offer from competing lenders
- NFT moves into secure protocol escrow
- Receive loan principal instantly
- Lender gets an NFT representing the active loan

### ✨ Repay Loan (Borrower)
- Repay principal + interest before loan expiry
- Small 1% protocol fee on interest earned
- NFT returned immediately from escrow
- Loan NFT burned on completion

### ⚡ Liquidate Loan (Lender)
- Claim NFT collateral after loan expiry and non-payment
- Automated liquidation process
- Loan NFT burned on completion

## Protocol Administration

### Token Management
- ERC20 token whitelisting for loan payments
- ERC721 collection whitelisting for collateral
- Protocol fee collection and withdrawal

### Parameters
- Maximum loan duration
- Maximum number of active loans
- Protocol fee percentage

## License

MIT License
