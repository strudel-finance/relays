export type GasPrice = "slow" | "average" | "fast" | "fastest";

export type Config = {
  ethGasStationEndpoint: string,
  speed: GasPrice,
  bchEndpoint: string,
  bchPort: number,
  relayAddress: string,
  ethRpc: string,
}

export type AddHeaders = {
  anchor: string,
  chain: string,
}
