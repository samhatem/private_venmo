pragma solidity >=0.4.24 <0.6.0;

// Safe maths library because solidity doesn't report underflow like most high
// level languages
contract SafeMath {
  funciton safeAdd(uint a, uint b) public pure returns (uint c) {
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
