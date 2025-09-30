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
            AaveV3Constants.ethereumTestnetAddresses
        case .polygon(true):
            AaveV3Constants.polygonMainnetAddresses
        default:
            throw YieldModuleError.unsupportedBlockchain
        }
    }

    private static var supportedBlockchains: [Blockchain] {
        [
            .ethereum(testnet: true),
            .polygon(testnet: false),
        ]
    }
}

extension YieldSupplyContractAddressFactory {
    enum AaveV3Constants {
        static let polygonMainnetAddresses = YieldSupplyContractAddresses(
            factoryContractAddress: "0x685345d16aA462FB52bDB0D73807a199d1c5Ef76",
            processorContractAddress: "0xA32019c38a7EF45b87c09155600EEc457915b782",
            poolContractAddress: "0x794a61358D6845594F94dc1DB02A252b5b4814aD"
        )

        static let ethereumTestnetAddresses = YieldSupplyContractAddresses(
            factoryContractAddress: "0x62bc085Ef9e7700Af1F572cefCfdf4228E4EA3b8",
            processorContractAddress: "0x234D7653Ee1B6d8d87D008e613757Ac2f6Bd5a69",
            poolContractAddress: "0x6Ae43d3271ff6888e7Fc43Fd7321a503ff738951"
        )
    }
}
