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
        static let ethereumAddress = "0xe3014E9AB2739aDeF234B3829C79128746160178"
        static let bscAddress = "0xe1d0BF13C427C4B2e25Df0CA29E1Faa2d10458f3"
        static let baseAddress = "0x61dD8620410a2372CbE4946f9148671F38F93fC7"
        static let polygonAddress = "0x2C2397c7605dc6d5493518260BDdeebE743B3faD"
        static let arbitrumAddress = "0x20e7016ff14Dd10f04028fE52aBBca34F44b6965"
    }
}
