import {task} from 'hardhat/config';

require("@nomiclabs/hardhat-web3");


task('deploy-icpad-stake')
    .addParam("token")
    .setAction(async (taskArgs, {ethers}) => {
        const ICPadStake = await ethers.getContractFactory('ICPadStake');
        const utils = ethers.utils;
        const icPadStake = await ICPadStake.deploy(taskArgs.token, 0, utils.parseUnits("999999999999999"), {
            gasLimit: 10000000,
            gasPrice: 10 * 1000000000
        });
        const stake = await icPadStake.deployed();
        console.log('stake address', stake.address);
    });