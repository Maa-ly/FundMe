//SPDX-License-Identifier: MiT

pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script {
    //if on local anvil deploy mocks
    //otherwise, grab the existing address from live network
    NetworkConfig public activeNetworkConfig;

    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8;

    struct NetworkConfig {
        address dataFeed;
    }

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthCongig();
        } else if (block.chainid == 1) {
            activeNetworkConfig = getMainnetEthConfig();
        } else {
            activeNetworkConfig = getOrAnvilEthConfig();
        }
    }

    function getSepoliaEthCongig() public pure returns (NetworkConfig memory) {
        //price Feed address
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            dataFeed: 0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43
        });
        return sepoliaConfig;
    }

    function getMainnetEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory MaiNetConfig = NetworkConfig({
            dataFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        });
        return MaiNetConfig;
    }

    function getOrAnvilEthConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.dataFeed != address(0)) {
            return activeNetworkConfig;
        }

        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(
            DECIMALS,
            INITIAL_PRICE
        );

        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({
            dataFeed: address(mockPriceFeed)
        });
        return anvilConfig;
    }
}
