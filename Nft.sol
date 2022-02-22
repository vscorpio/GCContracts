// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC2981.sol";
import "./RoyaltiesAddons.sol";

contract OnChainProperties {
    mapping(uint256 => bool) public isWorker;
    mapping(uint256 => bool) public isLandlord;
    mapping(uint256 => bool) public isBusinessOwner;
    mapping(uint256 => bool) public isGangster;
}

interface StakingInterface {
   function getRandomStakedGangsterOwnerAddr() external view returns (address);
}

contract GangsterCityNFT is RoyaltiesAddon, ERC2981, OnChainProperties, Ownable {

    // START ROYALTIES

    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721, ERC2981)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

     /// @dev sets royalties address
    /// for royalties addon
    /// for 2981
    function setRoyaltiesAddress(address _royaltiesAddress)
        public
        onlyOwner
    {
        super._setRoyaltiesAddress(_royaltiesAddress);
    }

    /// @dev sets royalties fees
    function setRoyaltiesFees(uint256 _royaltiesFees)
        public
        onlyOwner
    {
      require(_royaltiesFees >= 1 && royaltiesFees <= 100);
        royaltiesFees = _royaltiesFees;
    }

    /// @inheritdoc	IERC2981
    function royaltyInfo(uint256 tokenId, uint256 value)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (royaltiesAddress, value * royaltiesFees / 100);
    }

    // END ROYALTIES

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 nftCount = 50000;
    uint256 private royaltiesFees;

    address public ercAddress;
    address public stakingAddress;

    bool public isMintingEnabled;

    event ErcStakingAddressChanged(address newErcAddress, address newStakingAddress);
    event MintingEnabledChanged(bool status);
    event NewItemMinted(uint256 tokenId, string tokenURI);

    constructor(address ercAddr, address stakingAddr)
        ERC721("Gangster City NFT", "GC-NFT")
        OnChainProperties()
    {
        stakingAddress = stakingAddr;
        ercAddress = ercAddr;
    }

    address metadataProviderAddress = 0x9e4BDC464828B66b07eF826A44ccC42DfDA69b88;

    mapping(string => bool) consumedTokenURIs;
    mapping(uint256 => bool) consumedRandomness;

    // Utility function
    function normalSubstring(
        string memory input,
        uint256 startIndex,
        uint256 endIndex
    ) internal pure returns (string memory) {
        bytes memory strBytes = bytes(input);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    // Utility function
    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    // Ecrecover function
    function verifyURI(
        string memory message,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address signer) {
        string memory header = "\x19Ethereum Signed Message:\n000000";
        uint256 lengthOffset;
        uint256 length;
        assembly {
            length := mload(message)
            lengthOffset := add(header, 57)
        }
        require(length <= 999999);
        uint256 lengthLength = 0;
        uint256 divisor = 100000;
        while (divisor != 0) {
            uint256 digit = length / divisor;
            if (digit == 0) {
                if (lengthLength == 0) {
                    divisor /= 10;
                    continue;
                }
            }
            lengthLength++;
            length -= digit * divisor;
            divisor /= 10;
            digit += 0x30;
            lengthOffset++;
            assembly {
                mstore8(lengthOffset, digit)
            }
        }
        if (lengthLength == 0) {
            lengthLength = 1 + 0x19 + 1;
        } else {
            lengthLength += 1 + 0x19;
        }
        assembly {
            mstore(header, lengthLength)
        }
        bytes32 check = keccak256(abi.encodePacked(header, message));
        return ecrecover(check, v, r, s);
    }

    function getMintedNFTCount() external view returns (uint256) {
        return _tokenIds.current();
    }


    function withdrawBalance(address payable destinationWallet)
        external
        onlyOwner
    {
        require(destinationWallet != address(0), "Address cannot be the zero-address");
        destinationWallet.transfer(address(this).balance);
    }

    function withdrawERCBalance(address destinationWallet)
        external
        onlyOwner
    {
        require(destinationWallet != address(0), "Address cannot be the zero-address");
        IERC20(ercAddress).transfer(
            destinationWallet,
            IERC20(ercAddress).balanceOf(address(this))
        );
    }

    function changeErcAndStakingAddr(address ercAddr, address stakingAddr) external onlyOwner {
        require(ercAddr != address(0), "ERC address cannot be the zero-address");
        require(stakingAddr != address(0), "Staking address cannot be the zero-address");
        ercAddress = ercAddr;
        stakingAddress = stakingAddr;
        emit ErcStakingAddressChanged(ercAddr, stakingAddr);
    }

    function changeMintingEnabled(bool newValue) external onlyOwner {
        isMintingEnabled = newValue;
        emit MintingEnabledChanged(newValue);
    }

    function strToUint(string memory _str) public pure returns(uint256 res) {
        
        for (uint256 i = 0; i < bytes(_str).length; i++) {
            if ((uint8(bytes(_str)[i]) - 48) < 0 || (uint8(bytes(_str)[i]) - 48) > 9) {
                return (0);
            }
            res += (uint8(bytes(_str)[i]) - 48) * 10**(bytes(_str).length - i - 1);
        }
        
        return (res);
    }

    function createNft(
        string memory tokenURI,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 randomness,
        uint8 v2,
        bytes32 r2,
        bytes32 s2
        
    ) public payable returns (uint256) {

        _tokenIds.increment();

        require(_tokenIds.current() <= nftCount, "All NFTs have been minted!");
        require(isMintingEnabled == true);
        require(consumedTokenURIs[tokenURI] == false);
        require(consumedRandomness[randomness] == false);

        if (_tokenIds.current() >= 1 && _tokenIds.current() <= 10000) {
            require(
                msg.value >= 2 * 10**18,
                "You haven't sent enough AVAX to mint!"
            );
        } else if (
            _tokenIds.current() >= 10001 && _tokenIds.current() <= 20000
        ) {
            IERC20(ercAddress).transferFrom(
                msg.sender,
                address(this),
                10000 * 10**18
            );
        } else if (
            _tokenIds.current() >= 20001 && _tokenIds.current() <= 40000
        ) {
            IERC20(ercAddress).transferFrom(
                msg.sender,
                address(this),
                20000 * 10**18
            );
        } else if (
            _tokenIds.current() >= 40001 && _tokenIds.current() <= 50000
        ) {
            IERC20(ercAddress).transferFrom(
                msg.sender,
                address(this),
                40000 * 10**18
            );
        }

        uint256 newItemId = _tokenIds.current();

        require(
            verifyURI(tokenURI, v, r, s) == metadataProviderAddress,
            "Metadata signature is invalid"
        );

        string memory formattedMetadataURI = normalSubstring(tokenURI, 2, bytes(tokenURI).length); // metadata URI
        uint256 shouldTransferToGangster = strToUint(normalSubstring(tokenURI, 0, 1)); // first number in the signed message (0 - do not transfer | 1 - transfer)
        uint256 selectedClass = strToUint(normalSubstring(tokenURI, 1, 2)); // second number in the signed message (1 - worker | 2 - landlord | 3 - business owner | 4 - gangster)

        require(shouldTransferToGangster >= 0 && shouldTransferToGangster <= 1);
        require(selectedClass >= 1 && selectedClass <= 4);

        if (selectedClass == 1) isWorker[newItemId] = true;
        if (selectedClass == 2) isLandlord[newItemId] = true;
        if (selectedClass == 3) isBusinessOwner[newItemId] = true;
        if (selectedClass == 4) isGangster[newItemId] = true;

        address randomGangsterAddress = StakingInterface(stakingAddress).getRandomStakedGangsterOwnerAddr();

        if(_tokenIds.current() > 10000 && shouldTransferToGangster == 1 && randomGangsterAddress != address(0))
        {
            _mint(randomGangsterAddress, newItemId);
            _setTokenURI(newItemId, formattedMetadataURI);
        }
        else
        {
            _mint(msg.sender, newItemId);
            _setTokenURI(newItemId, formattedMetadataURI);
        }

        consumedTokenURIs[tokenURI] = true;
        consumedRandomness[randomness] = true;

        emit NewItemMinted(newItemId, formattedMetadataURI);

        return newItemId;
    }

    function checkIfWorker(uint256 tokenId) external view returns (bool) {
        return isWorker[tokenId];
    }

    function checkIfLandlord(uint256 tokenId) external view returns (bool) {
        return isLandlord[tokenId];
    }

    function checkIfBusinessOwner(uint256 tokenId)
        external
        view
        returns (bool)
    {
        return isBusinessOwner[tokenId];
    }

    function checkIfGangster(uint256 tokenId) external view returns (bool) {
        return isGangster[tokenId];
    }
}
