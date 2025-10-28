//
//  YieldSupplyContractAddressFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

class YieldSupplyContractAddressFactory {
    private let blockchain: Blockchain

    init(blockchain: Blockchain) {
        self.blockchain = blockchain
    }

    var isSupported: Bool {
        Self.supportedBlockchains.contains(blockchain)
    }

    func getYieldSupplyContractAddresses() throws -> YieldSupplyContractAddresses {
        switch blockchain {
        case .ethereum(false):
            AaveV3Constants.ethereumAddresses
        case .avalanche(false):
            AaveV3Constants.avalancheAddresses
        case .arbitrum(false):
            AaveV3Constants.arbitrumAddresses
        case .optimism(false):
            AaveV3Constants.optimismAddresses
        case .base(false):
            AaveV3Constants.baseAddresses
        case .gnosis:
            AaveV3Constants.gnosisAddresses
        case .bsc(false):
            AaveV3Constants.bscAddresses
        case .zkSync(false):
            AaveV3Constants.zkSyncAddresses
        case .polygon(false):
            AaveV3Constants.polygonAddresses
        case .sonic(false):
            AaveV3Constants.sonicAddresses
        default:
            throw YieldModuleError.unsupportedBlockchain
        }
    }

    private static var supportedBlockchains: [Blockchain] {
        [
            .ethereum(testnet: false),
            .avalanche(testnet: false),
            .arbitrum(testnet: false),
            .optimism(testnet: false),
            .base(testnet: false),
            .bsc(testnet: false),
            .polygon(testnet: false),
        ]
    }
}

extension YieldSupplyContractAddressFactory {
    enum AaveV3Constants {
        static let ethereumAddresses = YieldSupplyContractAddresses(
            processorContractAddress: "0x4fF6178B58a51Cb74E50254ED1e9ebd4F28Eb2C0",
            factoryContractAddress: "0xd8972a45616bEC62cB9687e38a99D763c0879B0d",
        )

        static let avalancheAddresses = YieldSupplyContractAddresses(
            processorContractAddress: "0x1A5Dd8e4Feb0bb4E6765DAd78B83e8bA3fba2dAC",
            factoryContractAddress: "0x7255BFf778243f58B53777878B931Df596e1816A",
        )

        static let arbitrumAddresses = YieldSupplyContractAddresses(
            processorContractAddress: "0xF22E4A776cca26A003920538E174E3aeA8177d9f",
            factoryContractAddress: "0xb49CF4ba3c821560b5A4E6474D28f547368346CF",
        )

        static let optimismAddresses = YieldSupplyContractAddresses(
            processorContractAddress: "0x1A5Dd8e4Feb0bb4E6765DAd78B83e8bA3fba2dAC",
            factoryContractAddress: "0x7255BFf778243f58B53777878B931Df596e1816A",
        )

        static let baseAddresses = YieldSupplyContractAddresses(
            processorContractAddress: "0x487C7bA76BB0611d20A97E89625Ca93c87Ed4AA1",
            factoryContractAddress: "0xC49B1438c8639AB48953e9091E5277D4C65003f0",
        )

        static let gnosisAddresses = YieldSupplyContractAddresses(
            processorContractAddress: "0x1A5Dd8e4Feb0bb4E6765DAd78B83e8bA3fba2dAC",
            factoryContractAddress: "0x7255BFf778243f58B53777878B931Df596e1816A",
        )

        static let bscAddresses = YieldSupplyContractAddresses(
            processorContractAddress: "0x1A5Dd8e4Feb0bb4E6765DAd78B83e8bA3fba2dAC",
            factoryContractAddress: "0x7255BFf778243f58B53777878B931Df596e1816A",
        )

        static let zkSyncAddresses = YieldSupplyContractAddresses(
            processorContractAddress: "0x1A5Dd8e4Feb0bb4E6765DAd78B83e8bA3fba2dAC",
            factoryContractAddress: "0x7255BFf778243f58B53777878B931Df596e1816A",
        )

        static let polygonAddresses = YieldSupplyContractAddresses(
            processorContractAddress: "0xB04aFaA060097C4a2c9e45FE611BB5db682C9aD6",
            factoryContractAddress: "0xb49CF4ba3c821560b5A4E6474D28f547368346CF",
        )

        static let sonicAddresses = YieldSupplyContractAddresses(
            processorContractAddress: "0x7255BFf778243f58B53777878B931Df596e1816A",
            factoryContractAddress: "0xF22E4A776cca26A003920538E174E3aeA8177d9f",
        )
    }
}
