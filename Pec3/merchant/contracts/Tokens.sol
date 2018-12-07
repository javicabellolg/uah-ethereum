pragma solidity ^0.4.16;

import "./ConvertLib.sol";
import "./Owned.sol";
import "./usingOraclize.sol";

contract Tokens is Owned, usingOraclize {
    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    
    // The owner address
    address owner;

    // From oracle
    uint constant conversionDefault = 100;
    uint public price;

    // Public variables of the token
    string public name;
    string public symbol;
    uint256 public totalSupply;

     // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor(uint256 initialSupply, string tokenName, string tokenSymbol) public {
        OAR = OraclizeAddrResolverI(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475); // For testing only, remove in production
        owner = msg.sender;
        totalSupply = initialSupply;
        balanceOf[owner] = totalSupply;
        name = tokenName;
        symbol = tokenSymbol;
        price = conversionDefault;
        update(); // Set price (ETH/EUR) from Oracle
        emit Transfer(0x0, owner, initialSupply);
    }

     /**
     * Set token
     *
     * @param supply total supply of tokens
     * @param tokenName the name of the token
     * @param tokenSymbol the symbol of the token
     */
    function setToken(uint256 supply, string tokenName, string tokenSymbol) public onlyOwner {
        // Only it's possible if owner has got the total supply
        require (totalSupply == balanceOf[owner]);
        totalSupply = supply;
        balanceOf[owner] = totalSupply;
        name = tokenName;
        symbol = tokenSymbol;
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);
    }

     /**
     * 
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send 
     */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * Destory tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value); // Check if the sender has enough
        balanceOf[msg.sender] -= _value;           // Subtract from the sender
        totalSupply -= _value;                     // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }

    /**
    * Mint tokens for the owner only
    * 
    * @param mintedAmount the amount of new tokens the owner will receive
    */
    function mint(uint256 mintedAmount) public onlyOwner {
        balanceOf[owner] += mintedAmount;
        totalSupply += mintedAmount;
        emit Transfer(0x0, owner, mintedAmount);
    }
  
    function _buy(address buyer, uint _amount) internal {
        require(_amount >= 1); // Check if the value of the ether to transfer is at least one
        update(); // Update price (ETH/EUR) from Oracle to ConversionRate
        uint amount = ConvertLib.convert(_amount, price);
        _transfer(owner, buyer, amount);
    }

    /**
    * Buy tokens from contract by sending ether
    */
    function buy() public payable {
        _buy(msg.sender, msg.value/1000000000000000000);
    }

    /**
    * Anonymous function
     */
    function () public payable {
        _buy(msg.sender, msg.value/1000000000000000000);
    }

    function getName() public view returns (string) {
        return name;
    }

    function getSymbol() public view returns (string) {
        return symbol;
    }

    function totalSupply() public view returns (uint256) {
        return totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balanceOf[_owner];
    }

    function isOwner() public view returns (bool) {
        return (msg.sender == owner);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance/1000000000000000000;
    }

    function getPrice() public view returns (uint) {
        return price;
    }

    /** 
    * Oraclize (update & __callback)
    *
    * Update price form min-api.crytocompare.com through Oraclize 
    */
    function __callback(bytes32 _myid, string _result) public {
        require (msg.sender == oraclize_cbAddress());
        bytes memory tempEmptyStringTest = bytes(_result); // Uses memory
        if (tempEmptyStringTest.length > 0) //Just updates the price if receives data from Oracle, otherwise keeps the last value
            price = parseInt(_result);
    }  

    function update() public payable {
        oraclize_query("URL","json(https://min-api.cryptocompare.com/data/price?fsym=ETH&tsyms=EUR).EUR");
    }

}