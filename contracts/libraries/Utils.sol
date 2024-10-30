// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

library Events {
    event LoanStarted(
        uint256 indexed loanId,
        address indexed borrower,
        address lender,
        uint256 loanPrincipalAmount,
        uint256 maximumRepaymentAmount,
        uint256 nftCollateralId,
        uint256 loanStartTime,
        uint256 loanDuration,
        uint256 loanInterestRate,
        address nftCollateralContract,
        address loanERC20Address
    );
    event ListingCreated(
        uint256 indexed listingId,
        address indexed borrower,
        address nftCollateralContract,
        uint256 nftCollateralId,
        address loanERC20Address,
        uint256 loanPrincipalAmount,
        uint256 maximumRepaymentAmount
    );
    event ListingCancelled(
        uint256 indexed listingId, address indexed borrower, address nftCollateralContract, uint256 nftCollateralId
    );
    event OfferCreated(
        uint256 indexed offerId,
        uint256 indexed listingId,
        address indexed lender,
        uint256 loanPrincipalAmount,
        uint256 maximumRepaymentAmount,
        uint32 loanDuration,
        uint32 loanInterestRate
    );

    event OfferCancelled(uint256 indexed offerId, uint256 indexed listingId, address indexed lender);
    event OfferAccepted(
        uint256 indexed offerId,
        uint256 indexed listingId,
        address indexed borrower,
        address lender,
        uint256 loanPrincipalAmount,
        uint256 maximumRepaymentAmount
    );
    event LoanRepaid(
        uint256 indexed loanId,
        address indexed borrower,
        address indexed lender,
        uint256 totalPayback,
        uint256 protocolFee,
        uint256 nftCollateralId
    );

    event ProtocolFeesWithdrawn(address indexed token, uint256 amount, address indexed owner);
    event LoanLiquidated(
        uint256 indexed loanId, address indexed borrower, address indexed lender, uint256 nftCollateralId
    );
    event ERC20Whitelisted(address indexed token, bool status);
    event ERC721Whitelisted(address indexed token, bool status);
}

library Errors {
    error NFTTransferFailed();
    error LoanDoesNotExist();
    error NotWhitelistedERC20();
    error NeedsMoreThanZero();
    error NotWhitelistedERC721();
    error NotERC721Owner();
    error ContractNotApproved();
    error RepaymentNotGreaterthanPrincipal();
    error InterestRateGreaterthanZero();
    error LoanDurationGreaterthanZero();
    error ListingNotActive();
    error NotlistingOwner();
    error YouarelistingOwner();
    error ListingDoesNotExist();
    error OfferDoesNotExist();
    error InsufficientERC20Allowance();
    error InsufficientERC20Balance();
    error OfferNotActive();
    error NotOfferOwner();
    error LoanNotactive();
    error NotLoanBorrower();
    error NotLoanOwner();
    error LoanNotOverdue();
    error AddressZero();
}
