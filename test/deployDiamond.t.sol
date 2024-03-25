// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "forge-std/Test.sol";
import "../contracts/Diamond.sol";
import "../contracts/NFTContract.sol";
import "../contracts/interfaces/IDiamondCut.sol";
import "../contracts/facets/DiamondCutFacet.sol";
import "../contracts/facets/DiamondLoupeFacet.sol";
import "../contracts/facets/OwnershipFacet.sol";
import "../contracts/facets/AuctionTokenFacet.sol";
import "../contracts/facets/AuctionFacet.sol";
import {LibAppStorage} from "../contracts/libraries/LibAppStorage.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract DiamondDeployer is Test, IDiamondCut {
    //contract types of facets to be deployed
    Diamond diamond;
    DiamondCutFacet dCutFacet;
    DiamondLoupeFacet dLoupe;
    OwnershipFacet ownerF;
    AuctionFacet dAuctionFacet;
    AuctionTokenFacet dAuctionTokenFacet;
    NFTContract dNFTContract;

    address A = address(0xa);
    address B = address(0xb);
    address C = address(0xc);
    address D = address(0xd);
    address E = address(0xe);

    AuctionFacet boundAuction;

    AuctionTokenFacet boundAuctionToken;

    LibAppStorage.Layout internal l;

    function setUp() public {
        //deploy facets
        dAuctionFacet = new AuctionFacet();
        dAuctionTokenFacet = new AuctionTokenFacet();
        dNFTContract = new NFTContract();
        dCutFacet = new DiamondCutFacet();
        diamond = new Diamond(
            address(this),
            address(dCutFacet),
            100000,
            "Auction Token",
            "AUCT",
            18,
            address(dNFTContract),
            address(dAuctionTokenFacet)
        );
        dLoupe = new DiamondLoupeFacet();
        ownerF = new OwnershipFacet();

        //upgrade diamond with facets

        //build cut struct
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

        cut[2] = (
            FacetCut({
                facetAddress: address(dAuctionTokenFacet),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("AuctionTokenFacet")
            })
        );

        cut[3] = (
            FacetCut({
                facetAddress: address(dAuctionFacet),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("AuctionFacet")
            })
        );

        //upgrade diamond
        IDiamondCut(address(diamond)).diamondCut(cut, address(0x0), "");

        //call a function
        DiamondLoupeFacet(address(diamond)).facetAddresses();

        //make addresses
        A = mkaddr("Bidder A");
        B = mkaddr("Bidder B");
        C = mkaddr("Bidder C");
        D = mkaddr("Bidder D");
        E = mkaddr("Bidder E");

        //mint test tokens to bidding address
        AuctionTokenFacet(address(diamond)).mint(A, 1000);
        AuctionTokenFacet(address(diamond)).mint(B, 2000);
        AuctionTokenFacet(address(diamond)).mint(C, 3000);
        AuctionTokenFacet(address(diamond)).mint(D, 4000);
        AuctionTokenFacet(address(diamond)).mint(E, 5000);

        boundAuction = AuctionFacet(address(diamond));

        boundAuctionToken = AuctionTokenFacet(address(diamond));
    }

    // ERC20 TEST
    function testName() public view {
        string memory tokenName = boundAuctionToken.name();

        assertEq(tokenName, "Auction Token");
    }

    function testSymbol() public view {
        string memory symbol = boundAuctionToken.symbol();

        assertEq(symbol, "AUCT");
    }

    function testDecimal() public view {
        uint decimal = boundAuctionToken.decimals();

        assertEq(decimal, 18);
    }

    function testTotalSupply() public view {
        uint totalSupply = boundAuctionToken.totalSupply();

        assertEq(totalSupply, 115000);
    }

    function testbBalanceOf() public view {
        uint addressBalance = boundAuctionToken.balanceOf(A);

        assertEq(addressBalance, 1000);
    }

    function testTransferRevertWithYouDontHaveEnoughBalance() public {

        switchSigner(A);

        vm.expectRevert(bytes("You don't have enough balance"));

        boundAuctionToken.transfer(B, 1200);

    }

    function testTransfer() public {
        switchSigner(A);

        bool res= boundAuctionToken.transfer(B, 900);

        vm.assertEq(res, true);

    }

    

    // TESTING AUCTIONFACET

    // CREATE AUCTION FUNCTION
    function testCreateAuctionRevertWithZeroDurationNotAllowed() public {
        switchSigner(A);

        vm.expectRevert(
            abi.encodeWithSelector(
                AuctionFacet.ZERO_DURATION_NOT_ALLOWED.selector
            )
        );

        boundAuction.createAuction(0, 100, 1);
    }

    function testCreateAuctionRevertWithZeroPriceNotAllowed() public {
        switchSigner(A);

        vm.expectRevert(
            abi.encodeWithSelector(AuctionFacet.ZERO_PRICE_NOT_ALLOWED.selector)
        );

        boundAuction.createAuction(100, 0, 1);
    }

    function testCreateAuctionRevertWithNotOwnerOfNft() public {
        switchSigner(A);

        NFTContract(address(dNFTContract)).safeMint(A, 1);

        switchSigner(B);

        vm.expectRevert(
            abi.encodeWithSelector(AuctionFacet.NOT_OWNER_OF_NFT.selector)
        );

        boundAuction.createAuction(100, 100, 1);
    }

    function testCreateAuction() public {
        NFTContract(address(dNFTContract)).safeMint(A, 1);

        switchSigner(A);

        IERC721(address(dNFTContract)).approve(address(diamond), 1);

        boundAuction.createAuction(100, 100, 1);

        assertEq(boundAuction.getAuctionById(l.auctionCount + 1), A);
    }


    //MAKEBID FUNCTION 
    function testMakeBidToRevertWithCraetorCannotBid() public {
        NFTContract(address(dNFTContract)).safeMint(A, 1);

        switchSigner(A);

        IERC721(address(dNFTContract)).approve(address(diamond), 1);

        boundAuction.createAuction(100, 100, 1);

        vm.expectRevert(
            abi.encodeWithSelector(AuctionFacet.CREATOR_CANNOT_BID.selector)
        );

        boundAuction.makeBid(1, 150);
    }

    function testMakeBidToRevertWithAuctionIdNotFound() public {
        NFTContract(address(dNFTContract)).safeMint(A, 1);

        switchSigner(A);

        IERC721(address(dNFTContract)).approve(address(diamond), 1);

        boundAuction.createAuction(100, 100, 1);

        vm.expectRevert(
            abi.encodeWithSelector(AuctionFacet.AUCTION_ID_NOT_FOUND.selector)
        );

        boundAuction.makeBid(2, 100);
    }

    function testMakeBidToRevertWithAuctionEnded() public {
        NFTContract(address(dNFTContract)).safeMint(A, 1);

        switchSigner(A);

        IERC721(address(dNFTContract)).approve(address(diamond), 1);

        boundAuction.createAuction(100, 100, 1);

        switchSigner(B);

        vm.warp(102);

        vm.expectRevert(
            abi.encodeWithSelector(AuctionFacet.AUCTION_ENDED.selector)
        );

        boundAuction.makeBid(1, 100);
    }

    function testMakeBidToRevertWithBidLessThanExistingBid() public {
        NFTContract(address(dNFTContract)).safeMint(A, 1);

        switchSigner(A);

        IERC721(address(dNFTContract)).approve(address(diamond), 1);

        boundAuction.createAuction(100, 100, 1);

        switchSigner(B);

        vm.expectRevert(
            abi.encodeWithSelector(
                AuctionFacet.BID_LESS_THAN_EXISTING_BID.selector
            )
        );

        boundAuction.makeBid(1, 99);
    }

    function testMakeBidToRevertWithNotAValidBid() public {
        NFTContract(address(dNFTContract)).safeMint(A, 1);

        switchSigner(A);

        IERC721(address(dNFTContract)).approve(address(diamond), 1);

        boundAuction.createAuction(100, 100, 1);

        switchSigner(B);

        vm.expectRevert(
            abi.encodeWithSelector(AuctionFacet.NOT_A_VALID_BID.selector)
        );

        boundAuction.makeBid(1, 101);
    }

    function testMakeBidToRevertWithInsufficientBalance() public {
        NFTContract(address(dNFTContract)).safeMint(A, 1);

        switchSigner(A);

        IERC721(address(dNFTContract)).approve(address(diamond), 1);

        boundAuction.createAuction(100, 100, 1);

        switchSigner(B);

        vm.expectRevert(
            abi.encodeWithSelector(AuctionFacet.INSUFFICIENT_BALANCE.selector)
        );

        boundAuction.makeBid(1, 2001);
    }

    function testMakeBid() public {
        NFTContract(address(dNFTContract)).safeMint(A, 1);

        switchSigner(A);

        IERC721(address(dNFTContract)).approve(address(diamond), 1);

        boundAuction.createAuction(100, 100, 1);

        switchSigner(B);

        address highestBidder = boundAuction.makeBid(1, 150);

        vm.assertEq(highestBidder, B);
    }

    function testMultipleBid() public {
        NFTContract(address(dNFTContract)).safeMint(A, 1);

        switchSigner(A);

        IERC721(address(dNFTContract)).approve(address(diamond), 1);

        boundAuction.createAuction(100, 100, 1);

        switchSigner(B);

        boundAuction.makeBid(1, 150);

        switchSigner(C);

        address highestBidder = boundAuction.makeBid(1, 250);

        vm.assertEq(highestBidder, C);
    }

    // CLAIM AUCTION PRICE OF AUCTION
    function testClaimTokenEqOfAuctionItemToRevertWithAuctionInProgress()
        public
    {
        NFTContract(address(dNFTContract)).safeMint(A, 1);

        switchSigner(A);

        IERC721(address(dNFTContract)).approve(address(diamond), 1);

        boundAuction.createAuction(100, 100, 1);

        switchSigner(B);

        boundAuction.makeBid(1, 150);

        switchSigner(A);

        vm.expectRevert(
            abi.encodeWithSelector(AuctionFacet.AUCTION_IN_PROGRESS.selector)
        );

        boundAuction.claimTokenEqOfAuctionItem(1);
    }

    function testClaimTokenEqOfAuctionItemToRevertWithNotTokenOwner()
        public
    {
        NFTContract(address(dNFTContract)).safeMint(A, 1);

        switchSigner(A);

        IERC721(address(dNFTContract)).approve(address(diamond), 1);

        boundAuction.createAuction(100, 100, 1);

        switchSigner(B);

        boundAuction.makeBid(1, 150);

        switchSigner(C);

        vm.warp(200);

        vm.expectRevert(
            abi.encodeWithSelector(AuctionFacet.NOT_TOKEN_OWNER.selector)
        );

        boundAuction.claimTokenEqOfAuctionItem(1);
    }

     function testClaimWithoutBid()
        public
    {
        NFTContract(address(dNFTContract)).safeMint(A, 1);

        switchSigner(A);

        IERC721(address(dNFTContract)).approve(address(diamond), 1);

        boundAuction.createAuction(100, 100, 1);

        vm.warp(200);

        boundAuction.claimTokenEqOfAuctionItem(1);

        vm.assertEq(IERC721(address(dNFTContract)).ownerOf(1), A);

    }

    function testClaimWithBid()
        public
    {
        NFTContract(address(dNFTContract)).safeMint(A, 1);

        switchSigner(A);

        IERC721(address(dNFTContract)).approve(address(diamond), 1);

        boundAuction.createAuction(100, 100, 1);

        uint balanceBeforeClaim = l.balances[A];

        switchSigner(B);

        boundAuction.makeBid(1, 150);

        switchSigner(C);

        boundAuction.makeBid(1, 250);

        vm.warp(200);

        switchSigner(A);

        boundAuction.claimTokenEqOfAuctionItem(1);

        uint balanceAfterClaim = l.balances[A];

        uint _currentBid = l.auctions[1].currentBid;
        
        vm.assertEq(balanceAfterClaim, balanceBeforeClaim + (_currentBid * 90) / 100 );
    }

    // CLAIM NFT
    function testclaimNFTToRevertWithAuctionInProgress()
        public
    {
        NFTContract(address(dNFTContract)).safeMint(A, 1);

        switchSigner(A);

        IERC721(address(dNFTContract)).approve(address(diamond), 1);

        boundAuction.createAuction(100, 100, 1);

        switchSigner(B);

        boundAuction.makeBid(1, 150);

        switchSigner(B);

        vm.expectRevert(
            abi.encodeWithSelector(AuctionFacet.AUCTION_IN_PROGRESS.selector)
        );

        boundAuction.claimNFT(1);
    }

    function testclaimNFTToRevertWithNotHighestBidder()
        public
    {
        NFTContract(address(dNFTContract)).safeMint(A, 1);

        switchSigner(A);

        IERC721(address(dNFTContract)).approve(address(diamond), 1);

        boundAuction.createAuction(100, 100, 1);

        switchSigner(B);

        boundAuction.makeBid(1, 150);

        switchSigner(C);

        vm.warp(120);

        vm.expectRevert(
            abi.encodeWithSelector(AuctionFacet.NOT_HIGHEST_BIDDER.selector)
        );

            boundAuction.claimNFT(1);
    }

     function testclaimNFT()
        public
    {
        NFTContract(address(dNFTContract)).safeMint(A, 1);

        switchSigner(A);

        IERC721(address(dNFTContract)).approve(address(diamond), 1);

        boundAuction.createAuction(100, 100, 1);

        switchSigner(B);

        boundAuction.makeBid(1, 150);

        vm.warp(120);

        boundAuction.claimNFT(1);

        vm.assertEq(IERC721(address(dNFTContract)).ownerOf(1), B);
        
    }



    function generateSelectors(
        string memory _facetName
    ) internal returns (bytes4[] memory selectors) {
        string[] memory cmd = new string[](3);
        cmd[0] = "node";
        cmd[1] = "scripts/genSelectors.js";
        cmd[2] = _facetName;
        bytes memory res = vm.ffi(cmd);
        selectors = abi.decode(res, (bytes4[]));
    }

    function mkaddr(string memory name) public returns (address) {
        address addr = address(
            uint160(uint256(keccak256(abi.encodePacked(name))))
        );
        vm.label(addr, name);
        return addr;
    }

    function switchSigner(address _newSigner) public {
        address foundrySigner = 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;
        if (msg.sender == foundrySigner) {
            vm.startPrank(_newSigner);
        } else {
            vm.stopPrank();
            vm.startPrank(_newSigner);
        }
    }

    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {}
}
