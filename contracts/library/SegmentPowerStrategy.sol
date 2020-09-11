
pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../interface/IPowerStrategy.sol";
import "./Governance.sol";

contract SegmentPowerStrategy is IPowerStrategy, Governance {
    using SafeMath for uint256;
    ////
    struct degoSegment {
        uint256 min;
        uint256 max;
    }
    struct countSegment {
        uint32 length;
        uint32 curCount;
    }
    struct playerInfo {
        uint256 amount;
        uint8 segIndex;
        uint32 playerId;
        uint32 offset;
    }

    mapping(address => uint32) public _addressXId;
    mapping(uint8 => degoSegment) public _degoSegment;
    mapping(uint8 => countSegment) public _countSegment;
    mapping(uint8 => mapping(uint32 => uint32)) public _playerIds;
    mapping(uint32 => playerInfo) public _playerMap;

    uint8[3] public _ruler = [8, 1, 1];
    uint8[3] public _factor = [1, 3, 5];

    uint8 public _high = 3;
    uint8 public _mid = 2;
    uint8 public _low = 1;

    uint32 public _playerId = 0;
    uint32 public _base = 100;
    uint32 public _anchor = _base;
    uint32 public _grouthCondition = 100;
    uint32 public _grouthStep = 10;
    uint32 constant public _highMax = 50;
    uint32 constant public _midMax = 50;

    uint256 constant public  _initMaxValue = 10000 * (10**18);

    address public _contractCaller = address(0x0);

    /**
     * check pool
     */
    modifier isNormalPool(){
        require( msg.sender==_contractCaller,"invalid pool address!");
        _;
    }

    constructor()
        public
    {
        _playerId = 0;

        initSegment();
        updateRuler(_initMaxValue);
    }

    function lpIn(address sender, uint256 amount) 
    isNormalPool()
    external {

        uint32 playerId = _addressXId[sender];
        if ( playerId > 0 ) {
            _playerMap[playerId].amount = _playerMap[playerId].amount.add(amount);
        } else {
            //new addr
            _playerId = _playerId+1;
            _addressXId[sender] = _playerId;

            playerId = _playerId;
            _playerMap[playerId].playerId = playerId;
            _playerMap[playerId].amount = amount;
            _playerMap[playerId].segIndex = 0;
            _playerMap[playerId].offset =  0;

            //update segment
            updateSegment();
        }

        settlePowerData(playerId);
    }

    function lpOut(address sender, uint256 amount) 
    isNormalPool()
    external{
        uint32 playerId = _addressXId[sender];
        if ( playerId > 0 ) {
            _playerMap[playerId].amount = _playerMap[playerId].amount.sub(amount);
        } else {
            return;
        }

        settlePowerData(playerId);
    }
    
    function getPower(address sender) 
    view external
    returns (uint256) {

        uint32 playerId = _addressXId[sender];
        if ( playerId > 0 ) {
            uint8 segment = _playerMap[playerId].segIndex;
            if(segment>0){
                return uint256(_factor[segment-1]).mul(_playerMap[playerId].amount);
            }
        }

        return 0;
    }


    function setCaller( address caller ) public  onlyGovernance{
        _contractCaller = caller;
    }

    function updateRuler( uint256 maxCount ) internal{

        uint256 lastBegin = 0;
        uint256 lastEnd = 0;
        uint256 splitPoint = 0;
        for (uint8 i = 1; i <= _ruler.length; i++) {
            splitPoint = maxCount * _ruler[i - 1]/10;
            if (splitPoint <= 0) {
                splitPoint = 1;
            }
            lastEnd = lastBegin + splitPoint;
            if (i == _ruler.length) {
                lastEnd = maxCount;
            }
            _degoSegment[i].min = lastBegin + 1;
            _degoSegment[i].max = lastEnd;
            lastBegin = lastEnd;
        }
    }

    function initSegment() internal {    

        _countSegment[_low].length = 80;
        _countSegment[_mid].length = 10;
        _countSegment[_high].length = 10;

        _countSegment[_low].curCount = 0;
        _countSegment[_mid].curCount = 0;
        _countSegment[_high].curCount = 0;
    }

    function updateSegment( ) internal {

        if (_playerId >= _grouthCondition+_anchor ) {
            if (_countSegment[_high].length + _grouthStep > _highMax) {
                _countSegment[_high].length = _highMax;
            } else {
                _countSegment[_high].length = _countSegment[_high].length+_grouthStep;
            }

            if (_countSegment[_mid].length + _grouthStep > _midMax) {
                _countSegment[_mid].length = _midMax;
            } else {
                _countSegment[_mid].length = _countSegment[_mid].length+_grouthStep;
            }
            _anchor = _playerId;
        }
    }

    function hasCountSegmentSlot(uint8 segIndex) internal view returns (bool){
        uint32 value = _countSegment[segIndex].length-_countSegment[segIndex].curCount;
        if (value > 0) {
            return true;
        } else {
            return false;
        }
    }

    function findSegmentMinPlayer(uint8 segIndex) internal view returns (uint32,uint256){
        uint256 firstMinAmount = _degoSegment[segIndex].max;
        uint256 secondMinAmount = _degoSegment[segIndex].max;
        uint32 minPlayerOffset = 0;
        for (uint8 i = 0; i < _countSegment[segIndex].curCount; i++) {
            uint32 playerId = _playerIds[segIndex][i];
            if( playerId==0 ){
                continue;
            }
            uint256 amount = _playerMap[playerId].amount;

            //find min amount;
            if ( amount < firstMinAmount) {
                if (firstMinAmount < secondMinAmount) {
                    secondMinAmount = firstMinAmount;
                }
                firstMinAmount = amount;
                minPlayerOffset = i;
            }else{
                //find second min amount
                if(amount < secondMinAmount ){
                    secondMinAmount = amount;
                }
            }
        }

        return (minPlayerOffset,secondMinAmount);
    }

    //swap the player data from old segment to the new segment
    function segmentSwap(uint32 playerId, uint8 segIndex) internal {

        uint8 oldSegIndex = _playerMap[playerId].segIndex;

        uint32 oldOffset = _playerMap[playerId].offset;
        uint32 tail = _countSegment[segIndex].curCount;

        _playerMap[playerId].segIndex = segIndex;
        _playerMap[playerId].offset = tail;

        _countSegment[segIndex].curCount = _countSegment[segIndex].curCount+1;
        _playerIds[segIndex][tail] = playerId;

        if (oldSegIndex>0 && segIndex != oldSegIndex && _playerIds[oldSegIndex][oldOffset] > 0) {

            uint32 originTail = _countSegment[oldSegIndex].curCount-1;
            uint32 originTailPlayer = _playerIds[oldSegIndex][originTail];

            if(originTailPlayer != playerId){

                _playerMap[originTailPlayer].segIndex = oldSegIndex;
                _playerMap[originTailPlayer].offset = oldOffset;
                _playerIds[oldSegIndex][oldOffset] = originTailPlayer;
            }

            _playerIds[oldSegIndex][originTail] = 0;
            _countSegment[oldSegIndex].curCount = _countSegment[oldSegIndex].curCount-1;
        }
    }

    //swap the player data with tail 
    function tailSwap( uint8 segIndex) internal returns (uint32){

        uint32 minPlayerOffset;
        uint256 secondMinAmount;
        (minPlayerOffset,secondMinAmount) = findSegmentMinPlayer(segIndex);
        _degoSegment[segIndex].min = secondMinAmount;

        uint32 leftPlayerId = _playerIds[segIndex][minPlayerOffset];

        //segmentSwap to reset
        uint32 tail = _countSegment[segIndex].curCount - 1;
        uint32 tailPlayerId = _playerIds[segIndex][tail];
        _playerIds[segIndex][minPlayerOffset] = tailPlayerId;

        _playerMap[tailPlayerId].offset = minPlayerOffset;

        return leftPlayerId;
    }

    function joinHigh(uint32 playerId) internal {
        uint8 segIndex = _high;
        if (hasCountSegmentSlot(segIndex)) {
            segmentSwap(playerId, segIndex);
        } else {
            uint32 leftPlayerId = tailSwap(segIndex);
            joinMid(leftPlayerId);
            segmentSwap(playerId, segIndex);

        }
    }

    function joinMid(uint32 playerId) internal {
        uint8 segIndex = _mid;
        if (hasCountSegmentSlot(segIndex)) {
            segmentSwap(playerId, segIndex);
        } else {
            uint32 leftPlayerId = tailSwap(segIndex);
            joinLow(leftPlayerId);
            segmentSwap(playerId, segIndex);
        }
        _degoSegment[segIndex].max = _degoSegment[segIndex + 1].min;
    }

    function joinLow(uint32 playerId) internal {

        uint8 segIndex = _low;
        segmentSwap(playerId, segIndex);
        _degoSegment[segIndex].max = _degoSegment[segIndex + 1].min;
        //_low segment length update
        if( _countSegment[segIndex].curCount > _countSegment[segIndex].length){
            _countSegment[segIndex].length = _countSegment[segIndex].curCount;
        }
    }

    function settlePowerData(uint32 playerId) internal {

        uint256 amount = _playerMap[playerId].amount;
        uint8 segIndex = 0;
        for (uint8 i = 1; i <= _high; i++) {
            if (amount < _degoSegment[i].max) {
                segIndex = i;
                break;
            }
        }
        if (segIndex == 0) {
            _degoSegment[_high].max = amount;
            segIndex = _high;
        }

        if (_playerMap[playerId].segIndex == segIndex) {
            return;
        }

        if (segIndex == _high) {
            joinHigh(playerId);
        } else if (segIndex == _mid) {
            joinMid(playerId);
        } else {
            joinLow(playerId);
        }
    }

    ////////////////////////////
}