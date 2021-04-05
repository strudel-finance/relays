const fs = require('fs');

const Client = require('bitcoin-core');
const client = new Client({
  host: "bchd.strudel.finance",
  port: 8332,
  username: process.env.UN,
  password: process.env.PW,
}); 

const swapEndianness = (hexString) => {
 if (hexString.length % 2 != 0) throw new Error("Hex string must be even length");
 return '0x' + hexString.match(/.{1,2}/g).reverse().join().replace(/,/g,'').slice(0,-2);
};

async function main() {
  const lastBlockHash = await client.getBestBlockHash();
  const lastHeader = await client.getBlockHeader(lastBlockHash);
  const lastBlockHeight = lastHeader.height;

  const chainLength = 15;
  const blockNums = Array(chainLength).fill(lastBlockHeight - chainLength + 1).map((n, ix) => n + ix);
  
  const data = await Promise.all(
    blockNums.map(num => {
      return (async () => {
        const blockHeader = await client.getBlockHeader(num);
        const rawBlockHeader = await client.getBlockHeader(num, false);
        return {
          ...blockHeader,
          raw: rawBlockHeader,
        };
      })();
    })
  );

  const marshalledData = data.map(block => {
    return {
      digest: "0x" + block.hash,
      digest_le: swapEndianness("0x" + block.hash),
      version: block.version,
      prev_block: "0x" + block.previousblockhash,
      merkle_root: "0x" + block.merkleroot,
      timestamp: block.time,
      nbits: "0x" + block.bits,
      difficulty: block.difficulty.split(".")[0],
      hex: "0x" + block.raw,
      height: block.height,
    };
  });
  const dump = {
    genesis: marshalledData[0],
    chain: marshalledData.slice(1),
  };
  fs.writeFileSync('./test/bchData.json', JSON.stringify(dump));
}

main();
