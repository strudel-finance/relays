import { Contract, BigNumber } from 'ethers';
import { AddHeaders, Tx } from './types';

export const addHeaders = async (
  relay: Contract,
  gasPrice: BigNumber,
  headers: AddHeaders,
): Promise<Tx> => {
  const tx = await relay.addHeaders(headers.anchor, headers.chain, {
    gasPrice: gasPrice
  });
  await tx.wait();
  return tx;
}

export const markNewHeaviest = async (
  relay: Contract,
  gasPrice: BigNumber,
  commonAncestor: string,
  currentBest: string,
  newBest: string,
  limit: number,
): Promise<Tx> => {
  const tx = await relay.markNewHeaviest(
    commonAncestor,
    currentBest,
    newBest,
    limit,
    { gasPrice: gasPrice }
  );
  await tx.wait();
  return tx;
}
