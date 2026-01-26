pragma solidity ^0.8.20;

contract Verify {
    function Check(bytes[] calldata  g1s,bytes[] calldata g2s)public view returns (bool){
        uint256 L1=g1s.length;
        uint256 L2=g2s.length;
        require(L1*2==L2);
        // Compute 4 Part
        uint256  rho1 =uint256(keccak256( abi.encode(g1s,g2s,0))) ;
        uint256  rho2 = uint256(keccak256( abi.encode(g1s,g2s,1)));
        uint256 temp1=1;
        uint256 temp2=1;
        uint256 k=0;
        bytes memory ag1 = new bytes(L1*160);
        bytes memory ag2 = new bytes((L2-2)*288);
        bytes memory ag3 = new bytes((L1-1)*160);
        bytes memory ag4 = new bytes((L2-2)*288);//长度还需要再考虑
        // Compute Part 1
        for(uint256 i=0;i<=L1-1;i++){
            for(uint256 j=0;j<128;j++){
                ag1[k]=g1s[i][j];
                k++;
            }
            bytes32 temp = bytes32(rho1);
            for(uint256 j=0;j<32;j++){
                ag1[k]=temp[j];
            }
            temp1=temp1*rho1;
        }
        bytes memory part1 = G1Muls(ag1);
        // Compute Part 2
        // Compute Part 3
        temp1=rho1;
        for(uint256 i=0;i<=L1-1-1;i++){
            for(uint256 j=0;j<128;j++){
                ag1[k]=g1s[i][j];
                k++;
            }
            bytes32 temp = bytes32(rho1);
            for(uint256 j=0;j<=32-1;j++){
                ag1[k]=temp[j];
            }
            temp1=temp1*rho1;
        }
        bytes memory part3 = G1Muls(ag3);
        part3 = G1Add(part3,part3);
        // Compute Part 4
        // Pairing Check
    }
        // G1s Section
    function G1Add(bytes calldata p1,bytes calldata p2)public view returns (bytes memory point){
        bytes memory input = abi.encodePacked(p1, p2);
        (bool ok, bytes memory ret) = address(0x0b).staticcall(input);
        return ret;
    }
    function G1Mul(bytes calldata p1,uint256 scalar)public view returns (bytes memory point){
        bytes memory input = abi.encodePacked(p1, scalar);
        (bool ok, bytes memory ret) = address(0x0c).staticcall(input);
        return ret;
    }
    function G1Muls(bytes memory d)public view returns (bytes memory point){
        (bool ok, bytes memory ret) = address(0x0c).staticcall(d);
        return ret;
    }
    // G2s Section
    function G2Add(bytes calldata p1,bytes calldata p2)public view returns (bytes memory point){
        bytes memory input = abi.encodePacked(p1, p2);
        (bool ok, bytes memory ret) = address(0x0d).staticcall(input);
        return ret;
    }
    function G2Mul(bytes calldata p1,uint256 scalar) public view returns(bytes memory point){
        bytes memory input = abi.encodePacked(p1, scalar);
        (bool ok, bytes memory ret) = address(0x0e).staticcall(input);
        return ret;
    }
    function G2Muls(bytes memory d)public view returns (bytes memory point){
        (bool ok, bytes memory ret) = address(0x0e).staticcall(d);
        return ret;
    }
    // Pairings Section
    function Pairing(bytes calldata p1,bytes calldata p2,bytes calldata p3,bytes calldata p4)public view returns (bool){
        bytes memory input = abi.encodePacked(p1,p2,p3,p4);
        (bool ok, bytes memory ret) = address(0x0f).staticcall(input);
        return uint256(bytes32(ret)) == 1;
    }


}

