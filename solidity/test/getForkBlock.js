const fs = require('fs');
const { nextTarget, targetToBits } = require('./aserti');

const Client = require('bitcoin-core');
const client = new Client({
  host: "bchd.strudel.finance",
  port: 8332,
  username: process.env.UN,
  password: process.env.PW,
}); 

async function main() {
  
  const anchor = 661647;
  const anchorHeader = await client.getBlockHeader(anchor);
  const anchorParentHeader = await client.getBlockHeader(anchor - 1);

  const anchorHeigth = anchorHeader.height;
  const anchorParentTime = anchorParentHeader.time;
  const anchorNBits = "0x" + anchorHeader.bits;

  console.log(anchorHeigth, anchorParentTime, anchorNBits);
  
  const delta = 110;
  const currentBlock = await client.getBlockHeader(anchor + delta);
  const currentHeigth = currentBlock.height;
  const currentTime = currentBlock.time;
  
  console.log(targetToBits(nextTarget(
    anchorHeigth,
    anchorParentTime,
    anchorNBits,
    currentHeigth,
    currentTime
  )).toString(16));

  const nextBlock = await client.getBlockHeader(anchor + delta + 1);
  console.log(nextBlock.bits);
}

main();
