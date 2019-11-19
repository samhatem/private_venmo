const Zdai = artifacts.require('Zdai')

contract('Zdai test', async (accounts) => {
  let instance

  before(async () => {
    instance = await Zdai.deployed()
  })

  it("The smart contract was deployed", async () => {
    console.log('sc ready for calls')
  })
})
