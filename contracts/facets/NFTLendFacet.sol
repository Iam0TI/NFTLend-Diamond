// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {ERC721Facet} from "./ERC721Facet.sol";
import {IERC721} from "../libraries/IERC721.sol";
import {IERC20} from "../libraries/IERC20.sol";
import {Events, Errors} from "../libraries/Utils.sol";

contract NFTLendFacet is ERC721Facet {
    modifier MoreThanZero(uint256 _amount) {
        require(_amount > 0, Errors.NeedsMoreThanZero());
        _;
    }

    modifier isAllowedToken(address _token) {
        LibDiamond.DiamondStorage storage l = LibDiamond.diamondStorage();
        require(l.whitelistedERC20s[_token] == true, Errors.NotWhitelistedERC20());
        _;
    }

    modifier isAllowedNFT(address _nfttoken) {
        LibDiamond.DiamondStorage storage l = LibDiamond.diamondStorage();
        require(l.whitelistedERC721s[_nfttoken] == true, Errors.NotWhitelistedERC721());
        _;
    }

    modifier listingExists(uint256 listingId) {
        LibDiamond.DiamondStorage storage l = LibDiamond.diamondStorage();
        require(listingId < l.listingId, Errors.ListingDoesNotExist());
        _;
    }

    modifier offerExists(uint256 offerId) {
        LibDiamond.DiamondStorage storage l = LibDiamond.diamondStorage();
        require(offerId < l.offerId, Errors.OfferDoesNotExist());
        _;
    }

    struct ListingParams {
        address nftCollateralContract;
        uint256 nftCollateralId;
        address loanERC20Address;
        uint256 loanPrincipalAmount;
        uint256 maximumRepaymentAmount;
        uint32 loanDuration;
        uint32 loanInterestRate;
    }

    struct OfferParams {
        uint256 listingId;
        uint256 loanPrincipalAmount;
        uint256 maximumRepaymentAmount;
        uint32 loanDuration;
        uint32 loanInterestRate;
    }

    function ListNFTAsCollateral(ListingParams calldata params)
        external
        MoreThanZero(params.loanPrincipalAmount)
        MoreThanZero(params.maximumRepaymentAmount)
        isAllowedToken(params.loanERC20Address)
        isAllowedNFT(params.nftCollateralContract)
    {
        require(
            IERC721(params.nftCollateralContract).ownerOf(params.nftCollateralId) == msg.sender, Errors.NotERC721Owner()
        );

        require(
            IERC721(params.nftCollateralContract).isApprovedForAll(msg.sender, address(this))
                || IERC721(params.nftCollateralContract).getApproved(params.nftCollateralId) == address(this),
            Errors.ContractNotApproved()
        );

        require(params.maximumRepaymentAmount > params.loanPrincipalAmount, Errors.RepaymentNotGreaterthanPrincipal());
        require(params.loanDuration > 0, Errors.LoanDurationGreaterthanZero());
        require(params.loanInterestRate > 0, Errors.InterestRateGreaterthanZero());

        LibDiamond.DiamondStorage storage l = LibDiamond.diamondStorage();
        uint256 listingId = l.listingId;

        l.listings[listingId] = LibDiamond.Listing({
            nftCollateralContract: params.nftCollateralContract,
            nftCollateralId: params.nftCollateralId,
            loanERC20Address: params.loanERC20Address,
            loanPrincipalAmount: params.loanPrincipalAmount,
            maximumRepaymentAmount: params.maximumRepaymentAmount,
            loanDuration: params.loanDuration,
            loanInterestRate: params.loanInterestRate,
            borrower: msg.sender,
            status: LibDiamond.ListingStatus.Active
        });

        ++l.listingId;

        emit Events.ListingCreated(
            listingId,
            msg.sender,
            params.nftCollateralContract,
            params.nftCollateralId,
            params.loanERC20Address,
            params.loanPrincipalAmount,
            params.maximumRepaymentAmount
        );
    }

    function cancelListing(uint256 listingId) external listingExists(listingId) {
        LibDiamond.DiamondStorage storage l = LibDiamond.diamondStorage();
        LibDiamond.Listing storage listing = l.listings[listingId];

        require(listing.borrower == msg.sender, Errors.NotlistingOwner());
        require(listing.status == LibDiamond.ListingStatus.Active, Errors.ListingNotActive());

        listing.status = LibDiamond.ListingStatus.Cancelled;

        emit Events.ListingCancelled(listingId, msg.sender, listing.nftCollateralContract, listing.nftCollateralId);
    }

    function MakeOfferForColleratalListing(OfferParams calldata params)
        external
        listingExists(params.listingId)
        MoreThanZero(params.loanPrincipalAmount)
        MoreThanZero(params.maximumRepaymentAmount)
    {
        LibDiamond.DiamondStorage storage l = LibDiamond.diamondStorage();
        LibDiamond.Listing storage listing = l.listings[params.listingId];

        require(listing.status == LibDiamond.ListingStatus.Active, Errors.ListingNotActive());
        require(msg.sender != listing.borrower, Errors.YouarelistingOwner());
        require(params.maximumRepaymentAmount > params.loanPrincipalAmount, Errors.RepaymentNotGreaterthanPrincipal());

        require(
            IERC20(listing.loanERC20Address).allowance(msg.sender, address(this)) >= params.loanPrincipalAmount,
            Errors.InsufficientERC20Allowance()
        );
        require(
            IERC20(listing.loanERC20Address).balanceOf(msg.sender) >= params.loanPrincipalAmount,
            Errors.InsufficientERC20Balance()
        );

        uint256 offerId = l.offerId;
        l.offers[offerId] = LibDiamond.Offer({
            offerId: offerId,
            listingId: params.listingId,
            lender: msg.sender,
            loanPrincipalAmount: params.loanPrincipalAmount,
            maximumRepaymentAmount: params.maximumRepaymentAmount,
            loanDuration: params.loanDuration,
            loanInterestRate: params.loanInterestRate,
            status: LibDiamond.OfferStatus.Active
        });

        ++l.offerId;

        emit Events.OfferCreated(
            offerId,
            params.listingId,
            msg.sender,
            params.loanPrincipalAmount,
            params.maximumRepaymentAmount,
            params.loanDuration,
            params.loanInterestRate
        );
    }

    function cancelOffer(uint256 offerId) external offerExists(offerId) {
        LibDiamond.DiamondStorage storage l = LibDiamond.diamondStorage();
        LibDiamond.Offer storage offer = l.offers[offerId];

        require(offer.lender == msg.sender, Errors.NotOfferOwner());
        require(offer.status == LibDiamond.OfferStatus.Active, Errors.OfferNotActive());

        offer.status = LibDiamond.OfferStatus.Cancelled;

        emit Events.OfferCancelled(offerId, offer.listingId, msg.sender);
    }

    function acceptLoanOffer(uint256 offerId) external offerExists(offerId) {
        LibDiamond.DiamondStorage storage l = LibDiamond.diamondStorage();
        LibDiamond.Offer storage offer = l.offers[offerId];
        LibDiamond.Listing storage listing = l.listings[offer.listingId];

        require(listing.borrower == msg.sender, Errors.NotlistingOwner());
        require(listing.status == LibDiamond.ListingStatus.Active, Errors.ListingNotActive());
        require(offer.status == LibDiamond.OfferStatus.Active, Errors.OfferNotActive());

        // Update statuses
        listing.status = LibDiamond.ListingStatus.Executed;
        offer.status = LibDiamond.OfferStatus.Accepted;

        _createLoan(
            offer.loanPrincipalAmount,
            offer.maximumRepaymentAmount,
            listing.nftCollateralId,
            offer.loanDuration,
            offer.loanInterestRate,
            listing.nftCollateralContract,
            listing.loanERC20Address,
            offer.lender
        );

        emit Events.OfferAccepted(
            offer.offerId,
            offer.listingId,
            msg.sender,
            offer.lender,
            offer.loanPrincipalAmount,
            offer.maximumRepaymentAmount
        );
    }

    function getListing(uint256 listingId) external view listingExists(listingId) returns (LibDiamond.Listing memory) {
        LibDiamond.DiamondStorage storage l = LibDiamond.diamondStorage();
        return l.listings[listingId];
    }

    function getOffer(uint256 offerId) external view offerExists(offerId) returns (LibDiamond.Offer memory) {
        LibDiamond.DiamondStorage storage l = LibDiamond.diamondStorage();
        return l.offers[offerId];
    }

    function _createLoan(
        uint256 loanPrincipalAmount,
        uint256 maximumRepaymentAmount,
        uint256 nftCollateralId,
        uint32 loanDuration,
        uint32 loanInterestRate,
        address nftCollateralContract,
        address loanERC20Address,
        address lender
    ) internal {
        // Transfer NFT collateral to the contract
        IERC721(nftCollateralContract).transferFrom(msg.sender, address(this), nftCollateralId);
        require(IERC721(nftCollateralContract).ownerOf(nftCollateralId) == address(this), Errors.NFTTransferFailed());

        // Access diamond storage
        LibDiamond.DiamondStorage storage l = LibDiamond.diamondStorage();
        uint256 loanId = l.loanId;

        // Create a new loan struct and assign values
        LibDiamond.Loan memory newLoan = LibDiamond.Loan({
            loanId: loanId,
            loanPrincipalAmount: loanPrincipalAmount,
            maximumRepaymentAmount: maximumRepaymentAmount,
            nftCollateralId: nftCollateralId,
            loanStartTime: block.timestamp,
            loanDuration: loanDuration,
            loanInterestRate: loanInterestRate,
            nftCollateralContract: nftCollateralContract,
            loanERC20Address: loanERC20Address,
            borrower: msg.sender,
            status: LibDiamond.LoanStatus.Active
        });

        // Assign the new loan to the storage and increment loanId
        l.loans[loanId] = newLoan;
        ++l.loanId;

        // Transfer the loan principal amount from lender to the contract
        IERC20(loanERC20Address).transferFrom(lender, address(this), loanPrincipalAmount);

        // Mint an NFT to the lender to represent ownership of the loan
        _mint(lender, loanId);

        // Emit the LoanStarted event
        emit Events.LoanStarted(
            loanId,
            msg.sender,
            lender,
            loanPrincipalAmount,
            maximumRepaymentAmount,
            nftCollateralId,
            block.timestamp,
            loanDuration,
            loanInterestRate,
            nftCollateralContract,
            loanERC20Address
        );
    }
}
