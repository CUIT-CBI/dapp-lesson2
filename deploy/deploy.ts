import { ethers } from "ethers";
import { DeployFunction } from "hardhat-deploy/dist/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
    const { deployments, getNamedAccounts } = hre;
    console.log(hre.network.name)
    const { deploy } = deployments;
    // 这里的deployer就是hardhat.confit.ts中namedAccounts下deployer，由.env下配置的私钥生成
    const { deployer } = await getNamedAccounts(); 
    console.log(deployer)
    // 这里的FT就是合约名称，后面的参数是构造函数的参数，如果没有就不用写
    const RuinToken = await deploy("FT", {
        from: deployer,
        args: ["cs","cx"],
        log: true,
    });

   

    console.log(RuinToken.address);
};

export default func;
// 这个tags就是部署时命令 --tags后面要输入的名称
func.tags = ["RUIN"];
