import { ethers } from 'ethers'

// Replace with your private key
const privateKey =
  '0x0000000000000000000000000000000000000000000000000000000000000000'

// Replace with your RPC URL
const provider = new ethers
  .JsonRpcProvider('https://api.avax-test.network/ext/bc/C/rpc')

export const wallet = new ethers.Wallet(privateKey, provider)
