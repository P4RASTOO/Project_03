// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PropertyVerification {
    struct Property {
        address owner;
        string houseDetails;
        bool exists;
        bool verified;
    }

    mapping(uint256 => Property) private _properties;
    uint256 public propertyCount = 0;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    event PropertyAdded(uint256 indexed propertyId, address indexed owner, string houseDetails, bool exists);
    event PropertyVerified(uint256 indexed propertyId);

    function addProperty(string memory houseDetails) public onlyOwner returns (uint256) {
        propertyCount++;
        _properties[propertyCount] = Property({
            owner: msg.sender,
            houseDetails: houseDetails,
            exists: true,
            verified: false
        });

        emit PropertyAdded(propertyCount, msg.sender, houseDetails, true);
        return propertyCount;
    }

    function verifyProperty(uint256 propertyId) public onlyOwner {
        require(propertyId <= propertyCount && propertyId > 0, "Invalid property ID");
        require(_properties[propertyId].exists, "Property does not exist");

        _properties[propertyId].verified = true;

        emit PropertyVerified(propertyId);
    }

    function getProperty(uint256 propertyId) public view returns (Property memory) {
        return _properties[propertyId];
    }
}



// Create the RealEstateToken
contract RealEstateToken is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    PropertyVerification public propertyVerification;

    constructor(address _propertyVerification) ERC721("RealEstateToken", "RET") Ownable(_propertyVerification) {
        propertyVerification = PropertyVerification(_propertyVerification);
    }

    enum PropertyType {RESIDENTIAL, COMMERCIAL, AGRICULTURAL, OTHER}
    enum BuildingType {DETACHED, SEMI_DETACHED, ROW_HOUSE, CONDO, OTHER}
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

    mapping(uint256 => RealEstate) public realEstates;

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

    function createRealEstateToken(
        uint256 propertyId,
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
        PropertyVerification.Property memory property = propertyVerification.getProperty(propertyId);
        require(property.exists, "Property does not exist");


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
