export const swapEndianness = (hexString: string): string => {
  if (hexString.length % 2 != 0) throw new Error("Hex string must be even length");
  return '0x' + (hexString.match(/.{1,2}/g) as any).reverse().join().replace(/,/g, '').slice(0, -2);
};

export const toBchFormat = (block: string): string => {
  return swapEndianness(block).replace('0x', '');
}

export const toEthFormat = (block: string): string => {
  return swapEndianness("0x" + block);
}

export const sleep = (seconds: number): Promise<void> => {
  return new Promise((resolve) => setTimeout(resolve, seconds * 1000));
}
