// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {LibAppStorage} from "../libraries/LibAppStorage.sol";



contract AuctionFacet{

error ZERO_DURATION_NOT_ALLOWED();
error ZERO_PRICE_NOT_ALLOWED();
error NOT_OWNER_OF_NFT();
error AUCTION_ID_NOT_FOUND();
error BID_LESS_THAN_EXISTING_BID();
error AUCTION_ENDED();
error NOT_A_VALID_BID();
error INSUFFICIENT_BALANCE();
error NOT_TOKEN_OWNER();
error AUCTION_IN_PROGRESS();
error NOT_HIGHEST_BIDDER();
error CREATOR_CANNOT_BID();

    LibAppStorage.Layout internal l;

    function createAuction(uint _durationInSeconds, uint _startingBid, uint _nftTokenId) external{

        // checking user inputs
        if (_durationInSeconds == 0) revert ZERO_DURATION_NOT_ALLOWED();

        if (_startingBid == 0) revert ZERO_PRICE_NOT_ALLOWED();

        // checking for owner of the NFT
        if (IERC721(l.nftContractAddress).ownerOf(_nftTokenId) != msg.sender) revert NOT_OWNER_OF_NFT();

        // transferring NFT to Contract
        IERC721(l.nftContractAddress).transferFrom(msg.sender, address(this), _nftTokenId);

        uint _newAuctionCount = l.auctionCount + 1;

        LibAppStorage.AuctionDetails storage ad = l.auctions[_newAuctionCount];

        // setting auction details
        ad.auctionCreator = msg.sender;

        ad.auctionId = _newAuctionCount;

        ad.duration = _durationInSeconds;

        ad.currentBid = _startingBid;

        ad.nftTokenId = _nftTokenId;

        ad.currentBid = _startingBid;

        ad.minValidBid = 120 * ad.currentBid / 100;

        ad.auctionCreatedTime = block.timestamp;

        
        // incrementing auctionCount
        l.auctionCount++;

    }

    function makeBid(uint _auctionId, uint _bid) external returns (address highestBidder_) {

        if(l.auctions[_auctionId].auctionCreator == msg.sender) revert CREATOR_CANNOT_BID();


        if(l.auctions[_auctionId].auctionCreator == address(0)) revert AUCTION_ID_NOT_FOUND();

        LibAppStorage.AuctionDetails storage ad = l.auctions[_auctionId];

        uint _auctionEllapseTime = ad.auctionCreatedTime + ad.duration;

        if (block.timestamp > _auctionEllapseTime) revert AUCTION_ENDED();

        if(_bid < ad.currentBid) revert BID_LESS_THAN_EXISTING_BID();

        if(_bid < ad.minValidBid) revert NOT_A_VALID_BID();

        uint256 _bidderBalance = l.balances[msg.sender];

        if(_bidderBalance < _bid) revert INSUFFICIENT_BALANCE();

        LibAppStorage._transferFrom(msg.sender, address(this), _bid);

        ad.currentBid = _bid;

        if (ad.hightestBidder == address(0)){

            ad.hightestBidder = msg.sender;

            highestBidder_ = msg.sender;

            return highestBidder_;

        } else {

            ad.previousBidder = ad.hightestBidder;

            ad.hightestBidder = msg.sender;

            highestBidder_ = msg.sender;

            ad.lastInteractor = msg.sender;

            totalFeeDistribution(_bid, _auctionId);

            return highestBidder_;
        }


    }

    function totalFeeDistribution(uint _bid, uint _auctionId)  private {

        LibAppStorage.AuctionDetails storage ad = l.auctions[_auctionId];

        uint256 totalFee = (_bid * 10) / 100;

        uint256 teamWalletFee = (totalFee * 20) / 100;

        uint256 daoFee = (totalFee * 20) / 100;

        uint256 burnedFee = (totalFee * 20) / 100;

        uint256 previousBidderFee = (totalFee * 30) / 100;

        uint256 lastInteractorFee = (totalFee * 10) / 100;

        LibAppStorage._transferFrom(
            address(this),
            0xe902aC65D282829C7a0c42CAe165D3eE33482b9f,
            teamWalletFee
        );

        LibAppStorage._transferFrom(
            address(this),
            0xe902aC65D282829C7a0c42CAe165D3eE33482b9f,
            daoFee
        );

        LibAppStorage._transferFrom(
            address(this),
            address(0),
            burnedFee
        );

        LibAppStorage._transferFrom(
            address(this),
            ad.previousBidder,
            previousBidderFee + ad.currentBid
        );

        LibAppStorage._transferFrom(
            address(this),
            ad.hightestBidder,
            lastInteractorFee
        );
        
    }

    function claimTokenEqOfAuctionItem(uint _auctionId) external {
        LibAppStorage.AuctionDetails storage ad = l.auctions[_auctionId];

        uint _auctionEllapseTime = ad.auctionCreatedTime + ad.duration;

        if (block.timestamp < _auctionEllapseTime) revert AUCTION_IN_PROGRESS();

        if (ad.hightestBidder == address(0)) {

           IERC721(l.nftContractAddress).transferFrom(address(this), ad.auctionCreator, ad.nftTokenId);

        }else{

        if (ad.auctionCreator != msg.sender) revert NOT_TOKEN_OWNER();

        uint _nftValue = ad.currentBid * 90 /100;

        LibAppStorage._transferFrom(
            address(this),
            msg.sender,
            _nftValue
        );
        }

    }

    function claimNFT(uint _auctionId) external {
        LibAppStorage.AuctionDetails storage ad = l.auctions[_auctionId];

        uint _auctionEllapseTime = ad.auctionCreatedTime + ad.duration;

        if (block.timestamp < _auctionEllapseTime) revert AUCTION_IN_PROGRESS();

        if (ad.hightestBidder != msg.sender) revert NOT_HIGHEST_BIDDER();

        IERC721(l.nftContractAddress).transferFrom(address(this), ad.hightestBidder, ad.nftTokenId);
        
    }

    function getAuctionById(uint _auctionId) external view returns (address owner) {
        
        LibAppStorage.AuctionDetails storage ad = l.auctions[_auctionId];

        return ad.auctionCreator;

    }

}