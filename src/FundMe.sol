// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;
import {PriceConverter} from "./PriceConverter.sol";
import "forge-std/console.sol";

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

error FundME_NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    address[] private s_funders;
    mapping(address funder => uint256 amountFunded)
        private s_addressToAmountFunded;

    address private immutable i_Owner;
    uint256 public constant MINIMUM_USD = 5e18;

    AggregatorV3Interface private s_dataFeed;

    constructor(address dataFeed) {
        i_Owner = msg.sender;
        s_dataFeed = AggregatorV3Interface(dataFeed);
    }

    function fund() public payable {
        uint256 conversion = msg.value.getConversion(s_dataFeed);
        console.log("Conversion Value: ", conversion); // Debugging line
        require(conversion >= MINIMUM_USD, "Didn't send enough ETH");
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] += msg.value;
    }

    function getVersion() public view returns (uint256) {
        return s_dataFeed.version();
    }

    function CheaperWithdraw() public onlyOwner {
        uint256 funderLength = s_funders.length;
        for (
            uint256 funderIndex = 0;
            funderIndex < funderLength;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        // Reset array
        s_funders = new address[](0);

        // Transfer remaining balance
        payable(msg.sender).transfer(address(this).balance);

        // Send remaining balance
        bool sendSuccess = payable(msg.sender).send(address(this).balance);
        require(sendSuccess, "Send failed");

        // Call remaining balance
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        // Reset array
        s_funders = new address[](0);

        // Transfer remaining balance
        payable(msg.sender).transfer(address(this).balance);

        // Send remaining balance
        bool sendSuccess = payable(msg.sender).send(address(this).balance);
        require(sendSuccess, "Send failed");

        // Call remaining balance
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    modifier onlyOwner() {
        if (msg.sender != i_Owner) revert FundME_NotOwner();
        _;
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    //view/pure functions (Getters)
    function getAddressToAmountFunded(
        address fundingAddress
    ) external view returns (uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getFunders(uint256 index) external view returns (address) {
        return s_funders[index];
    }

    function getOwner() external view returns (address) {
        return i_Owner;
    }
}
