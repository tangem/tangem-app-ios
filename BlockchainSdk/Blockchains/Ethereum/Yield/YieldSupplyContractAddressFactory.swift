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
        switch blockchain {
        case .ethereum(let testnet) where testnet: true
        default: false
        }
    }

    func getYieldSupplyContractAddresses() throws -> YieldSupplyContractAddresses {
        let aaveV3Factory = AaveV3YieldSupplyContractAddressFactory(blockchain: blockchain)
        return YieldSupplyContractAddresses(
            factoryContractAddress: try aaveV3Factory.getFactoryAddress(),
            processorContractAddress: try aaveV3Factory.getProcessorAddress(),
            poolContractAddress: try aaveV3Factory.poolContractAddress()
        )
    }
}
