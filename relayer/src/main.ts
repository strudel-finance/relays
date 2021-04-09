import Client from 'bitcoin-core';
import Relay from './Relay.json';
import { getDefaultProvider, Wallet, Contract } from 'ethers';
import { Config } from './types';
import { getCommonAncestor, getMissingData } from './read';



const CONFIG: Config = {
  ethGasStationEndpoint: "https://ethgasstation.info/api/ethgasAPI.json?",
  speed: "fast",
  bchEndpoint: "bchd.strudel.finance",
  bchPort: 8332,
  relayAddress: "0x6f63a1Db775c23168640BE1C415DfCF5c6577E36",
  ethRpc: "http://localhost:7545",
}

// TODO: writes (addHeaders, markNewheaviest)
// TODO: logging
// TODO: error handling
// retry when tx stuck too long -> Promise.race


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

  const bchBlock = await client.getBestBlockHash();
  const ethBlock = await relay.getBestKnownDigest();

  const x = await getCommonAncestor(client, relay, bchBlock, ethBlock);
  const y = await getMissingData(client, x, bchBlock);

  console.log(y);
}

main();
