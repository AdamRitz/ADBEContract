pragma solidity ^0.8.20;

contract Verify {
    uint256 constant q =
        0x73eda753299d7d483339d80809a1d80553bda402fffe5bfeffffffff00000001;
    uint256 constant q1 =
        0x73eda753299d7d483339d80809a1d80553bda402fffe5bfeffffffff00000000;
    bytes constant g1 =
        hex"0000000000000000000000000000000017f1d3a73197d7942695638c4fa9ac0fc3688c4f9774b905a14e3a3f171bac586c55e83ff97a1aeffb3af00adb22c6bb0000000000000000000000000000000008b3f481e3aaa0f1a09e30ed741d8ae4fcf5e095d5d00af600db18cb2c04b3edd03cc744a2888ae40caa232946c5e7e1";
    bytes constant g2 =
        hex"00000000000000000000000000000000024aa2b2f08f0a91260805272dc51051c6e47ad4fa403b02b4510b647ae3d1770bac0326a805bbefd48056c8c121bdb80000000000000000000000000000000013e02b6052719f607dacd3a088274f65596bd0d09920b61ab5da61bbdc7f5049334cf11213945d57e5ac7d055d042b7e000000000000000000000000000000000ce5d527727d6e118cc9cdc6da2e351aadfd9baa8cbdd3a76d429a695160d12c923ac9cc3baca289e193548608b82801000000000000000000000000000000000606c4a02ea734cc32acd2b02bc28b99cb3e287e85a763af267492ab572e99ab3f370d275cec1da1aaa9075ff05f79be";
    
    function Check3(
        bytes[] calldata g1s,
        bytes[] calldata g2s
    ) public  returns (bool) {
        uint256 L1 = g1s.length;
        uint256 L2 = g2s.length;
        require(L1 * 2 == L2);
        // Compute 4 Part
        uint256 rho1 = uint256(keccak256(abi.encode(g1s, g2s, 0))) % q;
        uint256 rho2 = uint256(keccak256(abi.encode(g1s, g2s, 1))) % q;
        uint256 temp1 = 1;
        uint256 temp2 = 1;
        uint256 k = 0;
        bytes memory ag1 = new bytes(L1 * 160);
        bytes memory ag2 = new bytes((L2 - 3) * 288);
        bytes memory ag3 = new bytes((L1 - 1) * 160);
        bytes memory ag4 = new bytes((L2 - 2) * 288); //长度还需要再考虑
        //
        // Compute Part 1
        //
        k = 0;
        for (uint256 i = 0; i <= L1 - 1; i++) {
            require(g1s[i].length == 128, "bad G1 len");
            for (uint256 j = 0; j < 128; j++) {
                ag1[k] = g1s[i][j];
                k++;
            }
            bytes32 temp = bytes32(temp1);
            for (uint256 j = 0; j < 32; j++) {
                ag1[k] = temp[j];
                k++;
            }
            temp1 = mulmod(temp1, rho1, q);
        }
        bytes memory part1 = G1Muls(ag1);
        //
        // Compute Part 2
        //
        k = 0;
        temp2 = rho2;
        for (uint256 i = 0; i <= 2 * L1 - 1 - 1; i++) {
            // 实际是数组里面的 L+1 和 L
            if (i == L1 - 1 || i == L1) {
                temp2 = mulmod(temp2, rho2, q);
                continue;
            }
            for (uint256 j = 0; j < 256; j++) {
                ag2[k] = g2s[i][j];
                k++;
            }
            bytes32 temp = bytes32(temp2);
            for (uint256 j = 0; j <= 32 - 1; j++) {
                ag2[k] = temp[j];
                k++;
            }
            temp2 = mulmod(temp2, rho2, q);
        }
        bytes memory part2 = G2Muls(ag2);
        part2 = G2Add(g2, part2);
        //
        // Compute Part 3
        //
        k = 0;
        temp1 = rho1;
        for (uint256 i = 0; i <= L1 - 1 - 1; i++) {
            for (uint256 j = 0; j < 128; j++) {
                ag3[k] = g1s[i][j];
                k++;
            }
            bytes32 temp = bytes32(temp1);
            for (uint256 j = 0; j <= 32 - 1; j++) {
                ag3[k] = temp[j];
                k++;
            }
            temp1 = mulmod(temp1, rho1, q);
        }
        bytes memory part3 = G1Muls(ag3);
        part3 = G1Add(g1, part3);
        //
        // Compute Part 4
        //

        k = 0;
        temp2 = 1;
        for (uint256 i = 0; i <= 2 * L1 - 1; i++) {
            if (i == L1 || i == L1 + 1) {
                //排除第 L+1  和 L+2
                temp2 = mulmod(temp2, rho2, q);
                continue;
            }
            for (uint256 j = 0; j < 256; j++) {
                ag4[k] = g2s[i][j];
                k++;
            }
            bytes32 temp = bytes32(temp2);
            for (uint256 j = 0; j < 32; j++) {
                ag4[k] = temp[j];
                k++;
            }
            temp2 = mulmod(temp2, rho2, q);
        }
        bytes memory part4 = G2Muls(ag4);

        return EqualPairingCheck(part1, part2, part3, part4);
    }
    function Check2(bytes[] calldata g1s, bytes[] calldata g2s) external  returns (bool) {
    uint256 L1 = g1s.length;
    uint256 L2 = g2s.length;
    require(L1 > 0);
    require(L1 * 2 == L2);

    uint256 rho1 = uint256(keccak256(abi.encode(g1s, g2s, uint256(0)))) % q;
    uint256 rho2 = uint256(keccak256(abi.encode(g1s, g2s, uint256(1)))) % q;

    uint256 k;
    uint256 temp1;
    uint256 temp2;

    // -------- Part 1 --------
    bytes memory ag1 = new bytes(L1 * 160);
    k = 0;
    temp1 = 1;
    for (uint256 i = 0; i < L1; ) {
        bytes calldata p = g1s[i];
        require(p.length == 128);

        _cdCopy(p, 0, ag1, k, 128);
        k += 128;

        _mstoreScalar(ag1, k, temp1);
        k += 32;

        temp1 = mulmod(temp1, rho1, q);
        unchecked { ++i; }
    }
    bytes memory part1 = G1Muls(ag1);

    // -------- Part 2 --------
    // i = 0..(2*L1-2), skip i==L1-1 and i==L1  => slices = 2*L1-3
    uint256 slices2 = 2 * L1 - 3;
    bytes memory ag2 = new bytes(slices2 * 288);

    k = 0;
    temp2 = rho2;
    for (uint256 i = 0; i <= 2 * L1 - 2; ) {
        if (i == L1 - 1 || i == L1) {
            temp2 = mulmod(temp2, rho2, q);
            unchecked { ++i; }
            continue;
        }

        bytes calldata p = g2s[i];
        require(p.length == 256);

        _cdCopy(p, 0, ag2, k, 256);
        k += 256;

        _mstoreScalar(ag2, k, temp2);
        k += 32;

        temp2 = mulmod(temp2, rho2, q);
        unchecked { ++i; }
    }
    bytes memory part2 = G2Muls(ag2);
    part2 = G2Add(g2, part2);

    // -------- Part 3 --------
    require(L1 >= 2);
    bytes memory ag3 = new bytes((L1 - 1) * 160);

    k = 0;
    temp1 = rho1;
    for (uint256 i = 0; i < L1 - 1; ) {
        bytes calldata p = g1s[i];
        require(p.length == 128);

        _cdCopy(p, 0, ag3, k, 128);
        k += 128;

        _mstoreScalar(ag3, k, temp1);
        k += 32;

        temp1 = mulmod(temp1, rho1, q);
        unchecked { ++i; }
    }
    bytes memory part3 = G1Muls(ag3);
    part3 = G1Add(g1, part3);

    // -------- Part 4 --------
    // i = 0..(2*L1-1), skip i==L1 and i==L1+1 => slices = 2*L1-2
    uint256 slices4 = 2 * L1 - 2;
    bytes memory ag4 = new bytes(slices4 * 288);

    k = 0;
    temp2 = 1;
    for (uint256 i = 0; i <= 2 * L1 - 1; ) {
        if (i == L1 || i == L1 + 1) {
            temp2 = mulmod(temp2, rho2, q);
            unchecked { ++i; }
            continue;
        }

        bytes calldata p = g2s[i];
        require(p.length == 256);

        _cdCopy(p, 0, ag4, k, 256);
        k += 256;

        _mstoreScalar(ag4, k, temp2);
        k += 32;

        temp2 = mulmod(temp2, rho2, q);
        unchecked { ++i; }
    }
    bytes memory part4 = G2Muls(ag4);
    require(EqualPairingCheck(part1, part2, part3, part4),"Check2 Failed");
    require(EqualPairingCheck(g1,g2s[L1+1],g1s[1],g2s[L1-1]),"Check3 Failed");
    return true;
}
 bool public  w=false;
// ---- helpers: 只做 copy 和写标量，不改你 precompile 包装函数 ----
function why1(bytes[] calldata g1s,bytes[] calldata g2s) public  {
    uint256 L1=g1s.length;
    w=EqualPairingCheck(g1,g2s[L1+1],g1s[1],g2s[L1-1]);
}
function why2(bytes[] calldata g1s,bytes[] calldata g2s) public  {

    uint256 t=uint256(keccak256(abi.encode(g1s,g2s)))%q;
    if (t!=0){
        w=false;
    }
}
function _cdCopy(
    bytes calldata src,
    uint256 srcOff,
    bytes memory dst,
    uint256 dstOff,
    uint256 len
) internal pure {
    assembly {
        calldatacopy(add(add(dst, 32), dstOff), add(src.offset, srcOff), len)
    }
}

function _mstoreScalar(bytes memory dst, uint256 dstOff, uint256 x) internal pure {
    assembly {
        mstore(add(add(dst, 32), dstOff), x)
    }
}
    //
    // Group Operation Section
    //
    function G1Add(
        bytes memory p1,
        bytes memory p2
    ) public view returns (bytes memory point) {
        bytes memory input = abi.encodePacked(p1, p2);
        (bool ok, bytes memory ret) = address(0x0b).staticcall(input);
        return ret;
    }
    function G1Mul(
        bytes memory p1,
        uint256 scalar
    ) public view returns (bytes memory point) {
        bytes memory input = abi.encodePacked(p1, scalar);
        (bool ok, bytes memory ret) = address(0x0c).staticcall(input);
        return ret;
    }
    function G1Muls(bytes memory d) public view returns (bytes memory point) {
        (bool ok, bytes memory ret) = address(0x0c).staticcall(d);
        return ret;
    }
    // G2s Section
    function G2Add(
        bytes memory p1,
        bytes memory p2
    ) public view returns (bytes memory point) {
        bytes memory input = abi.encodePacked(p1, p2);
        (bool ok, bytes memory ret) = address(0x0d).staticcall(input);
        return ret;
    }
    function G2Mul(
        bytes calldata p1,
        uint256 scalar
    ) public view returns (bytes memory point) {
        bytes memory input = abi.encodePacked(p1, scalar);
        (bool ok, bytes memory ret) = address(0x0e).staticcall(input);
        return ret;
    }
    function G2Muls(bytes memory d) public view returns (bytes memory point) {
        (bool ok, bytes memory ret) = address(0x0e).staticcall(d);
        return ret;
    }
    // Pairings Section
    function Pairing(
        bytes memory p1,
        bytes memory p2,
        bytes memory p3,
        bytes memory p4
    ) public view returns (bool) {
        bytes memory input = abi.encodePacked(p1, p2, p3, p4);
        (bool ok, bytes memory ret) = address(0x0f).staticcall(input);
        return uint256(bytes32(ret)) == 1;
    }
    function EqualPairingCheck(
        bytes memory p1,
        bytes memory p2,
        bytes memory p3,
        bytes memory p4
    ) public view returns (bool) {
        bytes memory negP3 = G1Mul(p3, q1);
        bytes memory input = abi.encodePacked(p1, p2, negP3, p4);
        (bool ok, bytes memory ret) = address(0x0f).staticcall(input);
        return uint256(bytes32(ret)) == 1;
    }
    function testt() public view {
        bytes memory a=new bytes(200);
        bytes memory b=new bytes(200);
        bytes memory c=abi.encodePacked(a,b);
    }
}
