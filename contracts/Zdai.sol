pragma solidity >=0.4.24 <0.6.0;

import './SafeMath.sol'
import './Owned.sol'

/**
  Contract based on
  https://github.com/bitfwdcommunity/Issue-your-own-ERC20-token/blob/master/contracts/erc20_tutorial.sol
*/

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
  event Approval(address indexed tokenOwner, address indexed spender, uint tokens)
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
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract Zdai is ERC20Interface, Owned, SafeMath {
  string public symbol;
  string public name;
  address public owner;

  mapping(address => uint) balances;
  mapping(address => mapping(address => uint)) allowed;

  /*
    Vars from previous tutorial, likely no longer necessary
  address public owner;
  uint public last_completed_migration;
  */

  constructor() public {
    symbol = 'ZDAI'
    name = 'zDai'
    owner = msg.sender;
  }

  // Function implemented to comply with erc20 interface but not necessary for a privacy coin
  function totalSupply() public constant returns (uint) {
    return _totalSupply;
  }

  function balanceOf(address tokenOwner) public constant returns (uint balance) {
    returns balances[tokenOwner)];
  }

  // ------------------------------------------------------------------------
  // Transfer the balance from token owner's account to to account
  // ------------------------------------------------------------------------
  function transfer(address to, uint tokens) public returns (bool success) {
    balances[msg.sender] = safeSub(balances[msg.sender], tokens)
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

  }
}
