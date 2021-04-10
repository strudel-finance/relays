// File: @summa-tx/bitcoin-spv-sol/contracts/SafeMath.sol

pragma solidity ^0.5.10;

/*
The MIT License (MIT)

Copyright (c) 2016 Smart Contract Solutions, Inc.

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (_a == 0) {
            return 0;
        }

        c = _a * _b;
        require(c / _a == _b, "Overflow during multiplication.");
        return c;
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        // assert(_b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = _a / _b;
        // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
        return _a / _b;
    }

    /**
     * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a, "Underflow during subtraction.");
        return _a - _b;
    }

    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        c = _a + _b;
        require(c >= _a, "Overflow during addition.");
        return c;
    }
}

// File: @summa-tx/bitcoin-spv-sol/contracts/TypedMemView.sol

pragma solidity ^0.5.10;


library TypedMemView {
    using SafeMath for uint256;


    // Why does this exist?
    // the solidity `bytes memory` type has a few weaknesses.
    // 1. You can't index ranges effectively
    // 2. You can't slice without copying
    // 3. The underlying data may represent any type
    // 4. Solidity never deallocates memory, and memory costs grow
    //    superlinearly

    // By using a memory view instead of a `bytes memory` we get the following
    // advantages:
    // 1. Slices are done on the stack, by manipulating the pointer
    // 2. We can index arbitrary ranges and quickly convert them to stack types
    // 3. We can insert type info into the pointer, and typecheck at runtime

    // This makes `TypedMemView` a useful tool for efficient zero-copy
    // algorithms.

    // Why bytes29?
    // We want to avoid confusion between views, digests, and other common
    // types so we chose a large and uncommonly used odd number of bytes
    //
    // Note that while bytes are left-aligned in a word, integers and addresses
    // are right-aligned. This means when working in assembly we have to
    // account for the 3 unused bytes on the righthand side
    //
    // First 5 bytes are a type flag.
    // - ff_ffff_fffe is reserved for unknown type.
    // - ff_ffff_ffff is reserved for invalid types/errors.
    // next 12 are memory address
    // next 12 are len
    // bottom 3 bytes are empty

    // Assumptions:
    // - non-modification of memory.
    // - No Solidity updates
    // - - wrt free mem point
    // - - wrt bytes representation in memory
    // - - wrt memory addressing in general

    // Usage:
    // - create type constants
    // - use `assertType` for runtime type assertions
    // - - unfortunately we can't do this at compile time yet :(
    // - recommended: implement modifiers that perform type checking
    // - - e.g.
    // - - `uint40 constant MY_TYPE = 3;`
    // - - ` modifer onlyMyType(bytes29 myView) { myView.assertType(MY_TYPE); }`
    // - instantiate a typed view from a bytearray using `ref`
    // - use `index` to inspect the contents of the view
    // - use `slice` to create smaller views into the same memory
    // - - `slice` can increase the offset
    // - - `slice can decrease the length`
    // - - must specify the output type of `slice`
    // - - `slice` will return a null view if you try to overrun
    // - - make sure to explicitly check for this with `notNull` or `assertType`
    // - use `equal` for typed comparisons.


    // The null view
    bytes29 public constant NULL = hex"ffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";
    uint256 constant LOW_12_MASK = 0xffffffffffffffffffffffff;
    uint8 constant TWELVE_BYTES = 96;

    // Returns the encoded hex charcter that represents the lower 4 bits of the argument.
    function nibbleHex(uint8 _b) internal pure returns (uint8) {
        // This can probably be done more efficiently, but it's only in error
        // paths, so we don't really care :)
        uint8 _nibble = _b | 0xf0; // set top 4, keep bottom 4
        if (_nibble == 0xf0) {return 0x30;} // 0
        if (_nibble == 0xf1) {return 0x31;} // 1
        if (_nibble == 0xf2) {return 0x32;} // 2
        if (_nibble == 0xf3) {return 0x33;} // 3
        if (_nibble == 0xf4) {return 0x34;} // 4
        if (_nibble == 0xf5) {return 0x35;} // 5
        if (_nibble == 0xf6) {return 0x36;} // 6
        if (_nibble == 0xf7) {return 0x37;} // 7
        if (_nibble == 0xf8) {return 0x38;} // 8
        if (_nibble == 0xf9) {return 0x39;} // 9
        if (_nibble == 0xfa) {return 0x61;} // a
        if (_nibble == 0xfb) {return 0x62;} // b
        if (_nibble == 0xfc) {return 0x63;} // c
        if (_nibble == 0xfd) {return 0x64;} // d
        if (_nibble == 0xfe) {return 0x65;} // e
        if (_nibble == 0xff) {return 0x66;} // f
    }

    // Returns a uint16 containing the hex-encoded byte
    function byteHex(uint8 _b) internal pure returns (uint16 encoded) {
        encoded |= nibbleHex(_b >> 4); // top 4 bits
        encoded <<= 8;
        encoded |= nibbleHex(_b); // lower 4 bits
    }

    // Encodes the uint256 to hex. `first` contains the encoded top 16 bytes.
    // `second` contains the encoded lower 16 bytes.
    function encodeHex(uint256 _b) internal pure returns (uint256 first, uint256 second) {
        for (uint8 i = 31; i > 15; i -= 1) {
            uint8 _byte = uint8(_b >> (i * 8));
            first |= byteHex(_byte);
            if (i != 16) {
                first <<= 16;
            }
        }

        // abusing underflow here =_=
        for (uint8 i = 15; i < 255 ; i -= 1) {
            uint8 _byte = uint8(_b >> (i * 8));
            second |= byteHex(_byte);
            if (i != 0) {
                second <<= 16;
            }
        }
    }

    /// @notice          Changes the endianness of a uint256
    /// @dev             https://graphics.stanford.edu/~seander/bithacks.html#ReverseParallel
    /// @param _b        The unsigned integer to reverse
    /// @return          The reversed value
    function reverseUint256(uint256 _b) internal pure returns (uint256 v) {
        v = _b;

        // swap bytes
        v = ((v >> 8) & 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF) |
            ((v & 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF) << 8);
        // swap 2-byte long pairs
        v = ((v >> 16) & 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF) |
            ((v & 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF) << 16);
        // swap 4-byte long pairs
        v = ((v >> 32) & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) |
            ((v & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) << 32);
        // swap 8-byte long pairs
        v = ((v >> 64) & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) |
            ((v & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) << 64);
        // swap 16-byte long pairs
        v = (v >> 128) | (v << 128);
    }

    /// Create a mask with the highest `_len` bits set
    function leftMask(uint8 _len) private pure returns (uint256 mask) {
        // ugly. redo without assembly?
        assembly {
            // solium-disable-previous-line security/no-inline-assembly
            mask := sar(
                sub(_len, 1),
                0x8000000000000000000000000000000000000000000000000000000000000000
            )
        }
    }

    /// Return the null view
    function nullView() internal pure returns (bytes29) {
        return NULL;
    }

    /// Check if the view is null
    function isNull(bytes29 memView) internal pure returns (bool) {
        return memView == NULL;
    }

    /// Check if the view is not null
    function notNull(bytes29 memView) internal pure returns (bool) {
        return !isNull(memView);
    }

    /// Check if the view is of a valid type and points to a valid location in
    /// memory. We perform this check by examining solidity's unallocated
    /// memory pointer and ensuring that the view's upper bound is less than
    /// that.
    function isValid(bytes29 memView) internal pure returns (bool ret) {
        if (typeOf(memView) == 0xffffffffff) {return false;}
        uint256 _end = end(memView);
        assembly {
            // solium-disable-previous-line security/no-inline-assembly
            ret := not(gt(_end, mload(0x40)))
        }
    }

    /// Require that a typed memory view be valid.
    /// Returns the view for easy chaining
    function assertValid(bytes29 memView) internal pure returns (bytes29) {
        require(isValid(memView), "Validity assertion failed");
        return memView;
    }

    /// Return true if the memview is of the expected type. Otherwise false.
    function isType(bytes29 memView, uint40 _expected) internal pure returns (bool) {
        return typeOf(memView) == _expected;
    }

    /// Require that a typed memory view has a specific type.
    /// Returns the view for easy chaining
    function assertType(bytes29 memView, uint40 _expected) internal pure returns (bytes29) {
        if (!isType(memView, _expected)) {
            (, uint256 g) = encodeHex(uint256(typeOf(memView)));
            (, uint256 e) = encodeHex(uint256(_expected));
            string memory err = string(
                abi.encodePacked(
                    "Type assertion failed. Got 0x",
                    uint80(g),
                    ". Expected 0x",
                    uint80(e)
                )
            );
            revert(err);
        }
        return memView;
    }

    /// Return an identical view with a different type
    function castTo(bytes29 memView, uint40 _newType) internal pure returns (bytes29 newView) {
        // then | in the new type
        assembly {
            // solium-disable-previous-line security/no-inline-assembly
            // shift off the top 5 bytes
            newView := or(newView, shr(40, shl(40, memView)))
            newView := or(newView, shl(216, _newType))
        }
    }

    /// Unsafe raw pointer construction. This should generally not be called
    /// directly. Prefer `ref` wherever possible.
    function buildUnchecked(uint256 _type, uint256 _loc, uint256 _len) private pure returns (bytes29 newView) {
        assembly {
            // solium-disable-previous-line security/no-inline-assembly
            newView := shl(96, or(newView, _type)) // insert type
            newView := shl(96, or(newView, _loc))  // insert loc
            newView := shl(24, or(newView, _len))  // empty bottom 3 bytes
        }
    }

    /// Instantiate a new memory view. This should generally not be called
    /// directly. Prefer `ref` wherever possible.
    function build(uint256 _type, uint256 _loc, uint256 _len) internal pure returns (bytes29 newView) {
        uint256 _end = _loc.add(_len);
        assembly {
            // solium-disable-previous-line security/no-inline-assembly
            if gt(_end, mload(0x40)) {
                _end := 0
            }
        }
        if (_end == 0) {
            return NULL;
        }
        newView = buildUnchecked(_type, _loc, _len);
    }

    /// Instantiate a memory view from a byte array.
    ///
    /// Note that due to Solidity memory representation, it is not possible to
    /// implement a deref, as the `bytes` type stores its len in memory.
    function ref(bytes memory arr, uint40 newType) internal pure returns (bytes29) {
        uint256 _len = arr.length;

        uint256 _loc;
        assembly {
            // solium-disable-previous-line security/no-inline-assembly
            _loc := add(arr, 0x20)  // our view is of the data, not the struct
        }

        return build(newType, _loc, _len);
    }

    /// Return the associated type information
    function typeOf(bytes29 memView) internal pure returns (uint40 _type) {
        assembly {
            // solium-disable-previous-line security/no-inline-assembly
            // 216 == 256 - 40
            _type := shr(216, memView) // shift out lower 24 bytes
        }
    }

    /// Optimized type comparison. Checks that the 5-byte type flag is equal.
    function sameType(bytes29 left, bytes29 right) internal pure returns (bool) {
        return (left ^ right) >> (2 * TWELVE_BYTES) == 0;
    }

    /// Return the memory address of the underlying bytes
    function loc(bytes29 memView) internal pure returns (uint96 _loc) {
        uint256 _mask = LOW_12_MASK;  // assembly can't use globals
        assembly {
            // solium-disable-previous-line security/no-inline-assembly
            // 120 bits = 12 bytes (the encoded loc) + 3 bytes (empty low space)
            _loc := and(shr(120, memView), _mask)
        }
    }

    /// The number of memory words this memory view occupies, rounded up
    function words(bytes29 memView) internal pure returns (uint256) {
        return uint256(len(memView)).add(32) / 32;
    }

    /// The in-memory footprint of a fresh copy of the view
    function footprint(bytes29 memView) internal pure returns (uint256) {
        return words(memView) * 32;
    }

    /// The number of bytes of the view
    function len(bytes29 memView) internal pure returns (uint96 _len) {
        uint256 _mask = LOW_12_MASK;  // assembly can't use globals
        assembly {
            // solium-disable-previous-line security/no-inline-assembly
            _len := and(shr(24, memView), _mask)
        }
    }

    /// Returns the endpoint of the `memView`
    function end(bytes29 memView) internal pure returns (uint256) {
        return loc(memView) + len(memView);
    }

    /// Safe slicing without memory modification.
    function slice(bytes29 memView, uint256 _index, uint256 _len, uint40 newType) internal pure returns (bytes29) {
        uint256 _loc = loc(memView);

        // Ensure it doesn't overrun the view
        if (_loc.add(_index).add(_len) > end(memView)) {
            return NULL;
        }

        _loc = _loc.add(_index);
        return build(newType, _loc, _len);
    }

    /// Shortcut to `slice`. Gets a view representing the first `_len` bytes
    function prefix(bytes29 memView, uint256 _len, uint40 newType) internal pure returns (bytes29) {
        return slice(memView, 0, _len, newType);
    }

    /// Shortcut to `slice`. Gets a view representing the last `_len` byte
    function postfix(bytes29 memView, uint256 _len, uint40 newType) internal pure returns (bytes29) {
        return slice(memView, uint256(len(memView)).sub(_len), _len, newType);
    }

    /// Construct an error message for an indexing overrun.
    function indexErrOverrun(
        uint256 _loc,
        uint256 _len,
        uint256 _index,
        uint256 _slice
    ) internal pure returns (string memory err) {
        (, uint256 a) = encodeHex(_loc);
        (, uint256 b) = encodeHex(_len);
        (, uint256 c) = encodeHex(_index);
        (, uint256 d) = encodeHex(_slice);
        err = string(
            abi.encodePacked(
                "TypedMemView/index - Overran the view. Slice is at 0x",
                uint48(a),
                " with length 0x",
                uint48(b),
                ". Attempted to index at offset 0x",
                uint48(c),
                " with length 0x",
                uint48(d),
                "."
            )
        );
    }

    /// Load up to 32 bytes from the view onto the stack.
    ///
    /// Returns a bytes32 with only the `_bytes` highest bytes set.
    /// This can be immediately cast to a smaller fixed-length byte array.
    /// To automatically cast to an integer, use `indexUint` or `indexInt`.
    function index(bytes29 memView, uint256 _index, uint8 _bytes) internal pure returns (bytes32 result) {
        if (_bytes == 0) {return bytes32(0);}
        if (_index.add(_bytes) > len(memView)) {
            revert(indexErrOverrun(loc(memView), len(memView), _index, uint256(_bytes)));
        }
        require(_bytes <= 32, "TypedMemView/index - Attempted to index more than 32 bytes");

        uint8 bitLength = _bytes * 8;
        uint256 _loc = loc(memView);
        uint256 _mask = leftMask(bitLength);
        assembly {
            // solium-disable-previous-line security/no-inline-assembly
            result := and(mload(add(_loc, _index)), _mask)
        }
    }

    /// Parse an unsigned integer from the view at `_index`. Requires that the
    /// view have >= `_bytes` bytes following that index.
    function indexUint(bytes29 memView, uint256 _index, uint8 _bytes) internal pure returns (uint256 result) {
        return uint256(index(memView, _index, _bytes)) >> ((32 - _bytes) * 8);
    }

    /// Parse an unsigned integer from LE bytes.
    function indexLEUint(bytes29 memView, uint256 _index, uint8 _bytes) internal pure returns (uint256 result) {
        return reverseUint256(uint256(index(memView, _index, _bytes)));
    }

    /// Parse a signed integer from the view at `_index`. Requires that the
    /// view have >= `_bytes` bytes following that index.
    function indexInt(bytes29 memView, uint256 _index, uint8 _bytes) internal pure returns (int256 result) {
        return int256(index(memView, _index, _bytes)) >> ((32 - _bytes) * 8);
    }

    /// Parse an address from the view at `_index`. Requires that the view have >= 20 bytes following that index.
    function indexAddress(bytes29 memView, uint256 _index) internal pure returns (address) {
        return address(uint160(indexInt(memView, _index, 20)));
    }

    /// Return the keccak256 hash of the underlying memory
    function keccak(bytes29 memView) internal pure returns (bytes32 digest) {
        uint256 _loc = loc(memView);
        uint256 _len = len(memView);
        assembly {
            // solium-disable-previous-line security/no-inline-assembly
            digest := keccak256(_loc, _len)
        }
    }

    /// Return the sha2 digest of the underlying memory. We explicitly deallocate memory afterwards
    function sha2(bytes29 memView) internal view returns (bytes32 digest) {
        uint256 _loc = loc(memView);
        uint256 _len = len(memView);
        assembly {
            // solium-disable-previous-line security/no-inline-assembly
            let ptr := mload(0x40)
            pop(staticcall(gas, 2, _loc, _len, ptr, 0x20)) // sha2 #1
            digest := mload(ptr)
        }
    }

    /// @notice          Implements bitcoin's hash160 (rmd160(sha2()))
    /// @param memView   The pre-image
    /// @return          The digest
    function hash160(bytes29 memView) internal view returns (bytes20 digest) {
        uint256 _loc = loc(memView);
        uint256 _len = len(memView);
        assembly {
            // solium-disable-previous-line security/no-inline-assembly
            let ptr := mload(0x40)
            pop(staticcall(gas, 2, _loc, _len, ptr, 0x20)) // sha2
            pop(staticcall(gas, 3, ptr, 0x20, ptr, 0x20)) // rmd160
            digest := mload(add(ptr, 0xc)) // return value is 0-prefixed.
        }
    }

    /// @notice          Implements bitcoin's hash256 (double sha2)
    /// @param memView   A view of the preimage
    /// @return          The digest
    function hash256(bytes29 memView) internal view returns (bytes32 digest) {
        uint256 _loc = loc(memView);
        uint256 _len = len(memView);
        assembly {
            // solium-disable-previous-line security/no-inline-assembly
            let ptr := mload(0x40)
            pop(staticcall(gas, 2, _loc, _len, ptr, 0x20)) // sha2 #1
            pop(staticcall(gas, 2, ptr, 0x20, ptr, 0x20)) // sha2 #2
            digest := mload(ptr)
        }
    }

    /// Return true if the underlying memory is equal. Else false.
    function untypedEqual(bytes29 left, bytes29 right) internal pure returns (bool) {
        return (loc(left) == loc(right) && len(left) == len(right)) || keccak(left) == keccak(right);
    }

    /// Return false if the underlying memory is equal. Else true.
    function untypedNotEqual(bytes29 left, bytes29 right) internal pure returns (bool) {
        return !untypedEqual(left, right);
    }

    /// Typed equality. Shortcuts if the pointers are identical, otherwise
    /// compares type and digest
    function equal(bytes29 left, bytes29 right) internal pure returns (bool) {
        return left == right || (typeOf(left) == typeOf(right) && keccak(left) == keccak(right));
    }

    /// Typed inequality. Shortcuts if the pointers are identical, otherwise
    /// compares type and digest
    function notEqual(bytes29 left, bytes29 right) internal pure returns (bool) {
        return !equal(left, right);
    }

    /// Copy the view to a location, return an unsafe memory reference
    ///
    /// Super Dangerous direct memory access.
    /// This reference can be overwritten if anything else modifies memory (!!!).
    /// As such it MUST be consumed IMMEDIATELY.
    /// This function is private to prevent unsafe usage by callers
    function copyTo(bytes29 memView, uint256 _newLoc) private view returns (bytes29 written) {
        require(notNull(memView), "TypedMemView/copyTo - Null pointer deref");
        require(isValid(memView), "TypedMemView/copyTo - Invalid pointer deref");
        uint256 _len = len(memView);
        uint256 _oldLoc = loc(memView);

        uint256 ptr;
        assembly {
            // solium-disable-previous-line security/no-inline-assembly
            ptr := mload(0x40)
            // revert if we're writing in occupied memory
            if gt(ptr, _newLoc) {
                revert(0x60, 0x20) // empty revert message
            }

            // use the identity precompile to copy
            // guaranteed not to fail, so pop the success
            pop(staticcall(gas, 4, _oldLoc, _len, _newLoc, _len))
        }

        written = buildUnchecked(typeOf(memView), _newLoc, _len);
    }

    /// Copies the referenced memory to a new loc in memory, returning a
    /// `bytes` pointing to the new memory
    function clone(bytes29 memView) internal view returns (bytes memory ret) {
        uint256 ptr;
        uint256 _len = len(memView);
        assembly {
            // solium-disable-previous-line security/no-inline-assembly
            ptr := mload(0x40) // load unused memory pointer
            ret := ptr
        }
        copyTo(memView, ptr + 0x20);
        assembly {
            // solium-disable-previous-line security/no-inline-assembly
            mstore(0x40, add(add(ptr, _len), 0x20)) // write new unused pointer
            mstore(ptr, _len) // write len of new array (in bytes)
        }
    }

    /// Join the views in memory, return an unsafe reference to the memory.
    ///
    /// Super Dangerous direct memory access.
    /// This reference can be overwritten if anything else modifies memory (!!!).
    /// As such it MUST be consumed IMMEDIATELY.
    /// This function is private to prevent unsafe usage by callers
    function unsafeJoin(bytes29[] memory memViews, uint256 _location) private view returns (bytes29 unsafeView) {
        assembly {
            // solium-disable-previous-line security/no-inline-assembly
            let ptr := mload(0x40)
            // revert if we're writing in occupied memory
            if gt(ptr, _location) {
                revert(0x60, 0x20) // empty revert message
            }
        }

        uint256 _offset = 0;
        for (uint256 i = 0; i < memViews.length; i ++) {
            bytes29 memView = memViews[i];
            copyTo(memView, _location + _offset);
            _offset += len(memView);
        }
        unsafeView = buildUnchecked(0, _location, _offset);
    }

    /// Produce the keccak256 digest of the concatenated contents of multiple views
    function joinKeccak(bytes29[] memory memViews) internal view returns (bytes32) {
        uint256 ptr;
        assembly {
            // solium-disable-previous-line security/no-inline-assembly
            ptr := mload(0x40) // load unused memory pointer
        }
        return keccak(unsafeJoin(memViews, ptr));
    }

    /// Produce the sha256 digest of the concatenated contents of multiple views
    function joinSha2(bytes29[] memory memViews) internal view returns (bytes32) {
        uint256 ptr;
        assembly {
            // solium-disable-previous-line security/no-inline-assembly
            ptr := mload(0x40) // load unused memory pointer
        }
        return sha2(unsafeJoin(memViews, ptr));
    }

    /// copies all views, joins them into a new bytearray
    function join(bytes29[] memory memViews) internal view returns (bytes memory ret) {
        uint256 ptr;
        assembly {
            // solium-disable-previous-line security/no-inline-assembly
            ptr := mload(0x40) // load unused memory pointer
        }

        bytes29 _newView = unsafeJoin(memViews, ptr + 0x20);
        uint256 _written = len(_newView);
        uint256 _footprint = footprint(_newView);

        assembly {
            // solium-disable-previous-line security/no-inline-assembly
            // store the legnth
            mstore(ptr, _written)
            // new pointer is old + 0x20 + the footprint of the body
            mstore(0x40, add(add(ptr, _footprint), 0x20))
            ret := ptr
        }
    }
}

// File: @summa-tx/bitcoin-spv-sol/contracts/ViewBTC.sol

pragma solidity ^0.5.10;

/** @title BitcoinSPV */
/** @author Summa (https://summa.one) */



