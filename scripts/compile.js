/**
 * 编译脚本
 * 输入参数一个：sol源文件名
 * 输出：sol源文件中所有合约的编译结果对象
 */

const fs = require('fs-extra');
const solc = require('solc');
const path = require('path');

//input
//处理输入参数
const arguments = process.argv.splice(2);
if (!arguments || arguments.length != 1){
	console.log('Parameter error')
	return;
}
//被编译的sol文件名
const solFileName = arguments[0];
const solName = solFileName.split('.')[0];

//clean up
//删除先前编译结果,保存最新的编译结果
//编译结果保存路径
const compiledDir = path.resolve(__dirname, '../compiled', solName);
//删除sol对应文件夹内容
fs.removeSync(compiledDir);
fs.ensureDirSync(compiledDir);


//Compile
//目标合约路径
const contractPath = path.resolve(__dirname, '../contracts', solFileName);
//读取合约内容
const contractSource = fs.readFileSync(contractPath, 'utf-8');
//编译合约
const contractResult = solc.compile(contractSource, 1); //参数1表示打开solc中的优化器

//check errors
//检查编译错误,优化输出抛出异常
//检查结果中的errors
if (Array.isArray(contractResult.errors) && contractResult.errors.length){
	throw new Error(contractResult.errors[0]);
}

//save to disk
//写入到文件
Object.keys(contractResult.contracts).forEach(name =>{ //对结果对象中的合约名字遍历，注意前面有：号
	//去掉：号,得到合约名
	let contractName = name.replace(/^:/, '');
	//保存的路径,保存为json文件
	let filePath = path.resolve(compiledDir, contractName + '.json');
	//保存
	fs.outputJsonSync(filePath, contractResult.contracts[name]); //注意这里是name
	//提示结果
	console.log("Save compiled contract", contractName, "to", filePath);
});
