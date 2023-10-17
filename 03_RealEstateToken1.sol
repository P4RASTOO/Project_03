// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RealEstateToken is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    enum PropertyType {RESIDENTIAL, COMMERCIAL, AGRICULTURAL, OTHER}
    enum BuildingType {DETACHED, SEMI_DETACHED, ROW_HOUSE, CONDO, OTHER}
    enum ParkingType {GARAGE, DRIVEWAY, STREET, NONE}

    // Define a struct to hold information about the real estate.
    struct RealEstate {
        string description;
        string location;
        uint256 price;
        string imageHash; // This will store the IPFS hash of the image.
        PropertyType propertyType;
        BuildingType buildingType;
        uint8 storeys;
        uint256 landSize; // In square feet/meters (or as per your measurement unit)
        uint256 propertyTaxes;
        ParkingType parkingType;
    }

    mapping(uint256 => RealEstate) public realEstates;

    constructor() ERC721("RealEstateToken", "RET") Ownable(msg.sender) {} // Fixed the Ownable constructor here

    // Function to create a new real estate token.
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
        return newTokenId;
    }

    // Function to view details of a real estate token.
    function viewRealEstate(uint256 tokenId) public view returns (RealEstate memory) {
        return realEstates[tokenId];
    }
}