library ViewBTC {
    using TypedMemView for bytes29;
    using SafeMath for uint256;

    // The target at minimum Difficulty. Also the target of the genesis block
    uint256 public constant DIFF1_TARGET = 0xffff0000000000000000000000000000000000000000000000000000;

    uint256 public constant RETARGET_PERIOD = 2 * 7 * 24 * 60 * 60;  // 2 weeks in seconds
    uint256 public constant RETARGET_PERIOD_BLOCKS = 2016;  // 2 weeks in blocks

    enum BTCTypes {
        Unknown,            // 0x0
        CompactInt,         // 0x1
        ScriptSig,          // 0x2 - with length prefix
        Outpoint,           // 0x3
        TxIn,               // 0x4
        IntermediateTxIns,  // 0x5 - used in vin parsing
        Vin,                // 0x6
        ScriptPubkey,       // 0x7 - with length prefix
        PKH,                // 0x8 - the 20-byte payload digest
        WPKH,               // 0x9 - the 20-byte payload digest
        WSH,                // 0xa - the 32-byte payload digest
        SH,                 // 0xb - the 20-byte payload digest
        OpReturnPayload,    // 0xc
        TxOut,              // 0xd
        IntermediateTxOuts, // 0xe - used in vout parsing
        Vout,               // 0xf
        Header,             // 0x10
        HeaderArray,        // 0x11
        MerkleNode,         // 0x12
        MerkleStep,         // 0x13
        MerkleArray         // 0x14
    }

    // TODO: any way to bubble up more info?
    /// @notice             requires `memView` to be of a specified type
    /// @param memView      a 29-byte view with a 5-byte type
    /// @param t            the expected type (e.g. BTCTypes.Outpoint, BTCTypes.TxIn, etc)
    /// @return             passes if it is the correct type, errors if not
    modifier typeAssert(bytes29 memView, BTCTypes t) {
        memView.assertType(uint40(t));
        _;
    }

    /// Revert with an error message re: non-minimal VarInts
    function revertNonMinimal(bytes29 ref) private pure returns (string memory) {
        (, uint256 g) = TypedMemView.encodeHex(ref.indexUint(0, uint8(ref.len())));
        string memory err = string(
            abi.encodePacked(
                "Non-minimal var int. Got 0x",
                uint144(g)
            )
        );
        revert(err);
    }

    /// @notice             reads a compact int from the view at the specified index
    /// @param memView      a 29-byte view with a 5-byte type
    /// @param _index       the index
    /// @return             the compact int at the specified index
    function indexCompactInt(bytes29 memView, uint256 _index) internal pure returns (uint64 number) {
        uint256 flag = memView.indexUint(_index, 1);
        if (flag <= 0xfc) {
            return uint64(flag);
        } else if (flag == 0xfd) {
            number = uint64(memView.indexLEUint(_index + 1, 2));
            if (compactIntLength(number) != 3) {revertNonMinimal(memView.slice(_index, 3, 0));}
        } else if (flag == 0xfe) {
            number = uint64(memView.indexLEUint(_index + 1, 4));
            if (compactIntLength(number) != 5) {revertNonMinimal(memView.slice(_index, 5, 0));}
        } else if (flag == 0xff) {
            number = uint64(memView.indexLEUint(_index + 1, 8));
            if (compactIntLength(number) != 9) {revertNonMinimal(memView.slice(_index, 9, 0));}
        }
    }

    /// @notice         gives the total length (in bytes) of a CompactInt-encoded number
    /// @param number   the number as uint64
    /// @return         the compact integer as uint8
    function compactIntLength(uint64 number) internal pure returns (uint8) {
        if (number <= 0xfc) {
            return 1;
        } else if (number <= 0xffff) {
            return 3;
        } else if (number <= 0xffffffff) {
            return 5;
        } else {
            return 9;
        }
    }

    /// @notice             extracts the LE txid from an outpoint
    /// @param _outpoint    the outpoint
    /// @return             the LE txid
    function txidLE(bytes29 _outpoint) internal pure typeAssert(_outpoint, BTCTypes.Outpoint) returns (bytes32) {
        return _outpoint.index(0, 32);
    }

    /// @notice             extracts the index as an integer from the outpoint
    /// @param _outpoint    the outpoint
    /// @return             the index
    function outpointIdx(bytes29 _outpoint) internal pure typeAssert(_outpoint, BTCTypes.Outpoint) returns (uint32) {
        return uint32(_outpoint.indexLEUint(32, 4));
    }

    /// @notice          extracts the outpoint from an input
    /// @param _input    the input
    /// @return          the outpoint as a typed memory
    function outpoint(bytes29 _input) internal pure typeAssert(_input, BTCTypes.TxIn) returns (bytes29) {
        return _input.slice(0, 36, uint40(BTCTypes.Outpoint));
    }

    /// @notice           extracts the script sig from an input
    /// @param _input     the input
    /// @return           the script sig as a typed memory
    function scriptSig(bytes29 _input) internal pure typeAssert(_input, BTCTypes.TxIn) returns (bytes29) {
        uint64 scriptLength = indexCompactInt(_input, 36);
        return _input.slice(36, compactIntLength(scriptLength) + scriptLength, uint40(BTCTypes.ScriptSig));
    }

    /// @notice         extracts the sequence from an input
    /// @param _input   the input
    /// @return         the sequence
    function sequence(bytes29 _input) internal pure typeAssert(_input, BTCTypes.TxIn) returns (uint32) {
        uint64 scriptLength = indexCompactInt(_input, 36);
        uint256 scriptEnd = 36 + compactIntLength(scriptLength) + scriptLength;
        return uint32(_input.indexLEUint(scriptEnd, 4));
    }

    /// @notice         determines the length of the first input in an array of inputs
    /// @param _inputs  the vin without its length prefix
    /// @return         the input length
    function inputLength(bytes29 _inputs) internal pure typeAssert(_inputs, BTCTypes.IntermediateTxIns) returns (uint256) {
        uint64 scriptLength = indexCompactInt(_inputs, 36);
        return uint256(compactIntLength(scriptLength)) + uint256(scriptLength) + 36 + 4;
    }

    /// @notice         extracts the input at a specified index
    /// @param _vin     the vin
    /// @param _index   the index of the desired input
    /// @return         the desired input
    function indexVin(bytes29 _vin, uint256 _index) internal pure typeAssert(_vin, BTCTypes.Vin) returns (bytes29) {
        uint256 _nIns = uint256(indexCompactInt(_vin, 0));
        uint256 _viewLen = _vin.len();
        require(_index < _nIns, "Vin read overrun");

        uint256 _offset = uint256(compactIntLength(uint64(_nIns)));
        bytes29 _remaining;
        for (uint256 _i = 0; _i < _index; _i += 1) {
            _remaining = _vin.postfix(_viewLen.sub(_offset), uint40(BTCTypes.IntermediateTxIns));
            _offset += inputLength(_remaining);
        }

        _remaining = _vin.postfix(_viewLen.sub(_offset), uint40(BTCTypes.IntermediateTxIns));
        uint256 _len = inputLength(_remaining);
        return _vin.slice(_offset, _len, uint40(BTCTypes.TxIn));
    }

    /// @notice         extracts the raw LE bytes of the output value
    /// @param _output  the output
    /// @return         the raw LE bytes of the output value
    function valueBytes(bytes29 _output) internal pure typeAssert(_output, BTCTypes.TxOut) returns (bytes8) {
        return bytes8(_output.index(0, 8));
    }

    /// @notice         extracts the value from an output
    /// @param _output  the output
    /// @return         the value
    function value(bytes29 _output) internal pure typeAssert(_output, BTCTypes.TxOut) returns (uint64) {
        return uint64(_output.indexLEUint(0, 8));
    }

    /// @notice             extracts the scriptPubkey from an output
    /// @param _output      the output
    /// @return             the scriptPubkey
    function scriptPubkey(bytes29 _output) internal pure typeAssert(_output, BTCTypes.TxOut) returns (bytes29) {
        uint64 scriptLength = indexCompactInt(_output, 8);
        return _output.slice(8, compactIntLength(scriptLength) + scriptLength, uint40(BTCTypes.ScriptPubkey));
    }

    /// @notice             determines the length of the first output in an array of outputs
    /// @param _outputs     the vout without its length prefix
    /// @return             the output length
    function outputLength(bytes29 _outputs) internal pure typeAssert(_outputs, BTCTypes.IntermediateTxOuts) returns (uint256) {
        uint64 scriptLength = indexCompactInt(_outputs, 8);
        return uint256(compactIntLength(scriptLength)) + uint256(scriptLength) + 8;
    }

    /// @notice         extracts the output at a specified index
    /// @param _vout    the vout
    /// @param _index   the index of the desired output
    /// @return         the desired output
    function indexVout(bytes29 _vout, uint256 _index) internal pure typeAssert(_vout, BTCTypes.Vout) returns (bytes29) {
        uint256 _nOuts = uint256(indexCompactInt(_vout, 0));
        uint256 _viewLen = _vout.len();
        require(_index < _nOuts, "Vout read overrun");

        uint256 _offset = uint256(compactIntLength(uint64(_nOuts)));
        bytes29 _remaining;
        for (uint256 _i = 0; _i < _index; _i += 1) {
            _remaining = _vout.postfix(_viewLen - _offset, uint40(BTCTypes.IntermediateTxOuts));
            _offset += outputLength(_remaining);
        }

        _remaining = _vout.postfix(_viewLen - _offset, uint40(BTCTypes.IntermediateTxOuts));
        uint256 _len = outputLength(_remaining);
        return _vout.slice(_offset, _len, uint40(BTCTypes.TxOut));
    }

    /// @notice         extracts the Op Return Payload
    /// @param _spk     the scriptPubkey
    /// @return         the Op Return Payload (or null if not a valid Op Return output)
    function opReturnPayload(bytes29 _spk) internal pure typeAssert(_spk, BTCTypes.ScriptPubkey) returns (bytes29) {
        uint64 _bodyLength = indexCompactInt(_spk, 0);
        uint64 _payloadLen = uint64(_spk.indexUint(2, 1));
        if (_bodyLength > 77 || _bodyLength < 4 || _spk.indexUint(1, 1) != 0x6a || _spk.indexUint(2, 1) != _bodyLength - 2) {
            return TypedMemView.nullView();
        }
        return _spk.slice(3, _payloadLen, uint40(BTCTypes.OpReturnPayload));
    }

    /// @notice         extracts the payload from a scriptPubkey
    /// @param _spk     the scriptPubkey
    /// @return         the payload (or null if not a valid PKH, SH, WPKH, or WSH output)
    function payload(bytes29 _spk) internal pure typeAssert(_spk, BTCTypes.ScriptPubkey) returns (bytes29) {
        uint256 _spkLength = _spk.len();
        uint256 _bodyLength = indexCompactInt(_spk, 0);
        if (_bodyLength > 0x22 || _bodyLength < 0x16 || _bodyLength + 1 != _spkLength) {
            return TypedMemView.nullView();
        }

        // Legacy
        if (_bodyLength == 0x19 && _spk.indexUint(0, 4) == 0x1976a914 && _spk.indexUint(_spkLength - 2, 2) == 0x88ac) {
            return _spk.slice(4, 20, uint40(BTCTypes.PKH));
        } else if (_bodyLength == 0x17 && _spk.indexUint(0, 3) == 0x17a914 && _spk.indexUint(_spkLength - 1, 1) == 0x87) {
            return _spk.slice(3, 20, uint40(BTCTypes.SH));
        }

        // Witness v0
        if (_spk.indexUint(1, 1) == 0) {
            uint256 _payloadLen = _spk.indexUint(2, 1);
            if (_bodyLength != 0x22 && _bodyLength != 0x16 || _payloadLen != _bodyLength - 2) {
                return TypedMemView.nullView();
            }
            uint40 newType = uint40(_payloadLen == 0x20 ? BTCTypes.WSH : BTCTypes.WPKH);
            return _spk.slice(3, _payloadLen, newType);
        }

        return TypedMemView.nullView();
    }

    /// @notice     (loosely) verifies an spk and converts to a typed memory
    /// @dev        will return null in error cases. Will not check for disabled opcodes.
    /// @param _spk the spk
    /// @return     the typed spk (or null if error)
    function tryAsSPK(bytes29 _spk) internal pure typeAssert(_spk, BTCTypes.Unknown) returns (bytes29) {
        if (_spk.len() == 0) {
            return TypedMemView.nullView();
        }
        uint64 _len = indexCompactInt(_spk, 0);
        if (_spk.len() == compactIntLength(_len) + _len) {
            return _spk.castTo(uint40(BTCTypes.ScriptPubkey));
        } else {
            return TypedMemView.nullView();
        }
    }

    /// @notice     verifies the vin and converts to a typed memory
    /// @dev        will return null in error cases
    /// @param _vin the vin
    /// @return     the typed vin (or null if error)
    function tryAsVin(bytes29 _vin) internal pure typeAssert(_vin, BTCTypes.Unknown) returns (bytes29) {
        if (_vin.len() == 0) {
            return TypedMemView.nullView();
        }
        uint64 _nIns = indexCompactInt(_vin, 0);
        uint256 _viewLen = _vin.len();
        if (_nIns == 0) {
            return TypedMemView.nullView();
        }

        uint256 _offset = uint256(compactIntLength(_nIns));
        for (uint256 i = 0; i < _nIns; i++) {
            if (_offset >= _viewLen) {
                // We've reached the end, but are still trying to read more
                return TypedMemView.nullView();
            }
            bytes29 _remaining = _vin.postfix(_viewLen - _offset, uint40(BTCTypes.IntermediateTxIns));
            _offset += inputLength(_remaining);
        }
        if (_offset != _viewLen) {
            return TypedMemView.nullView();
        }
        return _vin.castTo(uint40(BTCTypes.Vin));
    }

    /// @notice         verifies the vout and converts to a typed memory
    /// @dev            will return null in error cases
    /// @param _vout    the vout
    /// @return         the typed vout (or null if error)
    function tryAsVout(bytes29 _vout) internal pure typeAssert(_vout, BTCTypes.Unknown) returns (bytes29) {
        if (_vout.len() == 0) {
            return TypedMemView.nullView();
        }
        uint64 _nOuts = indexCompactInt(_vout, 0);
        uint256 _viewLen = _vout.len();
        if (_nOuts == 0) {
            return TypedMemView.nullView();
        }

        uint256 _offset = uint256(compactIntLength(_nOuts));
        for (uint256 i = 0; i < _nOuts; i++) {
            if (_offset >= _viewLen) {
                // We've reached the end, but are still trying to read more
                return TypedMemView.nullView();
            }
            bytes29 _remaining = _vout.postfix(_viewLen - _offset, uint40(BTCTypes.IntermediateTxOuts));
            _offset += outputLength(_remaining);
        }
        if (_offset != _viewLen) {
            return TypedMemView.nullView();
        }
        return _vout.castTo(uint40(BTCTypes.Vout));
    }

    /// @notice         verifies the header and converts to a typed memory
    /// @dev            will return null in error cases
    /// @param _header  the header
    /// @return         the typed header (or null if error)
    function tryAsHeader(bytes29 _header) internal pure typeAssert(_header, BTCTypes.Unknown) returns (bytes29) {
        if (_header.len() != 80) {
            return TypedMemView.nullView();
        }
        return _header.castTo(uint40(BTCTypes.Header));
    }


    /// @notice         Index a header array.
    /// @dev            Errors on overruns
    /// @param _arr     The header array
    /// @param index    The 0-indexed location of the header to get
    /// @return         the typed header at `index`
    function indexHeaderArray(bytes29 _arr, uint256 index) internal pure typeAssert(_arr, BTCTypes.HeaderArray) returns (bytes29) {
        uint256 _start = index.mul(80);
        return _arr.slice(_start, 80, uint40(BTCTypes.Header));
    }


    /// @notice     verifies the header array and converts to a typed memory
    /// @dev        will return null in error cases
    /// @param _arr the header array
    /// @return     the typed header array (or null if error)
    function tryAsHeaderArray(bytes29 _arr) internal pure typeAssert(_arr, BTCTypes.Unknown) returns (bytes29) {
        if (_arr.len() % 80 != 0) {
            return TypedMemView.nullView();
        }
        return _arr.castTo(uint40(BTCTypes.HeaderArray));
    }

    /// @notice     verifies the merkle array and converts to a typed memory
    /// @dev        will return null in error cases
    /// @param _arr the merkle array
    /// @return     the typed merkle array (or null if error)
    function tryAsMerkleArray(bytes29 _arr) internal pure typeAssert(_arr, BTCTypes.Unknown) returns (bytes29) {
        if (_arr.len() % 32 != 0) {
            return TypedMemView.nullView();
        }
        return _arr.castTo(uint40(BTCTypes.MerkleArray));
    }

    /// @notice         extracts the merkle root from the header
    /// @param _header  the header
    /// @return         the merkle root
    function merkleRoot(bytes29 _header) internal pure typeAssert(_header, BTCTypes.Header) returns (bytes32) {
        return _header.index(36, 32);
    }

    /// @notice         extracts the target from the header
    /// @param _header  the header
    /// @return         the target
    function target(bytes29  _header) internal pure typeAssert(_header, BTCTypes.Header) returns (uint256) {
        uint256 _mantissa = _header.indexLEUint(72, 3);
        uint256 _exponent = _header.indexUint(75, 1).sub(3);
        return _mantissa.mul(256 ** _exponent);
    }

    /// @notice         calculates the difficulty from a target
    /// @param _target  the target
    /// @return         the difficulty
    function toDiff(uint256  _target) internal pure returns (uint256) {
        return DIFF1_TARGET.div(_target);
    }

    /// @notice         extracts the difficulty from the header
    /// @param _header  the header
    /// @return         the difficulty
    function diff(bytes29  _header) internal pure typeAssert(_header, BTCTypes.Header) returns (uint256) {
        return toDiff(target(_header));
    }

    /// @notice         extracts the timestamp from the header
    /// @param _header  the header
    /// @return         the timestamp
    function time(bytes29  _header) internal pure typeAssert(_header, BTCTypes.Header) returns (uint32) {
        return uint32(_header.indexLEUint(68, 4));
    }

    /// @notice         extracts the parent hash from the header
    /// @param _header  the header
    /// @return         the parent hash
    function parent(bytes29 _header) internal pure typeAssert(_header, BTCTypes.Header) returns (bytes32) {
        return _header.index(4, 32);
    }

    /// @notice         calculates the Proof of Work hash of the header
    /// @param _header  the header
    /// @return         the Proof of Work hash
    function workHash(bytes29 _header) internal view typeAssert(_header, BTCTypes.Header) returns (bytes32) {
        return _header.hash256();
    }

    /// @notice         calculates the Proof of Work hash of the header, and converts to an integer
    /// @param _header  the header
    /// @return         the Proof of Work hash as an integer
    function work(bytes29 _header) internal view typeAssert(_header, BTCTypes.Header) returns (uint256) {
        return TypedMemView.reverseUint256(uint256(workHash(_header)));
    }

    /// @notice          Concatenates and hashes two inputs for merkle proving
    /// @dev             Not recommended to call directly.
    /// @param _a        The first hash
    /// @param _b        The second hash
    /// @return          The double-sha256 of the concatenated hashes
    function _merkleStep(bytes32 _a, bytes32 _b) internal view returns (bytes32 digest) {
        assembly {
            // solium-disable-previous-line security/no-inline-assembly
            let ptr := mload(0x40)
            mstore(ptr, _a)
            mstore(add(ptr, 0x20), _b)
            pop(staticcall(gas, 2, ptr, 0x40, ptr, 0x20)) // sha2 #1
            pop(staticcall(gas, 2, ptr, 0x20, ptr, 0x20)) // sha2 #2
            digest := mload(ptr)
        }
    }

    /// @notice         verifies a merkle proof
    /// @param _leaf    the leaf
    /// @param _proof   the merkle proof
    /// @param _root    the merkle root
    /// @param _index   the index
    /// @return         true if valid, false if otherwise
    function checkMerkle(
        bytes32 _leaf,
        bytes29 _proof,
        bytes32 _root,
        uint256 _index
    ) internal view typeAssert(_proof, BTCTypes.MerkleArray) returns (bool) {
        uint256 nodes = _proof.len() / 32;
        if (nodes == 0) {
            return _leaf == _root;
        }

        uint256 _idx = _index;
        bytes32 _current = _leaf;

        for (uint i = 0; i < nodes; i++) {
            bytes32 _next = _proof.index(i * 32, 32);
            if (_idx % 2 == 1) {
                _current = _merkleStep(_next, _current);
            } else {
                _current = _merkleStep(_current, _next);
            }
            _idx >>= 1;
        }

        return _current == _root;
    }

    /// @notice                 performs the bitcoin difficulty retarget
    /// @dev                    implements the Bitcoin algorithm precisely
    /// @param _previousTarget  the target of the previous period
    /// @param _firstTimestamp  the timestamp of the first block in the difficulty period
    /// @param _secondTimestamp the timestamp of the last block in the difficulty period
    /// @return                 the new period's target threshold
    function retargetAlgorithm(
        uint256 _previousTarget,
        uint256 _firstTimestamp,
        uint256 _secondTimestamp
    ) internal pure returns (uint256) {
        uint256 _elapsedTime = _secondTimestamp.sub(_firstTimestamp);

        // Normalize ratio to factor of 4 if very long or very short
        if (_elapsedTime < RETARGET_PERIOD.div(4)) {
            _elapsedTime = RETARGET_PERIOD.div(4);
        }
        if (_elapsedTime > RETARGET_PERIOD.mul(4)) {
            _elapsedTime = RETARGET_PERIOD.mul(4);
        }

        /*
            NB: high targets e.g. ffff0020 can cause overflows here
                so we divide it by 256**2, then multiply by 256**2 later
                we know the target is evenly divisible by 256**2, so this isn't an issue
        */
        uint256 _adjusted = _previousTarget.div(65536).mul(_elapsedTime);
        return _adjusted.div(RETARGET_PERIOD).mul(65536);
    }
}

