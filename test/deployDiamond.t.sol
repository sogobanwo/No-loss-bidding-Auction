// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// import "../contracts/interfaces/IDiamondCut.sol";
// import "../contracts/facets/DiamondCutFacet.sol";
// import "../contracts/facets/DiamondLoupeFacet.sol";
// import "../contracts/facets/OwnershipFacet.sol";
// import "forge-std/Test.sol";
// import "../contracts/Diamond.sol";
// import "../contracts/RewardToken.sol";
// import "../contracts/facets/StakeTokenFacet.sol";
// import "../contracts/facets/StakingContract.sol";


// contract DiamondDeployer is Test, IDiamondCut {
//     //contract types of facets to be deployed
//     Diamond diamond;
//     DiamondCutFacet dCutFacet;
//     DiamondLoupeFacet dLoupe;
//     OwnershipFacet ownerF;
//     StakeTokenFacet dStakeTokenFacet;
//     StakingContract dStakingContract;
//     RewardToken dRewardToken;

//     function setUp() public {
//         //deploy facets
//         dStakeTokenFacet = new StakeTokenFacet();
//         dStakingContract = new StakingContract();
//         dRewardToken = new RewardToken("Reward Token", "RT", 18, 100000);
//         dCutFacet = new DiamondCutFacet();
//         diamond = new Diamond(address(this), address(dCutFacet), 100000, "Stake Token", "ST", 18, address(dRewardToken), address(dStakeTokenFacet) );
//         dLoupe = new DiamondLoupeFacet();
//         ownerF = new OwnershipFacet();

//         //upgrade diamond with facets

//         //build cut struct
//         FacetCut[] memory cut = new FacetCut[](4);

//         cut[0] = (
//             FacetCut({
//                 facetAddress: address(dLoupe),
//                 action: FacetCutAction.Add,
//                 functionSelectors: generateSelectors("DiamondLoupeFacet")
//             })
//         );

//         cut[1] = (
//             FacetCut({
//                 facetAddress: address(ownerF),
//                 action: FacetCutAction.Add,
//                 functionSelectors: generateSelectors("OwnershipFacet")
//             })
//         );

//           cut[2] = (
//             FacetCut({
//                 facetAddress: address(dStakeTokenFacet),
//                 action: FacetCutAction.Add,
//                 functionSelectors: generateSelectors("StakeTokenFacet")
//             })
//         );

//           cut[3] = (
//             FacetCut({
//                 facetAddress: address(dStakingContract),
//                 action: FacetCutAction.Add,
//                 functionSelectors: generateSelectors("StakingContract")
//             })
//         );

       

//         //upgrade diamond
//         IDiamondCut(address(diamond)).diamondCut(cut, address(0x0), "");

//         //call a function
//         DiamondLoupeFacet(address(diamond)).facetAddresses();
//     }
//      function testStaking() public returns(address){
//             StakeTokenFacet st = StakeTokenFacet(address(diamond));

//             StakingContract sc = StakingContract(address(diamond));

//             st.balanceOf(address(this));

//             st.balanceOf(address(msg.sender));

//             st.mint(address(this), 10000);

//             st.transfer(address(this), 1000);

//             assertEq(sc.getAmountStaked(address(this)), 1000);

//             return address(this);
//         }

//         function testName() public {
//             StakeTokenFacet st = StakeTokenFacet(address(diamond));

//             string memory tokenName = st.name();

//             assertEq(tokenName, "Stake Token");
//         }

//     function generateSelectors(
//         string memory _facetName
//     ) internal returns (bytes4[] memory selectors) {
//         string[] memory cmd = new string[](3);
//         cmd[0] = "node";
//         cmd[1] = "scripts/genSelectors.js";
//         cmd[2] = _facetName;
//         bytes memory res = vm.ffi(cmd);
//         selectors = abi.decode(res, (bytes4[]));
//     }

//     function diamondCut(
//         FacetCut[] calldata _diamondCut,
//         address _init,
//         bytes calldata _calldata
//     ) external override {}
// }
