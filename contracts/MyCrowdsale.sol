pragma solidity ^0.4.16;

// ----------------------------------------------------------------------------
// MYT 'MyToken' crowdsale/token contract sample contract.
//
// NOTE: Use at your own risk
//
// Deployed to : 
// Symbol      : MYT
// Name        : MyToken
// Total supply: Unlimited
// Decimals    : 18
//
// Enjoy.
//
// (c) BokkyPooBah / Bok Consulting Pty Ltd 2017. The MIT Licence.
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/issues/20
// ----------------------------------------------------------------------------
contract ERC20Interface {
    uint public totalSupply;
    function balanceOf(address account) public constant returns (uint balance);
    function transfer(address to, uint value) public returns (bool success);
    function transferFrom(address from, address to, uint value)
        public returns (bool success);
    function approve(address spender, uint value) public returns (bool success);
    function allowance(address owner, address spender) public constant
        returns (uint remaining);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {

    // ------------------------------------------------------------------------
    // Current owner, and proposed new owner
    // ------------------------------------------------------------------------
    address public owner;
    address public newOwner;

    // ------------------------------------------------------------------------
    // Constructor - assign creator as the owner
    // ------------------------------------------------------------------------
    function Owned() public {
        owner = msg.sender;
    }


    // ------------------------------------------------------------------------
    // Modifier to mark that a function can only be executed by the owner
    // ------------------------------------------------------------------------
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }


    // ------------------------------------------------------------------------
    // Owner can initiate transfer of contract to a new owner
    // ------------------------------------------------------------------------
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }


    // ------------------------------------------------------------------------
    // New owner has to accept transfer of contract
    // ------------------------------------------------------------------------
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
    }
    event OwnershipTransferred(address indexed from, address indexed to);
}