// File: @summa-tx/bitcoin-spv-sol/contracts/ViewSPV.sol

pragma solidity ^0.5.10;

/** @title ViewSPV */
/** @author Summa (https://summa.one) */





library ViewSPV {
    using TypedMemView for bytes;
    using TypedMemView for bytes29;
    using ViewBTC for bytes29;
    using SafeMath for uint256;

    uint256 constant ERR_BAD_LENGTH = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    uint256 constant ERR_INVALID_CHAIN = 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe;
    uint256 constant ERR_LOW_WORK = 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffd;

    function getErrBadLength() internal pure returns (uint256) {
        return ERR_BAD_LENGTH;
    }

    function getErrInvalidChain() internal pure returns (uint256) {
        return ERR_INVALID_CHAIN;
    }

    function getErrLowWork() internal pure returns (uint256) {
        return ERR_LOW_WORK;
    }

    /// @notice             requires `memView` to be of a specified type
    /// @param memView      a 29-byte view with a 5-byte type
    /// @param t            the expected type (e.g. BTCTypes.Outpoint, BTCTypes.TxIn, etc)
    /// @return             passes if it is the correct type, errors if not
    modifier typeAssert(bytes29 memView, ViewBTC.BTCTypes t) {
        memView.assertType(uint40(t));
        _;
    }

    /// @notice                     Validates a tx inclusion in the block
    /// @dev                        `index` is not a reliable indicator of location within a block
    /// @param _txid                The txid (LE)
    /// @param _merkleRoot          The merkle root (as in the block header)
    /// @param _intermediateNodes   The proof's intermediate nodes (digests between leaf and root)
    /// @param _index               The leaf's index in the tree (0-indexed)
    /// @return                     true if fully valid, false otherwise
    function prove(
        bytes32 _txid,
        bytes32 _merkleRoot,
        bytes29 _intermediateNodes,
        uint _index
    ) internal view typeAssert(_intermediateNodes, ViewBTC.BTCTypes.MerkleArray) returns (bool) {
        // Shortcut the empty-block case
        if (_txid == _merkleRoot && _index == 0 && _intermediateNodes.len() == 0) {
            return true;
        }

        return ViewBTC.checkMerkle(_txid, _intermediateNodes, _merkleRoot, _index);
    }

    /// @notice             Hashes transaction to get txid
    /// @dev                Supports Legacy and Witness
    /// @param _version     4-bytes version
    /// @param _vin         Raw bytes length-prefixed input vector
    /// @param _vout        Raw bytes length-prefixed output vector
    /// @param _locktime    4-byte tx locktime
    /// @return             32-byte transaction id, little endian
    function calculateTxId(
        bytes4 _version,
        bytes29 _vin,
        bytes29 _vout,
        bytes4 _locktime
    ) internal view typeAssert(_vin, ViewBTC.BTCTypes.Vin) typeAssert(_vout, ViewBTC.BTCTypes.Vout) returns (bytes32) {
        // TODO: write in assembly
        return abi.encodePacked(_version, _vin.clone(), _vout.clone(), _locktime).ref(0).hash256();
    }

    // TODO: add test for checkWork
    /// @notice             Checks validity of header work
    /// @param _header      Header view
    /// @param _target      The target threshold
    /// @return             true if header work is valid, false otherwise
    function checkWork(bytes29 _header, uint256 _target) internal view typeAssert(_header, ViewBTC.BTCTypes.Header) returns (bool) {
        return _header.work() < _target;
    }


    /// @notice                     Checks validity of header chain
    /// @dev                        Compares current header parent to previous header's digest
    /// @param _header              The raw bytes header
    /// @param _prevHeaderDigest    The previous header's digest
    /// @return                     true if the connect is valid, false otherwise
    function checkParent(bytes29 _header, bytes32 _prevHeaderDigest) internal pure typeAssert(_header, ViewBTC.BTCTypes.Header) returns (bool) {
        return _header.parent() == _prevHeaderDigest;
    }

    /// @notice             Checks validity of header chain
    /// @notice             Compares the hash of each header to the prevHash in the next header
    /// @param _headers     Raw byte array of header chain
    /// @return             The total accumulated difficulty of the header chain, or an error code
    function checkChain(bytes29 _headers) internal view typeAssert(_headers, ViewBTC.BTCTypes.HeaderArray) returns (uint256 _totalDifficulty) {
        bytes32 _digest;
        uint256 _headerCount = _headers.len() / 80;
        for (uint256 i = 0; i < _headerCount; i += 1) {
            bytes29 _header = _headers.indexHeaderArray(i);
            if (i != 0) {
                if (!checkParent(_header, _digest)) {return ERR_INVALID_CHAIN;}
            }
            _digest = _header.workHash();
            uint256 _work = TypedMemView.reverseUint256(uint256(_digest));
            uint256 _target = _header.target();

            if (_work > _target) {return ERR_LOW_WORK;}

            _totalDifficulty += ViewBTC.toDiff(_target);
        }
    }
}

