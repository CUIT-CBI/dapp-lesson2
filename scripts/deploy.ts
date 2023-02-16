import '@nomiclabs/hardhat-ethers'
import { ethers } from 'hardhat'

async function main() {
	const FT = await ethers.getContractFactory('FT')

	const tokenA = await FT.deploy('TESTA', 'A')
	await tokenA.deployed()
	console.log(`token_A deployed: ${tokenA.address}`)

	const tokenB = await FT.deploy('TESTB', 'B')
	await tokenB.deployed()
	console.log(`token_B deployed: ${tokenB.address}`)

	const Uniswap = await ethers.getContractFactory('Uniswap')
	const swap = await Uniswap.deploy(tokenA.address, tokenB.address)
	await swap.deployed()
	console.log(`Uniswap deployed: ${swap.address}`)
}
