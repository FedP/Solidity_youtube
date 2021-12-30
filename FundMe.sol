// SPDX-Licence-Identifier: MIT

pragma solidity ^0.6.6;

// Brownie can't download from the npm package but can download from GitHub
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
// A library is similar to contracts, but their purpose is that they are deployed
// only once at a specific address and their code is reused.
import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";


// This contract should be able to accept some type of payment
contract FundMe{

    // The directive using A for B; can be used to attach library functions from the library A
    // to any type B in the context of a contract.
    using SafeMathChainlink for uint256;

    // Keep track with who sent us some value with a mapping
    mapping(address => uint256) public addressToAmountFunded;

    // We want now to update the balances of all the contracts but we can't loop 
    // through a mapping. So we create an array.
    address[] public funders;

    address public owner;
    // You want to allow only certain address to withdraw and so you need to initiaize owners
    // To do so you need a constructor that is called in the instance the contract is deployed
    constructor() public {
        // This will be executed when we deploy the contract
        // The owner is the one who deploy the contract
        owner = msg.sender;
    }

    // Function that can accept payments
    // payable means that this function can be used to pay for things
    function fund() public payable {

        // Let's set a threshold of 50$ => I want it in wei so I multiply 
        // it by 10 to the power of 18
        uint256 minimumUSD = 50 * 10 ** 18;

        require(getConversionRate(msg.value) >= minimumUSD, "The amount sent do not match the minimum set");

        // Let's keep track of all the people that sent us money
        // msg.sender is the sender of the function call
        // msg.value is the value sent
        addressToAmountFunded[msg.sender] += msg.value;

        // Add the funder address in the funders array;
        funders.push(msg.sender);
    }

    // I want to set a minimum value of money to send
    // But I need to get the conversion ETH => USD (ORACLE like Chainlink)

    // Anytime you want to interact with an already deployed smart contract you 
    // will need an ABI

    // Interfaces compile down to an ABI

    // Always need an ABI to interact with a contract

    function getVersion() public view returns(uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        // This is a contract call to another contract from our contract using the interface
        return priceFeed.version(); // 403600181020"
    }

    function getPrice() public view returns(uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        // This is a contract call to another contract from our contract using the interface
        (,int256 answer,,,) = priceFeed.latestRoundData();
        return uint256(answer * 10000000000);
    }

    // function that converts the ETH to USD equivalent
    function getConversionRate(uint256 ethAmount) public view returns(uint256) {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUsd;
    }

    // What if we have to use this "require" line multiple times?
    // We can use modifiers
    // Modifiers are used to change the behaviour of a function in a declarative way
    modifier onlyOwner {
        require(msg.sender == owner, "You can't withdraw balance because you're not the owner!");
        _;
    }

    function withdraw() payable onlyOwner public{

        // We require that only the owner can withdraw balance
        // require(msg.sender == owner, "You can't withdraw balance because you're not the owner!");

        // "this" is the contract you are currently in
        //  "address(this)" is the address of the contract
        // "address(this).balance" and this is the balance
        // "msg.sender" is whoever call the function
        msg.sender.transfer(address(this).balance);

        // Reset all the funders balance
        for (uint256 i = 0; i < funders.length; i++) {
            address funder = funders[i];
            addressToAmountFunded[funder] = 0;
        }

        // Initialize a new empty array
        funders = new address[](0);

    }
}
