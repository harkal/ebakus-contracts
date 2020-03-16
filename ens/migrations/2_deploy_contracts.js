const ENS = artifacts.require('ENS');

const ensContractJson = require('../build/contracts/ENS.json.js');

module.exports = async function(deployer, network, accounts) {
  await deployer.deploy(ENS);

  console.log('ENS address: ', ENS.address);
  console.warn('----------------');

  const instance = await ENS.deployed();

  /**
   * Store ABI for contract at Ebakus blockchain
   */
  const abiForSystemContractStoreAbiForAddress = [
    {
      type: 'function',
      name: 'storeAbiForAddress',
      inputs: [
        {
          name: 'address',
          type: 'address',
        },
        {
          name: 'abi',
          type: 'string',
        },
      ],
      outputs: [],
      stateMutability: 'nonpayable',
    },
  ];

  const systemContractAddress = '0x0000000000000000000000000000000000000101';
  const systemContract = new web3.eth.Contract( // eslint-disable-line no-undef
    abiForSystemContractStoreAbiForAddress,
    systemContractAddress
  );

  const cmd = systemContract.methods.storeAbiForAddress(
    instance.address,
    JSON.stringify(ensContractJson.abi)
  );

  const gas = await cmd.estimateGas();
  await cmd.send({ from: accounts[0], gas: gas });
};
