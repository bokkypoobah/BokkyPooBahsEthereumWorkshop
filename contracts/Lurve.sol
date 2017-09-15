pragma solidity ^0.4.16;

// -----------------------------------------------------------------------------
// See https://github.com/bokkypoobah/EthVoter
//
// Version 0.91
// 
// The MIT Licence 2017
// -----------------------------------------------------------------------------
contract LurveOption {
    Lurve public lurve;
    uint public yesNo;
    
    // Constructor - save parameters
    function LurveOption(Lurve _lurve, uint _yesNo) {
        lurve = _lurve;
        yesNo = _yesNo;
    }
    
    // User sends a 0 or non-0 ETH transaction to the address
    function () payable {
        // Call the factory to register the votes
        lurve.registerLurve(msg.sender, yesNo);
        // Send back any non-0 ETH
        if (msg.value > 0) {
            msg.sender.transfer(msg.value);
        }
    }
}

contract Lurve {
    // Contract addresses
    LurveOption public lurveNo;
    LurveOption public lurveYes;
    
    // Count of No votes
    uint public noCount;
    // Count of Yes votes
    uint public yesCount;
    
    // Save addresses that have voted
    mapping(address => bool) public seen;
    
    event LurveIt(address indexed addr, uint yesNo);
    
    // Constructor - deploy the yes and no contracts
    function Lurve() {
        // Deploy a contract to an address that will register a '0' vote
        lurveNo = new LurveOption(this, 0);
        // Deploy a contract to an address that will register a '1' vote
        lurveYes = new LurveOption(this, 1);
    }
    
    function registerLurve(address addr, uint yesNo) {
        // Only allow lurveNo and lurveYes to call this function
        require(msg.sender == address(lurveNo) || msg.sender == address(lurveYes));
        // Only allow each address to vote once
        require(!seen[addr]);
        // Register the address that is voting
        seen[addr] = true;
        // Register the vote
        if (yesNo == 0) {
            noCount++;
        } else {
            yesCount++;
        }
        // Log the event
        LurveIt(addr, yesNo);
    }
}