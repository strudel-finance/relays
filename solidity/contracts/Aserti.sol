pragma solidity ^0.5.10;

contract Aserti {
  int256 constant IDEAL_BLOCK_TIME = 600;
  int256 constant HALFLIFE = 172800;
  int256 constant RADIX = 2 ** 16;
  uint256 constant MAX_BITS = 0x1d00ffff;

  function bitsToTarget(uint256 nBits) public pure returns (uint256) {
    uint256 target;

    uint256 exponent = nBits >> 24;
    uint256 mantissa = nBits & 0x007fffff;

    if (exponent <= 3) {
      target = mantissa >> (8 * (3 - exponent));
    } else {
      target = mantissa << (8 * (exponent - 3));
    }
    return target;
  }

  function nextTarget(int256 anchorHeigth,
                      int256 anchorParentTime,
                      uint256 anchorNBits,
                      int256 currentHeigth,
                      int256 currentTime
                      ) external pure returns (uint256) {

    uint256 maxTarget = bitsToTarget(MAX_BITS);
    uint256 anchorTarget = bitsToTarget(anchorNBits);
    
    int256 timeDelta = currentTime - anchorParentTime;
    int256 heigthDelta = currentHeigth - anchorHeigth;

    int256 exponent =
      ((timeDelta - IDEAL_BLOCK_TIME * (heigthDelta + 1)) * RADIX) / HALFLIFE;
    int256 numShifts = exponent >> 16;
    exponent = exponent - numShifts * RADIX;

    // I think factor can be negative...
    int256 factor =
      ((195766423245049 * exponent + 971821376 * exponent * exponent +
        5127 * exponent * exponent * exponent + 2 ** 47) >> 48) + RADIX;

    // if factor is negative, is this cast a problem?
    uint256 nextTarget = anchorTarget * uint256(factor);

    if (numShifts < 0) {
      nextTarget = nextTarget >> (-numShifts);
    } else {
      nextTarget = nextTarget << numShifts;
    }

    nextTarget = nextTarget >> 16;

    if (nextTarget == 0) {
      return 1;
    }

    if (nextTarget > maxTarget) {
      return maxTarget;
    }
    
    return nextTarget;
  }
}
