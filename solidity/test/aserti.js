function parseTestVector(str) {
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
    describtion: lines[0],
    anchorHeigth: anchorHeigth,
    anchorParentTime: anchorParentTime,
    anchorNBits: anchorNBits,
    startHeigth: startHeigth,
    startTime: startTime,
    cases: parsedCases
  }
}

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
    compact >>= 8n;
    size += 1n;
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


module.exports = {
  parseTestVector,
  bitsToTarget,
  targetToBits,
  nextTarget,
}
