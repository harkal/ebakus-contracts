const namehash = require('eth-ens-namehash');

const ENS = artifacts.require('ENS');

const ensContractJson = require('../build/contracts/ENS.json');

module.exports = async function(deployer, network, accounts) {
  await deployer.deploy(ENS);

  console.log('ENS address: ', ENS.address);
  console.log('----------------');

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

  // await instance.register(namehash.hash('ens'), ENS.address, {
  //   from: accounts[0],
  //   value: web3.utils.toWei('0.1', 'ether'),
  // });

  // Test use for development
  if (network === 'development') {

    console.log('\n----------------\nDeployment tests\n----------------\n');

    const testLabel = namehash.hash('ebakus-ens.ebk');
    const testOwner = accounts[0];
    const testTarget1 = '0x8F10D3A6283672EcfAeea0377d460BdEd489EC44';
    const testTarget2 = '0x6FDFD8Bf1A5310243519dC2e7B90916f6b4534ab';

    try {
      const registrationAmount = await instance.getRegistrationAmount();
      console.log('RegistrationAmount: %d', registrationAmount)

      const receipt = await instance.register(testLabel, testTarget1, {
        from: testOwner,
        value: registrationAmount,
        // value: web3.utils.toWei('0.2', 'ether'), // test excess amount
      });
      console.info(
        'Label got inserted: %s, %s',
        receipt.logs[0].args.label,
        receipt.logs[0].args.target
      );
    } catch (err) {
      console.error('Label insertion err: ', err.message);
    }

    try {
      const address = await instance.getAddress(testLabel);

      if (address !== testTarget1) {
        console.error(
          "Address retrieved doesn't match with the address registered"
        );
      }

      console.info('Address: %s', address);
    } catch (err) {
      console.error('Get address err: ', err.message);
    }

    try {
      const expiresAt = await instance.expiresAt(testLabel);

      console.info('ExpiresAt: %d', expiresAt);
    } catch (err) {
      console.error('Get expiresAt err: ', err.message);
    }

    try {
      const receipt = await instance.transfer(testLabel, testTarget2);
      console.info(
        'Label got transfered: %s, %s',
        receipt.logs[0].args.label,
        receipt.logs[0].args.newTarget
      );
    } catch (err) {
      console.error('Label transfer err: ', err.message);
    }

    try {
      await instance.renew(testLabel);
      console.error('Label has been renewed while it shouldn\'t');

    } catch (err) {
      console.info('Label failed to be renewed, as it should happen.', err.message);
    }
  }
};
