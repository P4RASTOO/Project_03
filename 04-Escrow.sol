pragma solidity ^0.5.0;

contract RealEstateMarketplace {
    address public owner;
    uint public propertyCount;
    
    enum PropertyStatus { Listed, Pending, Sold }
    
    struct Property {
        uint id;
        string name;
        address owner;
        uint price;
        uint highestBid;
        address highestBidder;
        PropertyStatus status;
        mapping(address => uint) bids;
    }
    
    struct Escrow {
        address buyer;
        uint amount;
        bool funded;
        bool released;
    }
    
    mapping(uint => Property) public properties;
    mapping(uint => Escrow) public propertyEscrows;
    
    event PropertyListed(uint indexed id, string name, uint price);
    event PropertyUnlisted(uint indexed id, string name);
    event NewBid(uint indexed id, string name, uint amount, address bidder);
    event PropertySold(uint indexed id, string name, address buyer, uint price);
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }
    
    function listProperty(string memory _name, uint _price) public onlyOwner {
        propertyCount++;
        properties[propertyCount] = Property(propertyCount, _name, msg.sender, _price, 0, address(0), PropertyStatus.Listed);
        emit PropertyListed(propertyCount, _name, _price);
    }
    
    function unlistProperty(uint _id) public onlyOwner {
        Property storage property = properties[_id];
        require(property.status == PropertyStatus.Listed, "Property is not listed.");
        property.status = PropertyStatus.Pending;
        emit PropertyUnlisted(_id, property.name);
    }
    
    function placeBid(uint _id) public payable {
        Property storage property = properties[_id];
        require(property.status == PropertyStatus.Listed, "Property is not listed.");
        require(msg.value > property.highestBid, "Bid must be higher than the current highest bid.");
        property.bids[msg.sender] = msg.value;
        property.highestBid = msg.value;
        property.highestBidder = msg.sender;
        emit NewBid(_id, property.name, msg.value, msg.sender);
    }
    
    function acceptBid(uint _id) public onlyOwner {
        Property storage property = properties[_id];
        require(property.status == PropertyStatus.Pending, "Property is not in a pending state.");
        require(property.owner == msg.sender, "Only the owner can accept bids.");
        address highestBidder = property.highestBidder;
        uint amount = property.highestBid;
        
        // Create an escrow for the property
        propertyEscrows[_id] = Escrow(highestBidder, amount, false, false);
        
        // Mark the property as sold
        property.status = PropertyStatus.Sold;
        
        emit PropertySold(_id, property.name, highestBidder, amount);
    }
    
    function releaseEscrow(uint _id) public {
        Escrow storage escrow = propertyEscrows[_id];
        Property storage property = properties[_id];
        require(escrow.buyer == msg.sender, "Only the buyer can release escrow.");
        require(escrow.funded, "Escrow is not funded.");
        require(!escrow.released, "Escrow is already released.");
        escrow.released = true;
        property.owner = escrow.buyer;
    }
    
    function fundEscrow(uint _id) public payable {
        Escrow storage escrow = propertyEscrows[_id];
        require(escrow.buyer == msg.sender, "Only the buyer can fund escrow.");
        require(!escrow.funded, "Escrow is already funded.");
        require(msg.value == escrow.amount, "Funded amount must match the escrow amount.");
        escrow.funded = true;
    }
}
