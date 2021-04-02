const { parseTestVector, bitsToTarget, targetToBits, nextTarget } = require("./aserti");
const fs = require("fs");
const assert = require('assert');

const Aserti = artifacts.require('Aserti');

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

const runBitsToTargetTest = (btt) => {
  it(`bitsToTarget version ${btt.name}`, async () => {
    assert(target == (await btt(bits)));
    for (const [bits, target] of Object.entries(bitsToTargetExamples)) {
      const myTarget = await btt(bits);
      assert(myTarget ==  BigInt(target));
    }
  });
}

const runNextTargetTests = (nt) => {
  const testVectors = getTestVectors();
  for (const testVector of testVectors) {
    it(`Next Taregt - version: ${nt.name}, ${testVector.describtion}`, async () => {
      for (const c of testVector.cases) {
        const myTarget = await nt(
          testVector.anchorHeigth,
          testVector.anchorParentTime,
          testVector.anchorNBits,
          c.heigth,
          c.time
        );
        assert(targetToBits(myTarget) == BigInt(c.target));
      }
    });
  }
}

contract('Target', async () => {
// describe('Target', async () => {
  
  describe('JS implementation', async () => {

    it('targetToBits', async () => {
      assert(bits == targetToBits(target));
      for (const [bits, target] of Object.entries(bitsToTargetExamples)) {
        const myBits = targetToBits(target);
        // console.log(myBits, BigInt(bits));
      }
    });
    
    runBitsToTargetTest(bitsToTarget);
    // runNextTargetTests(nextTarget);
  });

  describe('Solidity implementation', async () => {

    let instance;

    before(async () => {
      instance = await Aserti.new();
    });

    const bitsToTargetSol = async (bits) => {
      const res = await instance.bitsToTarget.call(bits);
      return BigInt("0x" + res.toString('hex'));
    }

    const nextTargetSol = async (
      anchorHeigth,
      anchorParentTime,
      anchorNBits,
      currentHeigth,
      currentTime
    ) => {
      anchorHeigth = '0x' + anchorHeigth.toString(16);
      anchorParentTime = '0x' + anchorParentTime.toString(16);
      currentHeigth = '0x' + currentHeigth.toString(16);
      currentTime = '0x' + currentTime.toString(16);

      const res = await instance.nextTarget.call(
        anchorHeigth,
        anchorParentTime,
        anchorNBits,
        currentHeigth,
        currentTime
      );

      return BigInt('0x' + res['0'].toString('hex'));
    }

    runBitsToTargetTest(bitsToTargetSol);
    runNextTargetTests(nextTargetSol);
    
    it('test1', async () => {
      // console.log(bits, target);
      // uint256 returns BN instance...
      let res = await instance.bitsToTarget.call(bits);
      // console.log(res.toString('hex'));
    });

    it('test2', async () => {
      const testVectors = getTestVectors();
      const testVector = testVectors[1];

      const anchorHeigth = '0x' + testVector.anchorHeigth.toString(16);
      const anchorParentTime = '0x' + testVector.anchorParentTime.toString(16);
      const anchorNBits = testVector.anchorNBits;

      const case0 = testVector.cases[0];
      const currentHeigth = '0x' + case0.heigth.toString(16);
      const currentTime = '0x' + case0.time.toString(16);

      let res = await instance.nextTarget.call(
        anchorHeigth,
        anchorParentTime,
        anchorNBits,
        currentHeigth,
        currentTime
      );

      let js = nextTarget(
        testVector.anchorHeigth,
        testVector.anchorParentTime,
        testVector.anchorNBits,
        case0.heigth,
        case0.time
      );

      const resBits = targetToBits(BigInt('0x' + res['0'].toString('hex'))).toString(16);
      const debug = BigInt('0x' + res['1'].toString('hex'));
      console.log("Debug:", debug);
      console.log("Test:", case0.target);
      console.log("Mine:", "0x" + resBits);
    });
  });
});
