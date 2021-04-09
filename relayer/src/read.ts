import fetch from 'node-fetch';
import { utils, Contract, BigNumber } from 'ethers';
import Client from 'bitcoin-core';

import { GasPrice, AddHeaders } from './types';
import { toBchFormat } from './utils';

export const getGasPrice = async (endpoint: string, speed: GasPrice): Promise<BigNumber> => {
  const gasDataResponse = await fetch(endpoint);
  const gasData = await gasDataResponse.json();
  const gasPrice = (gasData[speed] / 10).toString();
  return utils.parseUnits(gasPrice, 'gwei');
}

// TODO: implement this
const getEthParent = async (relay: Contract, block: string): Promise<string> => {
  return "";
}

const getBchParent = async (client: Client, block: string): Promise<string> => {
  const header = await client.getBlockHeader(block);
  return header.previousblockhash;
}

const getBchHeight = async (client: Client, block: string): Promise<number> => {
  const header = await client.getBlockHeader(block);
  return header.height;
}

// assumes bch chain always has higher block number
// return bch format, inputs are their own formats
export const getCommonAncestor = async (
  client: Client,
  relay: Contract,
  bchBlock: string,
  ethBlock: string,
): Promise<string> => {

  const ethHeigth = (await relay.findHeight(ethBlock)).toNumber();
  const bchHeigth = await getBchHeight(client, bchBlock);

  if (bchHeigth > ethHeigth) {
    bchBlock = (await client.getBlockHeader(ethHeigth)).hash;
    return getCommonAncestor(client, relay, bchBlock, ethBlock);
  }

  if (bchBlock == toBchFormat(ethBlock)) return bchBlock;

  const ethParent = await getEthParent(relay, ethBlock);
  const bchParent = await getBchParent(client, bchBlock);
  return getCommonAncestor(client, relay, bchParent, ethParent);
}

// the caller should make sure end-start is not too large
export const getMissingData = async (client: Client, start: string, end: string): Promise<AddHeaders> => {
  const startBlockNum = await getBchHeight(client, start);
  const endBlockNum = await getBchHeight(client, end);

  const blockNums = Array(endBlockNum - startBlockNum + 1)
    .fill(startBlockNum)
    .map((n, ix) => n + ix);

  const headers = await Promise.all(blockNums.map(num => client.getBlockHeader(num, false)));
  return {
    anchor: "0x" + headers[0],
    chain: "0x" + headers.slice(1).reduce((cv, acc) => cv + acc, ""),
  };
}
