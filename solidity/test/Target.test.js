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
  '0x01003456': '0x00',      
  '0x01123456': '0x12',      
  '0x02008000': '0x80',
  '0x05009234': '0x92340000',
  '0x04123456': '0x12345600',
  '0x04923456': '0x12345600',
}

// // hexstring -> BigInt
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

// BigInt -> BigInt
function targetToBits(target) {
  target = BigInt(target);
  const maxBits = "0x1d00ffff";
  const maxTarget = bitsToTarget(maxBits);
  
  if (target > maxTarget) target = maxTarget;

  const bits = BigInt(target.toString(16).length * 4);
  let size = (bits + 7n) / 8n;
  
  const mask64 = BigInt('0xffffffffffffffff');

  let compact;
  if (size <= 3n) {
    compact = (target & mask64) << (8n * (3n - size));
  } else {
    compact = (target >> (8n * (size - 3n))) & mask64;
  }
  if ((compact & BigInt('0x00800000')) != 0n) {
    compact >>= 8n
    size += 1n
  }
  return compact | size << 24n;
}

function nextTarget(
  anchorHeigth,
  anchorParentTime,
  anchorNBits,
  currentHeigth,
  currentTime
) {
  const idealBlockTime = 600n;
  const halflife = 172800n;
  const radix = 2n ** 16n;
  const maxBits = "0x1d00ffff";
  const maxTarget = bitsToTarget(maxBits);

  const anchorTarget = bitsToTarget(anchorNBits);
  const timeDelta = BigInt(currentTime) - BigInt(anchorParentTime);
  const heightDelta = BigInt(currentHeigth) - BigInt(anchorHeigth);
  let exponent = ((timeDelta - idealBlockTime * (heightDelta + 1n)) * radix) / halflife;

  const numShifts = exponent >> 16n;
  exponent = exponent - numShifts * radix;

  const factor =
        ((BigInt('195766423245049') * exponent +
          BigInt('971821376') * exponent ** 2n +
          5127n * exponent ** 3n +
          2n ** 47n) >> 48n) + radix;

  let nextTarget = anchorTarget * factor;

  if (numShifts < 0n) {
    nextTarget = nextTarget >> (-numShifts);
  } else {
    nextTarget = nextTarget << numShifts;
  }
  
  nextTarget = nextTarget >> 16n;

  if (nextTarget == 0n) {
    return 1n;
  }

  if (nextTarget > maxTarget) {
    return maxTarget;
  }

  return nextTarget;
}

// contract('Target', async () => {
describe('Target', async () => {

  describe('JS implementation', async () => {

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
        // console.log(myBits, BigInt(bits));
      }
    });

    it('test vectors parsing', async () => {
      const testVectors = getTestVectors();

      for (const testVector of testVectors) {
        for (const c of testVector.cases) {
          const myTarget = nextTarget(
            testVector.anchorHeigth,
            testVector.anchorParentTime,
            testVector.anchorNBits,
            c.heigth,
            c.time
          );
          
          assert(targetToBits(myTarget) == BigInt(c.target));
        }
      }      
    });
  });
});
