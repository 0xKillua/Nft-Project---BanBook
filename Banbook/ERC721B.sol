    // SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

interface bagicToken{
    function mint(address to_, uint256 amount_) external;
    function balanceOf(address account) external view returns (uint256);
    function _burn(address account, uint256 amount) external;
}


contract Banbook is Ownable, ERC721Enumerable{


    string public _name; string public _symbol;

    struct banger {
        uint256 stakedAt;
        uint256 pagesAvailable;
        uint256 maxPages;
        bool ban;
    }

    struct status {
        bool isBanned;
        uint256 ashToken;
        uint256 count;
    }

    bagicToken public bagic;


    mapping(uint256 => banger) public _banger;

    mapping(address => status) public addressStatus;

    mapping(uint256 => address) public _owners;

    mapping(address => uint256) public _balances;

    mapping(address => uint256) public stakedAmount;

   

    // Mapping from token ID to approved address
    mapping(uint256 => address) public _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) public _operatorApprovals;

    // Events
    
    event statusChanged(address from, address to, bool banned, uint256 count);
    event staked(address from, uint tokenId, uint timestamp);
    event unstaked(address from, uint tokenId, uint timestamp);


    constructor(address _address) ERC721("Banbook", "BK"){
        bagic = bagicToken(_address);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
 



    /**
     * @dev See {IERC721-balanceOf}.
     */
    // function balanceOf(address owner) public view virtual override returns (uint256) {
    //     return _balances[owner];
    // }

    // /**
    //  * @dev See {IERC721-ownerOf}.
    //  */
    // function ownerOf(uint256 tokenId) public view virtual override returns (address) {
    //     return _banger[tokenId]._address;
    // }

    //Staking Function

    function stakeBook(uint256 tokenId) external {
        require(_exists(tokenId));
        require(!isStaked(tokenId));
        _banger[tokenId].stakedAt = block.timestamp;
        stakedAmount[msg.sender] += 1;
        emit staked(msg.sender, tokenId, block.timestamp);
    }

    function unStakeBook(uint256 tokenId) external {
        require(_exists(tokenId));
        require(isStaked(tokenId));
        _banger[tokenId].stakedAt = 0;
        stakedAmount[msg.sender] -= 1;
        emit unstaked(msg.sender, tokenId, block.timestamp);
    }

    function isStaked(uint256 tokenId) public view returns(bool) {
        return _banger[tokenId].stakedAt != 0;
    }


    //Flip Status function

    function flip(address toBan, uint tokenId) external {
        require(_owners[tokenId] == msg.sender, "You are not the owner");
        require(isStaked(tokenId), "You have to stake your book before banning");
        uint cost = 4 ** addressStatus[toBan].count;
        require(_banger[tokenId].pagesAvailable >= cost, "You don't have enough pages to flip");
        
        if(!addressStatus[toBan].isBanned){     //if status = not banned, ban
            _banger[tokenId].pagesAvailable -= cost;
            addressStatus[toBan].isBanned = true;
        }
        else{                                   //unban
            _banger[tokenId].pagesAvailable -= cost;
            addressStatus[toBan].isBanned = false;
            addressStatus[toBan].count += 1;   //update count after unban
        }

        _updateAshToken(cost);
        
        emit statusChanged(msg.sender, toBan, addressStatus[toBan].isBanned, addressStatus[msg.sender].count);
    }

    //yield

    function checkYield(uint256 tokenId) internal view returns(uint256){
        uint256 yield;
        return yield = ((block.timestamp - _banger[tokenId].stakedAt)/3600) * 30;
    }

    //check bagic amount

    function claimBagic(address _address) external returns(uint256){
        require(msg.sender == _address);
        require(stakedAmount[msg.sender] > 0);
        uint256 totalBagic;
        for (uint256 i; i < balanceOf(_address); i++){
            totalBagic += checkYield(tokenOfOwnerByIndex(_address, i));
            _banger[tokenOfOwnerByIndex(_address, i)].stakedAt = block.timestamp; //reset time
        }
        bagic.mint(msg.sender, totalBagic);
        return totalBagic;
    }


    //burn bagic to get back pages

    function restorePages(uint256 tokenId) external {
        require(_owners[tokenId] == msg.sender, "You are not the owner");
        require(bagic.balanceOf((_owners[tokenId])) >= 5000, "You don't have enough bagic");
        _banger[tokenId].pagesAvailable += _banger[tokenId].maxPages/4;
        bagic._burn(msg.sender, 5000);
    }

    function _updateAshToken(uint256 pageBurnt) internal {
        addressStatus[msg.sender].ashToken += pageBurnt;
    }

    function revertCount() external {
        uint currentCount = addressStatus[msg.sender].count;
        require(currentCount > 0, "Count already equal to 0!");
        require(addressStatus[msg.sender].ashToken >= 2 ** (currentCount));
        addressStatus[msg.sender].ashToken -= 2 **(currentCount);
        addressStatus[msg.sender].count -= 1;
    }



















}

