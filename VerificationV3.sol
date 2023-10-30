// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PropertyVerification {
    struct Property {
        uint256 id;
        string details;
        bool isVerified;
    }

    mapping(uint256 => Property) public properties;
    uint256 public propertyCount = 0;

    event PropertyAdded(uint256 propertyId, string details);
    event PropertyVerified(uint256 propertyId);

    function addProperty(string memory _details) public returns (uint) {
        propertyCount++;
        properties[propertyCount] = Property(propertyCount, _details, false);
        emit PropertyAdded(propertyCount, _details);
        return propertyCount;
}


    function verifyProperty(uint256 _propertyId) public returns (bool) {
        require(properties[_propertyId].id != 0, "Property does not exist");
        properties[_propertyId].isVerified = true;
        emit PropertyVerified(_propertyId);
        return true;
}

    function isPropertyVerified(uint256 _propertyId) public view returns (bool) {
        return properties[_propertyId].isVerified;
    }
}
