declare module 'bitcoin-core' {
  interface Options {
    host: string,
    port: number,
    username: string,
    password: string,
  };
  interface Header {
    previousblockhash: string,
    height: number,
    hash: string,
  }
  class Client {
    constructor(options: Options): Client;
    async getBestBlockHash(): Promise<string>;
    async getBlockHeader(block: string): Promise<Header>;
    async getBlockHeader(block: number): Promise<Header>;
    async getBlockHeader(blockNum: number, verbose: boolean): Promise<string>;
  };
  export default Client;
}
