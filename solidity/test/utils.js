
module.exports = {

  strip0xPrefix: function strip0xPrefix(hexString) {
    return hexString.substring(0, 2) === '0x' ? hexString.substring(2) : hexString;
  },

  concatenateHexStrings: function concatenateHexStrings(strs) {
    let current = '0x';
    for (let i = 0; i < strs.length; i += 1) {
      current = `${current}${this.strip0xPrefix(strs[i])}`;
    }
    return current;
  },
  concatenateHeadersHexes: function concatenateHeadersHexes(arr) {
    const hexes = arr.map(_arr => _arr.hex);
    return this.concatenateHexStrings(hexes);
  },
  parseTestVector: function parseTestVector(str) {
    const lines = str.split(/\r\n|\r|\n/);
    const anchorHeigth = BigInt(lines[1].split(" ")[5]);
    const anchorParentTime = BigInt(lines[2].split(" ")[6]);
    const anchorNBits = lines[3].split(" ")[5];
    const startHeigth = BigInt(lines[4].split(" ")[5]);
    const startTime = BigInt(lines[5].split(" ")[5]);
    const cases = lines.filter(l => !l.includes("#") && l.length > 2);
    const parsedCases = cases.map(c => {
      c = c.split(" ");
      return {
        iter: parseInt(c[0]),
        heigth: BigInt(c[1]),
        time: BigInt(c[2]),
        target: c[3],
      }
    });
    return {
      anchorHeigth: anchorHeigth,
      anchorParentTime: anchorParentTime,
      anchorNBits: anchorNBits,
      startHeigth: startHeigth,
      startTime: startTime,
      cases: parsedCases
    }
  }
};
