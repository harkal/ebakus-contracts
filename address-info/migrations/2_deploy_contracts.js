const AddressInfo = artifacts.require('AddressInfo');

const addressInfoContractJson = require('../build/contracts/AddressInfo.json');

module.exports = async function (deployer, network, accounts) {
  await deployer.deploy(AddressInfo);

  console.log('AddressInfo address: ', AddressInfo.address);
  console.warn('----------------');

  const instance = await AddressInfo.deployed();

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
    JSON.stringify(addressInfoContractJson.abi)
  );

  const gas = await cmd.estimateGas();
  await cmd.send({ from: accounts[0], gas: gas });

  // Test use for development
  if (network === 'development') {
    const testInfo = {
      name: 'Ebakus',
      logo: 'https://www.ebakus.com/img/logo.png',
      subtitle: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit',
      description:
        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aenean lectus nunc, laoreet et nulla sit amet, congue varius lacus. Morbi in tincidunt est. In blandit massa odio, nec porttitor nisi porta non. Fusce quis enim eleifend, dignissim risus luctus, facilisis arcu. Donec accumsan nulla nec metus pellentesque, quis ornare purus suscipit. Aliquam interdum turpis ut nunc pharetra, sed dictum mi porta.',
      website: 'https://www.ebakus.com',
      ens: 'ebakus',
    };

    const testInfoJSONString = JSON.stringify(testInfo);

    try {
      const receipt = await instance.set(accounts[0], testInfoJSONString);
      console.info(
        'AddressInfo got inserted: %s, %s',
        receipt.logs[0].args.Id,
        receipt.logs[0].args.Info
      );
    } catch (err) {
      console.error('AddressInfo insertion err: ', err);
    }

    try {
      const info = await instance.get(accounts[0]);

      if (info !== testInfoJSONString) {
        console.error(
          "Info retrieved doesn't match with the info passed in set method"
        );
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
