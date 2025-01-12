import { readFileSync } from 'fs'

// Replace with your file names
const abiFileName = '../dist/FILE_NAME.abi'
const binFileName = '../dist/FILE_NAME.bin'

export const bin = readFileSync(binFileName, 'utf8')

export const abi = JSON.parse(readFileSync(abiFileName, 'utf8'))
