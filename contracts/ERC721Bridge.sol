pragma solidity ^0.4.23;

import "./PausableDSAuth.sol";
import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";
import "./interfaces/ISettingsRegistry.sol";
import "./SettingIds.sol";
import "./interfaces/IInterstellarEncoderV3.sol";
import "./interfaces/IMintableERC20.sol";


contract ERC721Bridge is SettingIds, PausableDSAuth {

    // type
    struct LinkStatus {
        uint256 linkTokenId;
        bool isBridgedIn;
    }

// TODO: later
//    struct WorkStatus {
//
//    }

    /*
     *  Storage
    */
    bool private singletonLock = false;

    ISettingsRegistry public registry;

    ERC721 public originNft;

    uint128 public lastObjectId;

    // tokenId_outside_evolutionLand => tokenId_inside
    mapping(uint256 => LinkStatus) public tokenIdOut2In;

    // tokenId_inside => tokenId_outside
    mapping(uint256 => LinkStatus) public tokenIdIn2Out;



    /*
    *  Event
    */
    event BridgeIn(uint256 originTokenId, uint256 tokenId, address originContract, address owner);


    /*
    *  Modifiers
    */
    modifier singletonLockCall() {
        require(!singletonLock, "Only can call once");
        _;
        singletonLock = true;
    }

    function initializeContract(ISettingsRegistry _registry, ERC721 _originNft) public singletonLockCall {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
        registry = _registry;
        originNft = _originNft;
    }

    function bridgeIn(uint256 _originTokenId) public {
        require(originNft.ownerOf(_originTokenId) == msg.sender, "Invalid owner!");

        // not the first time to bridge in
        if(tokenIdOut2In[_originTokenId].linkTokenId != 0) {
            tokenIdOut2In[_originTokenId].isBridgedIn = true;
            tokenIdIn2Out[tokenIdOut2In[_originTokenId].linkTokenId].isBridgedIn = true;

        } else {
            // first time to bridge in
            lastObjectId += 1;

            IInterstellarEncoderV3 interstellarEncoder = IInterstellarEncoderV3(registry.addressOf(SettingIds.CONTRACT_INTERSTELLAR_ENCODER));
            address objectOwnership = registry.addressOf(SettingIds.CONTRACT_OBJECT_OWNERSHIP);
            uint256 tokenId = interstellarEncoder.encodeTokenIdForOuterObjectContract(address(this), address(originNft), lastObjectId);

            // link objects_in and objects_out
            tokenIdOut2In[_originTokenId].linkTokenId = tokenId;
            tokenIdOut2In[_originTokenId].isBridgedIn = true;
            tokenIdIn2Out[tokenId].linkTokenId = _originTokenId;
            tokenIdIn2Out[tokenId].isBridgedIn = true;
            // keep new mirror object in this contract
            // before the owner has transferred his/her outerObject into this contract
            // mirror object can not be transferred
            IMintableERC20(objectOwnership).mint(address(this), tokenId);
        }


        emit BridgeIn(_originTokenId, tokenId, address(originNft), msg.sender);
    }



    function bridgeOut(uint256 _tokenId) public {
        require(isValid(_tokenId), "already bridged out!");
        uint256 originTokenId = tokenIdIn2Out[_tokenId].linkTokenId;
        require(originNft.ownerOf(originTokenId) == msg.sender, "You have no right.");


        tokenIdIn2Out[_tokenId].isBridgedIn = false;
        tokenIdOut2In[originTokenId].isBridgedIn = false;
    }


    // this need to be checked every time
    function isValid(uint256 _tokenId) public view returns (bool) {
        return tokenIdIn2Out[_tokenId].isBridgedIn;
    }

}
