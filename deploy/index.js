import { ethers } from 'ethers'

import { wallet } from './wallet.js'
import { abi, bin } from './contract.js'

const deployContract = async () => {
  const factory = new ethers.ContractFactory(abi, bin, wallet)

  const contract = await factory.deploy()
  const address = await contract.getAddress()

  console.log('Address will be', address)
  console.log('Please wait...')

  await contract.waitForDeployment()

  console.log('Successfully deployed!')
}

deployContract().catch(error => console.log('error:', error))