// ----------------------------------------------------------------------------
// Safe maths, borrowed from OpenZeppelin
// ----------------------------------------------------------------------------
library SafeMath {

    // ------------------------------------------------------------------------
    // Add a number to another number, checking for overflows
    // ------------------------------------------------------------------------
    function add(uint a, uint b) pure internal returns (uint) {
        uint c = a + b;
        assert(c >= a && c >= b);
        return c;
    }

    // ------------------------------------------------------------------------
    // Subtract a number from another number, checking for underflows
    // ------------------------------------------------------------------------
    function sub(uint a, uint b) pure internal returns (uint) {
        assert(b <= a);
        return a - b;
    }

    // ------------------------------------------------------------------------
    // Multiply two numbers
    // ------------------------------------------------------------------------
    function mul(uint a, uint b) pure internal returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    // ------------------------------------------------------------------------
    // Multiply one number by another number
    // ------------------------------------------------------------------------
    function div(uint a, uint b) pure internal returns (uint) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
}


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals
// ----------------------------------------------------------------------------
contract MyToken is ERC20Interface, Owned {
    using SafeMath for uint;

    // ------------------------------------------------------------------------
    // Token parameters
    // ------------------------------------------------------------------------
    string public constant symbol = "MYT";
    string public constant name = "MyToken";
    uint8 public constant decimals = 18;
    uint public totalSupply = 0;

    uint public constant DECIMALSFACTOR = 10**uint(decimals);

    // ------------------------------------------------------------------------
    // Administrators can mint until sealed
    // ------------------------------------------------------------------------
    // bool public sealed;

    // ------------------------------------------------------------------------
    // Balances for each account
    // ------------------------------------------------------------------------
    mapping(address => uint) balances;

    // ------------------------------------------------------------------------
    // Owner of account approves the transfer tokens to another account
    // ------------------------------------------------------------------------
    mapping(address => mapping (address => uint)) allowed;


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    function MyToken() public Owned() {
    }


    // ------------------------------------------------------------------------
    // Get the account balance of another account with address account
    // ------------------------------------------------------------------------
    function balanceOf(address account) public constant returns (uint balance) {
        return balances[account];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from owner's account to another account
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Allow spender to withdraw from your account, multiple times, up to the
    // value tokens. If this function is called again it overwrites the
    // current allowance with value.
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Spender of tokens transfer an tokens of tokens from the token owner's
    // balance to another account. The owner of the tokens must already
    // have approve(...)-d this transfer
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public
        returns (bool success)
    {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(from, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Returns the number of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address owner, address spender ) public 
        constant returns (uint remaining)
    {
        return allowed[owner][spender];
    }


    // ------------------------------------------------------------------------
    // Mint coins for a single account
    // ------------------------------------------------------------------------
    function mint(address to, uint tokens) internal {
        require(to != 0x0 && tokens != 0);
        balances[to] = balances[to].add(tokens);
        totalSupply = totalSupply.add(tokens);
        Transfer(0x0, to, tokens);
    }


    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens)
      public onlyOwner returns (bool success)
    {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}


contract MyCrowdsale is MyToken {

    // ------------------------------------------------------------------------
    // Start Date
    //   > new Date('2017-10-03T08:00:00+11:00').getTime()/1000
    //   1506978000
    //   > new Date(1506978000 * 1000).toString()
    //   "Tue, 03 Oct 2017 08:00:00 AEDT"
    // End Date
    //   Start Date + 2 weeks
    // ------------------------------------------------------------------------
    uint public constant START_DATE = 1506978000;
    uint public constant END_DATE = START_DATE + 2 weeks;

    uint public constant ETH_HARD_CAP = 1 ether;

    uint public constant tokensPerKEther = 1000000; 

    uint public ethersRaised;

    bool public finalised;
    bool public transferable;

    address public wallet; 


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    function MyCrowdsale() public MyToken() {
        wallet = msg.sender;
    }


    // ------------------------------------------------------------------------
    // Add precommitment funding token balance and ether cost before the
    // crowdsale commences
    // ------------------------------------------------------------------------
    function addPrecommitment(address participant, uint tokens, uint ethers) public onlyOwner {
        require(block.timestamp < START_DATE);
        require(tokens > 0);
        mint(participant, tokens);
        ethersRaised = ethersRaised.add(ethers);
        PrecommitmentAdded(participant, tokens, ethers);
    }
    event PrecommitmentAdded(address indexed participant, uint tokens, uint ethers);


    // ------------------------------------------------------------------------
    // Fallback function to receive ETH contributions
    // ------------------------------------------------------------------------
    function() public payable {
        proxyPayment(msg.sender);
    }


    // ------------------------------------------------------------------------
    // Receive ETH contributions
    // ------------------------------------------------------------------------
    function proxyPayment(address contributor) public payable {
        require(block.timestamp >= START_DATE && block.timestamp <= END_DATE);
        require(contributor != 0x0);
        require(msg.value > 0);

        ethersRaised = ethersRaised.add(msg.value);
        require(ethersRaised <= ETH_HARD_CAP);

        uint tokens = msg.value.mul(tokensPerKEther).div(1000);

        mint(contributor, tokens);
        TokensBought(contributor, msg.value, tokens);
    }
    event TokensBought(address indexed contributor, uint ethers, uint tokens);


    // ------------------------------------------------------------------------
    // Finalise crowdsale, 20% of tokens for myself
    // ------------------------------------------------------------------------
    function finalise() public onlyOwner {
        require(!finalised);
        require(block.timestamp > END_DATE || ethersRaised == ETH_HARD_CAP);
        finalised = true;
        transferable = true;
        uint myTokens = totalSupply.mul(20).div(80);
        mint(owner, myTokens);
    }


    // ------------------------------------------------------------------------
    // transfer tokens, only transferable after the crowdsale is finalised
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
        require(transferable);
        return super.transfer(to, tokens);
    }


    // ------------------------------------------------------------------------
    // transferFrom tokens, only transferable after the crowdsale is finalised
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public
        returns (bool success)
    {
        require(transferable);
        return super.transferFrom(from, to, tokens);
    }
}
