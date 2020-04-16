pragma solidity >=0.6.0 <0.7.0;

contract ENS {
  event NewOwner(bytes32 indexed label, address owner);
  event Renew(bytes32 indexed label, uint256 expiresAt);
  event Transfer(bytes32 indexed label, address newOwner);

  // struct Record {
  //   bytes32 label;
  //   address owner;
  //   address buyer;
  //   uint expiryTimestamp;
  // }

  address private _owner;
  uint256 private _registrationAmount = 0.1 ether;
  uint256 private _registrationPeriod = 365 days;
  uint256 private _renewWithinPeriod = 182 days;

  mapping (address => bool) public _admins;

  mapping (bytes32 => address) private _lookupOwner;
  mapping (bytes32 => address) private _lookupBuyer;
  mapping (bytes32 => uint256) public _expiryTimes;

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
    require(msg.sender == _owner || _admins[msg.sender], "Sender is neither owner, nor an admin.");
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
   * @param _admin admin address
   * @param _isAdmin set/unset the admin priviledge
   */
  function setAdmin(address _admin, bool _isAdmin) public onlyOwner {
    _admins[_admin] = _isAdmin;
  }

  /**
   * @dev Returns if sender is an admin.
   */
  function isAdmin() public view returns (bool) {
    return _admins[msg.sender];
  }

  function setRegistrationAmount(uint256 value) external onlyOwnerOrAdmin {
    require(value >= 0 ether, "ENS: Registation amount has to be more than 0 EBK");
    _registrationAmount = value;
  }

  function getRegistrationAmount() external view returns (uint256) {
    return _registrationAmount;
  }

  function setRegistrationPeriod(uint256 period) external onlyOwnerOrAdmin {
    require(period >= 1 days, "ENS: Registation period can't be less than a day");
    _registrationPeriod = period;
  }

  function getRegistrationPeriod() external view returns (uint256) {
    return _registrationPeriod;
  }


  // End-user functions
  function register(bytes32 label, address owner) payable external {
    require(label.length > 0 && label.length <= 64, "ENS: Label length is not correct");
    require(owner != address(0), "ENS: Owner is the zero address");
    require(_expiryTimes[label] < now, "ENS: Label belongs to somebody else");
    require(msg.value >= _registrationAmount, "ENS: Not enough EBK for registering new label");
    require(msg.sender.balance >= _registrationAmount, "ENS: Not enough EBK for registering new label");

    _lookupOwner[label] = owner;
    _lookupBuyer[label] = msg.sender;
    _expiryTimes[label] = now + _registrationPeriod;

    // return back any excess amount
    if (msg.value > _registrationAmount) {
      msg.sender.transfer(msg.value - _registrationAmount);
    }

    emit NewOwner(label, owner);
  }

  function renew(bytes32 label) payable external {
    require(label.length > 0 && label.length <= 64, "ENS: Label length is not correct");
    require(_expiryTimes[label] <= now + _renewWithinPeriod, "ENS: Renew is allowed 6 months before expiration");
    require(msg.sender == _lookupOwner[label] || msg.sender == _lookupBuyer[label], "ENS: The label doesn't belong to you");
    require(msg.value >= _registrationAmount, "ENS: Not enough EBK for renewing the label");
    require(msg.sender.balance >= _registrationAmount, "ENS: Not enough EBK for renewing the label");

    _expiryTimes[label] = _expiryTimes[label] + _registrationPeriod;

    // return back any excess amount
    if (msg.value > _registrationAmount) {
      msg.sender.transfer(msg.value - _registrationAmount);
    }

    emit Renew(label, _expiryTimes[label]);
  }

  function transfer(bytes32 label, address newOwner) external {
    require(newOwner != address(0), "ENS: New owner is the zero address");
    require(_lookupOwner[label] != address(0), "ENS: Label doesn't exist");
    require(msg.sender == _lookupOwner[label] || msg.sender == _lookupBuyer[label], "ENS: The label doesn't belong to you");

    // TODO: remove this check? allowing the owner to transfer it, until someone boughts it
    require(_expiryTimes[label] >= now, "ENS: Label is expired");

    _lookupOwner[label] = newOwner;

    // TODO: if expired we might want to release the entries in _lookupOwner and _expiryTimes

    emit Transfer(label, newOwner);
  }

  function owner(bytes32 label) external view returns (address) {
    return _lookupOwner[label];
  }

  function expiresAt(bytes32 label) external view returns (uint) {
    return _expiryTimes[label];
  }

  /**
    * @dev Withdraws funds to the owner.
    */
  function fundsWithdraw(uint256 _amount) external payable onlyOwner {
    address(uint160(_owner)).transfer(_amount);
  }
}

