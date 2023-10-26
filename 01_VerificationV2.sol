// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PropertyVerification {
    struct Property {
        address owner;
        string HouseDetails;  // IPFS or other storage hash
        bool exists;
    }

    mapping(uint256 => Property) public properties;
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

    // Adds a property and returns its ID
    function addProperty(string memory houseDetails) public onlyOwner returns (uint256) {
        propertyCount++;
        properties[propertyCount] = Property({
            owner: msg.sender,
            HouseDetails: houseDetails,
            exists: true
        });

        emit PropertyAdded(propertyCount, msg.sender, houseDetails, true);

        return propertyCount;  // Returns the newly added property's ID
    }

    // Verifies a property and returns 1 for successful verification, 0 otherwise
    function verifyProperty(uint256 propertyId) public onlyOwner returns (uint256) {
    if (propertyId <= 0 || propertyId > propertyCount) {
        return 0;  // Invalid property ID
    }

    Property storage property = properties[propertyId];
    if (!property.exists) {
        return 0;  // Property does not exist
    }

    emit PropertyVerified(propertyId);
    
    return 1;  // Verification successful
}

}


