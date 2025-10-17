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
        case .ethereum(true):
            AaveV3Constants.ethereumTestnetAddresses
        case .polygon(false):
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
            factoryContractAddress: "0x1bE509C2fF23dF065E15A6d37b0eFe4c839c62fE",
            processorContractAddress: "0xD021F1D410aCB895aB110a0CbB740a33db209bDD",
            poolContractAddress: "0x794a61358D6845594F94dc1DB02A252b5b4814aD"
        )

        static let ethereumTestnetAddresses = YieldSupplyContractAddresses(
            factoryContractAddress: "0xF3b31452E8EE5B294D7172B69Bd02decF2255FCd",
            processorContractAddress: "0x9A4b70A216C1A84d72a490f8cD3014Fdb538d249",
            poolContractAddress: "0x6Ae43d3271ff6888e7Fc43Fd7321a503ff738951"
        )
    }
}
