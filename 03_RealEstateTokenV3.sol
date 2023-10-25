// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 *@title RealEstateToken
 *@dev This contract implements tokenization of real estate properties based on ERC721.
 */
contract RealEstateToken is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // Define various types of property attributes.
    enum PropertyType {RESIDENTIAL, COMMERCIAL, AGRICULTURAL, OTHER}
    enum BuildingType {DETACHED, SEMI_DETACHED, ROW_HOUSE, CONDO, OTHER}
    enum ParkingType {GARAGE, DRIVEWAY, STREET, NONE}

    /**
     * @dev Struct to store detailed information about a real estate property.
     */
    struct RealEstate {
        string description; // Description of the property
        string location;    // Location of the property
        uint256 price;      // Price of the property
        string imageHash;   // IPFS hash of the property image
        PropertyType propertyType;
        BuildingType buildingType;
        uint8 storeys;      // Number of floors
        uint256 landSize;   // Size of the land
        uint256 propertyTaxes; // Amount of property taxes
        ParkingType parkingType;
    }

    /**
     * @dev Struct to store detailed information about each transaction.
     */
    struct Transaction {
        address buyer;      // Address of the buyer
        uint256 price;      // Transaction price
        uint256 timestamp;  // Timestamp of the transaction
    }

    // Mapping to store real estate properties against their token IDs.
    mapping(uint256 => RealEstate) public realEstates;

    // Mapping to store transaction history for each token.
    mapping(uint256 => Transaction[]) public transactionHistory;

    // Event to notify when a new real estate token is created.
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

    // Event to notify when a transaction is recorded.
    event TransactionRecorded(
        uint256 indexed tokenId,
        address indexed buyer,
        uint256 price,
        uint256 timestamp
    );

    /**
     * @dev Constructor to set the name and symbol of the token.
     */
    constructor() ERC721("RealEstateToken", "RET") Ownable(msg.sender) {}

    /**
     * @dev Function to create a new real estate token. Only the owner can call this.
     * @return The ID of the newly created token.
     */
    function createRealEstateToken(
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
    ) public onlyOwner returns (uint256) {
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

    /**
     * @dev Function to view the details of a real estate token.
     * @return The detailed information of the real estate associated with the given token ID.
     */
    function viewRealEstate(uint256 tokenId) public view returns (RealEstate memory) {
        return realEstates[tokenId];
    }

    /**
     * @dev Internal function to record a transaction for a token.
     */
    function recordTransaction(uint256 tokenId, address buyer, uint256 price) internal {
        transactionHistory[tokenId].push(Transaction({
            buyer: buyer,
            price: price,
            timestamp: block.timestamp
        }));

        emit TransactionRecorded(tokenId, buyer, price, block.timestamp);
    }

    /**
     * @dev Function to retrieve the transaction history for a token.
     * @return The array of transactions associated with the given token ID.
     */
    function getTransactionHistory(uint256 tokenId) public view returns (Transaction[] memory) {
        return transactionHistory[tokenId];
    }

    /**
     * @dev Function to transfer a token and record the transaction.
     */
    function transferWithRecord(uint256 tokenId, address to, uint256 price) public {
        transferFrom(msg.sender, to, tokenId);
        recordTransaction(tokenId, to, price);
    }
}
