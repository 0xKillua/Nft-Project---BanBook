
// Staking the book into the contract unlock ‘banning’ mechanism and rewarded with token ‘Bagic’.
// There are 4 tiers of book, with legendary, epic, rare and common with each has different maximum page,
// every book minted start off with 50% of the maximum page available,
// banning/ unbanning would require to burn certain #of pages of your book base on a ‘count’ on an address,
//for each time someone is unbanned, the count goes up by 1,
//and the # of pages need to ban the same address needed would be 4^(count), e.g. an address is banned for 3 times,
//so the count is 3, the pages needed to unban is 4^3= 64pages.
//Staking a book is rewarded 30 bagic per hour per book, and burning 5000bagic can restore 25% of the maximum pages.
//Each time a page is burnt you will receive another token ‘Ash’, burning 2^(count) of ash will revert the count, e.g. count = count -1,
// Token ash and bagic can be used to mint our further projects and extensions of our game.

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

interface IBagicToken{
    function mint(address to_, uint256 amount_) external;
    function balanceOf(address account) external view returns (uint256);
    function burn(address account, uint256 amount) external;
}

contract banbook is ERC721Enumerable, Ownable {

    uint256 NUMBEROFBOOK = 3333;
    uint256 MINTPRICE = 0.02 ether;
    uint256 MAXPERTX = 5;

    struct book {
        uint256 stakedAt;
        uint256 pagesAvailable;
        uint256 maxPages;
    }
    struct status{
        bool isBanned;
        uint256 ashToken;
        uint256 count;
    }  

    mapping(uint256 => book) public _book;

    mapping(address => status) public addressStatus;

    mapping(address => uint256) public stakedAmount;

    IBagicToken public bagic;
    bool isSalesActive = true;
    uint256 public totalBanbook;

    event statusChanged(address from, address to, bool banned, uint256 count);
    event staked(address from, uint tokenId, uint timestamp);
    event unstaked(address from, uint tokenId, uint timestamp);


    constructor(address _address) ERC721("BankBook", "BB"){
        isSalesActive = false;
        bagic = IBagicToken(_address);
    }

    modifier human {
        require(tx.origin == msg.sender);
        _;
    }

    modifier staker(uint tokenId) {
        require(msg.sender == super.ownerOf(tokenId), "You are not the owner");
        require(!addressStatus[msg.sender].isBanned);
        _;
    }
    

    function ownerOf(uint256 tokenId) public view override (ERC721,IERC721)returns (address) {
        address owner = super.ownerOf(tokenId);
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        
        return _book[tokenId].stakedAt == 0? owner: address(this);  //if not staked return owner else return this contract
    }

    function approve(address to, uint256 tokenId) public override (ERC721,IERC721){
        address owner = ownerOf(tokenId);
        require(to != ownerOf(tokenId), "cannot approve to current owner");
        require(!addressStatus[msg.sender].isBanned);
        require(owner == msg.sender || super.isApprovedForAll(owner, msg.sender), "You are not the owner nor approved");
        super._approve(to, tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        require(!isStaked(tokenId), "Your book is staked");
        require(!addressStatus[from].isBanned && !addressStatus[to].isBanned, "From/TO is banned");
        super._transfer(from, to, tokenId);
    }




    //mint

    function _mint(address to, uint256 tokenId) internal override { 
        super._mint(to, tokenId);
        uint pages = uint(keccak256(abi.encodePacked(to, msg.value, tokenId, block.coinbase,block.timestamp,block.difficulty))) % 1048576 + 65536;
        _book[tokenId].maxPages = pages;
        _book[tokenId].pagesAvailable = pages/2;
    }

    function mintBanbook(uint256 amount) external payable human{
        require(isSalesActive == true, "Please wait");
        require(MAXPERTX >= amount, "You cannot mint more than 5");
        require(msg.value >= amount * MINTPRICE, "Not enough ether");

        uint tokenId = totalBanbook + 1;

        for(uint i = 0; i < amount; i++){
            _mint(msg.sender, tokenId + i);
        }

        totalBanbook += amount;
        
    }

    function stakeBook(uint256 tokenId) external staker(tokenId) {
        require(_exists(tokenId));
        require(!isStaked(tokenId));
        _book[tokenId].stakedAt = block.timestamp;
        stakedAmount[msg.sender] += 1;
        emit staked(msg.sender, tokenId, block.timestamp);
        emit Transfer(msg.sender, address(this), tokenId);
    }


    function unStakeBook(uint256 tokenId) external staker(tokenId) {
        require(_exists(tokenId), "c");
        require(isStaked(tokenId), "d");
        _claimBagicUnstake(tokenId);
        _book[tokenId].stakedAt = 0;
        stakedAmount[msg.sender] -= 1;
        
        emit unstaked(msg.sender, tokenId, block.timestamp);
        emit Transfer(address(this), msg.sender, tokenId);
    }

    function isStaked(uint256 tokenId) public view returns(bool) {
        return _book[tokenId].stakedAt != 0;
    }


    //Flip Status function

    function flip(address toBan, uint tokenId) external {
        require(super.ownerOf(tokenId) == msg.sender, "You are not the owner");
        require(isStaked(tokenId), "You have to stake your book before banning");
        uint cost = 4 ** addressStatus[toBan].count;
        require(_book[tokenId].pagesAvailable >= cost, "You don't have enough pages to flip");
        
        if(!addressStatus[toBan].isBanned){     //if status = not banned, ban
            _book[tokenId].pagesAvailable -= cost;
            addressStatus[toBan].isBanned = true;
        }
        else{                                   //unban
            _book[tokenId].pagesAvailable -= cost;
            addressStatus[toBan].isBanned = false;
            addressStatus[toBan].count += 1;   //update count after unban
        }

        _updateAshToken(cost);

        emit statusChanged(msg.sender, toBan, addressStatus[toBan].isBanned, addressStatus[msg.sender].count);
    }

    //yield

    function _checkYield(uint256 tokenId) public view returns(uint256){
        uint256 yieldRate;
        uint yield;
        yieldRate =  30 * 1e18 / uint(3600);
        yield = _book[tokenId].stakedAt > 0 ? (block.timestamp - _book[tokenId].stakedAt) * yieldRate : 0;
        return block.timestamp == _book[tokenId].stakedAt? 0: yield;
    }

    //check bagic amount

    function claimBagic(address _address) external returns(uint256){
        require(msg.sender == _address );
        require(stakedAmount[msg.sender] > 0);
        uint256 totalBagic;
        for (uint256 i; i < balanceOf(_address); i++){
            totalBagic += _checkYield(tokenOfOwnerByIndex(_address, i));
            _book[tokenOfOwnerByIndex(_address, i)].stakedAt = block.timestamp; //reset time
        }
        bagic.mint(msg.sender, totalBagic);
        return totalBagic;
    }

    function _claimBagicUnstake(uint256 tokenId) internal {
        uint256 bagicAvailable;
        bagicAvailable = _checkYield(tokenId);
        bagic.mint(msg.sender, bagicAvailable);
    }

    //burn bagic to get back pages

    function restorePages(uint256 tokenId) external {
        uint256 pagesToRestored;
        require(super.ownerOf(tokenId) == msg.sender, "You are not the owner");
        require(bagic.balanceOf((super.ownerOf(tokenId))) >= 5000 * 1e18 , "You don't have enough bagic");
        pagesToRestored = _book[tokenId].maxPages/4;
        if (_book[tokenId].pagesAvailable + pagesToRestored > _book[tokenId].maxPages){
            _book[tokenId].pagesAvailable =_book[tokenId].maxPages;
        } else {
            _book[tokenId].pagesAvailable += pagesToRestored;
        }
        bagic.burn(msg.sender, 5000 * 1e18);
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

    function flipSalesStatus() external onlyOwner{
        isSalesActive = isSalesActive == false? true: false;   
    }



    function getStatus(address _address) external view returns(bool, uint256,uint256){
        return (addressStatus[_address].isBanned, addressStatus[_address].ashToken,addressStatus[_address].count);

    }





    function withdraw() external onlyOwner{
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }
}

    