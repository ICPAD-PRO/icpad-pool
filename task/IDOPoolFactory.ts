import {task} from 'hardhat/config';

require("@nomiclabs/hardhat-web3");

task("deploy-ido-pool")
    .setAction(async (taskArgs, {ethers}) => {
        const poolFactory = await ethers.getContractFactory('PoolFactory');
        const pool = await poolFactory.deploy('');
        await pool.initialize(['']);
        console.log(`Deployed pool at: ${pool.address}`);
    });