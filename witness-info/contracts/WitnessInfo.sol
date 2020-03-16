pragma solidity >=0.6.0 <0.7.0;

contract WitnessInfo {
  event UpdatedWitnessInfo(address Id, string Info);

  mapping (address => string) private _abis;

  /**
   * @notice Set info for witness
   * @param account The witness account address
   * @param info A JSON string with info about the witness
   * @return iter Select iterator that has to be passed in EbakusDB.next(...)
   */
  function set(address account, string calldata info) external {
    require(msg.sender == account, "Only owner of address can store witness info.");
    // require(info.length <= 1048576, "Reached maximum size (1MB) for stored information");

    _abis[account] = info;

    emit UpdatedWitnessInfo(account, info);
  }

  /**
   * @notice Get info for witness
   * @param account The witness account address
   * @return info A JSON string with info about the witness
   */
  function get(address account) external view returns (string memory Info) {
    return _abis[account];
  }

  /**
   * @notice Remove stored info for witness
   * @param account The witness account address
   */
  function remove(address account) external {
    delete _abis[account];

    emit UpdatedWitnessInfo(account, "");
  }
}
