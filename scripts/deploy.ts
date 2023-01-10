import '@nomiclabs/hardhat-ethers'
import { ethers } from 'hardhat'

async function main() {
  const FT = await ethers.getContractFactory('FT')
  const ft = await FT.deploy('CBI', 'CUIT')
  await ft.deployed()
  const lww = await FT.deploy('LWW', 'LOVE')
  await lww.deployed()
  const HateUniswap = await FT.deploy(ft.address, lww.address)
  await HateUniswap.deployed()

  console.log(`FT deployed to ${ft.address}`)
  console.log(`LWW deployed to ${lww.address}`)
  console.log(`HateUniswap deployed to ${HateUniswap.address}`)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error)
  process.exitCode = 1
})