// File: contracts/Interfaces.sol

pragma solidity ^0.5.10;

/// @title      ISPVConsumer
/// @author     Summa (https://summa.one)
/// @notice     This interface consumes validated transaction information.
///             It is the primary way that user contracts accept
/// @dev        Implement this interface to process transactions provided by
///             the Relay system.
interface ISPVConsumer {
    /// @notice     A consumer for Bitcoin transaction information.
    /// @dev        Users must implement this function. It handles Bitcoin
    ///             events that have been validated by the Relay contract.
    ///             It is VERY IMPORTANT that this function validates the
    ///             msg.sender. The callee must check the origin of the data
    ///             or risk accepting spurious information.
    /// @param _txid        The LE(!) txid of the bitcoin transaction that
    ///                     triggered the notification.
    /// @param _vin         The length-prefixed input vector of the bitcoin tx
    ///                     that triggered the notification.
    /// @param _vout        The length-prefixed output vector of the bitcoin tx
    ///                     that triggered the notification.
    /// @param _requestID   The ID of the event request that this notification
    ///                     satisfies. The ID is returned by
    ///                     OnDemandSPV.request and should be locally stored by
    ///                     any contract that makes more than one request.
    /// @param _inputIndex  The index of the input in the _vin that triggered
    ///                     the notification.
    /// @param _outputIndex The index of the output in the _vout that triggered
    ///                     the notification. Useful for subscribing to transactions
    ///                     that spend the newly-created UTXO.
    function spv(
        bytes32 _txid,
        bytes calldata _vin,
        bytes calldata _vout,
        uint256 _requestID,
        uint8 _inputIndex,
        uint8 _outputIndex) external;
}

