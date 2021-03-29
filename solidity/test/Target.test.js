const { parseTestVector } = require("./utils");
const fs = require("fs");
var assert = require('assert');

const getTestVectors = () => {
  const testPath = "./test/aserti3-2d";
  const dir = fs.readdirSync(testPath);
  const testVectors = dir.map(file => parseTestVector(fs.readFileSync(`${testPath}/${file}`, "utf8")));
  return testVectors;
}

const target = "0x1bc330000000000000000000000000000000000000000000";
const bits = "0x181bc330";

const bitsToTargetExamples = {
  '0x01003456': '0x00',      // getLow fail
  '0x01123456': '0x12',      // getLow fail
  '0x02008000': '0x80',
  '0x05009234': '0x92340000',
  '0x04123456': '0x12345600',
  '0x04923456': '0x12345600', //fNegative fail
}

//hexstring -> BigInt
function bitsToTarget(bits) {
  let target;
  
  let exponent = BigInt(bits) >> 24n;
  let mantissa = BigInt(bits) & BigInt('0x007fffff');

  if (exponent <= 3) {
    target = mantissa >> (8n * (3n - exponent));
  } else {
    target = mantissa << (8n * (exponent - 3n));
  }
  return target;
}

//hexstring -> hexstring
function targetToBits(target) {
  target = BigInt(target);
  let nCompact = 0n;
  
  const bits = target.toString(16).length * 4;
  let nSize = Math.floor((bits + 7) / 8);
  
  if (nSize <= 3) {
    nCompact = target << (8n * (3n - BigInt(nSize)));
  } else {
    nCompact = target >> (8n * (BigInt(nSize) - 3n));
  }

  if ((nCompact & BigInt('0x00800000')) != 0n) {
    nCompact = nCompact >> 8n;
    nSize += 1;
  }

  nCompact = nCompact | (BigInt(nSize) << 24n);
  
  return "0x" + nCompact.toString(16);
}

function nextTarget(
  anchorHeigth,
  anchorParentTime,
  anchorNBits,
  currentHeigth,
  currentTime
) {
  const idealBlockTime = 600;
  const halflife = 172800;
  
  let nextTarget;

  return nextTarget;
}

// contract('Target', async () => {
describe('Target', async () => {

  describe('JS implementation', async () => {
    
    it('test vectors parsing', async () => {
      const testVectors = getTestVectors();
      const target = bitsToTarget("0x181bc330");
    });

    it('bitsToTarget', async () => {
      assert(target == bitsToTarget(bits));
      for (const [bits, target] of Object.entries(bitsToTargetExamples)) {
        const myTarget = bitsToTarget(bits);
        assert(myTarget ==  BigInt(target));
      }
    });

    it('targetToBits', async () => {
      assert(bits == targetToBits(target));
      for (const [bits, target] of Object.entries(bitsToTargetExamples)) {
        const myBits = targetToBits(target);
        console.log(myBits, bits);
        // assert(myTarget ==  BigInt(target));
      }
    });
    
  });
});
