# Have Fund

## Build

```shell
npx solc --include-path node_modules --base-path . src/FILE_NAME --output-dir dist --bin --abi
```

## Сценарий заведения фонда в сеть

```javascript
import { readFileSync } from 'fs'

import { ethers } from 'ethers'

import { ownerPrivateKey } from './secret.js'

// Вставить адрес USDT
const DOLLAR_ADDRESS = '0x944F24Ff5FdD9F3974b2da90302c54184BbCFd4A'

const tokenBin = readFileSync('Token.bin', 'utf8')
const tokenAbi = JSON.parse(readFileSync('Token.abi', 'utf8'))
const fundBin = readFileSync('Fund.bin', 'utf8')
const fundAbi = JSON.parse(readFileSync('Fund.abi', 'utf8'))

// Вставить https://api.avax.network/ext/bc/C/rpc
const provider = new ethers
  .JsonRpcProvider('https://api.avax-test.network/ext/bc/C/rpc')

const wallet = new ethers.Wallet(ownerPrivateKey, provider)

// --- СТАРТ ---
// 1. Развернуть токен Фонда
const tokenFactory = new ethers.ContractFactory(tokenAbi, tokenBin, wallet)

tokenFactory
  .deploy('Fund Token 2', 'FUN2', '')
  .then(contract => contract.waitForDeployment())
  .then(() => console.log('Successfully deployed!'))

// 2. Проверить в обозревателе, что токен успешно создан.
// Адрес токена вставить сюда:
// const tokenAddress = '0x0'

// 3. Развернуть Фонд
// const fundFactory = new ethers.ContractFactory(fundAbi, fundBin, wallet)

// fundFactory
//   .deploy(tokenAddress, DOLLAR_ADDRESS)
//   .then(contract => contract.waitForDeployment())
//   .then(() => console.log('Successfully deployed!'))

// 4. Проверить в обозревателе, что Фонд успешно создан.
// Адрес фонда вставить сюда:
// const fundAddress = '0x0'

// 5. Подготовить контракты токена и Фонда
// const tokenContract = new ethers.Contract(tokenAddress, tokenAbi, wallet)
// const fundContract = new ethers.Contract(fundAddress, fundAbi, wallet)

// 6. Передать Фонду владение токеном
// tokenContract['transferOwnership'](fundAddress)
//   .then(response => provider.waitForTransaction(response.hash))
//   .then(() => console.log('Ownership transferred!'))
//   .catch(error => console.log('error:', error.message))

// 7. Создать первый токен
// fundContract['mintFirstToken']()
//   .then(response => provider.waitForTransaction(response.hash))
//   .then(() => console.log('First token minted!'))
//   .catch(error => console.log('error:', error.message))

// 8. Отправить Фонду 1 доллар

// 9. Открыть Фонд
// fundContract['open']()
//   .then(response => provider.waitForTransaction(response.hash))
//   .then(() => console.log('Fund opened!'))
//   .catch(error => console.log('error:', error.message))
```
