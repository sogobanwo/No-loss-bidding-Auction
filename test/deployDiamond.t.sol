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


contract DiamondDeployer is Test, IDiamondCut {
    //contract types of facets to be deployed
    Diamond diamond;
    DiamondCutFacet dCutFacet;
    DiamondLoupeFacet dLoupe;
    OwnershipFacet ownerF;
    AuctionFacet dAuctionFacet;
    AuctionTokenFacet dAuctionTokenFacet;
    NFTContract dNFTContract;

    function setUp() public {
        //deploy facets
        dAuctionFacet = new AuctionFacet();
        dAuctionTokenFacet = new AuctionTokenFacet();
        dNFTContract = new NFTContract(msg.sender);
        dCutFacet = new DiamondCutFacet();
        diamond = new Diamond(address(this), address(dCutFacet), 100000, "Auction Token", "AUCT", 18, address(dNFTContract), address(dAuctionTokenFacet));
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
    }

    // ERC20 TEST
    function testName() public view {
        AuctionTokenFacet st = AuctionTokenFacet(address(diamond));

        string memory tokenName = st.name();

        assertEq(tokenName, "Auction Token");
    }

    function testSymbol() public view {
        AuctionTokenFacet st = AuctionTokenFacet(address(diamond));

        string memory symbol = st.symbol();

        assertEq(symbol, "AUCT");
    }

    function testDecimal() public view {
        AuctionTokenFacet st = AuctionTokenFacet(address(diamond));

        uint decimal = st.decimals();

        assertEq(decimal, 18);
    }

    function testTotalSupply() public view {
        AuctionTokenFacet st = AuctionTokenFacet(address(diamond));

        uint totalSupply = st.totalSupply();

        assertEq(totalSupply, 100000);
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

    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {}
}
