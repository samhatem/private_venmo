pragma solidity ^0.4.25;

import "./ERC20Interface.sol";
import "./verifier.sol";

contract CToken {}

contract CErc20 is CToken {
  function mint(uint mintAmount) external returns (uint) {}

  function redeem(uint redeemTokens) external returns (uint) {}

  function exchangeRateCurrent() external returns (uint) {}
}

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


contract SecretNote is Verifier, SafeMath {

  ERC20 internal DAI_TOKEN_ADDRESS = ERC20(0xB5E5D0F8C0cbA267CD3D7035d6AdC8eBA7Df7Cdd);
  CErc20 internal COMPOUND_ADDRESS = CErc20(0x2B536482a01E620eE111747F8334B395a42A555E);

  constructor() {}

  enum State {Invalid, Created, Spent}
  mapping(bytes32 => State) public notes; // mapping of hash of the note to state
  string[] public allNotes;
  bytes32[] public allHashedNotes;

  function getNotesLength() public view returns(uint) {
    return allNotes.length;
  }

  // function createNote(ERC20 srcToken, uint srcQty) public {
  //   // Check that the token transferFrom has succeeded
  //   require(srcToken.transferFrom(msg.sender, address(this), srcQty));

  //   // swap srcToken tokens with dai
  //   uint swappedAmount = kyberSwap(srcToken, srcQty);

  //   // create secret note @todo nonce
  //   bytes32 noteHash = sha256(bytes32(msg.sender), bytes32(swappedAmount));
  //   notes[noteHash] = State.Created;
  //   allNotes.push(noteHash);
  //   emit NoteCreated(noteHash);
  // }

  // function kyberSwap(ERC20 srcToken, uint srcQty) internal returns(uint) {
  //   // Get the minimum conversion rate
  //   uint minConversionRate;
  //   (minConversionRate,) = kyberProxy.getExpectedRate(srcToken, DAI_TOKEN_ADDRESS, srcQty);

  //   kyberProxy.trade(
  //     srcToken,
  //     srcQty,
  //     DAI_TOKEN_ADDRESS, // dest,
  //     address(this), // destAddress address to send tokens to
  //     1000000000, // maxDestAmount??
  //     minConversionRate, // check
  //     0
  //   );

  //   return srcQty * minConversionRate;
  // }

  event debug(bytes32 m, bytes32 m2);
  function createNoteDummy(address owner, uint amount, string encryptedNote) public {
    bytes32 note = sha256(bytes32(owner), bytes32(amount));
    createNote(note, encryptedNote);
    emit debug(bytes32(msg.sender), bytes32(amount));
  }

  function depositDai(uint amount) external {
    COMPOUND_ADDRESS.mint(amount)
  }

  function claimNote(uint amount) public {
    bytes32 note = sha256(bytes32(msg.sender), bytes32(amount));
    require(
      notes[note] == State.Created,
      'note doesnt exist'
    );
    notes[note] = State.Spent;

    uint status = COMPOUND_ADDRESS.redeem(amount);
    uint rate = COMPOUND_ADDRESS.exchangeRateCurrent();
    uint daiAmount = safeMul(amount, rate);
    require(status == 0, 'Compound redeem failure');
    require(
      DAI_TOKEN_ADDRESS.transfer(msg.sender, daiAmount * (10 ** 18)),
      'daiToken transfer failed'
    );
    emit Claim(msg.sender, daiAmount * (10 ** 18));
  }
  event Claim(address to, uint daiAmount);

  function transferNote(
    uint[2] a,
    uint[2] a_p,
    uint[2][2] b,
    uint[2] b_p,
    uint[2] c,
    uint[2] c_p,
    uint[2] h,
    uint[2] k,
    uint[7] input,
    string encryptedNote1,
    string encryptedNote2
  ) {
    require(
      verifyTx(a, a_p, b, b_p, c, c_p, h, k, input),
      'Invalid zk proof'
    );

    bytes32 spendingNote = calcNoteHash(input[0], input[1]);
    // emit debug(spendingNote, bytes32(0));
    require(
      notes[spendingNote] == State.Created,
      'spendingNote doesnt exist'
    );

    notes[spendingNote] = State.Spent;
    bytes32 newNote1 = calcNoteHash(input[2], input[3]);
    createNote(newNote1, encryptedNote1);
    bytes32 newNote2 = calcNoteHash(input[4], input[5]);
    createNote(newNote2, encryptedNote2);
  }

  event NoteCreated(bytes32 noteId, uint index);
  function createNote(bytes32 note, string encryptedNote) internal {
    notes[note] = State.Created;
    allNotes.push(encryptedNote);
    allHashedNotes.push(note);
    emit NoteCreated(note, allNotes.length - 1);
  }

  event d2(bytes16 a, bytes16 b);
  function calcNoteHash(uint _a, uint _b) internal returns(bytes32 note) {
    bytes16 a = bytes16(_a);
    bytes16 b = bytes16(_b);
    // emit d2(a, b);
    bytes memory _note = new bytes(32);

    for (uint i = 0; i < 16; i++) {
      _note[i] = a[i];
      _note[16 + i] = b[i];
    }
    note = bytesToBytes32(_note, 0);
  }

  function bytesToBytes32(bytes b, uint offset) internal pure returns (bytes32) {
    bytes32 out;
    for (uint i = 0; i < 32; i++) {
      out |= bytes32(b[offset + i] & 0xFF) >> (i * 8);
    }
    return out;
  }
}
