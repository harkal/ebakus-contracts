pragma solidity >=0.6.0 <0.7.0;


contract ENS {
    event NewOwner(bytes32 indexed label, address target);
    event Renew(bytes32 indexed label, uint256 expiresAt);
    event Transfer(bytes32 indexed label, address newTarget);

    address private _owner;
    uint256 private _registrationAmount = 0.1 ether;
    uint256 private _registrationPeriod = 365 days;
    uint256 private _renewWithinPeriod = 182 days;

    mapping(address => bool) public _admins;

    mapping(bytes32 => address) public _lookupTarget;
    mapping(bytes32 => address) public _lookupOwner;
    mapping(bytes32 => uint256) public _expiryTimes;

    /**
     * @dev Modifier that checks if sender is the contracts' owner.
     */
    modifier onlyOwner() {
        require(msg.sender == _owner, "Only owner can call this function");
        _;
    }

    /**
     * @dev Modifier that checks if sender is the contracts' owner or an administrator.
     */
    modifier onlyOwnerOrAdmin() {
        require(
            msg.sender == _owner || _admins[msg.sender],
            "Sender is neither owner, nor an admin."
        );
        _;
    }

    constructor() public {
        _owner = msg.sender;
    }

    fallback() external {
        revert("You are not allowed to call undefined functions");
    }

    // Admin functions

    /**
     * @dev Set/Unset an admin.
     *
     * @param admin admin address
     * @param isAdmin set/unset the admin priviledge
     */
    function setAdmin(address admin, bool isAdmin) public onlyOwner {
        _admins[admin] = isAdmin;
    }

    /**
     * @dev Returns if sender is an admin.
     */
    function isAdmin() public view returns (bool) {
        return _admins[msg.sender];
    }

    /**
     * @dev Set the registration amount for a label.
     *
     * @param value amount a label costs
     */
    function setRegistrationAmount(uint256 value) external onlyOwnerOrAdmin {
        require(
            value >= 0 ether,
            "ENS: Registation amount has to be more than 0 EBK"
        );
        _registrationAmount = value;
    }

    /**
     * @dev Returns the registration amount for a label.
     */
    function getRegistrationAmount() external view returns (uint256) {
        return _registrationAmount;
    }

    /**
     * @dev Set the registration period for a label.
     *
     * @param period period a label will be owned by the owner
     */
    function setRegistrationPeriod(uint256 period) external onlyOwnerOrAdmin {
        require(
            period >= 1 days,
            "ENS: Registation period can't be less than a day"
        );
        _registrationPeriod = period;
    }

    /**
     * @dev Returns the registration period for a label.
     */
    function getRegistrationPeriod() external view returns (uint256) {
        return _registrationPeriod;
    }

    // End-user functions

    /**
     * @dev Register a new label pointing to address.
     *
     * @param label label to be registered
     * @param target the address this label will point at
     */
    function register(bytes32 label, address target) external payable {
        require(target != address(0), "ENS: Target is the zero address");
        require(
            target != _owner || msg.sender == _owner,
            "ENS: Only the contract owner can set a Label for this contract"
        );
        require(
            _expiryTimes[label] < now,
            "ENS: Label belongs to somebody else"
        );
        require(
            msg.value >= _registrationAmount &&
                msg.sender.balance >= _registrationAmount,
            "ENS: Not enough EBK for registering new label"
        );

        _lookupTarget[label] = target;
        _lookupOwner[label] = msg.sender;
        _expiryTimes[label] = now + _registrationPeriod;

        // return back any excess amount
        if (msg.value > _registrationAmount) {
            msg.sender.transfer(msg.value - _registrationAmount);
        }

        emit NewOwner(label, target);
    }

    /**
     * @dev Renew a label expiry time.
     *
     * @param label label to be registered
     */
    function renew(bytes32 label) external payable {
        require(
            _expiryTimes[label] <= now + _renewWithinPeriod,
            "ENS: Renew is allowed 6 months before expiration"
        );
        require(
            msg.sender == _lookupTarget[label] ||
                msg.sender == _lookupOwner[label],
            "ENS: The label doesn't exist or doesn't belong to you"
        );
        require(
            msg.value >= _registrationAmount &&
                msg.sender.balance >= _registrationAmount,
            "ENS: Not enough EBK for renewing the label"
        );

        _expiryTimes[label] = _expiryTimes[label] + _registrationPeriod;

        // return back any excess amount
        if (msg.value > _registrationAmount) {
            msg.sender.transfer(msg.value - _registrationAmount);
        }

        emit Renew(label, _expiryTimes[label]);
    }

    /**
     * @dev Transfer a label to a new address.
     *
     * @param label label to be transfered
     * @param newTarget the new address this label will point at
     */
    function transfer(bytes32 label, address newTarget) external {
        require(newTarget != address(0), "ENS: New owner is the zero address");
        require(
            newTarget != _owner || msg.sender == _owner,
            "ENS: Only the contract owner can set a Label for this contract"
        );
        require(
            msg.sender == _lookupTarget[label] ||
                msg.sender == _lookupOwner[label],
            "ENS: The label doesn't exist or doesn't belong to you"
        );
        require(
            _expiryTimes[label] >= now,
            "ENS: Label is expired, please register it again"
        );

        _lookupTarget[label] = newTarget;

        emit Transfer(label, newTarget);
    }

    /**
     * @dev Get the address where a label points at.
     *
     * @param label label to get its address
     */
    function getAddress(bytes32 label) external view returns (address) {
        return _lookupTarget[label];
    }

    /**
     * @dev Get a label's expiry time.
     *
     * @return timestamp of the expiry time
     */
    function expiresAt(bytes32 label) external view returns (uint256) {
        return _expiryTimes[label];
    }

    /**
     * @dev Withdraws funds to the owner.
     */
    function fundsWithdraw(uint256 _amount) external payable onlyOwner {
        address(uint160(_owner)).transfer(_amount);
    }
}