/// @title      ISPVRequestManager
/// @author     Summa (https://summa.one)
/// @notice     The interface for using the OnDemandSPV system. This interface
///             allows you to subscribe to Bitcoin events.
/// @dev        Manage subscriptions to Bitcoin events. Register callbacks to
///             be called whenever specific Bitcoin transactions are made.
interface ISPVRequestManager {
    event NewProofRequest (
        address indexed _requester,
        uint256 indexed _requestID,
        uint64 _paysValue,
        bytes _spends,
        bytes _pays
    );

    event RequestClosed(uint256 indexed _requestID);
    event RequestFilled(bytes32 indexed _txid, uint256 indexed _requestID);

    /// @notice             Subscribe to a feed of Bitcoin transactions matching a request
    /// @dev                The request can be a spent utxo and/or a created utxo.
    ///
    ///                     The contract allows users to register a "consumer" contract
    ///                     that implements ISPVConsumer to handle Bitcoin events.
    ///
    ///                     Bitcoin transactions are composed of a vector of inputs,
    ///                     and a vector of outputs. The `_spends` parameter allows consumers
    ///                     to watch a specific UTXO, and receive an event when it is spent.
    ///
    ///                     The `_pays` and `_paysValue` param allow the user to watch specific
    ///                     Bitcoin output scripts. An output script is typically encoded
    ///                     as an address, but an address is not an in-protocol construction.
    ///                     In other words, consumers will receive an event whenever a specific
    ///                     address receives funds, or when a specific OP_RETURN is created.
    ///
    ///                     Either `_spends` or `_pays` MUST be set. Both MAY be set.
    ///                     If both are set, only notifications meeting both criteria
    ///                     will be triggered.
    ///
    /// @param  _spends     An outpoint that must be spent in acceptable transactions.
    ///                     The outpoint must be exactly 36 bytes, and composed of a
    ///                     LE txid (32 bytes), and an 4-byte LE-encoded index integer.
    ///                     In other words, the precise serialization format used in a
    ///                     serialized Bitcoin TxIn.
    ///
    ///                     Note that while we might expect a `_spends` event to fire at most
    ///                     one time, that expectation becomes invalid in long Bitcoin reorgs
    ///                     if there is a double-spend or a disconfirmation followed by
    ///                     reconfirmation.
    ///
    /// @param  _pays       An output script to watch for events. A filter with `_pays` set will
    ///                     validate any number of events that create new UTXOs with a specific
    ///                     output script.
    ///
    ///                     This is useful for watching an address and responding to incoming
    ///                     payments.
    ///
    /// @param  _paysValue  A minimum value in satoshi that must be paid to the output script.
    ///                     If this is set no any non-0 number, the Relay will only forward
    ///                     `_pays` notifications to the consumer if the value of the new UTXO is
    ///                     at least `_paysValue`.
    ///
    /// @param  _consumer   The address of a contract that implements the `ISPVConsumer` interface.
    ///                     Whenever events are available, the Relay will validate inclusion
    ///                     and confirmation, then call the `spv` function on the consumer.
    ///
    /// @param  _numConfs   The number of headers that must confirm the block
    ///                     containing the transaction. Used as a security parameter.
    ///                     More confirmations means less likely to revert due to a
    ///                     chain reorganization. Note that 1 confirmation is required,
    ///                     so the general "6 confirmation" rule would be expressed
    ///                     as `5` when calling this function
    ///
    /// @param  _notBefore  An Ethereum timestamp before which proofs will not be accepted.
    ///                     Used to control app flow for specific users.
    ///
    /// @return             A unique request ID.
    function request(
        bytes calldata _spends,
        bytes calldata _pays,
        uint64 _paysValue,
        address _consumer,
        uint8 _numConfs,
        uint256 _notBefore
    ) external returns (uint256);

