const {
    time,
    loadFixture,
  } = require("@nomicfoundation/hardhat-network-helpers");
  const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
  const { expect } = require("chai");
const { Contract } = require("hardhat/internal/hardhat-network/stack-traces/model");
const { ethers } = require("hardhat");

describe("uniswap Contracts",function(){
    let ERC20A;
    let ERC20B;
    let tokenA=50000;
    let tokenB=50000;
    let IncreaseNumberA=10000;
    let IncreaseNumberB=10000;
    let K;
    let owner; 
    let store_poolObj;
    let storeByPool=[];
    beforeEach(async function(){
        [owner, addr1, addr2, ...addrs] = await ethers.getSigners();
    })
    describe("Deployment", async function () {
        it("should create store_pool",async function(){
            const store_pool=await ethers.getContractFactory("storeFactory");
            store_poolObj=await store_pool.deploy();
            await store_poolObj.deployed();
            expect(store_poolObj!=undefined&&store_poolObj!=null).true;
        });
        it("init two different token ",async function(){
              let ERC20Facotry =await ethers.getContractFactory("FT");
              ERC20A =await ERC20Facotry.deploy("tokenA","xyA");
              ERC20B =await ERC20Facotry.deploy("tokenB","xyB");
              await ERC20A.deployed();
              await ERC20B.deployed();
              let result = ERC20A&&ERC20B?true:false;
              expect(result).true;
        });
        it("init a store object to store_pool",async function(){
            let needTokenANumber=tokenA
            let needTokenBNumber=tokenB
            await store_poolObj.createStore(ERC20A.address,ERC20B.address);
            let storeAddress= await store_poolObj.searchAMM(ERC20A.address,ERC20B.address);
            storeByPool.push(storeAddress);
            await ERC20A.mint(storeAddress,needTokenANumber);
            await ERC20B.mint(storeAddress,needTokenBNumber);
            let actualNumbersA=await ERC20A.balanceOf(storeAddress)
            actualNumbersA=actualNumbersA.toNumber();
            let actualNumbersB=await ERC20B.balanceOf(storeAddress);
            actualNumbersB=actualNumbersB.toNumber();
            await ERC20A.mint(owner.address,needTokenANumber);
            await ERC20B.mint(owner.address,needTokenBNumber);
            let ERC20ownerA = await ERC20A.balanceOf(owner.address);
            ERC20ownerA= ERC20ownerA.toNumber();
            let ERC20ownerB = await ERC20B.balanceOf(owner.address);
            ERC20ownerB= ERC20ownerB.toNumber();
            let tempContract =await ethers.getContractAt("Store",storeByPool[0],owner);
            await tempContract.syncBalance();
            let remainList = await tempContract.getStoreInfo();
            let storeA=remainList._medium0Num.toNumber();
            let storeB=remainList._medium1Num.toNumber(); 
            expect(ERC20ownerA === needTokenANumber && ERC20ownerB === needTokenBNumber).true
            expect(actualNumbersA === storeA && actualNumbersB === storeB).true
            tokenA =storeA
            tokenB=storeB;
            K=tokenA*tokenB;
        });
        it("should get right slipe point",async function(){
            const maxTestTimes=10;
            let sema=true;
            let failtureValuePairs={"theoryValue":undefined,"actualValue":undefined};
            let tempContract =await ethers.getContractAt("Store",storeByPool[0],owner);
            for(let i=0;i<maxTestTimes;i++){
            let INPUT_A = Number.parseInt(Math.random()*25000)+1;
            let consumerValueMul100=await tempContract.slipeCalFromToken0(INPUT_A)
            consumerValueMul100=consumerValueMul100.toNumber();
            let  theoryValue;
            (function(){
            //physical verify
               let origin=INPUT_A*tokenA*10**5/tokenB/10**5;
               let final=(tokenB - K/(tokenA+INPUT_A));
               //expand  molecule
               theoryValue= (origin-final)*10**6/(origin*10**4);
               theoryValue=Math.floor(theoryValue);
            }()
            )
             if(consumerValueMul100 != theoryValue &&consumerValueMul100+1!=theoryValue){
                  sema=false;
                  failtureValuePairs["theoryValue"]=theoryValue;
                  failtureValuePairs["actualValue"]=consumerValueMul100;
                  break;
             }
            }
            if(!sema){
                console.error("acturalValue is:",actualValue);
                console.error("theoryValue is:",theoryValue);
                expect(sema).true;
            }
        });
         it("increse liquidity is true",async function(){
            console.log("initial K is:",K);
            console.log("increasing liquidity----------------------");
            let storeAddress =storeByPool[0];
            let storeContract =await ethers.getContractAt("Store",storeAddress,owner);
            await ERC20A.mint(storeAddress,IncreaseNumberA);
            await ERC20B.mint(storeAddress,IncreaseNumberB);
            let actualNumbersA=await ERC20A.balanceOf(storeAddress)
            actualNumbersA=actualNumbersA.toNumber();
            let actualNumbersB=await ERC20B.balanceOf(storeAddress);
            actualNumbersB=actualNumbersB.toNumber();
            await storeContract.syncBalance();
            let remainList = await storeContract.getStoreInfo();
            let storeA=remainList._medium0Num.toNumber();
            let storeB=remainList._medium1Num.toNumber(); 
            tokenA=storeA;
            tokenB=storeB;
            K=tokenA*tokenB;
            expect(actualNumbersA === tokenA && actualNumbersB === tokenB).true
            console.log("increasing liquidity completely----------------------");
            console.log("Eventual K is:",K);
         })
        it("should promise the AMM function true",async function(){
            let swapNumberA= 2000;
            let swapNumberB =2000;
            const testMaxTimes=10;
            //only test single store
            let tempStoreAddress =  storeByPool[0];
            let tempContract =await ethers.getContractAt("Store",tempStoreAddress,owner);
            for(let i=0;i<testMaxTimes;i++){
              // get store
              //user give privileges to store,approve balance must greater than swapNumber
              await ERC20A.approve(tempStoreAddress,swapNumberA*2);
              await ERC20B.approve(tempStoreAddress,swapNumberB*2);
              let storeA,storeB;
              try{
              // token0 to token1
              await tempContract.swapFromToken0(swapNumberA,owner.address); 
              let remainList = await tempContract.getStoreInfo();
              storeA=remainList._medium0Num.toNumber();
              storeB=remainList._medium1Num.toNumber(); 
              expect(Math.round(K/(storeA*tokenB))).to.equal(1);
              //token1 to token0
              await tempContract.swapFromToken1(swapNumberB,owner.address); 
              remainList = await tempContract.getStoreInfo();
              storeA=remainList._medium0Num.toNumber();
              storeB=remainList._medium1Num.toNumber(); 
              expect(Math.round(K/(storeA*tokenB))).to.equal(1);
              if(i+1>=testMaxTimes){
                console.log("finial store tokenA is:",storeA);
                console.log("finial store tokenB is:",storeB);
              }
              }catch(err){
                console.error("K is:",K);
                console.error("store A is:",storeA);
                console.error("store B is",storeB);
                console.error(err);
                return;
              }finally{
                // release the token to owner
               let remainTokenA=await ERC20A.allowance(owner.address,tempStoreAddress);
               let remainTokenB=await ERC20B.allowance(owner.address,tempStoreAddress);
               remainTokenA=remainTokenA.toNumber();
               remainTokenB=remainTokenB.toNumber();
               await ERC20A.decreaseAllowance(tempStoreAddress,remainTokenA);
               await ERC20B.decreaseAllowance(tempStoreAddress,remainTokenB);
              }
            }
            
        });

});
    })