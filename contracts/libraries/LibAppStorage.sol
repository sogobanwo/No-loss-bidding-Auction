// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library LibAppStorage {

  struct AuctionDetails {

        address auctionCreator;

        address hightestBidder;

        address previousBidder;

        uint256 duration;

        uint256 nftTokenId;

        uint256 auctionId;

        uint256 auctionCreatedTime;

        uint256 currentBid;

        uint256 minValidBid;

        address lastInteractor;

    }

    struct Layout {

        string name;

        string symbol;

        uint8 decimal;

        address owner; 

        uint256 totalSupply;

        address nftContractAddress;

        address auctionTokenFacetAddress;

        uint auctionCount;

        mapping(address => uint256) balances;

        mapping(address => mapping(address => uint256)) allowances;

        mapping (uint => AuctionDetails) auctions;

    }

    function layoutStorage() internal pure returns (Layout storage l) {
        assembly {
            l.slot := 0
        }
    }

    function _transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        Layout storage l = layoutStorage();
        uint256 balance = l.balances[msg.sender];
        require(balance > _amount, "Insufficient funds");
        l.balances[_from] = balance - _amount;
        l.balances[_to] += _amount;
    }


}