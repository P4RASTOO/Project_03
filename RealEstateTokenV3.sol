// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./VerficationV3.sol"; 

contract RealEstateToken is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    PropertyVerification public propertyVerificationContract;

    enum PropertyType {RESIDENTIAL, COMMERCIAL, AGRICULTURAL, OTHER}
    enum BuildingType {DETACHED, SEMI_DETACHED, TOWNHOME, CONDO, OTHER}
    enum ParkingType {GARAGE, DRIVEWAY, STREET, NONE}

    struct RealEstate {
        string description;
        string location;
        uint256 price;
        string imageHash;
        PropertyType propertyType;
        BuildingType buildingType;
        uint8 storeys;
        uint256 landSize;
        uint256 propertyTaxes;
        ParkingType parkingType;
    }

    struct Transaction {
        address buyer;
        uint256 price;
        uint256 timestamp;
    }

    mapping(uint256 => RealEstate) public realEstates;
    mapping(uint256 => Transaction[]) public transactionHistory;

    event RealEstateCreated(
        uint256 indexed tokenId,
        string description,
        string location,
        uint256 price,
        string imageHash,
        PropertyType propertyType,
        BuildingType buildingType,
        uint8 storeys,
        uint256 landSize,
        uint256 propertyTaxes,
        ParkingType parkingType
    );

    event TransactionRecorded(
        uint256 indexed tokenId,
        address indexed buyer,
        uint256 price,
        uint256 timestamp
    );

    constructor(address _propertyVerificationAddress) 
        ERC721("RealEstateToken", "RET")
        Ownable(msg.sender) 
    {
        propertyVerificationContract = PropertyVerification(_propertyVerificationAddress);
    }

    function createOrDetailedRealEstateToken(
        uint256 _propertyId,
        string memory description,
        string memory location,
        uint256 price,
        string memory imageHash,
        PropertyType propertyType,
        BuildingType buildingType,
        uint8 storeys,
        uint256 landSize,
        uint256 propertyTaxes,
        ParkingType parkingType
    ) public returns (uint256) {
        if (bytes(description).length == 0) {
            require(propertyVerificationContract.isPropertyVerified(_propertyId), "Property must be verified first");
            _mint(msg.sender, _propertyId);
            return _propertyId;
        } else {
            _tokenIdCounter.increment();
            uint256 newTokenId = _tokenIdCounter.current();
            _mint(msg.sender, newTokenId);
            realEstates[newTokenId] = RealEstate(
                description,
                location,
                price,
                imageHash,
                propertyType,
                buildingType,
                storeys,
                landSize,
                propertyTaxes,
                parkingType
            );

            emit RealEstateCreated(
                newTokenId,
                description,
                location,
                price,
                imageHash,
                propertyType,
                buildingType,
                storeys,
                landSize,
                propertyTaxes,
                parkingType
            );

            return newTokenId;
        }
    }

    function viewRealEstate(uint256 tokenId) public view returns (RealEstate memory) {
        return realEstates[tokenId];
    }

    function recordTransaction(uint256 tokenId, address buyer, uint256 price) internal {
        transactionHistory[tokenId].push(Transaction({
            buyer: buyer,
            price: price,
            timestamp: block.timestamp
        }));

        emit TransactionRecorded(tokenId, buyer, price, block.timestamp);
    }

    function getTransactionHistory(uint256 tokenId) public view returns (Transaction[] memory) {
        return transactionHistory[tokenId];
    }

    function transferWithRecord(uint256 tokenId, address to, uint256 price) public {
        transferFrom(msg.sender, to, tokenId);
        recordTransaction(tokenId, to, price);
    }
}
