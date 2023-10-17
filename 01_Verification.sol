// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PropertyVerification {
    struct Property {
        address owner;
        string deedHash;  // IPFS or any other storage hash
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

    event PropertyAdded(uint256 indexed propertyId, address indexed owner, string deedHash, bool exists);
    event PropertyVerified(uint256 indexed propertyId, bool verified);

    function addProperty(string memory deedHash) public onlyOwner {
        propertyCount++;
        properties[propertyCount] = Property({
            owner: msg.sender,
            deedHash: deedHash,
            exists: true
        });

        emit PropertyAdded(propertyCount, msg.sender, deedHash, true);
    }

    function verifyProperty(uint256 propertyId, bool verified) public onlyOwner {
        require(propertyId > 0 && propertyId <= propertyCount, "Invalid property ID");

        Property storage property = properties[propertyId];
        require(property.exists, "Property does not exist");

        // In a real-world scenario, you would integrate with external systems for verification.
        // This simplified example assumes that the owner can manually set the verification status.
        property.exists = verified;

        emit PropertyVerified(propertyId, verified);
    }
}
