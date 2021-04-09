import Client from 'bitcoin-core';
import Relay from './Relay.json';
import { getDefaultProvider, Wallet, Contract } from 'ethers';
import { Config } from './types';
import { getCommonAncestor, getMissingData, getGasPrice, getBchBlock } from './read';
import { addHeaders, markNewHeaviest } from './write';
import { toEthFormat, sleep } from './utils';



const CONFIG: Config = {
  ethGasStationEndpoint: "https://ethgasstation.info/api/ethgasAPI.json?",
  speed: "fast",
  bchEndpoint: "bchd.strudel.finance",
  bchPort: 8332,
  relayAddress: "0x72677605c1F5593cFD5e9E5248902EA51d880b90",
  ethRpc: "http://localhost:7545",
  limit: 50,
}

const log = (msg: string) => {
  const now = new Date(Date.now());
  console.log(`${now.toUTCString()} - ${msg}`);
}

// TODO: retry when tx stuck too long -> Promise.race
const iter = async (client: Client, relay: Contract): Promise<void> => {
  const gasPrice = await getGasPrice(CONFIG.ethGasStationEndpoint, CONFIG.speed);

  const ethBlock = await relay.getBestKnownDigest();
  const bchBlock = await getBchBlock(client, relay, ethBlock, CONFIG.limit);

  log(`Current relay tip: ${ethBlock}`);
  log(`BCH tip in limit range: ${toEthFormat(bchBlock)}`);

  if (toEthFormat(bchBlock) == ethBlock) return;

  const commonAncestor = await getCommonAncestor(client, relay, bchBlock, ethBlock);
  const chain = await getMissingData(client, commonAncestor, bchBlock);

  log(`Need to submit ${(chain.chain.length - 2) / 160} blocks.`);

  const addHeadersTx = await addHeaders(relay, gasPrice, chain);
  log(`AddHeaders tx hash: ${addHeadersTx.hash}`);
  const markNewHeaviestTx = await markNewHeaviest(
    relay, gasPrice, toEthFormat(commonAncestor), chain.anchor, chain.newBest, CONFIG.limit
  );
  log(`MarkNewHeaviest tx hash: ${markNewHeaviestTx.hash}`);
}


async function main() {

  if (!process.env.UN || !process.env.PW || !process.env.PK) {
    throw new Error("Provide UN, PW and PK!");
  }

  // construct resources
  const client = new Client({
    host: CONFIG.bchEndpoint,
    port: CONFIG.bchPort,
    username: process.env.UN,
    password: process.env.PW,
  });
  const provider = getDefaultProvider(CONFIG.ethRpc);
  const wallet = new Wallet(process.env.PK, provider);
  const relay = new Contract(CONFIG.relayAddress, Relay.abi, wallet);

  while (true) {
    try {
      await iter(client, relay);
    } catch (e) {
      log(e);
    }
    await sleep(5);
  }
}

main();
