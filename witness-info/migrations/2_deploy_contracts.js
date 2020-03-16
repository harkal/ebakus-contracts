const WitnessInfo = artifacts.require('WitnessInfo');

const witnessInfoContractJson = require('../build/contracts/WitnessInfo.json');

module.exports = async function(deployer, network, accounts) {
  await deployer.deploy(WitnessInfo);

  console.log('WitnessInfo address: ', WitnessInfo.address);
  console.warn('----------------');

  const instance = await WitnessInfo.deployed();

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
    JSON.stringify(witnessInfoContractJson.abi)
  );

  const gas = await cmd.estimateGas();
  await cmd.send({ from: accounts[0], gas: gas });

  // Test use for development
  if (network === 'development') {
    const testInfo = {
      name: 'Test',
    };

    const testInfoJSONString = JSON.stringify(testInfo)

    try {
      const receipt = await instance.set(
        accounts[0],
        testInfoJSONString
      );
      console.info(
        'WitnessInfo got inserted: %s, %s',
        receipt.logs[0].args.Id,
        receipt.logs[0].args.Info
      );
    } catch (err) {
      console.error('WitnessInfo insertion err: ', err);
    }

    try {
      const info = await instance.get(accounts[0]);

      if (info !== testInfoJSONString) {
        console.error('Info retrieved doesn\'t match with the info passed in set method');
      }

      console.info('Get info: %s', info);
    } catch (err) {
      console.error('Get info err: ', err);
    }

    try {
      const receipt = await instance.remove(accounts[0]);
      console.info('Info deleted: %s', receipt.logs[0].args.Id);
    } catch (err) {
      console.error('Info deletion err: ', err);
    }

    try {
      const info = await instance.get(accounts[0]);
      console.error(
        "Hmmm, we shouldn't get back any data as they have been removed",
        info
      );
    } catch (err) {
      console.info('Great! No record found!');
    }
  }
};
