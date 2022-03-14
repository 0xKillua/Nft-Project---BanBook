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

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "Banbook/ERC721B.sol";

contract banbook is ERC721B, Ownable {
    constructor() ERC721("BANBOOK", "BK") {}

    uint256 NUMBEROFBOOK = 3333;
    uint256 MINTPRICE = 0.02 ether;
    uint256 MAXPERTX = 5;
    uint256 MAXPAGE = 5000;



    mapping(uint256 => banger) public _ownerOf;
    mapping(address => uint256) public balanceOf;
    mapping(address => bool) public state;

    event banned(address from, address to, uint256 pageburnt);
    event unbanned(address from, address to, uint256 count);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "Banbook: transfer caller is not owner nor approved"
        );
        require(_ownerOf[tokenId].stakedAt == 0);
        _transfer(from, to, tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        require(
            ERC721.ownerOf(tokenId) == from,
            "ERC721: transfer from incorrect owner"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }
}
