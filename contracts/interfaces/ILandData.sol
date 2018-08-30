pragma solidity ^0.4.24;

contract ILandData {

    function batchModifyResources(uint _tokenId, uint _goldRate, uint _woodRate, uint _waterRate, uint _fireRate, uint _soilRate) public;

    function modifyAttributes(uint _tokenId, uint _right, uint _left, uint _newValue) public;

    function isReserved(uint256 _tokenId) public view returns (bool);
    function isSpecial(uint256 _tokenId) public view returns (bool);
    function hasBox(uint256 _tokenId) public view returns (bool);

    function getDetailsFromLandInfo(uint _tokenId)
    public
    view
    returns (
        uint goldRate,
        uint woodRate,
        uint waterRate,
        uint fireRate,
        uint soilRate,
        uint flag);

    function encodeTokenId(int _x, int _y) pure public returns (uint);


}