    /// @notice                 Cancel an active bitcoin event request.
    /// @dev                    Prevents the relay from forwarding tx information
    /// @param  _requestID      The ID of the request to be cancelled
    /// @return                 True if succesful, error otherwise
    function cancelRequest(uint256 _requestID) external returns (bool);

    /// @notice             Retrieve info about a request
    /// @dev                Requests ids are numerical
    /// @param  _requestID  The numerical ID of the request
    /// @return             A tuple representation of the request struct.
    ///                     To save space`spends` and `pays` are stored as keccak256
    ///                     hashes of the original information. The `state` is
    ///                     `0` for "does not exist", `1` for "active" and `2` for
    ///                     "cancelled."
    function getRequest(
        uint256 _requestID
    ) external view returns (
        bytes32 spends,
        bytes32 pays,
        uint64 paysValue,
        uint8 state,
        address consumer,
        address owner,
        uint8 numConfs,
        uint256 notBefore
    );
}



interface IRelay {
    event Extension(bytes32 indexed _first, bytes32 indexed _last);
    event NewTip(bytes32 indexed _from, bytes32 indexed _to, bytes32 indexed _gcd);

    function getRelayGenesis() external view returns (bytes32);
    function getBestKnownDigest() external view returns (bytes32);
    function getLastReorgCommonAncestor() external view returns (bytes32);

