//
//  GaslessTransactionAddressFactory.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum GaslessTransactionAddressFactory {
    static func gaslessExecutorContractAddress(blockchain: Blockchain) throws -> String {
        switch blockchain {
        case .ethereum:
            return Constants.ethereumAddress
        case .bsc:
            return Constants.bscAddress
        case .base:
            return Constants.baseAddress
        case .polygon:
            return Constants.polygonAddress
        case .arbitrum:
            return Constants.arbitrumAddress
        case .xdc:
            return Constants.xdcAddress
        case .optimism:
            return Constants.optimismAddress
        default:
            throw GaslessTransactionAddressFactoryError.addressNotDefined(blockchain.displayName)
        }
    }
}

extension GaslessTransactionAddressFactory {
    enum GaslessTransactionAddressFactoryError: Error {
        case addressNotDefined(String)
    }
}

extension GaslessTransactionAddressFactory {
    enum Constants {
        static let ethereumAddress = "0x2C2397c7605dc6d5493518260BDdeebE743B3faD"
        static let bscAddress = "0x2C2397c7605dc6d5493518260BDdeebE743B3faD"
        static let baseAddress = "0x2C2397c7605dc6d5493518260BDdeebE743B3faD"
        static let polygonAddress = "0x2C2397c7605dc6d5493518260BDdeebE743B3faD"
        static let arbitrumAddress = "0x2C2397c7605dc6d5493518260BDdeebE743B3faD"
        static let xdcAddress = "0x2C2397c7605dc6d5493518260BDdeebE743B3faD"
        static let optimismAddress = "0x2C2397c7605dc6d5493518260BDdeebE743B3faD"
    }
}
