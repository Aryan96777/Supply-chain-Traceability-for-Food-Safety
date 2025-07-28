// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Project {
    // Structure to store product information
    struct Product {
        uint256 id;
        string name;
        string origin;
        uint256 creationTime;
        address currentOwner;
        string[] checkpoints;
        uint256[] timestamps;
        bool isActive;
    }
    
    // Mapping to store products by their ID
    mapping(uint256 => Product) public products;
    
    // Counter for generating unique product IDs
    uint256 private nextProductId = 1;
    
    // Events for tracking activities
    event ProductRegistered(uint256 indexed productId, string name, string origin, address owner);
    event ProductTracked(uint256 indexed productId, string checkpoint, uint256 timestamp);
    event OwnershipTransferred(uint256 indexed productId, address indexed from, address indexed to);
    
    // Modifier to check if product exists
    modifier productExists(uint256 _productId) {
        require(products[_productId].isActive, "Product does not exist or is inactive");
        _;
    }
    
    // Modifier to check if caller is the current owner
    modifier onlyProductOwner(uint256 _productId) {
        require(products[_productId].currentOwner == msg.sender, "Only product owner can perform this action");
        _;
    }
    
    /**
     * @dev Registers a new product in the supply chain
     * @param _name Name of the product
     * @param _origin Origin location of the product
     * @return productId The unique ID of the registered product
     */
    function registerProduct(string memory _name, string memory _origin) public returns (uint256) {
        require(bytes(_name).length > 0, "Product name cannot be empty");
        require(bytes(_origin).length > 0, "Origin cannot be empty");
        
        uint256 productId = nextProductId;
        nextProductId++;
        
        Product storage newProduct = products[productId];
        newProduct.id = productId;
        newProduct.name = _name;
        newProduct.origin = _origin;
        newProduct.creationTime = block.timestamp;
        newProduct.currentOwner = msg.sender;
        newProduct.isActive = true;
        
        // Add initial checkpoint
        newProduct.checkpoints.push(_origin);
        newProduct.timestamps.push(block.timestamp);
        
        emit ProductRegistered(productId, _name, _origin, msg.sender);
        return productId;
    }
    
    /**
     * @dev Tracks product movement through the supply chain
     * @param _productId ID of the product to track
     * @param _checkpoint Description of the current checkpoint/location
     */
    function trackProduct(uint256 _productId, string memory _checkpoint) 
        public 
        productExists(_productId) 
        onlyProductOwner(_productId) 
    {
        require(bytes(_checkpoint).length > 0, "Checkpoint description cannot be empty");
        
        Product storage product = products[_productId];
        product.checkpoints.push(_checkpoint);
        product.timestamps.push(block.timestamp);
        
        emit ProductTracked(_productId, _checkpoint, block.timestamp);
    }
    
    /**
     * @dev Transfers ownership of a product to a new owner
     * @param _productId ID of the product
     * @param _newOwner Address of the new owner
     */
    function transferOwnership(uint256 _productId, address _newOwner) 
        public 
        productExists(_productId) 
        onlyProductOwner(_productId) 
    {
        require(_newOwner != address(0), "New owner cannot be zero address");
        require(_newOwner != msg.sender, "Cannot transfer to yourself");
        
        address previousOwner = products[_productId].currentOwner;
        products[_productId].currentOwner = _newOwner;
        
        emit OwnershipTransferred(_productId, previousOwner, _newOwner);
    }
    
    /**
     * @dev Gets complete product information and tracking history
     * @param _productId ID of the product
     * @return id Product ID
     * @return name Product name
     * @return origin Product origin location
     * @return creationTime Timestamp when product was created
     * @return currentOwner Current owner address
     * @return checkpoints Array of checkpoint locations
     * @return timestamps Array of checkpoint timestamps
     */
    function getProductInfo(uint256 _productId) 
        public 
        view 
        productExists(_productId) 
        returns (
            uint256 id,
            string memory name,
            string memory origin,
            uint256 creationTime,
            address currentOwner,
            string[] memory checkpoints,
            uint256[] memory timestamps
        ) 
    {
        Product storage product = products[_productId];
        return (
            product.id,
            product.name,
            product.origin,
            product.creationTime,
            product.currentOwner,
            product.checkpoints,
            product.timestamps
        );
    }
    
    /**
     * @dev Gets the current status of a product
     * @param _productId ID of the product
     * @return currentLocation Current location of the product
     * @return lastUpdated Timestamp of last update
     */
    function getCurrentStatus(uint256 _productId) 
        public 
        view 
        productExists(_productId) 
        returns (string memory currentLocation, uint256 lastUpdated) 
    {
        Product storage product = products[_productId];
        uint256 checkpointCount = product.checkpoints.length;
        
        if (checkpointCount > 0) {
            return (
                product.checkpoints[checkpointCount - 1],
                product.timestamps[checkpointCount - 1]
            );
        }
        
        return ("", 0);
    }
    
    /**
     * @dev Gets total number of registered products
     * @return totalCount Total count of products
     */
    function getTotalProducts() public view returns (uint256) {
        return nextProductId - 1;
    }
}
