const Zdai = artifacts.require('Zdai')

contract('Zdai test', async (accounts) => {
  let instance

  before(async () => {
    instance = await Zdai.deployed();
  });
})
