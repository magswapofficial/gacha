pragma solidity ^0.8.4;
// SPDX-License-Identifier: MIT

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract ScratchAndWin is Context, Ownable {

    IERC20 token;

    uint256 public ticketPrice = 100000 * 10**9;  // 1 ticket = 100k tokens
    uint256[] public weights = [600, 250, 75, 50, 25];
    uint256[] public prizes = [50000, 150000, 300000, 500000, 1000000];

         ///////////////////////
        // Tracker Variables //
       ///////////////////////

    bool public isActive;
    uint256 public totTicketsBought;
    uint256 public numWinningTickets;

             ////////////
            // Events //
           ////////////

    event PrizesAndWeightsUpdated(uint256[] _prizes, uint256[] _weights);
    event TicketPriceUpdated(uint256 newPrice);
    event IsActiveUpdated(bool enabled);
    event TokenUpdated(address newToken);
    event TicketResult(uint256 result);

   // constructor(IERC20 tokenAddress){
    //    token = tokenAddress;
   // }

          ////////////////////
         // Core Functions //
        ////////////////////

    function getRandom(uint256 from, uint256 to, uint256 salty) private view returns (uint256) {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp + block.difficulty +
                    ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
                    block.gaslimit +
                    ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
                    block.number +
                    salty
                )
            )
        );
        return (seed % (to - from) + from);
    }

    function testRandom(uint256 salty) public returns(uint256){
        uint256 random = getRandom(0, 999, salty);
        uint256 result;
        for(uint256 i = 0; i < prizes.length; i++){
            if(random <= weights[i]) {
              result = prizes[i];
              emit TicketResult(result);
              return result;
            }
            random -= weights[i];
        }
        result = prizes[0];
        emit TicketResult(result);
        return result;
    }


    function buyTicket(uint256 salty) public returns(uint256){
        require(token.balanceOf(msg.sender) >= ticketPrice, "Insufficient balance");
        token.transferFrom(msg.sender, address(this), ticketPrice);
        totTicketsBought++;
        uint256 random = getRandom(0, 9999, salty);
        for(uint256 i = 0; i < prizes.length; i++){
            if(random < weights[i]){
                if(prizes[i] != prizes[0]) numWinningTickets++;
                token.transfer(msg.sender, prizes[i] * 10**9);
                return prizes[i];
            }
            random -= weights[i];
        }
        return prizes[0];
    }

         //////////////////////
        // Update Functions //
       //////////////////////

   function updatePrizesAndWeights(uint256[] memory newPrizes, uint256[] memory newWeights) external onlyOwner{
       prizes = newPrizes;
       weights = newWeights;
       emit PrizesAndWeightsUpdated(newPrizes, newWeights);
   }

   function updateTicketPrice(uint256 newPrice) external onlyOwner{
       ticketPrice = newPrice;
       emit TicketPriceUpdated(newPrice);
   }

   function updateIsActive(bool _enabled) external onlyOwner{
       require(isActive != _enabled, "You can't set the same flag");
       isActive = _enabled;
       emit IsActiveUpdated(_enabled);
   }

   function updateToken(address newToken) external onlyOwner{
       require(newToken != address(0), "Dead address is not valid");
       token = IERC20(newToken);
       emit TokenUpdated(newToken);
   }

}
