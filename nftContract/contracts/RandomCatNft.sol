// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "hardhat/console.sol";

error RandomIpfsNft__AlreadyInitialized();
error RandomIpfsNft__NeedMoreETHSent();
error RandomIpfsNft__RangeOutOfBounds();
error RandomIpfsNft__TransferFailed();

contract RandomIpfsNft is ERC721URIStorage, VRFConsumerBaseV2, Ownable {
    // Types
    enum Breed {
        PERSIAN_CAT,    
        BRITISH_CAT,
        SIAMESE_CAT
        
    }

    // Chainlink VRF Variables
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;

    // NFT Variables
    uint256 private immutable i_mintFee=100000000000000000;
    uint256 private s_tokenCounter;
    uint256 internal constant MAX_CHANCE_VALUE = 100;
    string[] internal s_catTokenUris;
    bool private s_initialized;

    // VRF Helpers
    mapping(uint256 => address) public s_requestIdToSender;

    // Events
    event NftRequested(uint256 indexed requestId, address requester);
    event NftMinted(Breed breed, address minter);

    constructor(
     
        
    ) VRFConsumerBaseV2(0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed) ERC721("Random IPFS NFT", "RIN") {
        i_vrfCoordinator = VRFCoordinatorV2Interface(0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed);
        i_gasLane = 0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f;
        i_subscriptionId = 4451;
       
        i_callbackGasLimit = 2000000;
        _initializeContract();
        s_tokenCounter = 0;
    }

    function requestNft() public payable returns (uint256 requestId) {
        if (msg.value < i_mintFee) {
            revert RandomIpfsNft__NeedMoreETHSent();
        }
        requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );

        s_requestIdToSender[requestId] = msg.sender;
        emit NftRequested(requestId, msg.sender);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        address catOwner = s_requestIdToSender[requestId];
        uint256 newItemId = s_tokenCounter;
        s_tokenCounter = s_tokenCounter + 1;
        uint256 moddedRng = randomWords[0] % MAX_CHANCE_VALUE;
        Breed catBreed = getBreedFromModdedRng(moddedRng);
        _safeMint(catOwner, newItemId);
        _setTokenURI(newItemId, s_catTokenUris[uint256(catBreed)]);
        emit NftMinted(catBreed, catOwner);
    }

    function getChanceArray() public pure returns (uint256[3] memory) {
        return [10, 40, MAX_CHANCE_VALUE];
    }

    function _initializeContract() internal {
    if (s_initialized) {
        revert RandomIpfsNft__AlreadyInitialized();
    }
    s_catTokenUris.push("https://bafybeievxj4a3ufex7eza2sl6qrrs6feiwajnngwxslb4mpy47kkmtj2nq.ipfs.nftstorage.link/1.json"); // Set the token URI for Breed.PERSIAN_CAT
    s_catTokenUris.push("https://bafybeievxj4a3ufex7eza2sl6qrrs6feiwajnngwxslb4mpy47kkmtj2nq.ipfs.nftstorage.link/2.json"); // Set the token URI for Breed.BRITISH_CAT
    s_catTokenUris.push("https://bafybeievxj4a3ufex7eza2sl6qrrs6feiwajnngwxslb4mpy47kkmtj2nq.ipfs.nftstorage.link/3.json"); // Set the token URI for Breed.SIAMESE_CAT
    s_initialized = true;
}

    function getBreedFromModdedRng(uint256 moddedRng) public pure returns (Breed) {
      
        if(moddedRng<10){
            return Breed(0);
        }
        else if(moddedRng>9 && moddedRng<40){
            return Breed(1);
        }
        else if(moddedRng>39 && moddedRng<100){
            return Breed(2);
        }
        revert RandomIpfsNft__RangeOutOfBounds();
    }

    function withdraw() public onlyOwner {
        uint256 amount = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) {
            revert RandomIpfsNft__TransferFailed();
        }
    }

    function getMintFee() public view returns (uint256) {
        return i_mintFee;
    }

    function getcatTokenUris(uint256 index) public view returns (string memory) {
        return s_catTokenUris[index];
    }

    function getInitialized() public view returns (bool) {
        return s_initialized;
    }

    function getTokenCounter() public view returns (uint256) {
        return s_tokenCounter;
    }
}