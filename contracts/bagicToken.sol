//bagic token for banbook

pragma solidity >= 0.5.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract bagicToken is ERC20, Ownable {

    constructor () ERC20("Bagic", "BG"){}

    mapping(address => bool) controller;

    modifier onlyController {
        require(controller[msg.sender] == true);
        _;
    }

    function setController(address _address) external onlyOwner{
        controller[_address] = true;
    }
        
    function mint(address to, uint256 amount) external onlyController{
        _mint(to, amount);
    }

    function burn(address to, uint256 amount) external onlyController{
        _burn(to, amount);
    }
}
    