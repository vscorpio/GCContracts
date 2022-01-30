// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

error InsufficientFunds();
error Unauthorized();

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

library IterableMapping {
    // Iterable mapping from address to uint;
    struct Map {
        uint256[] keys;
        mapping(uint256 => uint256) values;
        mapping(uint256 => uint256) indexOf;
        mapping(uint256 => bool) inserted;
    }

    function get(Map storage map, uint256 key) public view returns (uint256) {
        return map.values[key];
    }

    function getKeyAtIndex(Map storage map, uint256 index)
        public
        view
        returns (uint256)
    {
        return map.keys[index];
    }

    function size(Map storage map) public view returns (uint256) {
        return map.keys.length;
    }

    function set(
        Map storage map,
        uint256 key,
        uint256 val
    ) public {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, uint256 key) public {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint256 index = map.indexOf[key];
        uint256 lastIndex = map.keys.length - 1;
        uint256 lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}

interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    function checkIfWorker(uint256 tokenId) external view returns (bool);

    function checkIfLandlord(uint256 tokenId) external view returns (bool);

    function checkIfBusinessOwner(uint256 tokenId) external view returns (bool);

    function checkIfGangster(uint256 tokenId) external view returns (bool);

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

contract GangsterCityStaking is IERC721Receiver, Ownable {

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

    // Randomness verification (ecrecover)
    function verifyRandomness(
        string memory message,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address signer) {
        // The message header; we will fill in the length next
        string memory header = "\x19Ethereum Signed Message:\n000000";
        uint256 lengthOffset;
        uint256 length;
        assembly {
            // The first word of a string is its length
            length := mload(message)
            // The beginning of the base-10 message length in the prefix
            lengthOffset := add(header, 57)
        }
        // Maximum length we support
        require(length <= 999999);
        // The length of the message's length in base-10
        uint256 lengthLength = 0;
        // The divisor to get the next left-most message length digit
        uint256 divisor = 100000;
        // Move one digit of the message length to the right at a time
        while (divisor != 0) {
            // The place value at the divisor
            uint256 digit = length / divisor;
            if (digit == 0) {
                // Skip leading zeros
                if (lengthLength == 0) {
                    divisor /= 10;
                    continue;
                }
            }
            // Found a non-zero digit or non-leading zero digit
            lengthLength++;
            // Remove this digit from the message length's current value
            length -= digit * divisor;
            // Shift our base-10 divisor over
            divisor /= 10;

            // Convert the digit to its ASCII representation (man ascii)
            digit += 0x30;
            // Move to the next character and write the digit
            lengthOffset++;
            assembly {
                mstore8(lengthOffset, digit)
            }
        }
        // The null string requires exactly 1 zero (unskip 1 leading 0)
        if (lengthLength == 0) {
            lengthLength = 1 + 0x19 + 1;
        } else {
            lengthLength += 1 + 0x19;
        }
        // Truncate the tailing zeros from the header
        assembly {
            mstore(header, lengthLength)
        }
        // Perform the elliptic curve recover operation
        bytes32 check = keccak256(abi.encodePacked(header, message));
        return ecrecover(check, v, r, s);
    }

    //ERC721 fallback

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    address public ErcAddress;
    address public NftAddress;

    constructor(address ercAddr, address nftAddr) {
        ErcAddress = ercAddr;
        NftAddress = nftAddr;
    }

    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private workerMap;
    IterableMapping.Map private landlordMap;
    IterableMapping.Map private businessOwnerMap;
    IterableMapping.Map private gangsterMap;

    mapping(uint256 => uint256) lastClaimedReward;
    mapping(uint256 => uint256) public tokenIdReward;
    mapping(uint256 => address) public ownerOfDeposit;

    // Events

    event WOStaked(uint256 tokenId, uint256 timestamp, address owner);
    event LLStaked(uint256 tokenId, uint256 timestamp, address owner);
    event BOStaked(uint256 tokenId, uint256 timestamp, address owner);
    event GAStaked(uint256 tokenId, uint256 timestamp, address owner);

    event WOUnstaked(uint256 tokenId, uint256 timestamp, address owner);
    event LLUnstaked(uint256 tokenId, uint256 timestamp, address owner);
    event BOUnstaked(uint256 tokenId, uint256 timestamp, address owner);
    event GAUnstaked(uint256 tokenId, uint256 timestamp, address owner);

    event EtherJsLogger(uint256 messageNumber, uint256 value);

    uint256 public stakedWorkers;
    uint256 public stakedLandlords;
    uint256 public stakedBusinessOwners;
    uint256 public stakedGangsters;

    address randomnessProviderV1 = 0xffF82dd1f43899Aa2F254A4bAFa6c343e97682a7;

    uint256 dayTimeInSeconds = 86400;

    bool isStakingEnabled = false;

    function changeERCNFTAddr(address ercAddr, address nftAddr) external onlyOwner {

        require(
            ercAddr != address(0) &&
            nftAddr != address(0)
        );

        ErcAddress = ercAddr;
        NftAddress = nftAddr;
    }

    function changeStakingEnabled(bool value) external onlyOwner {
        isStakingEnabled = value;
    }

    function getRandomStakedGangsterOwnerAddr(
        uint256 randomness,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external view returns (address)  {

        string memory randomnessString = uint2str(randomness);

        if(verifyRandomness(randomnessString, v, r, s) != randomnessProviderV1) revert Unauthorized();
          
        if (stakedGangsters > 0) {
            uint256 key1 = gangsterMap.getKeyAtIndex(((randomness % stakedGangsters) + 1) - 1);
            return ownerOfDeposit[key1];
        } 

        return address(0);
    }


    function stakeNft(uint256 tokenId) external returns (bool) {

        if(isStakingEnabled == false) revert Unauthorized();

        lastClaimedReward[tokenId] = block.timestamp;
        ownerOfDeposit[tokenId] = msg.sender;

        if (IERC721(NftAddress).checkIfWorker(tokenId)) {
            IERC721(NftAddress).transferFrom(
                msg.sender,
                address(this),
                tokenId
            );
            workerMap.set(tokenId, 1);
            stakedWorkers++;
            emit WOStaked(tokenId, block.timestamp, msg.sender);
            return true;
        }
        if (IERC721(NftAddress).checkIfLandlord(tokenId)) {
            IERC721(NftAddress).transferFrom(
                msg.sender,
                address(this),
                tokenId
            );
            landlordMap.set(tokenId, 1);
            stakedLandlords++;
            emit LLStaked(tokenId, block.timestamp, msg.sender);
            return true;
        }
        if (IERC721(NftAddress).checkIfBusinessOwner(tokenId)) {
            IERC721(NftAddress).transferFrom(
                msg.sender,
                address(this),
                tokenId
            );
            businessOwnerMap.set(tokenId, 1);
            stakedBusinessOwners++;
            emit BOStaked(tokenId, block.timestamp, msg.sender);
            return true;
        }
        if (IERC721(NftAddress).checkIfGangster(tokenId)) {
            IERC721(NftAddress).transferFrom(
                msg.sender,
                address(this),
                tokenId
            );
            gangsterMap.set(tokenId, 1);
            stakedGangsters++;
            emit GAStaked(tokenId, block.timestamp, msg.sender);
            return true;
        }

        return false;
    }

    function getWorkerTimeLockReward(uint256 tokenId)
        public
        view
        returns (uint256)
    {
        if(ownerOfDeposit[tokenId] == address(0)) return 0;

        uint256 timeStackedForTokenId = block.timestamp - lastClaimedReward[tokenId];
        uint256 currentTimeLockReward = (((timeStackedForTokenId * (100000)) / dayTimeInSeconds) * 5000 * 1 ether) / (100000);

        return currentTimeLockReward;
    }

    function getUnclaimedRewards(uint256 tokenId)
        external
        view
        returns (uint256)
    {
        return tokenIdReward[tokenId];
    }

    function getTotalStakedNFTs()
        external
        view
        returns (uint256)
    {
        return stakedWorkers + stakedLandlords + stakedBusinessOwners + stakedGangsters;
    }


    function claimRewardWorker(uint256 tokenId) external payable returns (uint256) {

        if(IERC721(NftAddress).checkIfWorker(tokenId) != true) revert Unauthorized();
        if(ownerOfDeposit[tokenId] != msg.sender) revert Unauthorized();

        uint256 finalWorkerReward = getWorkerTimeLockReward(tokenId);
        uint256 finalWorkerRewardCopy = finalWorkerReward;

        // Distribute BO cut 20%
        if (stakedBusinessOwners > 0) {
            uint256 businessOwnerBonus = (finalWorkerRewardCopy * (20)) / (100);
            uint256 eachBusinessOwnerCut = businessOwnerBonus / (stakedBusinessOwners);
            finalWorkerReward -= businessOwnerBonus;
            if (stakedBusinessOwners == 1) {
                uint256 key1 = businessOwnerMap.getKeyAtIndex(0);
                tokenIdReward[key1] += eachBusinessOwnerCut;
            } else {
                for (uint256 i = 0; i <= stakedBusinessOwners - 1; i++) {
                    uint256 key = businessOwnerMap.getKeyAtIndex(i);
                    tokenIdReward[key] += eachBusinessOwnerCut;
                }
            }
        }

        // Distribute Landlord cut 15%
        if (stakedLandlords > 0) {
            uint256 landlordBonus = (finalWorkerRewardCopy * (15)) / (100);
            uint256 eachLandlordCut = landlordBonus / (stakedLandlords);
            finalWorkerReward -= landlordBonus;
            if (stakedLandlords == 1) {
                uint256 key1 = landlordMap.getKeyAtIndex(0);
                tokenIdReward[key1] += eachLandlordCut;
            } else {
                for (uint256 i = 0; i <= stakedLandlords - 1; i++) {
                    uint256 key = landlordMap.getKeyAtIndex(i);
                    tokenIdReward[key] += eachLandlordCut;
                }
            }
        }

        // Distribute Gangster cut 5%
        if (stakedGangsters > 0) {
            uint256 gangsterBonus = (finalWorkerRewardCopy * (5)) / (100);
            uint256 eachGangsterCut = gangsterBonus / (stakedGangsters);
            finalWorkerReward -= gangsterBonus;
            if (stakedGangsters == 1) {
                uint256 key1 = gangsterMap.getKeyAtIndex(0);
                tokenIdReward[key1] += eachGangsterCut;
            } else {
                for (uint256 i = 0; i <= stakedGangsters - 1; i++) {
                    uint256 key = gangsterMap.getKeyAtIndex(i);
                    tokenIdReward[key] += eachGangsterCut;
                }
            }
        }

        if (finalWorkerReward != 0) {
            lastClaimedReward[tokenId] = block.timestamp;
            tokenIdReward[tokenId] = 0;
            IERC20(ErcAddress).transfer(msg.sender, finalWorkerReward);
        }

        emit EtherJsLogger(1, finalWorkerReward);
        return finalWorkerReward;
    }

    function unstakeWorker(
        uint256 randomness,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 tokenId
    ) external payable  returns (uint256) {


        uint256 finalWorkerReward = getWorkerTimeLockReward(tokenId);
        uint256 returnedMsgNumber = 1;

        string memory randomnessString = uint2str(randomness);

        stakedWorkers--;
        workerMap.remove(tokenId);

        if(IERC721(NftAddress).checkIfWorker(tokenId) != true) revert Unauthorized();
        if(finalWorkerReward < 10000 * 1 ether) revert InsufficientFunds();
        if(verifyRandomness(randomnessString, v, r, s) != randomnessProviderV1) revert Unauthorized();

        uint256 chance = (randomness % 100) + 1;

        // 5% chance for income to be split among all landlords
        if ((chance >= 1 && chance <= 5))
            if (stakedLandlords > 0) {
                uint256 eachLandlordCut = finalWorkerReward / (stakedLandlords);
                finalWorkerReward = 0;
                returnedMsgNumber = 2;
                if (stakedLandlords == 1) {
                    uint256 key1 = landlordMap.getKeyAtIndex(0);
                    tokenIdReward[key1] += eachLandlordCut;
                } else {
                    for (uint256 i = 0; i <= stakedLandlords - 1; i++) {
                        uint256 key = landlordMap.getKeyAtIndex(i);
                        tokenIdReward[key] += eachLandlordCut;
                    }
                }
            }

        // 10% chance for income to be split among all BO
        if ((chance >= 6 && chance <= 15))
            if (stakedBusinessOwners > 0) {
                returnedMsgNumber = 3;
                uint256 eachBusinessOwnerCut = finalWorkerReward / (stakedBusinessOwners);
                finalWorkerReward = 0;
                if (stakedBusinessOwners == 1) {
                    uint256 key1 = businessOwnerMap.getKeyAtIndex(0);
                    tokenIdReward[key1] += eachBusinessOwnerCut;
                } else {
                    for (uint256 i = 0; i <= stakedBusinessOwners - 1; i++) {
                        uint256 key = businessOwnerMap.getKeyAtIndex(i);
                        tokenIdReward[key] += eachBusinessOwnerCut;
                    }
                }
            }

        // 20% chance for income to be split among all GA
        if ((chance >= 16 && chance <= 35))
            if (stakedGangsters > 0) {
                returnedMsgNumber = 4;
                uint256 eachGangsterCut = finalWorkerReward / (stakedGangsters);
                finalWorkerReward = 0;
                if (stakedGangsters == 1) {
                    uint256 key1 = gangsterMap.getKeyAtIndex(0);
                    tokenIdReward[key1] += eachGangsterCut;
                } else {
                    for (uint256 i = 0; i <= stakedGangsters - 1; i++) {
                        uint256 key = gangsterMap.getKeyAtIndex(i);
                        tokenIdReward[key] += eachGangsterCut;
                    }
                }
            }

        // 15% chance for all tokens to get burned
        if ((chance >= 36 && chance <= 50)) {
            IERC20(ErcAddress).transfer(address(0), finalWorkerReward);
            finalWorkerReward = 0;
            returnedMsgNumber = 5;
        }

        

        if (finalWorkerReward != 0) {
            tokenIdReward[tokenId] = 0;
            lastClaimedReward[tokenId] = block.timestamp;

            IERC20(ErcAddress).transfer(msg.sender, finalWorkerReward);
            IERC721(NftAddress).safeTransferFrom(
                address(this),
                ownerOfDeposit[tokenId],
                tokenId
            );
        }

        emit EtherJsLogger(returnedMsgNumber, finalWorkerReward);
        emit WOUnstaked(tokenId, block.timestamp, msg.sender);
        
        return returnedMsgNumber;
    }

    function claimRewardLandlord(uint256 tokenId) external payable returns (bool) {

        uint256 finalLandlordReward = tokenIdReward[tokenId];

        if(IERC721(NftAddress).checkIfLandlord(tokenId) != true) revert Unauthorized();
        if(ownerOfDeposit[tokenId] != msg.sender) revert Unauthorized();
        if(finalLandlordReward < 25000 * 1 ether) revert InsufficientFunds();
 

        // Distribute Gangster cut 5%
        if (stakedGangsters > 0) {
            uint256 gangsterBonus = (finalLandlordReward * (5)) / (100);
            uint256 eachGangsterCut = gangsterBonus / (stakedGangsters);
            finalLandlordReward -= gangsterBonus;
            if (stakedGangsters == 1) {
                uint256 key1 = gangsterMap.getKeyAtIndex(0);
                tokenIdReward[key1] += eachGangsterCut;
            } else {
                for (uint256 i = 0; i <= stakedGangsters - 1; i++) {
                    uint256 key = gangsterMap.getKeyAtIndex(i);
                    tokenIdReward[key] += eachGangsterCut;
                }
            }
        }

        if (finalLandlordReward != 0) {
            lastClaimedReward[tokenId] = block.timestamp;
            tokenIdReward[tokenId] = 0;
            IERC20(ErcAddress).transfer(msg.sender, finalLandlordReward);
        }

        emit EtherJsLogger(1, finalLandlordReward);
        return true;
    }

    function unstakeLandlord(
        uint256 randomness,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 tokenId
    ) external payable returns (uint256) {

        uint256 finalLandlordReward = tokenIdReward[tokenId];
        uint256 returnedMsgNumber = 1;
        string memory randomnessString = uint2str(randomness);

        stakedLandlords--;
        landlordMap.remove(tokenId);

        if(IERC721(NftAddress).checkIfLandlord(tokenId) != true) revert Unauthorized();
        if(finalLandlordReward < 25000 * 1 ether) revert InsufficientFunds();
        if(verifyRandomness(randomnessString, v, r, s) != randomnessProviderV1) revert Unauthorized();

        uint256 chance = (randomness % 100) + 1;
        bool hasLostNft = false;

        // 15% chance for token burn
        if ((chance >= 1 && chance <= 15)) {
            IERC20(ErcAddress).transfer(address(0), finalLandlordReward);
            finalLandlordReward = 0;
            returnedMsgNumber = 2;
        }

        // 10% chance for income to be split among all GA
        if ((chance >= 16 && chance <= 25))
            if (stakedGangsters > 0) {
                returnedMsgNumber = 3;
                uint256 eachGangsterCut = finalLandlordReward / (stakedGangsters);
                finalLandlordReward = 0;
                if (stakedGangsters == 1) {
                    uint256 key1 = gangsterMap.getKeyAtIndex(0);
                    tokenIdReward[key1] += eachGangsterCut;
                } else {
                    for (uint256 i = 0; i <= stakedGangsters - 1; i++) {
                        uint256 key = gangsterMap.getKeyAtIndex(i);
                        tokenIdReward[key] += eachGangsterCut;
                    }
                }
            }


        // 2% chance for NFT to be rewarded among a random gangster
        if ((chance >= 26 && chance <= 27))
            if (stakedGangsters > 0) {
                returnedMsgNumber = 4;
                if (stakedGangsters == 1) {
                    hasLostNft = true;
                    uint256 key1 = gangsterMap.getKeyAtIndex(0);
                    IERC721(NftAddress).safeTransferFrom(
                        address(this),
                        ownerOfDeposit[key1],
                        tokenId
                    );
                } else {
                    hasLostNft = true;
                    uint256 gangsterWhichGetsTheNft = (randomness % stakedGangsters) + 1;
                    uint256 key = gangsterMap.getKeyAtIndex(gangsterWhichGetsTheNft);
                    IERC721(NftAddress).safeTransferFrom(
                        address(this),
                        ownerOfDeposit[key],
                        tokenId
                    );
                }
            }


        if (hasLostNft == false)
        {
            IERC721(NftAddress).safeTransferFrom(
                address(this),
                ownerOfDeposit[tokenId],
                tokenId
            );
        }

        if (finalLandlordReward != 0) 
        {
            lastClaimedReward[tokenId] = block.timestamp;
            tokenIdReward[tokenId] = 0;
            IERC20(ErcAddress).transfer(msg.sender, finalLandlordReward);
        }

        
        emit EtherJsLogger(returnedMsgNumber, finalLandlordReward);
        emit LLUnstaked(tokenId, block.timestamp, msg.sender);
        return returnedMsgNumber;
    }

    function claimRewardBusinessOwner(
        uint256 randomness,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 tokenId
    ) external payable returns (uint256) {

        uint256 returnedMsgNumber = 1;
        uint256 finalBusinessOwnerReward = tokenIdReward[tokenId];
        uint256 chance = (randomness % 100) + 1;

        string memory randomnessString = uint2str(randomness);

        if(IERC721(NftAddress).checkIfBusinessOwner(tokenId) != true) revert Unauthorized();
        if(ownerOfDeposit[tokenId] != msg.sender) revert Unauthorized();
        if(finalBusinessOwnerReward < 50000 * 1 ether) revert Unauthorized();
        if(verifyRandomness(randomnessString, v, r, s) != randomnessProviderV1) revert Unauthorized();

        // Distribute Gangster cut 5%
        if (stakedGangsters > 0) {
            uint256 gangsterBonus = (finalBusinessOwnerReward * (5)) / (100);
            uint256 eachGangsterCut = gangsterBonus / (stakedGangsters);
            finalBusinessOwnerReward -= gangsterBonus;
            if (stakedGangsters == 1) {
                uint256 key1 = gangsterMap.getKeyAtIndex(0);
                tokenIdReward[key1] += eachGangsterCut;
            } else {
                for (uint256 i = 0; i <= stakedGangsters - 1; i++) {
                    uint256 key = gangsterMap.getKeyAtIndex(i);
                    tokenIdReward[key] += eachGangsterCut;
                }
            }
        }

        if ((chance >= 1 && chance <= 50)) {
            uint256 burnAmount = (finalBusinessOwnerReward * (25)) / (100);
            finalBusinessOwnerReward -= burnAmount;
            IERC20(ErcAddress).transfer(address(0), burnAmount);
            returnedMsgNumber = 2;
        }

        if (finalBusinessOwnerReward != 0)
        {
            lastClaimedReward[tokenId] = block.timestamp;
            tokenIdReward[tokenId] = 0;
            IERC20(ErcAddress).transfer(
                msg.sender,
                finalBusinessOwnerReward
            );
        }

        emit EtherJsLogger(returnedMsgNumber, finalBusinessOwnerReward);
        return returnedMsgNumber;
    }

    function unstakeBusinessOwner(
        uint256 randomness,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 tokenId
    ) external payable returns (uint256) {

        uint256 finalBusinessOwnerReward = tokenIdReward[tokenId];
        uint256 returnedMsgNumber = 1;

        string memory randomnessString = uint2str(randomness);
                
        stakedBusinessOwners--;
        businessOwnerMap.remove(tokenId);

        if(IERC721(NftAddress).checkIfBusinessOwner(tokenId) != true) revert Unauthorized();
        if(finalBusinessOwnerReward < 50000 * 1 ether) revert InsufficientFunds();
        if(verifyRandomness(randomnessString, v, r, s) != randomnessProviderV1) revert Unauthorized();

        uint256 chance = (randomness % 100) + 1;

        bool hasLostNft = false;
        bool haveTokensBurned = false;

        // 10% chance for token burn
        if ((chance >= 1 && chance <= 10)) {
            haveTokensBurned = true;
            IERC20(ErcAddress).transfer(
                address(0),
                finalBusinessOwnerReward
            );
            finalBusinessOwnerReward = 0;
            returnedMsgNumber = 2;
        }

        // 5% chance for income to be split among gangsters
        if ((chance >= 11 && chance <= 15))
            if (stakedGangsters > 0) {
                returnedMsgNumber = 3;
                uint256 eachGangsterCut = finalBusinessOwnerReward /
                    (stakedGangsters);
                finalBusinessOwnerReward = 0;
                if (stakedGangsters == 1) {
                    uint256 key1 = gangsterMap.getKeyAtIndex(0);
                    tokenIdReward[key1] += eachGangsterCut;
                } else {
                    for (uint256 i = 0; i <= stakedGangsters - 1; i++) {
                        uint256 key = gangsterMap.getKeyAtIndex(i);
                        tokenIdReward[key] += eachGangsterCut;
                    }
                }
            }

        // 1% chance for NFT to be rewarded among a random gangster
        if (chance == 16)
            if (stakedGangsters > 0) {
                returnedMsgNumber = 4;
                if (stakedGangsters == 1) {
                    hasLostNft = true;
                    uint256 key1 = gangsterMap.getKeyAtIndex(0);
                    IERC721(NftAddress).safeTransferFrom(
                        address(this),
                        ownerOfDeposit[key1],
                        tokenId
                    );
                } else {
                    hasLostNft = true;
                    uint256 gangsterWhichGetsTheNft = (randomness %
                        stakedGangsters) + 1;
                    uint256 key = gangsterMap.getKeyAtIndex(
                        gangsterWhichGetsTheNft
                    );
                    IERC721(NftAddress).safeTransferFrom(
                        address(this),
                        ownerOfDeposit[key],
                        tokenId
                    );
                }
            }

        //85% chance to unstake and claim token

        if (hasLostNft == false)
            IERC721(NftAddress).safeTransferFrom(
                address(this),
                ownerOfDeposit[tokenId],
                tokenId
            );

        if (finalBusinessOwnerReward != 0 && haveTokensBurned == false)
        {
            lastClaimedReward[tokenId] = block.timestamp;
            tokenIdReward[tokenId] = 0;
            IERC20(ErcAddress).transfer(
                msg.sender,
                finalBusinessOwnerReward
            );
        }       

        emit EtherJsLogger(returnedMsgNumber, finalBusinessOwnerReward);
        emit BOUnstaked(tokenId, block.timestamp, msg.sender);

        return returnedMsgNumber;
    }

    function claimRewardGangster(
        uint256 randomness,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 tokenId
    ) external payable returns (uint256) {

        uint256 returnedMsgNumber = 1;
        uint256 finalGangsterReward = tokenIdReward[tokenId];
        uint256 chance = (randomness % 100) + 1;

        string memory randomnessString = uint2str(randomness);

        if(IERC721(NftAddress).checkIfGangster(tokenId) != true) revert Unauthorized();
        if(ownerOfDeposit[tokenId] != msg.sender) revert Unauthorized();
        if(finalGangsterReward < 75000 * 1 ether) revert InsufficientFunds();
        if(verifyRandomness(randomnessString, v, r, s) != randomnessProviderV1) revert Unauthorized();

        if ((chance >= 1 && chance <= 50)) {
            uint256 bribeAmount = (finalGangsterReward * (25)) / (100);
            finalGangsterReward -= bribeAmount;
            returnedMsgNumber = 2;
        }


        if (finalGangsterReward != 0)
        {
            lastClaimedReward[tokenId] = block.timestamp;
            tokenIdReward[tokenId] = 0;
            IERC20(ErcAddress).transfer(msg.sender, finalGangsterReward);
        }

        emit EtherJsLogger(returnedMsgNumber, finalGangsterReward);
        return finalGangsterReward;
    }

    function unstakeGangster(
        uint256 randomness,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 tokenId
    ) external payable  returns (bool) {

        stakedGangsters--;
        gangsterMap.remove(tokenId);

        uint256 returnedMsgNumber = 2;
        uint256 finalGangsterReward = tokenIdReward[tokenId];
        uint256 chance = (randomness % 100) + 1;

        string memory randomnessString = uint2str(randomness);

        if(IERC721(NftAddress).checkIfGangster(tokenId) != true) revert Unauthorized();
        if(ownerOfDeposit[tokenId] != msg.sender) revert Unauthorized();
        if(finalGangsterReward < 75000 * 1 ether) revert InsufficientFunds();
        if(verifyRandomness(randomnessString, v, r, s) != randomnessProviderV1) revert Unauthorized();


        if ((chance >= 1 && chance <= 75)) {
            finalGangsterReward = 0;
            returnedMsgNumber = 1;
        }


        if (finalGangsterReward != 0) 
        {
          tokenIdReward[tokenId] = 0;
          lastClaimedReward[tokenId] = block.timestamp;
          IERC20(ErcAddress).transfer(msg.sender, finalGangsterReward);
        }

        IERC721(NftAddress).safeTransferFrom(
                address(this),
                ownerOfDeposit[tokenId],
                tokenId
            );

        emit EtherJsLogger(returnedMsgNumber, finalGangsterReward);
        emit GAUnstaked(tokenId, block.timestamp, msg.sender);
        return true;
    }
}