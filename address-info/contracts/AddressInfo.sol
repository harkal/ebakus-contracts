pragma solidity >=0.6.0 <0.7.0;


contract AddressInfo {
    event UpdatedAddressInfo(address indexed Id, string Info);

    mapping(address => string) private _abis;

    fallback() external {
        revert("You are not allowed to call undefined functions");
    }

    /**
     * @notice Set info for address
     * @param account The account address
     * @param info A JSON string with info about the address
     */
    function set(address account, string calldata info) external {
        require(
            msg.sender == account,
            "Only the owner of the address can store info."
        );
        require(
            bytes(info).length <= 1024,
            "Reached maximum size (1KB) of stored information"
        );

        _abis[account] = info;

        emit UpdatedAddressInfo(account, info);
    }

    /**
     * @notice Get info for address
     * @param account The account address
     * @return info A JSON string with info about the address
     */
    function get(address account) external view returns (string memory info) {
        return _abis[account];
    }

    /**
     * @notice Remove stored info for address
     * @param account The account address
     */
    function remove(address account) external {
        delete _abis[account];

        emit UpdatedAddressInfo(account, "");
    }
}