    function findHeight(bytes32 _digest) external view returns (uint256);

    function findAncestor(bytes32 _digest, uint256 _offset) external view returns (bytes32);

    function isAncestor(bytes32 _ancestor, bytes32 _descendant, uint256 _limit) external view returns (bool);

    function addHeaders(bytes calldata _anchor, bytes calldata _headers) external returns (bool);

    function markNewHeaviest(
        bytes32 _ancestor,
        bytes calldata _currentBest,
        bytes calldata _newBest,
        uint256 _limit
    ) external returns (bool);
}

// File: contracts/Relay.sol

pragma solidity ^0.5.10;

/** @title Relay */
/** @author Summa (https://summa.one) */






contract Relay is IRelay {
    using SafeMath for uint256;
    using TypedMemView for bytes;
    using TypedMemView for bytes29;
    using ViewBTC for bytes29;
    using ViewSPV for bytes29;

    /* using BytesLib for bytes;
    using BTCUtils for bytes;
    using ValidateSPV for bytes; */

    int256 constant IDEAL_BLOCK_TIME = 600;
    int256 constant HALFLIFE = 172800;
    int256 constant RADIX = 2 ** 16;
    uint256 constant MAX_BITS = 0x1d00ffff;

    // How often do we store the height?
    // A higher number incurs less storage cost, but more lookup cost
    uint32 public constant HEIGHT_INTERVAL = 4;

    bytes32 internal relayGenesis;
    bytes32 internal bestKnownDigest;
    bytes32 internal lastReorgCommonAncestor;
    mapping (bytes32 => bytes32) internal previousBlock;
    mapping (bytes32 => uint256) internal blockHeight;

    
    uint256 anchorHeight;
    uint256 anchorParentTime;
    uint256 anchorNBits;

    /// @notice                   Gives a starting point for the relay
    /// @dev                      We don't check this AT ALL really. Don't use relays with bad genesis
    /// @param  _genesisHeader    The starting header
    /// @param  _height           The starting height
    constructor(
                bytes memory _genesisHeader,
                uint256 _height,
                uint256 _anchorHeight,
                uint256 _anchorParentTime,
                uint256 _anchorNBits
                ) public {
        bytes29 _genesisView = _genesisHeader.ref(0).tryAsHeader();
        require(_genesisView.notNull(), "Stop being dumb");
        bytes32 _genesisDigest = _genesisView.hash256();

        relayGenesis = _genesisDigest;
        bestKnownDigest = _genesisDigest;
        lastReorgCommonAncestor = _genesisDigest;
        blockHeight[_genesisDigest] = _height;

        anchorHeight = _anchorHeight;
        anchorParentTime = _anchorParentTime;
        anchorNBits = _anchorNBits;
    }

    /// @notice     Getter for relayGenesis
    /// @dev        This is an initialization parameter
    /// @return     The hash of the first block of the relay
    function getRelayGenesis() public view returns (bytes32) {
        return relayGenesis;
    }

    /// @notice     Getter for bestKnownDigest
    /// @dev        This updated only by calling markNewHeaviest
    /// @return     The hash of the best marked chain tip
    function getBestKnownDigest() public view returns (bytes32) {
        return bestKnownDigest;
    }

    /// @notice     Getter for relayGenesis
    /// @dev        This is updated only by calling markNewHeaviest
    /// @return     The hash of the shared ancestor of the most recent fork
    function getLastReorgCommonAncestor() public view returns (bytes32) {
        return lastReorgCommonAncestor;
    }

    /// @notice         Finds the height of a header by its digest
    /// @dev            Will fail if the header is unknown
    /// @param _digest  The header digest to search for
    /// @return         The height of the header, or error if unknown
    function findHeight(bytes32 _digest) external view returns (uint256) {
        return _findHeight(_digest);
    }

    /// @notice         Finds an ancestor for a block by its digest
    /// @dev            Will fail if the header is unknown
    /// @param _digest  The header digest to search for
    /// @return         The height of the header, or error if unknown
    function findAncestor(bytes32 _digest, uint256 _offset) external view returns (bytes32) {
        return _findAncestor(_digest, _offset);
    }

    /// @notice             Checks if a digest is an ancestor of the current one
    /// @dev                Limit the amount of lookups (and thus gas usage) with _limit
    /// @param _ancestor    The prospective ancestor
    /// @param _descendant  The descendant to check
    /// @param _limit       The maximum number of blocks to check
    /// @return             true if ancestor is at most limit blocks lower than descendant, otherwise false
    function isAncestor(bytes32 _ancestor, bytes32 _descendant, uint256 _limit) external view returns (bool) {
        return _isAncestor(_ancestor, _descendant, _limit);
    }

    /// @notice             Adds headers to storage after validating
    /// @dev                We check integrity and consistency of the header chain
    /// @param  _anchor     The header immediately preceeding the new chain
    /// @param  _headers    A tightly-packed list of 80-byte Bitcoin headers
    /// @return             True if successfully written, error otherwise
    function addHeaders(bytes calldata _anchor, bytes calldata _headers) external returns (bool) {
        bytes29 _headersView = _headers.ref(0).tryAsHeaderArray();
        bytes29 _anchorView = _anchor.ref(0).tryAsHeader();

        require(_headersView.notNull(), "Header array length must be divisible by 80");
        require(_anchorView.notNull(), "Anchor must be 80 bytes");

        return _addHeaders(_anchorView, _headersView);
    }

    /// @notice                   Gives a starting point for the relay
    /// @dev                      We don't check this AT ALL really. Don't use relays with bad genesis
    /// @param  _ancestor         The digest of the most recent common ancestor
    /// @param  _currentBest      The 80-byte header referenced by bestKnownDigest
    /// @param  _newBest          The 80-byte header to mark as the new best
    /// @param  _limit            Limit the amount of traversal of the chain
    /// @return                   True if successfully updates bestKnownDigest, error otherwise
    function markNewHeaviest(
        bytes32 _ancestor,
        bytes calldata _currentBest,
        bytes calldata _newBest,
        uint256 _limit
    ) external returns (bool) {
        bytes29 _new = _newBest.ref(0).tryAsHeader();
        bytes29 _current = _currentBest.ref(0).tryAsHeader();
        require(
            _new.notNull() && _current.notNull(),
            "Bad args. Check header and array byte lengths."
        );
        return _markNewHeaviest(_ancestor, _current, _new, _limit);
    }

    /// @notice             Adds headers to storage after validating
    /// @dev                We check integrity and consistency of the header chain
    /// @param  _anchor     The header immediately preceeding the new chain
    /// @param  _headers    A tightly-packed list of new 80-byte Bitcoin headers to record
    /// @return             True if successfully written, error otherwise
    function _addHeaders(bytes29 _anchor, bytes29 _headers) internal returns (bool) {
        /// Extract basic info
        bytes32 _previousDigest = _anchor.hash256();
        uint256 _anchorHeight = _findHeight(_previousDigest);  /* NB: errors if unknown */
        uint256 _previousTime = _anchor.time();

        /*
        NB:
        1. check that the header has sufficient work
        2. check that headers are in a coherent chain (no retargets, hash links good)
        3. Store the block connection
        4. Store the height
        */
        uint256 _height;
        bytes32 _currentDigest;
        uint256 _target;
        uint256 _expectedTarget;
        for (uint256 i = 0; i < _headers.len() / 80; i += 1) {
            bytes29 _header = _headers.indexHeaderArray(i);
            _target = _header.target();
            _height = _anchorHeight.add(i + 1);
            _currentDigest = _header.hash256();
            
            /*
            NB:
            if the block is already authenticated, we don't need to a work check
            Or write anything to state. This saves gas
            */
            if (previousBlock[_currentDigest] == bytes32(0)) {
                require(
                    TypedMemView.reverseUint256(uint256(_currentDigest)) <= _target,
                    "Header work is insufficient"
                );
                previousBlock[_currentDigest] = _previousDigest;
                if (_height % HEIGHT_INTERVAL == 0) {
                    /*
                    NB: We store the height only every 4th header to save gas
                    */
                    blockHeight[_currentDigest] = _height;
                }
            }

            _expectedTarget = _nextTarget(int(anchorHeight),
                                          int(anchorParentTime),
                                          anchorNBits,
                                          int(_height.sub(1)),
                                          int(_previousTime));
            require((_target & _expectedTarget) == _target,
                    "Invalid retarget provided");

            /* NB: we do still need to make chain level checks tho */
            require(_header.checkParent(_previousDigest), "Headers do not form a consistent chain");

            _previousDigest = _currentDigest;
            _previousTime = _header.time();
        }

        emit Extension(
            _anchor.hash256(),
            _currentDigest);
        return true;
    }

    /// @notice         Finds the height of a header by its digest
    /// @dev            Will fail if the header is unknown
    /// @param _digest  The header digest to search for
    /// @return         The height of the header
    function _findHeight(bytes32 _digest) internal view returns (uint256) {
        uint256 _height = 0;
        bytes32 _current = _digest;
        for (uint256 i = 0; i < HEIGHT_INTERVAL + 1; i = i.add(1)) {
            _height = blockHeight[_current];
            if (_height == 0) {
                _current = previousBlock[_current];
            } else {
                return _height.add(i);
            }
        }
        revert("Unknown block");
    }

    /// @notice         Finds an ancestor for a block by its digest
    /// @dev            Will fail if the header is unknown
    /// @param _digest  The header digest to search for
    /// @return         The height of the header, or error if unknown
    function _findAncestor(bytes32 _digest, uint256 _offset) internal view returns (bytes32) {
        bytes32 _current = _digest;
        for (uint256 i = 0; i < _offset; i = i.add(1)) {
            _current = previousBlock[_current];
        }
        require(_current != bytes32(0), "Unknown ancestor");
        return _current;
    }

    /// @notice             Checks if a digest is an ancestor of the current one
    /// @dev                Limit the amount of lookups (and thus gas usage) with _limit
    /// @param _ancestor    The prospective ancestor
    /// @param _descendant  The descendant to check
    /// @param _limit       The maximum number of blocks to check
    /// @return             true if ancestor is at most limit blocks lower than descendant, otherwise false
    function _isAncestor(bytes32 _ancestor, bytes32 _descendant, uint256 _limit) internal view returns (bool) {
        bytes32 _current = _descendant;
        /* NB: 200 gas/read, so gas is capped at ~200 * limit */
        for (uint256 i = 0; i < _limit; i = i.add(1)) {
            if (_current == _ancestor) {
                return true;
            }
            _current = previousBlock[_current];
        }
        return false;
    }

    /// @notice                   Marks the new best-known chain tip
    /// @param  _ancestor         The digest of the most recent common ancestor
    /// @param  _current          The 80-byte header referenced by bestKnownDigest
    /// @param  _new              The 80-byte header to mark as the new best
    /// @param  _limit            Limit the amount of traversal of the chain
    /// @return                   True if successfully updates bestKnownDigest, error otherwise
    function _markNewHeaviest(
        bytes32 _ancestor,
        bytes29 _current,  // Header
        bytes29 _new,      // Header
        uint256 _limit
    ) internal returns (bool) {
        require(_limit <= 2016, "Requested limit is greater than 1 difficulty period");

        bytes32 _newBestDigest = _new.hash256();
        bytes32 _currentBestDigest = _current.hash256();
        require(_currentBestDigest == bestKnownDigest, "Passed in best is not best known");
        require(
            previousBlock[_newBestDigest] != bytes32(0),
            "New best is unknown");
        require(
            _isMostRecentAncestor(_ancestor, bestKnownDigest, _newBestDigest, _limit),
            "Ancestor must be heaviest common ancestor");
        require(
            _heaviestFromAncestor(_ancestor, _current, _new) == _newBestDigest,
            "New best hash does not have more work than previous");

        bestKnownDigest = _newBestDigest;
        lastReorgCommonAncestor = _ancestor;

        uint256 _newDiff = _new.diff();
        /* if (_newDiff != currentEpochDiff) { */
        /*     currentEpochDiff = _newDiff; */
        /* } */

        emit NewTip(
            _currentBestDigest,
            _newBestDigest,
            _ancestor);
        return true;
    }

    /// @notice             Checks if a digest is an ancestor of the current one
    /// @dev                Limit the amount of lookups (and thus gas usage) with _limit
    /// @param _ancestor    The prospective shared ancestor
    /// @param _left        A chain tip
    /// @param _right       A chain tip
    /// @param _limit       The maximum number of blocks to check
    /// @return             true if it is the most recent common ancestor within _limit, false otherwise
    function _isMostRecentAncestor(
        bytes32 _ancestor,
        bytes32 _left,
        bytes32 _right,
        uint256 _limit
    ) internal view returns (bool) {
        /* NB: sure why not */
        if (_ancestor == _left && _ancestor == _right) {
            return true;
        }

        bytes32 _leftCurrent = _left;
        bytes32 _rightCurrent = _right;
        bytes32 _leftPrev = _left;
        bytes32 _rightPrev = _right;

        for(uint256 i = 0; i < _limit; i = i.add(1)) {
            if (_leftPrev != _ancestor) {
                _leftCurrent = _leftPrev;  // cheap
                _leftPrev = previousBlock[_leftPrev];  // expensive
            }
            if (_rightPrev != _ancestor) {
                _rightCurrent = _rightPrev;  // cheap
                _rightPrev = previousBlock[_rightPrev];  // expensive
            }
        }
        if (_leftCurrent == _rightCurrent) {return false;} /* NB: If the same, they're a nearer ancestor */
        if (_leftPrev != _rightPrev) {return false;} /* NB: Both must be ancestor */
        return true;
    }

    /// @notice             Decides which header is heaviest from the ancestor
    /// @dev                Does not support reorgs above 2017 blocks (:
    /// @param _ancestor    The prospective shared ancestor
    /// @param _left        A chain tip
    /// @param _right       A chain tip
    /// @return             true if it is the most recent common ancestor within _limit, false otherwise
    function _heaviestFromAncestor(
        bytes32 _ancestor,
        bytes29 _left,
        bytes29 _right
    ) internal view returns (bytes32) {
        uint256 _ancestorHeight = _findHeight(_ancestor);
        uint256 _leftHeight = _findHeight(_left.hash256());
        uint256 _rightHeight = _findHeight(_right.hash256());

        require(
            _leftHeight >= _ancestorHeight && _rightHeight >= _ancestorHeight,
            "A descendant height is below the ancestor height");

        /* NB: we can shortcut if one block is in a new difficulty window and the other isn't */
        uint256 _nextPeriodStartHeight = _ancestorHeight.add(2016).sub(_ancestorHeight % 2016);
        bool _leftInPeriod = _leftHeight < _nextPeriodStartHeight;
        bool _rightInPeriod = _rightHeight < _nextPeriodStartHeight;

        /*
        NB:
        1. Left is in a new window, right is in the old window. Left is heavier
        2. Right is in a new window, left is in the old window. Right is heavier
        3. Both are in the same window, choose the higher one
        4. They're in different new windows. Choose the heavier one
        */
        if (!_leftInPeriod && _rightInPeriod) {return _left.hash256();}
        if (_leftInPeriod && !_rightInPeriod) {return _right.hash256();}
        if (_leftInPeriod && _rightInPeriod) {
            return _leftHeight >= _rightHeight ? _left.hash256() : _right.hash256();
        } else {  // if (!_leftInPeriod && !_rightInPeriod) {
            if (((_leftHeight % 2016).mul(_left.diff())) <
                (_rightHeight % 2016).mul(_right.diff())) {
                return _right.hash256();
            } else {
                return _left.hash256();
            }
        }
    }

    function _bitsToTarget(uint256 nBits) internal pure returns (uint256) {
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
    
    function _nextTarget(int256 anchorHeigth,
                        int256 anchorParentTime,
                        uint256 anchorNBits,
                        int256 currentHeigth,
                        int256 currentTime
                        ) internal pure returns (uint256) {
      
      uint256 maxTarget = _bitsToTarget(MAX_BITS);
      uint256 anchorTarget = _bitsToTarget(anchorNBits);
      
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

// For unittests
contract TestRelay is Relay {

    /// @notice                   Gives a starting point for the relay
    /// @dev                      We don't check this AT ALL really. Don't use relays with bad genesis
    /// @param  _genesisHeader    The starting header
    /// @param  _height           The starting height
    constructor(bytes memory _genesisHeader,
                uint256 _height,
                uint256 _anchorHeight,
                uint256 _anchorParentTime,
                uint256 _anchorNBits)
      Relay(_genesisHeader, _height, _anchorHeight, _anchorParentTime, _anchorNBits)
    public {}

    function heaviestFromAncestor(
        bytes32 _ancestor,
        bytes calldata _left,
        bytes calldata _right
    ) external view returns (bytes32) {
        return _heaviestFromAncestor(
            _ancestor,
            _left.ref(0).tryAsHeader(),
            _right.ref(0).tryAsHeader()
        );
    }

    function isMostRecentAncestor(
        bytes32 _ancestor,
        bytes32 _left,
        bytes32 _right,
        uint256 _limit
    ) external view returns (bool) {
        return _isMostRecentAncestor(_ancestor, _left, _right, _limit);
    }
}
