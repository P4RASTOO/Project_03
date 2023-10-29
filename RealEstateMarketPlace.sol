// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./RealEstateTokenV3.sol";

contract RealEstateMarketplace {
    address public owner;
    RealEstateToken public realEstateToken;
    uint public propertyCount;

    enum PropertyStatus { Listed, Pending, Sold }

    struct Property {
        uint id;
        uint256 tokenId;
        string name;
        address payable owner;
        uint priceInEther;
        uint highestBidInEther;
        address payable highestBidder;
        PropertyStatus status;
        mapping(address => uint) bids;
    }

    struct Escrow {
        address payable buyer;
        uint amountInEther;
        bool funded;
        bool released;
    }

    mapping(uint => Property) public properties;
    mapping(uint => Escrow) public propertyEscrows;

    event PropertyListed(uint indexed id, string name, uint priceInEther);
    event PropertyUnlisted(uint indexed id, string name);
    event NewBid(uint indexed id, string name, uint amountInEther, address bidder);
    event PropertySold(uint indexed id, string name, address buyer, uint priceInEther);

    constructor(address _realEstateTokenAddress) {
        owner = msg.sender;
        realEstateToken = RealEstateToken(_realEstateTokenAddress);
    }

    function listProperty(uint256 _tokenId, string memory _name, uint _priceInEther) public {
        require(realEstateToken.ownerOf(_tokenId) == msg.sender, "Caller must be the owner of the property token.");

        propertyCount++;

        // 
        Property storage property = properties[propertyCount];
        property.id = propertyCount;
        property.tokenId = _tokenId;
        property.name = _name;
        property.owner = payable(msg.sender);
        property.priceInEther = _priceInEther;
        property.highestBidInEther = 0;
        property.highestBidder = payable(address(0));
        property.status = PropertyStatus.Listed;

        emit PropertyListed(propertyCount, _name, _priceInEther);
    }

    function unlistProperty(uint _id) public {
        Property storage property = properties[_id];
        require(property.status == PropertyStatus.Listed, "Property is not listed.");
        property.status = PropertyStatus.Pending;
        emit PropertyUnlisted(_id, property.name);
    }

    function placeBid(uint _id) public payable {
        Property storage property = properties[_id];
        require(property.status == PropertyStatus.Listed, "Property is not listed.");
        require(msg.value > property.highestBidInEther, "Bid must be higher than the current highest bid.");
        property.bids[msg.sender] = msg.value;
        property.highestBidInEther = msg.value;
        property.highestBidder = payable(msg.sender);
        emit NewBid(_id, property.name, msg.value, msg.sender);
    }

    function acceptBid(uint _id) public {
        Property storage property = properties[_id];
        require(property.status == PropertyStatus.Pending, "Property is not in a pending state.");
        require(property.owner == msg.sender, "Only the property owner can accept bids.");
        address payable highestBidder = property.highestBidder;
        uint amountInEther = property.highestBidInEther;

        // Create an escrow for the property
        propertyEscrows[_id] = Escrow(highestBidder, amountInEther, false, false);

        // Mark the property as sold
        property.status = PropertyStatus.Sold;

        emit PropertySold(_id, property.name, highestBidder, amountInEther);
    }

    function releaseEscrow(uint _id) public {
        Escrow storage escrow = propertyEscrows[_id];
        Property storage property = properties[_id];
        require(escrow.buyer == msg.sender, "Only the buyer can release escrow.");
        require(escrow.funded, "Escrow is not funded.");
        require(!escrow.released, "Escrow is already released.");

        // Transfer the RealEstateToken to the buyer
        realEstateToken.transferFrom(property.owner, escrow.buyer, property.tokenId);

        escrow.released = true;
        property.owner.transfer(escrow.amountInEther); // Transfer funds to the property owner
    }

    function fundEscrow(uint _id) public payable {
        Escrow storage escrow = propertyEscrows[_id];
        require(escrow.buyer == msg.sender, "Only the buyer can fund escrow.");
        require(!escrow.funded, "Escrow is already funded.");
        require(msg.value == escrow.amountInEther, "Funded amount does not match expected value.");

        escrow.funded = true;
    }
}
