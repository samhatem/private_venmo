pragma solidity >=0.4.24 <0.6.0;

// ----------------------------------------------------------------------------
// 'zDai' token contract
//
// Deployed to : 0xB26B5a7C4b35efA73E2343a086AF55b459CebAB0
// Symbol      : ZDAI
// Name        : zDai
//
// Contract initially based on:
// https://github.com/bitfwdcommunity/Issue-your-own-ERC20-token/blob/master/contracts/erc20_tutorial.sol
// The MIT Licence.
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// Math library to ensure overflow does not cause errors
// ----------------------------------------------------------------------------
contract SafeMath {
  function safeAdd(uint a, uint b) public pure returns (uint c) {
    c = a + b;
    require (c >= a);
  }

  function safeSub(uint a, uint b) public pure returns (uint c) {
    require(b <= a);
    c = a - b;
  }

  function safeMul(uint a, uint b) public pure returns (uint c) {
    c = a * b;
    require(a == 0 || c / b == b);
  }

  function safeDiv(uint a, uint b) public pure returns (uint c) {
    require(b > 0);
    c = a / b;
  }
}

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
  function totalSupply() public constant returns (uint);
  function balanceOf(address tokenOwner) public constant returns (uint balance);
  function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
  function transfer(address to, uint tokens) public returns (bool success);
  function transferFrom(address from, address to, uint tokens) public returns (bool success);

  event Transfer(address indexed from, address indexed to, uint tokens);
  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
  function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

// ----------------------------------------------------------------------------
// Owned Contract
// ----------------------------------------------------------------------------
contract Owned {
  address public owner;
  address public newOwner;

  event OwnershipTransferred(address indexed _from, address indexed _to);

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address _newOwner) public onlyOwner {
      newOwner = _newOwner;
  }

  function acceptOwnership() public {
      require(msg.sender == newOwner);
      emit OwnershipTransferred(owner, newOwner);
      owner = newOwner;
      newOwner = address(0);
  }
}

// ----------------------------------------------------------------------------
// Compound ABI
// ----------------------------------------------------------------------------
contract CToken {}

contract CErc20 is CToken {

  function mint(uint mintAmount) external returns (uint) {}

  function redeem(uint redeemTokens) external returns (uint) {}

  function exchangeRateCurrent() returns (uint) {}
}

contract PriceOracleProxy {
  function getUnderlyingPrice(CToken cToken) public view returns (uint) {}
}

// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract Zdai is ERC20Interface, Owned, SafeMath {
  string public symbol;
  string public name;
  uint public _totalSupply;
  uint8 public decimals;

  CErc20 _compound;
  PriceOracleProxy _oracle;
  address _owner;

  // tracks cdai of the address
  mapping(address => uint) balances;

  // tracks amount of dai deposited
  mapping(address => uint) daiMinted;

  mapping(address => mapping(address => uint)) allowed;

  event Deposit(address minter, uint mintAmount);
  event Withdrawal(address redeemer, uint redeemAmount);

  constructor() public {
    symbol = 'ZDAI';
    name = 'zDai';
    _owner = msg.sender;
    decimals = 18;
    _compound = CErc20(0x5d3a536e4d6dbd6114cc1ead35777bab948e3643);
    _oracle = PriceOracleProxy(0x1d8aedc9e924730dd3f9641cdb4d1b92b848b4bd);

    // call compound to approve dai
  }

  // If the compound address changes, or we want to change the interest smart
  // contract the owner of the sc can call this function. Also has the potential
  // to be used in scams
  function setAddress(address _t) external {
    assert(msg.sender == _owner);
    _compound = CErc20(_t);
  }

  function mint(uint mintAmount) external returns (bool success) {
    uint status = _compound.mint(mintAmount);
    require(status == 0, 'Compound mint failure');

    uint rate = _compound.exchangeRateCurrent();
    uint cdaiAmount = safeDiv(mintAmount, rate);
    balances[msg.sender] = safeAdd(balances[msg.sender], cdaiAmount);
    daiMinted[msg.sender] = safeAdd(balances[msg.sender], mintAmount);
    emit Deposit(msg.sender, mintAmount);
    _totalSupply = safeAdd(_totalSupply, mintAmount);
    success = true;
  }

  function redeem(uint redeemTokens) external returns (bool success) {
    require(balances[msg.sender] >= redeemTokens);
    uint status = _compound.redeem(redeemTokens);
    require(status == 0, 'Compound redeem failure');

    // TODO: CORRECTLY CALCULATE INTEREST EARNED ON DAI
    uint rate = _compound.exchangeRateCurrent();
    uint daiWithdrawn = safeMul(rate, redeemTokens);
    uint interest = safeSub(daiWithdrawn, daiMinted[msg.sender]);
    balances[msg.sender] = safeSub(balances[msg.sender], redeemTokens);
    emit Withdrawal(msg.sender, redeemTokens);
    // withdraw the excess dai to the owner account
    _totalSupply = safeSub(_totalSupply, redeemTokens);
    success = true;
  }

  // Function implemented to comply with erc20 interface but not necessary for a privacy coin
  function totalSupply() public constant returns (uint) {
    return _totalSupply;
  }

  function balanceOf(address tokenOwner) public constant returns (uint balance) {
    return balances[tokenOwner];
  }

  // ------------------------------------------------------------------------
  // Transfer the balance from token owner's account to to account
  // ------------------------------------------------------------------------
  function transfer(address to, uint tokens) public returns (bool success) {
    balances[msg.sender] = safeSub(balances[msg.sender], tokens);
    balances[to] = safeAdd(balances[to], tokens);
    emit Transfer(msg.sender, to, tokens);
    return true;
  }

  // ------------------------------------------------------------------------
  // Transfer the balance from token owner's account to to account
  // ------------------------------------------------------------------------
  function approve(address spender, uint tokens) public returns (bool success) {
    allowed[msg.sender][spender] = tokens;
    emit Approval(msg.sender, spender, tokens);
    return true;
  }

  // ------------------------------------------------------------------------
  // Transfer tokens from the from account to the to account
  // ------------------------------------------------------------------------
  function transferFrom(address from, address to, uint tokens) public returns (bool success) {
    balances[from] = safeSub(balances[from], tokens);
    allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
    balances[to] = safeAdd(balances[to], tokens);
    emit Transfer(from, to, tokens);
    return true;
  }

  // ------------------------------------------------------------------------
  // Returns the amount of tokens approved by the owner that can be
  // transferred to the spender's account
  // ------------------------------------------------------------------------
  function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
    return allowed[tokenOwner][spender];
  }

  function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
    allowed[msg.sender][spender] = tokens;
    emit Approval(msg.sender, spender, tokens);
    ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
    return true;
  }

  // ------------------------------------------------------------------------
  // Accept ETH and send to me, to be used in future scams and if someone accidentally
  // sends the smart contract ETH.
  // ------------------------------------------------------------------------
  function () public payable {
    _owner.transfer(msg.value);
  }
}
