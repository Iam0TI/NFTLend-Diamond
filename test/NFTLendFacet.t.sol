// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.27;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Vm} from "forge-std/Vm.sol";
import "./helpers/DiamondUtils.sol";
import "../contracts/interfaces/IDiamondCut.sol";
import "../contracts/facets/DiamondCutFacet.sol";
import "../contracts/facets/DiamondLoupeFacet.sol";
import "../contracts/facets/OwnershipFacet.sol";
import "../contracts/facets/NFTLendFacet.sol";
import "../contracts/facets/WhitelistFacet.sol";
import "../contracts/Diamond.sol";

contract MockERC721 {
    mapping(uint256 => address) private _owners;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    mapping(uint256 => address) private _tokenApprovals;

    function mint(address to, uint256 tokenId) public {
        _owners[tokenId] = to;
    }

    function approve(address to, uint256 tokenId) public {
        _tokenApprovals[tokenId] = to;
    }

    function setApprovalForAll(address operator, bool approved) public {
        _operatorApprovals[msg.sender][operator] = approved;
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        return _owners[tokenId];
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        return _tokenApprovals[tokenId];
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        _owners[tokenId] = to;
    }
}

contract MockERC20 {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    function mint(address to, uint256 amount) public {
        _balances[to] += amount;
    }

    function approve(address spender, uint256 amount) public {
        _allowances[msg.sender][spender] = amount;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        _balances[from] -= amount;
        _balances[to] += amount;
        _allowances[from][msg.sender] -= amount;
        return true;
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        _balances[msg.sender] -= amount;
        _balances[to] += amount;
        return true;
    }
}

contract NFTLendFacetTest is Test, DiamondUtils, IDiamondCut {
    Diamond diamond;
    DiamondCutFacet dCutFacet;
    DiamondLoupeFacet dLoupe;
    OwnershipFacet ownerF;
    NFTLendFacet public nftLend;

    address public owner;
    address public lender;
    address public borrower;

    MockERC721 public mockNFT;
    MockERC20 public mockToken;

    uint256 constant NFT_ID = 1;
    uint256 constant LOAN_AMOUNT = 1 ether;
    uint256 constant MAX_REPAYMENT = 1.1 ether;
    uint32 constant LOAN_DURATION = 7 days;
    uint32 constant INTEREST_RATE = 1000; // 10%

    function deployDiamond() public {
        dCutFacet = new DiamondCutFacet();
        diamond = new Diamond(address(this), address(dCutFacet), "NFTLEND", "NTFLEND");
        dLoupe = new DiamondLoupeFacet();
        ownerF = new OwnershipFacet();

        FacetCut[] memory cut = new FacetCut[](4);

        cut[0] = (
            FacetCut({
                facetAddress: address(dLoupe),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("DiamondLoupeFacet")
            })
        );

        cut[1] = (
            FacetCut({
                facetAddress: address(ownerF),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("OwnershipFacet")
            })
        );
        cut[3] = (
            FacetCut({
                facetAddress: address(ownerF),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("NFTLendFacet")
            })
        );
        cut[2] = (
            FacetCut({
                facetAddress: address(ownerF),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("WhitelistedFacet")
            })
        );

        IDiamondCut(address(diamond)).diamondCut(cut, address(0x0), "");
        DiamondLoupeFacet(address(diamond)).facetAddresses();
    }

    function setUp() public {
        owner = address(this);
        lender = vm.addr(1);
        borrower = vm.addr(2);

        deployDiamond();
        nftLend = NFTLendFacet(address(diamond));

        mockNFT = new MockERC721();
        mockToken = new MockERC20();
        vm.prank(ownerF);
        // Whitelist the tokens
        WhitelistedFacet(address(diamond)).whitelistERC721(address(mockNFT), true);
        WhitelistedFacet(address(diamond)).whitelistERC20(address(mockToken), true);
        //vm.stopPrank();

        // Setup borrower with NFT
        mockNFT.mint(borrower, NFT_ID);

        // Setup lender with tokens
        mockToken.mint(lender, LOAN_AMOUNT * 2);
    }

    function test_ListingAndOfferFlow() public {
        // Create listing
        vm.startPrank(borrower);

        mockNFT.setApprovalForAll(address(nftLend), true);

        NFTLendFacet.ListingParams memory listingParams = NFTLendFacet.ListingParams({
            nftCollateralContract: address(mockNFT),
            nftCollateralId: NFT_ID,
            loanERC20Address: address(mockToken),
            loanPrincipalAmount: LOAN_AMOUNT,
            maximumRepaymentAmount: MAX_REPAYMENT,
            loanDuration: LOAN_DURATION,
            loanInterestRate: INTEREST_RATE
        });

        nftLend.ListNFTAsCollateral(listingParams);
        vm.stopPrank();

        // Create offer
        vm.startPrank(lender);
        mockToken.approve(address(nftLend), LOAN_AMOUNT);

        NFTLendFacet.OfferParams memory offerParams = NFTLendFacet.OfferParams({
            listingId: 0,
            loanPrincipalAmount: LOAN_AMOUNT,
            maximumRepaymentAmount: MAX_REPAYMENT,
            loanDuration: LOAN_DURATION,
            loanInterestRate: INTEREST_RATE
        });

        nftLend.MakeOfferForColleratalListing(offerParams);
        vm.stopPrank();

        // Accept offer
        vm.startPrank(borrower);
        nftLend.acceptLoanOffer(0);
        vm.stopPrank();
    }

    function test_RepayLoan() public {
        // Setup listing and offer first
        test_ListingAndOfferFlow();

        // Repay loan
        vm.startPrank(borrower);
        mockToken.mint(borrower, MAX_REPAYMENT); // Give borrower tokens to repay
        mockToken.approve(address(nftLend), MAX_REPAYMENT);
        nftLend.payBackLoan(0);
        vm.stopPrank();
    }

    function test_LoanLiquidation() public {
        // Setup listing and offer first
        test_ListingAndOfferFlow();

        // Fast forward past loan duration
        vm.warp(block.timestamp + LOAN_DURATION + 1);

        // Liquidate loan
        vm.startPrank(lender);
        nftLend.liquidateOverdueLoan(0);
        vm.stopPrank();
    }

    function diamondCut(FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata) external override {}
}
